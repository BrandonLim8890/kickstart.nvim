return {
  'rmagatti/auto-session',
  config = function()
    local auto_session = require 'auto-session'

    auto_session.setup {
      auto_restore_enabeld = false,
      auto_session_suppress_dirs = { '~/', '~/Developer', '~/Downloads', '~/Documents', '~/Desktop', '/' },
    }

    local keymap = vim.keymap

    keymap.set('n', '<leader>wr', '<cmd>SessionRestore<CR>', { desc = '[W]orkspace [R]estore Sesssion' })
  end,
}
