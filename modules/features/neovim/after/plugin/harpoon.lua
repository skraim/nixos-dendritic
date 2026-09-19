local harpoon = require("harpoon")
harpoon:setup()

local map = function(keys, func, desc, mode)
  mode = mode or 'n'
  vim.keymap.set(mode, keys, func, { desc = 'Harpoon: ' .. desc })
end

map("<leader>a", function() harpoon:list():add() end, "[A]dd file")
map("<C-S-P>", function() harpoon:list():prev() end, "[P]revious file")
map("<C-S-N>", function() harpoon:list():next() end, "[N]ext file")
map("<C-y>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, "Toggle quick menu")
map("<C-h>", function() harpoon:list():select(1) end, "Select file 1")
map("<C-a>", function() harpoon:list():select(2) end, "Select file 2")
map("<C-e>", function() harpoon:list():select(3) end, "Select file 3")
