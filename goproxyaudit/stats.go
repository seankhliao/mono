package goproxyaudit

import (
	"fmt"
	"net/http"

	goproxyauditv1 "go.seankhliao.com/mono/goproxyaudit/v1"
)

func (a *App) stats(rw http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	var mods, vers int
	a.store.RDo(ctx, func(s *goproxyauditv1.Store) {
		mods, vers = recursiveStats(s.GetRoot())
	})

	fmt.Fprintln(rw, "module count", mods)
	fmt.Fprintln(rw, "version count", vers)
}

func recursiveStats(m map[string]*goproxyauditv1.ModuleSegment) (modules, versions int) {
	for _, child := range m {
		var childModules, childVersions int
		children := child.GetChildren()
		if len(children) > 0 {
			childModules, childVersions = recursiveStats(children)
		}

		modules += childModules
		versions += childVersions

		mod := child.GetModule()
		if mod == nil {
			continue
		}
		ver := len(mod.GetVersions())
		if ver > 0 {
			modules += 1
			versions += ver
		}
	}
	return modules, versions
}
