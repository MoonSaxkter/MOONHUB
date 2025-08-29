--[[
  main.lua — Orquestador del Hub (solo wiring + persistencia)

  RESPONSABILIDAD
  ---------------------------------------------------------------------------
  • Este archivo NO dibuja UI. Carga `hub.lua`, lo construye y conecta módulos.
  • Centraliza la persistencia (config.json) y el "wiring" con módulos externos
    como `findtb.lua`.

  DISEÑO
  ---------------------------------------------------------------------------
  1) Espera a que el juego cargue.
  2) Descarga/ejecuta `hub.lua` (UI pura) y lo construye con un objeto Config.
  3) Suscribe eventos públicos del hub (p.ej. findTBChanged) para encender/
     apagar módulos.
  4) Guarda y restaura estados en `MoonHub/config.json`.

  CONTRATOS esperados del hub (documentados para el dev del hub):
  ---------------------------------------------------------------------------
  Hub.build(player, Config) -> hubInstance :: table con:
    - root                : ScreenGui o nodo raíz de la UI (opcional).
    - events.findTBChanged: BindableEvent (bool isOn).
    - filterSelections    : tabla { ["Map Label"] = { ["Challenge Label"] = true/false } }
    - toggles             : tabla con helpers opcionales (ej. .findTB.set(bool)).

  Si alguno no existe, este main se degrada con gracia (pcall + comprobaciones).

  FINDTB - protocolo flexible
  ---------------------------------------------------------------------------
  
  Cargamos `modules/findtb.lua` y soportamos varias interfaces:
    • mod.enable(opts)/mod.disable()
    • mod.start(opts)/mod.stop()
    • mod.setFilters(list|map)    -- si la expone, la invocamos al cambiar filtros

  `opts.getFilters()` devuelve un snapshot de filtros actuales (por mapa -> lista
   de challenges). Esto evita acoplarse a estructuras internas del hub.

  ARCHIVO DE CONFIGURACIÓN
  ---------------------------------------------------------------------------
  Ruta: MoonHub/config.json
  Estructura mínima compatible:
  {
    "toggles": { "findTB": false, "autoReplay": false, "autoSelect": false },
    "selectedMacro": null,
    "filters": { "Innovation Island": ["Flying Enemies", "Unsellable"], ... }
  }
  
  El hub puede leer/escribir esta estructura si así fue implementado. Aquí,
  igualmente, persistimos cambios que se originan desde main (por ejemplo,
  eventos que no persista el hub por sí mismo).

  LOGS
  ---------------------------------------------------------------------------
  Prefijo [Main] en prints/warns para debugear fácilmente.
]]

-- === 0) BOOT ===
repeat task.wait() until game:IsLoaded()

local Players        = game:GetService("Players")
local HttpService    = game:GetService("HttpService")
local player         = Players.LocalPlayer

-- === 1) URLs de módulos ===
local BASE       = "https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/"
local HUB_URL    = BASE .. "hub.lua"
local FINDTB_URL = BASE .. "findtb.lua"

-- === 2) Helpers genéricos ===
local function httpGet(url)
  local ok, res = pcall(function() return game:HttpGet(url) end)
  if not ok then warn("[Main][ERROR] HttpGet:", url, res) end
  return ok and res or nil
end

-- FS cross-executor
local FS = {}
 do
  local g = getgenv and getgenv() or _G or {}
  FS.writefile  = rawget(g, "writefile")  or (rawget(g, "syn") and g.syn.writefile) or (rawget(g, "krnl") and g.krnl.writefile)
  FS.readfile   = rawget(g, "readfile")   or (rawget(g, "syn") and g.syn.readfile)
  FS.isfile     = rawget(g, "isfile")     or (rawget(g, "syn") and g.syn.isfile)
  FS.isfolder   = rawget(g, "isfolder")   or (rawget(g, "syn") and g.syn.isfolder)
  FS.makefolder = rawget(g, "makefolder") or (rawget(g, "syn") and g.syn.makefolder)
 end

local function ensureFolder(path)
  if FS.isfolder and not FS.isfolder(path) and FS.makefolder then
    pcall(FS.makefolder, path)
  end
end

-- === 3) Persistencia: Config ===
local Config = {
  path = "MoonHub/config.json",
  data = {
    toggles = { findTB = false, autoReplay = false, autoSelect = false },
    selectedMacro = nil,
    filters = {}
  }
}

function Config.load()
  if not (FS.isfile and FS.readfile) then return end
  if not FS.isfile(Config.path) then return end
  local okR, raw = pcall(FS.readfile, Config.path)
  if not okR or not raw or #raw == 0 then return end
  local okD, t = pcall(function() return HttpService:JSONDecode(raw) end)
  if okD and typeof(t) == "table" then
    -- merge superficial con defaults
    Config.data.toggles = t.toggles or Config.data.toggles
    Config.data.selectedMacro = t.selectedMacro or Config.data.selectedMacro
    Config.data.filters = t.filters or Config.data.filters
  end
end

function Config.save()
  if not (FS.writefile and HttpService) then return end
  ensureFolder("MoonHub")
  local okJ, json = pcall(function() return HttpService:JSONEncode(Config.data) end)
  if okJ then pcall(FS.writefile, Config.path, json) end
end

-- Cargar estado previo antes de construir el hub
Config.load()

-- === 4) Cargar hub.lua y construir la UI ===
local Hub
 do
  local src = httpGet(HUB_URL)
  if not src then return end
  local chunk, loadErr = loadstring(src)
  if not chunk then warn("[Main][ERROR] loadstring(hub):", loadErr) return end
  local okRun, mod = pcall(chunk)
  if not okRun then warn("[Main][ERROR] ejecutando hub.lua:", mod) return end
  Hub = mod
 end

