return {
  "neovim/nvim-lspconfig",
  ---@class PluginLspOpts
  opts = {
    ---@type lspconfig.options
    servers = {
      phpactor = { enabled = false },
      intelephense = {
        settings = {
          intelephense = {
            files = { maxSize = 2000000 },
            exclude = { "**/vendor/**", "**/storage/**" },
          },
        },
      },
    },
  },
}
