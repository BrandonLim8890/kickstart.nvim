return {
  -- fff: fast fuzzy file finder + live grep (primary picker)
  {
    'dmtrKovalenko/fff.nvim',
    lazy = false,
    build = function()
      require('fff.download').download_or_build_binary()
    end,
    opts = {
      debug = {
        enabled = false,
        show_scores = false,
      },
    },
    config = function(_, opts)
      require('fff').setup(opts)

      -- Send to Trouble qflist instead of native copen
      local picker_ui = require 'fff.picker_ui.picker_ui'
      local original_stq = picker_ui.send_to_quickfix
      picker_ui.send_to_quickfix = function()
        original_stq()
        vim.schedule(function()
          vim.cmd 'cclose'
          require('trouble').open 'qflist'
        end)
      end

      -- Guard against stale TSNodes in nvim 0.12 when typing quickly
      -- TODO: remove once fff.nvim fixes the shared mutable scratch buffer in treesitter_hl.lua
      local ts_hl = require 'fff.treesitter_hl'
      local original_glh = ts_hl.get_line_highlights
      ts_hl.get_line_highlights = function(text, lang)
        local ok, result = pcall(original_glh, text, lang)
        return ok and result or {}
      end
    end,
    keys = {
      {
        '<leader>sf',
        function()
          require('fff').find_files()
        end,
        desc = '[S]earch [F]iles',
      },
      {
        '<leader>sg',
        function()
          require('fff').live_grep()
        end,
        desc = '[S]earch by [G]rep',
      },
      {
        '<leader>sw',
        function()
          require('fff').live_grep { query = vim.fn.expand '<cword>' }
        end,
        desc = '[S]earch current [W]ord',
      },
      {
        '<leader>sw',
        function()
          require('fff').live_grep { query = vim.fn.expand '<cword>' }
        end,
        mode = 'v',
        desc = '[S]earch current [W]ord',
      },
    },
  },

  -- Telescope: fallback picker for LSP, diagnostics, keymaps, commands, sessions
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        defaults = {
          path_display = {
            filename_first = { reverse_directories = false },
          },
          mappings = {
            i = {
              ['<C-q>'] = function(...)
                require('trouble.sources.telescope').open(...)
              end,
            },
            n = {
              ['<C-q>'] = function(...)
                require('trouble.sources.telescope').open(...)
              end,
            },
          },
        },
        pickers = {
          live_grep = {
            file_ignore_patterns = { 'node_modules', '.git', '^build/' },
            additional_args = function(_)
              return { '--hidden' }
            end,
          },
          find_files = {
            file_ignore_patterns = { 'node_modules', '.git', '^build/' },
            hidden = true,
          },
        },
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      pcall(require('telescope').load_extension, 'persisted')

      local builtin = require 'telescope.builtin'

      -- LSP pickers via Telescope (set on LspAttach so they use the buffer-local server)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf
          vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
          vim.keymap.set('n', 'gd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
          vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
          vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
          vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
          vim.keymap.set('n', '<leader>ds', builtin.lsp_document_symbols, { buffer = buf, desc = '[D]ocument [S]ymbols' })
          vim.keymap.set('n', '<leader>ws', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = '[W]orkspace [S]ymbols' })
          vim.keymap.set({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, { buffer = buf, desc = '[C]ode [A]ction' })
          vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, { buffer = buf, desc = '[C]ode [R]ename' })
        end,
      })

      -- Non-file pickers that Telescope owns
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
      end, { desc = '[/] Fuzzily search in current buffer' })
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
      end, { desc = '[S]earch [/] in Open Files' })
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
      vim.keymap.set('n', '<leader>shf', '<cmd>Telescope find_files no_ignore=true<CR>', { desc = '[S]earch [H]idden [F]iles' })
      vim.keymap.set('n', '<leader>si', '<cmd>I18nPicker<CR>', { desc = '[S]earch [I]18n translations' })
      vim.keymap.set('n', '<leader>st', function()
        local dirs = require 'bend_dirs'
        if #dirs == 0 then
          builtin.git_status()
        elseif #dirs == 1 then
          builtin.git_status { cwd = dirs[1] }
        else
          vim.ui.select(dirs, { prompt = 'Git status for repo:' }, function(choice)
            if choice then
              builtin.git_status { cwd = choice }
            end
          end)
        end
      end, { desc = '[S]earch by Git S[T]atus' })
    end,
  },
}
