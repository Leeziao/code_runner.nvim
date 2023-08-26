local api = vim.api

local M = {}

M.has_file = function(lines, start)
  local f_pattern = '([%w/%._\\:-]+%.%w+)'
  local pos_pattern = '%d+:%d+'
  local range = {}
  for i, line in ipairs(lines) do
    local tmp = {}
    local spos, epos = line:find(f_pattern)
    if spos then
      tmp.file = { line = start + i, scol = spos, ecol = epos }
    end

    spos, epos = line:find(pos_pattern)
    if spos then
      tmp.targetPos = {
        line = start + i,
        scol = spos,
        ecol = epos,
      }
    end
    if vim.tbl_count(tmp) > 0 then
      range[#range + 1] = tmp
    end
  end
  return range
end

M.render_seperate_line = function(lines, highlights, window_width)
  table.insert(lines, string.rep('─', window_width))
  table.insert(highlights, { 'CodeRunnerSeparator', #lines - 1, 0, -1 })
end

M.get_win_last_line = function(bufnr)
  local last = api.nvim_buf_line_count(bufnr)
  if last == 1 and #api.nvim_buf_get_lines(bufnr, 0, -1, false)[1] == 0 then
    last = 0
  end
  return last
end

M.get_editor_height = function()
  local editor_height = vim.o.lines - vim.o.cmdheight

  -- Subtract 1 if tabline is visible
  if vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1) then
    editor_height = editor_height - 1
  end

  -- Subtract 1 if statusline is visible
  if vim.o.laststatus >= 2 or (vim.o.laststatus == 1 and #vim.api.nvim_tabpage_list_wins(0) > 1) then
    editor_height = editor_height - 1
  end
  return editor_height
end

M.get_editor_width = function()
  local editor_width = vim.o.columns
  return editor_width
end

---@param cmd string|function
M.parse_command = function (cmd)
  if type(cmd) == 'function' then
    return cmd()
  end

  local filename = vim.fn.expand('%:t')

  if not cmd:find('%$') and cmd:sub(-1) ~= ' ' then
    return cmd .. ' ' .. filename
  end

  local filename_without_extension = vim.fn.expand('%:t:r')
  local dir = vim.fn.expand('%:p:h') .. '/'

  cmd = cmd:gsub('%$fileNameWithoutExt', filename_without_extension)
  cmd = cmd:gsub('%$fileName', filename)
  cmd = cmd:gsub('%$dir', dir)

  return cmd
end

return M
