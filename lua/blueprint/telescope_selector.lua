local M = {}
local config = require 'blueprint.config'
local utils = require 'blueprint.utils'
M.results = {}
M.picker = nil
M.finder = nil
M.is_projects = false
M.on_selected_func = function(_) end
M.on_create_selected_func = function(_) end
M.on_remove_selected_func = function(_) end

function M.reset()
  M.results = {}
  M.picker = nil
  M.finder = nil
  M.is_projects = false
  M.on_selected_func = function(_) end
  M.on_create_selected_func = function(_) end
  M.on_remove_selected_func = function(_) end
end

function M.on_selected(func)
  M.on_selected_func = func
end

function M.on_create_selected(func)
  M.on_create_selected_func = func
end

function M.on_remove_selected(func)
  M.on_remove_selected_func = func
end

local function build_finder()
  local finders = require 'telescope.finders'
  local entry_display = require 'telescope.pickers.entry_display'

  local displayerItems = {
    { width = 2 },
    { remaining = true },
  }
  if M.is_projects and config.get_settings().projects.picker.show_path then
    displayerItems = {
      { width = 2 },
      { width = config.get_settings().projects.picker.name_width },
      { remaining = true },
    }
  end
  local displayer = entry_display.create {
    separator = ' ',
    items = displayerItems,
  }

  M.finder = finders.new_table {
    results = M.results,
    entry_maker = function(entry)
      entry.value = entry
      entry.ordinal = entry.name

      local icon, icon_highlight = utils.get_filetype_icon(entry.filetype)
      entry.display = function(e)
        return displayer {
          { icon, icon_highlight },
          { e.name, M.is_projects and config.get_settings().projects.picker.name_color_icon and icon_highlight or nil },
          M.is_projects and config.get_settings().projects.picker.show_path and { e.path, config.get_settings().projects.picker.path_color } or nil,
        }
      end
      return entry
    end,
  }
end

function M.refresh()
  if M.picker ~= nil and M.finder ~= nil then
    build_finder()
    M.picker:refresh(M.finder, { reset_prompt = true })
  end
end

function M.open(title, is_projects)
  M.is_projects = is_projects
  local pickers = require 'telescope.pickers'
  local actions_state = require 'telescope.actions.state'
  local actions = require 'telescope.actions'
  local sorters = require 'telescope.sorters'

  local custom_sorter = function(opts)
    local fzy = require 'telescope.algos.fzy'
    local OFFSET = -fzy.get_score_floor()
    opts = opts or {}
    return sorters.Sorter:new {
      discard = true,
      scoring_function = function(_, prompt, _, entry)
        if not fzy.has_match(prompt, entry.value.name) then
          return -1
        end
        local fzy_score = fzy.score(prompt, entry.value.name)
        if fzy_score == fzy.get_score_min() then
          return 1
        end
        return 1 / (fzy_score + OFFSET)
      end,
      highlighter = function(_, prompt, display)
        return fzy.positions(prompt, display)
      end,
    }
  end

  local layout_config = nil
  local sorting_strategy = nil
  if M.is_projects then
    layout_config = config.get_settings().projects.picker.layout_config
    sorting_strategy = config.get_settings().projects.picker.sorting_strategy
  else
    layout_config = config.get_settings().templates.picker.layout_config
    sorting_strategy = config.get_settings().templates.picker.sorting_strategy
  end

  build_finder()
  local opts = {
    prompt_title = title,
    results_title = 'Results',
    finder = M.finder,
    layout_strategy = 'horizontal',
    layout_config = layout_config,
    sorting_strategy = sorting_strategy,
    sorter = custom_sorter(),
    cwd = require('telescope.utils').buffer_dir(),
    attach_mappings = function(bufnr, map)
      map({ 'i', 'n' }, '<cr>', function() -- Enter
        actions.close(bufnr)
        local selected_entry = actions_state.get_selected_entry()
        if selected_entry ~= nil then
          M.on_selected_func(selected_entry)
        end
      end)

      map({ 'n' }, 'c', function() -- Create
        local selected_entry = actions_state.get_selected_entry()
        if selected_entry ~= nil then
          M.on_create_selected_func(selected_entry)
        end
      end)
      map({ 'n' }, 'd', function() -- Remove
        local selected_entry = actions_state.get_selected_entry()
        if selected_entry ~= nil then
          M.on_remove_selected_func(selected_entry)
        end
      end)
      return true
    end,
  }
  M.picker = pickers.new({}, opts)
  M.picker:find()
end

return M
