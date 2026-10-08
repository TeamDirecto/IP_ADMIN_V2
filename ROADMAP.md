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
- [ ] Auditoría centralizada.

## Fase 2 — Reconciliación controlada

- [ ] Aplicación idempotente.
- [ ] Validación después de cada cambio.
- [ ] Persistencia automática.
- [ ] Rollback local.
- [ ] Health check.
- [ ] Modo `DRY_RUN`.

## Fase 3 — Piloto

- [ ] Seleccionar nodo piloto.
- [ ] Ejecutar en modo supervisado.
- [ ] Comparar contra IP Manager actual.
- [ ] Documentar diferencias.
- [ ] Validar reinicio.

## Fase 4 — Migración gradual

- [ ] Migrar nodos compatibles.
- [ ] Mantener IVR para nodos legacy.
- [ ] Evitar doble escritura sobre el mismo recurso.
- [ ] Monitorear drift.

## Fase 5 — Consolidación

- [ ] Migrar nodos restantes que sean compatibles.
- [ ] Retirar componentes antiguos únicamente cuando no tengan consumidores.
- [ ] Mantener backend legacy mientras exista dependencia real.
