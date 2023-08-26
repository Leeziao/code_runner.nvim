local Task = require('code_runner.tasklist.task')
local utils = require('code_runner.utils')

---@class TaskList
---@field tasks Task[]
---@field winnr number
local TaskManager = {
  tasks = {},
  task_lines = {}, -- { { startline = 3, endline = 5, task_id = 1 }, ... }
  toggle_preview = false,
}

---@return Task
function TaskManager.create_task(o)
  local opts = {
    name = o.name,
    cmd = { vim.o.shell, '-c', o.cmd and o.cmd or o.name },
    task_id = #TaskManager.tasks + 1,
    tasklist = TaskManager,
  }

  local task = Task:new(opts)
  table.insert(TaskManager.tasks, task)

  return task
end

function TaskManager.is_tasklist_win_valid()
  if TaskManager.winnr and vim.api.nvim_win_is_valid(TaskManager.winnr) then
    return true
  end
  return false
end

function TaskManager.is_preview_win_valid()
  if TaskManager.preview_winnr and vim.api.nvim_win_is_valid(TaskManager.preview_winnr) then
    return true
  end
  return false
end

function TaskManager.close_preview_win()
  if TaskManager.is_preview_win_valid() then
    vim.api.nvim_win_close(TaskManager.preview_winnr, true)
    TaskManager.preview_winnr = nil
    TaskManager.preview_bufnr = nil
  end
end

function TaskManager.open_preview_win()
  local task_id = TaskManager.get_preview_task_id()
  if not task_id then
    TaskManager.close_preview_win()
    return
  end

  if TaskManager.is_preview_win_valid() then
    TaskManager.render_preview_win(task_id)
    return
  end

  local padding = 2
  local win_width = vim.api.nvim_win_get_width(TaskManager.winnr)

  if win_width == utils.get_editor_width() then
    vim.cmd.new({
      mods = {
        vertical = true,
        noautocmd = true,
        split = 'botright',
      },
    })
    TaskManager.preview_bufnr, TaskManager.preview_winnr = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(TaskManager.winnr)

    win_width = math.floor(math.min(win_width * 0.4, 50))
    vim.api.nvim_win_set_width(TaskManager.winnr, win_width)
  else
    local row = 1
    local col = win_width + padding
    local width = utils.get_editor_width() - win_width - padding * 2
    local height = utils.get_editor_height() - padding * 2

    TaskManager.preview_bufnr = vim.api.nvim_create_buf(false, true)
    TaskManager.preview_winnr = vim.api.nvim_open_win(TaskManager.preview_bufnr, false, {
      relative = 'editor',
      width = width,
      height = height,
      row = row,
      col = col,
      style = 'minimal',
      border = 'rounded',
      noautocmd = true,
    })
  end

  local default_opts = {
    listchars = 'tab:> ',
    winfixwidth = true,
    winfixheight = true,
    number = false,
    signcolumn = 'no',
    foldcolumn = '0',
    relativenumber = false,
    wrap = false,
    spell = false,
  }
  for k, v in pairs(default_opts) do
    vim.api.nvim_set_option_value(k, v, { scope = 'local', win = TaskManager.preview_winnr })
  end

  vim.bo[TaskManager.preview_bufnr].filetype = 'CodeRunnerTaskPreview'
  vim.bo[TaskManager.preview_bufnr].buftype = 'nofile'
  vim.bo[TaskManager.preview_bufnr].bufhidden = 'wipe'
  vim.bo[TaskManager.preview_bufnr].swapfile = false
  vim.bo[TaskManager.preview_bufnr].buflisted = false
  vim.bo[TaskManager.preview_bufnr].modifiable = false

  vim.api.nvim_create_autocmd({ 'BufHidden', 'WinLeave' }, {
    desc = 'Close Preview Window',
    buffer = TaskManager.preview_bufnr,
    callback = function()
      TaskManager.close_preview_win()
    end,
  })

  TaskManager.render_preview_win(task_id)
end

function TaskManager.get_preview_task_id()
  local id
  local row, _ = unpack(vim.api.nvim_win_get_cursor(TaskManager.winnr))
  for _, item in ipairs(TaskManager.task_lines) do
    if row > item.startline and row <= item.endline then
      id = item.task_id
      break
    end
  end

  return id
end

