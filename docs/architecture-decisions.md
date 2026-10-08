# Architecture Decision Records

## ADR-001 — Repositorio independiente

IP_ADMIN_V2 se desarrolla en un repositorio separado del IP Manager actual.

**Motivo:** permitir desarrollo, pruebas y migración sin interrumpir la operación existente.

## ADR-002 — El IVR legacy permanece

El IVR existente seguirá disponible para nodos que todavía dependan de él y para otros nodos que aún no estén migrados.

**Motivo:** IP_ADMIN_V2 debe ampliar capacidades sin romper consumidores existentes.

## ADR-003 — Git como fuente de código

Los cambios permanentes de software y configuración versionable deben originarse en Git.

**Motivo:** eliminar parches manuales no auditables y facilitar rollback.

## ADR-004 — Reconciliación idempotente

El agent debe poder ejecutarse repetidamente sin generar duplicados ni alterar un estado que ya sea correcto.

**Motivo:** reducir el riesgo operativo de ejecuciones recurrentes.

## ADR-005 — Separar estado deseado de estado aplicado

El backend no debe asumir que una solicitud exitosa equivale a una regla realmente aplicada.

**Motivo:** el incidente observado en producción demostró que una IP puede estar registrada pero seguir inaccesible.
