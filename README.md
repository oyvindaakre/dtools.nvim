# dtools.nvim

This is my collection of develop and debug tools for working with projects using the `meson` build system and `Criterion` unit testing framework.

## Installation with lazy
```lua
return {
    "oyvindaakre/dtools.nvim",
}
```

## Configuration
Dynamically configure the build directory for the current open buffer with a custom function:
```lua
local dtools = require("dtools")({
    builddir = function(bufnr)
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if string.find(bufname, "some-important-dir") ~= nil then
            return "special/path/build"
        else
            return "build"
        end
    end,
})
```

## Example: Configuration for debugging a unit test
This configuration adds a new entry for debugging `.c`-files anmed "Debug unit test".
With this you should be able to place your cursor at or below the test function that you want to debug and when selecting the new configuration, a debug session will start for that particular function. 
```lua
--- Somewhere in your debug configuration
local dap = require("dap")

local dtools = require("dtools")({
    builddir = function(bufnr)
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if string.find(bufname, "some-important-dir") ~= nil then
            return "special/path/build"
        else
            return "build"
        end
    end,
})

--- Configure native GDB debug adapter
dap.adapters.gdb = {
    type = "executable",
    command = "gdb",
    args = { "-i", "dap" },
}

--- Add a configuration for debugging unit tests
local debug_unit_test = {
    name = "Debug unit test",
    type = "gdb",
    request = "attach",
    program = function()
        local _, err = dtools.start_debug_server()
        if err ~= nil then
            print(err)
            return nil
        end
        return dtools.get_executable_at_cursor()
    end,
    cwd = "${workspaceFolder}",
    stopAtBeginningOfMainSubprogram = true,
    target = "localhost:1234",
}
table.insert(dap.configurations["c"], debug_unit_test)
```
