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
	"go.seankhliao.com/mono/ycli"
	v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	corev1 "k8s.io/client-go/kubernetes/typed/core/v1"
	"k8s.io/client-go/tools/clientcmd"
	clientcmdapi "k8s.io/client-go/tools/clientcmd/api"
)

// kswitch current
// kswitch context
// kswitch context --context "" --namespace ""
// kswicth namespace

const tmpPrefix = "kswitch.tmp.kubeconfig."

func main() {
	a := App{
		lg:   slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{})),
		srcs: []string{os.Getenv("KUBECONFIG")},
	}
	userConf, _ := os.UserConfigDir()
	if userConf != "" {
		a.srcs = append(a.srcs, filepath.Join(userConf, "kube"))
	}
	ycli.OSExec(ycli.NewGroup("kswicth",
		"manage the kubectl context",
		a.register,
		ycli.New(
			"context",
			"switch the current context",
			nil,
			a.switchContext,
		),
		ycli.New(
			"namespace",
			"switch the current namespace",
			nil,
			a.switchNamespace,
		),
		ycli.New(
			"current",
			"show the current context and namespace",
			nil,
			a.showCurrent,
		),
		ycli.New(
			"wrapper",
			"print the wrapper script",
			nil,
			a.showWrapper,
		),
	))
}

type App struct {
	lg        *slog.Logger
	srcs      []string
	context   string
	namespace string
	evalFile  string
}

func (a *App) register(fset *flag.FlagSet) {
	fset.Func("log.level", "set log level", func(s string) error {
		var lvl slog.Level
		err := lvl.UnmarshalText([]byte(s))
		if err != nil {
			return err
		}
		a.lg = slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{
			Level: lvl,
		}))
		return nil
	})
	fset.Func("kubeconfig", "path to kubeconfigs, may be directory, repeatable", func(s string) error {
		a.srcs = append(a.srcs, s)
		return nil
	})
	fset.StringVar(&a.context, "context", "", "kubeconfig context to use")
	fset.StringVar(&a.namespace, "namespace", "", "kubeconfig namespace to use")
	fset.StringVar(&a.evalFile, "eval-file", "", "path to file to write commands")
}

func (a *App) switchContext(stdout, stderr io.Writer) error {
	conf, err := a.selectContext()
	if err != nil {
		return err
	}

	conf, err = a.selectNamespace(conf)
	if err != nil {
		return err
	}

	confPath, err := a.saveContext("", conf)
	if err != nil {
		return err
	}

	eval := fmt.Sprintf("export KUBECONFIG=%s\n", confPath)
	os.WriteFile(a.evalFile, []byte(eval), 0o644)

	fmt.Fprintf(stdout, "kswitch context --context %s --namespace %s\n", a.context, a.namespace)
	fmt.Fprintf(stdout, "CONTEXT %s :: %s\n", a.context, a.namespace)

	return nil
}

func (a *App) switchNamespace(stdout, stderr io.Writer) error {
	confPath, conf, confManaged := a.currentConfig()
	if !confManaged {
		var err error
		conf, err = a.selectContext()
		if err != nil {
			return err
		}
		confPath, err = a.saveContext("", conf)
		if err != nil {
			return err
		}
	}

	conf, err := a.selectNamespace(conf)
	if err != nil {
		return err
	}

	confPath, err = a.saveContext(confPath, conf)
	if err != nil {
		return err
	}

	eval := fmt.Sprintf("export KUBECONFIG=%s\n", confPath)
	os.WriteFile(a.evalFile, []byte(eval), 0o644)

	fmt.Fprintf(stdout, "kswitch context --context %s --namespace %s\n", a.context, a.namespace)
	fmt.Fprintf(stdout, "CONTEXT %s :: %s\n", a.context, a.namespace)

	return nil
}

