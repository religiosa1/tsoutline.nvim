local configModule = require("tsoutline/config")
local outline = require("tsoutline/outline")

local M = {}

---@param opts? TsOutlineConfig | {}
function M.tsoutline(opts)
  opts = vim.tbl_deep_extend("force", configModule.default(), opts or {})

  local ft = vim.bo.filetype

  local language = opts.languages[ft]
  local treesitter_language_name = (language and language.language) or vim.treesitter.language.get_lang(ft)
  if language.query and not treesitter_language_name then
    vim.notify(
      "There's a treesitter query for the outline, but not treesitter language was determined. Is the language registered in tree sitter? Falling back to LSP",
      "warn")
  end
  if language.query and treesitter_language_name then
    return Snacks.picker({
      title = opts.ts_picker_title,
      items = outline(treesitter_language_name, language.query),
      format = "lsp_symbol",
      tree = true,
      auto_confirm = false,
      show_empty = true,
      jump = { tagstack = true, reuse_win = true },
    })
  else
    local filter = opts.lsp_symbol_types[ft] or opts.default_lsp_symbols
    Snacks.picker.lsp_symbols({
      title = opts.fallback_picker_title,
      filter = { default = filter },
    })
  end
end

---@param opts TsOutlineConfig | {}
function M.setup(opts)
  vim.api.nvim_create_user_command("TsOutline", function()
    M.tsoutline(opts)
  end, {})
end

return M
