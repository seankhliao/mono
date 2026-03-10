package run

var (
	_ Commander      = &groupCommand{}
	_ CommanderGroup = &groupCommand{}
)

type groupCommand struct {
	name string
	desc string
	cmds []Commander
}

func (g *groupCommand) CmdName() string       { return g.name }
func (g *groupCommand) CmdDesc() string       { return g.desc }
func (g *groupCommand) Commands() []Commander { return g.cmds }

func Group(name, desc string, cmds ...Commander) Commander {
	return &groupCommand{name, desc, cmds}
}
