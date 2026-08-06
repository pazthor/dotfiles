local intelephense_licence = vim.fn.expand("~/intelephense/global/license.txt")

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        phpactor = { enabled = false },
        intelephense = {
          init_options = {
            licenceKey = intelephense_licence,
          },
          settings = {
            intelephense = {
              files = { maxSize = 2000000 },
            },
          },
        },
      },
    },
  },
  {
    -- Remove phpcs linter.
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        php = {},
      },
    },
  },
  {
    -- Add neotest-pest plugin for running PHP tests.
    -- A package is also available for PHPUnit if needed.
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "V13Axel/neotest-pest",
    },
    opts = { adapters = { "neotest-pest" } },
  },
  {
    -- Add the blade-nav.nvim plugin which provides Goto File capabilities
    -- for Blade files.
    "ricardoramirezr/blade-nav.nvim",
    dependencies = {
      "hrsh7th/nvim-cmp",
    },
    ft = { "blade", "php" },
  },
}
