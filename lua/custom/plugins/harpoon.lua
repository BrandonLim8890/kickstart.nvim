return {
  "ThePrimeagen/harpoon",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = true,
  keys = {
    { "<leader>A", "<cmd>lua require('harpoon.mark').add_file()<cr>",        desc = "Mark file with harpoon" },
    { "<leader><c-h>", "<cmd>lua require('harpoon.ui').nav_file(1)<cr>",          desc = "Go to first harpoon mark" },
    { "<leader><c-j>", "<cmd>lua require('harpoon.ui').nav_file(2)<cr>",          desc = "Go to second harpoon mark" },
    { "<leader><c-k>", "<cmd>lua require('harpoon.ui').nav_file(3)<cr>",          desc = "Go to third harpoon mark" },
    { "<leader><c-l>", "<cmd>lua require('harpoon.ui').nav_file(4)<cr>",          desc = "Go to forth harpoon mark" },
    { "<leader>a", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", desc = "Show harpoon marks" },
  },
}
