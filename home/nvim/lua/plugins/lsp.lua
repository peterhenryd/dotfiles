return {
  -- Auto-install language servers (except clangd, which is system, and
  -- rust-analyzer, which rustaceanvim manages via rustup).
  {
    "mason-org/mason.nvim",
    opts = { ui = { border = "rounded" } },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      -- clangd for C/C++ (system binary; rust-analyzer is handled by rustaceanvim)
      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders=1",
          "--fallback-style=llvm",
        },
      })
      vim.lsp.enable("clangd")

      -- vtsls covers JS/TS/React, and hosts the Vue plugin so .vue files
      -- get full TypeScript support (the setup vue_ls requires).
      local vue_plugin = {
        name = "@vue/typescript-plugin",
        location = vim.fn.expand("$MASON/packages")
          .. "/vue-language-server/node_modules/@vue/language-server",
        languages = { "vue" },
        configNamespace = "typescript",
      }
      vim.lsp.config("vtsls", {
        settings = {
          vtsls = { tsserver = { globalPlugins = { vue_plugin } } },
        },
        filetypes = {
          "javascript", "javascriptreact",
          "typescript", "typescriptreact", "vue",
        },
      })

      -- Let Ruff own formatting/import-fixes; Pyright does types & completion.
      vim.lsp.config("pyright", {
        settings = {
          pyright = { disableOrganizeImports = true },
        },
      })

      require("mason-lspconfig").setup({
        -- lspconfig names; mason-lspconfig maps them to mason packages,
        -- installs them, and enables them via vim.lsp.enable().
        ensure_installed = {
          "gopls",    -- Go
          "vtsls",    -- JavaScript / TypeScript / React
          "vue_ls",   -- Vue SFCs
          "html",     -- HTML
          "cssls",    -- CSS / SCSS
          "pyright",  -- Python types & completion
          "ruff",     -- Python lint / format / import sorting
          "lua_ls",   -- Lua (this config)
        },
      })

      -- Make lua_ls understand the Neovim runtime when editing this config.
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME, "${3rd}/luv/library" },
            },
          },
        },
      })
    end,
  },
}
