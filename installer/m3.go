package main

// A small Material 3 layer over MyGo's ui package: a color scheme generated
// from the desktop's accent, and the few components the installer uses.

import (
	"embed"
	gocolor "image/color"
	"log"
	"strings"

	"github.com/Nadim147c/material/v3"
	"github.com/egoist/mygo/ui"
)

// Material Symbols (Rounded), Apache License 2.0, from
// github.com/google/material-design-icons.
//
//go:embed icons/*.svg
var iconFS embed.FS

var icons = map[string]*ui.SVG{}

func init() {
	entries, _ := iconFS.ReadDir("icons")
	for _, e := range entries {
		b, _ := iconFS.ReadFile("icons/" + e.Name())
		icons[strings.TrimSuffix(e.Name(), ".svg")] = ui.MustParseSVG(b)
	}
}

// seedColor is used where the desktop has no accent color (M3's baseline).
var seedColor = ui.Hex("#6750a4")

// scheme holds the M3 color roles the installer draws with.
type scheme struct {
	Primary, OnPrimary                            ui.Color
	PrimaryContainer, OnPrimaryContainer          ui.Color
	SecondaryContainer, OnSecondaryContainer      ui.Color
	TertiaryContainer, OnTertiaryContainer        ui.Color
	Error, ErrorContainer, OnErrorContainer       ui.Color
	Surface, OnSurface, OnSurfaceVariant          ui.Color
	SurfaceContainerLow, SurfaceContainer         ui.Color
	SurfaceContainerHigh, SurfaceContainerHighest ui.Color
	Outline, OutlineVariant                       ui.Color
	InverseSurface, InverseOnSurface              ui.Color
	Success                                       ui.Color
}

// newScheme generates a tonal-spot scheme, the one Android derives from a
// wallpaper, from seed. The seed is always opaque and valid, so only a bug
// in the color library makes it fail.

func newScheme(seed ui.Color, dark bool) *scheme {
	c, err := material.Generate(
		material.FromColor(gocolor.NRGBA{R: seed.R, G: seed.G, B: seed.B, A: 255}),
		material.WithDark(dark),
		material.WithVariant(material.VariantTonalSpot),
		// The 2021 spec: the 2025 one mutes the containers' text (tone ~78, not 90).
		material.WithVersion(material.Version2021),
		material.WithCustomColorBlend("success", gocolor.NRGBA{R: 0x38, G: 0x8e, B: 0x3c, A: 255}, 0.3),
	)
	if err != nil {
		log.Printf("material scheme: %v", err)
		if seed != seedColor {
			return newScheme(seedColor, dark)
		}
		panic(err)
	}
	col := func(a interface{ RGBA() (r, g, b, a uint32) }) ui.Color {
		r, g, b, _ := a.RGBA()
		return ui.RGB(uint8(r>>8), uint8(g>>8), uint8(b>>8))
	}
	return &scheme{
		Primary: col(c.Primary), OnPrimary: col(c.OnPrimary),
		PrimaryContainer: col(c.PrimaryContainer), OnPrimaryContainer: col(c.OnPrimaryContainer),
		SecondaryContainer: col(c.SecondaryContainer), OnSecondaryContainer: col(c.OnSecondaryContainer),
		TertiaryContainer: col(c.TertiaryContainer), OnTertiaryContainer: col(c.OnTertiaryContainer),
		Error: col(c.Error), ErrorContainer: col(c.ErrorContainer), OnErrorContainer: col(c.OnErrorContainer),
		Surface: col(c.Surface), OnSurface: col(c.OnSurface), OnSurfaceVariant: col(c.OnSurfaceVariant),
		SurfaceContainerLow: col(c.SurfaceContainerLow), SurfaceContainer: col(c.SurfaceContainer),
		SurfaceContainerHigh: col(c.SurfaceContainerHigh), SurfaceContainerHighest: col(c.SurfaceContainerHighest),
		Outline: col(c.Outline), OutlineVariant: col(c.OutlineVariant),
		InverseSurface: col(c.InverseSurface), InverseOnSurface: col(c.InverseOnSurface),
		Success: col(c.CustomColors["success"].Color),
	}
}

