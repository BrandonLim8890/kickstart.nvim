return {
  {
    url = 'git@github.com:HubSpotEngineering/bend.nvim.git',
    config = function()
      local bend = require 'bend'
      bend.setup { v2 = true }

      local function organise_imports()
        local clients = vim.lsp.get_clients { bufnr = 0, name = 'ts_ls' }
        if clients[1] then
          clients[1]:exec_cmd {
            command = '_typescript.organizeImports',
            arguments = { vim.api.nvim_buf_get_name(0) },
          }
        end
      end

      -- Organise Imports
      vim.keymap.set('n', '<leader>co', organise_imports, { desc = 'Organise Imports' })

      vim.keymap.set('n', '<leader>lr', function()
        bend.reset()
      end, { desc = 'Bend Restart' })

      -- Force Absolute imports
      vim.keymap.set('n', '<leader>cp', function()
        local view = vim.fn.winsaveview()
        vim.cmd(string.format("%%!bash /Users/blim/src/misc/code-utils-master/forceabsolute-stdin.sh '%s'", vim.fn.expand '%:p:h'))
        vim.schedule(function()
          pcall(vim.fn.winrestview, view)
        end)
      end, { desc = 'Absolute Path' })

      vim.lsp.config['ts_ls'] = {
        cmd = {
          'bash',
          '-c',
          'NODE_OPTIONS="--max-old-space-size=8192" exec typescript-language-server --stdio',
        },
        filetypes = {
          'javascript',
          'javascriptreact',
          'javascript.jsx',
          'typescript',
          'typescriptreact',
          'typescript.tsx',
        },
        root_markers = {
          '.git',
        },
        on_attach = function(client)
          -- disable formatting so we can have prettier do that stuff
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
        init_options = {
          hostInfo = 'neovim',
          tsserver = { path = bend.getTsServerPathForCurrentFile() },
          plugins = {
            {
              name = '@styled/typescript-styled-plugin',
              location = '/opt/homebrew/lib/node_modules/@styled/typescript-styled-plugin',
            },
          },
        },
      }
      vim.lsp.log.set_level 'info'

      vim.lsp.enable 'ts_ls'

      vim.lsp.config['eslint'] = {
        cmd = {
          'bash',
          '-c',
          'NODE_OPTIONS="--max-old-space-size=8192" exec '
            .. vim.fn.expand '~/.local/share/nvim/mason/packages/eslint-lsp/node_modules/.bin/vscode-eslint-language-server'
            .. ' --stdio',
        },
        root_dir = function(bufnr, on_dir)
          -- Stop at the individual package boundary (tsconfig.json sits at each
          -- HubSpot package root, not inside static/) rather than walking all
          -- the way up to the monorepo yarn.lock. This prevents one ESLint server
          -- instance from owning the entire monorepo.
          local fname = vim.api.nvim_buf_get_name(bufnr)
          -- tsconfig.json is at every package root; yarn.lock is only at the monorepo root.
          -- By preferring tsconfig.json we stop at the package level.
          local package_root = vim.fs.root(bufnr, { 'tsconfig.json' })
          if not package_root then
            -- fall back for non-HubSpot projects
            package_root = vim.fs.root(bufnr, { 'yarn.lock', 'package-lock.json', '.git' })
              or vim.fn.getcwd()
          end
          -- only attach if the buffer actually has an eslint config in its tree
          local has_eslint_config = vim.fs.find(
            { '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', '.eslintrc.yaml', '.eslintrc.yml', 'eslint.config.js', 'eslint.config.mjs' },
            { path = fname, upward = true, stop = vim.fs.dirname(package_root), limit = 1, type = 'file' }
          )[1]
          if not has_eslint_config then
            return
          end
          on_dir(package_root)
        end,
      }
      vim.lsp.enable 'eslint'
    end,
  },
}
