return {
  {
    "folke/sidekick.nvim",
    opts = {
      -- Disable Copilot-powered Next Edit Suggestions.
      -- Cursor CLI will still work normally.
      nes = {
        enabled = false,
      },
      -- 1. Completely disable Copilot Next Edit Suggestions
      copilot = {
        status = { enabled = false },
      },


      cli = {
        -- Reload buffers when Cursor changes files on disk.
        watch = true,

        win = {
          layout = "right",
          split = {
            width = 80,
          },
          -- Custom terminal window overrides
          bo = {
            filetype = "sidekick-cursor",
          },
          -- 3. Dedicated Cursor prompt Engineering
          prompts = {
            cursor_plan = "Create a detailed execution plan before changing anything: {this}",
            refactor = "Refactor this code fragment for readability and performance:\n{selection}",
            fix_error = "I am getting an error near this block. Analyze and fix it:\n{selection}",
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
        desc = "Toggle Cursor Agent",
      },
      -- Visual Mode: Send raw code fragment straight to the Cursor prompt
      {
        "<leader>as",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = "x",
        desc = "Send Fragment to Cursor",
      },

      -- Ask Cursor to output a structural Plan based on your current cursor/selection
      {
        "<leader>ap",
        function()
          require("sidekick.cli").send({
            msg =
            "Please generate a comprehensive, step-by-step implementation plan for: {this}"
          })
        end,
        mode = { "n", "x" },
        desc = "Cursor: Generate Plan",
      },
      -- Open Sidekick's built-in prompt selector overlay
      {
        "<leader>am",
        function()
          require("sidekick.cli").prompt()
        end,
        desc = "Cursor Prompt Menu",
      },
      -- Fast exit/hide the Cursor window panel
      {
        "<leader>ah",
        function()
          require("sidekick.cli").hide({ name = "cursor" })
        end,
        desc = "Hide Cursor Window",
      },
    },
  },
}
