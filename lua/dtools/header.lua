local util = require("dtools.util")

local M = {}

function M.insert_header_guard()
  local bufname = vim.api.nvim_buf_get_name(0)
  local filename = util.get_filename(bufname)
  local guardname = util.splitstr(filename, ".")[1] or ""

  guardname = string.upper(guardname) .. "_H"

  vim.api.nvim_buf_set_lines(0, 0, 0, true, { "#ifndef " .. guardname })
  vim.api.nvim_buf_set_lines(0, 1, 1, true, { "#define " .. guardname })
  vim.api.nvim_buf_set_lines(0, -1, -1, true, { "#endif //" .. guardname })
end

return M
