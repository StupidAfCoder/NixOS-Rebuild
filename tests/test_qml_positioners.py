"""Portable source guard for Qt positioner properties that reject writes at load time.

Qt grammar parsing alone does not validate these assignments. These checks do not
replace a native Quickshell load, but prevent recurrence of the reported Flow bug.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
# Skip strings/comments before inspecting braces so examples and SVG/JS strings
# don't become fictitious QML objects. Layout-managed child Items can still set
# their own implicit size; only assignments on the positioner itself are banned.
TOKENS = re.compile(
    r'(?P<skip>\s+|//[^\n]*|/\*[\s\S]*?\*/)'
    r'|(?P<string>"(?:\\[\s\S]|[^"\\])*"|\'(?:\\[\s\S]|[^\'\\])*\'|`(?:\\[\s\S]|[^`\\])*`)'
    r'|(?P<word>[A-Za-z_$][\w$]*)|(?P<symbol>[^\s])'
)
POSITIONERS = {"Flow", "Row", "Column", "Grid"}


def implicit_size_assignments(source):
    """Return (line, positioner, property) for direct implicit-size bindings."""
    tokens = [(m.group(), m.start()) for m in TOKENS.finditer(source) if m.lastgroup != "skip"]
    owners = []
    errors = []
    for i, (token, offset) in enumerate(tokens):
        previous = tokens[i - 1][0] if i else ""
        following = tokens[i + 1][0] if i + 1 < len(tokens) else ""
        if token == "{":
            owners.append(previous if previous in POSITIONERS else None)
        elif token == "}":
            if owners:
                owners.pop()
        elif (owners and owners[-1] in POSITIONERS
              and token in ("implicitWidth", "implicitHeight")
              and previous != "." and following == ":"):
            errors.append((source.count("\n", 0, offset) + 1, owners[-1], token))
    return errors


class PositionerTests(unittest.TestCase):
    def test_shell_does_not_assign_positioner_implicit_dimensions(self):
        errors = []
        for path in sorted((ROOT / "quickshell").rglob("*.qml")):
            for line, owner, prop in implicit_size_assignments(path.read_text()):
                errors.append(f"{path.relative_to(ROOT)}:{line}: {owner}.{prop} is computed by Qt")
        self.assertEqual(errors, [])

    def test_detects_the_reported_flow_error_and_width_equivalent(self):
        source = "Flow {\n implicitHeight: childrenRect.height\n implicitWidth: childrenRect.width\n}"
        self.assertEqual(implicit_size_assignments(source),
                         [(2, "Flow", "implicitHeight"), (3, "Flow", "implicitWidth")])

    def test_all_positioners_and_qualified_types_are_checked(self):
        for owner in sorted(POSITIONERS):
            with self.subTest(owner=owner):
                self.assertEqual(implicit_size_assignments(
                    f"Quick.{owner} {{ implicitHeight: 10 }}"), [(1, owner, "implicitHeight")])

    def test_children_and_comments_are_not_positioner_assignments(self):
        source = '''
        // Flow { implicitHeight: 10 }
        Item {
            property string example: "Grid { implicitWidth: 10 }"
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: 2
                    Rectangle { implicitHeight: 20; implicitWidth: 40 }
                }
            }
            /* Column { implicitHeight: 30 } */
            Rectangle { implicitHeight: childrenRect.height }
        }
        '''
        self.assertEqual(implicit_size_assignments(source), [])


if __name__ == "__main__":
    unittest.main()
