-- Universal run/test/build/stop for every language, with one set of keys:
--
--   <leader>rr  run      <leader>rt  test     <leader>rb  build
--   <leader>rs  stop     <leader>rl  re-run last
--   <leader>ro  toggle the output terminal
--
-- The command is resolved from the project type first (Cargo.toml, go.mod,
-- package.json, ...), falling back to a per-filetype command for loose files.

local M = {}

local state = { buf = nil, win = nil, job = nil, last = nil }

-- ---------------------------------------------------------- project specs

-- Read package.json and pick the right package manager + script.
local function node_cmd(root, kind)
  local pm = "npm"
  if vim.uv.fs_stat(root .. "/pnpm-lock.yaml") then pm = "pnpm"
  elseif vim.uv.fs_stat(root .. "/yarn.lock") then pm = "yarn"
  elseif vim.uv.fs_stat(root .. "/bun.lockb") or vim.uv.fs_stat(root .. "/bun.lock") then pm = "bun" end

  local scripts = {}
  local f = io.open(root .. "/package.json", "r")
  if f then
    local ok, json = pcall(vim.json.decode, f:read("*a"))
    f:close()
    if ok and type(json.scripts) == "table" then scripts = json.scripts end
  end

  if kind == "run" then
    for _, name in ipairs({ "dev", "start", "serve" }) do
      if scripts[name] then return pm .. " run " .. name end
    end
    return nil
  elseif kind == "test" then
    if scripts.test then return pm .. " test" end
    return nil
  elseif kind == "build" then
    if scripts.build then return pm .. " run build" end
    return nil
  end
end

-- Each spec: markers that identify the project, then commands.
-- Commands may be strings or fn(root) -> string|nil.
local specs = {
  {
    markers = { "Cargo.toml" },
    run = "cargo run", test = "cargo test", build = "cargo build",
  },
  {
    markers = { "go.mod" },
    run = "go run .", test = "go test ./...", build = "go build ./...",
  },
  {
    markers = { "package.json" },
    run = function(root) return node_cmd(root, "run") end,
    test = function(root) return node_cmd(root, "test") end,
    build = function(root) return node_cmd(root, "build") end,
  },
  {
    markers = { "CMakeLists.txt" },
    build = "cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && cmake --build build",
    -- Assumes the executable is named after the project directory
    -- (true for projects created by the wizard).
    run = function(root)
      return "cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && cmake --build build && ./build/"
        .. vim.fs.basename(root)
    end,
    test = "cmake --build build && ctest --test-dir build --output-on-failure",
  },
  {
    markers = { "Makefile" },
    run = "make run", test = "make test", build = "make",
  },
  {
    markers = { "pyproject.toml", "requirements.txt", "setup.py" },
    run = function(root)
      for _, entry in ipairs({ "main.py", "app.py", "src/main.py" }) do
        if vim.uv.fs_stat(root .. "/" .. entry) then
          return "python3 " .. entry
        end
      end
      return nil
    end,
    test = "python3 -m pytest",
    build = nil,
  },
}

-- Fallbacks for a lone file with no recognizable project.
local file_fallbacks = {
  python = { run = "python3 %s", test = "python3 -m pytest %s" },
  go = { run = "go run %s", test = "go test" },
  javascript = { run = "node %s" },
  typescript = { run = "npx tsx %s" },
  sh = { run = "sh %s" },
  lua = { run = "nvim -l %s" },
  html = { run = "open %s" }, -- macOS: open in default browser
  c = { run = "cc -Wall -o /tmp/nvim-run %s && /tmp/nvim-run" },
  cpp = { run = "c++ -std=c++20 -Wall -o /tmp/nvim-run %s && /tmp/nvim-run" },
  rust = { run = "mkdir -p /tmp/nvim-run-rs && rustc -o /tmp/nvim-run-rs/bin %s && /tmp/nvim-run-rs/bin" },
}

-- ------------------------------------------------------------- resolution

local function resolve(kind)
  local file = vim.api.nvim_buf_get_name(0)

  -- Project-level: nearest spec marker above the current file (or cwd).
  local best -- { root, spec } with the deepest root winning
  for _, spec in ipairs(specs) do
    local root = vim.fs.root(file ~= "" and file or 0, spec.markers)
    if root and spec[kind] then
      if not best or #root > #best.root then
        best = { root = root, spec = spec }
      end
    end
  end
  if best then
    local cmd = best.spec[kind]
    if type(cmd) == "function" then cmd = cmd(best.root) end
    if cmd then return cmd, best.root end
  end

  -- File-level fallback.
  local fb = file_fallbacks[vim.bo.filetype]
  if fb and fb[kind] and file ~= "" then
    return fb[kind]:format(vim.fn.shellescape(file)), vim.fs.dirname(file)
  end

  return nil
end

-- ---------------------------------------------------------- terminal panel

local function open_panel()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    return state.win
  end
  vim.cmd("botright 15split")
  state.win = vim.api.nvim_get_current_win()
  return state.win
end

function M.toggle_panel()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
    state.win = nil
  elseif state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    local prev = vim.api.nvim_get_current_win()
    open_panel()
    vim.api.nvim_win_set_buf(state.win, state.buf)
    vim.api.nvim_set_current_win(prev)
  else
    vim.notify("Nothing has been run yet", vim.log.levels.INFO)
  end
end

function M.stop()
  if state.job then
    vim.fn.jobstop(state.job)
    state.job = nil
    vim.notify("Runner: stopped", vim.log.levels.INFO)
  else
    vim.notify("Runner: nothing running", vim.log.levels.INFO)
  end
end

function M.execute(cmd, cwd)
  M.stop()
  state.last = { cmd = cmd, cwd = cwd }

  local prev = vim.api.nvim_get_current_win()
  open_panel()
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(state.win, state.buf)
  vim.bo[state.buf].buflisted = false

  state.job = vim.fn.jobstart(cmd, {
    term = true,
    cwd = cwd,
    on_exit = function(_, code)
      state.job = nil
      vim.schedule(function()
        vim.notify(
          ("Runner: %s (exit %d)"):format(code == 0 and "done" or "failed", code),
          code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
        )
      end)
    end,
  })
  vim.keymap.set("n", "q", M.toggle_panel, { buffer = state.buf, silent = true })
  -- Keep focus in the editor; the panel scrolls on its own.
  vim.api.nvim_buf_call(state.buf, function() vim.cmd("normal! G") end)
  vim.api.nvim_set_current_win(prev)
end

-- ------------------------------------------------------------------ verbs

local function dispatch(kind)
  local cmd, cwd = resolve(kind)
  if not cmd then
    vim.notify(
      ("Runner: no '%s' command for this %s project/filetype"):format(kind, vim.bo.filetype),
      vim.log.levels.WARN
    )
    return
  end
  M.execute(cmd, cwd)
end

function M.run() dispatch("run") end
function M.test() dispatch("test") end
function M.build() dispatch("build") end

function M.rerun()
  if state.last then
    M.execute(state.last.cmd, state.last.cwd)
  else
    vim.notify("Runner: nothing to re-run", vim.log.levels.INFO)
  end
end

function M.setup()
  local map = vim.keymap.set
  map("n", "<leader>rr", M.run, { desc = "Run project/file" })
  map("n", "<leader>rt", M.test, { desc = "Test project/file" })
  map("n", "<leader>rb", M.build, { desc = "Build project" })
  map("n", "<leader>rs", M.stop, { desc = "Stop runner" })
  map("n", "<leader>rl", M.rerun, { desc = "Re-run last command" })
  map("n", "<leader>ro", M.toggle_panel, { desc = "Toggle runner output" })
end

return M
