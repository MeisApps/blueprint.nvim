local M = {}
local config = require 'blueprint.config'
local templates = require 'blueprint.templates'
local projects = require 'blueprint.projects'

function M.register_template(name, filetype, create_func, on_created)
  if name == nil then
    print 'Error: name must be set.'
  end
  if create_func == nil then
    print 'Error: create_func must be set.'
  end
  if type(create_func) ~= 'function' or select('#', create_func) ~= 3 then
    print 'Error: create_func must be a function which takes 3 parameters.'
  end
  local entry = {
    name = name,
    filetype = filetype or 'directory',
    vars = {},
    on_created = on_created or function() end,
    create_func = create_func,
  }
  table.insert(templates.custom_project_templates, entry)
end

function M.setup(settings)
  config.user_settings = settings or {}
  vim.api.nvim_create_user_command('BlueprintCreate', templates.cmd_create_project, { desc = 'Create project' })
  vim.api.nvim_create_user_command('BlueprintCreateFile', templates.cmd_create_file, { desc = 'Create file' })
  vim.api.nvim_create_user_command('BlueprintOpen', projects.cmd_open_project, { desc = 'Open project', nargs = '*' })
  vim.api.nvim_create_user_command('BlueprintAdd', projects.cmd_add_project, { desc = 'Add project', nargs = '*' })
  vim.api.nvim_create_user_command('BlueprintRemove', projects.cmd_remove_project, { desc = 'Remove project', nargs = '*' })
end

return M
