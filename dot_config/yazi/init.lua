local kanagawa_dragon = {
	overlay0 = "#625e5a",
	green = "#8a9a7b",
	base = "#1d1c19",
	violet = "#8992a7",
}

-- Plugins
require("full-border"):setup({
	type = ui.Border.ROUNDED,
})

require("zoxide"):setup({
	update_db = false,
})

require("session"):setup({
	sync_yanked = true,
})

require("searchjump"):setup({
	unmatch_fg = kanagawa_dragon.overlay0,
	match_str_fg = kanagawa_dragon.green,
	match_str_bg = kanagawa_dragon.base,
	first_match_str_fg = kanagawa_dragon.violet,
	first_match_str_bg = kanagawa_dragon.base,
	label_fg = kanagawa_dragon.violet,
	label_bg = kanagawa_dragon.base,
	only_current = false, -- only search the current window
	show_search_in_statusbar = true,
	auto_exit_when_unmatch = false,
	enable_capital_label = true,
})

require("git"):setup()

require("starship"):setup()
