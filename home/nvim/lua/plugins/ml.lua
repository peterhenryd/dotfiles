-- Python / machine-learning workflow tooling.
--
--   <leader>mr  open/toggle the ipython REPL
--   <leader>ms  send: motion in normal mode (e.g. <leader>msip), selection in visual
--   <leader>mc  send the current # %% cell and jump to the next one
--   <leader>mf  send the whole file
--   <leader>mx  interrupt the REPL       <leader>mq  close the REPL
--   <leader>mv  pick a virtualenv / conda env for the LSP

return {
  -- REPL integration: send code (lines, motions, # %% cells) to ipython.
  {
    "Vigemus/iron.nvim",
    keys = {
      { "<leader>mr", "<cmd>IronRepl<CR>", desc = "Toggle ipython REPL" },
      { "<leader>ms", mode = { "n", "v" }, desc = "Send to REPL" },
      { "<leader>mc", desc = "Send cell + next" },
      { "<leader>mf", desc = "Send file to REPL" },
      { "<leader>mx", desc = "Interrupt REPL" },
      { "<leader>mq", desc = "Close REPL" },
    },
    main = "iron.core",
    opts = function()
      return {
        config = {
          scratch_repl = true,
          repl_definition = {
            python = {
              command = vim.fn.executable("ipython") == 1
                  and { "ipython", "--no-autoindent" }
                or { "python3" },
              format = require("iron.fts.common").bracketed_paste_python,
              block_dividers = { "# %%", "#%%" },
            },
          },
          repl_open_cmd = "vertical botright 80 split",
        },
        keymaps = {
          send_motion = "<leader>ms",
          visual_send = "<leader>ms",
          send_file = "<leader>mf",
          send_code_block_and_move = "<leader>mc",
          interrupt = "<leader>mx",
          exit = "<leader>mq",
        },
        highlight = { italic = false },
        ignore_blank_lines = true,
      }
    end,
  },

  -- Open .ipynb notebooks as plain scripts/markdown; saves back to .ipynb.
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false, -- must be loaded before an .ipynb buffer is read
    opts = {
      style = "hydrogen", -- .ipynb opens as a .py with # %% cell markers
    },
  },

  -- Pick which virtualenv/conda env pyright + ruff should use.
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    dependencies = { "nvim-telescope/telescope.nvim" },
    cmd = "VenvSelect",
    keys = {
      { "<leader>mv", "<cmd>VenvSelect<CR>", desc = "Select Python venv" },
    },
    opts = {},
  },
}
