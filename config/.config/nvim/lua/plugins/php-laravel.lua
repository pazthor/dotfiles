local intelephense_licence = vim.fn.expand("~/intelephense/global/license.txt")

local function laravel_root(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr or 0)

  if filename == "" then
    return nil
  end

  local artisan = vim.fs.find("artisan", {
    path = vim.fs.dirname(filename),
    upward = true,
    type = "file",
  })[1]

  if artisan then
    return vim.fs.dirname(artisan)
  end

  return nil
end

local function is_laravel_buffer(bufnr)
  return laravel_root(bufnr or 0) ~= nil
end

return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.lsp.config("laravel_lsp", {
        cmd = { "laravel-lsp" },
        filetypes = { "php", "blade" },
        root_dir = function(bufnr, on_dir)
          local root = laravel_root(bufnr)
          if root then
            on_dir(root)
          end
        end,
        init_options = {
          phpEnvironment = "ddev",
          definitionProvider = true,
          pestGenerateDocBlocks = true,
        },
      })

      vim.lsp.enable("laravel_lsp")
    end,
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
    "adalessa/laravel.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-neotest/nvim-nio",
    },
    ft = { "php", "blade" },
    event = { "BufEnter composer.json" },
    opts = {
      features = {
        pickers = {
          provider = "snacks",
        },
      },
      eloquent_generate_doc_blocks = true,
      resources = {
        Actions = "app/Actions",
        DTOs = "app/DTOs",
        Enums = "app/Enums",
        Filament = "app/Filament",
        Jobs = "app/Jobs",
        Services = "app/Services",
      },
      environments = {
        default = "ddev",
        ask_on_boot = false,
        definitions = {
          {
            name = "ddev",
            map = {
              php = { "ddev", "php" },
              composer = { "ddev", "composer" },
              artisan = { "ddev", "artisan" },
              npm = { "ddev", "npm" },
              yarn = { "ddev", "yarn" },
            },
          },
        },
      },
      user_commands = {
        artisan = {
          ["test"] = {
            cmd = { "test" },
            desc = "Run Laravel tests",
          },
          ["test-parallel"] = {
            cmd = { "test", "--parallel" },
            desc = "Run Laravel tests in parallel",
          },
          ["optimize-clear"] = {
            cmd = { "optimize:clear" },
            desc = "Clear Laravel caches",
          },
          ["migrate-status"] = {
            cmd = { "migrate:status" },
            desc = "Show migration status",
          },
          ["queue-restart"] = {
            cmd = { "queue:restart" },
            desc = "Restart queue workers",
          },
        },
        composer = {
          autoload = {
            cmd = { "dump-autoload" },
            desc = "Regenerate Composer autoload files",
          },
        },
      },
    },
    keys = {
      {
        "<leader>ll",
        function()
          Laravel.pickers.laravel()
        end,
        desc = "Laravel: Picker",
      },
      {
        "<leader>la",
        function()
          Laravel.pickers.artisan()
        end,
        desc = "Laravel: Artisan",
      },
      {
        "<leader>lr",
        function()
          Laravel.pickers.routes()
        end,
        desc = "Laravel: Routes",
      },
      {
        "<leader>lm",
        function()
          Laravel.pickers.make()
        end,
        desc = "Laravel: Make",
      },
      {
        "<leader>lc",
        function()
          Laravel.pickers.commands()
        end,
        desc = "Laravel: Custom Commands",
      },
      {
        "<leader>lo",
        function()
          Laravel.pickers.resources()
        end,
        desc = "Laravel: Resources",
      },
      {
        "<leader>lt",
        function()
          Laravel.commands.run("actions")
        end,
        desc = "Laravel: Code Actions",
      },
      {
        "<leader>lu",
        function()
          Laravel.commands.run("hub")
        end,
        desc = "Laravel: Artisan Hub",
      },
      {
        "<leader>lp",
        function()
          Laravel.commands.run("command_center")
        end,
        desc = "Laravel: Command Center",
      },
      {
        "<leader>le",
        function()
          Laravel.commands.run("env:configure")
        end,
        desc = "Laravel: Configure Environment",
      },
      {
        "<leader>lh",
        function()
          Laravel.run("artisan docs")
        end,
        desc = "Laravel: Documentation",
      },
      {
        "<C-g>",
        function()
          Laravel.commands.run("view:finder")
        end,
        desc = "Laravel: View Finder",
      },
      {
        "gf",
        function()
          if is_laravel_buffer(0) and Laravel.app("gf").cursorOnResource() then
            return "<cmd>lua Laravel.commands.run('gf')<cr>"
          end

          return "gf"
        end,
        expr = true,
        noremap = true,
        desc = "Laravel: Go to Resource",
      },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>sw",
        function()
          Snacks.picker.grep_word()
        end,
        mode = { "n", "x" },
        desc = "Search Word or Selection",
      },
      {
        "<leader>sg",
        function()
          Snacks.picker.grep()
        end,
        desc = "Search Project Text",
      },
      {
        "<leader>ss",
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = "Search Document Symbols",
      },
      {
        "<leader>sS",
        function()
          Snacks.picker.lsp_workspace_symbols()
        end,
        desc = "Search Workspace Symbols",
      },
    },
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
