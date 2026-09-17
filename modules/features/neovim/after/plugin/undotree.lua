  vim.keymap.set('n', "<leader>ut", function()
      require('undotree').open({ command = "rightbelow 50vnew" })
  end, { desc = '[U]ndotree: [T]oggle' })
