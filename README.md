# Sterling

Front modular independiente con tema rubí oscuro. El proyecto original `fling_lua` no se modifica.

## Ejecutar

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/clayyy333/front_sterling/main/main.lua"))()
```

Para probar la carpeta en el sistema de archivos del ejecutor:

```lua
getgenv().SterlingSource = {LocalRoot="front_sterling"}
loadstring(readfile("front_sterling/main.lua"))()
```

Elimina `SterlingSource` para volver a la carga remota. La raíz local depende de dónde copies los archivos en tu ejecutor.

## Interfaz funcional

- Movimientos: catálogo paginado con miniaturas, buscador por nombre/ID, paquetes completos o por estado, favoritos, recientes, seguimiento de amigos presentes, atajos, preferencias de reproducción y combos de hasta 3 emotes.
- Reproductor flotante: pausa, detener, velocidades predefinidas y copia del ID cuando el ejecutor la permite.
- Volar: sin objetivo, eficiente corto con selector de jugador, contacto ajustable y vehículos 2 Delta/Xeno con selección y modo automático.
- Ancla: controles normales de Ancla/AntiSeat/Heartbeat, Test con regreso constante y Muévete anclado únicamente 1.3. La UI evita activar estos modos incompatibles simultáneamente.
- Control: perspectiva orbital, vuelo con ascenso/descenso táctil, velocidad/salto/teletransporte y salto continuo con teclado o botón táctil nativo. El salto continuo mantiene el impulso vertical mientras se mantiene pulsado y lo suelta al dejar de pulsar.
- Interfaz: centrar, restablecer tamaño y redimensionar arrastrando la esquina. El tamaño se guarda al terminar de redimensionar.

Los paneles usan pestañas compactas y botones de 32–40 px, sin tarjetas informativas grandes. Los controles llaman a las copias de los motores mediante `app.Flows`; sus fuentes físicas originales no se editan. Los ajustes avanzados del pulso y el diagnóstico de Muévete anclado conservan la restricción de owners de sus módulos. Los extras de la UI anterior copiados bajo `modules/movements/ui/` se conservan como fuentes; no se monta aquella interfaz ni su backend.

## Carga y módulos

`main.lua` es un orquestador estable. `core/loader.lua` muestra `ui/loading.lua` antes del manifiesto y los catálogos grandes. Carga y decodifica primero emotes y después paquetes de animación, luego compila e inicializa los módulos activos. La barra avanza por etapas completadas, no por tiempo simulado. La ventana se muestra al terminar. Un error deja una presentación cerrable y reejecutar limpia la anterior.

La imagen definitiva está pendiente; se muestra una S provisional. `SterlingSource.IntroImage` permite configurar un ID de imagen sin esperar a su descarga para continuar la carga.

Los motores de Movimientos se inicializan al abrir su página y reutilizan los catálogos ya preparados, sin volver a descargarlos ni decodificarlos. El buscador cede fotogramas durante el filtrado y únicamente crea las miniaturas de la página visible. Cambiar de pestaña elimina sus conexiones y cancelar una búsqueda invalida su resultado anterior.

La UI está en `modules/ui` y `modules/features`; las dependencias y APIs públicas, en `modules/adapters` y `core/legacy_context.lua`. Las preferencias de ventana usan `sterling_preferences_v1.json` y las de Movimientos `SterlingMovements_Data_<UserId>.json`. Sin acceso a archivos, esas preferencias de Movimientos solo duran durante su contexto actual.

Los bindings de render de motores copiados usan el prefijo `Sterling::` y `getgenv()` de esas copias es un espacio privado. Cerrar Sterling limpia sus conexiones y restaura los controladores activos; no cierra el front original. Ambos pueden modificar el mismo personaje: la separación de contextos no convierte sus modos físicos simultáneos en compatibles.

## Validación

```powershell
python -m pip install lupa
python tests/run_tests.py
```

Las pruebas comprueban sintaxis, manifiesto, progresión/cancelación de carga, APIs copiadas, clics funcionales, reproducción desde tarjetas, favoritos, filtrado, vuelo, salto continuo con teclado/touch, redimensionado y limpieza al recargar. Los hashes de `modules/copied_sources.json` comprueban que las copias de motores conservan su contenido preparado. `.gitattributes` evita alterar esos bytes por normalización de saltos de línea.

Son pruebas simuladas; la apariencia, replicación y física reales requieren ejecutar Sterling en Roblox.
