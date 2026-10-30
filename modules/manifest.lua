-- Add future flows under features; the entry point never needs their names.
return {
    version = 1,
    startupCatalogs = {
        {id="data/emotes",path="modules/movements/data/emotes.lua",label="Cargando emotes"},
        {id="data/animations",path="modules/movements/data/animations.lua",label="Cargando paquetes de animación"},
    },
    core = {
        "core/lifecycle", "core/config", "core/services", "core/storage",
        "ui/theme", "ui/components", "ui/controls", "core/features", "core/legacy_context", "ui/window", "ui/navigation",
    },
    legacy = {
        "player/anchor", "player/anchor_force_return", "player/static_noclip_anchor",
        "player/mobile_fall_guard", "player/mobile_anchor_v13", "player/fling2_efficient",
        "player/fling2_auto", "player/fling_return_guard", "player/contact_fling",
        "player/contact_fling_adjustable", "player/fling_car2_delta", "player/fling_car2_xeno",
        "player/xeno_fling_replication_assist",
        "player/spectator_camera", "player/flight_control", "player/movement_control",
    },
    adapters = {"adapters/flows", "adapters/vehicle2_auto", "adapters/movements", "player/continuous_jump"},
    features = {"features/home", "features/movements", "features/volar", "features/ancla", "features/control", "features/settings", "features/interface", "ui/playback"},
    start = "core/start",
}
