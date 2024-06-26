package.path = package.path .. ";" .. vim.env.NVIM_TREESITTER .. "/?.lua"

local Runner = require("tests.indent.common").Runner
local XFAIL = require("tests.indent.common").XFAIL

-- FIXME: path to root
local runner = Runner:new(it, ".", {
    tabstop = 4,
    shiftwidth = 4,
    softtabstop = 0,
    expandtab = true,
})

describe("indent Blueprint:", function()
    describe("whole file:", function()
        runner:whole_file("test/highlight/", {
            expected_failures = {
                -- NOTE: none for now
            },
        })
        runner:whole_file("test/indent/", {
            expected_failures = {
                "test/indent/select.bp",
            },
        })
    end)

    describe("new line:", function()
        runner:new_line("test/indent/expressions.bp", { on_line = 2, text = "foo = 42", indent = 0 }, "variable declaration")
        runner:new_line("test/indent/expressions.bp", { on_line = 4, text = "0,", indent = 4 }, "list element")
        runner:new_line("test/indent/expressions.bp", { on_line = 6, text = "]", indent = 0 }, "list closing delimiter")
        runner:new_line("test/indent/expressions.bp", { on_line = 9, text = "key: 42", indent = 4 }, "map property")
        runner:new_line("test/indent/expressions.bp", { on_line = 12, text = "key: 42", indent = 4 }, "map property, trailing")
        runner:new_line("test/indent/expressions.bp", { on_line = 9, text = "}", indent = 0 }, "map closing delimiter")
        runner:new_line("test/indent/expressions.bp", { on_line = 11, text = "]", indent = 4 }, "nested list closing delimiter")
        runner:new_line("test/indent/expressions.bp", { on_line = 18, text = "key: 42", indent = 12 }, "nested map property")
        runner:new_line("test/indent/expressions.bp", { on_line = 19, text = "key: 42", indent = 12 }, "nested map property, trailing")

        runner:new_line("test/indent/select.bp", { on_line = 1, text = '"case": "value"', indent = 4 }, "select case")
        runner:new_line("test/indent/select.bp", { on_line = 1, text = 'default: "value"', indent = 4 }, "default case")
        runner:new_line("test/indent/select.bp", { on_line = 11, text = '"case": "value"', indent = 4 }, "select case, trailing")
        runner:new_line("test/indent/select.bp", { on_line = 11, text = 'default: "value"', indent = 4 }, "default case, trailing")
        runner:new_line("test/indent/select.bp", { on_line = 11, text = '}', indent = 0 }, "select cases closing delimiter")
        runner:new_line("test/indent/select.bp", { on_line = 27, text = ')', indent = 0 }, "select expression closing delimiter")
        runner:new_line("test/indent/select.bp", { on_line = 16, text = '"case": "value"', indent = 8 }, "select case, alternate formatting")
        runner:new_line("test/indent/select.bp", { on_line = 16, text = 'default: "value"', indent = 8 }, "default case, alternate formatting")
        runner:new_line("test/indent/select.bp", { on_line = 26, text = '"case": "value"', indent = 8 }, "select case, trailing, alternate formatting")
        runner:new_line("test/indent/select.bp", { on_line = 26, text = 'default: "value"', indent = 8 }, "default case, trailing, alternate formatting")
        runner:new_line("test/indent/select.bp", { on_line = 26, text = '}', indent = 4 }, "select cases closing delimiter, alternate formatting")
        runner:new_line("test/indent/select.bp", { on_line = 27, text = ')', indent = 0 }, "select expression closing delimiter, alternate formatting")
        runner:new_line("test/indent/select.bp", { on_line = 30, text = 'device()', indent = 4 }, "multi-valued select condition, begin")
        runner:new_line("test/indent/select.bp", { on_line = 31, text = 'device()', indent = 4 }, "multi-valued select condition, middle")
        runner:new_line("test/indent/select.bp", { on_line = 32, text = 'device()', indent = 4 }, "multi-valued select condition, end")
        runner:new_line("test/indent/select.bp", { on_line = 46, text = 'device()', indent = 8 }, "multi-valued select condition, begin, alternate formatting")
        runner:new_line("test/indent/select.bp", { on_line = 47, text = 'device()', indent = 8 }, "multi-valued select condition, middle, alternate formatting")
        runner:new_line("test/indent/select.bp", { on_line = 48, text = 'device()', indent = 8 }, "multi-valued select condition, end, alternate formatting")
        runner:new_line("test/indent/select.bp", { on_line = 56, text = 'default,', indent = 8 }, "multi-valued select case, begin", XFAIL)
        runner:new_line("test/indent/select.bp", { on_line = 57, text = 'default,', indent = 8 }, "multi-valued select case, middle", XFAIL)
        runner:new_line("test/indent/select.bp", { on_line = 58, text = 'default,', indent = 8 }, "multi-valued select case, end", XFAIL)
    end)
end)
