from pathlib import Path
import re
import textwrap

ROOT = Path('.')


def read(name: str) -> str:
    path = ROOT / name
    if not path.exists():
        raise SystemExit(f'Missing required source: {name}')
    return path.read_text(encoding='utf-8')


control = read('ControlPanel.lua')
pets = read('ExactPets.lua')
star = read('ExactStar.lua')
polish = read('FinalPolish.lua')
star_reference = read('StarReference.b64').strip()

# The current ControlPanel had a hard syntax error. A loadstring cannot compile
# a chunk containing `local local`, which is why executing Main could appear to do nothing.
control = control.replace(
    'local local giftSuccessPageTitle,giftSuccessMessage',
    'local giftSuccessPage,giftSuccessPageTitle,giftSuccessMessage',
    1,
)
if 'local local giftSuccessPageTitle' in control:
    raise SystemExit('ControlPanel compile typo was not removed')

# The spinner functions were assigned before their local forward declaration,
# which made later callbacks see nil locals. Put the declaration before assignment.
first_spinner = 'stopGiftSpinner=function()'
if first_spinner in control and 'local stopGiftSpinner,startGiftSpinner\nstopGiftSpinner=function()' not in control:
    control = control.replace(
        first_spinner,
        'local stopGiftSpinner,startGiftSpinner\n' + first_spinner,
        1,
    )
control = control.replace(
    'local stopGiftSpinner,startGiftSpinner\nlocal function queueRecipientLookup()',
    'local function queueRecipientLookup()',
    1,
)

# ExactStar previously downloaded StarReference.b64 as a second file. Embed the
# supplied reference bytes directly into its source so Main.lua is truly standalone.
embedded_reference = (
    'local EMBEDDED_REFERENCE_B64=[========[\n'
    + star_reference
    + '\n]========]\n'
)
star, replacements = re.subn(
    r"local REFERENCE_URL=.*?\nlocal LOCAL_FILE=",
    embedded_reference + 'local LOCAL_FILE=',
    star,
    count=1,
)
if replacements != 1:
    raise SystemExit('Could not replace ExactStar reference URL')
star = star.replace(
    'return game:HttpGet(REFERENCE_URL,true)',
    'return EMBEDDED_REFERENCE_B64',
    1,
)
if 'game:HttpGet(REFERENCE_URL,true)' in star:
    raise SystemExit('ExactStar still has an external reference dependency')


def long_string(text: str, level: int = 12) -> str:
    while True:
        eq = '=' * level
        close = ']' + eq + ']'
        if close not in text:
            return '[' + eq + '[\n' + text.rstrip() + '\n]' + eq + ']'
        level += 1


