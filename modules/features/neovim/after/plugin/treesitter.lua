local languages = { 'lua', 'java', 'html', 'css', 'scss', 'javascript', 'typescript', 'json', 'qmljs', 'tsx', 'hyprlang', 'nix' }
local filetypes = { 'lua', 'java', 'html', 'css', 'scss', 'javascript', 'typescript', 'json', 'qml', 'typescriptreact', 'hyprlang', 'nix' }
local ts = require('nvim-treesitter')

ts.install(languages)

vim.api.nvim_create_autocmd('FileType', {
  pattern = filetypes,
  callback = function()
    vim.treesitter.start()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
