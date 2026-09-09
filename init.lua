-- ============================================================================
-- superreplace/init.lua
--
-- A scoped search-and-replace workflow, kept fully separate from Neovim's
-- normal `/` search so the two can never be confused:
--
--   /pattern<CR>            -> plain, vanilla Neovim search. NEVER arms
--                              replace mode. n/N navigate as usual.
--
--   <D-/>  or  <C-/>        -> starts a SCOPED search (feeds `/` for you,
--   (Super-/)   (alt bind,     full normal search UX -- incsearch, history,
--    also <C-_> for terminals   etc.) Once you confirm it with <CR>, this
--    that transmit it that way) arms `r`/`R` in the current buffer:
--
--        r   -> prompts for replacement text, then replaces ONLY the match
--               under the cursor. Stays in normal mode; search state is
--               untouched, so n/N still work afterward.
--        R   -> prompts for replacement text, then replaces ALL matches
--               of the last search pattern in the whole buffer
--
--   <Esc>                   -> disarms r/R, restoring their normal Vim
--                              meanings (replace-char / Replace-mode)
--                              until the next scoped search.
--
-- Because r/R are only armed after the <D-/>/<C-/> entry point (never
-- after plain `/`), you can never accidentally trigger a replace by doing
-- an ordinary search.
--
-- Loaded as a local Lazy.nvim plugin -- see plugins/superreplace.lua.
-- Usage from that spec: require("superreplace").setup()
-- ============================================================================

local M = {}

function M.setup()
    local sr_active = false       -- is r/R currently armed?
    local pending_sr_search = false -- was the search just started via our
    -- scoped entry point (vs plain `/`)?

    local function enable_search_replace_mode()
        if sr_active then
            return
        end
        sr_active = true

        vim.keymap.set("n", "r", function()
            local pattern = vim.fn.getreg("/")
            if pattern == "" then
                vim.notify("[SuperReplace] no active search pattern", vim.log.levels.WARN)
                return
            end

            -- Find the match at the cursor. Assumes cursor sits exactly at the
            -- match's start column, which is how Vim leaves it after `/` or n/N.
            -- NOTE: this only handles matches within a single line -- a pattern
            -- that matches across a newline won't be found by matchstrpos.
            local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- row 1-indexed, col 0-indexed
            local line = vim.api.nvim_get_current_line()
            local match = vim.fn.matchstrpos(line, pattern, col)
            local mstr, mstart, mend = match[1], match[2], match[3]

            if mstart == -1 or mstart ~= col then
                vim.notify("[SuperReplace] cursor is not on a match -- try n/N to land on one", vim.log.levels.WARN)
                return
            end

            vim.ui.input({ prompt = 'Replace "' .. mstr .. '" with: ' }, function(input)
                if input == nil then
                    return
                end -- cancelled
                vim.api.nvim_buf_set_text(0, row - 1, mstart, row - 1, mend, { input })
                -- Stay in normal mode, cursor at the start of what we just typed.
                -- Search register/history untouched, so n/N still work afterward.
                vim.api.nvim_win_set_cursor(0, { row, mstart })
            end)
        end, { buffer = true, desc = "[SuperReplace] replace current match" })

        vim.keymap.set("n", "R", function()
            local pattern = vim.fn.getreg("/")
            if pattern == "" then
                vim.notify("[SuperReplace] no active search pattern", vim.log.levels.WARN)
                return
            end
            vim.ui.input({ prompt = 'Replace all "' .. pattern .. '" with: ' }, function(input)
                if input ~= nil then
                    -- escape backslashes/forward-slashes so replacement text is
                    -- treated literally by :substitute
                    local safe = input:gsub("\\", "\\\\"):gsub("/", "\\/")
                    vim.cmd("%s//" .. safe .. "/g")
                end
            end)
        end, { buffer = true, desc = "[SuperReplace] replace all matches" })
    end

    local function disable_search_replace_mode()
        if not sr_active then
            return
        end
        sr_active = false
        pcall(vim.keymap.del, "n", "r", { buffer = true })
        pcall(vim.keymap.del, "n", "R", { buffer = true })
    end

    -- Entry point: Super-/ or Ctrl-/ (with <C-_> fallback for terminals that
    -- transmit Ctrl-/ that way) starts a search that WILL arm r/R once confirmed.
    local function start_scoped_search()
        pending_sr_search = true
        vim.api.nvim_feedkeys("/", "n", false)
    end

    -- Entry point: Super-/ or Ctrl-/ starts a search that WILL arm r/R once
    -- confirmed. <M-/> is included because on this setup Super consistently
    -- reports as Alt/Meta to Neovim (confirmed via keytrans) rather than a
    -- distinct Super bit -- same as the Super-Y situation in SuperCopy.
    -- <C-_> stays as a fallback for terminals that transmit Ctrl-/ that way.
    vim.keymap.set("n", "<D-/>", start_scoped_search, { desc = "[SuperReplace] start scoped search" })
    vim.keymap.set(
        "n",
        "<M-/>",
        start_scoped_search,
        { desc = "[SuperReplace] start scoped search (Alt, terminal fallback for Super)" }
    )
    vim.keymap.set("n", "<C-/>", start_scoped_search, { desc = "[SuperReplace] start scoped search (alt bind)" })
    vim.keymap.set(
        "n",
        "<C-_>",
        start_scoped_search,
        { desc = "[SuperReplace] start scoped search (terminal fallback for Ctrl-/)" }
    )

    -- Only arms r/R if the search that just finished was started via our
    -- scoped entry point above. Plain `/` never sets pending_sr_search, so it
    -- leaves this whole system untouched.
    --
    -- NOTE: pattern here matches directly against the command-line type
    -- ('/' or '?') rather than calling vim.fn.getcmdtype() inside the
    -- callback -- by the time CmdlineLeave fires, getcmdtype() has often
    -- already reset to empty, which silently breaks this check.
    vim.api.nvim_create_autocmd("CmdlineLeave", {
        pattern = { "/", "?" },
        callback = function()
            if vim.v.event.abort then
                pending_sr_search = false -- search was cancelled, don't arm
                return
            end
            if pending_sr_search then
                enable_search_replace_mode()
            end
            pending_sr_search = false
        end,
    })

    -- Disarm on <Esc>, restoring normal r/R behavior.
    -- NOTE: if you have other <Esc> mappings elsewhere in your config (closing
    -- floating windows, clearing hlsearch, etc.), merge the
    -- disable_search_replace_mode() call into that mapping instead of defining
    -- <Esc> twice -- whichever definition loads last wins and would silently
    -- override the other.
    vim.keymap.set("n", "<Esc>", function()
        disable_search_replace_mode()
        return vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
    end, { expr = true })
end

-- ============================================================================
-- Notes:
-- * `R` operates over the WHOLE buffer (%). For a visual-selection-only
--   replace, swap '%s//' for "'<,'>s//" and trigger from visual mode.
-- * `r` only handles matches within a single line -- a pattern that matches
--   across a newline won't be found by matchstrpos.
-- * `r`/`R` will warn instead of erroring if no search has happened yet in
--   the session (vim.fn.getreg('/') empty), or if the cursor isn't sitting
--   exactly on a match for `r`.
-- ============================================================================

return M
