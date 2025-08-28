-- main.lua (mínimo y robusto)
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local player  = Players.LocalPlayer

-- URL del módulo
local HUB_URL = "https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/hub.lua"

-- Cargar hub.lua con logs
local Hub
do
    local okGet, srcOrErr = pcall(function()
        return game:HttpGet(HUB_URL)
    end)
    if not okGet then
        warn("[Main][ERROR] HttpGet fallo:", srcOrErr)
        return
    end

    if type(srcOrErr) ~= "string" or #srcOrErr == 0 then
        warn("[Main][ERROR] hub.lua vacío o no descargado")
        return
    end

    local chunk, loadErr = loadstring(srcOrErr)
    if not chunk then
        warn("[Main][ERROR] loadstring fallo:", loadErr)
        return
    end

    local okRun, moduleOrErr = pcall(chunk)
    if not okRun then
        warn("[Main][ERROR] Ejecutando hub.lua:", moduleOrErr)
        return
    end

    Hub = moduleOrErr
end

if type(Hub) ~= "table" or type(Hub.build) ~= "function" then
    warn("[Main][ERROR] Hub inválido: se esperaba tabla con .build()")
    return
end

-- Config “stub” (luego lo reemplazas por config.json real)
local Config = {
    data = {},
    load = function() end,
    save = function() end,
}

-- Limpia UI anterior
local pg = player:WaitForChild("PlayerGui")
local old = pg:FindFirstChild("MyAwesomeUI")
if old then old:Destroy() end

-- Construir el Hub
local okBuild, uiOrErr = pcall(function()
    return Hub.build(player, Config)
end)
if not okBuild then
    warn("[Main][ERROR] Hub.build fallo:", uiOrErr)
    return
end

if uiOrErr and uiOrErr.root then
    print("[Main] Hub cargado con éxito:", uiOrErr.root.Name)
else
    print("[Main] Hub cargado (sin root expuesto)")
end