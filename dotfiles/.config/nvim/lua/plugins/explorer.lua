-- Dotfiles toggle for the file explorer (Snacks). Inside the explorer `H` already
-- flips hidden files; <leader>uH does the same from any window.
return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>uH",
      function()
        local explorer = Snacks.picker.get({ source = "explorer" })[1]
        if explorer then
          explorer:action("toggle_hidden")
        else
          Snacks.explorer({ hidden = true })
        end
      end,
      desc = "Toggle dotfiles in explorer",
    },
  },
}
