# :blue_book: blueprint.nvim

Project manager and generator from templates for Neovim.

## :package: Installation

Using **[Lazy.nvim](https://github.com/folke/lazy.nvim)**:

```lua
{
  'MeisApps/blueprint.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  opts = {},
}
```

## :gear: Configuration

```lua
require 'blueprint'.setup {
  projects = {
    default_dir = vim.fn.expand '~', -- Default projects directory
    save_path = vim.fn.stdpath 'data' .. '/blueprint-projects.json', -- Saved projects file path
    picker = {
      sort_by = 'recent', -- Sort by (asc,desc,recent)
      name_color_icon = false, -- Gives project name same color as filetype icon
      name_width = 0.5, -- Width of project name column
      show_path = false, -- Show project path
      path_color = nil, -- Highlight group for project path
      sorting_strategy = 'descending', -- Telescope sorting strategy
      layout_config = { -- Telescope layout config
        width = 0.5,
        height = 0.5,
      },
    },
  },
  templates = {
    path = vim.fn.stdpath 'config' .. '/lua/blueprint/template', -- Path for templates
    select_projects_dir = true, -- Open directory picker when creating project
    select_file_dir = true, -- Open directory picker when creating file
    picker = {
      sorting_strategy = 'descending', -- Telescope sorting strategy
      layout_config = { -- Telescope layout config
        width = 0.3,
        height = 0.3,
      },
    },
  },
  scan_filetypes = true, -- Enable project/template type scan
  scan_ignored_filetypes = { 'text', 'cmake', 'make', 'ninja' },
  scan_ignored_filenames = { 'bp-template.lua' },
}
```

## :keyboard: Commands

### `:BlueprintCreate`

Create a new project.

### `:BlueprintCreateFile`

Create a new file.

### `:BlueprintOpen`

Open a project. The parameter `sort=[asc,desc,recent]` can be used to set sorting.

### `:BlueprintAdd`

Add a project. The parameter `mode=[cwd,subdirs,select]` determines what to add.
`cwd` is the default. `select` opens a picker window. `subdirs` adds all subdirectories in the current working directory.

### `:BlueprintRemove`

Removes a project. The parameter `mode=[cwd,select]` determines what to remove.

## :open_book: Templates

Templates are located at `~/.config/nvim/lua/blueprint/template/` by default. Project templates are in the `project` subdirectory and file templates are in `file`.
Each template is a subdirectory at that location. When a project is created, all files from the directory are copied to the project path.
After copying, variables are applied to the files in the target directory. They can also be put in file names. `[[bp-name]]` is a default variable specifying the project/file name.

Optionally, a `bp-template.lua` file can be created for each template. It allows exposing multiple templates from one directory and to specify additional variables:

```lua
return {
  { -- Template 1
    name = 'C++ CMake - Executable',
    vars = {
      { key = 'cmakeadd', value = 'add_executable' }, -- Variable with an already set value
      { key = 'myvar', default_value = 'def' }, -- Shows vim.ui.input with default value
      { key = 'othervar' }, -- Shows vim.ui.input
    },
    on_created = function(project)
      print('Template OnCreated event ' .. project.name .. ' ' .. project.path)
    end,
  },
  { -- Template 2
    name = 'C++ CMake - Library',
    vars = {
      { key = 'cmakeadd', value = 'add_library' }, -- [[bp-cmakeadd]]
      { key = 'myvar', default_value = 'def' }, -- [[bp-myvar]]
      { key = 'othervar' }, -- [[bp-othervar]]
    },
  },
}
```

## :electric_plug: Events

The following autocmd events are available:

- `BlueprintProjectOpenPre`
- `BlueprintProjectOpenPost`
- `BlueprintProjectCreatePre`
- `BlueprintProjectCreatePost`
- `BlueprintFileCreatePre`
- `BlueprintFileCreatePost`

**Example**: Load session after opening a project using **[persisted.nvim](https://github.com/olimorris/persisted.nvim)**

```lua
vim.api.nvim_create_autocmd('User', {
    pattern = 'BlueprintProjectOpenPost',
    callback = function()
      vim.schedule(function()
        vim.cmd 'SessionLoad'
      end)
    end,
})
```
