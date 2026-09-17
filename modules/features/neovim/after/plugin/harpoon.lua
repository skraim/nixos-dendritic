local harpoon = require("harpoon")

local function read_state_file()
  local file = io.open(os.getenv("HOME") .. "/states", "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()

  local kb_layout = content:match('KB_LAYOUT="(.-)"')
  return kb_layout
end

local kb_layout = read_state_file()

if not kb_layout then
  kb_layout = 'qwerty'
end

harpoon:setup()

local map = function(keys, func, desc, mode)
  mode = mode or 'n'
  vim.keymap.set(mode, keys, func, { desc = 'Harpoon: ' .. desc })
end

map("<leader>a", function() harpoon:list():add() end, "[A]dd file")
map("<C-S-P>", function() harpoon:list():prev() end, "[P]revious file")
map("<C-S-N>", function() harpoon:list():next() end, "[N]ext file")

if kb_layout == 'qwerty' then
  map("<C-h>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, "Toggle quick menu")
  map("<C-j>", function() harpoon:list():select(1) end, "Select file 1")
  map("<C-k>", function() harpoon:list():select(2) end, "Select file 2")
  map("<C-l>", function() harpoon:list():select(3) end, "Select file 3")
  map("<C-m>", function() harpoon:list():select(4) end, "Select file 4")
end

if kb_layout == 'graphite' then
  map("<C-y>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, "Toggle quick menu")
  map("<C-h>", function() harpoon:list():select(1) end, "Select file 1")
  map("<C-a>", function() harpoon:list():select(2) end, "Select file 2")
  map("<C-e>", function() harpoon:list():select(3) end, "Select file 3")
end
