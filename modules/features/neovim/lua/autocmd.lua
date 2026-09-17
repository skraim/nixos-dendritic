-- https://gist.github.com/smnatale/692ac4f256d5f19fbcbb78fe32c87604
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  pattern = "*",
  desc = "highlight selection on yank",
  callback = function()
    vim.highlight.on_yank({ timeout = 200, visual = true })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
      vim.schedule(function()
        vim.cmd("normal! zz")
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  command = "wincmd =",
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("no_auto_comment", {}),
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

vim.api.nvim_create_autocmd("BufRead", {
  group = vim.api.nvim_create_augroup("dotenv_ft", { clear = true }),
  pattern = { ".env", ".env.*" },
  callback = function()
    vim.bo.filetype = "dosini"
  end,
})

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("active_cursorline", { clear = true }),
  callback = function()
    vim.opt_local.cursorline = true
  end,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
  group = "active_cursorline",
  callback = function()
    vim.opt_local.cursorline = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitsigns-blame",
  callback = function(ev)
    local win = vim.fn.bufwinid(ev.buf)
    if win ~= -1 then
      vim.api.nvim_win_set_width(win, 50)
    end
  end,
})

local window_binding_group = vim.api.nvim_create_augroup("disable-window-bindings", { clear = true })

local function disable_window_bindings()
  vim.opt_local.scrollbind = false
  vim.opt_local.cursorbind = false
end

vim.api.nvim_create_autocmd({ "VimEnter", "WinNew", "WinEnter", "BufWinEnter" }, {
  desc = "Prevent splits from inheriting synchronized scrolling",
  group = window_binding_group,
  callback = disable_window_bindings,
})

vim.api.nvim_create_autocmd("OptionSet", {
  desc = "Keep synchronized scrolling disabled",
  group = window_binding_group,
  pattern = { "scrollbind", "cursorbind" },
  callback = function()
    if vim.v.option_new == "1" then
      vim.schedule(disable_window_bindings)
    end
  end,
})
