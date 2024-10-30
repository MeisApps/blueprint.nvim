local M = {}
local plenary_scandir = require 'plenary.scandir'
M.on_selected_func = function(_) end

local title_text = 'Select a directory'
local function select_directory(current_dir)
  current_dir = current_dir or vim.fn.expand '~'
  local directories = plenary_scandir.scan_dir(current_dir, { only_dirs = true, depth = 1 })
  table.insert(directories, 1, '. (Select)')
  table.insert(directories, 2, '.. (Up)')

  vim.ui.select(directories, {
    prompt = title_text .. ' [' .. current_dir .. ']',
  }, function(choice)
    if choice then
      if choice == '. (Select)' then
        M.on_selected_func(current_dir)
      elseif choice == '.. (Up)' then
        local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
        select_directory(parent_dir)
      else
        select_directory(choice)
      end
    else
      print 'Canceled.'
    end
  end)
end

function M.on_selected(func)
  M.on_selected_func = func
end

function M.reset()
  M.on_selected_func = function(_) end
end

function M.open(title, start_dir)
  if title ~= nil then
    title_text = title
  end
  select_directory(start_dir)
end

return M
