package main

import (
	"cmp"
	"context"
	"crypto/rand"
	_ "embed"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"maps"
	"os"
	"path/filepath"
	"strings"

	fzf "github.com/junegunn/fzf/src"
	"go.seankhliao.com/mono/run"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	corev1 "k8s.io/client-go/kubernetes/typed/core/v1"
	"k8s.io/client-go/tools/clientcmd"
	clientcmdapi "k8s.io/client-go/tools/clientcmd/api"
)

const (
	tmpPrefix = "kswitch.tmp.kubeconfig."
	examples  = `manage the kubectl context

Examples:

	kswitch current
	kswitch context
	kswitch context -context "..." -namespace "..."
	kswitch namespace
	kswitch cache-show
	kswitch cache-clean
	kswitch wrapper
`
)

func main() {
	app := &App{}
	run.OSExec(run.Group(
		"kswitch",
		examples,
		run.Simple("current", "show the current context", &currentCmd{app}),
		run.Simple("context", "switch the current context", &switchContextCmd{app}),
		run.Simple("namespace", "switch the current context", &switchNamespaceCmd{app}),
		run.Simple("cache-show", "print the location of the cache", &cacheShowCmd{app}),
		run.Simple("cache-clear", "reset the cache", &cacheClearCmd{app}),
		run.Simple("wrapper", "print the wrapper script", &wrapperCmd{app}),
	))
}

type currentCmd struct{ *App }

func (c *currentCmd) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return c.App.showCurrent(ctx, stdin, stdout, stderr, fsys)
}

type switchContextCmd struct{ *App }

func (c *switchContextCmd) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return c.App.switchContext(ctx, stdin, stdout, stderr, fsys)
}

type switchNamespaceCmd struct{ *App }

func (c *switchNamespaceCmd) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return c.App.switchNamespace(ctx, stdin, stdout, stderr, fsys)
}

type cacheShowCmd struct{ *App }

func (c *cacheShowCmd) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return c.App.printCache(ctx, stdin, stdout, stderr, fsys)
}

type cacheClearCmd struct{ *App }

func (c *cacheClearCmd) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return c.App.clearCache(ctx, stdin, stdout, stderr, fsys)
}

type wrapperCmd struct{ *App }

func (c *wrapperCmd) Run(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	return c.App.printWrapper(ctx, stdin, stdout, stderr, fsys)
}

type App struct {
	lg        *slog.Logger
	lvl       slog.LevelVar
	srcs      []string
	context   string
	namespace string
	evalFile  string

	confPath string
	conf     *clientcmdapi.Config
}

func (a *App) Flags(fset *flag.FlagSet) error {
	a.srcs = append(a.srcs, os.Getenv("KUBECONFG"))
	home, err := os.UserHomeDir()
	if err == nil {
		a.srcs = append(a.srcs, filepath.Join(home, ".config", "kube", "config"))
		a.srcs = append(a.srcs, filepath.Join(home, ".kube", "config"))
	}
	a.lg = slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{
		Level: &a.lvl,
	}))
	fset.TextVar(&a.lvl, "log.level", &a.lvl, "log level")
	fset.Func("kubeconfig", "path to kubeconfigs, may be directory, repeatable", func(s string) error {
		a.srcs = append(a.srcs, s)
		return nil
	})
	fset.StringVar(&a.context, "context", "", "kubeconfig context to use")
	fset.StringVar(&a.namespace, "namespace", "", "kubeconfig namespace to use")
	fset.StringVar(&a.evalFile, "eval-file", "", "path to file to write commands")
	return nil
}

func (a *App) switchContext(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	err := a.selectContext()
	if err != nil {
		return fmt.Errorf("select context: %w", err)
	}

	return a.switchNamespace(ctx, stdin, stdout, stderr, fsys)
}

func (a *App) switchNamespace(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	a.currentConfig()

	if !strings.Contains(a.confPath, tmpPrefix) {
		err := a.selectContext()
		if err != nil {
			return fmt.Errorf("select context: %w", err)
		}
	}

	err := a.selectNamespace()
	if err != nil {
		return fmt.Errorf("select namespace: %w", err)
	}

	eval := fmt.Sprintf("export KUBECONFIG=%s\n", a.confPath)
	os.WriteFile(a.evalFile, []byte(eval), 0o644)

	fmt.Fprintf(stdout, "kswitch context --context %s --namespace %s\n", a.context, a.namespace)
	fmt.Fprintf(stdout, "CONTEXT %s :: %s\n", a.context, a.namespace)

	return nil
}

