#!/usr/bin/env bash

cliphist_style="${ROFI_CLIPHIST_STYLE:-clipboard}"

if [[ $HYDE_SHELL_INIT -ne 1 ]]; then
    eval "$(hyde-shell init)"
else
    export_hyde_config
fi

USAGE() {
    cat <<"USAGE"

	Usage: $(basename "$0") [option]
	Options:
		p     Print all outputs
		s     Select area or window to screenshot
		sf    Select area or window with frozen screen
		m     Screenshot focused monitor
		sc    Use tesseract to scan image, then add to clipboard
		sd    Select area with custom delay
		sfd   Freeze + select area with custom delay

USAGE
}

SCREENSHOT_POST_COMMAND+=()
SCREENSHOT_PRE_COMMAND+=()

pre_cmd() {
    for cmd in "${SCREENSHOT_PRE_COMMAND[@]}"; do
        eval "$cmd"
    done
    trap 'post_cmd' EXIT
}

post_cmd() {
    for cmd in "${SCREENSHOT_POST_COMMAND[@]}"; do
        eval "$cmd"
    done
}

temp_screenshot=${XDG_RUNTIME_DIR:-/tmp}/hyde_screenshot.png
if [ -z "$XDG_PICTURES_DIR" ]; then
    XDG_PICTURES_DIR="$HOME/Pictures"
fi
confDir="${confDir:-$XDG_CONFIG_HOME}"
save_dir="${2:-$XDG_PICTURES_DIR/Screenshots}"
save_file=$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')
annotation_tool="${SCREENSHOT_ANNOTATION_TOOL}"
annotation_args=("-o" "$save_dir/$save_file" "-f" "$temp_screenshot")
GRIMBLAST_EDITOR=${GRIMBLAST_EDITOR:-$annotation_tool}
tesseract_default_language=("eng")
tesseract_languages=("${SCREENSHOT_OCR_TESSERACT_LANGUAGES[@]:-${tesseract_default_language[@]}}")
tesseract_languages+=("osd")

if [[ -z $annotation_tool ]]; then
    pkg_installed "swappy" && annotation_tool="swappy"
    pkg_installed "satty" && annotation_tool="satty"
fi

mkdir -p "$save_dir"

if [[ $annotation_tool == "swappy" ]]; then
    swpy_dir="$confDir/swappy"
    mkdir -p "$swpy_dir"
    echo -e "[Default]\nsave_dir=$save_dir\nsave_filename_format=$save_file" >"$swpy_dir"/config
fi

if [[ $annotation_tool == "satty" ]]; then
    annotation_args+=("--copy-command" "wl-copy")
fi

[[ -n ${SCREENSHOT_ANNOTATION_ARGS[*]} ]] && annotation_args+=("${SCREENSHOT_ANNOTATION_ARGS[@]}")

take_screenshot() {
    local mode=$1
    shift
    local extra_args=("$@")
    if "$LIB_DIR/hyde/screenshot/grimblast" "${extra_args[@]}" copysave "$mode" "$temp_screenshot"; then
        [[ ${SCREENSHOT_ANNOTATION_ENABLED} == false ]] && return 0
        if ! "$annotation_tool" "${annotation_args[@]}"; then
            send_notifs -r 9 -a "HyDE Alert" "Screenshot Error" "Failed to open annotation tool"
            return 1
        fi
    else
        send_notifs -a "HyDE Alert" "Screenshot Error" "Failed to take screenshot"
        return 1
    fi
}

ocr_screenshot() {
    local mode=$1
    shift
    local extra_args=("$@")
    if "$LIB_DIR/hyde/screenshot/grimblast" "${extra_args[@]}" copysave "$mode" "$temp_screenshot"; then
        source "${LIB_DIR}/hyde/shutils/ocr.sh"
        source ${XDG_STATE_HOME}/hyde/config
        print_log -g "Performing OCR on $temp_screenshot"
        send_notifs "OCR" "Performing OCR on screenshot..." -i "document-scan" -r 9
        if ! ocr_extract "$temp_screenshot"; then
            send_notifs -r 9 -a "HyDE Alert" "OCR: extraction error" -e -i "dialog-error"
            return 1
        fi
    else
        send_notifs -a "HyDE Alert" "OCR: screenshot error" -e -i "dialog-error"
        return 1
    fi
}

qr_screenshot() {
    local mode=$1
    shift
    local extra_args=("$@")
    if "$LIB_DIR/hyde/screenshot/grimblast" "${extra_args[@]}" copysave "$mode" "$temp_screenshot"; then
        source "${LIB_DIR}/hyde/shutils/qr.sh"
        print_log -g "Performing QR scan on $temp_screenshot"
        send_notifs "QR Scan" "Performing QR scan on screenshot..." -i "document-scan" -r 9
        if ! qr_extract "$temp_screenshot"; then
            send_notifs -r 9 -a "HyDE Alert" "QR: extraction error" -e -i "dialog-error"
            return 1
        fi
    else
        send_notifs -a "HyDE Alert" "QR: screenshot error" -e -i "dialog-error"
        return 1
    fi
}

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

pre_cmd

case $1 in
    p) 
        take_screenshot "screen" 
        ;;
    s) 
        take_screenshot "area" 
        ;;
    sf) 
        take_screenshot "area" "--freeze" 
        ;;
    m) 
        take_screenshot "output" 
        ;;
    sc) 
        ocr_screenshot "area" "--freeze" 
        ;;
    sq) 
        qr_screenshot "area" "--freeze" 
        ;;
sd)
  setup_rofi_config
  delay_secs=$(echo -e "0\n1\n2\n3\n5\n10\n15\ncustom" | run_rofi "⏱️ Delay (s)")
  [[ -z "$delay_secs" ]] && exit 0
  if [[ "$delay_secs" == "custom" ]]; then
    delay_secs=$(echo "" | run_rofi "⏱️ Escribe delay en segundos" -mesg "Introduce un número")
    [[ -z "$delay_secs" ]] && exit 0
  fi
  [[ "$delay_secs" == "0" ]] && exec "$0" s
  sleep "$delay_secs"
  exec "$0" s
  ;;
sfd)
  setup_rofi_config
  delay_secs=$(echo -e "0\n1\n2\n3\n5\n10\n15\ncustom" | run_rofi "⏱️ Freeze + Delay (s)")
  [[ -z "$delay_secs" ]] && exit 0
  if [[ "$delay_secs" == "custom" ]]; then
    delay_secs=$(echo "" | run_rofi "⏱️ Escribe delay en segundos" -mesg "Introduce un número")
    [[ -z "$delay_secs" ]] && exit 0
  fi
  [[ "$delay_secs" == "0" ]] && exec "$0" sf
  sleep "$delay_secs"
  exec "$0" sf
  ;;

    *) 
        USAGE 
        ;;
esac

[ -f "$temp_screenshot" ] && rm "$temp_screenshot"
if [ -f "$save_dir/$save_file" ]; then
    send_notifs -r 9 -a "HyDE Alert" -i "$save_dir/$save_file" "saved in $save_dir"
fi
