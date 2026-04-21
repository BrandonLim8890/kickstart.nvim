local raw = vim.env.BEND_DIRS or ''
if raw == '' then
  return {}
end

local dirs = {}
for _, path in ipairs(vim.split(raw, ':')) do
  local expanded = vim.fn.expand(path)
  if expanded ~= '' then
    table.insert(dirs, expanded)
  end
end
return dirs
