return {
  "lewis6991/gitsigns.nvim",
  config = function()
    require("gitsigns").setup({
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        vim.keymap.set("n", "]h", gs.next_hunk, { buffer = bufnr, desc = "Next hunk" })
        vim.keymap.set("n", "[h", gs.prev_hunk, { buffer = bufnr, desc = "Prev hunk" })
        vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
        vim.keymap.set("n", "<leader>hb", gs.blame_line, { buffer = bufnr, desc = "Blame line" })
      end,
    })
  end,
}
