# ~/.config/zsh/functions/w3m.zsh
# Funciones para búsquedas web con w3m

# Función auxiliar para URL encoding
_urlencode() {
    python3 -c "import urllib.parse; print(urllib.parse.quote_plus('$*'))"
}

# DuckDuckGo (versión lite, perfecta para w3m)
duckit() {
    echo "🦆 Buscando: $*"
    w3m "https://lite.duckduckgo.com/lite/?q=$*"
}

# Google
googleit() {
    echo "🔍 Google: $*"
    w3m "https://www.google.com/search?q=$*"
}

# Brave
braveit() {
    echo "🦁 Brave: $*"
    w3m "https://search.brave.com/search?q=$*"
}
alias '?'='duckit'

# Wikipedia (español)
wiki() {
    echo "📚 Wikipedia: $*"
    w3m "https://es.wikipedia.org/wiki/Special:Search?search=$*"
}

# GitHub
w3m-gh() {
    echo "🐙 GitHub: $*"
    w3m "https://github.com/search?q=$*"
}

# Stack Overflow (para el pan de cada día)
w3m-so() {
    echo "📚 Stack Overflow: $*"
    w3m "https://stackoverflow.com/search?q=$*"
}

# Arch Wiki (porque sé que usas Arch, btw)
archwiki() {
    echo "🐧 Arch Wiki: $*"
    w3m "https://wiki.archlinux.org/index.php?search=$*"
}
