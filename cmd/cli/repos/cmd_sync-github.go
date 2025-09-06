package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"text/tabwriter"
	"time"

	"cuelang.org/go/cue"
	"github.com/briandowns/spinner"
	"github.com/google/go-github/v74/github"
	"go.seankhliao.com/mono/ycli"
	"golang.org/x/oauth2"
)

const (
	GithubTokenEnv = "GH_TOKEN"
)

type SyncGithubConfig struct {
	Parallel       int
	Worktree       bool
	Archived       bool
	Orgs           []string
	Users          []string
	ExcludeRegexes []string
}

func cmdSyncGithub(conf *CommonConfig) ycli.Command {
	return ycli.New(
		"sync-github",
		"sync repositories with a github account / org",
		nil,
		func(stdout, stderr io.Writer) error {
			configVal, err := conf.resolvedConfig()
			if err != nil {
				return err
			}

			var config SyncGithubConfig
			err = configVal.LookupPath(cue.ParsePath("SyncGithub")).Decode(&config)
			if err != nil {
				return fmt.Errorf("repos sync-github: decode config: %w", err)
			}

			err = runSyncGithub(stdout, config)
			if err != nil {
				return fmt.Errorf("repos sync-github: %w", err)
			}

			err = cmdSync().Run(stdout, stderr)
			if err != nil {
				return err
			}
			return nil
		},
	)
}

func runSyncGithub(stdout io.Writer, config SyncGithubConfig) error {
	ctx := context.Background()

	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: os.Getenv(GithubTokenEnv)},
	)
	tc := oauth2.NewClient(ctx, ts)
	client := github.NewClient(tc)

	allReposM := make(map[string]string)
	for _, user := range config.Users {
		workItems := 1
		spin := spinner.New(spinner.CharSets[39], 300*time.Millisecond)
		spin.Start()
		pagesForUser := 0
		for page := 1; true; page++ {
			spin.Suffix = fmt.Sprintf("list page %d for user %s", page, user)
			repos, res, err := client.Repositories.ListByUser(ctx, user, &github.RepositoryListByUserOptions{
				ListOptions: github.ListOptions{
					Page:    page,
					PerPage: 100,
				},
			})
			if err != nil {
				return fmt.Errorf("list repos page %d for %s: %v", page, user, err)
			}

			if pagesForUser == 0 {
				workItems += res.LastPage
				pagesForUser = res.LastPage
			}

			err = addRepos(config, allReposM, repos)
			if err != nil {
				return err
			}

			if page >= res.LastPage {
				break
			}
		}
		spin.FinalMSG = fmt.Sprintf("got %d repos for user %s\n", len(allReposM), user)
		spin.Stop()
		fmt.Fprintln(stdout)
	}
	for _, org := range config.Orgs {
		workItems := 1
		spin := spinner.New(spinner.CharSets[39], 300*time.Millisecond)
		spin.Start()
		pagesForOrg := 0
		for page := 1; true; page++ {
			spin.Suffix = fmt.Sprintf("list page %d for org %s", page, org)
			repos, res, err := client.Repositories.ListByOrg(ctx, org, &github.RepositoryListByOrgOptions{
				ListOptions: github.ListOptions{
					Page:    page,
					PerPage: 100,
				},
			})
			if err != nil {
				return fmt.Errorf("list repos page %d for %s: %v", page, org, err)
			}

			if pagesForOrg == 0 {
				workItems += res.LastPage
				pagesForOrg = res.LastPage
			}

			err = addRepos(config, allReposM, repos)
			if err != nil {
				return err
			}
			if page >= res.LastPage {
				break
			}
		}
		spin.FinalMSG = fmt.Sprintf("got %d repos for org %s\n", len(allReposM), org)
		spin.Stop()
		fmt.Fprintln(stdout)
	}

	localRepoM := make(map[string]struct{})
	des, err := os.ReadDir(".")
	if err != nil {
		return fmt.Errorf("read .: %w", err)
	}
	for _, de := range des {
		if !de.IsDir() {
			continue
		}
		localRepoM[de.Name()] = struct{}{}
	}

	var toClone []struct {
		owner, repo string
	}
	for k, v := range allReposM {
		if _, ok := localRepoM[k]; !ok {
			toClone = append(toClone, struct {
				owner string
				repo  string
			}{
				v, k,
			})
		}
	}
	sort.Slice(toClone, func(i, j int) bool {
		if toClone[i].owner != toClone[j].owner {
			return toClone[i].owner < toClone[j].owner
		}
		return toClone[i].repo < toClone[j].repo
	})
	var toPrune []string
	for r := range localRepoM {
		if _, ok := allReposM[r]; !ok {
			toPrune = append(toPrune, r)
		}
	}
	sort.Strings(toPrune)

	workItems := len(toClone) + len(toPrune)
	if workItems == 0 {
		return nil
	}

	spin := spinner.New(spinner.CharSets[39], 300*time.Millisecond)
	spin.Suffix = "diffing repo list"
	spin.Start()

	type syncResult struct {
		name string
		op   string
		err  error
	}

	var errs []syncResult

	for _, r := range toClone {
		spin.Suffix = fmt.Sprintf("cloning %s/%s", r.owner, r.repo)

		u := fmt.Sprintf("https://github.com/%s/%s", r.owner, r.repo)
		dst := r.repo
		if config.Worktree {
			dst += "/default"
		}
		cmd := exec.Command("git", "clone", u, dst)
		_, err := cmd.CombinedOutput()
		if err != nil {
			errs = append(errs, syncResult{
				r.owner + "/" + r.repo,
				"clone",
				err,
			})
		}

	}

	for _, r := range toPrune {
		spin.Suffix = "removing " + r

		err := os.RemoveAll(r)
		if err != nil {
			errs = append(errs, syncResult{
				r,
				"rm",
				err,
			})
		}

	}

	spin.Stop()
	fmt.Fprintln(stdout)

	if len(errs) > 0 {
		fmt.Fprintln(stdout)
		fmt.Fprintln(stdout, "Errors:")
		w := tabwriter.NewWriter(stdout, 0, 8, 1, ' ', 0)
		for _, err := range errs {
			fmt.Fprintf(w, "%s\t%s\t%v\n", err.op, err.name, err.err)
		}
		w.Flush()
	}

	return nil
}

func addRepos(config SyncGithubConfig, m map[string]string, repos []*github.Repository) error {
repoLoop:
	for _, repo := range repos {
		if !config.Archived && *repo.Archived {
			continue
		}
		for _, pattern := range config.ExcludeRegexes {
			ok, err := filepath.Match(pattern, *repo.Name)
			if err != nil {
				return fmt.Errorf("match exclude pattern %q against %q: %w", pattern, *repo.Name, err)
			} else if ok {
				continue repoLoop
			}
		}
		m[*repo.Name] = *repo.Owner.Login
	}
	return nil
}
