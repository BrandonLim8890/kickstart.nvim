local M = {
  key = 'nvim_cmp_hs_translations',
  cache = {
    ---@type table<string, table<{label: string, documentation: { kind: string, value: string }}>>
    completions = {},
    ---@type table<string, table<string, string>>
    translations = {},
  },
}

local lspconfig_util = require 'lspconfig.util'
local get_lib_dir = lspconfig_util.root_pattern('tsconfig.json', 'webpack.config.js', 'target')
local get_root = lspconfig_util.root_pattern('.git', '.blazar-enabled', 'package.json')

---@param bufnr number|nil
---@return string|nil
function M.get_root_dir(bufnr)
  local buffer_path = vim.api.nvim_buf_get_name(bufnr or vim.api.nvim_get_current_buf())
  return get_root(buffer_path)
end

---@param bufnr number|nil
---@return string|nil
function M.get_app_or_lib_dir(bufnr)
  local buffer_path = vim.api.nvim_buf_get_name(bufnr or vim.api.nvim_get_current_buf())
  return get_lib_dir(buffer_path)
end

local function split_string(str, delimiter)
  local result = {}
  for match in (str .. delimiter):gmatch('(.-)' .. delimiter) do
    table.insert(result, match)
  end
  return result
end

local function remove_prefix_from_string(str, pattern)
  return (str:sub(0, #pattern) == pattern) and str:sub(#pattern + 1) or str
end

local function get_completion_source()
  local source = {
    get_trigger_characters = function()
      return { '"' }
    end,
    is_available = function()
      return true
    end,
  }

  source.new = function()
    local self = setmetatable({ cache = M.cache.completions }, { __index = source })
    return self
  end

  source.complete = function(self, comp, callback)
    local cached_completions = M.get_completions()

    if vim.tbl_isempty(cached_completions) then
      M.parse_and_cache_translations()
      cached_completions = M.get_completions()
    end

    local all_items = {}
    for path, items in pairs(cached_completions) do
      for _, item in ipairs(items) do
        table.insert(all_items, item)
      end
    end

    callback { items = all_items, isIncomplete = false }
  end

  return source.new()
end

---@return table<string>
local function get_translation_files(root_dir)
  ---@type table<string>
  local translation_file_paths = {}
  vim
    .system({ 'rg', '--files', '-g', 'en.lyaml', root_dir }, { text = true }, function(result)
      if result.code == 0 then
        for file_path in result.stdout:gmatch '[^\r\n]+' do
          table.insert(translation_file_paths, file_path)
        end
      end
    end)
    :wait()
  return translation_file_paths
end

function M.parse_and_cache_translations()
  local root_dir = M.get_root_dir()

  if root_dir == nil or root_dir == '' then
    return
  end

  local file_paths = get_translation_files(root_dir)
  ---@type table<string, table<string, string>>
  local translations_by_directory = {}

  for _, file_path in ipairs(file_paths) do
    local path = file_path:match '(.+)/static/lang/.*%.lyaml$' or file_path:match '(.+)/lang/.*%.lyaml$'
    if path then
      if not translations_by_directory[path] then
        translations_by_directory[path] = {}
      end

      vim
        .system({ 'yq', 'ea', '. as $item ireduce ({}; . * $item )', file_path, '-o', 'p' }, { text = true }, function(res)
          if res.code == 0 then
            for line in res.stdout:gmatch '[^\r\n]+' do
              local key, value = unpack(split_string(line, ' = '))
              local label = remove_prefix_from_string(key, 'en.')
              translations_by_directory[path][label] = value
            end
          end
        end)
        :wait()
    end
  end
  M.set_translations(translations_by_directory)
  M.parse_and_cache_completions()
end

function M.parse_and_cache_completions()
  ---@type table<string, table<{label: string, documentation: { kind: string, value: string }}>>
  local completions = {}
  local translations = M.get_translations()

  for path, map in pairs(translations) do
    completions[path] = {}
    for key, value in pairs(map) do
      if key ~= '' and not key:match '^#' then -- filter out comments and empty lines
        table.insert(completions[path], {
          label = key,
          documentation = {
            kind = 'markdown',
            value = value,
          },
        })
      end
    end
  end

  M.set_completions(completions)
  return completions
end

---@param completions table<string, table<{label: string, documentation: { kind: string, value: string }}>>
function M.set_completions(completions)
  if completions == nil then
    return
  end
  M.cache.completions = completions
end

---@return table<string, table<{label: string, documentation: { kind: string, value: string }}>>
function M.get_completions()
  return M.cache.completions
end

---@param translations table<string, table<string, string>>
function M.set_translations(translations)
  if translations == nil then
    return
  end
  M.cache.translations = translations
end

---@return table<string, table<string, string>>
function M.get_translations()
  return M.cache.translations
end

---Find the YAML file, line number, and column for a given translation key
---@param key string
---@return string|nil file_path, number|nil line_number, number|nil column
function M.find_translation_definition(key)
  local translations = M.get_translations()

  local module_path = nil
  for path, keys in pairs(translations) do
    if keys[key] then
      module_path = path
      break
    end
  end

  if not module_path then
    return nil, nil
  end

  local yaml_files = {}
  vim
    .system({ 'rg', '--files', '-g', 'en.lyaml', module_path }, { text = true }, function(result)
      if result.code == 0 then
        for file_path in result.stdout:gmatch '[^\r\n]+' do
          table.insert(yaml_files, file_path)
        end
      end
    end)
    :wait()

  for _, yaml_file in ipairs(yaml_files) do
    local key_parts = vim.split(key, '.', { plain = true })

    local file_lines = {}
    local f = io.open(yaml_file, 'r')
    if f then
      for line in f:lines() do
        table.insert(file_lines, line)
      end
      f:close()
    end

    local current_line = 1
    local found = true

    for i, part in ipairs(key_parts) do
      local search_text = part .. ':'
      local part_found = false

      for line_num = current_line, #file_lines do
        if file_lines[line_num]:find(search_text, 1, true) then
          current_line = line_num
          part_found = true
          break
        end
      end

      if not part_found then
        found = false
        break
      end
    end

    if found then
      local line_content = file_lines[current_line]
      local colon_pos = line_content:find(':', 1, true)
      local column = 0

      if colon_pos then
        local value_start = line_content:find('%S', colon_pos + 1)
        if value_start then
          column = value_start - 1
        end
      end

      return yaml_file, current_line, column
    end
  end

  return nil, nil, nil
end

---Extract YAML key path from current cursor position in a YAML file
---@return string|nil
function M.extract_yaml_key_path()
  local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  if current_line_num > #lines then
    return nil
  end

  local current_line = lines[current_line_num]

  -- Extract key from current line (part before colon)
  local key_match = current_line:match '^%s*([%w_%-%.]+)%s*:'
  if not key_match then
    return nil
  end

  -- Get indentation level of current line
  local current_indent = #(current_line:match '^%s*' or '')

  -- Build path by walking backwards through parent keys
  local path_parts = { key_match }

  for i = current_line_num - 1, 1, -1 do
    local line = lines[i]
    local line_indent = #(line:match '^%s*' or '')

    -- Skip empty lines and comments
    if line:match '%S' and not line:match '^%s*#' then
      -- Found a parent key (less indentation)
      if line_indent < current_indent then
        local parent_key = line:match '^%s*([%w_%-%.]+)%s*:'
        if parent_key then
          table.insert(path_parts, 1, parent_key)
          current_indent = line_indent
        end
      end
    end
  end

  return table.concat(path_parts, '.')
end

function M.copy_yaml_key()
  local key_path = M.extract_yaml_key_path()

  if not key_path then
    vim.notify('[i18n] No valid YAML key found under cursor', vim.log.levels.WARN)
    return
  end

  -- Remove "en." prefix if present
  local clean_key = remove_prefix_from_string(key_path, 'en.')

  vim.fn.setreg('+', clean_key)
  vim.notify('Copied to clipboard: ' .. clean_key, vim.log.levels.INFO)
end

function M.goto_definition()
  local key = vim.fn.expand '<cword>'

  if not key:match '[%w_%-]+%.[%w_%-]+' then
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before = line:sub(1, col)
    local after = line:sub(col + 1)

    local start_quote = before:reverse():find '["\']'
    if not start_quote then
      vim.notify('[i18n] No translation key found under cursor', vim.log.levels.WARN)
      return
    end
    start_quote = col - start_quote + 1

    local end_quote = after:find '["\']'
    if not end_quote then
      vim.notify('[i18n] No translation key found under cursor', vim.log.levels.WARN)
      return
    end
    end_quote = col + end_quote

    key = line:sub(start_quote + 1, end_quote - 1)
  end

  if key == '' then
    vim.notify('[i18n] No translation key found under cursor', vim.log.levels.WARN)
    return
  end

  local translations = M.get_translations()
  local found_in_cache = false
  for _, keys in pairs(translations) do
    if keys[key] then
      found_in_cache = true
      break
    end
  end

  if not found_in_cache then
    vim.notify('[i18n] Key not in cache. Try triggering completion first.', vim.log.levels.WARN)
    return
  end

  local file_path, line_num, column = M.find_translation_definition(key)

  if file_path and line_num then
    vim.cmd('edit ' .. vim.fn.fnameescape(file_path))
    vim.api.nvim_win_set_cursor(0, { line_num, column or 0 })
  else
    vim.notify('[i18n] Translation key not found: ' .. key, vim.log.levels.WARN)
  end
end

local is_hubspot_machine = vim.uv.fs_stat(vim.env.HOME .. '/.hubspot')
function M.setup()
  if is_hubspot_machine then
    M.parse_and_cache_translations()
  end
end

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.schedule(function()
      M.setup()
    end)
  end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*/en.lyaml',
  callback = function()
    vim.schedule(function()
      M.cache.completions = {}
      M.cache.translations = {}
      M.parse_and_cache_translations()
    end)
  end,
})

