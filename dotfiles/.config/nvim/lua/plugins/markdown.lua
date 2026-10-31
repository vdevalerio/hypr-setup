-- render-markdown hides the rendered view of the line under the cursor
-- (anti-conceal), so moving through a table in normal mode kept breaking it into
-- raw pipes. Keep the rendered view in normal mode; insert mode is not in
-- render_modes (and `i` is left out of concealcursor), so it still shows the
-- real characters for editing.
--
-- Table rows too wide for the window are wrapped inside their cells, as virtual
-- lines. The plugin hard-codes hiding those on the cursor row (Updater:hide,
-- "virtual row"), with no option to turn it off, so that check is patched out
-- when the plugin loads; render_modes still hides them in insert mode.
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyLoad",
        callback = function(ev)
          if ev.data ~= "render-markdown.nvim" then
            return
          end
          local env = require("render-markdown.lib.env")
          local updater = require("render-markdown.core.ui").updater
          local hide = updater.hide
          updater.hide = function(self, extmark, range)
            if not extmark:get().replace then
              return hide(self, extmark, range)
            end
            -- no known cursor row: skips the "virtual row" rule
            local get = env.row.get
            env.row.get = function() end
            local ok, res = pcall(hide, self, extmark, range)
            env.row.get = get
            if not ok then
              error(res)
            end
            return res
          end
        end,
      })
    end,
    opts = {
      anti_conceal = { enabled = false },
      win_options = { concealcursor = { rendered = "nvc" } },
    },
  },
}
