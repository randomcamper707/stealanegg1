from pathlib import Path
import re

p=Path('Main.lua')
s=p.read_text(encoding='utf-8')

s=re.sub(
    r'\nGiftPanel=window\("GiftPanel","Gift Panel","Choose an item and recipient",390,430,UDim2\.new\(\.5,0,\.5,0\)\)\nGiftPanel\.Visible=false\nGiftPanel\.BackgroundTransparency=Main\.BackgroundTransparency\n',
    '\n',s,count=1
)

s=s.replace('Launch=Instance.new("Frame"); Launch.Position=UDim2.new(0,12,.5,-170); Launch.Size=UDim2.fromOffset(106,105); Launch.BackgroundTransparency=1; Launch.Parent=Gui',
            'Launch=Instance.new("Frame"); Launch.Position=UDim2.new(0,12,.5,-170); Launch.Size=UDim2.fromOffset(106,70); Launch.BackgroundTransparency=1; Launch.Parent=Gui',1)

s=re.sub(r'\nbGift=button\(Launch,"GIFT PANEL"[^\n]*\)', '', s, count=1)
s=re.sub(r'\nbGift\.MouseButton1Click:Connect\(function\(\) Main\.Visible=false; GiftPanel\.Visible=not GiftPanel\.Visible end\)', '', s, count=1)

# Remove the full Gift Panel implementation, not merely the visible launcher.
s,n=re.subn(
    r'\ngiftCatalogPage=Instance\.new\("Frame"\).*?\n-- Centered announcement layer\.',
    '\n-- Centered announcement layer.',
    s,count=1,flags=re.S
)
if n!=1:
    raise SystemExit('Gift Panel implementation block not found')

# Home now routes only to actual admin pages.
s=re.sub(
    r'b\.MouseButton1Click:Connect\(function\(\)\n\s*if item\[2\]=="Gift Panel" then\n\s*Main\.Visible=false\n\s*GiftPanel\.Visible=true\n\s*else\n\s*showAdminPage\(item\[2\],true\)\n\s*end\n\s*end\)',
    'b.MouseButton1Click:Connect(function()\n        showAdminPage(item[2],true)\n    end)',
    s,count=1
)

s=s.replace('GiftBuildModel=function(cat,name) return model(cat,name) end\n','',1)

if 'GiftPanel' in s:
    raise SystemExit('GiftPanel reference remains after removal')

p.write_text(s,encoding='utf-8')
print('Gift Panel fully removed')