func (a *App) selectContext() (*clientcmdapi.Config, error) {
	all := clientcmdapi.NewConfig()
	for _, src := range a.srcs {
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
				a.lg.Debug("failed load from file in dir", slog.String("file", f), slog.String("err", err.Error()))
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
		return nil, fmt.Errorf("no contexts available")
	}

	if a.context == "" {
		fzfOpts, err := fzf.ParseOptions(true, []string{})
		if err != nil {
			return nil, fmt.Errorf("prepare fzf: %w", err)
		}
		fzfOpts.Input = make(chan string, len(all.Contexts))
		for n := range maps.Keys(all.Contexts) {
			fzfOpts.Input <- n
		}
		fzfOpts.Output = make(chan string, 1)
		_, err = fzf.Run(fzfOpts)
		if err != nil {
			return nil, fmt.Errorf("run fzf: %w", err)
		}
		close(fzfOpts.Output)

		var ok bool
		a.context, ok = <-fzfOpts.Output
		if !ok {
			return nil, fmt.Errorf("no context selected")
		}
	}
	cont, ok := all.Contexts[a.context]
	if a.context == "" || !ok {
		return nil, fmt.Errorf("context not found in configs: %q", a.context)
	}
	a.lg.Debug("got context", slog.Any("context", cont))

	conf := clientcmdapi.NewConfig()
	conf.CurrentContext = a.context
	conf.Contexts[a.context] = cont
	conf.Clusters[cont.Cluster] = all.Clusters[cont.Cluster]
	conf.AuthInfos[cont.AuthInfo] = all.AuthInfos[cont.AuthInfo]
	conf.Preferences = all.Preferences
	conf.Extensions = all.Extensions
	return conf, nil
}

func (a *App) saveContext(confPath string, conf *clientcmdapi.Config) (string, error) {
	if confPath == "" {
		confPath = os.Getenv("KUBECONFIG")
	}
	if !strings.Contains(confPath, tmpPrefix) {
		confPath = filepath.Join(os.TempDir(), tmpPrefix+rand.Text())
	}
	err := clientcmd.WriteToFile(*conf, confPath)
	if err != nil {
		return "", fmt.Errorf("save kubeconfig to file %s: %w", confPath, err)
	}
	return confPath, nil
}

func (a *App) selectNamespace(conf *clientcmdapi.Config) (*clientcmdapi.Config, error) {
	if a.namespace == "" {
		var namespaces []string

		// load from cache on disk
		cacheDir, err := os.UserCacheDir()
		if err != nil {
			cacheDir = os.TempDir()
		}
		cacheFile := filepath.Join(cacheDir, "kswitch-ns-cache.json")
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
			return nil, fmt.Errorf("prepare fzf: %w", err)
		}
		fzfOpts.Output = make(chan string, 1)
		fzfOpts.Input = make(chan string, len(namespaces))
		nsSet := make(map[string]struct{}, len(namespaces))
		for _, ns := range namespaces {
			nsSet[ns] = struct{}{}
			fzfOpts.Input <- ns
		}

		go func() {
			restConf, errK := clientcmd.NewDefaultClientConfig(*conf, nil).ClientConfig()
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
				}
			}
			close(fzfOpts.Input)
		}()

		_, err = fzf.Run(fzfOpts)
		if err != nil {
			return nil, fmt.Errorf("run fzf: %w", err)
		}
		close(fzfOpts.Output)

		var ok bool
		a.namespace, ok = <-fzfOpts.Output
		if !ok {
			return nil, fmt.Errorf("no context selected")
		}

		nsCache[a.context] = namespaces
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

	cont := conf.Contexts[conf.CurrentContext]
	cont.Namespace = a.namespace

	return conf, nil
}

func (a *App) showCurrent(stdout, _ io.Writer) error {
	_, conf, _ := a.currentConfig()
	if conf == nil {
		return nil
	}
	kContext := conf.CurrentContext
	kNamespace := cmp.Or(conf.Contexts[conf.CurrentContext].Namespace, "default")
	fmt.Fprintf(stdout, "kswitch context --context %s --namespace %s\n", kContext, kNamespace)
	fmt.Fprintf(stdout, "CONTEXT %s :: %s\n", kContext, kNamespace)

	return nil
}

func (a *App) currentConfig() (confPath string, conf *clientcmdapi.Config, managed bool) {
	confPath = os.Getenv("KUBECONFIG")
	if confPath == "" {
		return "", nil, false
	}
	fi, err := os.Stat(confPath)
	if err != nil {
		// debug
		return "", nil, false
	}
	if fi.IsDir() {
		// debug
		return "", nil, false
	}
	conf, err = clientcmd.LoadFromFile(confPath)
	if err != nil {
		return "", nil, false
	}
	if strings.Contains(confPath, tmpPrefix) {
		managed = true
	}
	return confPath, conf, managed
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

func (a *App) showWrapper(stdout, stderr io.Writer) error {
	stdout.Write(wrapper)
	return nil
}
