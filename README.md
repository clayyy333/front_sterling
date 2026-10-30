# Sterling

Front independiente dentro de `fling_lua`. El `main.lua` raÃƒÂ­z del proyecto y su GUI no se modifican.

`main.lua` solo descarga y ejecuta el cargador. Para aÃƒÂ±adir funciones se editan los mÃƒÂ³dulos y el manifiesto, sin volver a ofuscar el main.

## Estructura

- `main.lua`: entrada estable, preparada para ofuscarse despuÃƒÂ©s.
- `modules/manifest.lua`: orden de carga y lista de funciones.
- `modules/core/config.lua`: nombre, versiÃƒÂ³n, tamaÃƒÂ±o inicial y archivo de preferencias.
- `modules/core/loader.lua`: carga y validaciÃƒÂ³n de mÃƒÂ³dulos; cada ejecuciÃƒÂ³n usa un contexto nuevo.
- `modules/core/lifecycle.lua`: conexiones y limpieza al cerrar o ejecutar otra vez.
- `modules/core/storage.lua`: preferencias locales independientes de la GUI original.
- `modules/core/legacy_context.lua`: dependencias y contexto aislado para las copias existentes.
- `modules/player/`: motores copiados, sin cambios en su lÃƒÂ³gica.
- `modules/adapters/flows.lua`: registro de motores para conectar controles posteriormente.
- `modules/ui/`: tema, componentes, ventana adaptable y navegaciÃƒÂ³n.
- `modules/features/`: pÃƒÂ¡ginas y futuros flujos.
- `tests/`: comprobaciones del cargador y ciclo de vida.

La base incluye Inicio, **Volar**, **Ancla** e Interfaz. Volar tiene preparados Sin objetivo (controlador automÃƒÂ¡tico), Eficiente corto, Por contacto ajustable y Con vehÃƒÂ­culos 2 (Delta/Xeno). Ancla incluye el ancla normal de tres controles (Ancla, AntiSeat, Heartbeat), su funciÃƒÂ³n de regreso y el ancla estÃƒÂ¡tica Test con su ajuste de regreso constante. La distribuciÃƒÂ³n de botones de estos flujos estÃƒÂ¡ pendiente; cargar o visitar sus pÃƒÂ¡ginas no los activa.

Los motores se copian completos desde `modules/player/` del proyecto principal. No se cambian velocidades, ciclos, parÃƒÂ¡metros ni mÃƒÂ©todos de esos archivos. `modules/copied_sources.json` conserva sus rutas y hashes para verificar la copia. La ÃƒÂºnica selecciÃƒÂ³n inicial del adaptador es el modo corto del motor eficiente.

Los mÃƒÂ³dulos de retorno y refuerzo de Xeno se incluyen como dependencias originales. El controlador de contacto ajustable conserva su dependencia de owner para los ajustes avanzados; el adaptador reproduce esa comprobaciÃƒÂ³n sin cargar todo Fling experimental. TodavÃƒÂ­a no se incorpora la conexiÃƒÂ³n al backend, sus bloqueos, emotes u otras versiones de ancla.

Cada copia escribe en `app.Legacy`, nunca en el contexto de la GUI original. `getgenv()` devuelve un espacio propio y los bindings de render se registran con el prefijo `Sterling::`; por eso cargar Sterling no ejecuta los callbacks de limpieza del otro front. Ambos fronts controlan el mismo personaje: no activar motores fÃƒÂ­sicos incompatibles simultÃƒÂ¡neamente.

## Motores preparados

Los futuros botones acceden a estas referencias desde `context.Flows`:

| Referencia | Motor |
| --- | --- |
| `Volar.SinObjetivo` | `Fling2AutoController` |
| `Volar.EficienteCorto` | `Fling2EfficientCore`, ya seleccionado en modo corto |
| `Volar.PorContacto` | `AdjustableContactFlingController` |
| `Volar.ConVehiculos2.Delta` | `CarFling2Delta` |
| `Volar.ConVehiculos2.Xeno` | `CarFling2Xeno` |
| `Volar.ConVehiculos2.Automatico` | LÃƒÂ³gica de selecciÃƒÂ³n automÃƒÂ¡tica extraÃƒÂ­da de la vista original de vehÃƒÂ­culos 2 |
| `Ancla.Normal` | `AnchorCore`: `SetAncla`, `SetAntiSeat`, `SetHeartbeat` |
| `Ancla.Regreso` | `AnchorForceReturn` |
| `Ancla.Test` | `StaticNoclipAnchorCore`: `Start`, `Stop`, `SetConstantReturn` |
| `Ancla.MueveteV13` | `MobileAnchorV13Core`: `Start`, `Stop`, `Toggle` |

Antes de iniciar Eficiente corto se debe seleccionar un jugador con `SetTarget(player)`. Sin objetivo selecciona jugadores mediante el controlador automÃƒÂ¡tico original. No se duplican motores al abrir o cambiar de pÃƒÂ¡gina.

