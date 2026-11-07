-- Colours come from the flavor DMS/matugen generates
-- (~/.config/yazi/flavors/DMS.yazi); nothing here hardcodes a palette.

-- ── UI ────────────────────────────────────────────────────────────────────

-- Rounded border around the three panes.
require("full-border"):setup({ set = "rounded" })

-- Starship prompt in the header, reusing the shell prompt config.
require("starship"):setup()

-- Git status signs next to the file names (fetchers are in yazi.toml).
require("git"):setup({ order = 1500 })

-- Linemode used by `linemode = "size_and_mtime"` in yazi.toml, shaped like
-- Strata's List view: size (item count for folders) then modification date.
function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	local date = ""
	if time ~= 0 then
		date = os.date("%Y", time) == os.date("%Y") and os.date("%d %b %H:%M", time) or os.date("%d %b  %Y", time)
	end
	return string.format("%5s %s", self:size(), date)
end

-- Symlink target and owner in the status bar.
Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	end
	return ""
end, 3300, Status.LEFT)

Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ""
	end
	return ui.Line({
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):style(th.mgr.cwd),
		":",
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):style(th.mgr.cwd),
		" ",
	})
end, 500, Status.RIGHT)

-- ── Behaviour ─────────────────────────────────────────────────────────────

-- Built-in plugins: `z` fzf and `Z` zoxide live in the preset keymap.
require("zoxide"):setup({ update_db = false })

-- Share the yank state between instances.
require("session"):setup({ sync_yanked = true })

-- Places and bookmarks menu (`b`, fuzzy `B`). The first group mirrors Strata's
-- sidebar; hops are fixed here and tabs/ephemeral hops are added on the fly.
require("bunny"):setup({
	hops = {
		{ key = "h", path = "~", desc = "Home" },
		{ key = "k", path = "~/Desktop", desc = "Desktop" },
		{ key = "o", path = "~/Documents", desc = "Documents" },
		{ key = "d", path = "~/Downloads", desc = "Downloads" },
		{ key = "m", path = "~/Music", desc = "Music" },
		{ key = "p", path = "~/Pictures", desc = "Pictures" },
		{ key = "v", path = "~/Videos", desc = "Videos" },
		{ key = "D", path = "~/development", desc = "Development" },
		{ key = "c", path = "~/.config", desc = "Config" },
		{ key = "n", path = "~/development/personal/projects/nixos-config", desc = "nixos-config" },
		{ key = "s", path = "~/.local/share/chezmoi", desc = "Chezmoi source" },
		{ key = "N", path = "/nix/store", desc = "Nix store" },
		{ key = "t", path = "/tmp", desc = "Temp" },
		{ key = "/", path = "/", desc = "Root" },
	},
	desc_strategy = "path",
	ephemeral = true,
	tabs = true,
	notify = false,
	fuzzy_cmd = "fzf",
})
