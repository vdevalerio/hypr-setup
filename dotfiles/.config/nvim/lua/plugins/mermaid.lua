-- Mermaid diagrams (and images) rendered inline in Markdown via Snacks.image (kitty graphics protocol,
-- through tmux with allow-passthrough). Diagrams are converted by mermaid-cli (`mmdc`, installed in
-- ~/.local/bin by `install.sh nvim`); the PNG is cached, so only changed diagrams are re-rendered.
-- <leader>uI shows the diagram or image under the cursor in a float.
return {
  "folke/snacks.nvim",
  opts = {
    image = {
      enabled = true,
      doc = { enabled = true, inline = true, float = true, max_width = 80, max_height = 20 },
      convert = { mermaid = function() return { "-i", "{src}", "-o", "{file}", "-b", "transparent", "-t", "dark", "-s", "{scale}" } end },
    },
  },
  keys = {
    { "<leader>uI", function() Snacks.image.hover() end, desc = "Image / diagram under cursor" },
  },
}