// uiTheme maps the scheme onto MyGo's theme, so its own widgets (check
// boxes, radios, inputs, progress) draw in M3 colors.
func (s *scheme) uiTheme(base *ui.Theme) *ui.Theme {
	u := *base
	u.Background = s.Surface
	u.Surface = s.SurfaceContainerHigh
	u.SurfaceHover = layer(s.SurfaceContainerHigh, s.OnSurface, stateHover)
	u.SurfacePressed = layer(s.SurfaceContainerHigh, s.OnSurface, statePress)
	u.Border = s.Outline
	u.Text = s.OnSurface
	u.TextMuted = s.OnSurfaceVariant
	u.Accent = s.Primary
	u.AccentHover = layer(s.Primary, s.OnPrimary, stateHover)
	u.AccentPressed = layer(s.Primary, s.OnPrimary, statePress)
	u.AccentText = s.OnPrimary
	u.Danger = s.Error
	u.Success = s.Success
	u.Selection = s.Primary.Alpha(0.32)
	u.Focus = s.Primary
	u.Inverse = s.InverseSurface
	u.InverseText = s.InverseOnSurface
	u.Scrollbar = s.OnSurfaceVariant.Alpha(0.5)
	u.Radius = 8
	return &u
}

// M3 state layer opacities.
const (
	stateHover = 0.08
	statePress = 0.10
)

func layer(bg, fg ui.Color, opacity float32) ui.Color { return bg.Mix(fg, opacity) }

// stateFill is bg with the state layer of the pointer's state over it.
func stateFill(e ui.Element, bg, fg ui.Color) ui.Color {
	switch {
	case e.Pressed():
		return layer(bg, fg, statePress)
	case e.Hovered():
		return layer(bg, fg, stateHover)
	}
	return bg
}

const full = 9999 // a pill's corner radius

// themed caches the scheme for the desktop's accent and appearance, and sets
// it as the frame's theme.
func (a *app) themed(c *ui.Context) *scheme {
	seed, dark := c.Preferences().Accent, c.Theme().Dark
	if seed.A == 0 {
		seed = seedColor
	}
	seed.A = 255
	if a.scheme == nil || a.schemeSeed != seed || a.schemeDark != dark {
		a.scheme, a.schemeSeed, a.schemeDark = newScheme(seed, dark), seed, dark
	}
	c.SetTheme(a.scheme.uiTheme(c.Theme()))
	return a.scheme
}

type buttonKind int

const (
	filled buttonKind = iota
	tonal
	outlined
)

// button is an M3 common button: a 40 DIP pill.
func (a *app) button(c *ui.Context, kind buttonKind, label string, disabled bool) bool {
	s := a.scheme
	bg, fg := s.Primary, s.OnPrimary
	switch kind {
	case tonal:
		bg, fg = s.SecondaryContainer, s.OnSecondaryContainer
	case outlined:
		bg, fg = s.Surface.Alpha(0), s.Primary
	}
	b := ui.ButtonBase(c).Label(label).Disabled(disabled).DimDisabled(false).
		Height(40).PaddingX(24).Radius(full).Justify(ui.Center)
	if kind == outlined {
		b.Border(1, s.OutlineVariant)
	}
	switch {
	case disabled:
		if kind != outlined {
			b.Background(s.OnSurface.Alpha(0.12))
		}
		fg = s.OnSurface.Alpha(0.38)
	case kind == outlined:
		b.Background(stateFill(b, bg, fg))
	default:
		b.Background(stateFill(b, bg, fg))
	}
	b.Children(func() {
		ui.Text(c, label).FontSize(14).FontWeight(500).TextColor(fg).SingleLine()
	})
	return b.Clicked()
}

// railItem is a destination of the navigation rail: an icon in a pill that
// fills when chosen, over its label.
func (a *app) railItem(c *ui.Context, i int, icon, label string) {
	s := a.scheme
	on := a.tab == i
	b := ui.ButtonBase(c.Key(label)).Label(label).AccessSelected(on).Role(ui.RoleTab).Width(80).Justify(ui.Center)
	b.Children(func() {
		ui.Column(c).Gap(4).PaddingY(4).AlignItems(ui.Center).Children(func() {
			bg, fg := s.SecondaryContainer.Alpha(0), s.OnSurfaceVariant
			name := icon
			if on {
				bg, fg, name = s.SecondaryContainer, s.OnSecondaryContainer, icon+"_fill1"
			}
			pill := ui.Row(c).Width(56).Height(32).Radius(full).Center()
			pill.Background(stateFill(b, bg, s.OnSurface)).Children(func() {
				ui.Icon(c, icons[name]).FontSize(24).TextColor(fg)
			})
			t := ui.Text(c, label).FontSize(12).FontWeight(500).TextColor(s.OnSurfaceVariant).SingleLine()
			if on {
				t.TextColor(s.OnSurface).FontWeight(700)
			}
		})
	})
	if b.Clicked() {
		a.tab = i
	}
}

