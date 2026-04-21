return {
  'WilliamHsieh/overlook.nvim',
  opts = {},

  -- Optional: set up common keybindings
  keys = {
    {
      '<leader>pd',
      function()
        require('overlook.api').peek_definition()
      end,
      desc = 'Overlook: Peek definition',
    },
    {
      '<leader>pc',
      function()
        require('overlook.api').close_all()
      end,
      desc = 'Overlook: Close all popup',
    },
    {
      '<leader>pu',
      function()
        require('overlook.api').restore_popup()
      end,
      desc = 'Overlook: Restore popup',
    },
    {
      '<leader>pU',
      function()
        require('overlook.api').restore_all_popups()
      end,
      desc = 'Overlook: Restore all popups',
    },
    {
      '<leader>ps',
      function()
        require('overlook.api').open_in_split()
      end,
      desc = 'Overlook: Open in split',
    },
    {
      '<leader>pv',
      function()
        require('overlook.api').open_in_vsplit()
      end,
      desc = 'Overlook: Open in vsplit',
    },
    {
      '<leader>po',
      function()
        require('overlook.api').open_in_original_window()
      end,
      desc = 'Overlook: Open in original window',
    },
    {
      '<leader>pp',
      function()
        require('overlook.api').peek_cursor()
      end,
      desc = 'Overlook: Peek cursor',
    },
    {
      '<leader>pf',
      function()
        require('overlook.api').switch_focus()
      end,
      desc = 'Overlook: Switch focus',
    },
  },
}
