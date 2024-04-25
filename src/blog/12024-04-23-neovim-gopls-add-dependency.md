# neovim with gopls, adding new deps

## making gopls pick up new go dependencies in neovim without a restart

### _neovim,_ gopls, dependencies

[neovim](https://neovim.io/)
is my editor of choice these days, 
and with that comes a plethora of plugin options.
For completion, I use
[nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
along with [nvim-cmp-lsp](https://github.com/hrsh7th/cmp-nvim-lsp),
and [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
to setup all the LSP settings.
For Go,
that means using [gopls](https://github.com/golang/tools/blob/master/gopls/README.md).

One thing that has been a papercut for me for a while has been adding new dependencies.
`gopls` will suggest to import a dependency,
say `golang.org/x/sys/unix`, adding it to the `import` block on the file,
but then completion breaks since the dependency is not part of the module's dependencies
(not listed in `go.mod`).
What I've been doing is:
save, exit neovim, run `go mod tidy`, open neovim.
But that incurs a startup penalty every time.

Recently, I learned that it should actually work with LSP's `didChangeWatchedFiles`,
[merged over a year ago](https://github.com/neovim/neovim/issues/16078) into neovim.
This lets gopls tell neovim it's interested in getting notified about `go.mod`
file updates (so new dependencies),
allowing it pick up changes without a restart.

Now the flow is: save, and in a separate terminal run `go mod tidy`.
`gopls` should just pick up the changes and autocomplete will start working for the new dependency.

```lua
local capabilities = require("cmp_nvim_lsp").default_capabilities()
capabilities.workspace = { didChangeWatchedFiles = { dynamicRegistration = true } }
-- ... set other capabilities

require("lspconfig").gopls.setup({
  capabilities = capabilities,
  -- other settings
})
```
