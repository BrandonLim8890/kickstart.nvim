return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons', 'linrongbin16/lsp-progress.nvim' },
  opts = {
    options = {
      theme = 'nordic',
      component_separators = '',
      section_separators = { left = '', right = '' },
      disabled_filetypes = { 'alpha', 'Outline' },
    },
    tabline = {
      lualine_b = {
        {
          'filetype',
          icon_only = true,
          padding = { left = 1, right = 0 },
        },
      },
      lualine_c = {
        {
          'filename',
          path = 1,
          shorting_target = 0,
        },
      },
    },
    inactive_sections = {
      lualine_b = {
        {
          'filetype',
          icon_only = true,
          padding = { left = 1, right = 0 },
        },
        'filename',
      },
      lualine_c = {},
    },
    sections = {
      lualine_a = {
        function()
          local reg = vim.fn.reg_recording()
          -- If a macro is being recorded, show "Recording @<register>"
          if reg ~= '' then
            return 'Recording @' .. reg
          else
            -- Get the full mode name using nvim_get_mode()
            local mode = vim.api.nvim_get_mode().mode
            local mode_map = {
              n = 'NORMAL',
              i = 'INSERT',
              v = 'VISUAL',
              V = 'V-LINE',
              ['^V'] = 'V-BLOCK',
              c = 'COMMAND',
              R = 'REPLACE',
              s = 'SELECT',
              S = 'S-LINE',
              ['^S'] = 'S-BLOCK',
              t = 'TERMINAL',
            }

            -- Return the full mode name
            return mode_map[mode] or mode:upper()
          end
        end,
      },
      lualine_b = {
        {
          'filetype',
          icon_only = true,
          padding = { left = 1, right = 0 },
        },
        'filename',
      },
      lualine_c = {
        {
          'branch',
          icon = '',
        },
      },
      lualine_x = {
        {
          'diagnostics',
          symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
          update_in_insert = true,
        },
      },
      lualine_y = {
        {
          'diff',
          source = function()
            local gitsigns = vim.b.gitsigns_status_dict
            if not gitsigns then return nil end
            return {
              added = gitsigns.added,
              modified = gitsigns.changed,
              removed = gitsigns.removed,
            }
          end,
        },
      },
      lualine_z = {
        { 'location', separator = { left = '', right = ' ' } },
      },
    },
  },
}
