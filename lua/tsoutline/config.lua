---@class TsOutlineConfig
---@field fallback_picker_title string title of the fallback LSP picker
---@field ts_picker_title string title of the TreeSitter picker
---@field languages table<string, TsOutlineLangSpec> map of neovim filetypes to tree-sitter queries per language
---@field lsp_symbol_types table<string, string[]> map of filetypes to LSP filters to use, if no query is provided
---@field default_lsp_symbols string[] type of LSP symbols to show in a fallback implementation, if no per language value is provided

---@class TsOutlineLangSpec
---@field language string? treesitter language name, defaults to the result returned by vim.treesitter.language.get_lang()
---@field query string treesitter query for the language

local ecmascript_query = require("tsoutline/langs/ecmascript")
local typescript_query = ecmascript_query({ is_js = false })
local javascript_query = ecmascript_query({ is_js = true })

local M = {}

--- Returns the default opts config object
---@return TsOutlineConfig
function M.default()
	---@type TsOutlineConfig
	return {
		fallback_picker_title = "Outline (LSP)",
		ts_picker_title = "Outline (treesitter)",
		languages = {
			typescript = {
				query = typescript_query,
			},
			typescriptreact = {
				query = typescript_query,
			},
			javascript = {
				query = javascript_query,
			},
			javascriptreact = {
				query = javascript_query,
			},
		},
		lsp_symbol_types = {},
		default_lsp_symbols = { "Class", "Function", "Method", "Constructor", "Enum", "Struct" },
	}
end

return M
