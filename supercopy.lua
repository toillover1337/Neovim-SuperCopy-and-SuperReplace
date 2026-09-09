-- ============================================================================
-- config/supercopy.lua
--
-- Register / clipboard discipline:
--   - normal y/d/p stay on Neovim's unnamed register, never touching the
--     OS clipboard implicitly
--   - explicit system-clipboard copy/paste via TWO alternate bindings:
--       Ctrl-Shift-C / Ctrl-Shift-V   (terminal-friendly on protocols that
--                                      forward the distinct keycode)
--       Super-Y       / Super-P      (Cmd/Win-Y, Cmd/Win-P -- GUI-friendly,
--                                      also works over Kitty w/ passthrough)
--   - x deletes into the black hole register (no register at all, ever)
--
-- Both clipboard bindings do the same thing -- keep both, since which one
-- is reachable/comfortable varies by context (GUI vs terminal, keyboard
-- layout, muscle memory).
--
-- Plain config, not a plugin -- just require('config.supercopy') once from
-- init.lua (order relative to Lazy's setup() doesn't matter, this has no
-- dependency on it).
-- ============================================================================

-- Make sure 'clipboard' is NOT unnamed/unnamedplus, so plain y/d/p use the
-- unnamed register only and never silently touch the OS clipboard. This is
-- Neovim's default if untouched -- set explicitly here as a guard against
-- some other config (system-wide or plugin) flipping it on.
vim.opt.clipboard = ""

-- x: delete without yanking into any register.
-- "_ is the black hole register -- anything sent there is discarded.
vim.keymap.set({ "n", "v" }, "x", '"_x', { desc = "Delete without yanking" })
-- Uncomment if you also want X (delete before cursor) to skip registers:
-- vim.keymap.set({ 'n', 'v' }, 'X', '"_X', { desc = 'Delete before cursor without yanking' })

-- ---- System clipboard: Ctrl-Shift-C / Ctrl-Shift-V -------------------------
-- CAVEAT: many terminals don't distinguish Ctrl-C from Ctrl-Shift-C at the
-- byte level. Reliable on Kitty/WezTerm/Alacritty (modern key handling) and
-- GUI front-ends (Neovide, Fvim). Often silently no-ops on xterm, GNOME
-- Terminal, or plain tmux.
vim.keymap.set("v", "<C-S-c>", '"+y', { desc = "Copy selection to system clipboard" })
vim.keymap.set({ "n", "v" }, "<C-S-v>", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("i", "<C-S-v>", "<C-r>+", { desc = "Paste from system clipboard (insert mode)" })

-- ---- System clipboard: Super-Y / Super-P (alternate bind) ------------------
-- CAVEAT: Super is frequently grabbed by the OS/window manager before the
-- terminal ever sees it, OR (as confirmed via `keytrans`) some setups report
-- the Super modifier AS Alt/Meta instead of a distinct Super bit -- if
-- `:lua print(vim.fn.keytrans(vim.fn.getcharstr()))` shows `M-y` when you
-- press what you think is Super-Y, that's exactly this. Both bindings
-- below are kept so whichever your terminal actually sends still works.
vim.keymap.set("v", "<D-y>", '"+y', { desc = "Copy selection to system clipboard (Super)" })
vim.keymap.set({ "n", "v" }, "<D-p>", '"+p', { desc = "Paste from system clipboard (Super)" })
vim.keymap.set("i", "<D-p>", "<C-r>+", { desc = "Paste from system clipboard (Super, insert mode)" })

vim.keymap.set("v", "<M-y>", '"+y', { desc = "Copy selection to system clipboard (Alt, terminal fallback for Super)" })
vim.keymap.set(
    { "n", "v" },
    "<M-p>",
    '"+p',
    { desc = "Paste from system clipboard (Alt, terminal fallback for Super)" }
)
vim.keymap.set(
    "i",
    "<M-p>",
    "<C-r>+",
    { desc = "Paste from system clipboard (Alt, insert mode, terminal fallback for Super)" }
)
