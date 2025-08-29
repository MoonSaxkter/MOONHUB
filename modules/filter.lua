-- modules/filter.lua
-- MoonHub Filter Module
-- Gestiona qué mapas/challenges están permitidos para FindTB
-- Persistencia opcional en Moon_Config/filter.json

local Filter = {}
Filter.__index = Filter

--------------------------------------------------------------------
-- Constantes de dominio
--------------------------------------------------------------------
local MAPS = {
  "Innovation Island",
  "Giant Island",
  "Future City (Ruins)",
  "City of Voldstandig",
  "Hidden Storm Village",
  "City of York",
  "Shadow Tournament",
}

-- Nota: "Random Units" existe en el juego, pero SIEMPRE se ignora
local CHALLENGES = {
  "Flying Enemies",
  "Juggernaut Enemies",
  "Single Placement",
  "High Cost",
  "Unsellable",
}

-- normalización de nombres
local function norm(s)
  s = tostring(s or ""):lower()
  -- reemplaza separadores y limpia
  s = s:gsub("[%s%-]+", "_")
  s = s:gsub("[^%w_]", "")
  s = s:gsub("_+", "_")
  s = s:gsub("^_", ""):gsub("_$", "")
  return s
end

-- índices rápidos de normalizados → original
local MAP_BY_KEY = {}
for _, m in ipairs(MAPS) do MAP_BY_KEY[norm(m)] = m end

local CHAL_BY_KEY = {}
for _, c in ipairs(CHALLENGES) do CHAL_BY_KEY[norm(c)] = c end

-- claves a ignorar siempre (random units)
local FORBIDDEN = { ["random_units"] = true, ["random"] = true }

--------------------------------------------------------------------
-- FS helpers
--------------------------------------------------------------------
local FS = {}
do
  local g = getgenv and getgenv() or _G or {}
  FS.writefile  = rawget(g, "writefile")  or (rawget(g, "syn") and g.syn.writefile)  or (rawget(g, "krnl") and g.krnl.writefile)
  FS.readfile   = rawget(g, "readfile")   or (rawget(g, "syn") and g.syn.readfile)   or (rawget(g, "krnl") and g.krnl.readfile)
  FS.isfile     = rawget(g, "isfile")     or (rawget(g, "syn") and g.syn.isfile)
  FS.isfolder   = rawget(g, "isfolder")   or (rawget(g, "syn") and g.syn.isfolder)
  FS.makefolder = rawget(g, "makefolder") or (rawget(g, "syn") and g.syn.makefolder)

  -- Fallback: synthesize isfile when only readfile exists (KRNL compatibility)
  if not FS.isfile and FS.readfile then
    FS.isfile = function(path)
      local ok = pcall(function() FS.readfile(path) end)
      return ok
    end
  end
end

local CFG_DIR  = "Moon_Config"
local CFG_FILE = CFG_DIR .. "/filter.json"

local function ensureCfgDir()
  if FS.isfolder and not FS.isfolder(CFG_DIR) and FS.makefolder then
    pcall(FS.makefolder, CFG_DIR)
  end
end

--------------------------------------------------------------------
-- Estado
--------------------------------------------------------------------
-- allowed: { [OriginalMapName] = { [OriginalChallengeName]=true, ... }, ... }
local state = { allowed = {} }

-- defaults: si el usuario no ha configurado nada aún, por defecto permitir TODO excepto Random Units
local function defaultAllowed()
  local t = {}
  for _, m in ipairs(MAPS) do
    local set = {}
    for _, c in ipairs(CHALLENGES) do set[c] = true end
    t[m] = set
  end
  return t
end

--------------------------------------------------------------------
-- Persistencia
--------------------------------------------------------------------
local function decodeJSON(s)
  local ok, res = pcall(function() return game:GetService("HttpService"):JSONDecode(s) end)
  if ok and type(res) == "table" then return res end
  return nil
end

local function encodeJSON(tbl)
  local ok, res = pcall(function() return game:GetService("HttpService"):JSONEncode(tbl) end)
  if ok and type(res) == "string" then return res end
  return nil
end

function Filter.load()
  if not (FS.readfile and (FS.isfile or FS.readfile)) then
    -- sin FS real: usar memoria por sesión y poblar defaults si está vacío
    if next(state.allowed) == nil then
      state.allowed = defaultAllowed()
    end
    return true, "memory-only"
  end
  ensureCfgDir()
  if FS.isfile(CFG_FILE) then
    local ok, raw = pcall(FS.readfile, CFG_FILE)
    if ok and type(raw) == "string" then
      local json = decodeJSON(raw)
      if json and json.allowed then
        -- validar y normalizar estructura
        local out = {}
        for mapName, chalTable in pairs(json.allowed) do
          local mk = MAP_BY_KEY[norm(mapName)]
          if mk then
            out[mk] = out[mk] or {}
            if type(chalTable) == "table" then
              for chName, v in pairs(chalTable) do
                local ck = CHAL_BY_KEY[norm(chName)]
                if ck and v == true then
                  out[mk][ck] = true
                end
              end
            end
          end
        end
        -- si quedó vacío, repoblar defaults
        local empty = true
        for _ in pairs(out) do empty = false break end
        state.allowed = empty and defaultAllowed() or out
        return true, "loaded"
      end
    end
  end
  state.allowed = defaultAllowed()
  return true, "defaulted"
