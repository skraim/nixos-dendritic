''
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
package.path = config_home .. "/hypr/?.lua;" .. package.path
local colors = require "colors"
hl.config({
  general = {
    col = {
      active_border = { colors = { "rgba(" .. colors.primary .. "ee)", "rgba(" .. colors.secondary .. "ee)" }, angle = 45 },
      inactive_border = "rgba(" .. colors.background .. "aa)",
    },
  },
})
''
