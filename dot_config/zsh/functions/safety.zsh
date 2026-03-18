# ═══════════════════════════════════════════════════════════
# TRASH MANAGEMENT - trashy
# ═══════════════════════════════════════════════════════════
alias trp='trashy put' # Mover a papelera
alias trl='trashy list' # Listar papelera
alias trr='trashy restore' # Restaurar archivos
alias tre='trashy empty' # Vaciar archivos específicos
alias trea='trashy empty --all' # Vaciar toda la papelera
alias trra='trashy restore --all' # Restaurar todo

# ═══════════════════════════════════════════════════════════
# PROTECCIÓN CONTRA ELIMINACIÓN ACCIDENTAL
# ═══════════════════════════════════════════════════════════
# Bloquear rm (fuerza usar papelera)
#alias rmi='command rm -i' # rm con confirmación

#rm() {
#    echo -e "\033[1;31mrm bloqueado\033[0m"
#    echo -e "\033[0;33mOpciones disponibles:\033[0m"
#    echo -e "  - \033[0;32mtp\033[0m <archivo>     (papelera recuperable)"
#    echo -e "  - \033[0;32mrmi\033[0m <archivo>    (rm con confirmación)"
#    return 1
#}

# Proteger find -delete con preview (compatible con zsh)
find() {
    # Detectar -delete
    for arg in "$@"; do
        if [[ "$arg" == "-delete" ]]; then
            # Construir comando sin -delete
            local cmd_parts=("find")
            for a in "$@"; do
                [[ "$a" != "-delete" ]] && cmd_parts+=("$a")
            done
            
            echo -e "\033[0;31m❌ find -delete bloqueado\033[0m"
            echo -e "Alternativa: \033[0;32m${cmd_parts[@]} -exec trashy put '{}' +\033[0m"
            return 1
        fi
    done
    
    command find "$@"
}

