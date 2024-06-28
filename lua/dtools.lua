local util = require("dtools.util")
local criterion = require("dtools.criterion")

---@class DtoolsOptions
---@field builddir (fun(buf: integer): string)?
---@field additional_args (fun(buf: integer): string[])?

local M = {
  test_exe = "",
  test_suite = "",
  test_name = "",
  ---@type DtoolsOptions
  options = {},
}

---Start a debug server in a new process to debug the test closest to the current line that was found by calling dtools.debug_test()
---Returns the connection string to the debug server (e.g. localhost:1234) or nil and an optional error message
---@return string | nil, string | nil
function M.start_debug_server()
  if M.test_exe == "" or M.test_suite == "" or M.test_name == "" then
    return nil, "Error: Need to call dtools.debug_test() first"
  end

  local pid = criterion.start_debug_server(M.test_exe, M.test_suite, M.test_name)
  if pid <= 0 then
    return nil, "Failed to start debug server"
  end

  print("Starting debug server")
  return M.test_exe, nil
end

---Debug the test under the cursor
---This is the pimary API for starting a debug session and must be called at least once.
---When this function is called, the module will try to find the test executable that implements the test under the cursor.
---An input list will be shown if there are multiple options.
---Next it finds the name of the suite and test closest to the cursor.
---All metadata is stored in the module before it automatically calls `dap.continue`.
---At this point dap takes over to start the debug session.
---NOTE: You can repeat the previous debug session by calling dap.continue manually.
---@return boolean, string | nil
function M.debug_test()
  M.test_exe = ""
  M.test_suite = ""
  M.test_name = ""

  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win() -- Get the current active window
  local cursor_pos = vim.api.nvim_win_get_cursor(win) -- Get the cursor position in the window

  local line = criterion.get_nearest_test(bufnr, cursor_pos)
  if line == "" then
    return false, "No test to run"
  end

  local builddir = M.options.builddir and M.options.builddir(bufnr) or "build"
  local test_exe = util.get_test_exe_from_buffer(bufnr, builddir)

  if test_exe == nil then
    return false, "No test executable was found in " .. builddir
  end

  local test = criterion.get_test_suite_and_name(line)
  if test == nil then
    return false, "Failed to parse test suite and name"
  end

  if #test_exe == 1 then
    M.test_exe = test_exe[1]
    M.test_name = test.test_name
    M.test_suite = test.test_suite
    require("dap").continue()
  else
    vim.ui.select(test_exe, {
      prompt = "Multiple tests available, please select:",
      format_item = function(item)
        return util.get_filename(item)
      end,
    }, function(choice)
      M.test_exe = choice
      M.test_name = test.test_name
      M.test_suite = test.test_suite
      require("dap").continue()
    end)
  end

  return true
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
