local M = {}
local code_runner = require('code_runner.runner')
local config = require('code_runner.config')

local api = vim.api
local create_command = api.nvim_create_user_command

local function setup_commands()
  create_command('CodeRunnerRun', function(opts)
    code_runner.run_code(opts)
  end, { nargs = '?' })
  create_command('CodeRunnerAutoRun', function()
    code_runner.auto_run_code()
  end, {})
  create_command('CodeRunnerHistory', function()
    code_runner.task_list()
  end, {})
end

local function setup_hl(opts)
  api.nvim_set_hl(0, 'CodeRunnerStatus', { bold = false, fg = 'blue', default = true })
  api.nvim_set_hl(0, 'CodeRunnerTitle', { bold = true, italic = true, fg = 'violet', default = true })

  api.nvim_set_hl(0, 'CodeRunnerStatus', { bold = false, fg = 'blue', default = true })
  api.nvim_set_hl(0, 'CodeRunnerCmd', { bold = true, fg = 'orange', default = true })
  api.nvim_set_hl(0, 'CodeRunnerFinished', { bold = true, fg = 'orange', default = true })
  api.nvim_set_hl(0, 'CodeRunnerDate', { bold = true, fg = 'violet', default = true })
  api.nvim_set_hl(0, 'CodeRunnerFile', { underline = true, fg = 'green', default = true })
  api.nvim_set_hl(0, 'CodeRunnerPos', { bold = true, fg = 'green', default = true })

  api.nvim_set_hl(0, "CodeRunnerSUCCESS", { link = "DiagnosticOk", default = true })
  api.nvim_set_hl(0, "CodeRunnerRUNNING", { link = "DiagnosticInfo", default = true })
  api.nvim_set_hl(0, "CodeRunnerCANCELED", { link = "DiagnosticWarn", default = true })
  api.nvim_set_hl(0, "CodeRunnerFAILURE", { link = "DiagnosticError", default = true })

  api.nvim_set_hl(0, 'CodeRunnerSTDOUT', { bold = true, fg = 'green', default = true })
  api.nvim_set_hl(0, 'CodeRunnerSTDERR', { bold = true, fg = 'red', default = true })
end

M.setup = function(opts)
  opts = opts or {}
  config.setup(opts)
  setup_commands()
  setup_hl(opts)
end

return M
