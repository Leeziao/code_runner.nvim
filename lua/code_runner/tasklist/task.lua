local uv, api, lsp = vim.uv, vim.api, vim.lsp
local utils = require('code_runner.utils')
local window = require('code_runner.tasklist.window')

-- local ns = api.nvim_create_namespace('code_runner')

---@class Task
---@field cmd string[]
---@field name string
---@field status string
---@field sysobj SystemObj
---@field result SystemCompleted|nil
---@field begin_time number
---@field end_time number
---@field running table
---@field tasklist TaskList
local Task = {}

function Task:new(o)
  setmetatable(o, self)
  self.__index = self
  o.running = {
    stdout = '',
    stderr = '',
  }
  return o
end

function Task:update_status(status)
  self.status = status
  self.tasklist.render_tasklist_win()
end

function Task:render_tasklist_win(lines, highlights)
  vim.validate({
    lines = { lines, 'table', false },
    highlights = { highlights, 'table', false },
  })

  local status_str = '[' .. self.status .. '] '
  local name_str = self.name

  table.insert(lines, status_str .. name_str)
  table.insert(highlights, { 'CodeRunner' .. self.status, #lines - 1, 0, #status_str })
  table.insert(highlights, { 'CodeRunnerCmd', #lines - 1, #status_str, -1 })
end

function Task:render_preview_win(lines, highlights, winnr)
  vim.validate({
    lines = { lines, 'table', false },
    highlights = { highlights, 'table', false },
  })

  -- first line: [STATUS] cmd
  local status_str = '[' .. self.status .. '] '
  local name_str = self.name
  local cmd_str = self.cmd[#self.cmd]

  table.insert(lines, status_str .. name_str .. ' (' .. cmd_str .. ')')
  table.insert(highlights, { 'CodeRunner' .. self.status, #lines - 1, 0, #status_str })
  table.insert(highlights, { 'CodeRunnerCmd', #lines - 1, #status_str, -1 })

  if self.status == 'RUNNING' then
    return
  end

  -- second line: exit code=0, duration=0.00s
  self:render_finish_line(lines, highlights)

  -- third line: a seperation line
  local window_width = vim.api.nvim_win_get_width(winnr)
  utils.render_seperate_line(lines, highlights, window_width)

  local sources = { 'stdout', 'stderr' }
  for _, s in ipairs(sources) do
    table.insert(lines, '[' .. s:upper() .. ']')
    table.insert(highlights, { 'CodeRunner' .. s, #lines - 1, 0, -1 })

    local data = vim.split(self.result[s], '\n')
    vim.list_extend(lines, data)
  end
end

function Task:render_finish_line(lines, highlights)
  assert(self.result)

  local duration = (self.end_time - self.begin_time) / 1e9

  -- local finish_at = os.date('%H:%M:%S')
  local segments = {
    '[Done]',
    ' exited with ',
    'code=' .. tostring(self.result.code),
    ' in ',
    string.format('%.2f', duration),
    ' seconds',
  }

  -- join lines to a string
  local concat_line = ''
  for _, seg in ipairs(segments) do
    concat_line = concat_line .. seg
  end

  vim.list_extend(highlights, {
    { 'CodeRunnerStatus', #lines, 0, #segments[1] },
    {
      'CodeRunnerFinished',
      #lines,
      #segments[1] + #segments[2],
      #segments[1] + #segments[2] + #segments[3],
    },
    {
      'CodeRunnerDate',
      #lines,
      #segments[1] + #segments[2] + #segments[3] + #segments[4],
      #segments[1] + #segments[2] + #segments[3] + #segments[4] + #segments[5],
    },
  })
  table.insert(lines, concat_line)
end

---@param data string
---@param task Task
local function update_buf(task, data)
  vim.schedule(function()
    local taskrun = window.get_or_create_taskrun()
    local lines = vim.split(data, '\n')
    if #lines < 1 then
      return
    end

    vim.bo[taskrun.bufnr].modifiable = true

    local first_line, rest_lines = lines[1], vim.list_slice(lines, 2, #lines)
    local old_last_line = api.nvim_buf_get_lines(taskrun.bufnr, -2, -1, false)[1]
    local new_last_line = old_last_line .. first_line

    lines = vim.list_extend({ new_last_line }, rest_lines)
    api.nvim_buf_set_lines(taskrun.bufnr, -2, -1, false, lines)

    -- auto scroll buffer
    api.nvim_win_call(taskrun.winnr, function()
      vim.cmd('normal! G')
    end)

    -- set file and position highlights
    local start = utils.get_win_last_line(taskrun.bufnr) - #lines
    local ranges = utils.has_file(lines, start)
    taskrun.range = vim.list_extend(taskrun.range or {}, ranges)
    if #ranges == 0 then
      return
    end

    for _, item in ipairs(ranges) do
      if item.file then
        api.nvim_buf_add_highlight(
          taskrun.bufnr,
          0,
          'CodeRunnerFile',
          item.file.line - 1,
          item.file.scol - 1,
          item.file.ecol
        )
      end
      if item.targetPos then
        api.nvim_buf_add_highlight(
          taskrun.bufnr,
          0,
          'CodeRunnerPos',
          item.targetPos.line - 1,
          item.targetPos.scol - 1,
          item.targetPos.ecol
        )
      end
    end

    vim.bo[taskrun.bufnr].modifiable = false
  end)
end

function Task:pre_run()
  local taskrun = window.get_or_create_taskrun()
  local last = utils.get_win_last_line(taskrun.bufnr)

  local status = '[Running] '
  local highlights = {
    { 'CodeRunnerStatus', last, 0, #status },
    { 'CodeRunnerCmd', last, #status, -1 },
  }

  vim.bo[taskrun.bufnr].modifiable = true
  api.nvim_buf_set_lines(
    taskrun.bufnr,
    last,
    -1,
    false,
    { status .. self.name .. ' (' .. self.cmd[#self.cmd] .. ')', '' }
  )

  for _, hl in ipairs(highlights) do
    local group, lnum, col_start, col_end = unpack(hl)
    api.nvim_buf_add_highlight(taskrun.bufnr, 0, group, lnum, col_start, col_end)
  end
  vim.bo[taskrun.bufnr].modifiable = false

  self.begin_time = uv.hrtime()
end

---@param obj table
function Task:post_run(obj)
  self.end_time = uv.hrtime()
  self.result.stdout = self.running.stdout
  self.result.stderr = self.running.stderr
  self.result.code = obj.code
  self.running = nil

  if obj.code == 0 then
    self:update_status('SUCCESS')
  else
    self:update_status('FAILURE')
  end

  local taskrun = window.get_or_create_taskrun()
  vim.bo[taskrun.bufnr].modifiable = true

  local lines, highlights = {}, {}
  self:render_finish_line(lines, highlights)
  table.insert(lines, '')

  local last = utils.get_win_last_line(taskrun.bufnr)
  api.nvim_buf_set_lines(taskrun.bufnr, -1, -1, false, lines)
  for _, hl in ipairs(highlights) do
    local group, _, col_start, col_end = unpack(hl)
    api.nvim_buf_add_highlight(taskrun.bufnr, 0, group, last, col_start, col_end)
  end

  vim.bo[taskrun.bufnr].modifiable = false
  api.nvim_win_call(taskrun.winnr, function()
    vim.cmd('normal! G')
  end)
end

function Task:run()
  self:pre_run()
  self:update_status('RUNNING')

  self.sysobj = vim.system(self.cmd, {
    stdout = function(_, data)
      if not data or type(data) ~= 'string' or #data == 0 then
        return
      end
      self.running.stdout = self.running.stdout .. data
      update_buf(self, data)
    end,
    stderr = function(_, data)
      if not data or type(data) ~= 'string' or #data == 0 then
        return
      end
      self.running.stderr = self.running.stderr .. data
      update_buf(self, data)
    end,
  }, function(obj)
    self.result = obj
    vim.schedule(function()
      self:post_run(obj)
    end)
  end)
end

return Task
