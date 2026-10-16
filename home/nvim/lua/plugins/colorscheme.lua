return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      -- Let the terminal's translucent/blurred background show through.
      transparent_background = true,
      custom_highlights = function(colors)
        return {
          -- Keep the sticky context header and cursorline readable but
          -- see-through rather than solid panels.
          TreesitterContext = { bg = colors.none },
          TreesitterContextLineNumber = { bg = colors.none },
          TabLine = { bg = colors.none },
          TabLineFill = { bg = colors.none },
          CursorLine = { bg = colors.surface0 },
        }
      end,
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        indent_blankline = { enabled = true },
        mini = { enabled = true },
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        telescope = { enabled = true },
        treesitter = true,
        which_key = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
