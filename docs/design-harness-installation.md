# Micro harness de diseño — guía de instalación para agentes

Estado: **instalación local parcial verificada el 20-09-2026**. Skills y CLIs
instaladas; MCPs configurados para Pi. Faltan autenticación fal, recarga de Pi y
validación en un proyecto frontend real. Ver [registro local](#registro-local-20-09-2026).

Objetivo: preparar un entorno portable entre agentes para landing pages,
dashboards/apps y presentaciones, con acceso a componentes, motion y assets
2D/3D. Reutilizar herramientas existentes; no construir un orquestador propio.

Leer este documento no autoriza a instalar. Ejecutar sus pasos cuando el usuario
pida aplicar la guía, dentro del alcance que haya aprobado.

## 1. Límites y decisiones previas

- **Coste:** servicios gratuitos o un plan gratuito útil. La única excepción es
  **fal.ai**, donde el usuario ya dispone de saldo. Tener saldo no autoriza a
  gastarlo: cada generación necesita presupuesto aprobado para esa tarea.
- Al agotar una cuota gratuita, usar alternativa o avisar. No activar pruebas
  con renovación, suscripciones, compras de créditos ni recargas automáticas.
- **Fuentes de assets:** admitir solo proveedores con CLI o MCP verificado que
  permita recuperar o generar recursos dentro del plan permitido. Una web,
  API HTTP o biblioteca instalable con npm no basta. No crear wrappers ni usar
  navegador/curl como sustituto de un conector para eludir este filtro.
- **Secretos:** utilizar el gestor de secretos existente o autenticación del
  cliente. Nunca guardar claves/tokens en Markdown, configuraciones versionadas,
  argumentos de comandos ni logs. Este repositorio cifra secretos con GPG.
- **Propiedad de archivos:** NixOS/Home Manager gestiona paquetes y configuración
  declarativa existente; chezmoi solo archivos personales no gestionados por Nix.
  Consultar [Linux](linux.md) antes de modificar esa instalación.
- **Alcance:** skills personales compartidas; dependencias de frontend y
  registries por proyecto. No inicializar una app React dentro de este repo.
- **Portabilidad:** una fuente mantenida de cada skill, expuesta mediante rutas
  soportadas por cada agente. La configuración MCP y el manejo de secretos
  varían entre clientes: no asumir un JSON universal.
- Conservar cambios ajenos y configuraciones existentes. Revisar diferencias
  antes de reemplazar skills, añadir servidores o migrar rutas.

Antes de ejecutar, resolver con el usuario lo que no conste en el contexto:

1. Agentes destinatarios y sistema operativo.
2. Repositorio Nix/Home Manager propietario de los paquetes que falten.
3. Proyecto frontend donde probar integración de componentes.
4. Autenticación existente de fal. No pedir que pegue la clave en el chat.

**Terminado cuando:** destinos, alcance y propietarios están identificados; las
credenciales ausentes constan como pendientes, sin inventar valores.

## 2. Inventariar antes de instalar

Comprobar ejecutables y sus versiones sin imprimir variables de entorno:

```bash
command -v node npx git python3 ffmpeg magick agent-browser
```

Inventariar también skills visibles, rutas reales/symlinks y conexiones MCP por
agente. La conversación previa detectó `frontend-slides`, `agent-browser`,
`better-writing`, Context7, FFmpeg e ImageMagick; **volver a comprobar**, no usar
ese inventario como prueba de la máquina actual.

Para cambios en este repositorio, resolver la fuente con `chezmoi source-path`.
`docs/**` ya está excluido en `.chezmoiignore`; esta guía no se despliega al HOME.

Antes de invocar instaladores:

- Revisar upstream y seleccionar versiones concretas de los CLIs.
- Registrar versiones y commits de las skills instaladas. Para fijar una revisión
  de una skill, instalar desde un checkout local revisado; el CLI admite rutas
  locales. No confundir fijar el CLI con fijar el contenido de las skills.
- Usar gestor y lockfile existentes. Evitar `latest` en configuración persistente.
- Guardar una copia privada de configuraciones que vayan a cambiar. Si contienen
  secretos, usar almacenamiento cifrado/seguro, nunca una copia dentro del repo.

**Terminado cuando:** cada pieza figura como reutilizable, pendiente o descartada,
con su propietario. No reinstalar lo que ya funciona.

## 3. Instalar skills y preservar referencias

### Selección

| Fase | Skill / fuente | Activación |
| --- | --- | --- |
| Landing | `frontend-design` de [anthropics/skills](https://github.com/anthropics/skills) | Dirección e implementación de landing |
| Dashboard/app | `interface-design` de [dammyjay93/interface-design](https://github.com/dammyjay93/interface-design) | Flujos, jerarquía, densidad y estados |
| Presentación | `frontend-slides`, versión local existente | Reutilizar, conservar personalizaciones |
| Comparar componentes | `variant` de [jakubkrehel/skills](https://github.com/jakubkrehel/skills) | Petición explícita |
| Pulir motion | `emil-design-eng` de [emilkowalski/skills](https://github.com/emilkowalski/skills) | Fase de motion/pulido |
| Especialidad | Jakub: `better-typography`, `better-colors`, `better-accessibility`, `better-layout`, `better-writing` | Solo dominio necesario |
| Estrés visual | Jakub: `break` | Petición explícita, un componente |
| Revisión común | `web-design-guidelines` de [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | Junto a verificación en navegador |
| Operar componentes | `shadcn` de [shadcn-ui/ui](https://github.com/shadcn-ui/ui/tree/main/skills/shadcn) | Proyectos shadcn; respetar versión revisada y permisos del agente |

Una skill dirige cada fase. Requisitos del producto, accesibilidad y sistema del
proyecto prevalecen sobre preferencias estéticas de una skill. No aplicar Emil y
`better-ui` simultáneamente al mismo componente.

Conservar carpetas completas, no solo `SKILL.md`. Las skills de Jakub se
referencian entre sí: mantener disponibles `better-interface` y sus seis módulos
propietarios, incluido `better-ui`. Disponibles no significa cargados siempre.
`better-interface` queda para revisión profunda solicitada, no como otro revisor
obligatorio junto a Vercel. `variant` y `break` deben seguir siendo manuales,
incluso si un cliente ignora `disable-model-invocation`.

### Procedimiento

Consultar [Skills CLI](https://github.com/vercel-labs/skills). Definir
`SKILLS_VERSION` con una versión revisada. Ejemplos Bash; **ejecutar únicamente
las instalaciones que falten**, ajustando la selección de skills:

```bash
: "${SKILLS_VERSION:?Set a reviewed skills CLI version}"
export DISABLE_TELEMETRY=1

npx "skills@$SKILLS_VERSION" add anthropics/skills --list
npx "skills@$SKILLS_VERSION" add dammyjay93/interface-design --list
npx "skills@$SKILLS_VERSION" add emilkowalski/skills --list
npx "skills@$SKILLS_VERSION" add jakubkrehel/skills --list
npx "skills@$SKILLS_VERSION" add vercel-labs/agent-skills --list
```

Leer las skills seleccionadas y sus referencias antes de instalarlas. Después:

```bash
: "${SKILLS_VERSION:?Set a reviewed skills CLI version}"
export DISABLE_TELEMETRY=1

npx "skills@$SKILLS_VERSION" add anthropics/skills --global --skill frontend-design
npx "skills@$SKILLS_VERSION" add dammyjay93/interface-design --global --skill interface-design
npx "skills@$SKILLS_VERSION" add emilkowalski/skills --global --skill emil-design-eng
npx "skills@$SKILLS_VERSION" add vercel-labs/agent-skills --global --skill web-design-guidelines
npx "skills@$SKILLS_VERSION" add jakubkrehel/skills --global --skill \
  variant break better-interface better-ui better-typography better-colors \
  better-accessibility better-layout better-writing
```

Comprobar la ruta global de la versión del instalador: versiones nuevas pueden
usar `~/.config/agents/skills` para el destino universal. Si el usuario pide
`~/.agents/skills`, copiar ahí las carpetas completas desde checkouts revisados
es válido; registrar commits y comprobar referencias, sin sobrescribir destinos.
El CLI `skills` no es una dependencia necesaria del harness.

Elegir interactivamente solo agentes aprobados y método **symlink** cuando sea
compatible. En ejecución no interactiva, añadir `--agent` con identificadores
verificados en la documentación del CLI. No usar `--all` ni seleccionar todos
los agentes de la máquina por defecto.

Si una skill ya existe o está personalizada, detener su reemplazo, comparar y
preservar la versión local. Para reproducibilidad, sustituir las fuentes remotas
de los ejemplos por checkouts locales fijados a los commits revisados.

`frontend-slides` se reutiliza con sus presets, referencias, CSS y scripts. Si no
está disponible, pedir la fuente aprobada; no sustituirla por otra skill homónima.
Lo mismo aplica al adaptador local de `agent-browser` y a Context7: reutilizarlos,
o seguir su documentación oficial si faltan.

**Terminado cuando:** cada agente aprobado descubre las skills previstas, sus
referencias resuelven y no existen copias divergentes ni personalizaciones
sobrescritas. Reiniciar/recargar el cliente solo cuando su mecanismo lo requiera.

## 4. Preparar herramientas locales

| Herramienta | Uso | Instalación |
| --- | --- | --- |
| `agent-browser` + navegador compatible | Capturas, estados e interacciones | Reutilizar configuración existente |
| FFmpeg / ImageMagick | Vídeo, posters, loops, tamaños y formatos | Reutilizar; declarar faltantes en Nix |
| Node / gestor de paquetes | CLIs y proyectos frontend | Respetar propietario y versión del proyecto |
| Python | Scripts de assets y slides cuando lo requieran | Reutilizar entorno; herramientas Python mediante `uv tool install`, no pip global |
| `shadcn` | MCP stdio, búsqueda e inspección de registries | Versión revisada; usar CLI instalado o runner fijado |
| `motion-primitives` | Listar y añadir microinteracciones | Versión revisada; `add` sobrescribe archivos e instala dependencias automáticamente |

No toda CLI necesita skill propia. shadcn dispone de skill oficial y MCP;
`agent-browser` sirve su guía mediante `skills get core`. Para Motion Primitives,
`--help`, `list` y documentación oficial cubren su interfaz pequeña: no crear una
skill duplicada.

En Linux, no añadir bootstrap de paquetes a chezmoi ni ejecutar instaladores de
sistema sugeridos por upstream. Para otro SO, seguir el gestor existente; para
Windows consultar [su guía](windows.md).

Para navegador, cargar instrucciones de la versión instalada:

```bash
agent-browser skills get core
```

Usar una sesión propia, separada de otras sesiones/agentes. En NixOS, resolver
Chromium y sus dependencias mediante la configuración existente; no ejecutar
`agent-browser install --with-deps` como sustituto de Nix.

El flujo 3D es web-first: componentes/escenas Three.js o modelos GLB/glTF
consumidos directamente por el frontend. Blender no es un requisito ni se
instala como parte de esta guía.

**Terminado cuando:** binarios necesarios disponibles, navegador abre una página
local y las herramientas multimedia procesan un archivo de prueba sin modificar
el original. Instalar un binario no basta para verificar su funcionamiento.

## 5. Conectar fal sin consumir saldo

Fuente: [MCP oficial de fal](https://fal.ai/docs/documentation/setting-up/mcp).

| Campo | Valor |
| --- | --- |
| Transporte | Streamable HTTP |
| Endpoint | `https://mcp.fal.ai/mcp` |
| Autenticación | OAuth oficial si el cliente lo admite, o clave existente mediante mecanismo seguro |
| Header para API key | `Authorization: Bearer <clave resuelta en runtime>` |

Adaptar al cliente destino y fusionar con sus servidores existentes. La forma de
inyectar una variable/secret en headers depende del cliente: no asumir que
`${FAL_KEY}` se expande en cualquier JSON. No pegar una clave literal en una
configuración versionada ni pasarla como argumento visible de un comando.
Si no hay mecanismo seguro disponible, dejar conexión pendiente.

Verificar cuenta/equipo asociado, no solo que la autenticación funcione. La
primera prueba consiste en buscar modelos, leer schemas y consultar precios.
**No ejecutar `run_model`, `submit_job` ni subir archivos en esta prueba.**

Para uso posterior: consultar modelo, schema, licencia y precio vigentes; fijar
cantidad/resolución/duración dentro del presupuesto aprobado. Conservar IDs de
trabajos y consultar su estado antes de reintentar una operación incierta, para
no duplicar cargos. Descargar resultados: una URL temporal no es un entregable.

El servidor alojado no puede leer rutas locales. Para subir material autorizado,
seguir su schema vigente de URL/base64 u otro mecanismo oficial; no publicar
archivos privados para solventar esa limitación sin consentimiento.

**Terminado cuando:** todos los clientes autorizados pueden buscar modelos y
consultar precios con la cuenta correcta, sin ejecuciones de pago ni secretos
en el diff, salida o historial de comandos.

## 6. Conectar shadcn en un proyecto compatible

Fuente: [MCP oficial de shadcn](https://ui.shadcn.com/docs/mcp).
Este paso pertenece al proyecto frontend, **no al repositorio de dotfiles**.
No imponer React/Tailwind a una app existente ni a slides HTML independientes.

1. Revisar framework, componentes, gestor y `components.json` existentes.
2. Si el proyecto necesita inicialización, proponerla antes de tocar estilos,
   tokens o dependencias. Un archivo con solo `registries` no reemplaza esa fase.
3. Elegir una versión revisada de `shadcn` y configurar su MCP stdio para que
   resuelva el proyecto correcto. Adaptar el esquema y el directorio de trabajo
   al cliente; verificar qué `components.json` está leyendo.

Ejemplo de forma del servidor para clientes con `mcpServers`; sustituir
`REVIEWED_VERSION` y **fusionar**, no reemplazar toda la configuración:

```json
{
  "mcpServers": {
    "shadcn": {
      "command": "npx",
      "args": ["-y", "shadcn@REVIEWED_VERSION", "mcp"]
    }
  }
}
```

Fusionar estos registries con los existentes en `components.json`:

```json
{
  "registries": {
    "@react-bits": "https://reactbits.dev/r/{name}.json",
    "@svgl": "https://svgl.app/r/{name}.json"
  }
}
```

El registry estándar de shadcn no requiere otra URL. Usar exclusivamente recursos
gratuitos aprobados. Antes de añadir un componente, inspeccionar código,
licencia, dependencias y archivos afectados. Conservar tokens y componentes
existentes; no autorizar sobrescrituras en bloque.

**Terminado cuando:** MCP puede buscar e inspeccionar resultados del registry
estándar, React Bits y SVGL dentro del proyecto correcto. Instalar un componente
y verificar build/interacción solo en un proyecto de prueba autorizado, no como
mutación implícita de un proyecto del usuario.

## 7. Habilitar solo fuentes con CLI/MCP

Consultar e incorporar recursos concretos, no instalar catálogos completos.
Verificar cada conector y su plan; que un MCP pueda buscar no garantiza que la
recuperación del código o asset sea gratuita.

| Necesidad | Fuente | Conector | Condiciones |
| --- | --- | --- | --- |
| Componentes base | [shadcn/ui](https://ui.shadcn.com/docs/mcp) | shadcn MCP/CLI | Revisar código y dependencias antes de añadir |
| Componentes visuales, efectos y escenas web | [React Bits](https://reactbits.dev/get-started/mcp) | shadcn MCP/CLI, registry `@react-bits` | Base gratuita; MIT + Commons Clause, no redistribuir componentes como catálogo |
| Logos SVG | [SVGL](https://svgl.app/docs/shadcn-ui) | shadcn MCP/CLI, registry `@svgl` | Respetar marcas y condiciones del recurso |
| Microinteracciones | [Motion Primitives](https://motion-primitives.com/docs/installation) | CLI `motion-primitives` | Versión revisada; añadir solo componentes necesarios |
| Imagen, vídeo, SVG y modelos 3D generados | [fal](https://fal.ai/docs/documentation/setting-up/mcp) | MCP oficial | Único servicio con gasto permitido, sujeto a presupuesto |

CSS, Motion, Three.js/R3F y bibliotecas de iconos son implementación/runtime,
no fuentes de assets que conectar. Reutilizar dependencias del proyecto y añadir
solo las necesarias. Context7 ya cubre su documentación; no añadir Motion MCP
solo para duplicar esa búsqueda.

### Dos tipos de recurso 3D

- **Escena/efecto web:** código de geometría, materiales, shaders e interacciones.
  Recuperar componentes adecuados de React Bits mediante shadcn e integrarlos
  directamente. Por ejemplo, su componente `Ballpit` usa Three.js. Comprobar
  cada implementación: el catálogo también contiene efectos CSS y otros motores
  WebGL; no presentar todo como Three.js ni imponer otro motor al proyecto.
- **Modelo:** archivo GLB/glTF con mallas, materiales y animaciones compatibles.
  Es un formato interoperable, no un formato exclusivo de Blender. Si hace falta
  generar uno, usar un modelo de fal con salida GLB, como Hunyuan3D, tras aprobar
  el gasto. Cargar el archivo directamente en Three.js/R3F.

Generación SVG puede usar Recraft en fal. Resolver modelos y precios por catálogo,
no fijar IDs de generación como si fueran permanentes. Esta selección cubre
componentes 3D web y generación de modelos; todavía no incorpora un catálogo de
modelos existentes con CLI/MCP gratuito validado.

El archivo GLB no incluye toda la lógica de una experiencia web. Verificar en el
renderer final materiales, escala, animaciones, peso y rendimiento móvil. Si un
asset exige una fase de modelado o conversión compleja, elegir otro recurso o
proponer esa tarea aparte; no convertir Blender en dependencia implícita.

Por proyecto, reutilizar documentación existente o guardar como máximo:

- Decisiones de diseño: dirección, tokens, tipografía, densidad y motion. Si ya
  existe `.interface-design/system.md`, mantener esa fuente, no duplicarla.
- Créditos de assets: ruta local, origen, autor, licencia, atribución y cambios.
  Para generación, añadir modelo/parámetros e ID del trabajo, sin secretos.

Inspeccionar SVGs externos antes de integrarlos; evitar scripts y referencias
externas inesperadas. Reutilizar assets locales en vez de URLs efímeras.

**Terminado cuando:** un componente/asset gratuito se ha recuperado mediante su
CLI/MCP y se ha comprobado localmente con licencia identificada. Para la prueba
3D, usar un componente web gratuito del registry. La prueba de carga GLB solo
aplica si se dispone de un modelo autorizado; no generar uno de pago para marcar
una casilla. Si falta, informar esa cobertura como pendiente.

## 8. Pruebas de aceptación y cierre

Realizar pruebas en un proyecto/directorio temporal aprobado. Distinguir una
prueba técnica mínima de un benchmark de calidad visual: no hace falta generar
una landing, un dashboard y una presentación completos para verificar instalación.

| Prueba | Evidencia requerida |
| --- | --- |
| Skills | Visibles en cada agente, referencias accesibles y activación por fase |
| fal | Búsqueda/schema/precio reales; ninguna generación ni cargo de prueba |
| shadcn | Búsqueda e inspección en los tres registries previstos |
| Navegador | Capturas desktop/móvil, foco visible, interacción y estado comprobados |
| Slides | Preview local de la versión existente; si se va a usar PDF, probar exportador aparte |
| 3D web | Componente Three.js/WebGL gratuito recuperado del registry y visible en navegador; carga GLB comprobada aparte cuando haya modelo autorizado |
| Multimedia | Conversión de una imagen o clip local sin sobrescribir original |
| Higiene | Diff acotado, secretos ausentes, sin dependencias ni suscripciones no aprobadas |

Ante un fallo, registrar comando/acción, error y siguiente paso. Una pieza
pendiente puede dejarse desactivada; nunca declarar el harness completo si falta
una prueba requerida. Cerrar solo procesos/sesiones temporales creados para estas
pruebas y retirar fixtures cuando el usuario ya no los necesite.

Entregar un resumen con versiones/commits, agentes configurados, archivos
modificados, pruebas realizadas, límites y pendientes. Registrar también cómo
revertir cada alta: retirar solo los enlaces/servidores creados y revertir los
cambios propios de paquetes, sin borrar configuraciones compartidas preexistentes.

## Registro local 20-09-2026

### Alcance y archivos

Equipo comprobado: **Omarchy**, sin ejecutable Nix. El usuario autorizó
expresamente **pnpm de usuario** para las dos CLIs; no se instalaron paquetes de
sistema ni se cambió la política declarativa de otros equipos.

- 13 skills nuevas en `~/.agents/skills`, copiadas desde commits revisados.
- 3 enlaces desde esa ruta a las versiones existentes en `~/.pi/agent/skills`:
  `frontend-slides`, `agent-browser`, `better-writing`. Originales intactos.
- Pi descubre ambas rutas automáticamente; no se modificó `settings.json`.
- MCPs en `~/.pi/agent/mcp.json`, enlace al archivo fuente
  `dot_pi/agent/mcp.json` de chezmoi. Copia anterior privada:
  `~/.local/state/design-harness/backups/mcp-2026-09-20.json`.
- Recibo con destinos y commits:
  `~/.local/state/design-harness/installation-2026-09-20.json`.
- Sin app, `components.json` ni dependencias frontend dentro del repo de dotfiles.

| Fuente | Commit revisado | Skills nuevas |
| --- | --- | --- |
| `anthropics/skills` | `34040c9c568585f6929bedeaad110ad08f079624` | frontend-design |
| `dammyjay93/interface-design` | `2f9be3206855bcb2d1d0af262c8bae25cba6658d` | interface-design |
| `emilkowalski/skills` | `85e8e2363b713506e1d5b6e07a0eb2da66be1bc3` | emil-design-eng |
| `jakubkrehel/skills` | `267330e1adfc66a718fb65fa6918c1f06d0a689e` | variant, break, better-interface, better-ui, better-typography, better-colors, better-accessibility, better-layout |
| `vercel-labs/agent-skills` | `063bee94c3f4df8453406c830b0a7df0f2860278` | web-design-guidelines |
| `shadcn-ui/ui` | `a87a63b2ca25143d26c8bd0903e4e9bc77b3f824` | shadcn |

Adaptaciones locales registradas: `shadcn/SKILL.md` pierde inyección automática
`!command` y permisos amplios; exige versión revisada, contexto explícito y
prioridad del proyecto. `better-ui/SKILL.md` deja que tokens, motion y
accesibilidad existentes prevalezcan sobre sus recetas exactas. Mantener estos
cambios al actualizar. `variant` y `break` conservan activación manual upstream.
No se instalaron comandos exclusivos de Claude ni `interface-review` opcional.

### Herramientas y pruebas

| Pieza | Resultado comprobado |
| --- | --- |
| `shadcn` **4.21.0** | Instalado con pnpm 12.4.2, versión exacta y scripts de instalación desactivados; CLI `search`/`view` recuperan código real |
| shadcn MCP | Handshake stdio, 7 herramientas, búsquedas e inspección de `@shadcn/button`, `@react-bits/Ballpit-TS-TW` y `@svgl/github` en fixture temporal |
| `motion-primitives` **0.1.0** | Instalado igual; `--version` y `list` pasan, 33 componentes. No se ejecutó `add` |
| `agent-browser` **0.38.1** | Reutilizado; HTML local, foco visible, activación por teclado, estado final, capturas desktop/móvil y ausencia de overflow horizontal |
| FFmpeg **9.0.1** / ImageMagick **7.1.2-31** | Reutilizados; captura convertida a WebP y clip MP4, originales intactos |
| Skills | Nombres/frontmatter, referencias locales, enlaces y contenido original reutilizado comprobados; pendiente descubrimiento tras recargar Pi |
| fal MCP | Configurado, pero sin token almacenado; ninguna generación ni subida de archivos |

El CLI reconoce los registries públicos por nombre; el MCP necesita las URLs
personalizadas en el `components.json` del proyecto. La prueba usó un fixture en
`/tmp/design-harness-setup.9f2snZ`, no inicializó un proyecto del usuario. Esa ruta
contiene pruebas, resultados y capturas temporales; puede desaparecer al limpiar
`/tmp`. Búsqueda MCP mostró un fallo cosmético upstream: `Add command: [object
Promise]`; usar CLI para obtener comandos/código, no ejecutar ese texto.

El servidor global ejecuta `shadcn mcp` y hereda el directorio de Pi, no una ruta
frontend fija. Abrir Pi desde el proyecto correcto o configurar su `cwd` en un
override de proyecto. React Bits y SVGL siguen siendo configuración por proyecto.

### Pendientes explícitos

1. **Autenticar fal.** El alta OAuth falló con discrepancia de issuer:
   `expected "https://auth.fal.ai", received "https://auth.fal.ai/"`.
   No se desactivó su validación. Alternativa configurada: bearer en almacén seguro
   del adaptador, con confirmación para todas las herramientas de fal.
   Introducir la clave existente en terminal local mediante prompt oculto:

   ```bash
   ~/.pi/agent/npm/node_modules/.bin/pi-mcp-adapter token set fal
   ```

   No pegarla en chat, argumentos ni archivos. Si el almacén del sistema no está
   disponible, detenerse; nunca pasar a texto plano. Tras guardar, verificar
   cuenta/equipo y únicamente búsqueda, schema y precio.
2. **Recargar Pi:** ejecutar `/reload`; esta sesión conserva el catálogo MCP
   anterior. Conectar `shadcn` y `fal` después. El handshake shadcn anterior fue
   prueba directa del servidor, no prueba de conexión del adaptador en esta sesión.
3. **Proyecto real:** acordar destino antes de fusionar registries o añadir
   componentes. Quedan pendientes build/interacción de Ballpit, preview de slides
   y carga GLB cuando exista modelo autorizado. Recuperar código no verifica
   renderizado 3D. No se generó un modelo para cubrir esta prueba.

Para revertir: eliminar únicamente las 13 carpetas nuevas y los 3 enlaces del
recibo; los destinos originales de los enlaces se conservan. Retirar solo
entradas MCP `shadcn`/`fal`, tras comparar con cambios posteriores. Desinstalar
las dos CLIs con `pnpm remove --global shadcn motion-primitives`. Si se guardó
una credencial, retirarla con `pi-mcp-adapter token remove fal` antes de quitar
su configuración. No restaurar una copia completa sobre cambios ajenos.

## Opcionales: requieren petición independiente

| Pieza | Cuándo considerarla | Estado / límite |
| --- | --- | --- |
| [SVGator MCP](https://www.svgator.com/help/svgator-mcp/faq) | Edición SVG visual desde agente | MCP incluido en Free; validar export real: pricing y ayuda discrepan sobre marcas de agua |
| [21st](https://21st.dev/mcp) | Más referencias/componentes | Solo cuota gratuita; sin generación que requiera compra de créditos |
| [MotionSites](https://motionsites.ai/mcp) | Referencias de prompts | Acceso gratuito muy limitado, no dependencia del harness |

Descartadas como fuentes en este setup: Kenney, Quaternius, Poly Haven y
ambientCG, porque aquí no se ha validado un CLI/MCP gratuito adecuado; sus webs
o APIs HTTP no satisfacen el criterio. Lucide deja de ser fuente independiente,
aunque un componente puede necesitar su paquete como dependencia.

Fuera del núcleo: Blender (no necesario para integrar assets web), Triplex
(sin CLI/MCP validado para este flujo), Spline (exportación limitada y MCP desktop
sin Linux), Meshy API (plan gratuito sin API), Motion+ y cualquier servicio que
exija nuevos pagos. Reevaluar solo con conector, condiciones y utilidad concretos.
