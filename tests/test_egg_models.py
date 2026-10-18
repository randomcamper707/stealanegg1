"""Validate the shipped solid egg designs. Run: python tests/test_egg_models.py.

Standard library only. This validates data/geometry and rejects image-based
rendering regressions; it does not substitute for a Roblox lighting/play test.
"""
from pathlib import Path
import math
import re
import unittest


class LiteralReader:
    """Read the declarative Lua design table without executing source code."""
    pattern=re.compile(r"\s*(?:(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)|'([^'\\]*(?:\\.[^'\\]*)*)'|([A-Za-z_][A-Za-z_0-9]*)|(.))",re.S)
    def __init__(self,text):
        self.tokens=[]
        for m in self.pattern.finditer(text):
            number,string,ident,punct=m.groups()
            if number is not None:self.tokens.append(('number',float(number)))
            elif string is not None:self.tokens.append(('string',string.replace("\\'","'")))
            elif ident is not None:self.tokens.append(('ident',ident))
            else:self.tokens.append((punct,punct))
        self.i=0
    def pop(self,kind=None):
        tok=self.tokens[self.i];self.i+=1
        if kind and tok[0]!=kind:raise ValueError((kind,tok))
        return tok
    def read(self):
        if self.tokens[self.i][0]!='{':return self.pop()[1]
        self.pop('{');array=[];mapping={}
        while self.tokens[self.i][0]!='}':
            if self.tokens[self.i][0]=='[':
                self.pop('[');key=self.read();self.pop(']');self.pop('=');mapping[key]=self.read()
            elif self.tokens[self.i][0]=='ident' and self.tokens[self.i+1][0]=='=':
                key=self.pop()[1];self.pop('=');mapping[key]=self.read()
            else:array.append(self.read())
            if self.tokens[self.i][0]==',':self.pop(',')
            elif self.tokens[self.i][0]!='}':raise ValueError('Missing comma')
        self.pop('}')
        if array and mapping:raise ValueError('Unexpected mixed table')
        return mapping if mapping else array


EXPECTED={
    'Unicorn Egg':{'IvoryHorn','CrystalPrism','CrystalPoint','PearlVein'},
    'Kitsune Egg':{'FoxTail','TailTuft','ForeheadSigilGem','FoxEye','FoxCheekFlame','UpperPinkMark','ShellEmboss'},
    'Night Flame Egg':{'BarkPanel','GoldenPinion','IvyLeaf','EmberHeartGem'},
    'Archangel Egg':{'Feather','FeatherQuill','Halo','HolyRuneStem'},
    'World Burner Egg':{'BatMembrane','ChainLink','DemonHorn','BurnerSigil'},
    'Aetheron Egg':{'DualArmor','CrownHorn','Feather','RadiantSigil'},
    'Cthulhu Egg':{'CurledTentacle','TentacleSucker','CarvedStone','EyeRune'},
    'Luminous Cthulhu Egg':{'CurledTentacle','TentacleSucker','CrownLamp','EyeRune'},
    'Sabertooth Egg':{'VolcanicPlate','MagmaFacet','IvoryHorn','Furnace'},
    'Skeletal Sabertooth Egg':{'BonePlate','SaberFang','SkullBrow','AmberEye'},
    'Octophant Egg':{'CageRail','EnergyCoil','RailRivet','PowerWindow'},
    'Mecha Scrambler Egg':{'CageRail','EnergyCoil','RailRivet','PowerWindow'},
}


