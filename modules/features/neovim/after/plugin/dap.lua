local dap_view = require('dap-view')
dap_view.setup({
  winbar = {
    sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl" },
    custom_sections = {},
    controls = {
      enabled = true,
    },
  },
  windows = {
    terminal = {
      hide = { "java" },
    },
  },
  auto_toggle = true,
});

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DapBreakpointCondition" })
vim.fn.sign_define("DapStopped",
  { text = "", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "DapStoppedLine" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DapBreakpointRejected" })

local dap = require('dap')
local dap_widgets = require('dap.ui.widgets')
dap.configurations.java = dap.configurations.java or {}

local cwd = vim.fn.getcwd()
local parent_dir = vim.fn.fnamemodify(cwd, ":h")
local deploy_file = parent_dir .. "/mvn-deploy-data"

if vim.fn.filereadable(deploy_file) == 1 then
  local lines = vim.fn.readfile(deploy_file)

  for _, line in ipairs(lines) do
    local key, value = line:match('^([A-Z0-9_]+)_DEBUG_PORT%s*=%s*"?([^"]+)"?$')

    if key and value then
      local instance = key
          :lower()
          :gsub("_", "-")

      table.insert(dap.configurations.java, {
        type = "java",
        request = "attach",
        name = string.format(
          "Remote Debug (Attach) - %s (%s)",
          instance,
          value
        ),
        hostName = "127.0.0.1",
        port = value,
      })
    end
  end
end

local map = function(keys, func, desc, mode)
  mode = mode or 'n'
  vim.keymap.set(mode, keys, func, { desc = '[D]ebug: ' .. desc })
end

local debug_keymaps_active = false

local function set_debug_keymaps()
  if debug_keymaps_active then
    return
  end
  debug_keymaps_active = true

  map('<F9>', function() dap.run_to_cursor() end, 'Run to cursor')
  map('<F12>', function() dap.terminate() end, 'Treminate')
  map('<F6>', function() dap.step_over() end, 'Step Over')
  map('<F2>', function() dap.step_into() end, 'Step Into')
  map('<F5>', function() dap.step_out() end, 'Step Out')
  map('<F4>', function() dap.step_back() end, 'Step Back')

  map('<Leader>dh', function() dap_widgets.hover() end, "[H]over", { 'n', 'v' })
  map('<leader>dw', function() dap_view.add_expr() end, 'Add to [W]atch list', { 'n', 'v' })

  map('<leader>dW', function() dap_view.show_view('watches') end, '[W]atches')
  map('<leader>dE', function() dap_view.show_view('exceptions') end, '[E]xceptions')
  map('<leader>dB', function() dap_view.show_view('breakpoints') end, '[B]reakpoints')
  map('<leader>dR', function() dap_view.show_view('repl') end, '[R]epl')
  map('<leader>dT', function() dap_view.show_view('threads') end, '[T]hreads')
  map('<leader>dS', function() dap_view.show_view('scopes') end, '[S]copes')
end

local function clear_debug_keymaps()
  if not debug_keymaps_active then
    return
  end
  debug_keymaps_active = false

  pcall(vim.keymap.del, 'n', '<F9>')
  pcall(vim.keymap.del, 'n', '<F12>')
  pcall(vim.keymap.del, 'n', '<F6>')
  pcall(vim.keymap.del, 'n', '<F2>')
  pcall(vim.keymap.del, 'n', '<F5>')
  pcall(vim.keymap.del, 'n', '<F4>')

  pcall(vim.keymap.del, 'n', '<Leader>dh')
  pcall(vim.keymap.del, 'v', '<Leader>dh')

  pcall(vim.keymap.del, 'n', '<leader>dw')
  pcall(vim.keymap.del, 'v', '<leader>dw')

  pcall(vim.keymap.del, 'n', '<leader>dW')
  pcall(vim.keymap.del, 'n', '<leader>dE')
  pcall(vim.keymap.del, 'n', '<leader>dB')
  pcall(vim.keymap.del, 'n', '<leader>dR')
  pcall(vim.keymap.del, 'n', '<leader>dT')
  pcall(vim.keymap.del, 'n', '<leader>dS')
end

map('<F8>', function() dap.continue() end, 'Run/Continue')
map('<Leader>b', function() dap.toggle_breakpoint() end, "Toggle [B]reakpoint")
map('<leader>B', function()
  local input = vim.fn.input 'Condition: '
  if input ~= '' then
    vim.cmd(string.format("lua require('dap').set_breakpoint('%s')", input))
  end
end, 'Conditional [B]reakpoint')

dap.listeners.after.event_initialized["debug_keymaps"] = function() set_debug_keymaps() end
dap.listeners.before.event_terminated["debug_keymaps"] = function() clear_debug_keymaps() end
dap.listeners.before.event_exited["debug_keymaps"] = function() clear_debug_keymaps() end
dap.listeners.before.disconnect["debug_keymaps"] = function() clear_debug_keymaps() end
