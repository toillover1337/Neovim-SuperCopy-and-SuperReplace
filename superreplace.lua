-- ============================================================================
-- plugins/superreplace.lua
--
-- Lazy.nvim spec for SuperReplace. This is a local, in-config "plugin" --
-- there's no git repo to clone, so `dir` just points Lazy at your own
-- config root, which already contains lua/superreplace/init.lua. Lazy adds
-- that to the runtimepath and calls config() like it would for any real
-- plugin; nothing gets fetched or installed.
-- ============================================================================

return {
    {
        "superreplace",             -- arbitrary unique name, no repo
        dir = vim.fn.stdpath("config"), -- local, not fetched from anywhere
        name = "superreplace",
        lazy = false,               -- load on startup, not on a trigger
        config = function()
            require("superreplace").setup()
        end,
    },
}
