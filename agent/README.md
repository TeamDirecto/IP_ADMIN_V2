# Agent

Componente local instalado en los nodos.

## Estado actual

La implementación es **read-only**.

El agente observa el estado runtime y persistente y reporta hashes y estado. No ejecuta altas o bajas de firewall en esta fase.

## Observer

Uso:

```bash
bash /root/bin/ip-admin-agent.sh
```

Variables configurables:

- `IP_ADMIN_RULES_FILE`
- `IP_ADMIN_IPTABLES_SAVE`
- `IP_ADMIN_IPTABLES_RESTORE`
- `IP_ADMIN_CHAIN`

Los overrides permiten ejecutar pruebas con fixtures sin tocar un firewall real.

## Estados

- `SYNCED`: runtime y persistencia coinciden y la cadena/jump requeridos existen.
- `DRIFT`: existe diferencia entre runtime y persistencia.
- `ERROR`: no se pudo observar o validar el estado.

## Heartbeat opcional

El reporter no modifica el firewall. Solo publica el resultado del observer al backend.

Configuración:

- `IP_ADMIN_BACKEND_URL`
- `IP_ADMIN_NODE_NAME`
- `IP_ADMIN_TOKEN_FILE`
- `IP_ADMIN_AGENT`
- `IP_ADMIN_AGENT_VERSION`

Uso:

```bash
bash /root/bin/ip-admin-heartbeat.sh
```

Si el backend no está disponible, el reporter sale sin alterar el firewall ni bloquear la operación local.

El token debe almacenarse en un archivo protegido por root y nunca debe entrar al repositorio.

La reconciliación será una fase posterior y deberá conservar la propiedad de escritura definida por nodo.
