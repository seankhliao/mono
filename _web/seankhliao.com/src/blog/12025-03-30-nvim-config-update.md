# neovim config update

## more built in things

### _neovim_ config update

[neovim](https://neovim.io/) recently had their v0.11 release,
which prompted me to look at my config again.
Turns out, a few things have become built in.

#### _commenting_ blocks

Writing code, I often toggle blocks of code with comments.
In vim I used [tpope/vim-commentary](https://github.com/tpope/vim-commentary),
in nvim [numToStr/Comment.nvim](https://github.com/numToStr/Comment.nvim).

These days, it's [built in](https://neovim.io/doc/user/various.html#commenting),
relying on the
[buffer option commentstring](https://neovim.io/doc/user/options.html#'commentstring')
to inform it of the comment style,
usually set through language support like
[sheerun/polygot](https://github.com/sheerun/vim-polyglot).

#### _lsp_ config

Previously, you needed a completion engine like [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp),
then a bunch of completion sources to feed into it to get autocomplete.
If you were using language servers, that meant the completion source like
[hrsh7th/cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp),
plus [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) to actually configure all the servers,
and a snippet engine [hrsh7th/vim-vsnip](https://github.com/hrsh7th/vim-vsnip) for snippets.

Now, there's built in [snippets](https://neovim.io/doc/user/lua.html#vim.snippet)
and [autocomplete](https://neovim.io/doc/user/lsp.html#lsp-autocompletion) for lsp,
so we can rip all those out and "just" use:

```lua
-- config per language server
vim.lsp.config("gopls", {
	-- https://github.com/golang/tools/tree/master/gopls
	cmd = { "gopls" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_markers = { "go.mod", "go.sum", "go.work", ".git" },
	settings = {
		gopls = {
			gofumpt = true,
			staticcheck = true,
			templateExtensions = { "gotmpl" },
			vulncheck = "Imports",
			analyses = {
				shadow = true,
			},
		},
	},
	on_init = function(client)
		local path = client.workspace_folders[1].name
		if path:find("/sdk/") then
			-- disable gofumpt when working on Go project repos
			client.config.settings.gopls.gofumpt = false
		end
	end,
})
vim.lsp.enable("gopls")

-- shared config for all LSPs
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("my.lsp", {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    -- shorter custom key binds
		local bufopts = { silent = true }
		vim.keymap.set("n", "<space>e", vim.diagnostic.open_float)
		vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist)
		vim.keymap.set("n", "<space>d", vim.lsp.buf.definition, bufopts)
		vim.keymap.set("n", "<space>h", vim.lsp.buf.hover, bufopts)
		vim.keymap.set("n", "<space>i", vim.lsp.buf.implementation, bufopts)
		vim.keymap.set("n", "<space>s", vim.lsp.buf.signature_help, bufopts)
		-- vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
		vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, bufopts)
		vim.keymap.set("n", "<space>a", vim.lsp.buf.code_action, bufopts)
		vim.keymap.set("n", "<space>r", vim.lsp.buf.references, bufopts)

		if client:supports_method("textDocument/completion") then
			-- Optional: trigger autocompletion on EVERY keypress. May be slow!
			local chars = {}
			for i = 32, 126 do
				table.insert(chars, string.char(i))
			end
			client.server_capabilities.completionProvider.triggerCharacters = chars
			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
		end

		-- Auto-format ("lint") on save.
		-- Usually not needed if server supports "textDocument/willSaveWaitUntil".
		if
			not client:supports_method("textDocument/willSaveWaitUntil")
			and client:supports_method("textDocument/formatting")
		then
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("my.lsp", { clear = false }),
				buffer = args.buf,
				callback = function()
					if client.name == "gopls" then
					  -- goimports
						vim.lsp.buf.code_action({ bufnr = args.buf, id = client.id, context = { only = { 'source.organizeImports' } }, apply = true })
						vim.lsp.buf.code_action({ bufnr = args.buf, id = client.id, context = { only = { 'source.fixAll' } }, apply = true })
					end
					vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
				end,
			})
		end
	end,
})
```
