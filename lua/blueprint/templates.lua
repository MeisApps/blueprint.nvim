local M = {}
local config = require 'blueprint.config'
local projects = require 'blueprint.projects'
local utils = require 'blueprint.utils'
local plenary_path = require 'plenary.path'
local plenary_scandir = require 'plenary.scandir'
M.custom_project_templates = {}

function M.cmd_create_project()
  local selector = require 'blueprint.telescope_selector'
  local dir_selector = require 'blueprint.dir_selector'

  -- Template selector
  selector.reset()
  selector.results = M.get_project_templates()
  selector.on_selected(function(selected_entry)
    -- Create the project
    local function create_project(project_path, project_name)
      M.create_project(selected_entry, project_path, project_name, function(result)
        if result then
          projects.open_project(project_path)
        end
      end)
    end

    -- Enter variables
    local function enter_vars_val(i, callback)
      if i > #selected_entry.vars then
        callback()
        return
      end
      local var = selected_entry.vars[i]
      if var.value == nil then
        vim.ui.input({ prompt = 'Enter Variable Value for "' .. var.key .. '":', default = var.default_value or '' }, function(input)
          if input then
            selected_entry.vars[i].value = input
            enter_vars_val(i + 1, callback)
          else
            print 'Canceled.'
          end
        end)
      else
        enter_vars_val(i + 1, callback)
      end
    end

    -- Enter project name
    local function enter_project_name(project_path)
      vim.ui.input({ prompt = 'Project Name:' }, function(input)
        if input then
          enter_vars_val(1, function()
            create_project(project_path .. '/' .. input, input)
          end)
        else
          print 'Canceled.'
        end
      end)
    end

    -- Select project dir
    if config.get_settings().templates.select_projects_dir then
      dir_selector.reset()
      dir_selector.on_selected(function(path)
        enter_project_name(path)
      end)
      dir_selector.open('Select project parent directory', config.get_settings().projects.default_dir)
    else
      enter_project_name(config.get_settings().projects.default_dir)
    end
  end)
  selector.open('Select project template', false)
end

function M.cmd_create_file()
  local selector = require 'blueprint.telescope_selector'
  local dir_selector = require 'blueprint.dir_selector'

  -- Template selector
  selector.reset()
  selector.results = M.get_file_templates()
  selector.on_selected(function(selected_entry)
    -- Enter variables
    local function enter_vars_val(i, callback)
      if i > #selected_entry.vars then
        callback()
        return
      end
      local var = selected_entry.vars[i]
      if var.value == nil then
        vim.ui.input({ prompt = 'Enter Variable Value for "' .. var.key .. '":', default = var.default_value or '' }, function(input)
          if input then
            selected_entry.vars[i].value = input
            enter_vars_val(i + 1, callback)
          else
            print 'Canceled.'
          end
        end)
      else
        enter_vars_val(i + 1, callback)
      end
    end

    -- Enter file name
    local function enter_file_name(file_path)
      vim.ui.input({ prompt = 'File Name:' }, function(input)
        if input then
          enter_vars_val(1, function()
            M.create_file(selected_entry, file_path, input)
          end)
        else
          print 'Canceled.'
        end
      end)
    end

    -- Select file dir
    if config.get_settings().templates.select_file_dir then
      dir_selector.reset()
      dir_selector.on_selected(function(path)
        enter_file_name(path)
      end)
      dir_selector.open('Select file directory', vim.fn.getcwd())
    else
      enter_file_name(vim.fn.getcwd())
    end
  end)
  selector.open('Select file template', false)
end

function M.create_project(template, project_path, project_name, callback)
  local function create_project_post()
    -- Apply variables
    local function apply_vars(data)
      data = string.gsub(data, '%[%[bp%-name%]%]', project_name)
      data = string.gsub(data, '%[%[bp%-name-upper%]%]', string.upper(project_name))
      data = string.gsub(data, '%[%[bp%-name-lower%]%]', string.lower(project_name))
      for _, var in ipairs(template.vars) do
        if var['key'] and var['value'] then
          data = string.gsub(data, '%[%[bp%-' .. var.key .. '%]%]', var.value)
        end
      end
      return data
    end
    for _, path in ipairs(plenary_scandir.scan_dir(project_path, {})) do
      local file = plenary_path:new(path)
      if file:is_file() and vim.fn.filereadable(file:absolute()) == 1 then
        file:write(apply_vars(file:read()), 'w')
        local filename = vim.fn.fnamemodify(file:absolute(), ':t')
        local new_filename = apply_vars(filename)
        if new_filename ~= filename then
          file:rename { new_name = (file:parent() / new_filename):absolute() }
        end
      end
    end

    -- Add project
    local project = projects.add_project(project_path)
    template.on_created(project)
    print('Created project "' .. project_name .. '" from template "' .. template.name .. '" at path "' .. project_path .. '".')
    vim.api.nvim_exec_autocmds('User', { pattern = 'BlueprintProjectCreatePost' })
    callback(true)
  end

  vim.api.nvim_exec_autocmds('User', { pattern = 'BlueprintProjectCreatePre' })
  if template.create_func ~= nil then
    -- Call custom template
    template.create_func(project_path, project_name, function(result)
      if not result then
        print 'Error creating custom template.'
        callback(false)
      else
        create_project_post()
      end
    end)
  else
    -- Copy files
    local src_path = plenary_path:new(template.path)
    local copy_result = src_path:copy {
      destination = project_path,
      recursive = true,
      parents = true,
    }
    if copy_result[project_path] == false then
      print 'Error copying project files.'
      callback(false)
      return
    end
    local dst_template_config_path = plenary_path:new(project_path) / 'bp-template.lua'
    if dst_template_config_path:exists() then
      dst_template_config_path:rm()
    end
    create_project_post()
  end
