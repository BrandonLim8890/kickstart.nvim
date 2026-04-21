return {
  'dmtrKovalenko/fff.nvim',
  build = function()
    require('fff.download').download_or_build_binary()
  end,
  -- if you are using nixos
  -- build = "nix run .#release",
  -- No need to lazy-load with lazy.nvim.
  -- This plugin initializes itself lazily.
  lazy = false,
  opts = {
    debug = {
      enabled = false,
      show_scores = false,
    },
  },
  config = function(_, opts)
    require('fff').setup(opts)

    -- Patch send_to_quickfix to open Trouble qflist instead of native copen
    local picker_ui = require 'fff.picker_ui'
    local original_stq = picker_ui.send_to_quickfix
    picker_ui.send_to_quickfix = function()
      original_stq()
      vim.schedule(function()
        vim.cmd 'cclose'
        require('trouble').open 'qflist'
      end)
    end

    -- Patch get_line_highlights to guard against stale TSNodes in nvim 0.12.
    -- When typing quickly, the scratch buffer is overwritten between parse and
    -- iter_captures, leaving nodes whose :range() returns nil and crashes nvim.
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
  },
}
