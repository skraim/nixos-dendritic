{
  inputs,
  self,
  ...
}: {
  flake.modules.neovim.general = {
    config,
    wlib,
    lib,
    pkgs,
    ...
  }: {
    options.mason.lspServers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "LSP servers that individual Neovim modules request from Mason.";
    };

    options.mason.ensureToolInstalled = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Tools that individual Neovim modules request from Mason.";
    };

    options.ftpluginFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = "Ftplugin files contributed by individual Neovim modules.";
    };

    config = {
      settings.config_directory = pkgs.runCommand "neovim-config" {} ''
        mkdir -p "$out/after/ftplugin"
        ln -s ${./lua} "$out/lua"
        ln -s ${./after/plugin} "$out/after/plugin"
        ${lib.concatMapStringsSep "\n" (file: ''
            ln -s ${file} "$out/after/ftplugin/${builtins.baseNameOf file}"
          '')
          config.ftpluginFiles}
      '';
      runtimePkgs = with pkgs; [
        ripgrep
        unzip
        tree-sitter
        self.packages.${stdenv.hostPlatform.system}.git
      ];
      specs = {
        init = {
          data = null;
          before = ["MAIN_INIT"];
          config = ''
            require 'remap'
            require 'autocmd'
            require 'set'
          '';
        };
        base = {
          data = with pkgs; [
            vimPlugins.nvim-web-devicons
            vimPlugins.plenary-nvim
          ];
          config = ''vim.cmd.packadd('nvim.undotree');'';
        };
        snacks = {
          data = with pkgs; [
            vimPlugins.snacks-nvim
          ];
          after = ["base"];
          # before = ["view"];
          config =
            #lua
            ''
              require("snacks").setup({
                bigfile = {
                  enabled = true,
                  notify = false
                },
                dim = { animate = { enabled = false } },
                indent = { enabled = true, animate = { enabled = false } },
                picker = {
                  enabled = true,
                  win = {
                    input = {
                      keys = {
                        ["<C-c>"] = "cancel",
                        ["<c-u>"] = { "preview_scroll_up", mode = { "i", "n" } },
                        ["<c-d>"] = { "preview_scroll_down", mode = { "i", "n" } },
                        ["<c-h>"] = { "list_down", mode = { "i", "n" } },
                        ["<c-a>"] = { "list_up", mode = { "i", "n" } },
                        ["<c-w>Y"] = "layout_left",
                        ["<c-w>H"] = "layout_bottom",
                        ["<c-w>A"] = "layout_top",
                        ["<c-w>E"] = "layout_right",
                        ["h"] = "list_down",
                        ["a"] = "list_up",
                        ["k"] = false,
                      }
                    }
                  },
                  sources = {
                    explorer = {
                      hidden = true,
                      win = {
                        list = {
                          keys = {
                            ["<CR>"] = "confirm",
                            ["<c-p>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
                            ["<c-w>Y"] = "layout_left",
                            ["<c-w>H"] = "layout_bottom",
                            ["<c-w>A"] = "layout_top",
                            ["<c-w>E"] = "layout_right",
                            ["<c-f>"] = "toggle_maximize",
                            ["h"] = "list_down",
                            ["a"] = "list_up",
                            ["e"] = "confirm",
                            ["y"] = "explorer_close",
                            ["k"] = "explorer_add",
                            ["s"] = "search_in_directory",
                            ["<leader>/"] = false,
                            ["<c-g>"] = false,
                            ["<c-a>"] = false,
                            ["l"] = "copy_item_cwd_path",
                            ["L"] = "copy_item_path",
                            ["P"] = "aemsync_push",
                          }
                        }
                      },
                      actions = {
                        copy_item_cwd_path = {
                          action = function(_, item)
                            if not item or not item.file then
                              return
                            end

                            local path = vim.fn.fnamemodify(item.file, ":.")
                            vim.fn.setreg("+", path)
                            Snacks.notify.info("Yanked `" .. path .. "`")
                          end,
                        },
                        copy_item_path = {
                          action = function(_, item)
                            if not item then
                              return
                            end

                            local vals = {
                              ["BASENAME"] = vim.fn.fnamemodify(item.file, ":t:r"),
                              ["EXTENSION"] = vim.fn.fnamemodify(item.file, ":t:e"),
                              ["FILENAME"] = vim.fn.fnamemodify(item.file, ":t"),
                              ["PATH"] = item.file,
                              ["PATH (CWD)"] = vim.fn.fnamemodify(item.file, ":."),
                              ["PATH (HOME)"] = vim.fn.fnamemodify(item.file, ":~"),
                              ["URI"] = vim.uri_from_fname(item.file),
                            }

                            local options = vim.tbl_filter(function(val)
                              return vals[val] ~= ""
                            end, vim.tbl_keys(vals))
                            if vim.tbl_isempty(options) then
                              vim.notify("No values to copy", vim.log.levels.WARN)
                              return
                            end
                            table.sort(options)
                            vim.ui.select(options, {
                              prompt = "Choose to copy to clipboard:",
                              format_item = function(list_item)
                                return ("%s: %s"):format(list_item, vals[list_item])
                              end,
                            }, function(choice)
                                local result = vals[choice]
                                if result then
                                  vim.fn.setreg("+", result)
                                  Snacks.notify.info("Yanked `" .. result .. "`")
                                end
                              end)
                          end,
                        },
                        search_in_directory = {
                          action = function(_, item)
                            if not item then
                              return
                            end
                            local dir = vim.fn.fnamemodify(item.file, ":p:h")
                            Snacks.picker.grep({
                              cwd = dir,
                              cmd = "rg",
                              args = {
                                "-g", "!.git",
                                "-g", "!node_modules",
                                "-g", "!dist",
                                "-g", "!build",
                                "-g", "!coverage",
                                "-g", "!.DS_Store",
                                "-g", "!.docusaurus",
                                "-g", "!.dart_tool",
                              },
                              show_empty = true,
                              hidden = true,
                              ignored = true,
                              follow = false,
                              supports_live = true,
                            })
                          end,
                        },
                        aemsync_push = {
                          action = function(_, item)
                            if not item then
                              Snacks.notify.warn("No item selected")
                              return
                            end

                            local path = vim.fn.fnamemodify(item.file, ":p")
                            if not path then
                              Snacks.notify.warn("No file path available")
                              return
                            end

                            if not path:match("jcr_root") then
                              Snacks.notify.error("Not an AEM path: must be inside jcr_root directory")
                              return
                            end

                            if vim.fn.executable("aemsync") ~= 1 then
                              Snacks.notify.error("aemsync not found in PATH")
                              return
                            end

                            Snacks.notify.info("Pushing to AEM: " .. vim.fn.fnamemodify(path, ":t"))

                            vim.fn.jobstart({ "aemsync", "-p", path }, {
                              stdout_buffered = true,
                              stderr_buffered = true,
                              on_stdout = function(_, data)
                                if data and #data > 0 then
                                  local output = table.concat(data, "\n")
                                  if output:match("Pushed") or output:match("OK") then
                                    Snacks.notify.info("AEM push successful:\n" .. output)
                                  elseif output ~= "" then
                                    Snacks.notify.info(output)
                                  end
                                end
                              end,
                              on_stderr = function(_, data)
                                if data and #data > 0 then
                                  local output = vim.trim(table.concat(data, "\n"))
                                  if output ~= "" then
                                    Snacks.notify.error("AEM push error:\n" .. output)
                                  end
                                end
                              end,
                              on_exit = function(_, exit_code)
                                if exit_code ~= 0 then
                                  Snacks.notify.error("AEM push failed (exit code: " .. exit_code .. ")")
                                end
                              end,
                            })
                          end,
                        },
                      }
                    }
                  },
                  formatters = {
                    file = {
                      truncate = 80
                    }
                  }
                },
                explorer = {
                  replace_netrw = true,
                },
                quickfile = { enabled = true },
                scope = { enabled = true },
                statuscolumn = { enabled = true }
              })

              local map = function(lhs, rhs, desc)
                vim.keymap.set("n", lhs, rhs, { desc = desc })
              end

              map("<leader><space>", function() Snacks.picker.smart({ multi = { "buffers", "files" }, hidden = true }) end, "Smart Find Files")
              map("<leader>,",       function() Snacks.picker.buffers({ hidden = true }) end, "Buffers")
              map("<leader>/",       function() Snacks.picker.grep({ hidden = true }) end, "Grep")
              map("<leader>ff",      function() Snacks.picker.files({ hidden = true }) end, "Find Files")
              map("<leader>fw",      function() Snacks.picker.grep_word({ hidden = true }) end, "Find Selected Word")
              map("<leader>e",       function() Snacks.picker.explorer({ auto_close = true, layout = { preset = "dropdown" } }) end, "Open Explorer")
              map("<leader>E",       function() Snacks.picker.explorer() end, "Open Explorer No Close")
              map("<leader>fg",      function() Snacks.picker.git_files({ submodules = true }) end, "Find Git Files")
              map("<leader>gs",      function() Snacks.picker.git_status({ submodules = true }) end, "Git Status")
              map("<leader>fm",      function() Snacks.picker.marks() end, "Marks")
              map("gd",              function() Snacks.picker.lsp_definitions() end, "Goto Definition")
              map("gD",              function() Snacks.picker.lsp_declarations() end, "Goto Declaration")
              map("gr",              function() Snacks.picker.lsp_references() end, "References")
              map("gI",              function() Snacks.picker.lsp_implementations() end, "Goto Implementation")
              map("gy",              function() Snacks.picker.lsp_type_definitions() end, "Goto T[y]pe Definition")
              map("<leader>Z",       function() Snacks.zen() end, "Toggle Zen Mode")
              map("<leader>z",       function() Snacks.zen.zoom() end, "Toggle Zoom")
              map("<leader>.",       function() Snacks.scratch() end, "Toggle Scratch Buffer")
              map("<leader>S",       function() Snacks.scratch.select() end, "Select Scratch Buffer")
              map("<C-/>",           function() Snacks.terminal() end, "Toggle Terminal")

              Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>ts")
              Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>tw")
              Snacks.toggle.option("relativenumber", { name = "Relative Numbers" }):map("<leader>tr")
              Snacks.toggle.diagnostics():map("<leader>td")
              Snacks.toggle.inlay_hints():map("<leader>th")
            '';
        };
        view = {
          data = with pkgs; [
            vimPlugins.fidget-nvim
            vimPlugins.nvim-highlight-colors
            vimPlugins.lualine-nvim
            vimPlugins.render-markdown-nvim
            vimPlugins.checkmate-nvim
            vimPlugins.colorful-menu-nvim
            vimPlugins.smartcolumn-nvim
            vimPlugins.tiny-inline-diagnostic-nvim
            vimPlugins.rose-pine
          ];
          after = ["base"];
          config =
            #lua
            ''
              require('render-markdown').setup({})
              require('smartcolumn').setup({ colorcolumn = '120' })
              require('fidget').setup {
                notification = {
                  window = {
                    winblend = 0
                  }
                }
              }
              require('nvim-highlight-colors').setup({})
              require('checkmate').setup({})
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
              require("tiny-inline-diagnostic").setup({
                preset = "simple",
                transparent_cursorline = false,
                options = {
                  multilines = {
                    enabled = true,
                  },
                },
              })
            '';
        };
        completion = {
          data = with pkgs; [
            vimPlugins.friendly-snippets
            vimPlugins.lspkind-nvim
            vimPlugins.luasnip
            vimPlugins.blink-cmp
          ];
          after = ["view"];
          config =
            #lua
            ''
              require("blink.cmp").setup({
                keymap = {
                  preset = 'none',
                  ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
                  ['<C-e>'] = { 'cancel' },
                  ['<Tab>'] = { 'select_and_accept', 'snippet_forward', 'fallback' },
                  ['<Up>'] = { 'select_prev', 'fallback' },
                  ['<Down>'] = { 'select_next', 'fallback' },
                  ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
                  ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },
                  ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
                  ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
                  ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
                  ['<C-s>'] = { 'show_signature', 'hide_signature', 'fallback' },
                },

                appearance = {
                  nerd_font_variant = 'mono'
                },

                completion = {
                  keyword = {
                    range = 'full'
                  },
                  menu = {
                    auto_show = false,
                    min_width = 60,
                    max_height = 15,
                    draw = {
                      padding = 1,
                      columns = { { "kind_icon" }, { "label", gap = 1 } },
                      components = {
                        kind_icon = {
                          text = function(ctx)
                            local icon = ctx.kind_icon
                            if vim.tbl_contains({ "Path" }, ctx.source_name) then
                              local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                              if dev_icon then
                                icon = dev_icon
                              end
                            else
                              icon = require("lspkind").symbolic(ctx.kind)
                            end

                            return icon .. ctx.icon_gap
                          end,

                          highlight = function(ctx)
                            local hl = ctx.kind_hl
                            if vim.tbl_contains({ "Path" }, ctx.source_name) then
                              local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                              if dev_icon then
                                hl = dev_hl
                              end
                            end
                            return hl
                          end,
                        },
                        label = {
                          text = function(ctx)
                            return require("colorful-menu").blink_components_text(ctx)
                          end,
                          highlight = function(ctx)
                            return require("colorful-menu").blink_components_highlight(ctx)
                          end,
                        },
                      },
                    },
                  },

                  documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 500,
                  },

                  trigger = { show_on_trigger_character = true },

                  ghost_text = { enabled = true },
                },

                signature = { enabled = true },

                sources = {
                  default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
                  providers = {
                    lazydev = {
                      name = 'LazyDev',
                      module = 'lazydev.integrations.blink',
                      score_offset = 100,
                    },
                    path = {
                      opts = {
                        get_cwd = function(_)
                          return vim.fn.getcwd()
                        end,
                      },
                    },
                  },
                },

                fuzzy = { implementation = "prefer_rust" },

                cmdline = {
                  enabled = true,
                  keymap = {
                    preset = 'none',
                    ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
                    ['<C-n>'] = { 'show_and_insert', 'select_next' },
                    ['<C-p>'] = { 'show_and_insert', 'select_prev' },
                    ['<Tab>'] = { 'select_and_accept' },
                    ['<C-e>'] = { 'cancel' },
                  },
                  sources = function()
                    local type = vim.fn.getcmdtype()
                    if type == '/' or type == '?' then return { 'buffer' } end
                    if type == ':' or type == '@' then return { 'cmdline' } end
                    return {}
                  end,
                  completion = {
                    trigger = {
                      show_on_blocked_trigger_characters = {},
                      show_on_x_blocked_trigger_characters = {},
                    },
                    list = {
                      selection = {
                        preselect = true,
                        auto_insert = true,
                      },
                    },
                    menu = {
                      auto_show = true,
                    },
                    ghost_text = { enabled = true }
                  }
                }
              });
            '';
        };
        git = {
          data = with pkgs; [
            vimPlugins.gitsigns-nvim
            vimPlugins.diffview-nvim
          ];
          after = ["base"];
          config =
            #lua
            ''
              require('gitsigns').setup({
                current_line_blame = true,
                on_attach = function(bufnr)
                  local function map(mode, lhs, rhs, desc)
                    local opts = { noremap = true, silent = true, desc = 'Git: ' .. desc }
                    vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)
                  end

                  map('n', '<leader>hs', ':Gitsigns stage_hunk<CR>', '[H]unk [S]tage')
                  map('v', '<leader>hs', ':Gitsigns stage_hunk<CR>', '[H]unk [S]tage')
                  map('n', '<leader>hr', ':Gitsigns reset_hunk<CR>', '[H]unk [R]eset')
                  map('v', '<leader>hr', ':Gitsigns reset_hunk<CR>', '[H]unk [R]eset')
                  map('n', '[h', ':Gitsigns nav_hunk prev target=all --preview<CR>', '[H]unk Previous')
                  map('v', '[h', ':Gitsigns nav_hunk prev target=all --preview<CR>', '[H]unk Previous')
                  map('n', ']h', ':Gitsigns nav_hunk next target=all --preview<CR>', '[H]unk Next')
                  map('v', ']h', ':Gitsigns nav_hunk next target=all --preview<CR>', '[H]unk Next')
                  map('n', '<leader>hu', ':Gitsigns undo_stage_hunk<CR>', '[H]unk [U]ndo stage')
                  map('n', '<leader>hp', ':Gitsigns preview_hunk<CR>', '[H]unk [P]review')
                  map('n', '<leader>gb', ':Gitsigns blame<CR>', '[B]lame')
                end
              })

              local actions = require("diffview.actions")
              require("diffview").setup({
                keymaps = {
                  disable_defaults = true,
                  view = {
                    { "n", "<tab>",      actions.select_next_entry,             { desc = "Open the diff for the next file" } },
                    { "n", "<s-tab>",    actions.select_prev_entry,             { desc = "Open the diff for the previous file" } },
                    { "n", "<leader>gg", actions.select_first_entry,            { desc = "Open the diff for the first file" } },
                    { "n", "<leader>G",  actions.select_last_entry,             { desc = "Open the diff for the last file" } },
                    { "n", "gf",         actions.goto_file_edit,                { desc = "Open the file in the previous tabpage" } },
                    { "n", "<C-w><C-f>", actions.goto_file_split,               { desc = "Open the file in a new split" } },
                    { "n", "<C-w>gf",    actions.goto_file_tab,                 { desc = "Open the file in a new tabpage" } },
                    { "n", "<leader>e",  actions.focus_files,                   { desc = "Bring focus to the file panel" } },
                    { "n", "<leader>t",  actions.toggle_files,                  { desc = "Toggle the file panel." } },
                    { "n", "<C-j>",      actions.cycle_layout,                  { desc = "Cycle through available layouts." } },
                    { "n", "<C-p>",      actions.prev_conflict,                 { desc = "In the merge-tool: jump to the previous conflict" } },
                    { "n", "<C-n>",      actions.next_conflict,                 { desc = "In the merge-tool: jump to the next conflict" } },
                    { "n", "<leader>co", actions.conflict_choose("ours"),       { desc = "Choose the OURS version of a conflict" } },
                    { "n", "<leader>ct", actions.conflict_choose("theirs"),     { desc = "Choose the THEIRS version of a conflict" } },
                    { "n", "<leader>cb", actions.conflict_choose("base"),       { desc = "Choose the BASE version of a conflict" } },
                    { "n", "<leader>ca", actions.conflict_choose("all"),        { desc = "Choose all the versions of a conflict" } },
                    { "n", "<leader>cx", actions.conflict_choose("none"),       { desc = "Delete the conflict region" } },
                    { "n", "<leader>cO", actions.conflict_choose_all("ours"),   { desc = "Choose the OURS version of a conflict for the whole file" } },
                    { "n", "<leader>cT", actions.conflict_choose_all("theirs"), { desc = "Choose the THEIRS version of a conflict for the whole file" } },
                    { "n", "<leader>cB", actions.conflict_choose_all("base"),   { desc = "Choose the BASE version of a conflict for the whole file" } },
                    { "n", "<leader>cA", actions.conflict_choose_all("all"),    { desc = "Choose all the versions of a conflict for the whole file" } },
                    { "n", "<leader>cX", actions.conflict_choose_all("none"),   { desc = "Delete the conflict region for the whole file" } },
                  },
                  diff1 = {
                    { "n", "g?", actions.help({ "view", "diff1" }), { desc = "Open the help panel" } },
                  },
                  diff2 = {
                    { "n", "g?", actions.help({ "view", "diff2" }), { desc = "Open the help panel" } },
                  },
                  diff3 = {
                    { { "n", "x" }, "2do", actions.diffget("ours"),           { desc = "Obtain the diff hunk from the OURS version of the file" } },
                    { { "n", "x" }, "3do", actions.diffget("theirs"),         { desc = "Obtain the diff hunk from the THEIRS version of the file" } },
                    { "n",          "g?",  actions.help({ "view", "diff3" }), { desc = "Open the help panel" } },
                  },
                  diff4 = {
                    { { "n", "x" }, "1do", actions.diffget("base"),           { desc = "Obtain the diff hunk from the BASE version of the file" } },
                    { { "n", "x" }, "2do", actions.diffget("ours"),           { desc = "Obtain the diff hunk from the OURS version of the file" } },
                    { { "n", "x" }, "3do", actions.diffget("theirs"),         { desc = "Obtain the diff hunk from the THEIRS version of the file" } },
                    { "n",          "g?",  actions.help({ "view", "diff4" }), { desc = "Open the help panel" } },
                  },
                  file_panel = {
                    { "n", "h",             actions.next_entry,                    { desc = "Bring the cursor to the next file entry" } },
                    { "n", "<down>",        actions.next_entry,                    { desc = "Bring the cursor to the next file entry" } },
                    { "n", "a",             actions.prev_entry,                    { desc = "Bring the cursor to the previous file entry" } },
                    { "n", "<up>",          actions.prev_entry,                    { desc = "Bring the cursor to the previous file entry" } },
                    { "n", "<cr>",          actions.select_entry,                  { desc = "Open the diff for the selected entry" } },
                    { "n", "o",             actions.select_entry,                  { desc = "Open the diff for the selected entry" } },
                    { "n", "e",             actions.select_entry,                  { desc = "Open the diff for the selected entry" } },
                    { "n", "<2-LeftMouse>", actions.select_entry,                  { desc = "Open the diff for the selected entry" } },
                    { "n", "-",             actions.toggle_stage_entry,            { desc = "Stage / unstage the selected entry" } },
                    { "n", "s",             actions.toggle_stage_entry,            { desc = "Stage / unstage the selected entry" } },
                    { "n", "S",             actions.stage_all,                     { desc = "Stage all entries" } },
                    { "n", "U",             actions.unstage_all,                   { desc = "Unstage all entries" } },
                    { "n", "X",             actions.restore_entry,                 { desc = "Restore entry to the state on the left side" } },
                    { "n", "L",             actions.open_commit_log,               { desc = "Open the commit log panel" } },
                    { "n", "zo",            actions.open_fold,                     { desc = "Expand fold" } },
                    { "n", "y",             actions.close_fold,                    { desc = "Collapse fold" } },
                    { "n", "zc",            actions.close_fold,                    { desc = "Collapse fold" } },
                    { "n", "za",            actions.toggle_fold,                   { desc = "Toggle fold" } },
                    { "n", "zR",            actions.open_all_folds,                { desc = "Expand all folds" } },
                    { "n", "zM",            actions.close_all_folds,               { desc = "Collapse all folds" } },
                    { "n", "<c-b>",         actions.scroll_view(-0.25),            { desc = "Scroll the view up" } },
                    { "n", "<c-f>",         actions.scroll_view(0.25),             { desc = "Scroll the view down" } },
                    { "n", "<tab>",         actions.select_next_entry,             { desc = "Open the diff for the next file" } },
                    { "n", "<s-tab>",       actions.select_prev_entry,             { desc = "Open the diff for the previous file" } },
                    { "n", "[F",            actions.select_first_entry,            { desc = "Open the diff for the first file" } },
                    { "n", "]F",            actions.select_last_entry,             { desc = "Open the diff for the last file" } },
                    { "n", "gf",            actions.goto_file_edit,                { desc = "Open the file in the previous tabpage" } },
                    { "n", "<C-w><C-f>",    actions.goto_file_split,               { desc = "Open the file in a new split" } },
                    { "n", "<C-w>gf",       actions.goto_file_tab,                 { desc = "Open the file in a new tabpage" } },
                    { "n", "i",             actions.listing_style,                 { desc = "Toggle between 'list' and 'tree' views" } },
                    { "n", "f",             actions.toggle_flatten_dirs,           { desc = "Flatten empty subdirectories in tree listing style" } },
                    { "n", "R",             actions.refresh_files,                 { desc = "Update stats and entries in the file list" } },
                    { "n", "<leader>e",     actions.focus_files,                   { desc = "Bring focus to the file panel" } },
                    { "n", "<leader>b",     actions.toggle_files,                  { desc = "Toggle the file panel" } },
                    { "n", "g<C-x>",        actions.cycle_layout,                  { desc = "Cycle available layouts" } },
                    { "n", "[x",            actions.prev_conflict,                 { desc = "Go to the previous conflict" } },
                    { "n", "]x",            actions.next_conflict,                 { desc = "Go to the next conflict" } },
                    { "n", "g?",            actions.help("file_panel"),            { desc = "Open the help panel" } },
                    { "n", "<leader>cO",    actions.conflict_choose_all("ours"),   { desc = "Choose the OURS version of a conflict for the whole file" } },
                    { "n", "<leader>cT",    actions.conflict_choose_all("theirs"), { desc = "Choose the THEIRS version of a conflict for the whole file" } },
                    { "n", "<leader>cB",    actions.conflict_choose_all("base"),   { desc = "Choose the BASE version of a conflict for the whole file" } },
                    { "n", "<leader>cA",    actions.conflict_choose_all("all"),    { desc = "Choose all the versions of a conflict for the whole file" } },
                    { "n", "dX",            actions.conflict_choose_all("none"),   { desc = "Delete the conflict region for the whole file" } },
                  },
                  file_history_panel = {
                    { "n", "g!",            actions.options,                    { desc = "Open the option panel" } },
                    { "n", "<C-A-d>",       actions.open_in_diffview,           { desc = "Open the entry under the cursor in a diffview" } },
                    { "n", "l",             actions.copy_hash,                  { desc = "Copy the commit hash of the entry under the cursor" } },
                    { "n", "L",             actions.open_commit_log,            { desc = "Show commit details" } },
                    { "n", "X",             actions.restore_entry,              { desc = "Restore file to the state from the selected entry" } },
                    { "n", "zo",            actions.open_fold,                  { desc = "Expand fold" } },
                    { "n", "zc",            actions.close_fold,                 { desc = "Collapse fold" } },
                    { "n", "y",             actions.close_fold,                 { desc = "Collapse fold" } },
                    { "n", "za",            actions.toggle_fold,                { desc = "Toggle fold" } },
                    { "n", "zR",            actions.open_all_folds,             { desc = "Expand all folds" } },
                    { "n", "zM",            actions.close_all_folds,            { desc = "Collapse all folds" } },
                    { "n", "h",             actions.next_entry,                 { desc = "Bring the cursor to the next file entry" } },
                    { "n", "<down>",        actions.next_entry,                 { desc = "Bring the cursor to the next file entry" } },
                    { "n", "a",             actions.prev_entry,                 { desc = "Bring the cursor to the previous file entry" } },
                    { "n", "<up>",          actions.prev_entry,                 { desc = "Bring the cursor to the previous file entry" } },
                    { "n", "<cr>",          actions.select_entry,               { desc = "Open the diff for the selected entry" } },
                    { "n", "o",             actions.select_entry,               { desc = "Open the diff for the selected entry" } },
                    { "n", "e",             actions.select_entry,               { desc = "Open the diff for the selected entry" } },
                    { "n", "<2-LeftMouse>", actions.select_entry,               { desc = "Open the diff for the selected entry" } },
                    { "n", "<c-b>",         actions.scroll_view(-0.25),         { desc = "Scroll the view up" } },
                    { "n", "<c-f>",         actions.scroll_view(0.25),          { desc = "Scroll the view down" } },
                    { "n", "<tab>",         actions.select_next_entry,          { desc = "Open the diff for the next file" } },
                    { "n", "<s-tab>",       actions.select_prev_entry,          { desc = "Open the diff for the previous file" } },
                    { "n", "[F",            actions.select_first_entry,         { desc = "Open the diff for the first file" } },
                    { "n", "]F",            actions.select_last_entry,          { desc = "Open the diff for the last file" } },
                    { "n", "gf",            actions.goto_file_edit,             { desc = "Open the file in the previous tabpage" } },
                    { "n", "<C-w><C-f>",    actions.goto_file_split,            { desc = "Open the file in a new split" } },
                    { "n", "<C-w>gf",       actions.goto_file_tab,              { desc = "Open the file in a new tabpage" } },
                    { "n", "<leader>e",     actions.focus_files,                { desc = "Bring focus to the file panel" } },
                    { "n", "<leader>b",     actions.toggle_files,               { desc = "Toggle the file panel" } },
                    { "n", "g<C-x>",        actions.cycle_layout,               { desc = "Cycle available layouts" } },
                    { "n", "g?",            actions.help("file_history_panel"), { desc = "Open the help panel" } },
                  },
                  option_panel = {
                    { "n", "<tab>", actions.select_entry,         { desc = "Change the current option" } },
                    { "n", "q",     actions.close,                { desc = "Close the panel" } },
                    { "n", "g?",    actions.help("option_panel"), { desc = "Open the help panel" } },
                  },
                  help_panel = {
                    { "n", "q",     actions.close, { desc = "Close help menu" } },
                    { "n", "<esc>", actions.close, { desc = "Close help menu" } },
                  },
                },
              })
            '';
        };
        dap = {
          data = with pkgs; [
            vimPlugins.nvim-dap
            vimPlugins.nvim-dap-view
          ];
          after = ["base"];
        };
        mini = {
          data = with pkgs; [
            vimPlugins.mini-comment
            vimPlugins.mini-surround
            vimPlugins.mini-pairs
          ];
          after = ["base"];
          config =
            #lua
            ''
              require('mini.comment').setup();
              require('mini.surround').setup();
              require('mini.pairs').setup();
            '';
        };
        treesitter = {
          data = with pkgs; [
            vimPlugins.nvim-treesitter
            vimPlugins.nvim-treesitter-context
          ];
          after = ["base"];
          config =
            #lua
            ''
              require('treesitter-context').setup({
                multiline_threshold = 1,
                max_lines = 15
              });
            '';
        };
        mason = {
          data = with pkgs; [
            vimPlugins.nvim-lspconfig
            vimPlugins.mason-tool-installer-nvim
            vimPlugins.mason-nvim
            vimPlugins.mason-lspconfig-nvim
          ];
          after = ["lsp"];
          config =
            #lua
            ''
              require("mason").setup()
              require("mason-tool-installer").setup({
                ensure_installed = ${lib.generators.toLua {} (lib.unique config.mason.ensureToolInstalled)},
              })
              require("mason-lspconfig").setup({
                ensure_installed = ${lib.generators.toLua {} (lib.unique config.mason.lspServers)},
                automatic_enable = {
                  exclude = {
                    "jdtls"
                  }
                },
              })
            '';
        };
        misc = {
          data = with pkgs; [
            vimPlugins.nvim-window-picker
            vimPlugins.sidekick-nvim
            vimPlugins.trouble-nvim
            vimPlugins.harpoon2
            vimPlugins.which-key-nvim
            vimPlugins.treesj
          ];

          config =
            #lua
            ''
              local whichKey = require('which-key')
              whichKey.setup({ preset = "modern" })
              vim.keymap.set("n", "<leader>?", function()
                whichKey.show({ global = true })
              end, { desc = "Which-key global mapping"})

              require("trouble").setup {
                keys = {
                  ["<c-x>"] = "jump_split"
                }
              }
              require 'window-picker'.setup({
                hint = 'floating-big-letter',
                selection_chars = 'SHTARENIWFDOLUCP',
                show_prompt = false,
                filter_func = nil,
                filter_rules = {
                  bo = {
                    filetype = { 'snacks_notif', 'snacks_picker_input', 'nvim-undotree' },
                    buftype = {},
                  },
                  wo = {},
                  file_path_contains = {},
                  file_name_contains = {},
                },
              })
              local quickSelect = function()
                local window = require("window-picker").pick_window()
                if not window or not vim.api.nvim_win_is_valid(window) then
                  return
                end

                vim.api.nvim_set_current_win(window)
              end
              vim.api.nvim_create_user_command("PickWin", quickSelect, {
                nargs = "?"
              })
              vim.keymap.set({ "n", "t" }, "<C-g>", "<cmd>PickWin<cr>")

              local treesj = require('treesj')
              treesj.setup({
                use_default_keymaps = false,
              })
              vim.keymap.set('n', '<leader>m', treesj.toggle)
            '';
        };
        haunt-nvim = {
          data = config.nvim-lib.mkPlugin "haunt" inputs.haunt-nvim;
        };
        tiny-code-action = {
          data = config.nvim-lib.mkPlugin "tiny-code-action" inputs.tiny-code-action;
          config =
            #lua
            ''
              require('tiny-code-action').setup({
                picker = {
                  "snacks",
                  opts = {
                    hotkeys = true,
                    hotkeys_mode = "text_diff_based",
                    auto_preview = true,
                    auto_accept = false,
                    position = "cursor",
                    winborder = "single",
                    keymaps = {
                      close = { "q", "<Esc>" },
                      select = "<CR>",
                      preview_close = { "q", "<Esc>" },
                    },
                    custom_keys = {
                      { key = 'm', pattern = 'Fill match arms' },
                      { key = 'r', pattern = 'Rename.*' },
                    },
                    group_icon = " └",
                  },
                },
              })
            '';
        };
      };
    };
  };

  perSystem = {
    pkgs,
    self',
    ...
  }: {
    packages.neovim = inputs.wrapper-modules.wrappers.neovim.wrap {
      inherit pkgs;
      imports = [
        self.modules.neovim.general
        self.modules.neovim.lsp
        self.modules.neovim.developmentLsp
      ];
    };
  };
}