class SculptedEggs(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source=(Path(__file__).resolve().parents[1]/'Main.lua').read_text(encoding='utf-8')
        table=cls.source.split('local EGG_DESIGNS=',1)[1].split('\nlocal EGG_MATERIALS=',1)[0].strip()
        reader=LiteralReader(table)
        cls.designs=reader.read()
        if reader.i!=len(reader.tokens):raise ValueError('Unparsed model data')

    def test_all_twelve_have_distinct_sculpted_features(self):
        self.assertEqual(set(self.designs),set(EXPECTED))
        for name,design in self.designs.items():
            with self.subTest(egg=name):
                labels={p[1] for p in design['parts']}
                self.assertTrue(EXPECTED[name]<=labels,EXPECTED[name]-labels)
                self.assertEqual(design['parts'][0][1],'EggShell')
                self.assertEqual(design['parts'][0][0],'box')
                self.assertIn('OriginalShellCell',labels)
                shell=[p for p in design['parts'] if p[1] in ('EggShell','OriginalShellCell')]
                self.assertGreater(len(shell),30)
                self.assertGreaterEqual(len({p[4][1] for p in shell}),8)
                for p in shell:
                    self.assertEqual(p[0],'box')
                    self.assertEqual(p[5],[1,0,0,0,1,0,0,0,1])
                for rejected in ('ShellBase','ShellShoulder','ShellCrown'):self.assertNotIn(rejected,labels)
                self.assertLess(len(design['parts']),340)
                self.assertGreater(len(design['parts']),40)

    def test_real_volume_transforms_and_held_size(self):
        for name,d in self.designs.items():
            with self.subTest(egg=name):
                low=[float('inf')]*3;high=[-float('inf')]*3
                for kind,label,size,index,pos,r,material,alpha,shine in d['parts']:
                    self.assertIn(kind,('box','wedge','corner','ball','cylinder'))
                    self.assertEqual(len(r),9)
                    self.assertTrue(all(math.isfinite(x) for x in size+pos+r))
                    self.assertTrue(all(x>.001 for x in size))
                    self.assertEqual(index,int(index))
                    self.assertTrue(1<=index<=len(d['palette']))
                    self.assertIn(material,('plastic','metal','wood','slate','sandstone','concrete','glass','neon'))
                    self.assertTrue(0<=alpha<1 and 0<=shine<=1)
                    rows=[r[i:i+3] for i in (0,3,6)]
                    for a in range(3):
                        for b in range(3):
                            self.assertAlmostEqual(sum(rows[a][j]*rows[b][j] for j in range(3)),1 if a==b else 0,places=5)
                    det=(r[0]*(r[4]*r[8]-r[5]*r[7])-r[1]*(r[3]*r[8]-r[5]*r[6])+r[2]*(r[3]*r[7]-r[4]*r[6]))
                    self.assertAlmostEqual(det,1,places=5)
                    for axis in range(3):
                        extent=sum(abs(rows[axis][j])*size[j]/2 for j in range(3))
                        low[axis]=min(low[axis],pos[axis]-extent);high[axis]=max(high[axis],pos[axis]+extent)
                actual=[high[i]-low[i] for i in range(3)]
                self.assertAlmostEqual(max(actual),4.375,places=4)
                self.assertGreater(actual[2],1.0,'Egg must have substantial side depth')
                for a,b in zip(actual,d['bounds']):self.assertAlmostEqual(a,b,places=4)
                for c in d['palette']:
                    self.assertEqual(len(c),3)
                    self.assertTrue(all(0<=x<=255 and x==int(x) for x in c))
        self.assertIn("t.Grip=CFrame.new(0,-.1,-.25)",self.source)
        self.assertIn("weld(t,m,CFrame.new(0,.45,-.75)",self.source)

    def test_no_image_projection_and_selective_emission(self):
        inventory=self.source.split('local EGG_DESIGNS=',1)[1]
        for rejected in ('EGG_SURFACE','paintEggBlock','ReferencePanel','SurfaceMark','LuminousInlay',"Instance.new('SurfaceGui')",'TextureID','ImageLabel','rbxassetid'):
            self.assertNotIn(rejected,inventory)
        self.assertIn("cat=='Eggs' and EGG_DESIGNS[name]",inventory)
        self.assertIn("return finalize(m,root)",inventory)
        for name,d in self.designs.items():
            glowing=[p[1] for p in d['parts'] if p[6]=='neon']
            if name in ('Unicorn Egg','Kitsune Egg'):self.assertEqual(glowing,[])
            else:self.assertTrue(glowing)
            self.assertFalse(any(any(s in label for s in ('Armor','Plate','Shell','Membrane','Feather')) for label in glowing))


if __name__=='__main__':unittest.main(verbosity=2)