end

function Filter.save()
  if not FS.writefile then return false, "no-fs" end
  ensureCfgDir()
  local data = { allowed = state.allowed }
  local json = encodeJSON(data)
  if not json then return false, "json-error" end
  local ok, err = pcall(FS.writefile, CFG_FILE, json)
  return ok, ok and "saved" or tostring(err)
end

--------------------------------------------------------------------
-- API de edición/consulta
--------------------------------------------------------------------
-- Establece challenges permitidos para un mapa (lista de strings / claves)
function Filter.setAllowed(mapName, challengesList)
  local mk = MAP_BY_KEY[norm(mapName)]
  if not mk then return false, "invalid map" end
  local set = {}
  if type(challengesList) == "table" then
    for _, c in ipairs(challengesList) do
      local key = norm(c)
      if not FORBIDDEN[key] then
        local ck = CHAL_BY_KEY[key]
        if ck then set[ck] = true end
      end
    end
  end
  state.allowed[mk] = set
  pcall(Filter.save)
  return true
end

-- Agrega o quita un challenge puntual
function Filter.toggle(mapName, challengeName, enable)
  local mk = MAP_BY_KEY[norm(mapName)]
  if not mk then return false, "invalid map" end
  local key = norm(challengeName)
  if FORBIDDEN[key] then return false, "forbidden" end
  local ck = CHAL_BY_KEY[key]
  if not ck then return false, "invalid challenge" end
  state.allowed[mk] = state.allowed[mk] or {}
  if enable == false then
    state.allowed[mk][ck] = nil
  else
    state.allowed[mk][ck] = true
  end
  pcall(Filter.save)
  return true
end

-- Devuelve lista (array) de challenges permitidos para un mapa
function Filter.getAllowed(mapName)
  local mk = MAP_BY_KEY[norm(mapName)]
  if not mk then return {} end
  local set = state.allowed[mk] or {}
  local out = {}
  for _, c in ipairs(CHALLENGES) do
    if set[c] then table.insert(out, c) end
  end
  return out
end

-- Consulta rápida: ¿puedo entrar a este mapa/challenge?
function Filter.isAllowed(mapName, challengeName)
  -- Random Units: jamás permitido
  if FORBIDDEN[norm(challengeName)] then return false end

  local mk = MAP_BY_KEY[norm(mapName)]
  if not mk then
    return true -- mapa desconocido => allow-all
  end
  local set = state.allowed[mk]
  if not set then
    return true -- no hay entrada para el mapa => allow-all
  end
  -- si la entrada existe pero está vacía => deny-all para ese mapa
  if next(set) == nil then
    return false
  end
  local ck = CHAL_BY_KEY[norm(challengeName)]
  if not ck then
    return false
  end
  return set[ck] == true
end

-- Util para UI: listas maestras
function Filter.listMaps()       return MAPS end
function Filter.listChallenges() return CHALLENGES end

-- Exporta/Importa estado crudo (para UI avanzada)
function Filter.export()
  -- devuelve copia superficial segura
  local out = {}
  for m, set in pairs(state.allowed) do
    out[m] = {}
    for c, v in pairs(set) do out[m][c] = v and true or nil end
  end
  return out
end

function Filter.import(tbl)
  if type(tbl) ~= "table" then return false, "invalid" end
  local okAll = true
  local out = {}
  for m, set in pairs(tbl) do
    local mk = MAP_BY_KEY[norm(m)]
    if mk then
      out[mk] = {}
      if type(set) == "table" then
        for c, v in pairs(set) do
          local ck = CHAL_BY_KEY[norm(c)]
          if ck and v == true then
            out[mk][ck] = true
          end
        end
      end
    else
      okAll = false -- hubo alguna clave inválida; igual aceptamos el resto
    end
  end
  local empty = true
  for _ in pairs(out) do empty = false break end
  state.allowed = empty and defaultAllowed() or out
  pcall(Filter.save)
  return okAll
end

-- Reemplaza todo el estado allowed con un snapshot confiable
function Filter.replaceAll(tbl)
  if type(tbl) ~= "table" then return false, "invalid" end
  local out = {}
  for m, set in pairs(tbl) do
    local mk = MAP_BY_KEY[norm(m)]
    if mk then
      out[mk] = {}
      if type(set) == "table" then
        for c, v in pairs(set) do
          local keyC = norm(c)
          if not FORBIDDEN[keyC] then
            local ck = CHAL_BY_KEY[keyC]
            if ck and v == true then
              out[mk][ck] = true
            end
          end
        end
      end
    end
    -- claves inválidas se ignoran sin afectar ok
  end
  state.allowed = out
  pcall(Filter.save)
  return true
end

-- Reset total
function Filter.reset()
  state.allowed = defaultAllowed()
  pcall(Filter.save)
end

--------------------------------------------------------------------
-- Inicialización + puente global
--------------------------------------------------------------------
Filter.load()

-- Exponer en getgenv para fácil acceso desde main.lua / findtb.lua
local g = getgenv and getgenv() or _G
g.MoonFilter = Filter

return Filter