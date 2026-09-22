# Extensiones y skills de Pi — evaluación acumulada

Documento vivo: cada vez que se revisa un repo/config externo buscando
extensiones o skills de Pi que valgan la pena, se añade aquí. No es el
reporte cerrado de un solo repo — es un registro que se va iterando a medida
que aparecen fuentes nuevas.

## Método

- Se lee el código fuente completo de cada pieza candidata (no solo el
  README).
- Se compara contra lo ya **nativo** en esta instalación de Pi
  (`ask_user_question`, `web_search`, `fetch_content`, automatización de
  browser vía skills, `pi_messenger`/Crew) y contra lo ya adoptado en este
  mismo documento.
- Verificación en vivo cuando aplica (ej. probar `fetch_content` contra una
  página real antes de descartar un fetcher alternativo por redundante).
- Cuando la pieza tiene ficha en [skills.sh](https://www.skills.sh), se revisan
  sus auditorías automáticas (Gen Agent Trust Hub, Socket, Snyk) como señal
  adicional — sobre todo Snyk, que detecta patrones de riesgo en el
  *comportamiento* del skill (manejo de credenciales, exposición a contenido
  de terceros), no solo en sus dependencias.

## Fuentes evaluadas

| Fecha | Fuente | Contenido revisado |
| --- | --- | --- |
| 2026-09-02 | [amosblomqvist/pi-config](https://github.com/amosblomqvist/pi-config) | 8 extensiones, 4 skills, + 2 repos satélite ([pi-interactive-subagents](https://github.com/amosblomqvist/pi-interactive-subagents), [pi-observational-memory](https://github.com/amosblomqvist/pi-observational-memory)) |
| 2026-09-02 | [elpapi42/pi-observational-memory](https://github.com/elpapi42/pi-observational-memory) | Implementación alternativa de memoria observacional (V3, npm `pi-observational-memory@3.0.4`), comparada contra la de amosblomqvist |
| 2026-09-02 | [@juicesharp/rpiv-web-tools](https://www.npmjs.com/package/@juicesharp/rpiv-web-tools) (npm, v2.9.0) | Extensión standalone de `web_search` + `web_fetch`, comparada contra el tooling nativo |
| 2026-09-07 | Auditoría del setup local (`pi-extension-manager.json`) + 6 candidatas sugeridas | 3 extensiones ya instaladas confirmadas (ponytail, `rpiv-ask-user-question`, `pi-web-access`) + `pi-opencode`, `better-claude-code-ui`, `pi-simplify`, `@narumitw/pi-plan-mode`, `@tintinweb/pi-subagents`, `pi-hermes-memory` |

*(añadir una fila por cada fuente nueva que se revise)*

## Veredicto acumulado

**Adoptadas / cópialas:**

- `bash-guard` — de amosblomqvist/pi-config
- `prompt-snippets` — de amosblomqvist/pi-config
- `analyze-sessions` (skill) — de amosblomqvist/pi-config — **con precaución**, ver auditoría Snyk en el detalle

**Descartadas — ya cubierto por lo nativo:**

- `web-search` — de amosblomqvist/pi-config
- `web-fetch` — de amosblomqvist/pi-config
- `ask-user-question.ts` — de amosblomqvist/pi-config
- `custom-header.ts` — de amosblomqvist/pi-config
- `rpiv-web-tools` — npm `@juicesharp/rpiv-web-tools`

**Evaluar según flujo real, no copiar a ciegas:**

- `browser/` — de amosblomqvist/pi-config
- `pi-interactive-subagents` — repo satélite de amosblomqvist
- `pi-observational-memory` (elpapi42, V3) — recomendada **por encima** de la versión de amosblomqvist, ver detalle
- `pdf-reader`, `web-debug`, `youtube-transcript` (skills) — de amosblomqvist/pi-config

**Reemplazadas por una alternativa mejor:**

- `pi-observational-memory` (amosblomqvist) — reemplazada por `pi-observational-memory` (elpapi42, V3); ver comparación en detalle

**Ya instaladas (confirmado en `pi-extension-manager.json`):**

- `@dietrichgebert/ponytail` (pi-extension) — activa ahora mismo
- `@juicesharp/rpiv-ask-user-question` — provee el `ask_user_question` nativo
- `pi-web-access` (nicobailon) — provee `web_search`/`fetch_content` nativos

**Recomendada:**

- `@narumitw/pi-plan-mode` — modo `/plan` de solo lectura estilo Codex; no es solo un comando, cambia el flujo real de proponer plan antes de tocar archivos

**Interesante pero no esencial, según necesidad concreta:**

- `pi-opencode` (es `awtotty`, no `autotty`) — solo si usas créditos de OpenCode Zen/Go
- `better-claude-code-ui` — puramente cosmético (temas + UI estilo Claude Code)
- `pi-simplify` — revisor de código post-hoc; solapa en espíritu con lo que ya cubre ponytail

**Muy interesante, evaluar a fondo:**

- `pi-hermes-memory` — memoria estilo Hermes/CLAUDE.md con SQLite FTS5; ver comparación con Engram en el detalle

**Descartada — ya hay alternativa mejor identificada:**

- `@tintinweb/pi-subagents` — ver `docs/agents/pi-subagents-workflows-comparison.md`

**Ignorar:**

- `deprecated/` de amosblomqvist/pi-config — el propio autor ya lo descartó

## Comparativa detallada

| Pieza | Fuente | Tipo | Veredicto | Motivo principal |
| --- | --- | --- | --- | --- |
| `bash-guard` | amosblomqvist/pi-config | Extensión | **Copiar** | Intercepta comandos destructivos con parseo real de shell; nada nativo lo cubre |
| `analyze-sessions` | amosblomqvist/pi-config | Skill | **Copiar (con precaución)** | Stdlib-only, sin dependencias, info que no hay en ningún otro lado; Snyk marca riesgo de exposición de credenciales y prompt injection indirecta (ver detalle) |
| `prompt-snippets` | amosblomqvist/pi-config | Extensión | **Copiar** | Barato, cero solape con nada nativo |
| `web-search` | amosblomqvist/pi-config | Extensión | Descartar | Requiere Google CSE de pago; el `web_search` nativo ya cubre Google vía otros proveedores, mejor mantenido |
| `web-fetch` | amosblomqvist/pi-config | Extensión | Descartar | `fetch_content` nativo ya maneja PDF y páginas Next.js/RSC (verificado en vivo) |
| `ask-user-question.ts` | amosblomqvist/pi-config | Extensión | Descartar | Clon funcional del tool nativo `ask_user_question` |
| `custom-header.ts` | amosblomqvist/pi-config | Extensión | Descartar | Puramente cosmético |
| `browser/` | amosblomqvist/pi-config | Extensión | Evaluar | Solapa con skill de browser ya instalada; solo si esa no cubre debugging de SPA en vivo |
| `pi-interactive-subagents` | amosblomqvist (repo propio) | Extensión (repo externo) | Evaluar | Requiere tmux (solo lado Linux); UX distinta a Crew, no funcionalidad ausente |
| `pi-observational-memory` | amosblomqvist (repo propio) | Extensión (repo externo) | **Reemplazada** | Ver `pi-observational-memory` (elpapi42) — arquitectura más madura para el mismo problema |
| `pi-observational-memory` (V3) | elpapi42 (repo propio) | Extensión (repo externo) | Evaluar (recomendada sobre la de amosblomqvist) | Nested-agent en proceso (no subprocesos `pi`), usa credenciales/OAuth de la sesión, hooks nativos de Pi (`agent_settled`, `session_before_compact`), versionada (3.0.4), 25+ tests, CI + npm publish |
| `pdf-reader`, `web-debug`, `youtube-transcript` | amosblomqvist/pi-config | Skills | Evaluar | Correctas y simples, pero atadas a herramientas de sistema (venv, yt-dlp, ffmpeg); solo si se usan seguido |
| `deprecated/` | amosblomqvist/pi-config | — | Ignorar | El autor ya hizo la poda |
| `rpiv-web-tools` | npm `@juicesharp/rpiv-web-tools` | Extensión | Descartar | Nativo ya cubre más backends (25 vs 10) + síntesis IA con citas + GitHub URLs; única ventaja no verificada es el guard SSRF explícito de su `web_fetch` |
| `@dietrichgebert/ponytail` | git:DietrichGebert/ponytail | Extensión | Ya instalada | Activa ahora mismo, rige el comportamiento de toda la sesión |
| `@juicesharp/rpiv-ask-user-question` | npm | Extensión | Ya instalada | Provee el `ask_user_question` nativo |
| `pi-web-access` | npm (nicobailon) | Extensión | Ya instalada | Provee `web_search`/`fetch_content` nativos |
| `@narumitw/pi-plan-mode` | npm, v0.56.0 | Extensión | **Recomendada** | Modo `/plan` de solo lectura estilo Codex; flujo real, no un simple comando |
| `pi-opencode` (awtotty) | GitHub | Extensión (provider) | Interesante, no esencial | Solo registra modelos de OpenCode Zen/Go; equivalente a escribirlo a mano en `models.json` |
| `better-claude-code-ui` | npm, v0.1.7 | Extensión + tema | Interesante, no esencial | Puramente cosmético: 6 temas Claude Code + UI |
| `pi-simplify` | npm, v0.2.3 | Extensión | Interesante, no esencial | Revisor post-hoc de claridad/mantenibilidad; solapa con ponytail |
| `@tintinweb/pi-subagents` | GitHub | Extensión | Descartar | Ya evaluada en `pi-subagents-workflows-comparison.md`: mejor UX, peor mantenimiento (69 issues) |
| `pi-hermes-memory` | npm, v0.9.8 | Extensión | Evaluar a fondo | Memoria estilo Hermes + secret scanning + SQLite FTS5; comparar con Engram |

## Detalle por pieza

### `bash-guard` — copiar

*Fuente: amosblomqvist/pi-config*

Intercepta el tool `bash` y aplica protección distinta según el contexto:

- **Sesión principal**: parsea el comando con `shell-quote` (no regex ingenuo) y
  detecta patrones de riesgo (`rm -rf`, `sudo`, `git push --force`, `dd of=`,
  herramientas de disco como `diskutil`/`mkfs`/`parted`, pipe-a-shell, etc.).
  Muestra un diálogo Run/Abort y recuerda comandos abortados 60s para evitar
  reintentos.
- **Subagente headless** (`PI_SUBAGENT_DEPTH >= 1`): sin UI posible, así que
  hace hard-block silencioso de un set reducido de patrones catastróficos.
- Toggle `/bash-guard` para modo autónomo, con un "suelo" de bloqueo que sigue
  activo incluso desactivado.

**Caveat**: los patrones son POSIX (bash/zsh). En PowerShell no detecta
`Remove-Item -Recurse -Force` ni equivalentes — protege tal cual solo en el
lado Linux, salvo que se extiendan los regex para PowerShell.

### `web-search` — descartar

*Fuente: amosblomqvist/pi-config*

El diferenciador real no es "soporte de Google" (el `web_search` nativo
también llega a resultados tipo-Google vía otros proveedores) sino la
**composición estructurada de la query** (`exactPhrases[]`, `excludeTerms[]`,
`site`) como parámetros tipados en vez de un string libre. Aun así, sigue
atada a la API de pago de Google Custom Search (100 queries/día gratis) y el
`web_search` nativo es multi-proveedor, mejor mantenido y con más soporte.

### `web-fetch` — descartar

*Fuente: amosblomqvist/pi-config*

Hace `fetch(url)` → Readability + Turndown → markdown limpio, con extracción
de PDF (`unpdf`), fallback a Jina Reader para páginas JS-rendered, y un parser
manual de payloads RSC de Next.js (`self.__next_f.push`) para sacar contenido
de apps donde Readability falla. Se probó `fetch_content` (nativo) contra una
página real de Next.js App Router con RSC y devolvió markdown limpio y
correcto sin necesidad de ningún parser especial — el caso que la extensión
resuelve a mano ya está cubierto nativamente.

### `ask-user-question.ts` — descartar

*Fuente: amosblomqvist/pi-config*

UI bien hecha (opción "Other", multi-select, lock compartido entre popups),
pero es funcionalmente un clon del tool nativo `ask_user_question`.

### `custom-header.ts` — descartar

*Fuente: amosblomqvist/pi-config*

Solo cambia el logo ASCII de arranque. Cero funcionalidad.

### `prompt-snippets` — copiar

*Fuente: amosblomqvist/pi-config*

Reglas de prompt reutilizables como archivos markdown con frontmatter
(`name`, `placement: prepend|append`, `order`), activables/desactivables por
mensaje con `alt+s` o `/snippets`. Se insertan en el mensaje al enviarlo y el
toggle se resetea solo. Sin dependencias, un archivo + carpeta de `.md`; fácil
de adoptar y de tirar si no se usa.

### `browser/` — evaluar

*Fuente: amosblomqvist/pi-config*

Playwright headless bien construido: cola de serialización para evitar race
conditions entre `browser_*` en el mismo batch, off-by-default (ahorra ~800
tokens de system prompt hasta `/browser on`), perfil persistente (cookies,
localStorage) para no repetir login/2FA entre turnos. El skill que lo
acompaña (`web-debug`, playbooks por síntoma: login roto, 401/403/CORS, JWT,
formulario que no envía, pantalla en blanco) es el mejor argumento a favor.
Solapa con la skill de browser ya instalada en este setup — solo copiar si
esa no cubre bien el debugging de SPA en vivo (localStorage, headers de red,
decodificar JWT).

### `pi-interactive-subagents` — evaluar

*Fuente: repo satélite de amosblomqvist, referenciado desde pi-config*

Fork de `HazAT/pi-interactive-subagents` recortado a **solo tmux** (el
upstream soporta también cmux/zellij/WezTerm).

- `subagent()` lanza un sub-agente en un split de tmux, no bloquea, widget en
  vivo con estado (`active`/`waiting`/tiempo).
- `subagent_message` direcciona por nombre: si sigue vivo escribe en el pane,
  si terminó resume la sesión con el mensaje como nueva tarea.
- `ask_question`: el sub-agente puede preguntarle al orquestador y quedar en
  pausa (`waiting`) en vez de morir.
- Sandboxing serio en el resume: congela un `loadout.json` (allowlist de
  tools, modelo, thinking level, system prompt, permisos de spawn, cwd) al
  spawnear, y el resume reconstruye exactamente ese proceso restringido.
- 3 agentes bundle (`scout`, `researcher`, `worker`) corriendo
  `openrouter/z-ai/glm-5.3` por defecto — coste distinto al de la sesión
  principal.
- Tiene tests de integración reales (`test/integration/*.test.ts`).

**Caveat**: requiere tmux — solo viable en el lado Linux de este dotfiles, o
vía WSL2 en Windows. Solapa conceptualmente con `pi_messenger`/Crew (ya
disponible), pero es una UX distinta: paneles visibles y "steereables" en
vivo, en vez de una cola de tareas headless con DAG.

### `pi-observational-memory` — evaluar

*Fuente: repo satélite de amosblomqvist, referenciado desde pi-config*

El más ambicioso y el más caro de adoptar. Pipeline de 3 tiers:

```text
chunks crudos → observers (subprocesos pi headless, paralelos) → observaciones
  → ledger branch-local (correcto bajo /tree) → compaction determinista (sin modelo)
  → consolidator (subproceso pi) → .memory/<sessionId>/<topic>.md + INDEX.md + JOURNEY.md
```

- Ledger por branch (no lo corrompe `/tree`).
- Compaction determinista y model-free (no le pide a un LLM que resuma).
- Consolidator poda observaciones viejas a archivos `.memory/` durables y
  grep-ables por tema, más un `JOURNEY.md` narrativo que se comprime
  progresivamente.
- Trackea coste real (`usage.cost.total` de cada subproceso) en el footer.
- Suite de tests con vitest (11 archivos), `PLAN.md`, tipado estricto.

**Caveat importante**: cada observer y cada consolidator es un **subproceso
`pi` completo** — gasta tokens y dinero además de la sesión principal. Config
con 7+ knobs a calibrar por proyecto. El propio README lo marca apagado por
defecto — el autor lo trata como early/beta.

Vale la pena solo si la compactación nativa de Pi hace perder contexto
importante en sesiones largas y se necesita memoria persistente por tema,
grep-able, entre sesiones/forks. Si la compactación nativa basta, es
complejidad y coste sin beneficio claro.

**Reemplazada por**: `pi-observational-memory` (elpapi42, V3) — ver detalle
abajo. Resuelve el mismo problema con una arquitectura más madura y sin el
coste de spawnear subprocesos `pi` completos.

### `pi-observational-memory` (elpapi42, V3) — evaluar, recomendada sobre la de amosblomqvist

*Fuente: [elpapi42/pi-observational-memory](https://github.com/elpapi42/pi-observational-memory)*

Mismo problema (compactación que resume una compactación de una
compactación, perdiendo matices con cada ciclo), arquitectura distinta y, en
la lectura de código, más madura:

- **Observaciones** (eventos puntuales con timestamp y relevancia
  `low/medium/high/critical`) → **reflexiones** (hechos durables destilados,
  con `supportingObservationIds` explícitos para trazabilidad) → **dropper**
  (poda observaciones ya cubiertas por reflexiones, con niveles de cobertura
  `none/partial/strong` como evidencia para el modelo, no como regla
  automática).
- El ledger es branch-local y es la única fuente de verdad; la compactación
  (`session_before_compact`) es puramente determinista y model-free — no
  llama a ningún modelo, no espera a los workers de fondo, solo pliega el
  ledger ya existente. Si la proyección está vacía, delega en el
  compactador nativo de Pi en vez de escribir un resumen vacío.
- **Sin subprocesos**: observer/reflector/dropper corren como `agentLoop` de
  `@earendil-works/pi-agent-core` **dentro del mismo proceso**, no como un
  `pi` completo spawneado aparte (a diferencia de la versión de
  amosblomqvist). Menos overhead, coste directamente atribuible en el
  `usage.cost` de la sesión.
- **No requiere configurar modelo ni API key aparte**: por defecto usa el
  modelo de la sesión actual, y acepta tanto API key como headers
  OAuth-style — proveedores autenticados por OAuth funcionan sin key
  separada. Esto es una ventaja práctica real frente a la versión de
  amosblomqvist, que exige configurar un modelo/credencial propios para el
  observer y el consolidator.
- Tool `recall` expuesto al agente para recuperar la evidencia fuente exacta
  detrás de un id de observación/reflexión, con distinción explícita entre
  "progress watermark" (`coversUpToId`) y "provenance" (`sourceEntryIds` /
  `supportingObservationIds") — diseño cuidadoso para no confundir ambos
  conceptos.
- Integrado con los hooks nativos de Pi (`turn_end`, `agent_settled`,
  `session_before_compact`), en vez de reimplementar el ciclo de
  compactación por fuera.
- Señales de madurez claras: versión semver real (**3.0.4**, ya en su
  tercera iteración mayor de diseño con tabla de migración V2→V3), 25+
  archivos de test (incluyendo `oauth-end-to-end.test.ts` y
  `ambient-credential-auth.test.ts`), CI (`ci.yml` + `npm-publish.yml`),
  documentación separada en `concepts.md` / `how-it-works.md` /
  `configuration.md`. Se instala como paquete npm publicado
  (`pi install npm:pi-observational-memory`), no como carpeta en desarrollo.

**Trade-off frente a la versión de amosblomqvist**: no genera archivos
`.memory/<sesión>/<tema>.md` legibles y grep-ables fuera del ledger — todo
vive dentro del ledger de la sesión (JSONL), inspeccionable solo vía
`/om:view` o el tool `recall`. Si lo que se busca es un directorio de notas
en markdown que se pueda abrir directamente en un editor, la versión de
amosblomqvist cubre ese caso concreto mejor; para todo lo demás (coste,
mantenimiento, integración con Pi, madurez), esta gana.

Sigue sin ser gratis: observer/reflector/dropper consumen tokens reales en
cada ciclo, solo que sin el overhead de un proceso `pi` aparte. Vale la pena
evaluarla si la compactación nativa pierde contexto importante en sesiones
largas; si no, sigue siendo complejidad sin beneficio claro.

### `analyze-sessions` (skill) — copiar, con precaución

*Fuente: amosblomqvist/pi-config*

Scripts Python stdlib-only sobre `~/.pi/agent/sessions/*.jsonl`: coste por
proyecto/modelo/día, minería de patrones de prompting, búsqueda en
transcripts, render de una sesión concreta. Sin dependencias, sin red. Útil
de inmediato si se usa Pi a diario: qué proyectos consumen más tokens, qué
patrones repetir en AGENTS.md, dónde falló el agente.

**Snyk marca riesgo (verificado leyendo el código, no es falso positivo)**:
los scripts vuelcan transcripciones crudas tal cual — si una sesión vieja
tenía un secreto pegado, sale verbatim. Es un efecto secundario de lo que la
herramienta hace por diseño, no un bug ni cadena de suministro comprometida
(Socket pasa limpio). Precaución práctica: no asumas que el output está
limpio si sospechas que alguna sesión antigua tenía secretos.

Instalada con `npx skills add https://github.com/amosblomqvist/pi-config
--skill analyze-sessions --global --agent pi --yes` → `~/.pi/agent/skills/analyze-sessions/`.

### `pdf-reader`, `web-debug`, `youtube-transcript` (skills) — evaluar

*Fuente: amosblomqvist/pi-config*

Correctas y simples, pero atadas a herramientas de sistema (`yt-dlp`,
`ffmpeg`, venv de Python para `pdf-reader`). No inventan nada que no se pueda
montar en 10 minutos; solo merece la pena copiarlos si se usan seguido
(lectura de PDFs académicos, transcripción de YouTube, debugging de SPA con
el playbook de `browser/`).

### `deprecated/` — ignorar

*Fuente: amosblomqvist/pi-config*

Extensiones y skills del setup de dos meses del autor, ya descartadas por él
mismo ("didn't earn their place"). Referencia histórica, nada que evaluar.

### `rpiv-web-tools` — descartar

*Fuente: [@juicesharp/rpiv-web-tools](https://www.npmjs.com/package/@juicesharp/rpiv-web-tools) (npm, v2.9.0)*

Extensión standalone (no atada a un repo de dotfiles) que añade `web_search` +
`web_fetch` con 10 backends seleccionables (Brave, Tavily, Serper, Exa,
You.com, Jina, Firecrawl, Perplexity, SearXNG, Ollama) vía comando
`/web-tools`, incluyendo rutas self-hosted (SearXNG, Ollama) para que las
queries no salgan de la red local.

**Señales de mantenimiento excelentes**: v2.9.0, más de 120 releases desde
abril de 2026, última publicación el 2026-09-01 (ayer) — cadencia de
desarrollo muy alta, forma parte de un monorepo (`rpiv-mono`) con un paquete
paraguas (`@juicesharp/rpiv-pi`) que incluye un agente `web-search-researcher`.

**Por qué se descarta frente al tooling nativo**:

- El `web_search` nativo ya cubre más backends (~25, incluyendo `searxng` y
  `ollama` — los dos self-hosted que rpiv destaca como diferenciador) y
  además hace síntesis de respuesta con citas y curación interactiva; rpiv
  solo devuelve título/URL/snippet crudos por resultado, sin síntesis.
- El interceptor de URLs de GitHub de rpiv (opt-in, convierte un link de
  github.com en árbol de archivos/README vía shallow clone) es exactamente lo
  que `fetch_content` ya hace automáticamente y sin flag — se comprobó en
  vivo varias veces en este mismo documento.
- El truncado de páginas grandes a un archivo temporal legible bajo demanda
  es equivalente a la paginación que ya ofrece `get_search_content`.

**Única ventaja no verificada**: `web_fetch` de rpiv rechaza explícitamente
protocolos que no sean http(s) y direcciones privadas/loopback/metadata (guard
anti-SSRF documentado en su README). No se ha confirmado si `fetch_content`
nativo tiene la misma protección — si algo importa aquí es justamente ese
detalle de seguridad, no la funcionalidad de búsqueda/fetch en sí, que ya
está cubierta y superada por lo nativo.

### `@dietrichgebert/ponytail` (pi-extension) — ya instalada

*Fuente: git `github.com/DietrichGebert/ponytail`*

Es la contraparte en extensión del skill ponytail (ya activo en esta sesión). No
hace falta evaluarla en abstracto: está rigiendo el comportamiento completo de
esta conversación ahora mismo.

### `@juicesharp/rpiv-ask-user-question` — ya instalada

*Fuente: npm `@juicesharp/rpiv-ask-user-question`*

Provee el tool `ask_user_question` usado toda la sesión (cuestionario
estructurado con opciones tipadas en vez de respuesta libre). Ya cubre la
necesidad; nada que añadir.

### `pi-web-access` (nicobailon) — ya instalada

*Fuente: npm `pi-web-access`*

Provee `web_search` y `fetch_content` nativos. Es el mismo paquete contra el
que se compararon y descartaron `web-search`/`web-fetch` de amosblomqvist y
`rpiv-web-tools` de juicesharp más arriba — confirma que esas comparaciones
eran válidas: no había un "nativo genérico" abstracto, era literalmente este
paquete.

### `@narumitw/pi-plan-mode` — recomendada

*Fuente: npm `@narumitw/pi-plan-mode`, v0.56.0*

Añade un modo `/plan` de solo lectura estilo Codex: el agente propone un plan
antes de tocar archivos, en vez de lanzarse a editar directamente. No es solo
un comando de UI — cambia el flujo de trabajo real (fase de planificación
explícita, separada de la ejecución). Nicho pero legítimo si ese flujo
plan-primero-ejecución-después es lo que buscas.

### `pi-opencode` (awtotty) — interesante, no esencial

*Fuente: GitHub `awtotty/pi-opencode` (el nombre correcto es `awtotty`, no
`autotty`)*

Registra 4 `pi.registerProvider()` apuntando a los endpoints Zen/Go de
OpenCode (~30 modelos, incluyendo GLM/Kimi/Qwen/MiniMax abiertos). Verificado
en código: no añade tools ni comportamiento, solo un catálogo de modelos —
exactamente lo mismo que se puede escribir a mano en `~/.pi/agent/models.json`
(y a mano se puede rellenar el `cost` real, que la extensión deja en `0`
para los 30 modelos). Solo vale la pena si no quieres teclear el catálogo tu
mismo o si usas créditos Zen/Go activamente.

### `better-claude-code-ui` — interesante, no esencial

*Fuente: npm `better-claude-code-ui`, v0.1.7 (repo `Demo-0416/my-pi-extensions`)*

Puramente cosmético: 6 temas (`claude-code-dark[-ansi|-daltonized]`,
`claude-code-light[-ansi|-daltonized]`) + welcome box, status line, spinner y
renderizado de tools al estilo Claude Code. Confirmado 1:1 contra la carpeta
`theme/` del repo. Cuestión de gusto visual, no de funcionalidad.

### `pi-simplify` — interesante, no esencial

*Fuente: npm `pi-simplify`, v0.2.3 (repo `MattDevy/pi-extensions`)*

Revisa el código recién cambiado buscando claridad, consistencia y
mantenibilidad — un revisor post-hoc, reactivo. Solapa en espíritu con
ponytail (que ya está activo y es proactivo, previene el problema en vez de
señalarlo después). Redundante mientras ponytail siga activo.

### `@tintinweb/pi-subagents` — descartar

*Fuente: GitHub `tintinweb/pi-subagents`*

Ya evaluada a fondo en `docs/agents/pi-subagents-workflows-comparison.md`: mejor UX
visual estilo Claude Code (FleetView, `@agent`, sesiones reanudables), pero
peor señal de mantenimiento (69 issues abiertos frente a 4 de
`nicobailon/pi-subagents`). Sin motivo para preferirla habiendo una
alternativa mejor mantenida ya identificada.

### `pi-hermes-memory` — evaluar a fondo

*Fuente: npm `pi-hermes-memory`, v0.9.8 (repo `chandra447/pi-hermes-memory`,
"ported from Hermes agent")*

Memoria persistente + búsqueda de sesiones + secret scanning explícito — el
mismo punto débil que Snyk señaló en `analyze-sessions`, pero atacado de
frente aquí en vez de ignorado. SQLite FTS5 para búsqueda de texto completo,
auto-consolidación, memorias categorizadas (fallos, correcciones, insights),
~700 tests, actualizada hace días.

La filosofía es la misma que memoria basada en markdown (el `.memory/*.md` de
amosblomqvist/elpapi42, o el `CLAUDE.md`/`memory.markdown` de Claude): anotar
hechos destilados de la conversación para que sobrevivan a la compactación.
La diferencia es el almacenamiento — SQLite indexado en vez de archivos
markdown sueltos — lo que cambia búsqueda (FTS5 real vs grep) y rendimiento a
escala, no la filosofía de fondo.

**Comparación con Engram** (`gentle-engram`/`pi-engram`, verificado): mismo
enfoque SQLite+FTS5, pero Engram es un **binario Go agnóstico de agente** (un
servicio local expuesto por CLI/HTTP/MCP/TUI que sirve tanto a Pi como a
Claude Code, Cursor, Codex, etc., con sync opcional a la nube), mientras que
`pi-hermes-memory` es una extensión TypeScript nativa de Pi, en proceso, sin
servicio aparte. Trade-off: Engram gana si quieres **una sola memoria
compartida entre varios agentes distintos** (no solo Pi); `pi-hermes-memory`
gana en simplicidad de instalación (sin binario aparte que gestionar) si solo
usas Pi. Ambos evitan deliberadamente la memoria vectorial/embeddings — la
crítica compartida es que los sistemas vectoriales tienden a acumular
demasiado contenido de baja señal que después no se recupera útilmente; FTS5
léxico sobre hechos ya destilados es más barato y más predecible.

**El problema de fondo (compartido por toda memoria basada en juicio de LLM)**:
en última instancia es el modelo quien decide qué merece guardarse, y eso es
no-determinista en ambas direcciones — puede guardar basura/ruido de baja
señal que después contamina el contexto (el miedo real al adoptar cualquiera
de estos plugins), o puede no guardar algo crítico justo cuando importaba.
No es un defecto de implementación específico de un proyecto, es inherente a
delegar la decisión de "qué es memoria útil" a un LLM.

Mitigaciones encontradas, comparadas:

- **Engram**: el guardado pasivo pasa por un parser que solo persiste
  "structured learnings reconocidos" (decisiones de arquitectura, root-causes,
  preferencias, handoffs) — "raw or general tool output is not saved as an
  observation". El guardado activo (`mem_save`) sigue siendo discreción del
  modelo. Para excluir contenido hay un convenio manual `<private>...</private>`;
  el propio README avisa que **no** es un sistema de secret-scanning real:
  "a lightweight convenience convention, not a full secret-scanning system".
- **pi-hermes-memory**: reconoce el problema explícitamente en su propio
  README — *"Recall is probabilistic. [...] for a prohibition, that is
  exactly the moment it has no reason to look"* — y responde con **Standing
  Instructions** (`/memory-pin`): un archivo pequeño editado solo por el
  usuario (nunca por el agente — "the agent cannot promote its own memory
  into this block"), inyectado en **cada** sesión sin depender de que el
  modelo decida buscar. Además tiene dos disparadores no discrecionales que
  Engram no tiene: detección de correcciones (guarda de inmediato cuando el
  usuario corrige al agente, sin que el modelo "decida") y un content
  scanner determinista en cada escritura (bloquea API keys/tokens/SSH keys,
  y protege contra que una inyección de prompt convenza al modelo de guardar
  contenido malicioso que resurja luego por búsqueda).

**Conclusión**: el miedo a "acabar guardando basura que contamina el
contexto" es válido para cualquier memoria de este tipo, incluida la nativa
de Claude (`CLAUDE.md`/memory tool, que no documenta ningún filtro o
scanner equivalente sobre lo que el modelo decide escribir). De los tres,
`pi-hermes-memory` es el que mejor lo ha pensado: no elimina el riesgo de
fondo, pero da la salida correcta — no confiar el recall probabilístico para
lo que no puede fallar, y fijarlo a mano en Standing Instructions en su
lugar. Eso sube la confianza para probarla por encima de un simple
"evaluar".

Pendiente: instalar y probar en un proyecto real antes de mover esto a
"copiar".

## Cómo añadir una fuente nueva

Al revisar un repo/config externo distinto:

1. Añadir una fila en "Fuentes evaluadas" con fecha, link y qué se revisó.
2. Clasificar cada pieza nueva en el veredicto acumulado (adoptar / descartar
   / evaluar / ignorar).
3. Añadir su fila en la comparativa detallada, con la columna "Fuente".
4. Añadir su sección de detalle bajo el encabezado correspondiente.
5. Si una pieza nueva compite con una ya adoptada, no borrar la vieja
   entrada: marcarla como "Reemplazada por `<pieza-nueva>` (ver fuente X)" y
   explicar por qué gana la nueva.

## Recomendación acumulada (instalación mínima hasta ahora)

```bash
cp -r extensions/bash-guard ~/.pi/agent/extensions/
cp -r extensions/prompt-snippets ~/.pi/agent/extensions/
cp -r skills/analyze-sessions ~/.pi/agent/skills/
```

(rutas relativas a la fuente de cada pieza — ver tabla de fuentes arriba)

El resto de piezas marcadas "Evaluar" solo se copian si aparece una necesidad
concreta que las herramientas nativas de esta instalación de Pi no cubran ya.
