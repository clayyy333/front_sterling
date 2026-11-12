# Presencia en Metro Life

El loader descarga `modules/core/presence.lua` en segundo plano después de terminar
`Window:OpenBook()`. No se incluye en el manifiesto ni en la barra de carga.
`main.lua` no requiere cambios. Fuera del GameId 4540138978 no descarga el módulo
ni realiza solicitudes de presencia.

Usa el backend existente y sus rutas `sessions/start`, `sessions/heartbeat` y
`sessions/end`. Registra UserId, nombre, nombre visible, GameId, PlaceId, JobId
y versión `script_sterling`. No solicita geolocalización ni perfiles de red.
El panel existente muestra el origen en la columna de versión del script.

Los avisos se envían cada 30 segundos, sin depender de RenderStepped/Heartbeat.
Los errores de conexión se reintentan con espera creciente hasta 120 segundos.
Cerrar o recargar Sterling intenta finalizar la sesión; si el cliente termina
abruptamente, aplica el vencimiento de actividad existente del backend.

Preparado localmente, pendiente de publicar los dos archivos del conector y
probar con el cliente real. No necesita migración del backend. El panel agrupa
sesiones de un mismo usuario, lugar y servidor: si ejecuta ambos scripts a la vez,
puede mostrar solo la sesión más reciente. Un filtro independiente por script
requeriría ajustar esa consulta y el panel.