Test es la copia ÃƒÂ­ntegra del ancla estÃƒÂ¡tica pÃƒÂºblica: activa automÃƒÂ¡ticamente la prevenciÃƒÂ³n de asientos a 15 studs con `Start()` y la retira con `Stop()`. `SetConstantReturn(true/false)` prepara el control que acompaÃƒÂ±a al botÃƒÂ³n principal. No requiere un tercer botÃƒÂ³n de prevenciÃƒÂ³n ni permiso de owner. Conserva noclip, recuperaciÃƒÂ³n antes/despuÃƒÂ©s de fÃƒÂ­sica y restauraciÃƒÂ³n de propiedades al desactivar.

MuÃƒÂ©vete anclado incluye **solo 1.3** y su dependencia `mobile_fall_guard.lua`, copiados ÃƒÂ­ntegramente. Las versiones 1.0 y 1.1 no se cargan. Conserva la prevenciÃƒÂ³n de caÃƒÂ­das, cachÃƒÂ© de asientos, recuperaciÃƒÂ³n, liberaciÃƒÂ³n de uniones y diagnÃƒÂ³stico restringido a owners de la versiÃƒÂ³n original. Se registra junto a las otras anclas sin activarse al abrir la GUI.

VehÃƒÂ­culos 2 conserva ambas copias de motor completas. Su lÃƒÂ³gica automÃƒÂ¡tica estaba en `ui/fling_car2.lua`, junto a los botones: se separÃƒÂ³ en `adapters/vehicle2_auto.lua`, con la misma comprobaciÃƒÂ³n de apariciÃƒÂ³n cada 0.25 s y elecciÃƒÂ³n del ÃƒÂºltimo vehÃƒÂ­culo propio disponible. La API ofrece `SetPlayer(player)`, `SetCar(car)` y `SetMode("Delta")` / `SetMode("Xeno")` / `SetMode(nil)`. Queda desactivada al cargar. El coordinador con VehÃƒÂ­culos 1 no es necesario porque ese flujo todavÃƒÂ­a no forma parte de Sterling.

## Carga

DespuÃƒÂ©s de publicar esta carpeta en el repositorio, ejecutar su propio main:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/clayyy333/front_sterling/main/main.lua"))()
```

Para probar archivos locales antes de publicar, copiar la carpeta al espacio de archivos del executor y configurar su ruta:

```lua
getgenv().SterlingSource = { LocalRoot = "front_sterling" }
loadstring(readfile("front_sterling/main.lua"))()
```

Para volver a la fuente remota, usar `getgenv().SterlingSource = nil`. TambiÃƒÂ©n se admite `BaseUrl` para otro alojamiento y `Revision` para fijar una versiÃƒÂ³n. La cachÃƒÂ© del cargador solo dura una ejecuciÃƒÂ³n; los mÃƒÂ³dulos se vuelven a descargar al ejecutar otra vez.

## AÃƒÂ±adir un flujo

Crear `modules/features/mi_flujo.lua` y aÃƒÂ±adir `"features/mi_flujo"` al apartado `features` del manifiesto:

```lua
return function(app)
    app.Features:Register({
        Id = "mi_flujo",
        Label = "Mi funciÃƒÂ³n",
        Title = "Mi funciÃƒÂ³n",
        Subtitle = "DescripciÃƒÂ³n breve",
        Mount = function(context, parent)
            local button = context.UI:Button(parent, "Activar")
            button.Size = UDim2.new(1, 0, 0, 44)
            context:Connect(button.Activated, function()
                -- Controlador independiente del flujo.
            end)
            context:OnCleanup(function()
                -- Detener el controlador y restaurar sus propiedades.
            end)
        end,
    })
    return true
