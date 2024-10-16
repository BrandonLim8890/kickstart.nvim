return {
  'pocco81/auto-save.nvim',
  config = function()
    require('auto-save').setup {
      condition = function(buf)
        local fn = vim.fn
        local utils = require("auto-save.utils.data")

        if
            fn.getbufvar(buf, "&modifiable") == 1 and
            -- change here is adding harpoon file type to exclusion list
            utils.not_in(fn.getbufvar(buf, "&filetype"), { "harpoon" }) then
          return true
        end
        return false
      end,
    }
  end,
}
