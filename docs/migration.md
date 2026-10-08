# Estrategia de migración

## Regla principal

No se detiene el IP Manager actual para comenzar IP_ADMIN_V2.

Ambos proyectos coexistirán durante el desarrollo.

## Modos

### LEGACY

El nodo continúa administrado por el mecanismo actual.

### OBSERVE

IP_ADMIN_V2 solamente consulta y reporta.

### HYBRID

IP_ADMIN_V2 administra componentes específicos, mientras legacy conserva los demás.

### V2

IP_ADMIN_V2 es el propietario de la administración del nodo.

## Regla de propiedad

Durante la migración debe existir un único propietario de escritura para cada conjunto de reglas.

No se permitirá que dos agentes modifiquen simultáneamente el mismo recurso sin un mecanismo explícito de coordinación.

## Rollback

Cada cambio aplicado debe poder:

1. identificarse por versión;
2. validarse;
3. revertirse;
4. auditarse.
