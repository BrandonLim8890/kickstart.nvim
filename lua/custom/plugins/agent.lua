local function get_buffer_context()
  local buf_name = vim.fn.expand '%:t'
  local buf_path = vim.fn.expand '%:p'
  local selected_text = ''
  local start_line, end_line

  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\22' then -- v, V, or ctrl-v
    local save_reg = vim.fn.getreg '"'
    local save_regtype = vim.fn.getregtype '"'

    -- Yank the selection into the unnamed register
    vim.cmd [[silent normal! "xy]]

    -- Get the text from the unnamed register
    selected_text = vim.fn.getreg 'x'

    -- Get start and end positions of selection
    start_line = vim.fn.line "'<"
    end_line = vim.fn.line "'>"

    -- Restore the register
    vim.fn.setreg('"', save_reg, save_regtype)

    -- Add line numbers to the selected text
    local lines = {}
    local line_num = start_line
    for line in selected_text:gmatch '[^\r\n]+' do
      table.insert(lines, string.format('%4d: %s', line_num, line))
      line_num = line_num + 1
    end
    selected_text = table.concat(lines, '\n')
  else
    start_line = vim.fn.line '.'
    end_line = start_line
  end

  local context = string.format("I'm looking at the %s file (%s)\n\n", buf_name, buf_path)

  if selected_text ~= '' then
    context = context .. string.format(' on lines %d to %d.\n\nHere is the selected content:\n%s\n\n', start_line, end_line, selected_text)
  end

  return context
end

local function open_prompt_editor(initial_text, on_submit)
  -- Create a scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer content
  local lines = vim.split(initial_text, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Calculate small window size and position in bottom-right
  local width = math.floor(vim.o.columns * 0.35)
  local height = math.floor(vim.o.lines * 0.25)
  local row = vim.o.lines - height - 3
  local col = vim.o.columns - width - 2

  -- Open floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Edit Prompt (Enter to send, Ctrl-c to cancel) ',
    title_pos = 'center',
  })

  -- Position cursor at end of buffer
  local last_line = #lines
  local last_col = #lines[last_line]
  vim.api.nvim_win_set_cursor(0, { last_line, last_col })

  -- Set buffer options
  vim.api.nvim_set_option_value('filetype', 'markdown', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })

  -- Submit function
  local function submit()
    local content_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(content_lines, '\n')
    vim.api.nvim_win_close(win, true)
    on_submit(content)
  end

  -- Cancel function
  local function cancel()
    vim.api.nvim_win_close(win, true)
  end

  -- Set buffer-local keymaps
  vim.keymap.set('n', '<CR>', submit, { buffer = buf, desc = 'Submit prompt' })
  vim.keymap.set('n', '<C-c>', cancel, { buffer = buf, desc = 'Cancel prompt' })
  vim.keymap.set('n', 'q', cancel, { buffer = buf, desc = 'Cancel prompt' })
end

local function find_existing_pane(match_pattern)
  if not vim.env.TMUX then
    return nil
  end

  local current_session = vim.fn.system("tmux display-message -p '#S'"):gsub('%s+$', '')
  local tmux_panes = vim.fn.systemlist('tmux list-panes -t ' .. current_session .. " -F '#{pane_id} #{pane_current_command} #{pane_title}'")

  for _, line in ipairs(tmux_panes) do
    if line:match(match_pattern) then
      return line:match '^(%%[%d]+)'
    end
  end

  return nil
end

local function send_to_agent(prompt, agent_command, match_pattern)
  if not vim.env.TMUX then
    vim.notify('Not in tmux session', vim.log.levels.ERROR)
    return
  end

  -- Check if pane already exists
  local found_pane = find_existing_pane(match_pattern)

  if found_pane then
    -- Send prompt to existing pane using bracketed paste mode
    -- This mimics Cmd+V behavior which prevents newlines from being interpreted as Enter
    vim.fn.setreg('+', prompt)
    local cmd = (vim.fn.has 'mac' == 1 and 'pbpaste' or 'wl-paste') .. ' | tmux load-buffer -'
    vim.fn.system(cmd)
    -- Wrap content in bracketed paste escape sequences
    local wrapped_cmd = string.format(
      "printf '\\033[200~' && tmux save-buffer - && printf '\\033[201~\\n'",
      found_pane
    )
    vim.fn.system('bash -c ' .. vim.fn.shellescape(wrapped_cmd) .. ' | tmux load-buffer -')
    vim.fn.system('tmux paste-buffer -t ' .. found_pane)
    vim.fn.system('tmux select-pane -t ' .. found_pane)
  else
    -- Create new pane with inline prompt
    local escaped_prompt = prompt:gsub("'", "'\\''")
    local new_pane = vim.fn.systemlist('tmux split-window -h -b -p 33 -P -F "#{pane_id}"')[1]
    local command = string.format("%s '%s'", agent_command, escaped_prompt)
    vim.fn.system('tmux send-keys -t ' .. new_pane .. ' ' .. vim.fn.shellescape(command) .. ' Enter')
    vim.fn.system('tmux select-pane -t ' .. new_pane)
  end
end

local function send_to_claude(prompt)
  send_to_agent(prompt, 'exec claude', 'claude')
end

local function send_to_opencode(prompt)
  send_to_agent(prompt, 'opencode --prompt', 'python')
end

vim.keymap.set({ 'n', 'v' }, '<leader>ac', function()
  local context = get_buffer_context()
  open_prompt_editor(context, send_to_claude)
end, { desc = 'Send prompt to Claude' })

vim.keymap.set({ 'n', 'v' }, '<leader>ao', function()
  local context = get_buffer_context()
  open_prompt_editor(context, send_to_opencode)
end, { desc = 'Send prompt to OpenCode' })

return {}
