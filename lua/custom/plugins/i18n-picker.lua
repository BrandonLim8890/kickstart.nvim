local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local previewers = require 'telescope.previewers'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local i18n_module = require 'custom.plugins.i18n'
local hs_completion = i18n_module() -- Call to get M module

local function is_empty(t)
  if t == nil then
    return true
  end
  for _ in pairs(t) do
    return false
  end
  return true
end

local function get_translation_keys()
  local path = hs_completion.get_app_or_lib_dir()
  local translations = hs_completion.get_translations()
  if is_empty(translations) then
    return {}
  end

  local keys = {}
  if path ~= nil and not is_empty(translations[path]) then
    for key, value in pairs(translations[path]) do
      table.insert(keys, { key, value })
    end
    return keys
  end

  for _, values in pairs(translations) do
    for key, value in pairs(values) do
      table.insert(keys, { key, value })
    end
  end

  return keys
end

local previewer = previewers.new_buffer_previewer {
  define_preview = function(self, entry)
    if self.state.winid ~= -1 then
      vim.api.nvim_win_set_option(self.state.winid, 'wrap', true)
    end
    if entry.value ~= nil then
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, false, { entry.value[2] })
    end
  end,
}

local find_translation = function(opts)
  local results = get_translation_keys()

  local path = hs_completion.get_app_or_lib_dir()
  opts = opts or { defaults = { preview = { wrap = true } } }
  pickers
    .new(opts, {
      defaults = { preview = { wrap = true } },
      prompt_title = path and 'Translations for ' .. path:match '([^/]+)$' or 'All Translations',
      previewer = previewer,
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and selection.value then
            local key = selection.value[1]
            local file_path, line_num, column = hs_completion.find_translation_definition(key)

            if file_path and line_num then
              vim.cmd('edit ' .. vim.fn.fnameescape(file_path))
              vim.api.nvim_win_set_cursor(0, { line_num, column or 0 })
            else
              vim.notify('[i18n] Translation key not found: ' .. key, vim.log.levels.WARN)
            end
          end
        end)

        -- Add clipboard copy mapping
        map('i', '<C-y>', function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and selection.value then
            vim.fn.setreg('+', selection.value[1])
            print('Copied to clipboard: ' .. selection.value[1])
          end
        end)

        map('n', '<C-y>', function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and selection.value then
            vim.fn.setreg('+', selection.value[1])
            print('Copied to clipboard: ' .. selection.value[1])
          end
        end)

        return true
      end,
      finder = finders.new_table {
        results = results,
        entry_maker = function(entry)
          if entry == nil then
            return {
              value = 'No results',
              display = 'No results',
              ordinal = 'No results',
            }
          end
          return {
            value = entry,
            display = entry[1],
            ordinal = entry[1] .. ' ' .. entry[2],
          }
        end,
      },
    })
    :find()
end

local M = {}
function M.open()
  find_translation()
end

local is_hubspot_machine = vim.loop.fs_stat(vim.env.HOME .. '/.hubspot')
if not is_hubspot_machine then
  return {}
end

local i18n = i18n_module()

vim.api.nvim_create_user_command('I18nPicker', find_translation, { desc = 'Open i18n translation picker' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'lyaml', 'conf' },
  callback = function(args)
    vim.keymap.set('n', '<leader>iy', i18n.copy_yaml_key, { buffer = args.buf, desc = 'Copy i18n key path' })
  end,
})

return {}