header = textwrap.dedent(r'''\
-- STEAL AN EGG - SELF-CONTAINED MAIN
-- All approved production logic is embedded below. No external Lua files are loaded.
-- Night Flame and Luminous Cthulhu approved pet rigs are preserved unchanged.

local env=(getgenv and getgenv()) or _G
if env.SAE_SINGLE_MAIN_RUNNING then
    warn('[SAE] Main.lua is already running in this session.')
    return
end
env.SAE_SINGLE_MAIN_RUNNING=true

local Players=game:GetService('Players')
local StarterGui=game:GetService('StarterGui')
local player=Players.LocalPlayer
local playerGui=player and (player:FindFirstChildOfClass('PlayerGui') or player:WaitForChild('PlayerGui',10))

local statusGui
local statusLabel
if playerGui then
    local old=playerGui:FindFirstChild('SAE_SINGLE_BOOT_STATUS')
    if old then old:Destroy() end

    statusGui=Instance.new('ScreenGui')
    statusGui.Name='SAE_SINGLE_BOOT_STATUS'
    statusGui.ResetOnSpawn=false
    statusGui.DisplayOrder=999999
    statusGui.IgnoreGuiInset=true
    statusGui.Parent=playerGui

    statusLabel=Instance.new('TextLabel')
    statusLabel.AnchorPoint=Vector2.new(.5,.5)
    statusLabel.Position=UDim2.fromScale(.5,.5)
    statusLabel.Size=UDim2.fromOffset(460,118)
    statusLabel.BackgroundColor3=Color3.fromRGB(18,20,27)
    statusLabel.TextColor3=Color3.fromRGB(245,247,255)
    statusLabel.Font=Enum.Font.GothamBold
    statusLabel.TextSize=17
    statusLabel.TextWrapped=true
    statusLabel.Text='STEAL AN EGG\nLoading single-file build...'
    statusLabel.Parent=statusGui

    local corner=Instance.new('UICorner')
    corner.CornerRadius=UDim.new(0,12)
    corner.Parent=statusLabel
end

local function setStatus(text,isError)
    if statusLabel and statusLabel.Parent then
        statusLabel.Text=text
        statusLabel.TextColor3=isError and Color3.fromRGB(255,105,105) or Color3.fromRGB(245,247,255)
    end
end

local function executeEmbedded(label,source)
    setStatus('STEAL AN EGG\nLoading '..label..'...')
    local fn,compileErr=loadstring(source)
    if not fn then
        setStatus('FAILED TO COMPILE '..label..'\n'..tostring(compileErr),true)
        warn('[SAE] '..label..' compile error: '..tostring(compileErr))
        return false
    end

    local ok,err=pcall(fn)
    if not ok then
        setStatus(label..' RUNTIME ERROR\n'..tostring(err),true)
        warn('[SAE] '..label..' runtime error: '..tostring(err))
        return false
    end
    return true
end

-- Clear stale flags from the older split-file versions before the approved
-- modules install their watchers.
env.SAE_V7=nil
env.SAE_MAIN_V7_LOADING=nil
env.SAE_FINAL_NATIVE_OVERRIDE=nil
env.SAE_EXACT_PETS=nil
env.SAE_FINAL_POLISH=nil
env.SAE_FINAL_ALL_LOADING=nil
''')

footer = textwrap.dedent(r'''\

local allOkay=true
allOkay=executeEmbedded('approved exact pets',EXACT_PETS_SOURCE) and allOkay
allOkay=executeEmbedded('held Star',EXACT_STAR_SOURCE) and allOkay
allOkay=executeEmbedded('pet/egg polish',FINAL_POLISH_SOURCE) and allOkay
allOkay=executeEmbedded('control panel',CONTROL_PANEL_SOURCE) and allOkay

env.SAE_SINGLE_MAIN_RUNNING=nil

if allOkay then
    setStatus('STEAL AN EGG\nLoaded successfully')
    task.delay(1,function()
        if statusGui and statusGui.Parent then statusGui:Destroy() end
    end)
else
    pcall(function()
        StarterGui:SetCore('SendNotification',{
            Title='Steal An Egg',
            Text='A module failed to load. The exact error is shown on screen.',
            Duration=8
        })
    end)
end
''')

bundled = header
bundled += '\nlocal EXACT_PETS_SOURCE=' + long_string(pets) + '\n'
bundled += '\nlocal EXACT_STAR_SOURCE=' + long_string(star) + '\n'
bundled += '\nlocal FINAL_POLISH_SOURCE=' + long_string(polish) + '\n'
bundled += '\nlocal CONTROL_PANEL_SOURCE=' + long_string(control) + '\n'
bundled += footer

Path('Main.lua').write_text(bundled, encoding='utf-8')

# Remove split production layers. ExactReferenceResolver/ReferenceModels are old
# experiments superseded by the approved exact-pet and exact-Star layers, so
# merging them too would reintroduce conflicting behaviour.
for name in [
    'ControlPanel.lua',
    'ExactPets.lua',
    'ExactReferenceResolver.lua',
    'ExactStar.lua',
    'FinalPolish.lua',
    'ReferenceModels.lua',
    'StarReference.b64',
    'bundle_main.py',
]:
    path = Path(name)
    if path.exists():
        path.unlink()

print(f'Generated self-contained Main.lua ({len(bundled):,} bytes)')