-- ============================================================================
-- MONITORING & DEBUGGING
-- ============================================================================
M._debug = {
  parse_count = 0,
  last_parse_time = 0,
  total_parse_time = 0,
  system_call_count = 0,
}

-- Command to show detailed cache statistics
vim.api.nvim_create_user_command('I18nStats', function()
  local comp_count = 0
  local trans_count = 0
  local memory_estimate = 0
  local module_count = 0

  -- Count completions
  for path, items in pairs(M.cache.completions) do
    module_count = module_count + 1
    comp_count = comp_count + #items
    for _, item in ipairs(items) do
      -- Rough estimate: label + documentation value
      memory_estimate = memory_estimate + #item.label + #(item.documentation.value or "")
    end
  end

  -- Count translations
  for path, keys in pairs(M.cache.translations) do
    for key, value in pairs(keys) do
      trans_count = trans_count + 1
      memory_estimate = memory_estimate + #key + #value
    end
  end

  local memory_mb = memory_estimate / 1024 / 1024
  local lua_memory_mb = collectgarbage('count') / 1024
  local avg_parse_time = M._debug.parse_count > 0 and (M._debug.total_parse_time / M._debug.parse_count) or 0

  print(string.format([[
╔════════════════════════════════════════════════════════════════╗
║                    i18n Cache Statistics                       ║
╠════════════════════════════════════════════════════════════════╣
║  Modules cached:        %5d                                 ║
║  Total completions:     %5d items                           ║
║  Total translations:    %5d keys                            ║
║  Estimated cache size:  %5.2f MB                            ║
║                                                                ║
║  Parse operations:      %5d times                           ║
║  Last parse took:       %5.2f ms                            ║
║  Average parse time:    %5.2f ms                            ║
║  Total parse time:      %5.2f sec                           ║
║  System calls made:     %5d                                 ║
║                                                                ║
║  Total Lua memory:      %5.2f MB                            ║
╚════════════════════════════════════════════════════════════════╝
  ]],
    module_count,
    comp_count,
    trans_count,
    memory_mb,
    M._debug.parse_count,
    M._debug.last_parse_time,
    avg_parse_time,
    M._debug.total_parse_time / 1000,
    M._debug.system_call_count,
    lua_memory_mb
  ))
end, { desc = 'Show i18n cache statistics' })

