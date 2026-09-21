# Pixel shell — coordinated console redesign

**Review branch: `arena/01a0c316-nixos-rebuild`. Submitted for review only; do not merge or activate until native QA is complete.**

This is the revised implementation for review, **not a claim of completed native desktop QA**. The HTML preview is an illustration with sample data; it is not a remote Quickshell session. The actual implementation is in this repository's QML/Python/Nix files.

## What changed in this pass

- **Shared console controls:** cut-corner keycaps with a small raised lip, depressed click/selected states, and keyboard-only focus indication. Buttons, tabs, fields, sliders and menu rows share the geometry. Rail glyphs stay unboxed at rest. Notification silhouette, original mascot/recoloring and original Power video are retained.
- **Rail and origins:** hidden modules occupy no space. Hover the **top-center screen edge**, then click **↓ Settings**; Library search and Super+Ctrl+S also work. The optional Settings module remains available. Ordinary bar popups align to the invoking control and clamp inside the screen. Keyboard/IPC opens fall back to the focused monitor. The launcher keeps top/bottom/center placement; Settings and Power remain right-edge drawers, and the full editor stays centered.
- **Personal placement:** Settings → Bar → Placement moves any of the thirteen modules between top/center/bottom and reorders within each group. Visibility is independent of position. The horizontal `HH:mm` clock moves with other modules, with an optional short date. Workspaces use numbered empty slots and occupied-app glyphs; only Hyprland's active workspace receives the selected cap. Mouse clicks no longer retain a competing focus rectangle.
- **Library:** category pages, a scrollable cartridge grid, selected-app icon/readout and a separate Launch button. Single-click selects; double-click or Enter launches. Down from search enters the shelf; arrows browse; typing from the grid returns to search. Settings remains searchable even if every rail module is hidden.
- **Visual path picker:** image thumbnails in the local folder grid, a larger selected-image preview, and explicit Select/Cancel. Folder-only mode also shows image contents, but still confirms only the current directory. Files are not saved just by browsing. Image decode sizes are bounded; video files have a generic icon, not a video thumbnail decoder.
- **Wallpaper studio:** a full-width two-row contact sheet, then a compact preview/palette workbench. Balanced/Tinted/True black/Paper are primary choices; the other recipes and seed selector are under More palette options. Live app sync and Trash confirmations remain here, not in the quick view. Opening the editor starts with the applied/privately tried image (or an explicitly requested image).
- **Quick wallpaper selector:** no Sheet background, header, dimming layer or editing controls. Only floating photos, selected filename/status and a keyboard hint. Arrows/wheel browse, click/Enter applies (private colors only in preview), Escape/outside click closes. Right-edge dwell and Super+Ctrl+W remain. A scan restores selection by path; image clicks return keyboard control to the carousel.
- **Balanced colors:** wallpaper-derived highlights over low-chroma, lightly tinted charcoal surfaces. Surface chroma is capped at 6 rather than the vivid recipe's 36. This intentionally keeps one primary accent, not competing neon accents. **Balanced is the new-preference default only.** Explicit saved `wallpaper`/black/other recipes are preserved. `wallpaper` is labeled **Tinted**; black remains exact `#000000`.
- **Power:** video and actions only; the profile row is removed. Destructive actions still require confirmation.
- **Preserved safety/reliability:** opt-in history/workspace audio; queued directory scans and separate error channels; palette staging before wallpaper-daemon apply; per-file atomic publication and explicit partial-success reporting; preferences saved only on success/partial success. Wallust remains separate from the shell palette. Unconfirmed preview operations do not write live app themes; explicitly confirmed live sync intentionally does.

See [the design notes](CONSOLE-DESIGN.md) for references, state rules and keyboard behavior. `docs/tour/index.html` has twelve **illustrative** scenes; it is not a native desktop recording.

## Safest native preview first — no rebuild

