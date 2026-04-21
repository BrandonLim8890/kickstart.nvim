return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    { url = 'git@github.com:HubSpotEngineering/neotest-hs-jasmine.git', build = 'cd runner && bend yarn' },
  },
  config = function()
    require('neotest').setup {
      adapters = {
        require 'neotest-hs-jasmine',
      },
    }
  end,
  keys = {
    {
      '<leader>tn',
      function()
        require('neotest').run.run()
      end,
      desc = 'Run nearest test',
    },
    {
      '<leader>tf',
      function()
        require('neotest').run.run(vim.fn.expand '%')
      end,
      desc = 'Run file tests',
    },
    {
      '<leader>to',
      function()
        require('neotest').output.open { enter = true }
      end,
      desc = 'Test output',
    },
    {
      '<leader>ts',
      function()
        require('neotest').summary.toggle()
      end,
      desc = 'Test summary',
    },
  },
}
