local configModule = require("tsoutline/config")
local outline = require("tsoutline/outline")

local M = {}

---@param opts? TsOutlineConfig | {}
function M.tsoutline(opts)
  opts = vim.tbl_deep_extend("force", configModule.default(), opts or {})

  local ft = vim.bo.filetype

  local language_query = opts.languages[ft]
  if language_query then
    return Snacks.picker({
      title = opts.ts_picker_title,
      items = outline(ft, language_query),
      format = "lsp_symbol",
      tree = true,
      auto_confirm = false,
      show_empty = true,
      jump = { tagstack = true, reuse_win = true },
    })
  else
    Snacks.picker.lsp_symbols({
      title = opts.fallback_picker_title,
      filter = { default = opts.default_lsp_symbols },
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
