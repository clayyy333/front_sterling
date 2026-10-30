"""Run Sterling's isolated Lua checks: python front_sterling/tests/run_tests.py."""
from pathlib import Path
import hashlib
import json
import re

from lupa.lua55 import LuaRuntime


def main():
    root = Path(__file__).resolve().parents[1]
    sources = {
        path.relative_to(root).as_posix(): path.read_text(encoding="utf-8-sig")
        for path in root.rglob("*.lua")
    }
    # Test runtime is Lua 5.5; production modules retain their Luau syntax.
    compiled_sources = {
        name: re.sub(r"([A-Za-z_][A-Za-z_0-9.]*)\s*([+*/%-])=\s*", lambda m: m[1] + "=" + m[1] + m[2], source)
        for name, source in sources.items()
    }
    for source in compiled_sources.values():
        LuaRuntime().execute("assert(load(...))", source)
    lua = LuaRuntime()
    manifest = lua.execute(sources["modules/manifest.lua"])
    paths = [path for group in ("core", "legacy", "adapters", "features") for path in manifest[group].values()] + [manifest["start"]]
    for module in paths:
        assert f"modules/{module}.lua" in sources, f"Missing module: {module}"
    LuaRuntime().execute(
        sources["tests/loader_spec.lua"], sources["modules/core/loader.lua"],
        sources["modules/core/lifecycle.lua"], sources["modules/core/features.lua"],
    )
    lua = LuaRuntime()
    lua.execute(sources["tests/interface_spec.lua"], lua.table_from(compiled_sources))
    movement_lua = LuaRuntime()
    movement_lua.execute(sources["tests/movements_spec.lua"], movement_lua.table_from(compiled_sources))
    LuaRuntime().execute(sources["tests/vehicle2_auto_spec.lua"], sources["modules/adapters/vehicle2_auto.lua"])
    LuaRuntime().execute(sources["tests/static_noclip_anchor_spec.lua"], sources["modules/player/static_noclip_anchor.lua"])
    LuaRuntime().execute(
        sources["tests/mobile_fall_guard_spec.lua"], sources["modules/player/mobile_fall_guard.lua"],
        compiled_sources["modules/player/mobile_anchor_v13.lua"],
    )
    for entry in json.loads((root / "modules/copied_sources.json").read_text(encoding="utf-8")):
        copied = root / entry["copy"]
        assert hashlib.sha256(copied.read_bytes()).hexdigest() == entry["sha256"], f"Copied engine changed: {copied}"
    print(f"Sterling: {len(sources)} Lua files parse; manifest and simulated startup checks passed")


if __name__ == "__main__":
    main()
