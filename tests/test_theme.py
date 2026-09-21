import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("theme", ROOT / "scripts/generate-theme.py")
theme = importlib.util.module_from_spec(spec)
spec.loader.exec_module(theme)


class ThemeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.path = Path(self.temp.name) / "sample with spaces.png"
        Image.new("RGB", (32, 32), (150, 30, 55)).save(self.path)

    def tearDown(self):
        self.temp.cleanup()

    def test_every_recipe_final_contrast(self):
        for rgb in [(150, 30, 55), (0, 0, 0), (255, 255, 255), (20, 80, 210), (0, 90, 40), (240, 210, 0)]:
            Image.new("RGB", (32, 32), rgb).save(self.path)
            for recipe in theme.RECIPES:
                for tone in (-15, 0, 15):
                    for high in (0, 1):
                        c = theme.generate(self.path, recipe=recipe, tone=tone, contrast_level=high)
                        target = 7 if high else 4.5
                        for key in ("background", "surface", "surface_container_low", "surface_container", "surface_container_high", "surface_variant"):
                            self.assertGreaterEqual(theme.contrast(c["accent"], c[key]), target, (rgb, recipe, tone, key))
                            self.assertGreaterEqual(theme.contrast(c["on_surface_variant"], c[key]), target)
                            self.assertGreaterEqual(theme.contrast(c["on_surface"], c[key]), target)
                        self.assertGreaterEqual(theme.contrast(c["on_accent"], c["accent"]), 4.5)
                        self.assertEqual(c["accent_secondary"], c["accent"])

    def test_black_is_exact_and_neutral_is_not_recolored(self):
        Image.new("RGB", (32, 32), "black").save(self.path)
        c = theme.generate(self.path)
        self.assertEqual(c["background"], "#000000")
        self.assertTrue(c["_meta"]["neutral"])
        self.assertEqual(c["accent"][1:3], c["accent"][3:5])
        self.assertEqual(c["accent"][3:5], c["accent"][5:7])

    def test_diversity_and_determinism(self):
        c = theme.generate(self.path)
        self.assertEqual(c, theme.generate(self.path))
        self.assertNotEqual(c["accent"], theme.generate(self.path, tone=15)["accent"])
        self.assertNotEqual(c["accent"], theme.generate(self.path, saturation=.2)["accent"])
        self.assertNotEqual(c["surface"], theme.generate(self.path, recipe="tonal")["surface"])

    def test_population_not_tiny_bright_patch(self):
        image = Image.new("RGB", (100, 100), (170, 35, 45))
        image.paste((255, 240, 0), (0, 0, 10, 10))
        image.save(self.path)
        seed = theme.extract_seed(self.path)
        self.assertLess(theme.hue_distance(seed["hue"], theme.Hct.from_int(0xffaa232d).hue), 15)
        self.assertEqual(theme.hue_distance(359, 1), 2)

    def test_invalid_and_transparent(self):
        for kwargs in ({"tone": float("nan")}, {"saturation": 2}, {"contrast_level": -1}, {"recipe": "unknown"}, {"source": "unknown"}):
            with self.assertRaises(ValueError):
                theme.generate(self.path, **kwargs)
        Image.new("RGBA", (10, 10), (255, 0, 0, 0)).save(self.path)
        with self.assertRaises(ValueError):
            theme.generate(self.path)

    def test_preview_no_write_and_cli_compatibility(self):
        out = Path(self.temp.name) / "output"
        cmd = [sys.executable, str(ROOT / "scripts/generate-theme.py"), str(self.path), "dark", "0.2", "--output-dir", str(out)]
        preview = subprocess.run(cmd + ["--preview"], text=True, capture_output=True, check=True)
        self.assertEqual(json.loads(preview.stdout)["background"], "#000000")
        self.assertFalse(out.exists())
        subprocess.run(cmd, check=True)
        self.assertTrue((out / "hypr/colors.lua").exists())
        self.assertEqual(json.loads((out / "quickshell/bar/theme/colors.json").read_text())["background"], "#000000")
        before = (out / "hypr/colors.lua").read_text()
        result = subprocess.run(cmd + ["--tone", "nan"], capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((out / "hypr/colors.lua").read_text(), before)


if __name__ == "__main__":
    unittest.main()
