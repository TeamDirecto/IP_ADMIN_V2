# Máquina de estados IP_ADMIN_V2

## Acceso

PENDING -> APPROVED -> APPLYING -> ACTIVE

También existen las salidas ERROR, EXPIRING, EXPIRED, REVOKING y REVOKED.

ACTIVE solo es válido cuando cada nodo físico requerido tiene evidencia de aplicación correcta.

## Salud del nodo

- SYNCED: DESIRED, APPLIED y PERSISTED coinciden y las validaciones pasan.
- DRIFT: existe diferencia entre estados.
- STALE: el backend dejó de recibir heartbeat dentro del TTL.
- ERROR: el agente no puede observar o validar el estado.

## Expiración

La expiración modifica primero el estado deseado y después genera una acción REMOVE por nodo.

El nodo no decide por sí mismo que una IP sigue vigente basándose únicamente en una copia local.

## Regla de cierre

Una acción no se cierra por haber ejecutado el comando. Se cierra después de validar el estado resultante.
