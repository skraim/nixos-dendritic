vim.opt_local.shiftwidth = 2

require('lazydev').setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
});
