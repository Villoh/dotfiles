# Comparativa de extensiones Pi: subagents y workflows

Fecha: 2026-08-17

## Alcance y método

Se clonaron los nueve repositorios con `git clone --depth 1` en:

```text
C:\Users\mikel\AppData\Roaming\Temp\pi-workflow-comparison
```

Se revisaron README, `package.json`, arquitectura fuente, persistencia, aislamiento, pruebas y workflows de CI. No se ejecutaron pruebas que requirieran acceso a modelos, credenciales o servicios externos.

Entorno local:

- Windows
- Pi `0.84.2`
- Node `22.22.2`
- pnpm `11.22.0`
- Bun `1.3.14`

## Veredicto

### Mejor extensión de subagents

**[`nicobailon/pi-subagents`](https://github.com/nicobailon/pi-subagents)**

Es la opción más equilibrada para delegación general:

- agentes integrados `scout`, `worker`, `reviewer`, `oracle` y `researcher`;
- foreground/background, steering y espera durable;
- workflows JavaScript con `runs.run()` y `runs.all()`;
- worktrees, artifacts, sesiones, límites de profundidad y spawn budgets;
- canal de supervisor para que un hijo pida decisiones al padre;
- CI explícita en Ubuntu y Windows;
- MIT, versión publicada `0.50.0`.

La implementación principal está en `src/extension/index.ts`; el grafo y los estados de workflow están en `src/runs/shared/workflow-graph.ts`.

### Mejor workflow práctico para usar hoy

**[`vekexasia/pi-extensible-workflows`](https://github.com/vekexasia/pi-extensible-workflows)**

Es la mejor elección general si se prioriza estabilidad operativa sobre seguridad avanzada:

- `parallel`, `pipeline` y composición determinista;
- journal de resultados y recuperación sin repetir fases completadas;
- checkpoints y aprobación humana;
- budgets de tokens, coste y tiempo;
- worktrees y políticas de agentes compartidas;
- companion `@piewf/subagents` dentro del mismo ecosistema;
- CLI, roles y extensibilidad.

El runtime está separado en `packages/core/src/runtime/`; la persistencia está en `packages/core/src/persistence.ts` y `store.ts`.

Advertencia para Windows: el código de runtime contempla Windows, pero algunos scripts de desarrollo/test del repositorio dependen de shell POSIX (`rm`, `find`, `xargs`, `env -u`). El paquete publicado debería ser más sencillo de usar que el checkout de desarrollo.

### Mejor diseño técnico de workflow

**[`heggria/taskflow`](https://github.com/heggria/taskflow)**

Después de revisar el código, supera a las demás en verificabilidad, trazabilidad y control de mutaciones:

- DAG declarativo JSON o `.tf.ts`;
- 12 tipos de fase: `agent`, `parallel`, `map`, `reduce`, `gate`, `approval`, `flow`, `loop`, `tournament`, `script`, `race` y `expand`;
- validación estática, FlowIR y hashes de definición;
- budgets, retries, timeouts, caché y recompute incremental;
- trace y replay offline sin tokens;
- aislamiento `temp`, `dedicated` y `worktree`;
- Trusted Effects con snapshots, leases, intents, staging, commit y restore;
- adapter oficial para Pi (`pi-taskflow`) y adapters para otros hosts;
- CI con pruebas específicas en `windows-latest`;
- core con cero dependencias runtime, aparte de TypeBox.

La lógica central está en `packages/taskflow-core/src/runtime.ts`, `store.ts`, `workspace.ts` y `resources/file-transaction.ts`. El adapter Pi está en `packages/pi-taskflow/src/index.ts` y utiliza `/tf` y la herramienta `taskflow`, por lo que no compite directamente con `/workflow`.

La desventaja es importante: la rama revisada es `0.3.0-beta.1`. Trusted Effects declara explícitamente que **no es un sandbox del sistema operativo**; las escrituras no declaradas siguen dependiendo de la política del host. Es el ganador técnico, pero no necesariamente el mejor primer paquete para una configuración sencilla.

El paquete beta está publicado como `pi-taskflow@0.3.0-beta.1`; `latest` sigue siendo `0.2.10`.

## Comparativa resumida

| Proyecto | Modelo | Lo mejor | Coste o riesgo | Windows |
| --- | --- | --- | --- | --- |
| [`nicobailon/pi-subagents`](https://github.com/nicobailon/pi-subagents) | Subagents + workflows JS | Delegación completa, madurez, artifacts, worktrees y buen control | Amplio; puede ser más de lo necesario | **Buena**: CI Windows |
| [`tintinweb/pi-subagents`](https://github.com/tintinweb/pi-subagents) | Subagents estilo Claude Code | FleetView, `@agent`, memoria, scheduling y steering | Mayor superficie; 69 issues abiertos en la consulta | Código con soporte; CI solo Linux |
| [`vekexasia/pi-extensible-workflows`](https://github.com/vekexasia/pi-extensible-workflows) | Workflows JS deterministas | Durabilidad, gates, budgets, replay y extensibilidad | Scripts de desarrollo POSIX; ecosistema reciente | Runtime razonable; validar instalación nativa |
| [`heggria/taskflow`](https://github.com/heggria/taskflow) | DAG declarativo y verificable | Mejor trazabilidad, seguridad de efectos y recompute | Beta, monorepo grande y más configuración | **La mejor evidencia**: CI Windows |
| [`osolmaz/pi-workflows`](https://github.com/osolmaz/pi-workflows) | Grafos con controllers | Checkpoints, runs siempre activos, controllers y visor | `better-sqlite3`, visor Rust y CI solo Linux | Posible, pero con más fricción |
| [`mjasnikovs/pi-task`](https://github.com/mjasnikovs/pi-task) | Pipeline de specs | `refine → research → grill → compose → critique`; muy bueno para modelos locales | No es un workflow runtime general; AGPL; remote sin auth | **Buena**: CI Windows y Node smoke |
| [`QuintinShaw/pi-dynamic-workflows`](https://github.com/QuintinShaw/pi-dynamic-workflows) | Workflows dinámicos code-mode | Routing por modelos, costes, `parallel`, `pipeline`, `verify`, resume | Menos adecuado para grafos declarativos fijos | Sin CI Windows |
| [`AgwaB/pi-workflow`](https://github.com/AgwaB/pi-workflow) | Stage graphs | `foreach`, `reduce`, `loop`, `dag` y workflows preparados | **No soporta Windows nativo**; requiere WSL2 | **Descartado en Windows nativo** |
| [`davis7dotsh/my-pi-setup`](https://github.com/davis7dotsh/my-pi-setup) | Setup personal | Buenas ideas: subagents, workflows, UI y búsqueda | No es una extensión aislada; sin licencia declarada; muy opinionado | No usar como paquete base |

## Evaluación individual

### `nicobailon/pi-subagents`

Es el mejor subagent manager general. Tiene una base de tests grande, CI Windows, configuración explícita de límites y una API suficientemente rica para workflows sin obligar a adoptar un framework de grafos.

Punto fuerte adicional: los agentes hijos no reciben automáticamente las instrucciones de orquestación del padre, y el runtime limita la recursión. Esto reduce delegación accidental e inflación de contexto.

### `tintinweb/pi-subagents`

Es probablemente la mejor experiencia visual: `/agents`, FleetView, conversación navegable, steering, menciones `@agent`, sesiones reanudables y scheduling. Lo elegiría si la prioridad fuese una UX muy parecida a Claude Code.

No lo prefiero como base porque tiene una superficie más grande y una señal de mantenimiento más ruidosa: 69 issues abiertos frente a 4 en `nicobailon` en la consulta.

### `pi-extensible-workflows`

Es el mejor equilibrio para workflows repetibles sin asumir toda la complejidad de `taskflow`. Su sandbox de scripts impide imports, filesystem, red, procesos, timers y globals de código dinámico; las operaciones de host son explícitas.

La división core/CLI/subagents/Herdr está bien diseñada, aunque conviene instalar solo los paquetes necesarios.

### `taskflow`

Es la propuesta más seria para workflows que modifican repositorios y necesitan una explicación posterior de qué ocurrió. Su persistencia guarda hashes, dependencias declaradas, lecturas observadas, traces y estado de cada fase.

Trusted Effects es una diferencia real frente a los demás: una fase puede proponer una escritura, pero el commit pasa por una transacción de recursos con comprobaciones de path, snapshots, leases y restore. Aun así, el propio proyecto no promete aislamiento hostil completo.

La combinación de 11 paquetes, varios hosts, FlowIR, MCP, DSL, event kernel y control de recursos es potente pero no minimalista.

### `osolmaz/pi-workflows`

Es una buena opción si se piensa en workflows como máquinas de estados persistentes: nodos explícitos, edges, controllers, outbox dirigido a sesiones y visor temporal.

Lo pondría detrás de `pi-extensible-workflows` porque requiere más piezas operativas y su CI no prueba Windows.

### `pi-task`

No lo trataría como competidor directo de un motor de workflows. Es una capa de planificación y especificación, especialmente buena para modelos locales: investiga, pregunta, compone una spec y verifica el trabajo.

Es útil junto a un workflow engine, pero su servidor remoto se inicia sin autenticación; debe permanecer limitado a una red personal confiable. La licencia AGPL también importa si se redistribuye o se integra en un producto.

### `pi-dynamic-workflows`

Coincido con la observación original: su centro es el flujo dinámico generado en code-mode. Es muy bueno para auditorías masivas, research, reviews de múltiples perspectivas y routing entre modelos.

No lo usaría como motor único si el objetivo es mantener workflows estáticos, auditables y fáciles de revisar en Git.

### `pi-workflow`

La arquitectura de etapas es razonable y sus workflows integrados son atractivos. Sin embargo, el propio README declara que Node nativo en Windows no está soportado. Para este entorno solo tendría sentido dentro de WSL2.

### `my-pi-setup`

No es una alternativa equivalente. Es una configuración personal que contiene extensiones propias. Su implementación de subagents es interesante porque unifica Pi, Claude Code y Codex, y su workflow usa un proceso hijo con permisos restringidos, pero copiar el repositorio entero introduciría demasiadas decisiones y dependencias.

## Conflictos de comandos y convivencia

No conviene instalar todos los motores juntos:

- `pi-extensible-workflows`, `osolmaz/pi-workflows` y `AgwaB/pi-workflow` usan `/workflow` o conceptos muy cercanos;
- `pi-dynamic-workflows` registra `/workflows` y una herramienta `workflow`;
- `my-pi-setup` también contiene una herramienta `workflow`;
- `taskflow` usa `/tf` y `taskflow`, por lo que es el candidato más limpio para convivir con `pi-subagents`;
- `@piewf/subagents` y `pi-subagents` cubren el mismo espacio: elegir uno, no ambos.

## Ranking final

### Subagents

1. **`nicobailon/pi-subagents`** — recomendación general.
2. **`tintinweb/pi-subagents`** — mejor UX estilo Claude Code.
3. **`@piewf/subagents`** — mejor si se adopta todo el ecosistema Vekexasia.
4. **Subagents incluidos en `taskflow`** — suficientes dentro de DAGs, no sustituyen a un manager general.
5. **Subagents de `my-pi-setup`** — interesantes, pero no como instalación independiente.

### Workflows

1. **`taskflow`** — ganador técnico para seguridad, trazabilidad y DAGs; usar beta fijada.
2. **`pi-extensible-workflows`** — ganador práctico y estable para uso diario.
3. **`osolmaz/pi-workflows`** — mejor para controllers y workflows siempre activos.
4. **`pi-dynamic-workflows`** — mejor únicamente para orquestación dinámica.
5. **`pi-task`** — mejor como pipeline de planificación/specs, no como motor general.
6. **`AgwaB/pi-workflow`** — buena arquitectura, descartado por Windows nativo.

## Preferencia final

Si la prioridad es una instalación usable y mantenible ahora:

```text
pi-subagents + pi-extensible-workflows
```

Si la prioridad es máxima verificabilidad y control de efectos sobre el repositorio:

```text
pi-subagents + pi-taskflow@0.3.0-beta.1
```

No instalaría ambos motores de workflow inicialmente. Empezaría con `pi-subagents`; añadiría **uno** de los dos motores cuando exista una necesidad real de workflows durables.

### Instalación recomendada por etapas

```text
pi install npm:pi-subagents
```

Después, elegir una sola opción:

```text
pi install npm:pi-extensible-workflows
```

O, si se acepta beta y se necesita el modelo declarativo:

```text
pi install npm:pi-taskflow@0.3.0-beta.1
```
