#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}💾 Haciendo backup de configuraciones del sistema...${NC}\n"

# Configuración de módulos
# Formato: "nombre_modulo:ruta_absoluta_archivo"
declare -A MODULES=(
    ["sdboot"]="/etc/sdboot-manage.conf"
    ["pacman"]="/etc/pacman.conf /etc/makepkg.conf"
    ["fstab"]="/etc/fstab"
    # Añade más módulos aquí
    # ["grub"]="/etc/default/grub"
    # ["nvidia"]="/etc/modprobe.d/nvidia.conf"
)

backup_count=0
module_count=0

for module_name in "${!MODULES[@]}"; do
    echo -e "${MAGENTA}📦 Módulo: $module_name${NC}"
    module_has_files=false
    
    # Separar múltiples archivos por espacios
    for file in ${MODULES[$module_name]}; do
        if [ ! -f "$file" ]; then
            echo -e "${YELLOW}  ⚠ No existe: $file (saltando)${NC}"
            continue
        fi
        
        # Obtener path relativo desde /
        rel_path="${file#/}"
        dest="$SCRIPT_DIR/$module_name/$rel_path"
        
        # Crear directorio si no existe
        mkdir -p "$(dirname "$dest")"
        
        # Copiar
        cp "$file" "$dest"
        echo -e "${GREEN}  ✓ $file${NC}"
        ((backup_count++))
        module_has_files=true
    done
    
    if [ "$module_has_files" = true ]; then
        ((module_count++))
    fi
    
    echo ""
done

echo -e "${GREEN}✅ Backup completado${NC}"
echo -e "   Módulos: $module_count${NC}"
echo -e "   Archivos: $backup_count${NC}"
echo -e "\n${YELLOW}💡 No olvides hacer commit y push a Git${NC}"
