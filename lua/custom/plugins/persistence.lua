return {
  'folke/persistence.nvim',
  event = 'BufReadPre',
  opts = {},
  -- stylua: ignore
  keys = {
    { "<leader>ps", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>pS", function() require("persistence").select() end, desc = "Select a session to load"},
    { "<leader>pl", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>pd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
  },
}
