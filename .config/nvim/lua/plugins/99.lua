return {
  {
    'ThePrimeagen/99',
    config = function()
      local _99 = require '99'
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)

      local Providers = require '99.providers'
      local DvxProvider = setmetatable({}, { __index = Providers.OpenCodeProvider })

      function DvxProvider._build_command(_, query, context)
        return {
          'dvx',
          'opencode',
          'run',
          '--agent',
          'build',
          '-m',
          context.model,
          query,
        }
      end

      function DvxProvider._get_provider_name()
        return 'DvxProvider'
      end

      _99.open_qfix_for_request = function(request)
        local items = request:qfix_data()
        if #items == 0 then
          print 'there are no quickfix items to show'
          return
        end
        vim.fn.setqflist({}, 'r', { title = '99 Results', items = items })
        vim.cmd 'Trouble qflist open'
      end

      _99.setup {
        provider = DvxProvider,
        model = 'openai_locked/gpt-5.6-luna',
        tmp_dir = './99_tmp',
        md_files = { 'AGENT.md' },
        logger = {
          level = _99.DEBUG,
          type = 'file',
          path = '/tmp/' .. basename .. '.99.debug',
          print_on_error = true,
        },
      }

      local explain_ns = vim.api.nvim_create_namespace 'opencode-explain'

      vim.keymap.set('v', '<leader>ae', function()
        local Prompt = require '99.prompt'
        local CleanUp = require '99.ops.clean-up'
        local Window = require '99.window'

        local start_pos = vim.fn.getpos 'v'
        local end_pos = vim.fn.getpos '.'
        local start_line = math.min(start_pos[2], end_pos[2]) - 1
        local end_line = math.max(start_pos[2], end_pos[2]) - 1
        local buf = vim.api.nvim_get_current_buf()
        local selected_lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line + 1, false)
        local selected_text = table.concat(selected_lines, '\n')

        local state = _99.__get_state()
        local context = Prompt.search(state)

        -- Show an in-flight spinner as virtual text, tracked separately from context.marks
        -- so context:stop()/clear_marks() does not wipe it
        local spinner_chars = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
        local spinner_idx = 1
        local spinner_top_id = vim.api.nvim_buf_set_extmark(buf, explain_ns, start_line, 0, {
          virt_lines = { { { spinner_chars[1] .. ' Explaining...', 'Comment' } } },
          virt_lines_above = true,
        })
        local spinner_bot_id = vim.api.nvim_buf_set_extmark(buf, explain_ns, end_line, 0, {
          virt_lines = { { { spinner_chars[1] .. ' Explaining...', 'Comment' } } },
          virt_lines_above = false,
        })
        local spinner_running = true
        local function tick()
          if not spinner_running then
            return
          end
          spinner_idx = spinner_idx % #spinner_chars + 1
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_set_extmark(buf, explain_ns, start_line, 0, {
              id = spinner_top_id,
              virt_lines = { { { spinner_chars[spinner_idx] .. ' Explaining...', 'Comment' } } },
              virt_lines_above = true,
            })
            vim.api.nvim_buf_set_extmark(buf, explain_ns, end_line, 0, {
              id = spinner_bot_id,
              virt_lines = { { { spinner_chars[spinner_idx] .. ' Explaining...', 'Comment' } } },
              virt_lines_above = false,
            })
          end
          vim.defer_fn(tick, 250)
        end
        vim.defer_fn(tick, 250)

        context:_ready_request_files()
        state.tracking:track(context)
        context.state = 'requesting'

        local prompt = 'Explain what this code does. Be concise. Write your explanation to <TEMP_FILE>'
          .. context.tmp_file
          .. '</TEMP_FILE>\n\n'
          .. selected_text

        local provider = state.provider_override or require('99.providers').OpenCodeProvider

        provider:make_request(
          prompt,
          context,
          CleanUp.make_observer(context, {
            on_complete = function(status, response)
              spinner_running = false
              if status ~= 'success' or vim.trim(response) == '' then
                vim.api.nvim_buf_del_extmark(buf, explain_ns, spinner_top_id)
                vim.api.nvim_buf_del_extmark(buf, explain_ns, spinner_bot_id)
                return
              end

              local first_line = vim.split(response, '\n')[1] or ''
              local preview = '// explain: ' .. first_line:sub(1, 80) .. (#first_line > 80 and '...' or '')
              local full_lines = vim.split(response, '\n')

              vim.api.nvim_buf_set_extmark(buf, explain_ns, start_line, 0, {
                id = spinner_top_id,
                virt_lines = { { { preview, 'Comment' } } },
                virt_lines_above = true,
              })
              vim.api.nvim_buf_del_extmark(buf, explain_ns, spinner_bot_id)

              vim.keymap.set('n', '<leader>ae', function()
                local cursor = vim.api.nvim_win_get_cursor(0)
                local popup_buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, full_lines)
                local width = 0
                for _, line in ipairs(full_lines) do
                  width = math.max(width, #line)
                end
                width = math.min(width, math.floor(vim.o.columns * 0.8))
                local height = math.min(#full_lines, math.floor(vim.o.lines * 0.5))
                vim.api.nvim_open_win(popup_buf, true, {
                  relative = 'cursor',
                  row = 1,
                  col = 0,
                  width = width,
                  height = height,
                  style = 'minimal',
                  border = 'rounded',
                })
                if popup_buf then
                  vim.keymap.set('n', 'q', function()
                    vim.api.nvim_buf_delete(popup_buf, { force = true })
                  end, { desc = 'Close explain popup', buffer = popup_buf })
                end
              end, { desc = 'AI: open explain popup', buffer = buf })
            end,
          })
        )
      end, { desc = 'AI: explain selection' })

      vim.keymap.set('v', '<leader>av', function()
        _99.visual()
      end, { desc = 'AI: visual replace' })

      vim.keymap.set('n', '<leader>af', function()
        _99.search()
      end, { desc = 'AI: search' })

      vim.keymap.set('n', '<leader>ac', function()
        _99.stop_all_requests()
      end, { desc = 'AI: stop all requests' })

      vim.keymap.set('n', '<leader>am', function()
        require('99.extensions.telescope').select_model()
      end, { desc = 'AI: select model' })

      vim.keymap.set('n', '<leader>ap', function()
        require('99.extensions.telescope').select_provider()
      end, { desc = 'AI: select provider' })

      vim.keymap.set('n', '<leader>al', function()
        _99.view_logs()
      end, { desc = 'AI: view request logs' })

      vim.keymap.set('n', '<leader>ar', function()
        _99.open()
      end, { desc = 'AI: reopen past request results' })
    end,
  },
}
