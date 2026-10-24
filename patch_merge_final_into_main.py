from pathlib import Path

main_path = Path('Main.lua')
final_fix_path = Path('FinalFix.lua')
exact_icons_path = Path('FinalExactIcons.lua')

main = main_path.read_text(encoding='utf-8')
final_fix = final_fix_path.read_text(encoding='utf-8')
exact_icons = exact_icons_path.read_text(encoding='utf-8')

marker = '\n-- SAE_INTEGRATED_FINAL_FIXES_20261024\n'
if marker in main:
    main = main.split(marker, 1)[0].rstrip() + '\n'

fix_start = "local Players=game:GetService('Players')"
icons_start = "local Players=game:GetService('Players')"

if fix_start not in final_fix:
    raise SystemExit('Could not locate FinalFix body')
if icons_start not in exact_icons:
    raise SystemExit('Could not locate FinalExactIcons body')

fix_body = final_fix[final_fix.index(fix_start):].rstrip()
icons_body = exact_icons[exact_icons.index(icons_start):].rstrip()

integrated = (
    marker
    + "-- Integrated from FinalFix.lua so Main.lua alone includes the requested panel +15% and Star visibility fixes.\n"
    + "(function()\n" + fix_body + "\nend)()\n\n"
    + "-- Integrated from FinalExactIcons.lua so Main.lua alone installs the exact supplied egg/pet/Star hotbar renders.\n"
    + "(function()\n" + icons_body + "\nend)()\n"
)

main = main.rstrip() + '\n' + integrated
main_path.write_text(main, encoding='utf-8')

# Targeted verification: make sure this is a Main-only final build with all requested integration points.
text = main_path.read_text(encoding='utf-8')
assert text.count('SAE_INTEGRATED_FINAL_FIXES_20261024') == 1
assert "d.Scale=.66125" in text, '15% larger Items panel patch missing'
assert "tool.Parent==player.Character" in text, 'already-equipped Star visibility path missing'
assert "['Unicorn Egg']='unicorn_egg'" in text, 'Unicorn Egg exact icon mapping missing'
assert "['Mecha Scrambler']='mecha_scrambler_pet'" in text, 'Mecha Scrambler exact icon mapping missing'
assert "['Star']='star'" in text, 'Star exact icon mapping missing'
assert "REF_URL='https://raw.githubusercontent.com/randomcamper707/stealanegg1/6f14a6070a1207346018d4283037d2bc539c0b1d/Main.lua" in text
print('Main.lua final integration checks passed')
