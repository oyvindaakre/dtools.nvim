local util = require("dtools.util")
local Job = require("plenary.job")

local M = {}

---Parse a test declaration to get the name of the suite and test
---This function assumes the Criterion unit test framework
---Expected input is one of
--- ParameterizedTest(struct param_type* param, test_suite, test_name...)
--- Test(test_suite, test_name, ...)
---Returns the test suite and name in a table
---@param line string
---@return table | nil
function M.get_test_suite_and_name(line)
  local parts = util.splitstr(line, ")")
  if parts[1] == nil then
    return nil
  end

  parts = util.splitstr(parts[1], "(")
  if parts[1] == nil then
    return nil
  end

  local index = 1

  if vim.startswith(parts[1], "ParameterizedTest") then
    index = 2 -- Skip over param
  end

  parts = util.splitstr(parts[2], ",")
  if not parts[index] or not parts[index + 1] then
    return nil
  end
  return {
    test_suite = string.gsub(parts[index], "%s+", ""), -- Trim whitespace
    test_name = string.gsub(parts[index + 1], "%s+", ""),
  }
end

---Try to find the test definition closest to the cursor position.
---This function assumes the Criterion unit test framework.
---In this context 'nearest' is the first definition found when searching toward the start of the file.
---If the cursor is on or within a function then this function's name is returned, otherwise search "up"
---for next possible match.
---@param bufnr integer
---@param cursor_pos integer[]
---@return string
function M.get_nearest_test(bufnr, cursor_pos)
  for pos = cursor_pos[1], 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, pos - 1, pos, true)[1]
    if vim.startswith(line, "Test(") or vim.startswith(line, "ParameterizedTest(") then
      return line
    end
  end
  return ""
end

---Make the arguments to pass to the test executable
---@param test_suite string | nil
---@param test_name string | nil
---@param additional_args string[]
---@return table
function M.make_test_args(test_suite, test_name, additional_arg)
  local test_args = {}

  ---We pass --filter=test_suite/test_name to run the named test under the named suite (or all if not specified)
  local ts = test_suite or "*"
  local tn = test_name or "*"
  local test_to_run = "--filter=" .. ts .. "/" .. tn
  table.insert(test_args, test_to_run)

  ---We pass --json to enable test results as a JSON document
  table.insert(test_args, "--json")

  ---Insert user arguments if any
  test_args = vim.list_extend(test_args, additional_args)
  return test_args
end

---Locate the line number with the error from the given error message
---Example: /some/path/to/test_module.c:42:
---@param msg string
---@return integer | nil
function M.locate_error(msg)
  local s = util.splitstr(msg, ":")
  if s[2] then
    return tonumber(s[2])
  end
end

---Start a debug server in a new process that listens to localhost:1234
---@param test_exe string Path to executable
---@param test_suite string Name of test suite
---@param test_name string Name of test
---@return integer
function M.start_debug_server(test_exe, test_suite, test_name)
  local test_args = {}
  local ts = test_suite or "*"
  local tn = test_name or "*"
  local test_to_run = "--filter=" .. ts .. "/" .. tn
  table.insert(test_args, test_to_run)
  table.insert(test_args, "--debug")

  local retval = -1

  local job = Job:new({
    command = test_exe,
    args = test_args,
    on_stdout = function(_, data)
      print(data)
    end,
    on_stderr = function(_, data)
      print(data)
    end,
    on_exit = function(_, return_val) end,
  })
  job:start()

  return job.pid
end
return M