end

function M.create_file(template, file_path, file_name)
  vim.api.nvim_exec_autocmds('User', { pattern = 'BlueprintFileCreatePre' })
  if template.name == 'Empty' then
    local file = plenary_path:new(file_path) / file_name
    if file:exists() then
      print('File "' .. file_name .. '" aleady exists.')
      return false
    end
    file:write('', 'w')
  else
    -- Copy files
    local src_path = plenary_path:new(template.path)
    local copy_result = src_path:copy {
      destination = file_path,
      recursive = true,
      parents = true,
      interactive = true,
    }
    if copy_result[file_path] == false then
      print 'Error copying template files.'
      return false
    end
    local dst_template_config_path = plenary_path:new(file_path) / 'bp-template.lua'
    if dst_template_config_path:exists() then
      dst_template_config_path:rm()
    end

    -- Apply variables
    local function apply_vars(data)
      data = string.gsub(data, '%[%[bp%-name%]%]', file_name)
      data = string.gsub(data, '%[%[bp%-name%-upper%]%]', string.upper(file_name))
      data = string.gsub(data, '%[%[bp%-name%-lower%]%]', string.lower(file_name))
      for _, var in ipairs(template.vars) do
        if var['key'] and var['value'] then
          data = string.gsub(data, '%[%[bp%-' .. var.key .. '%]%]', var.value)
        end
      end
      return data
    end
    for info, _ in pairs(copy_result) do
      local file = plenary_path:new(info.filename)
      if file:is_file() and vim.fn.filereadable(file:absolute()) == 1 then
        file:write(apply_vars(file:read()), 'w')
        local filename = vim.fn.fnamemodify(file:absolute(), ':t')
        local new_filename = apply_vars(filename)
        if new_filename ~= filename then
          file:rename { new_name = (file:parent() / new_filename):absolute() }
        end
      end
    end
  end

  template.on_created(file_path, file_name)
  print('Created file "' .. file_name .. '" from template "' .. template.name .. '" at path "' .. file_path .. '".')
  vim.api.nvim_exec_autocmds('User', { pattern = 'BlueprintFileCreatePost' })
  return true
end

local function get_templates(templates_path)
  local function parse_entry(dir, template_entry)
    local name = vim.fn.fnamemodify(dir, ':t')
    local vars = {}
    local on_created = function() end
    if template_entry ~= nil then
      if template_entry['name'] then
        name = template_entry['name']
      end
      if template_entry['vars'] then
        vars = template_entry['vars']
      end
      if template_entry['on_created'] then
        on_created = template_entry['on_created']
      end
    end
    local entry = {
      name = name,
      path = dir,
      filetype = utils.get_directory_filetype(dir),
      vars = vars,
      on_created = on_created,
    }
    return entry
  end

  local templates = {}
  for _, dir in ipairs(plenary_scandir.scan_dir(templates_path, { only_dirs = true, depth = 1 })) do
    local config_file = plenary_path:new(dir) / 'bp-template.lua'
    if config_file:is_file() then
      local template_config = loadstring(config_file:read())()
      print(vim.inspect(template_config))
      if #template_config > 1 then -- Multiple templates
        for _, template_entry in ipairs(template_config) do
          local entry = parse_entry(dir, template_entry)
          table.insert(templates, entry)
        end
      else -- Single template
        local entry = parse_entry(dir, template_config)
        table.insert(templates, entry)
      end
    else -- No config
      table.insert(templates, parse_entry(dir))
    end
  end
  for _, template in ipairs(M.custom_project_templates) do
    table.insert(templates, template)
  end
  return templates
end

function M.get_project_templates()
  return get_templates(config.get_project_templates_path())
end

function M.get_file_templates()
  local templates = get_templates(config.get_file_templates_path())
  local empty_entry = {
    name = 'Empty',
    path = nil,
    filetype = 'text',
    vars = {},
    on_created = function() end,
  }
  table.insert(templates, empty_entry)
  return templates
end

return M
