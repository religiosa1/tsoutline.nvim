# Tree-Sitter Outline Snacks Picker neovim.

Code outline [snacks](https://github.com/folke/snacks.nvim) picker for
typescript/javascript for neovim.

## The problem

Built-in lsp_symbols picker is a bless to quickly navigate around the code in
some languages (for example in Lua).

In typescript (or to lesser extent in javascript), not so much, as it:

- shows extra noise, such as every lambda fuction inside of maps/filter/reduces,
  every field on every object, every property of every interface, etc.
- doesn't show nearly enough at the same time, as it misses top level constants,
  which leaves out the popular pattern of assigning arrow functions to a const
  like this:

```ts
export const foo = () => {
	/* do something here */
};
```

Though the first issue can **partially** be addressed with a filter on what
kind of lsp_symbols, the solution for me is just to get the parts we're
really interested in with a tree-sitter query, falling back to filtered LSP
symbols for languages without the Tree-Sitter query.

## Installation (Lazy)

```lua
{
  "religiosa1/tsoutline.nvim",
  -- most likely you don't need this, as I assume snacks is already configured
  dependencies = { "folke/snacks.nvim" },
  opts = { },
  keys = {
    {
      "<Leader>sf",
      "<cmd>TsOutline<cr>",
      desc = "T-S outline",
      mode = { "n" },
    },
  },
}
```

## Languages and limitations

Currently only supports ts and js, but extra languages can be added with an
appropriate TS query in the config.

For ts/js it only supports ESM export syntax, not CommonJS export.

Enums are not yet supported in typescript

## Configuration

For the list of configuration options and their default values, see
[config.lua](./lua/tsoutline/config.lua)

## License

tsoutline.nvim is MIT licensed.
