from pathlib import Path

p=Path('Main.lua')
s=p.read_text(encoding='utf-8')
marker="local Eggs=GiftCatalog.Eggs"
if marker not in s:
    raise SystemExit('item panel marker not found')

catalog="""local GiftCatalog={
    Eggs={
        'Unicorn Egg','Kitsune Egg','Night Flame Egg','Archangel Egg',
        'World Burner Egg','Aetheron Egg','Cthulhu Egg','Luminous Cthulhu Egg',
        'Sabertooth Egg','Skeletal Sabertooth Egg','Octophant Egg','Mecha Scrambler Egg'
    },
    Pets={
        'Unicorn','Kitsune','Night Flame','Archangel',
        'World Burner','Aetheron','Cthulhu','Luminous Cthulhu',
        'Sabertooth','Skeletal Sabertooth','Octophant','Mecha Scrambler'
    },
    Star={'Star'}
}

"""

# Restore only the data table the ITEMS panel depends on. The Gift Panel UI stays removed.
if "local GiftCatalog={" not in s:
    s=s.replace(marker,catalog+marker,1)

p.write_text(s,encoding='utf-8')
