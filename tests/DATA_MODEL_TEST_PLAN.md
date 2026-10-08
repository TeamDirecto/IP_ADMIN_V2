# Pruebas del modelo de datos

Antes de conectar el backend real se deben probar:

1. Crear una solicitud para un nodo individual.
2. Crear una solicitud para un grupo lógico.
3. Expandir un grupo a varios nodos.
4. Verificar que la misma IP pueda existir en dos nodos.
5. Verificar que no pueda existir dos veces en el mismo nodo.
6. Generar acciones independientes por nodo.
7. Simular éxito en todos los nodos.
8. Simular fallo en un nodo de un fan-out.
9. Verificar que la solicitud no se marque ACTIVE mientras falte un target obligatorio.
10. Simular drift DESIRED/APPLIED.
11. Simular drift APPLIED/PERSISTED.
12. Registrar reconciliación y rollback.
13. Registrar inventario IVR legacy.
14. Verificar expiración y revocación.
15. Verificar auditoría completa.
