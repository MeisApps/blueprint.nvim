local M = {}
local config = require 'blueprint.config'
local utils = require 'blueprint.utils'
local plenary_scandir = require 'plenary.scandir'

function M.cmd_add_project(opts)
  local args_map = utils.parse_args(opts.args)
  local mode = 'cwd'
  if args_map.map['mode'] then
    mode = args_map.map['mode']
  end

  if mode == 'cwd' then -- Add cwd
    local project = M.add_project(vim.fn.getcwd())
    print('Project "' .. project.name .. '" added.')
  elseif mode == 'subdirs' then -- Add subdirs in cwd
    local added_str = ''
    for _, dir in ipairs(plenary_scandir.scan_dir(vim.fn.getcwd(), { only_dirs = true, depth = 1 })) do
      local project = M.add_project(dir)
      added_str = added_str .. '"' .. project.name .. '", '
    end
    if added_str == '' then
      print 'No subdirectories found.'
      return
    end
    added_str = added_str:sub(1, -3)
    print('Projects [' .. added_str .. '] added.')
  elseif mode == 'select' then -- Add select
    local dir_selector = require 'blueprint.dir_selector'
    dir_selector.reset()
    dir_selector.on_selected(function(path)
      local project = M.add_project(path)
      print('Project "' .. project.name .. '" added.')
    end)
    dir_selector.open('Add project', vim.fn.getcwd())
  else
    print('Invalid mode "' .. mode .. '".')
  end
end

function M.cmd_remove_project(opts)
  local args_map = utils.parse_args(opts.args)
  local mode = 'cwd'
  if args_map.map['mode'] then
    mode = args_map.map['mode']
  end

  if mode == 'cwd' then -- Remove cwd
    local project = M.remove_project(vim.fn.getcwd())
    print('Project "' .. project.name .. '" removed.')
  elseif mode == 'select' then -- Remove select
    local selector = require 'blueprint.telescope_selector'
    selector.reset()
    selector.results = M.get_projects()
    selector.on_selected(function(selected_entry)
      M.remove_project(selected_entry.path)
      print('Project "' .. selected_entry.name .. '" removed.')
    end)
    selector.open('Remove project', true)
  else
    print('Invalid mode "' .. mode .. '".')
  end
end

function M.cmd_open_project(opts)
  local args_map = utils.parse_args(opts.args)
  local selector = require 'blueprint.telescope_selector'
  selector.reset()
  local function update_entries()
    selector.results = M.get_projects()
    local sort_by = config.get_settings().projects.picker.sort_by
    if args_map.map['sort'] then
      sort_by = args_map.map['sort']
    end
    table.sort(selector.results, function(a, b)
      if sort_by == 'asc' then
        return a.name:lower() > b.name:lower()
      elseif sort_by == 'desc' then
        return a.name:lower() < b.name:lower()
      elseif sort_by == 'recent' then
        return a.access_time > b.access_time
      end
      return false
    end)
    selector.refresh()
  end
  update_entries()

  selector.on_selected(function(selected_entry)
    M.open_project(selected_entry.path)
  end)
  selector.on_remove_selected(function(selected_entry)
    M.remove_project(selected_entry.path)
    update_entries()
  end)
  selector.open('Open project', true)
end

function M.open_project(project_path)
  vim.api.nvim_exec_autocmds('User', { pattern = 'BlueprintProjectOpenPre' })
  local project = M.get_project_by_path(project_path)
  if project == nil then
    print('Project at path "' .. project_path .. '" does not exist.')
    return
  end
  project.access_time = os.time()
  M.update_project(project)

  vim.fn.execute('cd ' .. project_path, 'silent')
  print('Opened project "' .. project_path .. '".')
  vim.api.nvim_exec_autocmds('User', { pattern = 'BlueprintProjectOpenPost' })
end

function M.add_project(project_path)
  M.remove_project(project_path)
  local projects = M.get_projects()
  local entry = {
    name = vim.fn.fnamemodify(project_path, ':t'),
    path = project_path,
    filetype = utils.get_directory_filetype(project_path),
    access_time = os.time(),
  }
  table.insert(projects, entry)
  M.save_projects(projects)
  return entry
end

function M.remove_project(project_path)
  local projects = M.get_projects()
  local project = {}
  for i = #projects, 1, -1 do
    if projects[i].path == project_path then
      project = projects[i]
      table.remove(projects, i)
    end
  end
  M.save_projects(projects)
  return project
end

function M.update_project(project)
  local projects = M.get_projects()
  for i = #projects, 1, -1 do
    if projects[i].path == project.path then
      projects[i] = project
      break
    end
  end
  M.save_projects(projects)
end

function M.get_project_by_path(project_path)
  for _, project in ipairs(M.get_projects()) do
    if project.path == project_path then
      return project
    end
  end
  return nil
end

function M.get_projects()
  local json_file = vim.fn.readfile(config.get_projects_file_path())
  local projects_json = vim.fn.json_decode(json_file)
  if projects_json ~= nil then
    return projects_json
  end
  return {}
end

function M.save_projects(projects)
  local projects_json = vim.fn.json_encode(projects)
  vim.fn.writefile({ projects_json }, config.get_projects_file_path())
end

return M