func (a *App) selectContext() error {
	a.currentConfig()

	all := clientcmdapi.NewConfig()
	for _, src := range a.srcs {
		if src == "" {
			continue
		}
		fi, err := os.Stat(src)
		if err != nil {
			a.lg.Debug("failed stat of src", slog.String("file", src), slog.String("err", err.Error()))
			continue
		}
		if !fi.IsDir() {
			c, errL := clientcmd.LoadFromFile(src)
			if errL != nil {
				a.lg.Debug("failed load from file", slog.String("file", src), slog.String("err", errL.Error()))
				continue
			}
			mergeConfig(all, c)
			continue
		}
		fsys := os.DirFS(src)
		err = fs.WalkDir(fsys, ".", func(p string, d fs.DirEntry, errL error) error {
			if d.IsDir() || errL != nil {
				return errL
			}
			f := filepath.Join(src, p)
			c, errL := clientcmd.LoadFromFile(f)
			if errL != nil {
				a.lg.Debug("failed load from file in dir", slog.String("file", f), slog.String("err", errL.Error()))
				return nil
			}
			mergeConfig(all, c)
			return nil
		})
		if err != nil {
			a.lg.Debug("failed load from dir", slog.String("dir", src), slog.String("err", err.Error()))
		}
	}

	if len(all.Contexts) == 0 {
		return fmt.Errorf("no contexts available")
	}

	if a.context == "" {
		fzfOpts, err := fzf.ParseOptions(true, []string{})
		if err != nil {
			return fmt.Errorf("prepare fzf: %w", err)
		}
		fzfOpts.Input = make(chan string, len(all.Contexts))
		for n := range maps.Keys(all.Contexts) {
			fzfOpts.Input <- n
		}
		fzfOpts.Output = make(chan string, 1)
		_, err = fzf.Run(fzfOpts)
		if err != nil {
			return fmt.Errorf("run fzf: %w", err)
		}
		close(fzfOpts.Output)

		var ok bool
		a.context, ok = <-fzfOpts.Output
		if !ok {
			return fmt.Errorf("no context selected")
		}
	}
	cont, ok := all.Contexts[a.context]
	if a.context == "" || !ok {
		return fmt.Errorf("context not found in configs: %q", a.context)
	}
	a.lg.Debug("got context", slog.Any("context", cont))

	conf := clientcmdapi.NewConfig()
	conf.CurrentContext = a.context
	conf.Contexts[a.context] = cont
	conf.Clusters[cont.Cluster] = all.Clusters[cont.Cluster]
	conf.AuthInfos[cont.AuthInfo] = all.AuthInfos[cont.AuthInfo]
	conf.Preferences = all.Preferences
	conf.Extensions = all.Extensions
	a.conf = conf
	return nil
}

