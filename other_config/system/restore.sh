#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}🔧 Restaurando configuraciones del sistema...${NC}\n"

# Función para restaurar un archivo
restore_file() {
    local source_file="$1"
    local module="$2"
    
    # Obtener path relativo eliminando el nombre del módulo
    # Ej: sdboot/etc/sdboot-manage.conf -> etc/sdboot-manage.conf
    local rel_path="${source_file#$SCRIPT_DIR/$module/}"
    local dest_file="/$rel_path"
    local backup_file="$dest_file.backup"
    
    # Crear directorio destino si no existe
    local dest_dir="$(dirname "$dest_file")"
    if [ ! -d "$dest_dir" ]; then
        echo -e "${YELLOW}  📁 Creando directorio: $dest_dir${NC}"
        sudo mkdir -p "$dest_dir"
    fi
    
    # Hacer backup si el archivo existe y es diferente
    if [ -f "$dest_file" ]; then
        if ! cmp -s "$source_file" "$dest_file"; then
            echo -e "${YELLOW}  💾 Backup: $dest_file -> $backup_file${NC}"
            sudo cp "$dest_file" "$backup_file"
        else
            echo -e "${BLUE}  ✓ Sin cambios: $rel_path${NC}"
            return
        fi
    fi
    
    # Copiar el archivo
    echo -e "${GREEN}  📋 Copiando: $rel_path${NC}"
    sudo cp "$source_file" "$dest_file"
    
    # Preservar permisos si es posible
    sudo chmod --reference="$source_file" "$dest_file" 2>/dev/null || true
}

# Variable para tracking de módulos procesados
modules_processed=0
files_processed=0

# Iterar por cada módulo (carpetas en system/)
for module_dir in "$SCRIPT_DIR"/*/; do
    # Saltar si no es un directorio
    [ -d "$module_dir" ] || continue
    
    # Obtener nombre del módulo
    module_name=$(basename "$module_dir")
    
    # Saltar directorios especiales
    [[ "$module_name" == ".*" ]] && continue
    
    # Contar archivos en el módulo
    file_count=$(find "$module_dir" -type f ! -name "*.md" | wc -l)
    
    if [ "$file_count" -eq 0 ]; then
        continue
    fi
    
    echo -e "${MAGENTA}📦 Módulo: $module_name ($file_count archivo(s))${NC}"
    ((modules_processed++))
    
    # Procesar archivos del módulo
    while IFS= read -r -d '' file; do
        restore_file "$file" "$module_name"
        ((files_processed++))
    done < <(find "$module_dir" -type f ! -name "*.md" -print0)
    
    echo ""
done

if [ "$modules_processed" -eq 0 ]; then
    echo -e "${RED}❌ No se encontraron módulos para restaurar${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Restauración completada${NC}"
echo -e "${BLUE}   Módulos procesados: $modules_processed${NC}"
echo -e "${BLUE}   Archivos procesados: $files_processed${NC}"

# Post-actions específicas
if [ -d "$SCRIPT_DIR/sdboot" ]; then
    echo -e "\n${YELLOW}🔄 Regenerando entradas de systemd-boot...${NC}"
    sudo sdboot-manage gen
    echo -e "${GREEN}✅ Entradas regeneradas${NC}"
fi

echo -e "\n${BLUE}💡 Tip: Revisa los archivos .backup si necesitas revertir cambios${NC}"
