# Mapa de ramas

Estado al 2026-11-04. Rama de verdad: **`cierre/integracion`**. Todo el
trabajo nuevo sale de ella y vuelve a ella; nada va a `main` sin
autorización del responsable (CLAUDE.md).

## Ramas vivas

| Rama | Para qué |
|---|---|
| `cierre/integracion` | La rama de verdad: auditoría, cierres #1–#17, reglas con su matriz y la suite de `docs/RESULTADOS_SUITE.md`. |
| `cierre/main-igual-integracion` | `cierre/integracion` más `git merge -s ours origin/main`: mismo árbol que `cierre/integracion` (git diff vacío), con `main` como antecesor. Sirve para llevar `cierre/integracion` a `main` sin conflictos. Al fusionarla, todo lo que `main` tenía y `cierre/integracion` no (el PR #24: empresas, servicios especiales y sus reglas) deja de estar en `main`. |
| `main` | Producción. Hoy es el PR #24 (`claude/sleepy-brown-wuamgt`), cuya ejecución del CI se canceló antes de desplegar (run 41853680224). |

## Ya contenidas en `cierre/integracion` (no aportan nada más)

`cierre/ajustes`, `cierre/auditoria`, `cierre/build-seguridad`,
`cierre/endurecimiento`, `cierre/experiencia`, `cierre/identidad`,
`cierre/idiomas`, `cierre/pagos`, `cierre/pagos-g`, `cierre/piloto`,
`cierre/preferencias`, `cierre/registro-chofer`, `cierre/sos`,
`cierre/ventana-chofer`, `cierre/verificacion`, `cierre/vuelos`,
`cierre/reglas-usuarios`, `cierre/fuentes-limite` y las ramas `claude/*`
antiguas (`affectionate-carson`, `awesome-johnson`, `beautiful-dijkstra`,
`deploy-sa-key`, `fix-android-ios-build`, `fix-ci-flutter`,
`fix-firebase-project`).

## Descartadas o pendientes

- `claude/sleepy-brown-wuamgt` (PR #24, ya en `main`; la rama remota ya no
  existe, queda `refs/pull/24/head`): empresas y servicios especiales
  escriben desde el cliente y no siguen las reglas de `cierre/integracion`
  (callables con zod, segundo factor, auditoría, matriz, textos en tres
  idiomas, modelo de pagos). No se portan. Empresas espera la decisión de
  negocio sobre el NIT y la facturación; si se retoma, se rehace desde
  `cierre/integracion` y apagada por defecto (clave ausente = inactiva,
  como `config/ops.blockOnExpiredDocs`).
- `claude/sleepy-cerf-mggmiw`: otra línea (sale del PR #23), sin revisar.

## Cuidado al fusionar en `main`

Cada push a `main` lanza el CI y sus despliegues (functions, índices y
hosting) en cuanto terminan los builds. En `cierre/integracion` esos jobs
usan el entorno `production`, que pide aprobación solo si el entorno tiene
revisores obligatorios en GitHub (Settings → Environments). Las reglas solo
se despliegan a mano (`deploy_rules`, ver DEPLOY.md).
