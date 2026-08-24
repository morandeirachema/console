-- Pin nvim-treesitter to `master`.
--
-- Upstream made `main` (the parser-API rewrite) the default branch, and `main`
-- drops `lua/nvim-treesitter/configs.lua`. LazyVim v14 still does
-- `require("nvim-treesitter.configs")`, so without an explicit branch here
-- lazy.nvim follows the new default on the next `:Lazy update` and treesitter
-- + textobjects fail to configure. Remove this file when moving to LazyVim v15+,
-- which targets the `main` API.
return {
  { "nvim-treesitter/nvim-treesitter", branch = "master" },
  { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
}
