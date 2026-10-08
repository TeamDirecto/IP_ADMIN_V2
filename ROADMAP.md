# Roadmap

## Fase 0 — Diseño

- [x] Crear repositorio independiente.
- [x] Mantener IP Manager actual intacto.
- [x] Mantener IVR/legacy como compatibilidad.
- [x] Definir Git como fuente de código.
- [x] Definir modelo de datos.
- [x] Definir API inicial.
- [x] Definir contrato Agent <-> Backend.
- [x] Definir estados DESIRED/APPLIED/PERSISTED.

## Fase 1 — Observabilidad

- [x] Agent en modo read-only.
- [x] Inventario de reglas.
- [x] Hash de estado.
- [x] Detección de drift.
- [x] Reporte de discrepancias.
- [x] CI básica del agent.
- [x] Auditoría centralizada.

## Fase 2A — Backend mínimo

- [x] API Flask inicial.
- [x] SQLite con WAL y busy timeout.
- [x] Autenticación por token por nodo.
- [x] Endpoint DESIRED.
- [x] Endpoint HEARTBEAT.
- [x] Endpoint ACTION RESULT.
- [x] Auditoría de heartbeat y resultados.
- [x] Rechazo de resultados de acciones obsoletas.
- [x] Tests unitarios del contrato.
- [ ] Endpoint/flujo de administración de nodos.
- [ ] Revisión de seguridad antes de exposición de red.
- [ ] TLS/proxy de producción.
- [ ] Métrica y monitoreo central.

## Fase 2B — Reconciliación controlada

- [ ] Aplicación idempotente.
- [ ] Validación antes de cada cambio.
- [ ] Persistencia automática.
- [ ] Snapshot pre-cambio.
- [ ] Rollback local.
- [ ] Health check post-cambio.
- [ ] Modo DRY_RUN.
- [ ] Acción con generación y expiración.
- [ ] Evidencia de resultado.

## Fase 3 — Piloto

- [ ] Seleccionar nodo piloto.
- [ ] Ejecutar en modo supervisado.
- [ ] Comparar contra IP Manager actual.
- [ ] Documentar diferencias.
- [ ] Validar reinicio.
- [ ] Probar recuperación de reglas después de reboot.

## Fase 4 — Migración gradual

- [ ] Migrar nodos compatibles.
- [ ] Mantener IVR para nodos legacy.
- [ ] Evitar doble escritura sobre el mismo recurso.
- [ ] Monitorear drift.
- [ ] Migración por grupos con rollback.

## Fase 5 — Consolidación

- [ ] Migrar nodos restantes que sean compatibles.
- [ ] Retirar componentes antiguos únicamente cuando no tengan consumidores.
- [ ] Mantener backend legacy mientras exista dependencia real.
