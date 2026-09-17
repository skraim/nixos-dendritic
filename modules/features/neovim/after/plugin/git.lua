vim.keymap.set("n", "<leader>do", vim.cmd.DiffviewOpen, { noremap = true, silent = true, desc = '[D]iffview [O]pen' })
vim.keymap.set("n", "<leader>dc", vim.cmd.DiffviewClose, { noremap = true, silent = true, desc = '[D]iffview [C]lose' })
vim.keymap.set("n", "<leader>df", ':DiffviewFileHistory %<CR>',
  { noremap = true, silent = true, desc = '[D]iffview [F]ile History' })