if type(Hub) ~= "table" or type(Hub.build) ~= "function" then
  warn("[Main][ERROR] Hub inválido: se esperaba tabla con .build()")
  return
end

-- Limpia UI previa por si quedó algo
local pg  = player:WaitForChild("PlayerGui")
local prev = pg:FindFirstChild("MyAwesomeUI")
if prev then prev:Destroy() end

-- Construir Hub con Config inyectado
local hub
 do
  local okBuild, res = pcall(function()
    return Hub.build(player, Config)  -- el hub puede leer/escribir Config.data
  end)
  if not okBuild then warn("[Main][ERROR] Hub.build fallo:", res) return end
  hub = res
 end

print("[Main] Hub cargado:", hub and hub.root and hub.root.Name or "(sin root)")

-- === 5) Utilidades para acceder a filtros desde findtb ===
local function readFiltersSnapshot()
  -- preferimos lo que expone el hub en vivo; si no, lo último guardado
  if hub and type(hub) == "table" and hub.filterSelections then
    -- convertir set {label=true} -> array {label1,label2,...}
    local out = {}
    for mapLabel, set in pairs(hub.filterSelections) do
      out[mapLabel] = {}
      for challLabel, on in pairs(set) do
        if on then table.insert(out[mapLabel], challLabel) end
      end
    end
    return out
  end
  return Config.data.filters or {}
end

-- === 6) Integración con findtb.lua (carga perezosa + API flexible) ===
local FindTB = { module = nil, active = false }

local function ensureFindTB()
  if FindTB.module ~= nil then return true end
  local src = httpGet(FINDTB_URL)
  if not src then return false end
  local chunk, loadErr = loadstring(src)
  if not chunk then warn("[Main][ERROR] loadstring(findtb):", loadErr) return false end
  local okRun, mod = pcall(chunk)
  if not okRun then warn("[Main][ERROR] ejecutando findtb.lua:", mod) return false end
  if type(mod) ~= "table" then warn("[Main][ERROR] findtb.lua no retornó tabla") return false end
  FindTB.module = mod
  return true
end

local function callFindTB(method, ...)
  if not FindTB.module then return false end
  local fn = FindTB.module[method]
  if type(fn) == "function" then
    local ok, err = pcall(fn, ...)
    if not ok then warn("[Main][findtb]", method, "error:", err) end
    return ok
  end
  return false
end

local function buildFindTBOpts()
  return {
    getFilters = readFiltersSnapshot,   -- función: devuelve { [map]= {ch1,ch2...} }
  }
end

local function startFindTB()
  if not ensureFindTB() then return end
  local opts = buildFindTBOpts()
  -- soporta enable/start indistintamente
  if not callFindTB('enable', opts) then
    callFindTB('start', opts)
  end
  -- si expone setFilters, pásalos también al inicio
  local filters = readFiltersSnapshot()
  callFindTB('setFilters', filters)
  FindTB.active = true
end

local function stopFindTB()
  if not FindTB.module then return end
  if not callFindTB('disable') then
    callFindTB('stop')
  end
  FindTB.active = false
end

-- === 7) Suscripción de eventos del hub ===
local function connectIf(ev, name, cb)
  if ev and typeof(ev) == "Instance" and ev:IsA("BindableEvent") then
    ev.Event:Connect(cb)
    print("[Main] Suscrito:", name)
    return true
  end
  return false
end

-- a) Toggle FindTB desde la UI
if hub and hub.events and hub.events.findTBChanged then
  connectIf(hub.events.findTBChanged, "findTBChanged", function(isOn)
    print("[Main] findTBChanged =>", isOn)

    -- Persistimos el toggle (por si el hub no lo hace)
    Config.data.toggles = Config.data.toggles or {}
    Config.data.toggles.findTB = not not isOn
    Config.save()

    if isOn then startFindTB() else stopFindTB() end
  end)
else
  warn("[Main] hub.events.findTBChanged no disponible; el toggle no controlará findtb")
end

-- b) Si el hub expone cambios de filtros, actualizamos findtb y persistimos
if hub and hub.events and hub.events.filtersChanged then
  connectIf(hub.events.filtersChanged, "filtersChanged", function()
    local snap = readFiltersSnapshot()
    Config.data.filters = snap
    Config.save()
    callFindTB('setFilters', snap)
  end)
end

-- c) Restaura estado FindTB desde config (si UI no lo hace por sí misma)
task.defer(function()
  local tg = Config.data.toggles or {}
  if tg.findTB then
    -- Si el hub tiene un setter público, úsalo para que la UI quede sincronizada
    local okSet = false
    if hub and hub.toggles and hub.toggles.findTB and type(hub.toggles.findTB.set) == 'function' then
      local ok, err = pcall(hub.toggles.findTB.set, true)
      okSet = ok
      if not ok then warn("[Main] hub.toggles.findTB.set(true) fallo:", err) end
    end
    -- En cualquier caso, asegúrate de arrancar la lógica
    if not okSet then startFindTB() end
  end
end)

-- d) Auto-cleanup si el usuario cierra la UI
if hub and hub.root and typeof(hub.root) == "Instance" then
  hub.root.AncestryChanged:Connect(function(_, parent)
    if not parent then
      -- La UI fue destruida
      stopFindTB()
      print("[Main] UI destruida → módulos detenidos")
    end
  end)
end

print("[Main] Wiring completo ✓")