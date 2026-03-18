#!/usr/bin/env bash

if [[ $HYDE_SHELL_INIT -ne 1 ]]; then
    eval "$(hyde-shell init)"
else
    export_hyde_config
fi

cliphist_style="${ROFI_CLIPHIST_STYLE:-clipboard}"

run_rofi() {
    local placeholder="$1"
    shift
    rofi -dmenu \
        -theme-str "entry { placeholder: \"$placeholder\";}" \
        -theme-str "$font_override" \
        -theme-str "$r_override" \
        -theme-str "$rofi_position" \
        -theme "${cliphist_style}" \
        "$@"
}

setup_rofi_config() {
    local font_scale="${ROFI_SCREENSHOT_SCALE:-10}"
    local font_name="${ROFI_SCREENSHOT_FONT:-$(get_hyprConf "MENU_FONT")}"
    font_name="${font_name:-JetBrainsMono Nerd Font}"
    font_override="* {font: \"${font_name} ${font_scale}\";}"
    
    local hypr_border="$(hyprctl -j getoption decoration:rounding | jq '.int')"
    local wind_border=$((hypr_border * 3 / 2))
    local elem_border=$((hypr_border == 0 ? 5 : hypr_border))
    rofi_position=$(get_rofi_pos)
    local hypr_width="$(hyprctl -j getoption general:border_size | jq '.int')"
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;} element{border-radius:${elem_border}px;}"
}

setup_rofi_config

# Menú principal
selected=$(cat <<EOF | run_rofi "📸 Screenshot Menu"
📷 Area with Delay
❄️ Freeze with Delay
🖥️ Current Monitor
🌐 All Monitors
🔍 OCR Scan
📱 QR Scan
EOF
)

[[ -z "$selected" ]] && exit 0

case "$selected" in
    "📷 Area with Delay")
        exec screenshot.sh sd
        ;;
    "❄️ Freeze with Delay")
        exec screenshot.sh sfd
        ;;
    "🖥️ Current Monitor")
        exec screenshot.sh m
        ;;
    "🌐 All Monitors")
        exec screenshot.sh p
        ;;
    "🔍 OCR Scan")
        exec screenshot.sh sc
        ;;
    "📱 QR Scan")
        exec screenshot.sh sq
        ;;
esac
