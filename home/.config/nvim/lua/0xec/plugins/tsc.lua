return {
  {
    "dmmulroy/tsc.nvim",
    cmd = { "TSC", "TSCOpen", "TSCClose", "TSCStop" },
    opts = {
      bin_name = "tsgo",
      flags = {
        noEmit = true,
      },
    },
  },
}
