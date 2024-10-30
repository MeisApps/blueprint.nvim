local M = {}
local plenary_path = require 'plenary.path'

M.default_settings = {
  projects = {
    default_dir = vim.fn.expand '~',
    save_path = vim.fn.stdpath 'data' .. '/blueprint-projects.json',
    picker = {
      sort_by = 'recent',
      name_color_icon = false,
      name_width = 0.5,
      show_path = false,
      path_color = nil,
      sorting_strategy = 'descending',
      layout_config = {
        width = 0.5,
        height = 0.5,
      },
    },
  },
  templates = {
    path = vim.fn.stdpath 'config' .. '/lua/blueprint/template',
    select_projects_dir = true,
    select_file_dir = true,
    picker = {
      sorting_strategy = 'descending',
      layout_config = {
        width = 0.3,
        height = 0.3,
      },
    },
  },
  scan_filetypes = true,
  scan_ignored_filetypes = { 'text', 'cmake', 'make', 'ninja' },
  scan_ignored_filenames = { 'bp-template.lua' },
}
M.user_settings = {}

function M.get_settings()
  return vim.tbl_deep_extend('force', M.default_settings, M.user_settings)
end

function M.get_projects_file_path()
  local path = plenary_path:new(M.get_settings().projects.save_path)
  if not path:exists() then
    path:write('{}', 'w')
  end
  return path:absolute()
end

function M.get_project_templates_path()
  local path = plenary_path:new(M.get_settings().templates.path) / 'project'
  if not path:exists() then
    path:mkdir { parents = true }
  end
  return path:absolute()
end

function M.get_file_templates_path()
  local path = plenary_path:new(M.get_settings().templates.path) / 'file'
  if not path:exists() then
    path:mkdir { parents = true }
  end
  return path:absolute()
end

return M