// card is a filled M3 card.
func (a *app) card(c *ui.Context, fn func()) ui.Element {
	return ui.Column(c).Background(a.scheme.SurfaceContainerLow).Radius(16).Padding(16).Gap(12).Children(fn)
}

// choiceCard is a selectable card: a radio button drawn as a card.
func (a *app) choiceCard(c *ui.Context, on bool, icon, title, body string) bool {
	s := a.scheme
	bg, fg, border := s.SurfaceContainerLow, s.OnSurface, s.OutlineVariant
	if on {
		bg, fg, border = s.SecondaryContainer, s.OnSecondaryContainer, s.SecondaryContainer
	}
	b := ui.ButtonBase(c.Key(title)).Label(title).Checked(on).Role(ui.RoleRadio).
		Radius(16).Padding(16).Gap(16).Border(1, border).AlignItems(ui.Start).Grow(1).Basis(0)
	b.Background(stateFill(b, bg, fg)).Children(func() {
		if icon != "" {
			ui.Icon(c, icons[icon]).FontSize(24).TextColor(fg)
		}
		ui.Column(c).Gap(4).Grow(1).Shrink(1).Children(func() {
			ui.Text(c, title).FontSize(16).FontWeight(500).TextColor(fg)
			ui.Text(c, body).FontSize(14).TextColor(fg.Alpha(0.8))
		})
		if on {
			ui.Icon(c, icons["check_circle"]).FontSize(20).TextColor(s.Primary)
		}
	})
	return b.Clicked()
}

// filterChip is an M3 filter chip toggling *on.
func (a *app) filterChip(c *ui.Context, on *bool, label string) {
	s := a.scheme
	bg, fg := s.Surface.Alpha(0), s.OnSurfaceVariant
	if *on {
		bg, fg = s.SecondaryContainer, s.OnSecondaryContainer
	}
	b := ui.ButtonBase(c.Key(label)).Label(label).Checked(*on).Role(ui.RoleCheckBox).
		Height(32).PaddingX(12).Gap(8).Radius(8)
	if !*on {
		b.Border(1, s.OutlineVariant)
	}
	b.Background(stateFill(b, bg, fg)).Children(func() {
		if *on {
			ui.Icon(c, icons["check"]).FontSize(18).TextColor(fg)
		}
		ui.Text(c, label).FontSize(14).FontWeight(500).TextColor(fg).SingleLine()
	})
	if b.Clicked() {
		*on = !*on
	}
}

// listItem is a two-line M3 list item with a leading status icon.
func (a *app) listItem(c *ui.Context, ok bool, title, body string) {
	s := a.scheme
	ui.Row(c.Key(title)).Gap(16).PaddingY(8).Children(func() {
		icon, color := "check_circle", s.Success
		if !ok {
			icon, color = "error", s.Error
		}
		ui.Icon(c, icons[icon]).FontSize(24).TextColor(color)
		ui.Column(c).Gap(2).Grow(1).Shrink(1).Children(func() {
			ui.Text(c, title).FontSize(16).TextColor(s.OnSurface)
			ui.Text(c, body).FontSize(14).TextColor(s.OnSurfaceVariant)
		})
	})
}

// banner is a tonal message strip, an error or a success.
func (a *app) banner(c *ui.Context, isErr bool, msg string) {
	s := a.scheme
	bg, fg, icon := s.TertiaryContainer, s.OnTertiaryContainer, "check_circle"
	if isErr {
		bg, fg, icon = s.ErrorContainer, s.OnErrorContainer, "error"
	}
	ui.Row(c).Background(bg).Radius(12).Padding(12, 16).Gap(12).Children(func() {
		ui.Icon(c, icons[icon]).FontSize(20).TextColor(fg)
		ui.Text(c, msg).FontSize(14).TextColor(fg).Grow(1).Shrink(1)
	})
}
