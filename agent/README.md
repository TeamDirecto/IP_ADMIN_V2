# Agent

Componente local instalado en los nodos.

## Estado actual

La primera implementación es **read-only**.

El agente observa el estado runtime y persistente y reporta hashes y estado. No debe ejecutar altas o bajas en esta fase.

## Uso

```bash
/root/bin/ip-admin-agent.sh
```

Variables configurables:

- `IP_ADMIN_NODE_NAME`
- `IP_ADMIN_RULES_FILE`
- `IP_ADMIN_IPTABLES_SAVE`
- `IP_ADMIN_IPTABLES_RESTORE`
- `IP_ADMIN_CHAIN`

Los overrides permiten ejecutar pruebas con fixtures sin tocar un firewall real.

## Estados

- `SYNCED`: runtime y persistencia coinciden.
- `DRIFT`: existe diferencia entre ambos estados.
- `ERROR`: no se pudo observar o validar el estado.

La reconciliación será una fase posterior y deberá conservar la propiedad de escritura definida por nodo.
