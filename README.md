# IP_ADMIN_V2

Nueva generación del sistema de administración de acceso IP para nodos VICIdial/Asterisk.

## Objetivo

Diseñar un reemplazo gradual y controlado del IP Manager actual, sin interrumpir la operación existente.

El proyecto debe permitir:

- mantener compatibilidad con el IVR/flujo legacy existente;
- administrar nodos nuevos y nodos que todavía dependen del sistema actual;
- hacer persistentes las reglas de firewall;
- separar estado deseado, estado aplicado y persistencia;
- detectar y reconciliar diferencias;
- evitar parches manuales en producción;
- versionar todo el código y la configuración mediante Git;
- permitir despliegues y rollback controlados.

## Principio de migración

**IP_ADMIN_V2 no reemplaza de inmediato al IP Manager actual.**

Durante la primera etapa ambos coexistirán. La migración será gradual por nodo y por capacidad.

## Arquitectura inicial

- **IVR/Legacy:** continúa existiendo como mecanismo de compatibilidad para los sistemas que todavía lo necesitan.
- **IP_ADMIN_V2:** nueva plataforma de administración y reconciliación.
- **Agentes:** componentes instalados en los nodos que aplican el estado autorizado.
- **Backend:** fuente de estado deseado y coordinación.
- **Git:** fuente de código, scripts, documentación y configuración versionable.
- **Firewall:** separación explícita entre runtime y persistencia.

## Estado del proyecto

Fase 0 — arquitectura y diseño.

No se realizan cambios de producción desde este repositorio todavía.

## Reglas de operación

1. Ningún secreto, contraseña, token o llave privada debe almacenarse en Git.
2. Los cambios de producción deben provenir de una versión identificable del repositorio.
3. Todo despliegue debe poder auditarse y revertirse.
4. La compatibilidad legacy debe mantenerse hasta completar la migración.
