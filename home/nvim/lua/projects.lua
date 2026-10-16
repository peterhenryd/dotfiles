-- Custom startup dashboard + project management for ~/Repositories.
--
--   :Projects          reopen the dashboard
--   [1]..[9]           open a recent project
--   [o] open project   picker over every dir in ~/Repositories
--   [n] new project    template wizard (rust / svelte / c / c++ / empty)
--   [e] empty buffer   [q] quit

local M = {}

M.root = vim.fn.expand("~/Repositories")

local history_file = vim.fn.stdpath("data") .. "/project_history.json"
local ns = vim.api.nvim_create_namespace("projects_dashboard")

-- ---------------------------------------------------------------- history

local function read_history()
  local f = io.open(history_file, "r")
  if not f then return {} end
  local ok, data = pcall(vim.json.decode, f:read("*a"))
  f:close()
  return (ok and type(data) == "table") and data or {}
end

local function touch_history(dir)
  local hist = read_history()
  hist[dir] = os.time()
  local f = io.open(history_file, "w")
  if f then
    f:write(vim.json.encode(hist))
    f:close()
  end
end

-- ---------------------------------------------------------------- projects

local function is_dir(path)
  return vim.fn.isdirectory(path) == 1
end

local function all_projects()
  local dirs = {}
  if not is_dir(M.root) then return dirs end
  for name, kind in vim.fs.dir(M.root) do
    if kind == "directory" and not name:match("^%.") then
      table.insert(dirs, M.root .. "/" .. name)
    end
  end
  table.sort(dirs)
  return dirs
end

local function package_deps(dir)
  local f = io.open(dir .. "/package.json", "r")
  if not f then return {} end
  local ok, json = pcall(vim.json.decode, f:read("*a"))
  f:close()
  if not ok or type(json) ~= "table" then return {} end
  return vim.tbl_extend("force", json.dependencies or {}, json.devDependencies or {})
end

local function project_kind(dir)
  local function has(file) return vim.uv.fs_stat(dir .. "/" .. file) ~= nil end
  if has("Cargo.toml") then return " rust" end
  if has("go.mod") then return " go" end
  if has("svelte.config.js") or has("svelte.config.ts") then return " svelte" end
  if has("package.json") then
    local deps = package_deps(dir)
    if deps.vue then return " vue" end
    if deps.react then return " react" end
    return " node"
  end
  if has("pyproject.toml") or has("requirements.txt") then return " python" end
  if has("CMakeLists.txt") then return " c/c++" end
  if has("Makefile") then return " make" end
  if has(".git") then return " git" end
  return ""
end

-- Recent projects: history order, falling back to directory mtime.
local function recent_projects(limit)
  local hist = read_history()
  local dirs = all_projects()
  table.sort(dirs, function(a, b)
    local ha, hb = hist[a], hist[b]
    if ha or hb then return (ha or 0) > (hb or 0) end
    local sa = vim.uv.fs_stat(a)
    local sb = vim.uv.fs_stat(b)
    return (sa and sa.mtime.sec or 0) > (sb and sb.mtime.sec or 0)
  end)
  return vim.list_slice(dirs, 1, limit)
end

-- ---------------------------------------------------------------- actions

function M.open_project(dir)
  touch_history(dir)
  vim.cmd.cd(vim.fn.fnameescape(dir))
  local ok = pcall(function()
    require("telescope.builtin").find_files({ prompt_title = vim.fs.basename(dir) })
  end)
  if not ok then
    vim.cmd.edit(vim.fn.fnameescape(dir))
  end
end

function M.pick_project()
  local dirs = all_projects()
  if #dirs == 0 then
    vim.notify("No projects found in " .. M.root, vim.log.levels.WARN)
    return
  end
  vim.ui.select(dirs, {
    prompt = "Open project",
    format_item = function(dir)
      return vim.fs.basename(dir) .. "  " .. project_kind(dir)
    end,
  }, function(dir)
    if dir then M.open_project(dir) end
  end)
end

-- ---------------------------------------------------------------- wizard

local function scaffold_files(dir, files)
  vim.fn.mkdir(dir, "p")
  for path, content in pairs(files) do
    local full = dir .. "/" .. path
    vim.fn.mkdir(vim.fs.dirname(full), "p")
    local f = assert(io.open(full, "w"))
    f:write(content)
    f:close()
  end
  vim.system({ "git", "init" }, { cwd = dir }):wait()
end

