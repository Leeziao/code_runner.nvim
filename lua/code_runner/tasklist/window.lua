local api = vim.api

local utils = require('code_runner.utils')

local M = {
  taskrun = { },
}

M.get_or_create_taskrun = function()
  if M.taskrun.winnr and vim.api.nvim_win_is_valid(M.taskrun.winnr) then
    return M.taskrun
  end

  vim.cmd('botright new')
  M.taskrun.bufnr, M.taskrun.winnr = api.nvim_get_current_buf(), api.nvim_get_current_win()

  local editor_height = utils.get_editor_height()
  local window_height = math.floor(math.min(editor_height * 0.4, 10))
  vim.api.nvim_win_set_height(M.taskrun.winnr, window_height)

  vim.bo[M.taskrun.bufnr].buftype = 'nofile'
  vim.bo[M.taskrun.bufnr].bufhidden = 'wipe'
  vim.bo[M.taskrun.bufnr].swapfile = false
  vim.bo[M.taskrun.bufnr].buflisted = false
  vim.bo[M.taskrun.bufnr].filetype = 'CodeRunner'
  vim.bo[M.taskrun.bufnr].modifiable = false

  vim.keymap.set('n', 'o', function()
    local row, col = unpack(api.nvim_win_get_cursor(M.taskrun.winnr))
    local items = vim
      .iter(M.taskrun.range)
      :filter(function(item)
        if item.file then
          local line, scol, ecol = item.file.line, item.file.scol, item.file.ecol
          return row == line and col >= scol - 1 and col <= ecol - 1
        end
      end)
      :totable()
    assert(#items <= 1)
    if #items == 0 then
      return
    end

    local item = items[1]
    local line, scol, ecol = item.file.line, item.file.scol, item.file.ecol
    local filename = api.nvim_buf_get_lines(M.taskrun.bufnr, line - 1, line, false)[1]
    filename = filename:sub(scol, ecol)

    vim.cmd([[vertical new]])
    vim.cmd.e(filename)

    if item.targetPos then
      local line, scol, ecol = item.targetPos.line, item.targetPos.scol, item.targetPos.ecol
      local pos = api.nvim_buf_get_lines(M.taskrun.bufnr, line - 1, line, false)[1]
      pos = pos:sub(scol, ecol)
      local lnum, lcol = pos:match('(%d+):(%d+)')
      api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(lcol) - 1 })
    end
  end, { buffer = M.taskrun.bufnr })

  return M.taskrun
end

return M
