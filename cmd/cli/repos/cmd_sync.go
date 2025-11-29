package main

import (
	"cmp"
	"context"
	_ "embed"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path"
	"regexp"
	"slices"
	"strings"
	"sync"
	"time"

	"github.com/briandowns/spinner"
	"github.com/google/go-github/v74/github"
	"go.seankhliao.com/mono/cueconf"
	"go.seankhliao.com/mono/ycli"
	"golang.org/x/oauth2"
)

const (
	GithubTokenEnv = "GH_TOKEN"
)

//go:embed schema.cue
var configSchema string

type Config struct {
	Parallel int

	Upstream string
	Origin   string

	ExcludeRegexes []string
}

type ConfigRemote struct{}

func cmdSync() ycli.Command {
	var configFile string
	return ycli.New(
		"sync",
		"sync repositories with upstream origins",
		func(fs *flag.FlagSet) {
			fs.StringVar(&configFile, "config", "repos.cue", "path to config file")
		},
		func(stdout, _ io.Writer) error {
			config, err := cueconf.ForFile[Config](configSchema, "#SyncConfig", configFile, false)
			if err != nil {
				return fmt.Errorf("repos: decode config: %w", err)
			}

			err = runSync(stdout, config)
			if err != nil {
				return fmt.Errorf("repos sync: %w", err)
			}
			return nil
		},
	)
}

func runSync(stdout io.Writer, conf Config) error {
	ctx := context.Background()

	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: os.Getenv(GithubTokenEnv)},
	)
	tc := oauth2.NewClient(ctx, ts)
	client := github.NewClient(tc)

	spin := spinner.New(spinner.CharSets[39], 300*time.Millisecond)
	spin.Start()

	remoteURL := cmp.Or(conf.Upstream, conf.Origin)
	org := path.Base(remoteURL)
	spin.Suffix = "listing repos from org " + org
	remoteRepos, err := allRemoteRepos(client, ctx, org, conf.ExcludeRegexes)
	if err != nil {
		return fmt.Errorf("get remote repos: %w", err)
	}

	localRepos, err := allLocalRepos()
	if err != nil {
		return fmt.Errorf("get local repos: %w", err)
	}

	download, update, prune := splitRepos(remoteRepos, localRepos)
	totalWork := len(download) + len(update) + len(prune)
	spin.Suffix = fmt.Sprintf("% 4d/% 4d working on repos...", 0, totalWork)

	var wg sync.WaitGroup
	limiter := make(chan struct{}, conf.Parallel)
	errc := make(chan error)

	for _, repo := range download {
		wg.Go(func() {
			limiter <- struct{}{}
			defer func() { <-limiter }()

			errc <- downloadRemote(ctx, conf.Upstream, conf.Origin, repo)
		})
	}
	for _, repo := range update {
		wg.Go(func() {
			limiter <- struct{}{}
			defer func() { <-limiter }()

			errc <- updateRemote(ctx, repo)
		})
	}
	for _, repo := range prune {
		wg.Go(func() {
			limiter <- struct{}{}
			defer func() { <-limiter }()

			errc <- removeLocal(ctx, repo)
		})
	}

	var errs []error
	for i := range totalWork {
		spin.Suffix = fmt.Sprintf("% 4d/% 4d working on repos...", i, totalWork)
		err := <-errc
		if err != nil {
			errs = append(errs, err)
		}
	}
	spin.FinalMSG = fmt.Sprintf("% 4d/% 4d Downloaded: %d, Updated: %d, Pruned: %d, Errors: %d",
		totalWork, totalWork, len(download), len(update), len(prune), len(errs))

	if len(errs) > 0 {
		fmt.Fprintln(stdout, "Errors:", len(errs))
		fmt.Fprintln(stdout, "\t", err)
	}

	return nil
}