-- Run a non-interactive command, then open the resulting project.
local function run_and_open(cmd, dir)
  vim.system(cmd, { cwd = M.root }, function(out)
    vim.schedule(function()
      if out.code ~= 0 then
        vim.notify(table.concat(cmd, " ") .. " failed:\n" .. (out.stderr or ""), vim.log.levels.ERROR)
      elseif is_dir(dir) then
        M.open_project(dir)
      end
    end)
  end)
end

-- Run an interactive command in a terminal buffer, then open the project.
local function run_interactive(cmd, dir)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.fn.jobstart(cmd, {
    term = true,
    cwd = M.root,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 and is_dir(dir) then
          M.open_project(dir)
        elseif code ~= 0 then
          vim.notify("Project creation exited with code " .. code, vim.log.levels.WARN)
        end
      end)
    end,
  })
  vim.cmd.startinsert()
end

-- Public so extra templates can be added: table.insert(require("projects").templates, ...)
M.templates = {
  {
    name = "Rust (binary)",
    create = function(dir, name) run_and_open({ "cargo", "new", name }, dir) end,
  },
  {
    name = "Rust (library)",
    create = function(dir, name) run_and_open({ "cargo", "new", "--lib", name }, dir) end,
  },
  {
    name = "Go",
    create = function(dir, name)
      scaffold_files(dir, {
        ["main.go"] = ('package main\n\nimport "fmt"\n\nfunc main() {\n\tfmt.Println("Hello from %s!")\n}\n'):format(name),
        [".gitignore"] = name .. "\n",
      })
      vim.system({ "go", "mod", "init", name }, { cwd = dir }):wait()
      M.open_project(dir)
    end,
  },
  {
    name = "Python (uv)",
    create = function(dir, name) run_and_open({ "uv", "init", name }, dir) end,
  },
  {
    name = "Svelte (sv create)",
    create = function(dir, name) run_interactive({ "pnpm", "dlx", "sv", "create", name }, dir) end,
  },
  {
    name = "React (Vite)",
    create = function(dir, name)
      run_interactive({ "pnpm", "create", "vite", name, "--template", "react-ts" }, dir)
    end,
  },
  {
    name = "Vue (create-vue)",
    create = function(dir, name)
      run_interactive({ "pnpm", "create", "vue@latest", name }, dir)
    end,
  },
  {
    name = "C (Makefile)",
    create = function(dir, name)
      scaffold_files(dir, {
        ["Makefile"] = ("CC ?= cc\nCFLAGS ?= -Wall -Wextra -g\n\n%s: src/main.c\n\t$(CC) $(CFLAGS) -o $@ $^\n\n.PHONY: run clean\nrun: %s\n\t./%s\n\nclean:\n\trm -f %s\n"):format(name, name, name, name),
        ["src/main.c"] = '#include <stdio.h>\n\nint main(void) {\n    printf("Hello from ' .. name .. '!\\n");\n    return 0;\n}\n',
        [".gitignore"] = name .. "\n*.o\n*.dSYM/\n",
      })
      M.open_project(dir)
    end,
  },
  {
    name = "C++ (CMake)",
    create = function(dir, name)
      scaffold_files(dir, {
        ["CMakeLists.txt"] = ("cmake_minimum_required(VERSION 3.20)\nproject(%s CXX)\n\nset(CMAKE_CXX_STANDARD 20)\nset(CMAKE_CXX_STANDARD_REQUIRED ON)\nset(CMAKE_EXPORT_COMPILE_COMMANDS ON)\n\nadd_executable(%s src/main.cpp)\n"):format(name, name),
        ["src/main.cpp"] = '#include <iostream>\n\nint main() {\n    std::cout << "Hello from ' .. name .. '!\\n";\n    return 0;\n}\n',
        [".gitignore"] = "build/\n",
      })
      M.open_project(dir)
    end,
  },
  {
    name = "Empty (git init)",
    create = function(dir, _)
      scaffold_files(dir, { ["README.md"] = "# " .. vim.fs.basename(dir) .. "\n" })
      M.open_project(dir)
    end,
  },
}

function M.new_project()
  vim.ui.select(M.templates, {
    prompt = "New project template",
    format_item = function(t) return t.name end,
  }, function(template)
    if not template then return end
    vim.ui.input({ prompt = "Project name: " }, function(name)
      if not name or name == "" then return end
      if name:match("[/%s]") then
        vim.notify("Project name must not contain spaces or slashes", vim.log.levels.ERROR)
        return
      end
      local dir = M.root .. "/" .. name
      if is_dir(dir) then
        vim.notify(dir .. " already exists", vim.log.levels.ERROR)
        return
      end
      vim.fn.mkdir(M.root, "p")
      template.create(dir, name)
    end)
  end)
end

-- ---------------------------------------------------------------- dashboard

