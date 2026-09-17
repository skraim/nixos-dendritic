local haunt = require("haunt.api")
local haunt_picker = require("haunt.picker")

local map = function(keys, func, desc, mode)
  mode = mode or 'n'
  vim.keymap.set(mode, keys, func, { desc = '[H]aunt: ' .. desc })
end

map("<leader>ha", function() haunt.annotate() end, "[A]nnotate")
map("<leader>ht", function() haunt.toggle_annotation() end, "[T]oggle annotation")
map("<leader>hT", function() haunt.toggle_all_lines() end, "[T]oggle all annotations")
map("<leader>hd", function() haunt.delete() end, "[D]elete bookmark")
map("<leader>hD", function() haunt.clear_all() end, "[D]elete all bookmarks")
map("<leader>hp", function() haunt.prev() end, "[P]revious bookmark")
map("<leader>hn", function() haunt.next() end, "[N]ext bookmark")
map("<leader>hf", function() haunt_picker.show() end, "[F]ind picker")
map("<leader>hq", function() haunt.to_quickfix() end, "To [Q]uickfix (all)")
map("<leader>hQ", function() haunt.to_quickfix({ current_buffer = true }) end, "To [Q]uickfix (buffer)")
map("<leader>hl", function() haunt.yank_locations({ current_buffer = true }) end, "Yank [L]ocations (buffer)")
map("<leader>hL", function() haunt.yank_locations() end, "Yank [L]ocations (all)")