Download the [review branch ZIP](https://github.com/StupidAfCoder/NixOS-Rebuild/archive/refs/heads/arena/01a0c316-nixos-rebuild.zip), or open the branch on GitHub and choose **Code → Download ZIP**. Unlike the earlier standalone preview bundle, this ZIP contains the full repository, including the native shell and `docs/tour/index.html`.

1. Extract into a **new directory**, not over `~/.nixos_dotfiles` or `~/.config/quickshell`. Open a terminal in the extracted repository root (the folder containing `flake.nix`, `quickshell/` and `scripts/`). Do not copy changes into your active dotfiles merely to preview: out-of-store symlinks can reload immediately.

2. In a terminal in your existing Hyprland/Wayland desktop, with your installed Quickshell and configured Python (Pillow + materialyoucolor):

   ```sh
   bash scripts/preview-shell.sh --sample-history --software-video
   ```

   `--software-video` opts into Qt FFmpeg software decoding and disables hardware texture conversion, targeting the VAAPI texture-export errors in your log. Omit it to compare normal hardware decoding. These diagnostic Qt environment variables are private APIs and are inherited by apps launched from this preview; they are **not** installed globally.

   Omit `--sample-history` to inspect honest empty states. The helper copies your display/path preferences into a private temporary directory, disables history/audio automation there, and uses separate XDG configuration/state/cache. It does **not** launch the collector or change your Nix generation. Demo history is explicitly labeled and never written to real history.

3. The helper temporarily stops `quickshell.service` if active. It refuses to run beside another manually started Quickshell; close that instance yourself if needed. **Ctrl+C in the preview terminal** stops the preview and restarts the original service only if it was previously active. It restores the service after a shell failure too. If the terminal/helper is forcibly killed and cannot clean up, use `systemctl --user start quickshell.service` yourself.

4. Open panels using the rail, or a second terminal from the same extracted directory:

   ```sh
   qs ipc --path "$PWD/quickshell/shell.qml" call settings toggle
   qs ipc --path "$PWD/quickshell/shell.qml" call wellbeing toggle
   qs ipc --path "$PWD/quickshell/shell.qml" call power toggle
   ```

   The explicit path matters: existing keybindings can target the original/default configuration, and the new bindings have not been installed by this helper.

5. **This is not an OS sandbox.** Power/session actions, wallpaper application and wallpaper Trash are blocked in preview mode. Palette generation is still available. App launching and network, Bluetooth, media, brightness and audio controls act on your real session. Notifications are handled by the preview shell while it runs. Avoid disruptive device actions if you are only reviewing appearance. Any already-running collector continues using its original settings; this preview neither starts nor stops it.

6. The helper prints a temporary directory containing `shell.log` and preview preferences. It leaves them available for debugging until you remove that directory or your runtime directory is cleared. This temporary directory is never in Git.

In Wallpaper studio, select an image, choose **Balanced**, and use **Try in preview** to recolor the real preview shell and wizard. Its palette is generated under the private cache; it does not change the live wallpaper, Firefox, terminals or compositor files.

### Testing Firefox / live app colors without a rebuild

Ordinary preview selection intentionally does **not** recolor Firefox. This is isolation, not terminal-launch detection failure.

In the full wallpaper editor, select an image, click **Sync live app colors…**, read the warning, then **Confirm live recoloring**. This is an explicit exception to preview isolation: it writes the real Wallust targets (including existing terminal and application theme files), requests Firefox refresh and signals Kitty. It does not change the live wallpaper, run Matugen, or enable the collector. These live theme changes persist after preview exits. Choose your original wallpaper and sync again to restore its colors.

The helper restores the original XDG paths **only for that child command**. No confirmed sync, no live Wallust writes. The private preview's palette operation remains separate.

Firefox must have the Pywalfox extension enabled in the profile actually in use, with a connected native host. The repository already includes the addon and native package. If the extension reports a missing host on an existing installation, run from a normal terminal:

```sh
pywalfox install --executable "$(command -v pywalfox)"
```

That writes the native messaging manifest. Reconnect the extension/restart Firefox if needed, then retry app sync. `pywalfox update` returning zero is **not** proof that the browser acknowledged a theme; inspect the browser too. Custom Firefox forks/profiles may require their own manifest path. Do not start a standalone `pywalfox start` systemd daemon as a substitute for the browser connection.

### Quick wallpaper ribbon

After activation, **Super+Ctrl+W** opens the quick view; **Super+Shift+W** retains the full editor. In a preview, use the edge/Library or:

```sh
qs ipc --path "$PWD/quickshell/shell.qml" call quickwallpaper toggle
```

Preview ribbon selections affect only the private shell palette; live mode runs the full wallpaper / shell / Wallust / GTK-Qt pipeline. The ribbon uses the recipe/tone last chosen in the editor.

To verify **live wallpaper apply, real collection, new services and terminal integration**, use the later build/activation workflow only after reviewing the source. Those side effects are deliberately not exercised by the preview helper. In the browser, open `docs/tour/index.html` (or the live Arena preview); it is an illustration, not native Quickshell output.

## Start here: a five-minute tour

### 1. The frame and your wizard

- Frame defaults to **6px**, down from 10px. Corner brackets remain; they now use the theme accent.
- Rail defaults to 44px and can be adjusted from 36–64px. Frame can be adjusted from 4–10px.
- **Your original wizard template and recoloring code are retained**, not redrawn. Its robe still takes the wallpaper accent, and generated sprites still reload from cache.
- Wizard click opens Wallpapers. Clock click opens **Your day**. The NixOS launcher now uses the theme accent rather than fixed blue. Bundled pixel icons open Settings, Sound & light and System; accessible names identify actions without hover labels.
- The rail scrolls on short screens; the media marquee becomes a small glyph. The clock/date is now horizontal. Top-center Settings access stays outside the rail, even with every module hidden.

### 2. Wallpapers: balanced color, vivid tint, or true black

Open with the wizard, `Super+Shift+W`, or:

```sh
qs ipc call wallpaper toggle
```

1. Search for a wallpaper. Click a landscape thumbnail; selection **does not apply it**.
2. The contact sheet spans the width; the preview and controls stack on narrow screens.
3. Select **Balanced**, **Tinted**, **True black**, or **Paper**. More palette options exposes neutral, tonal, expressive and mono.
4. Adjust **Tone** and **Intensity**. More palette options also exposes representative, dominant or colorful source selection.
5. The swatch strip is generated by the **actual Python generator**. Preview generation does not overwrite your live colors.
6. Click **Apply wallpaper + palette**. Recipe, tone, intensity and source preference are remembered globally for subsequent selections. Per-wallpaper remembered profiles are not implemented in this pass.
7. Wallpaper removal now goes to **Trash**, with an explicit confirmation; generation failure is never a reason to delete an image automatically.

The generator extracts **one seed**, not two unrelated accents. Every decorative accent token shares that family. Grayscale images remain neutral; no hash-derived surprise blue/purple. True-black base surfaces are exactly `#000000`, with near-black card layers for readability. Contrast corrections can limit extreme tone choices; that is intentional.

Firefox **still uses Wallust + Pywalfox**, not the shell's palette. GTK/Qt remain on their separate Matugen pipeline, now tonal-spot rather than always vibrant. The browser/terminal therefore need not match the shell's exact black background.

### 3. Launcher and connections

- **Launcher:** searchable cartridge grid, categories, selected-app readout, arrow navigation and Enter launch. Select Top, Bottom or Center under Your corner / Look. No heavy scanlines or focus-stealing timer.
- **Wi-Fi:** connected properties first, a separate scan list, then focused credential entry with reveal control. Passwords are supplied through stdin rather than command-line arguments. `Advanced…` opens NetworkManager's editor for enterprise/hidden-network configuration.
- **Bluetooth:** connected/saved devices separate from discovery, a separate nearby view, trust and confirmed forget actions. Pairing opens **Blueman** for proper PIN/passkey/agent handling rather than pretending an unsupported pairing dialog exists.
- Popups share bounds, keyboard focus, Escape and outside-click behavior. One primary popup is active at a time, on the invoking monitor (focused monitor for IPC). Utility panels align beside their rail origin; large task sheets are centered. Settings and Power instead slide from the right edge, without dimming the whole screen.

### 4. Power and notifications: deliberately familiar

**Power** opens from the right with `Super+Ctrl+P` or `qs ipc call power toggle`, and keeps the looping, muted video. Default path is still `~/Videos/pixel-traffic.mp4`.

- The profile row is gone; the video leads straight into actions.
- Lock and sleep are immediate actions.
- Logout, restart and shutdown show a confirmation, with **Keep playing focused**.
- Escape cancels confirmation before closing the menu.
- The video decoder is unloaded while hidden or in reduced-motion mode. Missing/unplayable video leaves a quiet fallback rather than removing the controls.

**Notifications retain the existing stepped silhouette and full-height colored left block.** Changes are intentionally modest:

- Theme-colored app label instead of the fixed purple label.
- Thinner right accent, responsive width and larger close target.
- Notification actions exposed, expiry seconds correctly converted to milliseconds, hover pauses timeout.
- Critical and explicitly persistent notifications do not auto-expire.
- No redesign into the earlier generic notification cards.

### 5. Your profile and live settings

Hover the top-center screen edge and click **↓ Settings**, search **Settings** in Library, use `Super+Ctrl+S`, or:

```sh
qs ipc call settings toggle
```

**Profile:** display name, short note, and a pixel file/folder picker for avatar, power video and wallpaper directory. Paths are local absolute paths; nothing is uploaded. This does not change your Linux account name or user account photo.

**Bar → Placement:** reorder and move each module between top/center/bottom; clock date is optional. **Bar → Modules:** individually toggle launcher, workspaces, clock, wizard, media, sound/brightness, system, battery/energy, network, Bluetooth, tray, power and settings. Settings and System default off; all others default on; unavailable Bluetooth hardware still hides its control. Workspace indicators: 1–10; rail width: 36–64px. Restore module defaults requires confirmation. Hiding a module does not disable its keyboard shortcut or prevent an already open panel from working.

**Look (appearance):** frame width, body font size, animation duration, reduced motion, high contrast, launcher position, link to wallpaper tone controls. Settings/Power drawers translate horizontally and the launcher can translate vertically; ordinary popups fade. Neither scales pixel text. Reduced motion makes transitions instant and pauses decorative animation/video.

**Audio:** enable the optional workspace-audio controller, then select workspaces to mute. It mutes identifiable **application playback streams**, not the microphone or the entire output device.

**Data (privacy):** opt into focused-app history, choose 1–90 day retention, set a daily reference goal, or explicitly clear local history.

Settings are stored outside Git at:

```text
~/.config/pixel-shell/settings.json
```

External JSON edits reload too. The command-line helper validates writes:

```sh
python3 ~/.nixos_dotfiles/scripts/shell-state.py patch '{"frameWidth":6,"reducedMotion":true}'
```

### 6. Your day: calendar and local history

Click the clock, press `Super+Ctrl+C`, or:

```sh
qs ipc call wellbeing toggle
```

- **Day:** selected date, focused time, reference goal and top three apps.
- **History:** 7/14/30 daily bars, period total, recorded-day average, retained-history total and calendar. Selecting a bar or date opens the Day page and aligns the calendar month. Selections outside the plotted range move its ending date.
- **Apps:** selected day or plotted range, most/least-used order, duration and percentage, bars relative to the most-used app.
- **Calendar:** Monday-first, complete week rows, selected outline and today marker. Five intensity levels: zero, up to ¼ goal, ½ goal, goal, and above goal. Thresholds stay consistent between months; labels use contrast-safe colors.
- Missing days differ from explicitly observed zero-use days. Missing dates are excluded from averages. Future calendar dates are disabled.
- No data is fabricated or backfilled; a new installation shows an honest empty state. The optional preview fixture is labeled **Sample history**.
- Recording is **off by default**. Enable it in Settings / Data.
- Counts stable focused-app intervals, not background playback or browser tabs. App **classes** only; never titles, URLs, keystrokes or screenshots.
- A small user service samples every two seconds and writes approximately every 15 seconds. Counts exclude gaps/suspend and known idle/display-off/locked intervals. Idle detection uses a Hypridle listener at five minutes; session-lock detection uses logind when available. Accuracy depends on those integrations.
- Retention pruning runs independently of whether recording is enabled. Pausing does not erase existing history. Clear history does.
- The calendar is a local date/history browser, **not** a CalDAV/event/task client in this pass.

Local data lives under `$XDG_STATE_HOME/pixel-shell` (normally `~/.local/state/pixel-shell`), with private files.

### 7. Workspace audio: what it can and cannot do

The collector uses `pactl` stream process IDs, Hyprland client workspace IDs and process ancestry. Stable stream serials prevent restoring a different stream after an index is recycled.

- Selecting workspace 2 mutes mapped streams in workspace 2, even after you focus another workspace.
- Moving a mapped window to an unmuted workspace restores a mute owned by this feature.
- Disabling the feature restores streams it muted. Pre-existing user mutes are left alone.
- A normal service stop restores its owned mutes; persisted ownership allows retry after a crash.
- **Shared-process apps on multiple workspaces, many browser-tab cases, unidentifiable/remote streams and streams without stable identity are intentionally skipped.** This is not tab-level audio routing and cannot perfectly attribute every application.
- The Settings page reports the collector's last status. No streams are modified until the feature is explicitly enabled.

### 8. Terminal and prompt

- Kitty: **Pixel Operator Mono**, solid background, block cursor, no ligatures, 12px padding, simple separated tabs.
- Foot: existing 16px pixel font retained, 12px padding, opaque theme, hard-coded teal slots removed. All sixteen ANSI colors now come from Wallust.
- Kitty gets its own mutable Wallust include and a reload signal after successful wallpaper application.
- Starship: quiet two-line pixel branches, directory/Git/context, duration only for slow commands, error status on the right. No giant identity block, permanent clock or language-module parade. Username/hostname appear when useful (root/SSH).

Illustration:

```text
┌─ ~/.nixos_dotfiles git:arena/01a0c316-nixos-rebuild ~? nix:dev
└─> █
```

## What hot-reloads?

| Change | Behavior |
|---|---|
| QML source | Quickshell's existing source reload; singleton preferences are read back from disk |
| Module visibility / workspace count / frame / rail / text size / motion | Live settings bindings; no Nix rebuild |
| Avatar / video path and watched file replacement | Reloaded by the shell; use a valid local file |
| Shell colors | Watched JSON reload after successful generation |
| Wizard colors | Existing sprite watcher; explicit regeneration plus existing systemd path unit |
| Wallpaper directory | Re-scan on directory preference change or Refresh |
| Recipe / tone / intensity / contrast | Preview before Apply; no accidental live recolor during browsing |
| History settings / workspace muting | Collector reads settings each sample |
| Firefox palette | Existing Wallust → Pywalfox update path |
| Kitty config / palette | SIGUSR1 reload after apply; full Home Manager settings require activation first |
| Foot palette | Wallust terminal sequences where supported; include read by new terminals |
| Foot font/layout / Starship declarative config | Activate Home Manager; open a new terminal/shell as needed |
| Nix packages, user units, Hypridle installation | **One rebuild/activation required**; not falsely advertised as hot-reloadable |
| Hyprland compositor animation parameters | Remain separate from shell reduced-motion settings |

## Later: review and activate the complete checkout

No configuration was activated on your desktop from this sandbox. Use the separate review branch or its ZIP to review files; merging is not required.

1. Inspect the diff on **this branch**, especially the new user service and Hypridle listener. The latter only reports idle; it adds no automatic lock or suspend policy.
2. Once these files are in your dotfiles checkout, QML edits may already reload because your configuration uses out-of-store symlinks. Save important work before testing shell changes.
3. Evaluate/build your Nix configuration first:

   ```sh
   cd ~/.nixos_dotfiles
   nixos-rebuild build --flake path:.#nixos
   ```

4. If you want to activate the new packages/services for a review session:

   ```sh
   sudo nixos-rebuild test --flake path:.#nixos
   ```

   This **does change the running system and Home Manager configuration**; it is not a dry run. It does not set the new NixOS generation as the boot default. Existing Home Manager file changes may persist across reboot. Use your normal backup/recovery workflow.

5. Inspect logs if anything does not appear:

   ```sh
   systemctl --user status quickshell pixel-shell-state hypridle
   journalctl --user -u quickshell -u pixel-shell-state -n 100 --no-pager
   ```

6. If needed, restart only the shell/collector after activation:

   ```sh
   systemctl --user restart quickshell pixel-shell-state
   ```

To stop collection/audio automation without discarding data, disable both controls in Settings; or stop `pixel-shell-state.service` (normal shutdown attempts to restore owned mutes). Revert files selectively from your own backup if you want the old shell; no automated destructive Git reset is recommended.

## Validation performed here

- **51 Python tests pass**, including a multi-recipe/color/tone/contrast matrix, exact black and grayscale, single-accent compatibility, deterministic extraction, tiny-patch rejection, preview non-mutation, failed-generation preservation, settings validation, private atomic files, daily retention, corrupt-history recovery, module schema/deep merging/concurrent writers, and audio ownership/recycled stream safety. Stubbed preview-helper tests verify isolation, private palette/mascot initialization, root/video environment, duplicate refusal, and service restoration after successful and failed shell exits. Additional source contracts guard filesystem resolution, pure icon bindings, grouped tray controls, decoder lifetime, content sizing, recovery access, path picker/edge registration and launcher schema. Apply integration tests run the real apply script and generator in a copied fixture, with all desktop commands stubbed, covering pre-apply failure preservation and partial-success reporting. Stubbed Wallust integration checks cover explicit config selection, restored preview XDG paths, blocked unconfirmed writes, normal sync and failure/malformed-cache handling.
- Four source-guard tests prevent assigning `implicitHeight`/`implicitWidth` on Qt positioners (`Flow`, `Row`, `Column`, `Grid`). This catches the native startup failure reported during the first review; grammar parsing alone did not catch it.
- **19 Node tests pass**, covering the actual QML JavaScript date/sanitization/aggregation/heat/ranking helpers, selection/scan/apply logic, rail placement, library filtering and actual popup-manager routing. Popup geometry is tested at both edges and on short screens. Repeated in Asia/Kolkata and America/New_York timezones.
- **75 QML files** parse using Qt's `qmlformat`. Explicit `qmldir` registrations added for custom singletons.
- `qmllint` inspected; corrected a SystemTray type-name collision and a Button `action` name collision. Full type validation is limited by missing native Quickshell modules.
- **11 Nix files** parse with the Nix tree-sitter grammar. **No full Nix module evaluation or build** in this sandbox.
- Bash syntax checks cover all eleven shell scripts. The seven core rice scripts (apply, preview, Wallust sync, theme toggle, brightness, system stats and asset generation) also pass ShellCheck. The unrelated recording helper has a pre-existing `ls | grep` warning and is untouched.
- Quickshell API declarations inspected for MPRIS controls, notification timeout units/actions, Process stdin, focused-monitor routing, IconImage status/asynchronous aliases and IPC path selection. All statically named bundled icons exist.
- The revised HTML tour has **12 illustrative scenes**, with cartridge selection/search, thumbnail picker, compact editor, background-free ribbon, rail placement, wireless flow, Day/History/Apps and safe session confirmations. Five DOM regression tests cover these transitions. It is not an exhaustive replica of native Settings or a hardware test.
- The HTML tour is a safe mockup. An attempted offscreen native Qt render was blocked by unavailable system graphics libraries; **no native screenshots or native animation claims** are presented.

Run Python tests locally with Pillow and materialyoucolor installed:

```sh
python3 -m unittest discover -s tests -v
node --test tests/test_usage_math.cjs tests/test_collection_state.cjs tests/test_console_layout.cjs
# Optional HTML illustration tests, with jsdom available on NODE_PATH:
node --test tests/test_tour.cjs
```

## First native review: startup fix

The first local run of review commit `d23141a` stopped at
`NotificationCard.qml: Invalid property assignment: "implicitHeight" is a read-only property`.
The `NotificationManager unavailable` messages were cascading failures, not missing packages.

The fix removes eleven manual `implicitHeight: childrenRect.height` assignments from
`Flow` containers in eight components. Qt computes Flow's implicit size itself, including
wrapped action buttons. A source regression guard covers the other Qt positioner types too.
This fix does not establish that the remaining native startup or hardware checks pass.

## Native log issues addressed in the console revision

The failed settings writes were **not** intentional preview isolation. Quickshell's virtual QML URLs had been treated as filesystem paths, so helper commands could not reach the checkout. `shellPath` / the helper's explicit root now supply real paths. Icon loading had a separate binding-loop hazard; it now stores SVG text on load and keeps the image-source binding pure. Preview initialization also supplies private status/history/current-wallpaper and mascot files before startup.

The VAAPI texture-export warnings are a separate video/driver path. The `--software-video` option is an explicit workaround to test, not a claim that your driver has been repaired. Power releases its player while closed. We have not established the cause or impact of all PipeWire warnings: test actual playback, volume and device switching rather than assuming every warning is harmless.

## Native QA still required before merge or activation

- [ ] Top-center Settings reveal has no reserved rail gap and remains reachable with all modules hidden.
- [ ] Move/reorder every module; switch workspaces by mouse then keyboard: only the compositor-active slot remains selected.
- [ ] Open network/audio/Bluetooth/energy beside their bar origins, including bottom-edge clamping and second-monitor transfer.
- [ ] File picker thumbnails and selected-image preview render; it navigates nested/spaced paths, selects images/videos/folders, cancels without writes and restores Settings focus.
- [ ] Right-edge ribbon opens only after dwell, stays closed until pointer re-entry, scrolls/selects, and routes to the invoking monitor.
- [ ] Balanced is restrained on varied wallpapers; Tinted still colors all surfaces; black remains exact black. Existing saved choices survive.
- [ ] Quick selector has no panel background and arrow navigation survives clicks/refreshes; full editor opens the applied image.
- [ ] Confirmed live app sync changes Firefox with its extension connected; unconfirmed preview operations leave live targets untouched.
- [ ] Shell starts without QML binding/type errors on your pinned Quickshell revision.
- [ ] Your corner and Power enter/exit from the right; Escape cancels a pending power action before closing.
- [ ] In the preview, change frame/bar width, font and module switches: the visible shell must update, and private `config/pixel-shell/settings.json` must change without helper errors. Restart against that same private state to check persistence.
- [ ] Try a wallpaper palette in the preview: real rail/wizard recolor; live wallpaper/Firefox/terminal files remain untouched.
- [ ] Library top/bottom/center, empty search, arrows/Enter and launch are correct.
- [ ] Third-party tray entries expand, activate and open their nested menus without magenta textures.
- [ ] Rapid module toggles/sliders persist after restart; hiding all modules leaves Settings reachable.
- [ ] Graph period/day/range/sort controls agree with calendar and displayed totals; missing days and recorded zero look distinct.
- [ ] All panels fit your screen, 125%/150% scaling and portrait; large collections scroll.
- [ ] Escape, outside click, search focus, Tab/arrow navigation; popup only on invoking/focused monitor.
- [ ] Wizard recolors; notification silhouette/actions/timeouts match expectations.
- [ ] Your actual video decodes/loops, unloads while hidden and works with/without software-video; avatar reloads.
- [ ] Light/dark/tone combinations look good on **your** problematic wallpapers.
- [ ] Wi-Fi saved/password/failed/offline and enterprise manager flows.
- [ ] Bluetooth discovery, connect/disconnect and Blueman passkey flow.
- [ ] Media seekability/live streams and player switching; battery/no-battery systems.
- [ ] Brightness/DDC, mute and transient feedback on your hardware.
- [ ] Usage pause/idle/midnight/retention; workspace audio's shared-browser limitation.
- [ ] Firefox/Foot/Kitty updates; Starship in normal, error, Git, SSH and Nix-shell contexts.
- [ ] Smoothness/frame pacing with your compositor/GPU. No system can guarantee this from static code review.

**Please review this pass before merging or activating it.** Useful feedback: card size/density, which accent/tone results feel wrong, whether the 6px frame feels right, and any shell journal errors.
