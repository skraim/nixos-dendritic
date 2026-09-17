local map = function(keys, func, desc, mode)
  mode = mode or 'n'
  vim.keymap.set(mode, keys, func, { desc = 'Trouble: ' .. desc })
end

map("<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0 focus=true<cr>", "Diagnostics (buffer)")
map("<leader>xX", "<cmd>Trouble diagnostics toggle focus=true<cr>", "Diagnostics (workspace)")

