local fn = vim.fn

local M = {}

local function find_executable()
  local import_sort_executable = fn.getcwd() .. "/node_modules/.bin/import-sort"
  if 0 == fn.executable(import_sort_executable) then
    local sub_cmd =  fn.system("git rev-parse --show-toplevel")
    local project_root_path = sub_cmd:gsub("\n","")
    import_sort_executable = project_root_path .. "/node_modules/.bin/import-sort"
  end

  if 0 == fn.executable(import_sort_executable) then
    import_sort_executable = "import-sort"
  end
  return import_sort_executable
end

local function onread(err, data)
  if err then
    error("SORT_IMPORT: ", err)
  end
end

function M.sort_import(async)
  local winview = fn.winsaveview()
  local path = fn.fnameescape(fn.expand("%:p"))
  local executable_path = find_executable()
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)


  if fn.executable(executable_path) then
    if true == async then
      handle = vim.loop.spawn(executable_path, {
        args = {path, "--write"},
        stdio = {stdout,stderr}
      },
      vim.schedule_wrap(function()
        stdout:read_stop()
        stderr:read_stop()
        stdout:close()
        stderr:close()
        handle:close()
        vim.api.nvim_command[["checktime"]]
        fn.winrestview(winview)
      end
      )
      )
      vim.loop.read_start(stdout, onread)
      vim.loop.read_start(stderr, onread)
    else
      fn.system(executable_path .. " " .. path .. " " .. "--write")
      vim.api.nvim_command[["checktime"]]
      fn.winrestview(winview)
    end
  else
    error("Cannot find import-sort executable")
  end
end

function M.setup()
  vim.cmd 'command! SortImport lua require"sort-import".sort_import()'
end


return M
