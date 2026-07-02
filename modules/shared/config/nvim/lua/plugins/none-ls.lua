-- Customize None-ls sources

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local h = require "null-ls.helpers"

    -- oxfmt (https://oxc.rs, nix package "oxfmt") doesn't have a none-ls
    -- builtin yet, so it's defined here the same way none-ls defines its
    -- own builtins. AstroNvim formats on save by default;
    -- Scoped to markdown only for now.
    local oxfmt = h.make_builtin {
      name = "oxfmt",
      method = require("null-ls.methods").internal.FORMATTING,
      filetypes = { "markdown" },
      generator_opts = {
        command = "oxfmt",
        args = { "-c", vim.fn.stdpath "config" .. "/.oxfmtrc.json", "--stdin-filepath", "$FILENAME" },
        to_stdin = true,
      },
      factory = h.formatter_factory,
    }

    -- Check supported formatters and linters
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/formatting
    -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics

    -- Only insert new sources, do not replace the existing ones
    -- (If you wish to replace, use `opts.sources = {}` instead of the `list_insert_unique` function)
    opts.sources = require("astrocore").list_insert_unique(opts.sources, { oxfmt })
  end,
}