local header = {
  [[███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗]],
  [[████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║]],
  [[██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║]],
  [[██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║]],
  [[██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║]],
  [[╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
}

local function render(buf, win)
  local recents = recent_projects(8)
  local width = vim.api.nvim_win_get_width(win)
  local height = vim.api.nvim_win_get_height(win)

  -- Build the content block, then center it.
  local block = {}
  local hl = {} -- { [block_line_index] = hl_group } for full-line highlights
  local function push(line, group)
    table.insert(block, line)
    hl[#block] = group
  end

  for _, line in ipairs(header) do
    push(line, "ProjectsHeader")
  end
  push("", nil)

  if #recents > 0 then
    push("Recent projects", "ProjectsTitle")
    push("", nil)
    local name_w = 0
    for _, dir in ipairs(recents) do
      name_w = math.max(name_w, #vim.fs.basename(dir))
    end
    for i, dir in ipairs(recents) do
      local name = vim.fs.basename(dir)
      push(("[%d]  %s%s   %s"):format(
        i, name, string.rep(" ", name_w - #name), project_kind(dir)
      ), nil)
    end
  else
    push("No projects yet in ~/Repositories", "ProjectsMuted")
  end

  push("", nil)
  push("[o] open project    [n] new project    [e] empty buffer    [q] quit", nil)

  local block_w = 0
  for _, line in ipairs(block) do
    block_w = math.max(block_w, vim.fn.strdisplaywidth(line))
  end
  local pad_left = string.rep(" ", math.max(0, math.floor((width - block_w) / 2)))
  local pad_top = math.max(1, math.floor((height - #block) / 2) - 1)

  local lines = {}
  for _ = 1, pad_top do
    table.insert(lines, "")
  end
  for _, line in ipairs(block) do
    table.insert(lines, pad_left .. line)
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, group in pairs(hl) do
    local lnum = pad_top + i - 1
    vim.api.nvim_buf_set_extmark(buf, ns, lnum, 0, {
      end_row = lnum + 1,
      hl_group = group,
      hl_eol = false,
    })
  end
end

function M.show()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  local win = vim.api.nvim_get_current_win()

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "projects"
  for opt, val in pairs({
    number = false, relativenumber = false, cursorline = false,
    signcolumn = "no", foldcolumn = "0", colorcolumn = "", list = false,
    spell = false, wrap = false,
  }) do
    vim.api.nvim_set_option_value(opt, val, { win = win, scope = "local" })
  end

  -- Highlight the [x] key hints.
  vim.api.nvim_win_call(win, function()
    vim.fn.matchadd("ProjectsKey", "\\[\\w\\]")
  end)

  render(buf, win)

  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true, desc = desc })
  end
  map("q", "<cmd>quit<CR>", "Quit")
  map("e", "<cmd>enew<CR>", "Empty buffer")
  map("o", M.pick_project, "Open project")
  map("n", M.new_project, "New project")
  for i = 1, 9 do
    map(tostring(i), function()
      local recents = recent_projects(9)
      if recents[i] then M.open_project(recents[i]) end
    end, "Open recent project " .. i)
  end

  vim.api.nvim_create_autocmd("VimResized", {
    buffer = buf,
    callback = function()
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
        render(buf, win)
      end
    end,
  })
end

-- ---------------------------------------------------------------- setup

function M.setup()
  -- Dashboard highlights (defaults; the colorscheme can override).
  vim.api.nvim_set_hl(0, "ProjectsHeader", { link = "Function", default = true })
  vim.api.nvim_set_hl(0, "ProjectsTitle", { link = "String", default = true })
  vim.api.nvim_set_hl(0, "ProjectsKey", { link = "Keyword", default = true })
  vim.api.nvim_set_hl(0, "ProjectsMuted", { link = "Comment", default = true })

  vim.api.nvim_create_user_command("Projects", M.show, { desc = "Open project dashboard" })

  -- Record visits when nvim starts inside a project.
  local cwd = vim.fn.getcwd()
  if cwd ~= M.root and cwd:sub(1, #M.root + 1) == M.root .. "/" then
    local proj = cwd:sub(#M.root + 2):match("^[^/]+")
    if proj then touch_history(M.root .. "/" .. proj) end
  end

  -- Show the dashboard when nvim is started with no arguments.
  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("user_projects_dashboard", { clear = true }),
    callback = function()
      local starting_empty = vim.fn.argc() == 0
        and vim.api.nvim_buf_get_name(0) == ""
        and not vim.bo.modified
        and vim.api.nvim_buf_line_count(0) == 1
        and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ""
      if starting_empty then M.show() end
    end,
  })
end

return M