function TaskManager.open_tasklist_win()
  if TaskManager.is_tasklist_win_valid() then
    TaskManager.render_tasklist_win()
    return
  end

  vim.cmd.new({
    mods = {
      vertical = true,
      noautocmd = true,
      split = 'topleft',
    },
  })
  TaskManager.bufnr, TaskManager.winnr = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()

  -- set window width
  local editor_width = utils.get_editor_width()
  local window_width = math.floor(math.min(editor_width * 0.4, 50))
  vim.api.nvim_win_set_width(TaskManager.winnr, window_width)

  local default_opts = {
    listchars = 'tab:> ',
    winfixwidth = true,
    winfixheight = true,
    number = false,
    signcolumn = 'no',
    foldcolumn = '0',
    relativenumber = false,
    wrap = false,
    spell = false,
  }
  for k, v in pairs(default_opts) do
    vim.api.nvim_set_option_value(k, v, { scope = 'local', win = 0 })
  end

  vim.bo[TaskManager.bufnr].filetype = 'CodeRunnerTaskList'
  vim.bo[TaskManager.bufnr].buftype = 'nofile'
  vim.bo[TaskManager.bufnr].bufhidden = 'wipe'
  vim.bo[TaskManager.bufnr].swapfile = false
  vim.bo[TaskManager.bufnr].buflisted = false
  vim.bo[TaskManager.bufnr].modifiable = false

  vim.api.nvim_create_autocmd({ 'BufHidden', 'WinLeave' }, {
    desc = 'Close Preview Window',
    buffer = TaskManager.bufnr,
    callback = function()
      TaskManager.close_preview_win()
    end,
  })
  vim.api.nvim_create_autocmd('CursorMoved', {
    desc = 'Change Preview Task Item',
    buffer = TaskManager.bufnr,
    callback = function()
      if TaskManager.toggle_preview then
        TaskManager.open_preview_win()
      end
    end,
  })

  vim.keymap.set('n', 'p', function()
    TaskManager.toggle_preview = not TaskManager.toggle_preview
    if TaskManager.toggle_preview then
      TaskManager.open_preview_win()
    else
      TaskManager.close_preview_win()
    end
  end, { buffer = TaskManager.bufnr, desc = 'Toggle Task Preview' })

  TaskManager.render_tasklist_win()
end

function TaskManager.render_preview_win(id)
  if not TaskManager.is_preview_win_valid() then
    return
  end

  if #TaskManager.task_lines == 0 then
    return
  end

  vim.bo[TaskManager.preview_bufnr].modifiable = true

  local lines, highlights = {}, {}
  local task = TaskManager.tasks[id]
  task:render_preview_win(lines, highlights, TaskManager.preview_winnr)

  vim.api.nvim_buf_set_lines(TaskManager.preview_bufnr, 0, -1, true, lines)
  for _, hl in ipairs(highlights) do
    local group, lnum, col_start, col_end = unpack(hl)
    vim.api.nvim_buf_add_highlight(TaskManager.preview_bufnr, 0, group, lnum, col_start, col_end)
  end

  vim.bo[TaskManager.bufnr].modifiable = false
end

function TaskManager.render_tasklist_win()
  if not TaskManager.is_tasklist_win_valid() then
    return
  end

  vim.bo[TaskManager.bufnr].modifiable = true

  local window_width = vim.api.nvim_win_get_width(TaskManager.winnr)

  local lines, highlights = {}, {}
  vim.list_extend(lines, {'Code Runner Task List', ''})
  table.insert(highlights, { 'CodeRunnerTitle', 0, 0, -1 })

  TaskManager.task_lines = {}
  for i = #TaskManager.tasks, 1, -1 do
    local task = TaskManager.tasks[i]
    local startline = #lines
    task:render_tasklist_win(lines, highlights)
    local endline = #lines

    TaskManager.task_lines[#TaskManager.task_lines + 1] = {
      startline = startline,
      endline = endline,
      task_id = i,
    }

    if i > 1 then
      utils.render_seperate_line(lines, highlights, window_width)
    end
  end

  vim.api.nvim_buf_set_lines(TaskManager.bufnr, 0, -1, true, lines)
  for _, hl in ipairs(highlights) do
    local group, lnum, col_start, col_end = unpack(hl)
    vim.api.nvim_buf_add_highlight(TaskManager.bufnr, 0, group, lnum, col_start, col_end)
  end
  vim.bo[TaskManager.bufnr].modifiable = false
end

return TaskManager
