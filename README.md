# dtools.nvim

This is my collection of develop and debug tools for working with projects using the `meson` build system and `Criterion` unit testing framework.

## Installation with lazy
```lua
return {
    "oyvindaakre/dtools.nvim",
    dependencies = {
        "mfussenegger/nvim-dap",
    }
}
```

## Configuration
Dynamically set which build directory that belongs to the currently open buffer with a custom function:
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

    --- Add a keymap to run the plugin
    vim.keymap.set("n", "<leader>dt", dtools.debug_test, { desc = "[D]ebug: [T]est" })
})
```

## Example: Configuration for debugging a unit test
This configuration adds a new entry for debugging `.c`-files anmed "Debug unit test".
With this you should be able to place your cursor at or below the test function that you want to debug and 
when triggering `dtools.debug_test(), a debug session will start for that particular function.
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
    vim.keymap.set("n", "<leader>dt", dtools.debug_test, { desc = "[D]ebug: [T]est" })
})

--- Configure native GDB debug adapter
dap.adapters.gdb = {
    type = "executable",
    command = "gdb",
    args = { "-i", "dap" },
}

--- Add a configuration for debugging unit tests
--- Note that this is automatically called when you first call dtools.debug_test()
local debug_unit_test = {
    name = "Debug unit test",
    type = "gdb",
    request = "attach",
    program = function()
        local exe, err = dtools.start_debug_server()
        if err ~= nil then
            print(err)
            return nil
        end
        return exe 
    end,
    cwd = "${workspaceFolder}",
    stopAtBeginningOfMainSubprogram = true,
    target = "localhost:1234",
}
table.insert(dap.configurations["c"], debug_unit_test)
```
