-- Entry point: load core settings, then plugins.
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
require("projects").setup()
require("runner").setup()