func (a *App) selectNamespace() error {
	if a.namespace == "" {
		var namespaces []string

		// load from cache on disk
		cacheDir, err := os.UserCacheDir()
		if err != nil {
			cacheDir = os.TempDir()
		}
		cacheFile := filepath.Join(cacheDir, "kswitch-ns-cache.json")
		a.lg.Debug("namespace cache", slog.String("file", cacheFile))
		nsCache := make(map[string][]string)
		b, err := os.ReadFile(cacheFile)
		if err != nil {
			a.lg.Debug("read ns cache file", slog.String("file", cacheFile), slog.String("err", err.Error()))
		} else {
			err = json.Unmarshal(b, &nsCache)
			if err != nil {
				a.lg.Debug("unmarshal ns cache file", slog.String("file", cacheFile), slog.String("err", err.Error()))
			} else {
				namespaces = nsCache[a.context]
			}

		}

		fzfOpts, err := fzf.ParseOptions(true, []string{})
		if err != nil {
			return fmt.Errorf("prepare fzf: %w", err)
		}
		fzfOpts.Output = make(chan string, 1)
		fzfOpts.Input = make(chan string, len(namespaces))
		nsSet := make(map[string]struct{}, len(namespaces))
		for _, ns := range namespaces {
			nsSet[ns] = struct{}{}
			fzfOpts.Input <- ns
		}

		var updatedNamespaces []string
		go func() {
			restConf, errK := clientcmd.NewDefaultClientConfig(*a.conf, nil).ClientConfig()
			if errK != nil {
				a.lg.Error("create k8s config", slog.String("err", errK.Error()))
				return
			}

			coreClient, errK := corev1.NewForConfig(restConf)
			if errK != nil {
				a.lg.Error("create k8s client", slog.String("err", errK.Error()))
				return
			}

			nsList, errK := coreClient.Namespaces().List(context.Background(), v1.ListOptions{})
			if errK != nil {
				a.lg.Error("list k8s namespaces", slog.String("err", errK.Error()))
				return
			}
			for _, ns := range nsList.Items {
				if _, ok := nsSet[ns.Name]; !ok {
					fzfOpts.Input <- ns.Name
					namespaces = append(namespaces, ns.Name)
					updatedNamespaces = append(updatedNamespaces, ns.Name)
				}
			}
			close(fzfOpts.Input)
		}()

		_, err = fzf.Run(fzfOpts)
		if err != nil {
			return fmt.Errorf("run fzf: %w", err)
		}
		close(fzfOpts.Output)

		var ok bool
		a.namespace, ok = <-fzfOpts.Output
		if !ok {
			return fmt.Errorf("no context selected")
		}

		if len(updatedNamespaces) > 0 {
			nsCache[a.context] = updatedNamespaces
		}
		b, err = json.Marshal(nsCache)
		if err != nil {
			a.lg.Debug("marshal ns cache file", slog.String("err", err.Error()))
		} else {
			err = os.WriteFile(cacheFile, b, 0o644)
			if err != nil {
				a.lg.Debug("write ns cache file", slog.String("file", cacheFile), slog.String("err", err.Error()))
			}
		}
	}

	a.conf.Contexts[a.conf.CurrentContext].Namespace = a.namespace
	if !strings.Contains(a.confPath, tmpPrefix) {
		a.confPath = filepath.Join(os.TempDir(), tmpPrefix+rand.Text())
	}
	err := clientcmd.WriteToFile(*a.conf, a.confPath)
	if err != nil {
		return fmt.Errorf("save kubeconfig to file %s: %w", a.confPath, err)
	}
	return nil
}

func (a *App) showCurrent(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	a.currentConfig()
	if a.conf == nil {
		return nil
	}
	kContext := a.conf.CurrentContext
	kNamespace := cmp.Or(a.conf.Contexts[a.conf.CurrentContext].Namespace, "default")
	fmt.Fprintf(stdout, "kswitch context --context %s --namespace %s\n", kContext, kNamespace)
	fmt.Fprintf(stdout, "CONTEXT %s :: %s\n", kContext, kNamespace)

	return nil
}

func (a *App) currentConfig() {
	if a.conf != nil && a.confPath != "" {
		return
	}

	confPath := os.Getenv("KUBECONFIG")
	if confPath == "" {
		return
	}
	fi, err := os.Stat(confPath)
	if err != nil {
		return
	}
	if fi.IsDir() {
		return
	}
	a.conf, err = clientcmd.LoadFromFile(confPath)
	if err != nil {
		return
	}

	a.context = a.conf.CurrentContext
	a.confPath = confPath
}

func (a *App) printCache(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	cacheDir, err := os.UserCacheDir()
	if err != nil {
		cacheDir = os.TempDir()
	}
	cacheFile := filepath.Join(cacheDir, "kswitch-ns-cache.json")
	fmt.Fprintln(stdout, cacheFile)
	return nil
}

func (a *App) clearCache(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	cacheDir, err := os.UserCacheDir()
	if err != nil {
		cacheDir = os.TempDir()
	}
	cacheFile := filepath.Join(cacheDir, "kswitch-ns-cache.json")
	err = os.Remove(cacheFile)
	if err != nil {
		return fmt.Errorf("remove cache file %s: %w", cacheFile, err)
	}
	fmt.Fprintln(stdout, "removed", cacheFile)
	return nil
}

func mergeConfig(all, conf *clientcmdapi.Config) {
	maps.Copy(all.Preferences.Extensions, conf.Preferences.Extensions)
	maps.Copy(all.Clusters, conf.Clusters)
	maps.Copy(all.AuthInfos, conf.AuthInfos)
	maps.Copy(all.Contexts, conf.Contexts)
	maps.Copy(all.Extensions, conf.Extensions)
}

//go:embed wrapper.zsh
var wrapper []byte

func (a *App) printWrapper(ctx context.Context, stdin io.Reader, stdout, stderr io.Writer, fsys fs.FS) error {
	stdout.Write(wrapper)
	return nil
}
