package main

import (
	"context"
	_ "embed"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"text/tabwriter"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"github.com/google/go-github/v60/github"
	"go.seankhliao.com/mono/ycli"
	"golang.org/x/oauth2"
)

const (
	GithubTokenEnv = "GH_TOKEN"
)

//go:embed schema.cue
var schemaBytes []byte

type SyncGithubConfig struct {
	Parallel     int
	Worktree     bool
	Archived     bool
	Orgs         []string
	Users        []string
	ExcludeRegex []string
}

func cmdSyncGithub() ycli.Command {
	cuectx := cuecontext.New()
	configVal := cuectx.CompileBytes(schemaBytes)
	var configFile string

	return ycli.New(
		"sync-github",
		"sync repositories with a github account / org",
		func(fs *flag.FlagSet) {
			fs.StringVar(&configFile, "config", "sync-github.repos.cue", "path to config file")
		},
		func(stdout, stderr io.Writer) error {
			configBytes, err := os.ReadFile(configFile)
			if err != nil {
				return fmt.Errorf("repos sync-github: read config file: %w", err)
			}
			configVal = configVal.Unify(cuectx.CompileBytes(configBytes))
			err = configVal.Validate()
			if err != nil {
				return fmt.Errorf("repos sync-github: validate config: %w", err)
			}

			var config SyncGithubConfig
			err = configVal.LookupPath(cue.ParsePath("config")).Decode(&config)
			if err != nil {
				return fmt.Errorf("repos sync-github: decode config: %w", err)
			}

			err = runSyncGithub(stderr, config)
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

func runSyncGithub(stderr io.Writer, config SyncGithubConfig) error {
	ctx := context.Background()

	ts := oauth2.StaticTokenSource(
		&oauth2.Token{AccessToken: os.Getenv(GithubTokenEnv)},
	)
	tc := oauth2.NewClient(ctx, ts)
	client := github.NewClient(tc)

	allReposM := make(map[string]string)
	for _, user := range config.Users {
		workItems := 1
		done, bar := progress(stderr, workItems, "listing repos for "+user)
		pagesForUser := 0
		for page := 1; true; page++ {
			repos, res, err := client.Repositories.ListByUser(ctx, user, &github.RepositoryListByUserOptions{
				ListOptions: github.ListOptions{
					Page:    page,
					PerPage: 100,
				},
			})
			if err != nil {
				return fmt.Errorf("list repos page %d for %s: %v", page, user, err)
			}

			if pagesForUser != res.LastPage {
				workItems += res.LastPage - pagesForUser
				pagesForUser = res.LastPage
				bar.ChangeMax(workItems)
			}

			err = addRepos(config, allReposM, repos)
			if err != nil {
				return err
			}

			bar.Add(1)
			if page >= res.LastPage {
				break
			}
		}
		bar.Add(1)
		<-done
		fmt.Fprintln(stderr)
	}
	for _, org := range config.Orgs {
		workItems := 1
		done, bar := progress(stderr, workItems, "listing repos for "+org)
		pagesForOrg := 0
		for page := 1; true; page++ {
			repos, res, err := client.Repositories.ListByOrg(ctx, org, &github.RepositoryListByOrgOptions{
				ListOptions: github.ListOptions{
					Page:    page,
					PerPage: 100,
				},
			})
			if err != nil {
				return fmt.Errorf("list repos page %d for %s: %v", page, org, err)
			}

			if pagesForOrg != res.LastPage {
				workItems += res.LastPage - pagesForOrg
				pagesForOrg = res.LastPage
				bar.ChangeMax(workItems)
			}

			err = addRepos(config, allReposM, repos)
			if err != nil {
				return err
			}
			bar.Add(1)
			if page >= res.LastPage {
				break
			}
		}
		bar.Add(1)
		<-done
		fmt.Fprintln(stderr)
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

	done, bar := progress(stderr, workItems, "Diffing repo list")

	type syncResult struct {
		name string
		op   string
		err  error
	}

	var errs []syncResult

	for _, r := range toClone {
		bar.Describe(fmt.Sprintf("cloning %s/%s", r.owner, r.repo))

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

		bar.Add(1)
	}

	for _, r := range toPrune {
		bar.Describe("removing " + r)

		err := os.RemoveAll(r)
		if err != nil {
			errs = append(errs, syncResult{
				r,
				"rm",
				err,
			})
		}

		bar.Add(1)
	}

	<-done
	fmt.Fprintln(stderr)

	if len(errs) > 0 {
		fmt.Fprintln(stderr)
		fmt.Fprintln(stderr, "Errors:")
		w := tabwriter.NewWriter(stderr, 0, 8, 1, ' ', 0)
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
		for _, pattern := range config.ExcludeRegex {
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
