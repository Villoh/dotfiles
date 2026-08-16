// Vercel Geist palette (dark). Nilesoft Shell only loads whichever theme is
// imported by shell.nss, so this is a reference clone — import this file
// instead of theme.nss to switch.
theme
{
	name = "modern"

	view = view.small

	background
	{
		color = #0a0a0a
		opacity = 100
		// effect = 2
	}

	item
	{
		opacity = 100

		prefix = 1

		text
		{
			normal = #ededed
			select = #ededed
			normal-disabled = #45a557
			select-disabled = #45a557
		}

		back
		{
			select = #1f1f1f
			select-disabled = #0a0a0a
		}
	}

	// font
	// {
	// 	size = 14
	// 	name = "Segoe UI Variable Text"
	// 	weight = 2
	// 	italic = 0
	// }

	border
	{
		enabled = true
		size = 1
		color = #8e4ec6
		opacity = 100
		radius = 2
	}

	shadow
	{
		enabled = true
		size = 5
		opacity = 5
		color = #0a0a0a
	}

	separator
	{
		size = 1
		color = #1f1f1f
	}

	symbol
	{
		normal = #8e4ec6
		select = #0072f5
		normal-disabled = #45a557
		select-disabled = #45a557
	}

	image
	{
		enabled = true
		color = [#ededed, #8e4ec6, #0a0a0a]
	}
}
