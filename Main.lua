-- Steal An Egg V4 bootstrap
-- Fixed 2026-10-18: the previous Main.lua loaded its own raw URL, causing infinite recursion and freezing the client.

if getgenv and getgenv().SAE_V4_BOOTING then
    warn("[SAE] Script is already loading.")
    return
end

local env = getgenv and getgenv() or _G
env.SAE_V4_BOOTING = true

local CORE_URL = "https://raw.githubusercontent.com/randomcamper707/stealanegg1/6f14a6070a1207346018d4283037d2bc539c0b1d/Main.lua"

local ok, err = pcall(function()
    local source = game:HttpGet(CORE_URL)

    -- The archived V4 file contains an old bootstrap at the top which points
    -- back to Main.lua. Start from the actual script body so it cannot recurse.
    local marker = 'local Players = game:GetService("Players")'
    local startPos = source:find(marker, 1, true)
    if not startPos then
        error("Could not locate V4 script body")
    end

    source = source:sub(startPos)

    local fn, compileErr = loadstring(source)
    if not fn then
        error(compileErr or "Could not compile V4 script")
    end

    fn()
end)

env.SAE_V4_BOOTING = nil

if not ok then
    warn("[SAE] Failed to load: " .. tostring(err))
end
