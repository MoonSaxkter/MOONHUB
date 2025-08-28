local HttpService = game:GetService("HttpService")

local FS = {}
do
  local g = getgenv and getgenv() or _G or {}
  FS.writefile  = rawget(g, "writefile")  or (rawget(g, "syn") and g.syn.writefile) or (rawget(g, "krnl") and g.krnl.writefile)
  FS.readfile   = rawget(g, "readfile")   or (rawget(g, "syn") and g.syn.readfile)
  FS.isfile     = rawget(g, "isfile")     or (rawget(g, "syn") and g.syn.isfile)
  FS.isfolder   = rawget(g, "isfolder")   or (rawget(g, "syn") and g.syn.isfolder)
  FS.makefolder = rawget(g, "makefolder") or (rawget(g, "syn") and g.syn.makefolder)
end

local M = {}
M.path = "MoonHub/config.json"
M.data = {
  toggles = { findTB=false, autoReplay=false, autoSelect=false },
  selectedMacro = nil,
  filters = {}
}

local function ensureFolder()
  if FS.isfolder and not FS.isfolder("MoonHub") and FS.makefolder then
    pcall(FS.makefolder, "MoonHub")
  end
end

function M.save()
  if not (FS.writefile and HttpService) then return end
  ensureFolder()
  local ok, json = pcall(function() return HttpService:JSONEncode(M.data) end)
  if ok then pcall(FS.writefile, M.path, json) end
end

function M.load()
  if not (FS.isfile and FS.readfile and HttpService) then return end
  if not FS.isfile(M.path) then return end
  local ok, raw = pcall(FS.readfile, M.path)
  if not ok or not raw or #raw == 0 then return end
  local ok2, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
  if ok2 and typeof(decoded) == "table" then
    M.data = decoded
    M.data.toggles = M.data.toggles or { findTB=false, autoReplay=false, autoSelect=false }
    M.data.filters = M.data.filters or {}
  end
end

return M