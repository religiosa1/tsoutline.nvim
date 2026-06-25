# Tree-Sitter Outline Snacks Picker neovim.

Code outline [snacks](https://github.com/folke/snacks.nvim) picker for
typescript/javascript for neovim.

<img width="1890" height="1017" alt="image" src="https://github.com/user-attachments/assets/a4ff5d30-bc33-4aa3-ab4c-36a77a10a26d" />

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

## What it shows

### Tree-Sitter mode (TypeScript/JavaScript)

For languages with a Tree-Sitter query, the picker displays:

- Function declarations
- Arrow functions and function expressions assigned to `const` or `let/var` (shown as `foo()`)
- Root-level callbacks with string literal passed to caller (shown as `describe("arg") callback`)
- Classes
- Constructors, methods (shown as `name()`)
- Getters and setters (shown as `(get) name` / `(set) name`)
- Root-level constants

Items are displayed as a hierarchical tree, so class methods appear nested
under their class, etc. with the appropriate icon.

### LSP fallback (other languages)

For languages without a Tree-Sitter query, the plugin falls back to the
built-in LSP document symbols picker, filtered to show only: Class, Function,
Method, Constructor, and Enum symbols by default. This filter list is
configurable per language via `lsp_symbol_types` or globally via
`default_lsp_symbols`.

## Languages and limitations

Currently only supports ts and js, but extra languages can be added with an
appropriate TS query in the config.

For ts/js it only supports ESM export syntax, not CommonJS export.

## Configuration

For the list of configuration options and their default values, see
[config.lua](./lua/tsoutline/config.lua)

## Local development

If you want to extend or change TreeSitter definitions, first you need to figure
out the correct query. You can use `:InspectTree` for that.

Your query must capture `<type>.name` and `<type>.definition`, containing the
name and full definition of a thing you're trying to capture, where `<type>`
is one of `SymbolType` enum values (e.g. `function`, `class`, etc).

Once you have your query written you can verify it, by using `:EditQuery` in
a source file and pasting your query there -- it should find the thing you're
trying to get in tree-sitter.

See [ecmascript.lua](./lua/tsoutline/langs/ecmascript.lua) for an example.

## License

tsoutline.nvim is MIT licensed.
