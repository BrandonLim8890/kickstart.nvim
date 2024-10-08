return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  opts = {
    menu = {
      width = vim.api.nvim_win_get_width(0) - 4,
    },
    settings = {
      save_on_toggle = true,
    },
  },
  keys = {
    {
      '<leader>a',
      function()
        require('harpoon'):list():add()
      end,
      desc = 'Harpoon File',
    },
    {
      '<leader>sm',
      function()
        local harpoon = require 'harpoon'
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = '[S]earch Harpoon [M]arks',
    },
    {
      '<leader>H',
      function()
        require('harpoon'):list():select(1)
      end,
      desc = 'Go to first harpoon mark',
    },
    {
      '<leader>J',
      function()
        require('harpoon'):list():select(2)
      end,
      desc = 'Go to second harpoon mark',
    },
    {
      '<leader>K',
      function()
        require('harpoon'):list():select(3)
      end,
      desc = 'Go to third harpoon mark',
    },
    {
      '<leader>L',
      function()
        require('harpoon'):list():select(4)
      end,
      desc = 'Go to fourth harpoon mark',
    },
    {
      '<leader>:',
      function()
        require('harpoon'):list():select(5)
      end,
      desc = 'Go to fifth harpoon mark',
    },
  },
}
