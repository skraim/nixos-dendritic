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

vim.g.mapleader = " "

local map = function(keys, func, desc, mode)
  mode = mode or 'n'
  vim.keymap.set(mode, keys, func, { desc = desc })
end

map("<Esc>", "<cmd>noh<CR>", "Clear Highlights")
map('<leader>p', '"_dP', "[P]aste without yanking", 'v')
map('<leader>p', '"+p', "[P]aste from system clipboard")
map('<leader>cq', '<cmd>cclose<CR>', "[P]revious quickfix item")

if kb_layout == 'qwerty' then
  map('<leader>y', '"+y', "[Y]ank to system clipboard", { 'n', 'v' })
  map('<leader>Y', '"+Y', "[Y]ank line to system clipboard")

  map('J', ":m '>+1<CR>gv=gv", "Move line down", 'v')
  map('K', ":m '<-2<CR>gv=gv", "Move line up", 'v')

  map('J', 'mzJ`z', "Join lines")

  map('n', 'nzzzv', "Next search result (centered)")
  map('N', 'Nzzzv', "Previous search result (centered)")
end

if kb_layout == 'graphite' then
  vim.keymap.set({ "n", "v", "o" }, "y", "h", { noremap = true, silent = true })
  vim.keymap.set({ "n", "v", "o" }, "Y", "H", { noremap = true, silent = true })
  vim.keymap.set({ "n", "v", "o" }, "l", "y", { noremap = true, silent = true })
  vim.keymap.set({ "n", "v", "o" }, "L", "Y", { noremap = true, silent = true })
  vim.keymap.set({ "n", "v", "o" }, "k", "a", { noremap = true, silent = true })
  vim.keymap.set({ "n", "v", "o" }, "K", "A", { noremap = true, silent = true })
  vim.keymap.set({ "n", "v", "o" }, "a", "k", { noremap = true, silent = true })
  vim.keymap.set({ "n", "v", "o" }, "A", "K", { noremap = true, silent = true })
  vim.keymap.set({ "n", "v", "o" }, "e", "l", { noremap = true, silent = true })
  vim.keymap.set({ "n", "v", "o" }, "E", "L", { noremap = true, silent = true })
  vim.keymap.set({ "n", "v", "o" }, "j", "e", { noremap = true, silent = true })
  vim.keymap.set({ "v", "o" }, "J", "E", { noremap = true, silent = true })
  vim.keymap.set({ "n", "v", "o" }, "h", "j", { noremap = true, silent = true })
  vim.keymap.set({ "v", "o" }, "H", "J", { noremap = true, silent = true })

  map('<leader>l', '"+y', "Yank to system clipboard", { 'n', 'v' })
  map('<leader>L', '"+Y', "Yank line to system clipboard")

  map('H', ":m '>+1<CR>gv=gv", "Move line down", 'v')
  map('A', ":m '<-2<CR>gv=gv", "Move line up", 'v')

  map('J', 'mzJ`z', "Join lines")

  map('n', 'nzzzv', "Next search result (centered)")
  map('N', 'Nzzzv', "Previous search result (centered)")

  vim.keymap.set({ "n", "t" }, "<C-w>y", "<cmd>wincmd h<CR>",
    { noremap = true, silent = true, desc = "[W]indow: Go to left window" })
  vim.keymap.set({ "n", "t" }, "<C-w>h", "<cmd>wincmd j<CR>",
    { noremap = true, silent = true, desc = "[W]indow: Go to lower window" })
  vim.keymap.set({ "n", "t" }, "<C-W>a", "<cmd>wincmd k<CR>",
    { noremap = true, silent = true, desc = "[W]indow: Go to upper window" })
  vim.keymap.set({ "n", "t" }, "<C-W>e", "<cmd>wincmd l<CR>",
    { noremap = true, silent = true, desc = "[W]indow: Go to right window" })
  vim.keymap.set({ "n", "t" }, "<C-w>Y", "<cmd>wincmd H<CR>",
    { noremap = true, silent = true, desc = "[W]indow: Move window to far left" })
  vim.keymap.set({ "n", "t" }, "<C-w>H", "<cmd>wincmd J<CR>",
    { noremap = true, silent = true, desc = "[W]indow: Move window to very bottom" })
  vim.keymap.set({ "n", "t" }, "<C-W>A", "<cmd>wincmd K<CR>",
    { noremap = true, silent = true, desc = "[W]indow: Move window to very top" })
  vim.keymap.set({ "n", "t" }, "<C-W>E", "<cmd>wincmd L<CR>",
    { noremap = true, silent = true, desc = "[W]indow: Move window to far right" })
end
