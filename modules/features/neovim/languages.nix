{...}: {
  flake.modules.neovim.lsp = {pkgs, ...}: {
    mason.ensureToolInstalled = [
      "tree-sitter-cli"
      "alejandra"
    ];

    mason.lspServers = [
      "lua_ls"
      "qmlls"
      "jsonls"
      "nil_ls"
    ];

    ftpluginFiles = [
      ./after/ftplugin/lua.lua
      ./after/ftplugin/nix.lua
    ];

    specs.lua = {
      data = with pkgs; [
        vimPlugins.nvim-lspconfig
        vimPlugins.lazydev-nvim
      ];
    };

    specs.nix = {
      data = with pkgs; [
        vimPlugins.nvim-lspconfig
      ];
      config =
        #lua
        ''
          vim.lsp.config('nil_ls', {
            settings = {
              ['nil'] = {
                formatting = {
                  command = { 'alejandra' },
                },
              },
            },
          })
        '';
    };
  };

  flake.modules.neovim.developmentLsp = {pkgs, ...}: {
    mason.ensureToolInstalled = [
      "java-debug-adapter"
      "java-test"
    ];

    mason.lspServers = [
      "ts_ls"
      "jdtls"
      "cssls"
    ];

    ftpluginFiles = [./after/ftplugin/java.lua];

    specs.java = {
      data = pkgs.vimPlugins.nvim-jdtls;
    };
  };
}
