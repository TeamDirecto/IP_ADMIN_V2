# Seguridad

## Principios

- Nunca guardar secretos en Git.
- No exponer credenciales en logs.
- Validar entradas antes de convertirlas en reglas de firewall.
- Aplicar mínimo privilegio.
- Separar API de administración y agentes.
- Registrar quién, qué, cuándo y desde qué versión se realizó un cambio.

## Firewall

Las reglas generadas deben ser deterministas y verificables.

Una regla no se considera correcta solamente por existir en un archivo.

Debe comprobarse:

- sintaxis;
- runtime;
- persistencia;
- cadena;
- jump;
- conectividad esperada cuando corresponda.
