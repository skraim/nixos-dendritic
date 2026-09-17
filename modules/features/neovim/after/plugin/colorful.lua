require("colorful-menu").setup({
  ls = {
    lua_ls = {
      arguments_hl = "@comment",
    },
    ts_ls = {
      extra_info_hl = "@comment",
    },
    fallback = true,
    fallback_extra_info_hl = "@comment",
  },
  fallback_highlight = "@variable",
  max_width = 60,
})
