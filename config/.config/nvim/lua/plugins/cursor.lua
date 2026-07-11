return {
  {
    "folke/sidekick.nvim",
    opts = {
      -- Disable Copilot-powered Next Edit Suggestions.
      -- Cursor CLI will still work normally.
      nes = {
        enabled = false,
      },

      cli = {
        -- Reload buffers when Cursor changes files on disk.
        watch = true,

        win = {
          layout = "right",
          split = {
            width = 80,
          },
        },
      },
    },

    keys = {
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({
            name = "cursor",
            focus = true,
          })
        end,
        desc = "Cursor Agent",
      },
    },
  },
}
