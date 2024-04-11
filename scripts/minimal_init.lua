vim.opt.runtimepath:append(vim.env.NVIM_PLENARY)
vim.opt.runtimepath:append(vim.env.NVIM_TREESITTER)
vim.opt.runtimepath:append(vim.env.NVIM_TREESITTER_TEXTOBJECTS)
vim.opt.runtimepath:append(vim.env.NVIM_TREESITTER_PARSER)

vim.cmd.runtime({ "plugin/plenary.vim", bang = true })
vim.cmd.runtime({ "plugin/nvim-treesitter.lua", bang = true })
vim.cmd.runtime({ "plugin/nvim-treesitter-textobjects.lua", bang = true })

local Path = require("plenary.path")

local project_root =  Path:new(".") -- FIXME: relies on current working directory

vim.filetype.add({
  extension = {
    bp = "bp",
  },
})

vim.o.swapfile = false
vim.bo.swapfile = false

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.bp = {
  install_info = {
    url = project_root.filename,
    files = {"src/parser.c"},
  },
}

require("nvim-treesitter.configs").setup({
  indent = { enable = true },
  highlight = { enable = true },
})

-- We need a hierarchy of `queries/bp/*.scm` in the runtimepath, otherwise
-- `nvim-treesitter` doesn't enable some of its features (e.g: folding).
-- The dummy plugin has a symlink following that format for our queries.
local dummy_plugin_path = project_root / "scripts" / "dummy_plugin"
vim.opt.runtimepath:append(dummy_plugin_path.filename)
