local util = require("dtools.util")
local criterion = require("dtools.criterion")

---@class DtoolsOptions
---@field builddir (fun(buf: integer): string)?
---@field additional_args (fun(buf: integer): string[])?

local M = {
  ---@type DtoolsOptions
  options = {},
}

---Start a debug server in a new process to debug the test closest to the current line
---Returns the connection string to the debug server (e.g. localhost:1234) or nil and an optional error message
---@return string | nil, string | nil
function M.start_debug_server()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win() -- Get the current active window
  local cursor_pos = vim.api.nvim_win_get_cursor(win) -- Get the cursor position in the window

  local line = criterion.get_nearest_test(bufnr, cursor_pos)
  if line == "" then
    return nil, "No test to run"
  end

  local builddir = M.options.builddir and M.options.builddir(bufnr) or "build"
  local test_exe = util.get_test_exe_from_buffer(bufnr, builddir)

  if test_exe == "" then
    return nil, "No test executable was found in " .. builddir
  end

  local test = criterion.get_test_suite_and_name(line)
  if test == nil then
    return nil, "Failed to parse test suite and name"
  end

  local pid = criterion.start_debug_server(test_exe, test.test_suite, test.test_name)
  if pid <= 0 then
    return nil, "Failed to start debug server"
  end

  return "localhost:1234", nil
end

---Get the test executable that implements the test closest to the cursor
---@return string | nil
function M.get_executable_at_cursor()
  local current_buffer = vim.api.nvim_get_current_buf()
  local builddir = M.options.builddir and M.options.builddir(current_buffer) or "build"
  local test_exe = util.get_test_exe_from_buffer(current_buffer, builddir)
  return test_exe
end

--- Plugin options
setmetatable(M, {
  ---@param opts DtoolsOptions
  __call = function(_, opts)
    M.options = opts
    return M
  end,
})

return M