end
```

Las pÃƒÂ¡ginas se construyen cuando se abren por primera vez. Los controladores nuevos se aÃƒÂ±aden a `core`; las copias que usan el contexto antiguo se aÃƒÂ±aden a `legacy`. Los mÃƒÂ³dulos de `adapters` se ejecutan despuÃƒÂ©s de todas las copias y antes de registrar las pÃƒÂ¡ginas.

Al reutilizar un mÃƒÂ³dulo antiguo, copiarlo dentro de esta carpeta y adaptar sus dependencias al contexto. Los mÃƒÂ³dulos actuales que usan `setfenv`, nombres compartidos o callbacks de la GUI original necesitan esa adaptaciÃƒÂ³n; no se ejecutan automÃƒÂ¡ticamente como mÃƒÂ³dulos de Sterling. Evitar cargar el bootstrap o el manifiesto completo de la GUI anterior.

Para validar el tamaÃƒÂ±o se usan los lÃƒÂ­mites de la pantalla. Arrastre, redimensionado y navegaciÃƒÂ³n aceptan ratÃƒÂ³n o toque. El tamaÃƒÂ±o se guarda al terminar de redimensionar; con `writefile` se conserva entre ejecuciones y sin ÃƒÂ©l solo durante la sesiÃƒÂ³n disponible. Cerrar o reejecutar Sterling limpia sus conexiones y su GUI, sin cerrar la GUI original.

## ValidaciÃƒÂ³n

Las pruebas utilizan Python y Lupa ÃƒÂºnicamente en desarrollo; no aÃƒÂ±aden dependencias a la GUI:

```powershell
python -m pip install lupa
python front_sterling/tests/run_tests.py
```

Cubren sintaxis, manifiesto, carga local completa, pÃƒÂ¡ginas bajo demanda, interacciÃƒÂ³n tÃƒÂ¡ctil simulada, preferencias, diseÃƒÂ±o adaptable, reejecuciÃƒÂ³n y limpieza. La apariencia y la interacciÃƒÂ³n real se deben comprobar en Roblox.

Control: perspectiva de cÃƒÂ¡mara, vuelo y velocidad copiados con su lÃƒÂ³gica original, todavÃƒÂ­a sin controles de activaciÃƒÂ³n en la pÃƒÂ¡gina. La copia de movement_control ÃƒÂºnicamente expone su conexiÃƒÂ³n CharacterAdded para desconectarla al cerrar Sterling.

## Movimientos preparados

`modules/movements/` contiene las fuentes de Emotes, Animaciones, Favoritos, Recientes, Amigos, Atajos y Ajustes, incluidos catÃƒÂ¡logos, HUD, combos y mÃƒÂ³dulos auxiliares de ajustes. Las fuentes de UI se conservan para la siguiente fase de diseÃƒÂ±o; no se monta la GUI antigua dentro de Sterling.

`app.Flows.Movimientos:EnsureLoaded()` carga los motores y devuelve `true, contexto` o `false, error`. No se lee ni decodifica ningÃƒÂºn catÃƒÂ¡logo al arrancar Sterling o abrir la pÃƒÂ¡gina descriptiva. El contexto ofrece las funciones originales `PlayEmote`, `StopEmote`, `EquipAnimationPack`, `EquipAnimationPart`, `ToggleFavorite`, `AddToRecent`, `SetKeybind`, `StartCombo` y `LocalEmoteFollow`, junto con los datos y preferencias originales. Los mÃƒÂ³dulos visuales y auxiliares de Ajustes estÃƒÂ¡n copiados pero todavÃƒÂ­a no se ejecutan: su conexiÃƒÂ³n a los nuevos controles corresponde a la fase de diseÃƒÂ±o.

El guardado usa `SterlingMovements_Data_<UserId>.json`, independiente del front original y de las dimensiones de Sterling. No se importa el bootstrap original ni su backend. Las ÃƒÂºnicas adaptaciones de las copias son el nombre del archivo de preferencias y la exposiciÃƒÂ³n de conexiones/limpieza de animaciones para cerrar Sterling sin dejar observadores. Los hashes representan estas copias adaptadas. Los catÃƒÂ¡logos se conservan ÃƒÂ­ntegros, sin traducciones ni recortes.

## PresentaciÃ³n y carga por etapas

El `main.lua` permanece intacto. `core/loader.lua` lee primero `ui/loading.lua`, que muestra inmediatamente la presentaciÃ³n roja con una S provisional y espera a que se dibuje antes de leer fuentes grandes. DespuÃ©s lee el manifiesto, carga y decodifica emotes, luego paquetes de animaciÃ³n y finalmente descarga/compila e inicializa los mÃ³dulos activos. `startupCatalogs` define el orden en el manifiesto. El porcentaje representa etapas completadas (no bytes ni segundos estimados), es monotÃ³nico y solo llega a 100% tras completar la inicializaciÃ³n. No hay esperas cosmÃ©ticas.

La ventana principal se mantiene oculta durante la preparaciÃ³n. La presentaciÃ³n cede fotogramas entre etapas cuando se agota el presupuesto de trabajo; la decodificaciÃ³n individual de JSON sigue siendo una operaciÃ³n sÃ­ncrona del motor de Roblox. La carga por etapas mejora la respuesta visual, no elimina el coste total de descargar y procesar los catÃ¡logos.

`getgenv().SterlingSource.IntroImage` acepta un ID o URL de imagen de Roblox. Sin imagen se usa el monograma S, pendiente de recibir el arte definitivo. La presentaciÃ³n no espera a descargar esa imagen para avanzar. Un error deja una presentaciÃ³n cerrable; al reejecutar se retira la anterior. Cancelar durante la preparaciÃ³n conserva la instancia anterior que ya estuviera abierta. La cancelaciÃ³n se comprueba entre operaciones; no interrumpe una peticiÃ³n HTTP en curso.

El tema predeterminado usa grafito y rojo rubÃ­, con bordes discretos y capas de sombra estÃ¡ticas sin descargas de texturas. Los controles funcionales de las pÃ¡ginas siguen pendientes de la fase de diseÃ±o acordada.

Repositorio independiente: https://github.com/clayyy333/front_sterling
Desde la raíz del repositorio: `python tests/run_tests.py`. Los módulos y catálogos se descargan exclusivamente desde este repositorio.
