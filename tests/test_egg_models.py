"""Check appearance data and guard the original 3D shell against changes.

Run: python tests/test_egg_models.py
No external dependencies. A Roblox play test is still required for lighting.
"""
from pathlib import Path
import hashlib
import json
import math
import re
import unittest


def decode(number, widths):
    if not 0 <= number < 2**53 or int(float(number)) != number:
        raise ValueError('Data loses precision in Luau')
    result = []
    for bits in widths:
        result.append(number % (1 << bits))
        number //= 1 << bits
    if number:
        raise ValueError('Unconsumed packed bits')
    return result


def tables(source, name):
    section = source.split('local '+name+'={', 1)[1].split('\n}\n', 1)[0]
    return {name: json.loads(value.replace('{', '[').replace('}', ']'))
            for name, value in re.findall(r"\['([^']+)'\]=(\{.*\}),?", section)}


class EggAppearance(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = (Path(__file__).resolve().parents[1]/'Main.lua').read_text(encoding='utf-8')
        cls.surfaces = tables(cls.source, 'EGG_SURFACE')
        cls.vox = tables(cls.source, 'VOX')

    def test_original_shell_geometry_is_preserved(self):
        s = self.source
        vox = s[s.index('local VOX={'):s.index('local function pullBits', s.index('local VOX={'))]
        self.assertEqual(hashlib.sha256(vox.encode()).hexdigest(),
                         '69a01805d0ecadb7275fc2c8c0def5c7339f02cbb5f79e29e79e690400750a9f')
        start = s.index('local function buildVox(name)')
        end = s.index('    for i = 1, #cols do', start)
        self.assertEqual(hashlib.sha256(s[start:end].encode()).hexdigest(),
                         'b978d6d6140a27c336f07dac105adf32dfbdef100e78154c2e9c345983a3fcde')
        build = s[start:s.index('local function nightPet()', start)]
        self.assertIn("Vector3.new(stud,stud,depth)", build)
        self.assertIn("CFrame.new(px,py,0)", build)
        self.assertNotIn('LuminousInlay', build)
        self.assertNotIn('ReferencePanel', build)
        self.assertNotIn('Instance.new(\'WedgePart\')', build)
        self.assertEqual(build.count("part(m,'Shell'"), 1)
        self.assertIn('return finalize(m, root)', build)
        self.assertIn('gui.AlwaysOnTop=false', s)
        self.assertIn('gui.ZOffset=0', s)
        self.assertEqual(set(self.surfaces), set(self.vox))
        self.assertEqual(len(self.surfaces), 12)

    def test_paint_coverage_and_per_egg_emission(self):
        for name, spec in self.surfaces.items():
            with self.subTest(egg=name):
                w, h, palette, packed = spec
                self.assertEqual(max(w, h), 96)
                self.assertEqual(len(palette), 64)
                self.assertTrue(all(len(c)==3 and all(0<=v<=255 for v in c) for c in palette))
                cells = {}
                for n in packed:
                    x,y,sx,sy,pi,lit = decode(n, (7,7,7,7,6,1))
                    self.assertTrue(0<=x<x+sx<=w and 0<=y<y+sy<=h)
                    self.assertTrue(0<=pi<64 and lit in (0,1))
                    for yy in range(y,y+sy):
                        for xx in range(x,x+sx):
                            self.assertNotIn((xx,yy),cells)
                            cells[xx,yy] = lit
                self.assertEqual(len(cells),w*h)
                fraction = sum(cells.values())/(w*h)
                if name in ('Unicorn Egg','Kitsune Egg'):
                    self.assertEqual(fraction,0)
                else:
                    self.assertTrue(.001<fraction<.12, (name,fraction))

    def test_surface_paint_clips_to_existing_parts(self):
        # Front and rear use identical clipping and occupy zero physical depth.
        # Check every cell of every possible legacy shell row/column layout.
        for name, spec in self.surfaces.items():
            w,h,palette,packed = spec
            rects = [decode(n,(7,7,7,7,6,1)) for n in packed]
            ow,oh = self.vox[name][:2]
            dw,dh = max(6,int(ow*12/max(ow,oh)+.5)),max(8,int(oh*12/max(ow,oh)+.5))
            bins = [[] for _ in range(h)]
            for r in rects:
                for y in range(r[1],r[1]+r[3]): bins[y].append(r)
            for iy in range(dh):
                for ix in range(dw):
                    x0,x1 = ix*w/dw,(ix+1)*w/dw
                    y0,y1 = (dh-iy-1)*h/dh,(dh-iy)*h/dh
                    seen=set(); area=0
                    for y in range(math.floor(y0),min(h,math.ceil(y1))):
                        for r in bins[y]:
                            key=tuple(r)
                            if key in seen: continue
                            seen.add(key)
                            l,t = max(x0,r[0]),max(y0,r[1])
                            right,bottom = min(x1,r[0]+r[2]),min(y1,r[1]+r[3])
                            if right>l and bottom>t:
                                u,v=(l-x0)/(x1-x0),(t-y0)/(y1-y0)
                                sx,sy=(right-l)/(x1-x0),(bottom-t)/(y1-y0)
                                self.assertTrue(-1e-9<=u<u+sx<=1+1e-9)
                                self.assertTrue(-1e-9<=v<v+sy<=1+1e-9)
                                area+=sx*sy
                    self.assertAlmostEqual(area,1,places=8,msg=(name,ix,iy))


if __name__=='__main__':
    unittest.main(verbosity=2)