-- Command to show which modules are cached
vim.api.nvim_create_user_command('I18nModules', function()
  print("\n📦 Cached i18n modules:")
  print("─────────────────────────────────────────────────────────")
  local sorted_modules = {}
  for path, _ in pairs(M.cache.translations) do
    table.insert(sorted_modules, path)
  end
  table.sort(sorted_modules)

  for _, path in ipairs(sorted_modules) do
    local module_name = path:match('([^/]+)$') or path
    local key_count = vim.tbl_count(M.cache.translations[path])
    local comp_count = M.cache.completions[path] and #M.cache.completions[path] or 0
    print(string.format("  • %-40s %4d keys, %4d completions", module_name, key_count, comp_count))
  end
  print(string.format("\nTotal: %d modules", #sorted_modules))
end, { desc = 'Show cached i18n modules' })

-- Command to clear cache and force garbage collection
vim.api.nvim_create_user_command('I18nClear', function()
  local before = collectgarbage('count') / 1024
  M.cache.completions = {}
  M.cache.translations = {}
  collectgarbage('collect')
  local after = collectgarbage('count') / 1024
  print(string.format("🗑️  Cache cleared. Memory freed: %.2f MB (%.2f MB → %.2f MB)", before - after, before, after))
end, { desc = 'Clear i18n cache and force GC' })

-- Command to count translation files in repo
vim.api.nvim_create_user_command('I18nFiles', function()
  local root = M.get_root_dir()
  if not root then
    print("❌ Not in a git repo")
    return
  end

  print("🔍 Scanning for en.lyaml files...")
  local start = vim.uv.hrtime()
  local result = vim.fn.systemlist(string.format("rg --files -g 'en.lyaml' '%s' 2>/dev/null", root))
  local elapsed = (vim.loop.hrtime() - start) / 1000000

  print(string.format("\n📄 Found %d translation files in %.0fms:", #result, elapsed))
  for i, file in ipairs(result) do
    local short_path = file:gsub(root .. '/', '')
    print(string.format("  %2d. %s", i, short_path))
  end
end, { desc = 'List all i18n translation files' })

-- Wrap parse_and_cache_translations to track metrics
local original_parse = M.parse_and_cache_translations
function M.parse_and_cache_translations()
  M._debug.parse_count = M._debug.parse_count + 1
  local start_time = vim.uv.hrtime()

  print(string.format("⏳ [i18n] Starting parse #%d...", M._debug.parse_count))
  original_parse()

  local end_time = vim.uv.hrtime()
  local elapsed = (end_time - start_time) / 1000000 -- Convert to ms
  M._debug.last_parse_time = elapsed
  M._debug.total_parse_time = M._debug.total_parse_time + elapsed

  print(string.format("✅ [i18n] Parse #%d completed in %.2fms", M._debug.parse_count, elapsed))
end

-- Wrap get_translation_files to track system calls
local original_get_files = get_translation_files
get_translation_files = function(root_dir)
  M._debug.system_call_count = M._debug.system_call_count + 1
  return original_get_files(root_dir)
end

local plugin_spec = {}

setmetatable(plugin_spec, {
  __index = M,
  __call = function(_, ...)
    return M
  end,
})

return plugin_spec
