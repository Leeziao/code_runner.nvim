local tasklist = require('code_runner.tasklist')
local config = require('code_runner.config')
local utils = require('code_runner.utils')

local uv, api, lsp = vim.uv, vim.api, vim.lsp

local function run_cmd(input)
  if not input or #input == 0 then
    return
  end

  local task = tasklist.create_task({ name = input })

  task:run()
end

local function run_code(opts)
  local cmd = opts and opts.args or ''

  if cmd == '' then
    vim.ui.input({
      prompt = 'Code Runner',
    }, run_cmd)
  else
    run_cmd(cmd)
  end
end

local function auto_run()
  local current_buf = api.nvim_get_current_buf()
  local filetype = api.nvim_buf_get_option(current_buf, 'filetype')

  local matched_launcher = {}
  for _, laucher in ipairs(config.launchers) do
    if type(laucher.pattern) == 'function' then
      if laucher.pattern(filetype) then
        table.insert(matched_launcher, laucher)
      end
    elseif type(laucher.pattern) == 'string' then
      local pattern = '^' .. laucher.pattern .. '$'
      if filetype:match(pattern) then
        table.insert(matched_launcher, laucher)
      end
    end
  end

  local run_item = function(item)
    local cmd = utils.parse_command(item.cmd)
    local task = tasklist.create_task({
      name = item.name,
      cmd = cmd,
    })
    task:run()
  end

  if #matched_launcher == 0 then
    run_code()
  elseif #matched_launcher == 1 then
    run_item(matched_launcher[1])
  else
    table.insert(matched_launcher, { name = 'Enter Command' })
    vim.ui.select(matched_launcher, {
      prompt = 'Code Runner',
      format_item = function(item)
        return item.name and item.name or item.cmd
      end,
    }, function(item)
      if item.name ~= 'Enter Command' then
        run_item(item)
      else
        run_code()
      end
    end)
  end
end

return {
  run_code = run_code,
  auto_run_code = auto_run,
  task_list = tasklist.open_tasklist_win,
}
