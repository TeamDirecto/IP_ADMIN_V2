# Arquitectura de IP_ADMIN_V2

## 1. Objetivo

IP_ADMIN_V2 será una plataforma nueva para administrar el acceso por IP de los nodos de voz, manteniendo una migración gradual desde el IP Manager actual.

La arquitectura debe resolver específicamente los problemas observados en producción:

- una IP puede aparecer como autorizada pero no estar realmente aplicada;
- runtime y persistencia pueden quedar desincronizados;
- una regla puede desaparecer de `rules.v4`;
- el reinicio del nodo puede recuperar un estado diferente al estado deseado;
- el sistema actual puede eliminar una regla local aunque el backend todavía la considere deseada;
- los cambios manuales pueden quedar fuera de control de versiones.

## 2. Compatibilidad legacy

El IVR/flujo legacy continuará existiendo.

No se considera un componente temporal que deba eliminarse al inicio. Será un backend de compatibilidad mientras existan nodos que dependan de él.

La migración debe permitir:

- nodos exclusivamente legacy;
- nodos administrados por IP_ADMIN_V2;
- nodos híbridos durante la transición;
- coexistencia con otros nodos que todavía no formen parte del nuevo proyecto.

## 3. Componentes

### Backend

Fuente del estado deseado, inventario de nodos, políticas y auditoría.

### Agent

Proceso instalado en cada nodo. Consulta el estado autorizado y ejecuta la reconciliación local.

### Firewall adapter

Capa responsable de aplicar reglas al firewall. No debe mezclar la lógica de negocio con comandos de iptables.

### Persistence manager

Responsable de garantizar que el estado persistente corresponda al estado aplicado y validado.

### Legacy IVR backend

Mantiene la compatibilidad con el mecanismo existente.

## 4. Modelo de estados

Se distinguirán explícitamente:

1. **DESIRED** — lo que el backend determina que debe existir.
2. **APPLIED** — lo que actualmente existe en el firewall runtime.
3. **PERSISTED** — lo que existe en la configuración persistente.
4. **HEALTHY** — cuando los tres estados esperados coinciden y las validaciones pasan.

Una IP no se considerará correctamente aplicada solamente porque exista en una tabla o archivo.

## 5. Reconciliación

La reconciliación será idempotente.

Si:

`DESIRED == APPLIED == PERSISTED`

no debe realizar cambios.

Si existe una diferencia:

- registrar el motivo;
- aplicar únicamente la corrección necesaria;
- validar runtime;
- validar persistencia;
- registrar resultado;
- reportar estado final.

## 6. Git

Git será la fuente de código y configuración versionable.

No se deben realizar cambios permanentes mediante edición manual de archivos en producción.

Todo cambio de:

- agentes;
- scripts;
- servicios;
- plantillas;
- migraciones;
- configuración versionable;

debe originarse en un commit identificable.

Los secretos y datos dinámicos no se almacenarán en Git.

## 7. Principio de seguridad

IP_ADMIN_V2 no debe asumir que el firewall está sano.

Antes de modificar reglas deberá validar:

- existencia de cadenas requeridas;
- jump desde INPUT;
- sintaxis;
- estado runtime;
- estado persistente;
- integridad básica del archivo;
- capacidad de restauración.

## 8. Migración

La migración será por nodo.

Orden conceptual:

1. observación;
2. instalación del agent;
3. comparación;
4. reconciliación controlada;
5. persistencia;
6. validación;
7. operación normal;
8. retiro gradual del componente legacy únicamente cuando ya no sea necesario.

No se contempla un cambio global de una sola vez.
