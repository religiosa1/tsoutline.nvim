---@class TsOutlineConfig
---@field default_lsp_symbols string[] type of LSP symbols to show in a fallback implementation
---@field fallback_picker_title string title of the fallback LSP picker
---@field ts_picker_title string title of the TreeSitter picker
---@field languages table<string, string> map of tree-sitter queries per language

local typescript_query = require("tsoutline/langs/typescript")

local M = {}

--- Returns the default opts config object
---@return TsOutlineConfig
function M.default()
  ---@type TsOutlineConfig
  return {
    default_lsp_symbols = { "Class", "Function", "Method", "Constructor", "Enum" },
    fallback_picker_title = "Outline (LSP)",
    ts_picker_title = "Outline (treesitter)",
    languages = {
      typescript = typescript_query,
      typescriptreact = typescript_query,
    }
  }
end

return M
