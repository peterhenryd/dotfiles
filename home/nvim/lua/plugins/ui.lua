return {
  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "diagnostics", "lsp_status", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
    config = function(_, opts)
      -- Start from catppuccin's lualine palette, but make the b/c fills
      -- transparent so the terminal blur shows through the statusline.
      local theme = require("lualine.themes.catppuccin-mocha")
      for _, mode in pairs(theme) do
        if type(mode) == "table" then
          if mode.b then mode.b.bg = "NONE" end
          if mode.c then mode.c.bg = "NONE" end
        end
      end
      opts.options.theme = theme
      require("lualine").setup(opts)
    end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "▏" },
      scope = { enabled = true, show_start = false, show_end = false },
      exclude = { filetypes = { "help", "lazy", "oil", "projects" } },
    },
  },

  -- LSP progress notifications (bottom right)
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    opts = {
      notification = { window = { winblend = 0 } },
    },
  },

  -- Pretty vim.ui.select / vim.ui.input (used by the project wizard)
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- Keymap hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>b", group = "buffer" },
        { "<leader>t", group = "toggle" },
        { "<leader>c", group = "code" },
        { "<leader>r", group = "run / refactor" },
        { "<leader>m", group = "ml / repl" },
      },
    },
  },
}
