local conf = require('telescope.config').values

local function toggle_telescope(harpoon_files)
  local finder = function()
    local file_paths = {}
    for _, item in ipairs(harpoon_files.items) do
      table.insert(file_paths, item.value)
    end

    return require('telescope.finders').new_table {
      results = file_paths,
    }
  end

  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Harpoon',
      finder = finder(),
      previewer = conf.file_previewer {},
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        map('n', 'dd', function()
          local state = require 'telescope.actions.state'
          local selected_entry = state.get_selected_entry()
          local current_picker = state.get_current_picker(prompt_bufnr)

          table.remove(harpoon_files.items, selected_entry.index)
          current_picker:refresh(finder())
        end)
        return true
      end,
    })
    :find()
end

return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('telescope').load_extension 'harpoon'
    -- require('harpoon'):setup()
  end,
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
        toggle_telescope(require('harpoon'):list())
      end,
      desc = '[S]earch Harpoon [M]arks',
    },
    {
      '<leader><c-h>',
      function()
        require('harpoon'):list():select(1)
      end,
      desc = 'Go to first harpoon mark',
    },
    {
      '<leader><c-j>',
      function()
        require('harpoon'):list():select(2)
      end,
      desc = 'Go to second harpoon mark',
    },
    {
      '<leader><c-k>',
      function()
        require('harpoon'):list():select(3)
      end,
      desc = 'Go to third harpoon mark',
    },
    {
      '<leader><c-l>',
      function()
        require('harpoon'):list():select(4)
      end,
      desc = 'Go to fourth harpoon mark',
    },
  },
}
