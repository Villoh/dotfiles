# Zed + Vim Cheatsheet

> **Modos Vim:** `NORMAL` es el modo base. `INSERT` para escribir. `VISUAL` para seleccionar.
> Siempre puedes volver a NORMAL con `Esc` o `Ctrl+[`.

---

## 🔀 Modos

| Atajo | Acción |
|-------|--------|
| `Esc` / `Ctrl+[` | Volver a NORMAL |
| `i` | INSERT antes del cursor |
| `a` | INSERT después del cursor |
| `I` | INSERT al inicio de la línea |
| `A` | INSERT al final de la línea |
| `o` | Nueva línea debajo + INSERT |
| `O` | Nueva línea arriba + INSERT |
| `v` | VISUAL (carácter) |
| `V` | VISUAL (línea) |
| `Ctrl+v` | VISUAL BLOCK (columnas) |

---

## 🧭 Movimiento básico

| Atajo | Acción |
|-------|--------|
| `h j k l` | ← ↓ ↑ → |
| `w` | Siguiente palabra |
| `b` | Palabra anterior |
| `e` | Final de la palabra |
| `W B E` | Igual pero ignorando puntuación |
| `0` | Inicio de línea |
| `^` | Primer carácter no vacío |
| `$` | Final de línea |
| `gg` | Inicio del archivo |
| `G` | Final del archivo |
| `{numero}G` | Ir a línea número |
| `Ctrl+d` | Bajar media pantalla |
| `Ctrl+u` | Subir media pantalla |
| `Ctrl+f` | Bajar página completa |
| `Ctrl+b` | Subir página completa |
| `%` | Saltar al bracket/paréntesis correspondiente |
| `H` | Línea visible superior |
| `M` | Línea visible central |
| `L` | Línea visible inferior |

---

## 🔍 Búsqueda y salto

| Atajo | Acción |
|-------|--------|
| `/texto` | Buscar hacia adelante |
| `?texto` | Buscar hacia atrás |
| `n` | Siguiente resultado |
| `N` | Resultado anterior |
| `*` | Buscar palabra bajo el cursor (adelante) |
| `#` | Buscar palabra bajo el cursor (atrás) |
| `f{char}` | Saltar al siguiente `char` en la línea |
| `F{char}` | Saltar al anterior `char` en la línea |
| `t{char}` | Saltar justo antes del siguiente `char` |
| `;` | Repetir último `f/F/t/T` |
| `,` | Repetir último `f/F/t/T` en sentido contrario |

---

## ✂️ Edición (NORMAL)

| Atajo | Acción |
|-------|--------|
| `x` | Borrar carácter bajo el cursor |
| `X` | Borrar carácter anterior |
| `dd` | Borrar línea |
| `D` | Borrar desde cursor hasta fin de línea |
| `cc` | Cambiar línea completa (borra + INSERT) |
| `C` | Cambiar desde cursor hasta fin de línea |
| `yy` | Copiar línea |
| `p` | Pegar después |
| `P` | Pegar antes |
| `u` | Deshacer |
| `Ctrl+r` | Rehacer |
| `r{char}` | Reemplazar carácter bajo el cursor |
| `~` | Alternar mayúscula/minúscula |
| `J` | Unir línea siguiente a la actual |
| `.` | Repetir última acción |

---

## 🎯 Operadores + Movimientos (el poder real de Vim)

> Los operadores se combinan con movimientos: `{operador}{movimiento}`

| Operador | Acción |
|----------|--------|
| `d` | Borrar |
| `c` | Cambiar (borra + INSERT) |
| `y` | Copiar (yank) |
| `>` | Indentar |
| `<` | Desindentar |
| `=` | Formatear/autoindent |

### Ejemplos prácticos

| Atajo | Acción |
|-------|--------|
| `dw` | Borrar hasta la siguiente palabra |
| `d$` | Borrar hasta el final de la línea |
| `d0` | Borrar hasta el inicio de la línea |
| `diw` | Borrar la palabra bajo el cursor |
| `di"` | Borrar contenido entre comillas |
| `di(` | Borrar contenido entre paréntesis |
| `di{` | Borrar contenido entre llaves |
| `dit` | Borrar contenido de una etiqueta HTML/XML |
| `ci"` | Cambiar contenido entre comillas |
| `ca(` | Cambiar paréntesis y su contenido |
| `yiw` | Copiar la palabra bajo el cursor |
| `y$` | Copiar hasta el final de la línea |
| `>ip` | Indentar párrafo |
| `=G` | Formatear desde cursor hasta final |

---

## 🔢 Números como multiplicador

> Cualquier movimiento o acción puede precederse de un número.

| Atajo | Acción |
|-------|--------|
| `5j` | Bajar 5 líneas |
| `3w` | Avanzar 3 palabras |
| `2dd` | Borrar 2 líneas |
| `10yy` | Copiar 10 líneas |
| `3p` | Pegar 3 veces |

