-- This file is used to define the dependencies of this plugin when the user is
-- using lazy.nvim.
--
-- If you are curious about how exactly the plugins are used, you can use e.g.
-- the search functionality on Github.
--
-- https://lazy.folke.io/packages#lazy

---@module "lazy"
---@module "tsoutline"

---@type LazySpec
return {
  { "folke/snacks.nvim",         opts = {} },
  { "religiosa1/tsoutline.nvim", opts = {}, cmd = "TsOutline" },
}
