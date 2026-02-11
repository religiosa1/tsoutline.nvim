---@class TsOutlineConfig
---@field default_lsp_symbols string[] type of LSP symbols to show in a fallback implementation
---@field fallback_picker_title string title of the fallback LSP picker
---@field ts_picker_title string title of the TreeSitter picker
---@field languages table<string, TsOutlineLangSpec> map of neovim filetypes to tree-sitter queries per language

---@class TsOutlineLangSpec
---@field language string? treesitter language name, defaults to the result returned by vim.treesitter.language.get_lang()
---@field query string treesitter query for the language

local typescript_query = require("tsoutline/langs/typescript")
local javascript_query = require("tsoutline/langs/javascript")

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
    }
  }
end

return M
