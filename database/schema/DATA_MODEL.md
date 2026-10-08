# Modelo de datos V2

## Principios

El modelo conserva las capacidades comprobadas del IP Manager actual, pero separa explícitamente:

- solicitud;
- expansión a nodos físicos;
- estado deseado;
- acción de ejecución;
- estado observado;
- persistencia;
- salud;
- inventario legacy;
- auditoría.

## Fan-out lógico

Una solicitud puede apuntar a un nodo individual o a un grupo lógico.

Ejemplo:

`GENERADORES` -> múltiples nodos físicos.

La solicitud se conserva una sola vez, mientras `access_request_targets` y `node_actions` representan cada nodo físico.

Esto evita confundir el estado de una solicitud lógica con el resultado de cada nodo.

## Flujo

```
access_requests
       |
       v
access_request_targets
       |
       +----> desired_access
       |
       +----> node_actions
                    |
                    v
                  Agent
                    |
          +---------+---------+
          |                   |
       APPLIED             PERSISTED
          |                   |
          +---------+---------+
                    |
                    v
               node_health
```

## Estados críticos

### Solicitud

`PENDING -> APPLYING -> ACTIVE`

Errores:

`ERROR`

Revocación:

`REVOKING -> REVOKED`

Expiración:

`EXPIRING -> EXPIRED`

### Acción por nodo

`PENDING -> RECEIVED -> COMPLETED`

o:

`PENDING/RECEIVED -> ERROR`

### Salud del nodo

- `SYNCED`
- `DRIFT`
- `STALE`
- `ERROR`

## Regla fundamental

Una solicitud no pasa a `ACTIVE` porque el backend haya creado una acción.

Debe existir evidencia por cada nodo físico requerido de que:

1. el firewall runtime contiene la regla;
2. la persistencia contiene la regla;
3. la validación de sintaxis pasa;
4. el agent reportó el resultado;
5. el estado observado coincide con el deseado.

## Compatibilidad IVR

Las tablas `ivr_inventory_state` e `ivr_rules_inventory` conservan la función de inventario legacy.

El IVR no se elimina de la arquitectura V2.

Esto permite que un nodo todavía legacy siga siendo visible para las comprobaciones de acceso aunque aún no sea administrado por V2.

## Regla de unicidad

Una misma IP puede existir en múltiples nodos.

La unicidad se aplica a:

`(node_id, ip_address)`

No a la IP global.

Esto permite correctamente escenarios como:

- misma IP en distintos dialers;
- fan-out de ALIADOS;
- fan-out de GENERADORES.

## Separación de hashes

No se utilizará un único hash ambiguo.

Se conservarán como mínimo:

- `desired_hash`
- `applied_hash`
- `persisted_hash`

Así podremos distinguir:

`DESIRED != APPLIED`

de:

`APPLIED != PERSISTED`

Este último caso es precisamente el tipo de drift que V2 debe detectar y corregir.

## Git

El esquema de base de datos también será versionado.

Las migraciones futuras vivirán en:

`database/migrations/`

No se ejecutará SQL manual en producción como método permanente de cambio.
