require('lualine').setup {
  theme = 'rose-pine',
  options = {
    component_separators = { left = '', right = '' },
    section_separators = { left = '', right = '' },
    globalstatus = false,
  },
  sections = {
    lualine_a = {
      { 'mode', fmt = function(str) return str:sub(1, 1) end } },
    lualine_b = { { 'branch', fmt = function(str)
      local trim = (function(val, len)
        if #val > len + 1 then
          return val:sub(1, len) .. '…'
        end

        return val
      end)

      local first, second = str:match('^([^/]+)/(.+)$')

      if first and second then
        return trim(first, 3) .. '/' .. trim(second, 12)
      end

      return trim(str, 15)
    end },
      'diff', 'diagnostics' },
    lualine_c = { {
      'filename',
      path = 1,
    } },
  },
}
