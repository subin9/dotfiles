return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup({
      ensure_installed = {
        "python", "rust", "lua", "bash",
        "yaml", "toml", "json", "markdown",
        "dockerfile",
      },
      auto_install = true,
    })
  end,
}