func allRemoteRepos(client *github.Client, ctx context.Context, org string, excludes []string) ([]string, error) {
	excludeRes := make([]*regexp.Regexp, 0, len(excludes))
	for i, exclude := range excludes {
		re, err := regexp.Compile(exclude)
		if err != nil {
			return nil, fmt.Errorf("error compiling regex %d %q: %v", i, exclude, err)
		}
		excludeRes = append(excludeRes, re)
	}

	var allRepos []string

	pagesForOrg := 0
	for page := 1; true; page++ {
		repos, res, err := client.Repositories.ListByOrg(ctx, org, &github.RepositoryListByOrgOptions{
			ListOptions: github.ListOptions{
				Page:    page,
				PerPage: 100,
			},
		})
		if err != nil {
			return nil, fmt.Errorf("list repos page %d for %s: %v", page, org, err)
		}

		if pagesForOrg == 0 {
			pagesForOrg = res.LastPage
		}

	nextRepo:
		for _, repo := range repos {
			if *repo.Archived {
				continue
			}
			for _, re := range excludeRes {
				if re.MatchString(*repo.Name) {
					continue nextRepo
				}
			}
			allRepos = append(allRepos, *repo.Name)
		}

		if page >= res.LastPage {
			break
		}
	}

	return allRepos, nil
}

func allLocalRepos() ([]string, error) {
	des, err := os.ReadDir(".")
	if err != nil {
		return nil, fmt.Errorf("read directory: %w", err)
	}

	var allRepos []string
	for _, de := range des {
		if !de.IsDir() {
			continue
		}
		if strings.HasPrefix(de.Name(), ".") {
			continue
		}
		allRepos = append(allRepos, de.Name())
	}

	return allRepos, nil
}

func splitRepos(remoteRepos, localRepos []string) (download, sync, prune []string) {
	slices.Sort(remoteRepos)
	slices.Sort(localRepos)
	var i, j int
	for {
		if i == len(remoteRepos) {
			prune = append(prune, localRepos[j:]...)
			break
		}
		if j == len(localRepos) {
			download = append(download, remoteRepos[i:]...)
			break
		}
		switch strings.Compare(remoteRepos[i], localRepos[j]) {
		case -1:
			download = append(download, remoteRepos[i])
			i++
		case 0:
			sync = append(sync, remoteRepos[i])
			i++
			j++
		case 1:
			prune = append(prune, localRepos[j])
			j++
		default:
			panic("unreachable")
		}
	}
	return
}

func downloadRemote(ctx context.Context, upstream, origin, name string) error {
	remoteName := "upstream"
	remoteURL := path.Join(upstream, name)
	if upstream == "" {
		remoteName = "origin"
		remoteURL = path.Join(origin, name)
	}
	dir := path.Join(name, "default")
	cmd := exec.CommandContext(ctx, "jj", "git", "clone", "--colocate", "--remote", remoteName, remoteURL, dir)
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("clone %s: %w", remoteURL, err)
	}

	if remoteName == "origin" {
		return nil
	}

	remoteURL = path.Join(origin, name)
	cmd = exec.CommandContext(ctx, "jj", "git", "remote", "add", "origin", remoteURL)
	cmd.Dir = dir
	err = cmd.Run()
	if err != nil {
		return fmt.Errorf("clone %s: %w", remoteURL, err)
	}

	return nil
}

func updateRemote(ctx context.Context, name string) error {
	dir := path.Join(name, "default")
	cmd := exec.CommandContext(ctx, "jj", "git", "fetch")
	cmd.Dir = dir
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("update repo %s: jj fetch: %w", name, err)
	}

	cmd = exec.CommandContext(ctx, "jj", "new", "trunk()")
	cmd.Dir = dir
	err = cmd.Run()
	if err != nil {
		return fmt.Errorf("update repo %s: jj new: %w", name, err)
	}

	return nil
}

func removeLocal(ctx context.Context, repo string) error {
	err := os.RemoveAll(repo)
	if err != nil {
		return fmt.Errorf("remove local repo %s: %w", repo, err)
	}
	return nil
}
