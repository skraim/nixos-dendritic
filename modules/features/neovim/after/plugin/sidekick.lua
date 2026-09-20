local haunt_sk = require("haunt.sidekick")
local sk_cli = require("sidekick.cli")
require('sidekick').setup({
  nes = {
    enabled = false,
  },
  copilot = {
    status = {
      enabled = false
    }
  },
  cli = {
    prompts = {
      haunt_all = function()
        return haunt_sk.get_locations()
      end,
      haunt_buffer = function()
        return haunt_sk.get_locations({ current_buffer = true })
      end,
    },
  }
});

local map = function(keys, func, desc, mode)
  mode = mode or 'n'
  vim.keymap.set(mode, keys, func, { desc = '[A]I: ' .. desc })
end

map(
  "<leader>aa",
  function() sk_cli.toggle({ focus = true, filter = { installed = true } }) end,
  "Toggle [A]I"
)

map("<leader>at", function()
  sk_cli.send({ focus = true, filter = { installed = true }, msg = "{this}" })
end, "Send [T]his", { "x", "n" })

map("<leader>af", function()
  sk_cli.send({ focus = true, filter = { installed = true }, msg = "{file}" })
end, "Send [F]ile")

map("<leader>av", function()
  sk_cli.send({ focus = true, filter = { installed = true }, msg = "{selection}" })
end, "Send [V]isual Selection", "x")

map("<leader>ap", function()
  sk_cli.prompt()
end, "Select [P]rompt", { "n", "x" })
