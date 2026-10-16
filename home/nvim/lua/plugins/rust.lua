return {
  -- Batteries-included rust-analyzer integration:
  -- grouped diagnostics, runnables, expand macro, open Cargo.toml, etc.
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false, -- the plugin is already lazy by design
    init = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              cargo = { allFeatures = true },
              check = { command = "clippy" },
              inlayHints = {
                lifetimeElisionHints = { enable = "skip_trivial" },
              },
            },
          },
        },
      }
    end,
  },

  -- Cargo.toml smarts: shows available crate versions, updates deps
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },
}
