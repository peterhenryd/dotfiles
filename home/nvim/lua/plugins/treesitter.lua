-- nvim-treesitter `main` branch (the rewritten API for Neovim 0.11+).
local ensure_installed = {
  "c", "cpp", "rust", "lua", "vim", "vimdoc", "query",
  "toml", "cmake", "make", "bash", "json", "yaml",
  "markdown", "markdown_inline", "diff", "regex",
  "go", "gomod", "gosum", "javascript", "typescript", "tsx",
  "html", "css", "scss", "python", "vue", "jsdoc",
}

-- Filetypes to attach treesitter highlighting/indent to.
local ts_filetypes = {
  "c", "cpp", "rust", "lua", "vim", "toml", "cmake", "make",
  "sh", "bash", "zsh", "json", "yaml", "markdown", "query",
  "go", "gomod", "gosum", "javascript", "typescript",
  "javascriptreact", "typescriptreact", "html", "css", "scss",
  "python", "vue",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require("nvim-treesitter").install(ensure_installed)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = ts_filetypes,
        callback = function(event)
          -- Only start if a parser actually exists for this filetype
          local ok = pcall(vim.treesitter.start, event.buf)
          if ok then
            vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- Sticky context line (shows the enclosing function/impl at the top)
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = { max_lines = 3, mode = "cursor" },
  },
}
