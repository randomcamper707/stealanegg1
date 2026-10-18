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
    'Unicorn Egg':{'IvoryHorn','CrystalPrism','CrystalPoint','CrystalVioletRoot','CrystalRoseBand','HornSpiral'},
    'Kitsune Egg':{'FoxTail','TailTuft','ForeheadSigilGem','FoxEye','FoxCheekFlame','UpperPinkMark','ShellEmboss'},
    'Night Flame Egg':{'BarkPanel','GoldenPinion','IvyLeaf','EmberHeartGem','PinionTip','CarvedDiamondFrame','CrownLeaf','CrownBand','CrownRim','CrownMerlon'},
    'Archangel Egg':{'Feather','FeatherQuill','Halo','HolyRuneStem'},
    'World Burner Egg':{'BatMembrane','ChainLink','DemonHorn','BurnerSigil'},
    'Aetheron Egg':{'DualArmor','CrownHorn','Feather','RadiantSigil'},
    'Cthulhu Egg':{'CurledTentacle','TentacleSucker','CarvedStone','EyeRune'},
    'Luminous Cthulhu Egg':{'CurledTentacle','TentacleSucker','CrownLamp','EyeRune'},
    'Sabertooth Egg':{'VolcanicPlate','MagmaFacet','IvoryHorn','MoltenSeam','JaggedLavaScale','IvoryHornTip','RedSideShard'},
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
                self.assertLess(len(design['parts']),400 if name in ('Unicorn Egg','Night Flame Egg','Sabertooth Egg') else 340)
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

    def test_every_egg_is_25_percent_smaller_than_previous_display(self):
        previous_scale={'Unicorn Egg': 1.369078413724544, 'Kitsune Egg': 1.2, 'Night Flame Egg': 1.4286391388633881, 'Archangel Egg': 1.6848344679867573, 'World Burner Egg': 1.4875660479325281, 'Aetheron Egg': 1.6848331321444359, 'Cthulhu Egg': 1.2012585798127506, 'Luminous Cthulhu Egg': 1.2012585798127506, 'Sabertooth Egg': 1.2, 'Skeletal Sabertooth Egg': 1.2, 'Octophant Egg': 1.245390954593632, 'Mecha Scrambler Egg': 1.245390954593632}
        self.assertIn("local displayScale=(design.displayScale or math.max(1.20,4.25/bodyHeight))*0.75",self.source)
        self.assertIn("m:ScaleTo(displayScale)",self.source)
        for name,d in self.designs.items():
            with self.subTest(egg=name):
                body=[p for p in d['parts'] if p[1] in ('EggShell','OriginalShellCell')]
                height=max(p[4][1]+p[2][1]/2 for p in body)-min(p[4][1]-p[2][1]/2 for p in body)
                scale=d.get('displayScale',max(1.20,4.25/height))*.75
                previous_size=4.375*previous_scale[name]
                self.assertAlmostEqual(max(d['bounds'])*scale/previous_size,.75,places=5)

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



    def test_requested_crown_glow_and_unicorn_proportions(self):
        unicorn=self.designs['Unicorn Egg']
        labels={p[1] for p in unicorn['parts']}
        self.assertFalse(labels & {'PearlVein','IvoryFracture','PearlCrownLip','PearlFacet'})
        shell=[p for p in unicorn['parts'] if p[1] in ('EggShell','OriginalShellCell')]
        dimensions=[max(p[4][a]+p[2][a]/2 for p in shell)-min(p[4][a]-p[2][a]/2 for p in shell) for a in range(3)]
        self.assertLess(dimensions[0]/dimensions[1],.80)
        self.assertLess(dimensions[2]/dimensions[1],.70)
        crown=self.designs['Night Flame Egg']['parts']
        band=[p for p in crown if p[1]=='CrownBand']
        self.assertEqual(len(band),4)
        # Four continuous walls connect at their corners; merlons emerge from
        # the rim rather than floating independently above the shell.
        for wall in band:
            overlaps=0
            for other in band:
                if wall is other:continue
                if all(abs(wall[4][a]-other[4][a]) <= (wall[2][a]+other[2][a])/2+.00001 for a in range(3)):overlaps+=1
            self.assertGreaterEqual(overlaps,2)
        rims=[p for p in crown if p[1]=='CrownRim']
        teeth=[p for p in crown if p[1]=='CrownMerlon']
        self.assertEqual(len(teeth),8)
        for tooth in teeth:
            self.assertTrue(any(all(abs(tooth[4][a]-rim[4][a]) <= (tooth[2][a]+rim[2][a])/2+.00001 for a in range(3)) for rim in rims))
        saber=self.designs['Sabertooth Egg']['parts']
        self.assertFalse(any(p[1] in ('Furnace','FurnaceRim') for p in saber))
        molten=[p for p in saber if p[1]=='MoltenSeam']
        self.assertGreaterEqual(len(molten),24)
        for axis in (0,2):
            for sign in (-1,1):
                self.assertGreaterEqual(sum(p[4][axis]*sign>.3 for p in molten),3)
        self.assertGreaterEqual(sum(p[1]=='RedSideShard' for p in saber),28)

if __name__=='__main__':unittest.main(verbosity=2)