---

## 📦 Registros (portapapeles múltiple)

| Atajo | Acción |
|-------|--------|
| `"ayy` | Copiar línea al registro `a` |
| `"ap` | Pegar desde registro `a` |
| `"+y` | Copiar al portapapeles del sistema |
| `"+p` | Pegar desde el portapapeles del sistema |
| `""p` | Pegar desde el registro por defecto |

---

## 📌 Marcas

| Atajo | Acción |
|-------|--------|
| `m{a-z}` | Crear marca local `a-z` |
| `'{marca}` | Saltar a la línea de la marca |
| `` `{marca} `` | Saltar a la posición exacta de la marca |
| `''` | Saltar a la posición anterior |

---

## 🔁 Macros

| Atajo | Acción |
|-------|--------|
| `q{a-z}` | Empezar a grabar macro en registro |
| `q` | Parar grabación |
| `@{a-z}` | Ejecutar macro |
| `@@` | Repetir última macro |
| `10@a` | Ejecutar macro `a` 10 veces |

---

## 🪟 Splits y ventanas (Zed + Vim)

| Atajo | Acción |
|-------|--------|
| `Ctrl+w s` | Split horizontal |
| `Ctrl+w v` | Split vertical |
| `Ctrl+w h/j/k/l` | Moverse entre splits |
| `Ctrl+w w` | Siguiente split |
| `Ctrl+w =` | Igualar tamaño de splits |
| `Ctrl+w q` | Cerrar split |

---

## ⚡ Zed — Comandos globales

| Atajo | Acción |
|-------|--------|
| `Cmd+Shift+P` / `Ctrl+Shift+P` | Command Palette |
| `Cmd+P` / `Ctrl+P` | Buscar archivo |
| `Cmd+Shift+F` / `Ctrl+Shift+F` | Buscar en todo el proyecto |
| `Cmd+,` / `Ctrl+,` | Abrir Settings |
| `Cmd+K Cmd+S` | Abrir Keymap |
| `Cmd+Shift+E` | Abrir/cerrar panel de proyecto |
| `Cmd+Shift+O` | Ir a símbolo en el archivo |
| `Cmd+T` | Ir a símbolo en el proyecto |
| `Cmd+L` | Ir a línea |
| `Cmd+W` | Cerrar pestaña |
| `Cmd+Shift+T` | Reabrir pestaña cerrada |

---

## 🔤 Zed — Edición

| Atajo | Acción |
|-------|--------|
| `Cmd+D` | Seleccionar siguiente ocurrencia |
| `Cmd+Shift+L` | Seleccionar todas las ocurrencias |
| `Cmd+/` | Comentar/descomentar línea |
| `Cmd+]` / `Cmd+[` | Indentar / Desindentar |
| `Alt+↑` / `Alt+↓` | Mover línea arriba/abajo |
| `Cmd+Shift+D` | Duplicar línea |
| `Cmd+Shift+K` | Borrar línea |
| `Cmd+Enter` | Nueva línea debajo sin mover cursor |
| `Cmd+Shift+Enter` | Nueva línea arriba sin mover cursor |
| `Ctrl+Space` | Forzar autocompletado |

---

## 🧠 Zed — LSP e Inteligencia

| Atajo | Acción |
|-------|--------|
| `F12` / `Cmd+Click` | Ir a definición |
| `Cmd+F12` | Ir a implementación |
| `Shift+F12` | Ver referencias |
| `F2` | Renombrar símbolo |
| `Cmd+.` | Code actions (fix, refactor...) |
| `K` | Mostrar hover/documentación (Vim normal) |
| `Shift+K` | Hover en Zed sin Vim |
| `]d` / `[d` | Siguiente/anterior diagnóstico |
| `]e` / `[e` | Siguiente/anterior error |

---

## 🔀 Zed — Git

| Atajo | Acción |
|-------|--------|
| `Cmd+Shift+G` | Abrir panel Git |
| `]c` / `[c` | Siguiente/anterior cambio en el gutter |
| `Cmd+Alt+Z` | Revertir hunk bajo el cursor |

---

## 🖥️ Zed — Terminal

| Atajo | Acción |
|-------|--------|
| `Ctrl+\`` | Abrir/cerrar terminal |
| `Cmd+Shift+\`` | Nueva terminal |

---

## 💡 Flujo recomendado para aprender

1. **Semana 1-2:** `h j k l`, `w b e`, `dd yy p`, `i a o`, `u Ctrl+r`
2. **Semana 3-4:** `f t / ?`, operadores + movimientos (`diw`, `ci"`, `d$`)
3. **Semana 5-6:** números como multiplicador, registros, marcas
4. **Semana 7+:** macros, splits, comandos `:` de ex

> La clave es **no aprenderlo todo de golpe**. Incorpora 2-3 atajos nuevos por semana y úsalos hasta que sean musculares.