return {
  'rmagatti/auto-session',
  lazy = false,

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    suppressed_dirs = { '~/', '~/Developer', '~/Downloads', '~/Documents', '~/Desktop', '/' },
  },
  keys = {
    { '<leader>wr', '<cmd>SessionRestore<CR>', desc = '[W]orkspace [R]estore Sesssion' },
    { '<leader>sp', '<cmd>SessionSearch<CR>', desc ='[S]earch [P]roject' }
  },
}
