-- macro_manager.lua — Gestor de selección/guardado de macros
-- Responsabilidad:
--  - Mantener el nombre seleccionado del macro
--  - Listar/seleccionar/limpiar macros
--  - Bloquear grabación si el archivo ya existe (hasta "Clear Macro")
--  - Dar a macrosys.lua la ruta exacta donde guardar

local MacroManager = {}

local FOLDER = "Moon_Macros"

-- ==== helpers FS (según executor) ====
local function has(fn) return type(_G[fn])=="function" or type(getfenv and getfenv()[fn])=="function" or type(_G[fn])=="table" end
local function safe_isfolder(p) local ok,res=pcall(function() return isfolder and isfolder(p) end); return ok and res end
local function safe_makefolder(p) pcall(function() if makefolder and not isfolder(p) then makefolder(p) end end) end
local function safe_listfiles(p)
  local ok,res=pcall(function() return listfiles and listfiles(p) or {} end)
  return ok and res or {}
end
local function safe_isfile(p) local ok,res=pcall(function() return isfile and isfile(p) end); return ok and res end
local function safe_delfile(p) pcall(function() if delfile and isfile and isfile(p) then delfile(p) end end) end

local function sanitize(name)
  name = tostring(name or ""):gsub("^%s+",""):gsub("%s+$","")
  if name == "" then return "macro" end
  -- Solo letras/números/espacios/_/-
  name = name:gsub("[^%w%-%_ ]", "")
  if name == "" then name = "macro" end
  return name
end

local STATE = {
  selected = nil,     -- nombre sin .json (ej: "Mi macro")
}

-- ==== API pública ====

function MacroManager.ensureFolder()
  safe_makefolder(FOLDER)
  return FOLDER
end

function MacroManager.list()
  MacroManager.ensureFolder()
  local out = {}
  local files = safe_listfiles(FOLDER)
  for _,p in ipairs(files) do
    local name = tostring(p):match(".-[/\\]([^/\\]+)%.json$")
    if name then table.insert(out, name) end
  end
  table.sort(out)
  return out
end

function MacroManager.select(name)
  name = sanitize(name)
  STATE.selected = name
  -- avisar a la UI si hay callback
  pcall(function()
    if type(getgenv)=="function" and type(getgenv().OnMacroSelection)=="function" then
      getgenv().OnMacroSelection(name)
    end
  end)
  return true, name
end

function MacroManager.getSelected()
  return STATE.selected
end

function MacroManager.exists(name)
  name = sanitize(name or STATE.selected)
  if not name then return false end
  local path = ("%s/%s.json"):format(FOLDER, name)
  return safe_isfile(path)
end

-- Regla de seguridad:
--  - Si el archivo ya existe → NO se permite grabar hasta Clear
function MacroManager.canRecord()
  local name = STATE.selected
  if not name or name == "" then
    return false, "Select or type a macro name first"
  end
  local path = ("%s/%s.json"):format(FOLDER, name)
  if safe_isfile(path) then
    return false, "Selected macro already exists. Press Clear Macro to overwrite"
  end
  return true
end

-- Devuelve la ruta donde macrosys debe guardar.
-- Si hay seleccionado y se puede grabar, usa ese.
-- Si no, devuelve fallback con name por defecto (timestamp de macrosys).
function MacroManager.getSavePath(defaultNameNoExt)
  MacroManager.ensureFolder()
  local ok, reason = MacroManager.canRecord()
  if ok then
    return ("%s/%s.json"):format(FOLDER, STATE.selected)
  end
  -- fallback: respeta nombre autogenerado de macrosys
  defaultNameNoExt = sanitize(defaultNameNoExt or "macro")
  return ("%s/%s.json"):format(FOLDER, defaultNameNoExt), reason
end

-- Borra el archivo seleccionado (si existe) para habilitar nueva grabación
function MacroManager.clearSelected()
  if not STATE.selected then
    return false, "Nothing selected"
  end
  local path = ("%s/%s.json"):format(FOLDER, STATE.selected)
  if safe_isfile(path) then safe_delfile(path) end
  -- avisar a la UI
  pcall(function()
    if type(getgenv)=="function" and type(getgenv().OnMacroCleared)=="function" then
      getgenv().OnMacroCleared(STATE.selected)
    end
  end)
  return true
end

-- Para UI: selecciona por nombre y asegura carpeta
function MacroManager.setNameFromInput(name)
  MacroManager.ensureFolder()
  return MacroManager.select(name)
end

-- Exponer en getgenv
pcall(function()
  if type(getgenv)=="function" then
    getgenv().MacroManager = MacroManager
  else
    _G.MacroManager = MacroManager
  end
end)

return MacroManager