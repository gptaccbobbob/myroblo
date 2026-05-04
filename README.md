# myroblo

A Roblox tycoon starter built with **Rojo + Wally + Roact + ProfileService**.

Out of the box you get:

- Per-player tycoon plot generated when each player joins.
- Currency (`Cash`) saved across sessions via ProfileService (DataStore-backed, session-locked, anti-dupe).
- A working dropper → conveyor → collector flow.
- A buy button to upgrade the starter dropper to an iron dropper.
- A Roact-driven HUD: live cash counter + toast notifications.
- Selene + Stylua + Lune wired into GitHub Actions CI.

## Prerequisites (one-time setup)

1. **Roblox Studio** with the **Rojo plugin v7.6.1** installed.
2. **Rokit** — toolchain manager ([install instructions](https://github.com/rojo-rbx/rokit#installation)). On Windows:
   ```powershell
   irm https://github.com/rojo-rbx/rokit/releases/latest/download/install.ps1 | iex
   ```
   On macOS/Linux:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
   ```
   Restart your terminal after install.

## First-time project setup

```bash
git clone https://github.com/gptaccbobbob/myroblo
cd myroblo

# Install Rojo, Wally, Selene, Stylua, Lune at the versions pinned in rokit.toml
rokit install

# Install Wally dependencies (Roact, ProfileService, Promise, Signal)
wally install
```

## Day-to-day workflow

1. **Start the Rojo server** (in the repo root):
   ```bash
   rojo serve
   ```

2. **In Roblox Studio:**
   - Open a new Baseplate (or your existing place file).
   - Click the **Plugins** tab → **Rojo** → **Connect**.
   - The first time you connect, Studio will ask for **script injection permission** — grant it.
   - Studio will sync everything from `src/` into the place tree.

3. **Test the game.**
   - Press **F5** ("Play" button). You should:
     - Spawn on a tycoon plot with your name on a sign.
     - See a yellow dropper, a green collector, and a red buy button.
     - Watch your `Cash` go up automatically as drops reach the collector.
     - Step on the red button to buy the iron dropper (costs 100).

4. **Edit code** in your editor of choice — VS Code with `luau-lsp` is recommended.
   Rojo will hot-sync changes into Studio. **You do not need to restart the place** to pick up code changes; just stop and re-Play.

5. **Save the place** (`File → Save to File`) to keep your map / GUI / non-code edits between sessions. The place file (`.rbxlx`) is not version-controlled — only your code is.

## Project layout

```
myroblo/
├── src/
│   ├── server/              → ServerScriptService.Server
│   │   ├── main.server.luau            (entry Script)
│   │   ├── PlayerDataService.luau      (ProfileService wrapper, leaderstats)
│   │   ├── TycoonService.luau          (per-player plot spawning)
│   │   └── Tycoon/
│   │       ├── Dropper.luau
│   │       ├── Collector.luau
│   │       └── BuyButton.luau
│   ├── shared/              → ReplicatedStorage.Shared
│   │   ├── Config/
│   │   │   ├── Tycoon.luau             (purchasable items catalog)
│   │   │   └── PlayerDataTemplate.luau (default profile schema)
│   │   └── Network/
│   │       └── Remotes.luau            (lazy RemoteEvent definitions)
│   └── client/              → StarterPlayer.StarterPlayerScripts.Client
│       ├── main.client.luau            (mounts the Roact tree)
│       └── UI/
│           ├── App.luau
│           ├── CurrencyDisplay.luau
│           └── NotificationToast.luau
├── tests/
│   └── run.luau              (Lune smoke tests for config integrity)
├── default.project.json      (Rojo project tree)
├── rokit.toml                (toolchain versions)
├── wally.toml                (package dependencies)
├── selene.toml / stylua.toml (lint + format config)
└── .github/workflows/ci.yml  (CI: format check, lint, tests, build)
```

## Adding new tycoon items

Edit [`src/shared/Config/Tycoon.luau`](src/shared/Config/Tycoon.luau) and add a new entry:

```lua
{
    id = "diamond_dropper",
    name = "Diamond Dropper",
    price = 25_000,
    requires = { "gold_dropper" },
    kind = "dropper",
    dropAmount = 100,
    dropInterval = 1.5,
},
```

Then either:
- **(Quick path)** Update `TycoonService.buildPlotForPlayer` to spawn a part with the matching `ItemId` attribute and the `BuyButton` tag, so the item can be purchased.
- **(Recommended path, see below)** Place a part in your Studio plot template and tag it.

## Building a custom plot in Studio

The auto-generated plot is just a starter. Once you want a real layout:

1. In Studio, build your plot as a single `Model` containing all the parts.
2. Tag parts using the **Tag Editor** plugin (or `CollectionService:AddTag`):
   - **`Dropper`** — set attribute `ItemId` to a dropper-kind item id from the catalog.
   - **`Collector`** — any part. Drops touching it credit cash to the plot's owner.
   - **`BuyButton`** — set attribute `ItemId` to the item this button purchases.
3. Save the model into `ReplicatedStorage` as `TycoonTemplate`.
4. In `TycoonService.buildPlotForPlayer`, replace the programmatic part-creation with a `template:Clone()` and reposition by `plotIndex`.

The runtime listeners in `Dropper.luau`, `Collector.luau`, `BuyButton.luau` automatically pick up any parts with the right tags — including ones you add later in Studio.

## Linting / formatting / tests

```bash
# Format check (CI fails if anything is unformatted)
stylua --check src tests

# Apply formatting in place
stylua src tests

# Lint
selene src

# Unit tests (config validation)
lune run tests/run

# Build a .rbxlx file without Studio (sanity check the project)
rojo build --output build.rbxlx default.project.json
```

CI runs all of the above on every PR.

## Notes / caveats

- **DataStore in Studio**: ProfileService transparently uses a **mock** store in Studio when API access is disabled. This means data does NOT persist between Studio sessions unless you go to **Game Settings → Security → Enable Studio Access to API Services**. In a published place, persistence works automatically.
- **First publish**: To save data in a published place, the place must be saved to Roblox.com (not just to file) and the experience needs to allow API access.
- **Roact 1.x** is used for compatibility and ecosystem maturity. If you want hooks-style state, consider migrating to React-Lua (`jsdotlua/react`) later — the App.luau pattern stays mostly the same.
- **`.rbxlx` files** (place files containing your map / GUI / non-code instances) are NOT in git by design. Code lives in git; place files live with you and are republished to Roblox via Studio.

## License

MIT
