return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("telescope").setup({
      defaults = {
        layout_strategy = "horizontal",
        sorting_strategy = "ascending",
      },
    })
  end,
}
