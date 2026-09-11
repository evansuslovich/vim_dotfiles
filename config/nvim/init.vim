    set runtimepath^=~/.vim runtimepath+=~/.vim/after
    let &packpath = &runtimepath
    source ~/.vim/vimrc

if has('nvim-0.5')
  lua << EOF
  local status, _ = pcall(require, 'lspconfig')
  if status then
    -- Run an LSP command using a Telescope picker if it's available, otherwise use the fallback.
    function lsp_do(picker, fallback)
      if picker == "lsp_code_actions" then
        print('Getting code actions (this may take a while on first use)...')
      end
      vim.schedule(function()
        local ok, telescope = pcall(require, 'telescope.builtin')
        if ok then
          telescope[picker]{}
        else
          fallback()
        end
      end)
    end

    function lsp_workspace_symbols(query)
      local ok, telescope = pcall(require, 'telescope.builtin')
      if ok then
        telescope.lsp_workspace_symbols{query=query}
      else
        vim.lsp.buf.workspace_symbol(query)
      end
    end

    -- Runs on every buffer an LSP client attaches to, replacing the old
    -- setup({on_attach = ...}) pattern (removed along with the lspconfig
    -- "framework" in Neovim 0.11). See :help lspconfig-nvim-0.11
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local bufnr = args.buf
        local opts = { noremap = true, silent = true, buffer = bufnr }

        -- Navigation
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gd', function() lsp_do('lsp_definitions', vim.lsp.buf.definition) end, opts)
        vim.keymap.set('n', '<Leader>D', function() lsp_do('lsp_type_definitions', vim.lsp.buf.type_definition) end, opts)

        -- Information
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('n', 'gr', function() lsp_do('lsp_references', vim.lsp.buf.references) end, opts)
        vim.keymap.set('n', '<Leader>ds', function() lsp_do('lsp_document_symbols', vim.lsp.buf.document_symbol) end, opts)

        -- Diagnostics
        vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
        vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
        vim.keymap.set('n', '<Leader>e', vim.diagnostic.open_float, opts)
        vim.keymap.set('n', '<Leader>q', vim.diagnostic.setloclist, opts)

        -- Refactoring
        vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set('n', '<Leader>ca', function() lsp_do('lsp_code_actions', vim.lsp.buf.code_action) end, opts)

        -- Workspaces
        vim.keymap.set('n', '<Leader>wa', vim.lsp.buf.add_workspace_folder, opts)
        vim.keymap.set('n', '<Leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
        vim.keymap.set('n', '<Leader>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, opts)

        if client and (client:supports_method('textDocument/formatting') or client:supports_method('textDocument/rangeFormatting')) then
          vim.keymap.set('n', '<Leader>fd', vim.lsp.buf.format, opts)
        end

        if client and client:supports_method('textDocument/documentHighlight') then
          vim.api.nvim_set_hl(0, 'LspReferenceRead', { bold = true, bg = 'LightYellow' })
          vim.api.nvim_set_hl(0, 'LspReferenceText', { bold = true, bg = 'LightYellow' })
          vim.api.nvim_set_hl(0, 'LspReferenceWrite', { bold = true, bg = 'LightYellow' })
          local hl_group = vim.api.nvim_create_augroup('lsp_document_highlight', { clear = false })
          vim.api.nvim_clear_autocmds({ group = hl_group, buffer = bufnr })
          vim.api.nvim_create_autocmd('CursorHold', { group = hl_group, buffer = bufnr, callback = vim.lsp.buf.document_highlight })
          vim.api.nvim_create_autocmd('CursorMoved', { group = hl_group, buffer = bufnr, callback = vim.lsp.buf.clear_references })
        end
      end,
    })

    -- Language server for Go
    if vim.fn.executable('gopls') == 1 then
      vim.lsp.enable('gopls')
    end

    -- Language server for Bash
    if vim.fn.executable('bash-language-server') == 1 then
      vim.lsp.enable('bashls')
    end

    -- Language server for editing this Lua/Vimscript config
    if vim.fn.executable('lua-language-server') == 1 then
      vim.lsp.enable('lua_ls')
    end

    -- Remove unused imports for Java
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'java',
      callback = function()
        vim.api.nvim_create_autocmd('BufWritePre', { buffer = 0, command = 'UnusedImports' })
      end,
    })

    -- Language server for Java
    if vim.fn.executable('java-language-server') == 1 then
      local jdtls_bundles = { vim.env.HOME .. "/language-servers/java/extensions/debug.jar" }
      vim.list_extend(jdtls_bundles, vim.split(vim.fn.glob(vim.env.HOME .. "/language-servers/java/extensions/test/extension/server/*.jar"), "\n"))
      vim.lsp.config('jdtls', {
        cmd = { "java-language-server", "--heap-max", "8G" },
        init_options = {
          bundles = jdtls_bundles,
        },
      })
      vim.lsp.enable('jdtls')
    end
  end

  local status, telescope = pcall(require, 'telescope')
  if status then
    telescope.setup{
      pickers = {
        ['lsp_code_actions'] = {
          timeout = 30000
        }
      }
    }
  end

  local status, treesitter = pcall(require, 'nvim-treesitter.configs')
  if status then
    treesitter.setup{
      -- List of supported languages can be found here: https://github.com/nvim-treesitter/nvim-treesitter#supported-languages
      ensure_installed = {"bash", "c_sharp", "clojure", "comment", "css", "go", "graphql", "html", "java", "javascript", "json", "kotlin", "lua", "php", "python", "regex", "ruby", "rust", "scala", "toml", "typescript"},
      highlight = {
        enable = true
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",
          node_incremental = "grn",
          scope_incremental = "grc",
          node_decremental = "grm",
        },
      },
      indent = {
        enable = true
      },
    }

    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
    vim.o.foldlevelstart = 99
  end

  function notify_file_changed(buffer, change)
    local log = require('vim.lsp.log')
    local filepath = vim.fn.expand('#'..buffer..':p')
    for _,client in pairs(vim.lsp.get_clients()) do
      log.info('Notifying LSP server "'..client.name..'" of change to file "'..filepath..'"')
      local result = client:notify('workspace/didChangeWatchedFiles', {
        changes = {{ uri = 'file://'..filepath, type = change }},
      })
      if not result then
        log.warn('File change notification failed!')
      end
    end
  end
EOF

  " LSP servers may not always pick up changes to relevant files, such as when
  " changing a resource file in a Java project. To help ensure that the language
  " server always has recent changes, send a notification to all active servers
  " whenever a file is changed.
  augroup buffer_updates
    au!
    au BufWritePost,FileWritePost * lua notify_file_changed(vim.fn.expand('<abuf>'), 2)
  augroup END

  command! -nargs=1 Symbols :lua lsp_workspace_symbols('<args>')

endif
