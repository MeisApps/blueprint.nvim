local M = {}
local config = require 'blueprint.config'
local plenary_path = require 'plenary.path'
local plenary_scandir = require 'plenary.scandir'
local web_devicons = require 'nvim-web-devicons'

function M.parse_args(args)
  local args_map = { map = {}, other = {} }
  for arg in string.gmatch(args, '%S+') do
    local key, value = string.match(arg, '^(%S+)=(%S+)$')
    if key and value then
      args_map.map[key] = value
    else
      table.insert(args_map.other, arg)
    end
  end
  return args_map
end

function M.get_directory_filetype(dir)
  if not config.get_settings().scan_filetypes then
    return 'directory'
  end
  local filetype_count = {}
  local most_frequent_type = nil
  local max_count = 0
  for _, path in ipairs(plenary_scandir.scan_dir(dir, { hidden = false, respect_gitignore = true })) do
    local file = plenary_path:new(path)
    if file:is_file() then
      local filename = vim.fn.fnamemodify(file:absolute(), ':t')
      for _, ignored_filename in ipairs(config.get_settings().scan_ignored_filenames) do
        if filename == ignored_filename then
          goto continue
        end
      end
      local filetype = vim.filetype.match { filename = file.filename }
      if filetype == nil then
        goto continue
      end
      for _, ignored_filetype in ipairs(config.get_settings().scan_ignored_filetypes) do
        if filetype == ignored_filetype then
          goto continue
        end
      end
      filetype_count[filetype] = (filetype_count[filetype] or 0) + 1
      if filetype_count[filetype] > max_count then
        max_count = filetype_count[filetype]
        most_frequent_type = filetype
      end
    end
    ::continue::
  end
  return most_frequent_type
end

function M.get_filetype_icon(filetype)
  if filetype == 'directory' then
    return '', 'DevIconLua'
  end
  local icon, icon_highlight = web_devicons.get_icon_by_filetype(filetype, { default = true })
  if icon == nil then
    return '', 'DevIconLua'
  end
  return icon, icon_highlight
end

return M
