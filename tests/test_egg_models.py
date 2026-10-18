"""Validate Main.lua's packed shell geometry with Python's standard library.

Run: python tests/test_egg_models.py
These checks do not replace a Roblox play test.
"""
from pathlib import Path
import json
import re
import unittest


BASELINE = {
    'Unicorn Egg': (1.86666667, 2.8, 1.63333333),
    'Kitsune Egg': (2.56666667, 2.8, 2.56666667),
    'Night Flame Egg': (2.8, 2.8, 2.79026084),
    'Archangel Egg': (2.8, 2.1, 2.79026084),
    'World Burner Egg': (2.8, 1.86666667, 2.79026084),
    'Aetheron Egg': (2.8, 2.56666667, 2.79026084),
    'Cthulhu Egg': (2.56666667, 2.8, 2.56666667),
    'Luminous Cthulhu Egg': (2.33333333, 2.8, 2.32163735),
    'Sabertooth Egg': (2.56666667, 2.8, 2.56666667),
    'Skeletal Sabertooth Egg': (2.8, 2.8, 2.79026084),
    'Octophant Egg': (2.56666667, 2.8, 2.56666667),
    'Mecha Scrambler Egg': (2.8, 2.8, 2.79026084),
}


def decode(number, widths):
    if number != int(float(number)) or not 0 <= number < 2**53:
        raise ValueError('Packed data must survive Luau double precision')
    fields = []
    for bits in widths:
        fields.append(number % (1 << bits))
        number //= 1 << bits
    if number:
        raise ValueError('Unexpected trailing packed bits')
    return fields


class EggModels(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = (Path(__file__).resolve().parents[1] / 'Main.lua').read_text(encoding='utf-8')
        section = source.split('local VOX={', 1)[1].split('\n}\n', 1)[0]
        cls.specs = {
            name: json.loads(value.replace('{', '[').replace('}', ']'))
            for name, value in re.findall(r"\['([^']+)'\]=(\{.*\}),", section)
        }

    def test_all_reference_eggs(self):
        self.assertEqual(set(self.specs), set(BASELINE))

    def test_packed_surfaces_and_solid_shells(self):
        for name, spec in self.specs.items():
            with self.subTest(egg=name):
                width, height, dx, dy, dz, palette, surfaces, shell, shell_color = spec
                for actual, expected in zip((dx, dy, dz), BASELINE[name]):
                    self.assertAlmostEqual(actual, expected, places=7)
                self.assertTrue(60 <= max(width, height) <= 64)
                self.assertTrue(1 <= len(palette) <= 40)
                self.assertTrue(all(len(c) == 4 and all(0 <= v <= 255 for v in c[:3]) and c[3] in (0, 1) for c in palette))
                self.assertEqual(len(shell_color), 3)
                self.assertLess(1 + len(shell) + 2 * len(surfaces), 6000)
                art, body = {}, {}
                for number in surfaces:
                    x, y, sx, sy, pi, depth = decode(number, (7, 7, 7, 7, 6, 5))
                    self.assertTrue(0 <= pi < len(palette))
                    self.assertTrue(1 <= depth <= 31)
                    self.assertTrue(0 <= x < x + sx <= width)
                    self.assertTrue(0 <= y < y + sy <= height)
                    for yy in range(y, y + sy):
                        for xx in range(x, x + sx):
                            self.assertNotIn((xx, yy), art)
                            art[xx, yy] = depth
                for number in shell:
                    x, y, sx, sy, depth = decode(number, (7, 7, 7, 7, 5))
                    self.assertTrue(0 <= x < x + sx <= width)
                    self.assertTrue(0 <= y < y + sy <= height)
                    for yy in range(y, y + sy):
                        for xx in range(x, x + sx):
                            self.assertNotIn((xx, yy), body)
                            body[xx, yy] = depth
                self.assertEqual(art, body, 'Every inlay needs a matching solid shell depth')
                self.assertEqual((min(x for x, y in art), max(x for x, y in art)), (0, width - 1))
                self.assertEqual((min(y for x, y in art), max(y for x, y in art)), (0, height - 1))
                self.assertEqual(max(art.values()), 31)


if __name__ == '__main__':
    unittest.main(verbosity=2)
