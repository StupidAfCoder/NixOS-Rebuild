# Console pass: interaction before decoration

This is an implemented design direction for review, not native QA sign-off.
The browser tour uses sample applications, procedural placeholder landscapes and fake devices.
It never launches apps or controls the desktop. The QML implementation uses the real local data.

## References and what was borrowed

- [Serpantinum](https://github.com/ilyamiro/serpantinum): inspected its SideBar module layout source. Borrowed the separation into configurable groups and the restraint of a narrow rail, **not** its rounded pill styling or assets.
- [TWiLight Menu++ controls and themes](https://www.gamebrew.org/wiki/TWiLight_Menu++): directional selection and a separate launch action informed the shelf/selection/launch model. [1](https://www.gamebrew.org/wiki/TWiLight_Menu++)
- [MinUI Menu adaptation](https://github.com/anthonycaccese/minui-menu-es-de): useful counter-reference for readable names and restrained navigation; its list and optional-art variants informed the selected-item readout. The result here is deliberately a cartridge grid, not a reskinned list. [1](https://github.com/anthonycaccese/minui-menu-es-de)

No external artwork, fonts or reference project code was copied during this pass. Existing bundled icon/font licenses are unchanged.

## Layouts

```
Rail:          Library:                       Wallpaper studio:
[launcher]     search                         search / refresh
[◇ ◈ ◆]       All / Games / Create / Tools    [full-width contact sheet]
               selected-app | cartridge       image + apply | recipe / tone
[wizard]       readout      | grid             + swatches    | intensity
[media]        Launch       | scroll           advanced / live sync / Trash
[09/41]        position count

[utilities]    Quick wallpapers: floating images + outlined text + scrubber
[power]        (transparent parent, no editor controls or backdrop)
```

The Settings reveal is at the top-center **screen edge**, outside the rail layout.
Hidden modules are not transparent placeholders. Saved visibility and placement are separate.

Utility popup coordinates are captured in the clicked control's **window-local** coordinate
system. The relevant axis follows that origin (Y on vertical rails, X on horizontal rails), with four-edge frame-safe clamping. No origin is
carried into a subsequent keyboard/IPC open. Clicking an already-open module on another
monitor transfers it instead of closing an unseen popup. Drawers retain their edge direction;
launcher positioning remains a user preference.

## Control states

- Idle rail: glyph only; normal form/action buttons: low-contrast raised keycap.
- Hover: brighter face and a highlighted one-pixel top lip.
- Press: face/content move two pixels; no blurry shadow or scale animation on text.
- Selected: depressed cap, accent edge and accent ink. Workspace selection comes only
  from Hyprland; mouse focus cannot leave a second active-looking outline.
- Keyboard focus: explicit accent outline; disabled controls are dimmed and cannot act.
- Selected/hover faces use validated palette surface roles, not an untested accent blend.
  The palette tests cover the 4.5:1/7:1 text targets on every such surface.

## Keyboard paths

| View | Behavior |
| --- | --- |
| Library | Search gets initial focus; Down enters shelf; arrows select; Enter launches; type from shelf to resume search; Tab reaches categories/Launch; Escape closes. |
| File browser | Tab to grid, four arrows navigate/preview, Enter opens folder/selects file, Backspace goes up; Select confirms; Escape/Cancel returns without saving. Image preview is not a confirmation. |
| Wallpaper studio | Down from search enters contact sheet; arrows select/preview; Page Up/Down and Home/End navigate the collection; the persistent scrollbar supports direct mouse dragging; Tab reaches palette/sliders/actions; Escape closes. |
| Quick wallpaper | Arrows/wheel browse; Page Up/Down jumps ten images, Home/End reach the ends; mouse scrubber jumps directly; Enter/click applies; Escape/outside click closes. Drag selection is retained after release. |
| Workspaces | Arrows inspect tiles, Enter/Open switches; Tab reaches window focus/move actions; Escape cancels a move before closing. Super+Ctrl+E after activation, or Library/IPC in preview. |
| Power | Destructive actions enter confirmation and focus the safe choice; Escape cancels first. |
| Settings | Tab operates buttons/sliders, including placement. Launcher search and Super+Ctrl+S are recovery paths. |

Changing palette controls in the editor only generates a preview until Apply/Try is pressed.
**Sync live app colors** is a separate, confirmed Wallust operation; it is not a promise that
Firefox acknowledged the refresh or that its palette exactly matches the shell's recipe.

## Async selection rules

An installed-app refresh preserves the selected **desktop-entry ID**, not its row number or
name. A new search/category deliberately resets selection. Wallpaper preview completion is
revision-checked: closing the editor or clearing its selection invalidates old work without
interrupting an explicit Apply/Try. Global editor closure is distinct from hiding one screen's
content instance during monitor transfer.

Trash owns its captured path until completion and blocks competing in-shell apply/try/sync
jobs. Only a successful completion clears a matching selection. Failed/refused deletion and
selection of a different image never optimistically erase the user's current choice.

Nested tray menus retain their parent screen, since their coordinates are window-local.

## Deliberate limits / native checks

- Image picker decodes images at bounded preview sizes; it does not generate video thumbnails.
- Long collections scroll and sheets remain screen-bounded. Fractional scale, small/portrait
  displays, mouse/keyboard focus, top-edge input masks and compositor fullscreen behavior
  still need native testing.
- Reduced motion uses the existing zero-duration setting and stops animated/video content
  where already supported. No performance claim is based on this browser illustration.
- Quickshell/Hyprland, Nix evaluation and real wallpaper/audio/network/Firefox operations
  cannot be run in this sandbox. Qt grammar and source/JS tests are not substitutes.

## Final rail refinement

Settings → Bar adds all four edges, 35–100% background opacity and opt-in blur.
The saved layout keys remain `top/middle/bottom` for compatibility; horizontal rails
present them as Start/Center/End. Inactive gems and the date use the wallpaper accent,
including Balanced. Empty/occupied/active gems use outline/core/full sprites rather than numbers.
A focused workspace beyond the slot limit replaces only the last visible slot; the manager
still lists every compositor workspace, including named and special spaces across monitors.

The quick wallpaper edge is click-only. The full contact sheet has a persistent draggable
scrollbar; the transparent carousel adds a scrubber, not palette/editor controls.

Blur uses a separate **static namespace**, selected by replacing the frame component, not
by changing an already-connected layer's namespace. Singleton backends and struts outlive
that replacement; Settings retains its tab. Other ephemeral widget state may reset.
`ignore_alpha = 0.2` excludes the transparent desktop and the editor's 0.15 scrim, while
rail opacity cannot fall below 0.35. Normal preview does not install compositor rules: without the
new rule only transparency is visible. The explicit `--preview-blur` option installs
a uniquely scoped session rule, starts private opacity at 80%, and disables its
rule on exit. It never edits files or turns on globally disabled blur. Native composition/input validation remains pending.

API references: [Quickshell layershell declaration](https://github.com/quickshell-mirror/quickshell/blob/master/src/wayland/wlr_layershell/wlr_layershell.hpp),
[Hyprland Lua dispatchers](https://wiki.hypr.land/Configuring/Basics/Dispatchers/),
Hyprland Lua layer rules [2](https://wiki.hypr.land/Configuring/Basics/Window-Rules/).

## Native-review adjustments

Middle placement uses `RailGeometry.arrange`: center in the full axis, clamp only
against occupied end groups, extend the scrollable axis if needed. Hiding end
modules therefore no longer changes an otherwise feasible center.

The date is a small pixel calendar with the same Silkscreen face as the time.
The overview icon can be hidden separately; a delayed last-gem hover offers
Yes/Not now outside the clipped rail, with its own input region and exit grace.

The contact sheet's scrollbar is a sibling of the GridView, not its attached
control inside another ScrollView. The mouse grab is protected from ancestor
Flickables, and pointer-to-content mapping keeps the initial thumb offset.
The quick strip has no filename caption; status/errors remain.

One optional window preview is active only while Workspaces is shown. Its lazy
capture component uses the window's Wayland handle, fits aspect ratio and has an
unavailable fallback. Nothing is written to disk or included in activity history.
The external network editor uses a start handshake before the shell releases
exclusive input; missing packages and process failures are surfaced in the panel.
