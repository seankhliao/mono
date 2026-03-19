package main

import (
	"cmp"
	"context"
	_ "embed"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"net/url"
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
	"go.seankhliao.com/mono/run"
	"golang.org/x/oauth2"
)

type Sync struct {
	tokenEnv string
	parallel int
	upstream string
	origin   string
	exclude  []*regexp.Regexp
	evalFile string
}

func (s *Sync) Flags(fset *flag.FlagSet, args **[]string) error {
	fset.StringVar(&s.tokenEnv, "token", "GH_TOKEN", "env variable to read github token from")
	fset.IntVar(&s.parallel, "parallel", 10, "parallel pulls")
	fset.StringVar(&s.upstream, "upstream", "", "upstream url prefix, also the org to sync from")
	fset.StringVar(&s.origin, "origin", "", "origin url prefix")
	fset.StringVar(&s.evalFile, "eval-file", "", "path to file for printing commands to eval")
	fset.Func("exclude", "regex where matching repos are excluded", func(ss string) error {
		r, err := regexp.Compile(ss)
		if err != nil {
			return fmt.Errorf("compile regex for %q: %w", ss, err)
		}
		s.exclude = append(s.exclude, r)
		return nil
	})

	return run.ChdirToParentFlagFile(fset, "repos.sync.txt")
}

func (s *Sync) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: os.Getenv(s.tokenEnv)},
	)
	tc := oauth2.NewClient(ctx, ts)
	client := github.NewClient(tc)

	spin := spinner.New(spinner.CharSets[39], 300*time.Millisecond, spinner.WithWriter(stdout))
	spin.Start()

	remoteURL := cmp.Or(s.upstream, s.origin)
	org := path.Base(remoteURL)
	spin.Suffix = "listing repos from org " + org
	remoteRepos, err := s.allRemoteRepos(ctx, client, org)
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
	limiter := make(chan struct{}, s.parallel)
	resc := make(chan syncResult)

	for _, repo := range download {
		wg.Add(1)
		go func(repo string) {
			limiter <- struct{}{}
			defer func() { <-limiter; wg.Done() }()

			resc <- syncResult{"download", repo, downloadRemote(ctx, s.upstream, s.origin, repo)}
		}(repo)
	}
	for _, repo := range update {
		wg.Add(1)
		go func(repo string) {
			limiter <- struct{}{}
			defer func() { <-limiter; wg.Done() }()

			resc <- syncResult{"update", repo, updateRemote(ctx, s.upstream, s.origin, repo)}
		}(repo)
	}
	for _, repo := range prune {
		wg.Add(1)
		go func(repo string) {
			limiter <- struct{}{}
			defer func() { <-limiter; wg.Done() }()

			resc <- syncResult{"prune", repo, removeLocal(ctx, repo)}
		}(repo)
	}

	var errs []error
	for i := range totalWork {
		res := <-resc
		spin.Suffix = fmt.Sprintf("% 4d/% 4d Working... %d errored, %s done",
			i+1, totalWork, len(errs), res.name)
		if res.err != nil {
			errs = append(errs, res.err)
		}
	}
	wg.Wait()
	spin.FinalMSG = fmt.Sprintf("% 4d/% 4d Downloaded: %d, Updated: %d, Pruned: %d, Errors: %d",
		totalWork, totalWork, len(download), len(update), len(prune), len(errs))
	spin.Stop()

	if len(errs) > 0 {
		fmt.Fprintln(stdout, "Errors:", len(errs))
		for _, gerr := range errs {
			fmt.Fprintln(stdout, "\t", gerr)
		}
	}

	return nil
}

type syncResult struct {
	action string
	name   string
	err    error
}

func (s *Sync) allRemoteRepos(ctx context.Context, client *github.Client, org string) ([]string, error) {
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
			for _, re := range s.exclude {
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
	return download, sync, prune
}

func downloadRemote(ctx context.Context, upstream, origin, name string) error {
	remoteName := "upstream"
	remoteURL, _ := url.JoinPath(upstream, name)
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

	remoteURL, _ = url.JoinPath(origin, name)
	cmd = exec.CommandContext(ctx, "jj", "git", "remote", "add", "origin", remoteURL)
	cmd.Dir = dir
	err = cmd.Run()
	if err != nil {
		return fmt.Errorf("clone %s: %w", remoteURL, err)
	}

	return nil
}

func updateRemote(ctx context.Context, upstream, origin, name string) error {
	dir := path.Join(name, "default")

	_, err := os.Stat(dir)
	if err != nil {
		if errors.Is(err, fs.ErrNotExist) {
			return downloadRemote(ctx, upstream, origin, name)
		}
		return fmt.Errorf("checking %s: %w", dir, err)
	}

	cmd := exec.CommandContext(ctx, "jj", "git", "fetch")
	cmd.Dir = dir
	err = cmd.Run()
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
