"""Guard Keys handlers against the Qt Quick signal API, not just QML grammar.

Signal names verified against QtQuick/plugins.qmltypes (QQuickKeysAttached).
This is portable source validation, not a full native Quickshell load.
"""
from pathlib import Path
import unittest
from test_qml_positioners import TOKENS

ROOT = Path(__file__).resolve().parents[1]
SIGNALS = set("""
    enabledChanged priorityChanged pressed released shortcutOverride
    leftPressed rightPressed upPressed downPressed tabPressed backtabPressed
    asteriskPressed numberSignPressed escapePressed returnPressed enterPressed
    deletePressed spacePressed backPressed cancelPressed selectPressed yesPressed
    noPressed callPressed hangupPressed flipPressed menuPressed
    volumeUpPressed volumeDownPressed
""".split()) | {f"digit{i}Pressed" for i in range(10)} | {f"context{i}Pressed" for i in range(1, 5)}
HANDLERS = {"on" + s[0].upper() + s[1:] for s in SIGNALS}


def invalid_keys_handlers(source):
    tokens = [(m.group(), m.start()) for m in TOKENS.finditer(source)
              if m.lastgroup not in ("skip", "string")]
    errors = []
    for i in range(len(tokens) - 3):
        names = [token for token, _ in tokens[i:i + 4]]
        if names[0:2] == ["Keys", "."] and names[2].startswith("on") and names[3] == ":":
            if names[2] not in HANDLERS:
                errors.append((source.count("\n", 0, tokens[i][1]) + 1, names[2]))
    return errors


class KeysTests(unittest.TestCase):
    def test_shell_uses_only_supported_keys_handlers(self):
        errors = []
        for path in sorted((ROOT / "quickshell").rglob("*.qml")):
            errors.extend((str(path.relative_to(ROOT)), line, handler)
                          for line, handler in invalid_keys_handlers(path.read_text()))
        self.assertEqual(errors, [])

    def test_rejects_all_four_unsupported_navigation_signals(self):
        for key in ("Home", "End", "PageUp", "PageDown"):
            with self.subTest(key=key):
                self.assertEqual(invalid_keys_handlers(f"Item {{ Keys.on{key}Pressed: go() }}"),
                                 [(1, f"on{key}Pressed")])

    def test_valid_handlers_and_examples_do_not_trigger_guard(self):
        self.assertEqual(invalid_keys_handlers('''
            // Keys.onEndPressed: invalid()
            /* Keys.onHomePressed: invalid() */
            Item {
                property string example: "Keys.onPageDownPressed: invalid()"
                Keys.onPressed: event => { event.accepted = false; }
                Keys.onReturnPressed: go()
                Quick.Keys.onReleased: event => {}
                Keys.onEscapePressed: close()
            }
        '''), [])
