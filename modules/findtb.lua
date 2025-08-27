-- ############################################################
-- # FIND TRAIT BURNER (TP + EXPERT + TB FAST + JOIN Remote)
-- # Modo ligero: mínimos logs y menos overhead
-- ############################################################

-- ===== Servicios base =====
local Players  = game:GetService("Players")
local Rep      = game:GetService("ReplicatedStorage")
local Run      = game:GetService("RunService")
local vim      = game:GetService("VirtualInputManager")
local LP       = Players.LocalPlayer
local PG       = LP:WaitForChild("PlayerGui")
local RF       = Rep:WaitForChild("Remotes"):WaitForChild("GetFunction")

-- ===== Filter (optional; UI may configure allowed maps/challenges) =====
local Filter = (getgenv and getgenv().MoonFilter)
            or (function()
                  local ok, mod = pcall(function()
                    return loadstring(game:HttpGet("https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/filter.lua"))()
                  end)
                  if ok then return mod end
                  return nil
                end)()

-- ===== Config =====
local UI_TIMEOUT_SEC   = 20
local RETRIES_PRESS    = 3
local WAIT_BETWEEN_TRY = 0.35
local TB_EVENT_WINDOW  = 1.3
local CHAPTER          = 1
local DIFFICULTY       = "Hard"

-- ===== Estado =====
local LAST_SELECTED = "Challenge1"
local ENTERED       = false

-- ------------------------------------------------------------
-- Util: descender por ruta con espera
-- ------------------------------------------------------------
local function descend(root, segments, timeout)
    local t0 = tick()
    local node = root
    for _,name in ipairs(segments) do
        while not (node and node:FindFirstChild(name)) do
            if tick() - t0 > (timeout or UI_TIMEOUT_SEC) then
                return nil
            end
            if not node then return nil end
            node.ChildAdded:Wait()
        end
        node = node[name]
    end
    return node
end

-- ------------------------------------------------------------
-- getconnections seguro
-- ------------------------------------------------------------
local function get_gc()
    local okEnv, env = pcall(function() return getgenv and getgenv() end)
    if okEnv and type(env)=="table" and type(env.getconnections)=="function" then
        return env.getconnections
    end
    if type(_G)=="table" and type(_G.getconnections)=="function" then
        return _G.getconnections
    end
    if type(getconnections)=="function" then
        return getconnections
    end
    return nil
end

-- ------------------------------------------------------------
-- Click robusto
-- ------------------------------------------------------------
local function robustClick(btn)
    if not (btn and btn:IsA("TextButton")) then return false end

    -- firesignal si existe
    local fs = (getgenv and getgenv().firesignal) or (_G and _G.firesignal)
    if type(fs)=="function" then
        pcall(function()
            if typeof(btn.MouseButton1Click) == "RBXScriptSignal" then fs(btn.MouseButton1Click) end
            if typeof(btn.Activated)        == "RBXScriptSignal" then fs(btn.Activated)        end
        end)
        return true
    end

    -- getconnections
    local gc = get_gc()
    if gc then
        pcall(function()
            if typeof(btn.MouseButton1Click)=="RBXScriptSignal" then
                for _,c in ipairs(gc(btn.MouseButton1Click)) do
                    if c and c.Function and c.Connected ~= false then pcall(c.Function) end
                end
            end
            if typeof(btn.Activated)=="RBXScriptSignal" then
                for _,c in ipairs(gc(btn.Activated)) do
                    if c and c.Function and c.Connected ~= false then pcall(c.Function) end
                end
            end
        end)
        task.wait(0.02)
    end

    -- VirtualInputManager
    pcall(function()
        local center = btn.AbsolutePosition + (btn.AbsoluteSize/2)
        vim:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
        vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
    end)

    return true
end

-- ------------------------------------------------------------
-- TP al Pod de Challenges
-- ------------------------------------------------------------
local function tpToChallengePod()
    local obj = workspace:FindFirstChild("Map")
              and workspace.Map:FindFirstChild("Buildings")
              and workspace.Map.Buildings:FindFirstChild("ChallengePods")
    if obj and obj:FindFirstChild("Pod") and obj.Pod:FindFirstChild("Interact") then
        obj = obj.Pod.Interact
    else
        local cp = obj
        if cp then
            for _,d in ipairs(cp:GetDescendants()) do
                if d.Name == "Interact" then obj = d break end
            end
        end
    end
    if not obj then return false end
    local ok = pcall(function()
        RF:InvokeServer({ Type = "Lobby", Object = obj, Mode = "Pod" })
    end)
    return ok
end


-- ------------------------------------------------------------
-- Trait Burner detector (ligero)
-- ------------------------------------------------------------
local PATH_REWARD_SCROLL = {
  "MainUI","WorldFrame","WorldFrame","MainFrame","RightFrame","InfoFrame","InfoInner",
  "BoxFrame","InfoFrame2","InnerFrame","CanvasFrame","CanvasGroup","BottomFrame",
  "DetailFrame","RewardFrame","Rewards","RewardScroll"
}

local function ci_contains(s, needle)
  s = tostring(s or ""):lower(); needle = tostring(needle or ""):lower()
  return s:find(needle, 1, true) ~= nil
end

local function deepScanForTB(scroll)
  for _,n in ipairs(scroll:GetDescendants()) do
    if n:IsA("TextLabel") and n.Text and ci_contains(n.Text, "trait burner") then
      return true
    end
    if n:IsA("StringValue") and n.Value and ci_contains(n.Value, "trait burner") then
      return true
    end
  end
  return false
end

local function hasTraitBurner_fast()
  local scroll = descend(PG, PATH_REWARD_SCROLL, 6.0)
  if not scroll then return false end

  if deepScanForTB(scroll) then return true end

  local found = false
  local conn = scroll.DescendantAdded:Connect(function(n)
    if found then return end
    if (n:IsA("TextLabel") and n.Text and ci_contains(n.Text, "trait burner"))
    or (n:IsA("StringValue") and n.Value and ci_contains(n.Value, "trait burner")) then
      found = true
    end
  end)
  local t0 = tick()
  while not found and tick()-t0 < TB_EVENT_WINDOW do
    Run.RenderStepped:Wait()
  end
  pcall(function() conn:Disconnect() end)

  if found then return true end
  return deepScanForTB(scroll)
end

-- ------------------------------------------------------------
-- Join via Remote
-- ------------------------------------------------------------
local function start_challenge_via_remote(name, chapter, difficulty)
    name       = name or LAST_SELECTED or "Challenge1"
    chapter    = chapter or CHAPTER
    difficulty = difficulty or DIFFICULTY
    local payload = {
        Chapter = chapter, Type = "Lobby", Name = name,
        Friend = true, Mode = "Pod", Update = true, Difficulty = difficulty
    }
    pcall(function() RF:InvokeServer(payload) end)
end

-- Dispara el botón "Start" via Remote (payload corto)
local function press_start_remote()
    local payload = { Start = true, Type = "Lobby", Update = true, Mode = "Pod" }
    pcall(function() RF:InvokeServer(payload) end)
end

-- ===================== Helpers StageScroll + EXPERT refresh =========
local function findStageScroll()
    local ok, scroll = pcall(function()
        return PG.MainUI.WorldFrame.WorldFrame.MainFrame.StageFrame.Stages.StageScroll
    end)
    if ok and typeof(scroll)=="Instance" then return scroll end
    for _,d in ipairs(PG:GetDescendants()) do
        if d.Name=="StageScroll" then return d end
    end
    return nil
end

-- Espera de refresh basada en eventos (sin fingerprint)
local function waitRewardsRefresh(timeout)
    timeout = timeout or 2.0
    local r = descend(PG, PATH_REWARD_SCROLL, 0.8)
    if not r then
        task.wait(0.25)
        return
    end
    local updated, t0 = false, tick()
    local connA = r.DescendantAdded:Connect(function() updated = true end)
    local connR = r.DescendantRemoving:Connect(function() updated = true end)
    repeat
        Run.RenderStepped:Wait()
    until updated or (tick()-t0) > timeout
    pcall(function() connA:Disconnect() end)
    pcall(function() connR:Disconnect() end)
end

local function findExpertButton()
    local segments = {
        "MainUI","WorldFrame","WorldFrame","MainFrame","RightFrame","InfoFrame",
        "InfoInner","BoxFrame","InfoFrame2","InnerFrame","RecordFrame","RecordInfo",
        "DifficultFrame","Hard","Button"
    }
    local btn = descend(PG, segments, 3.0)
    if btn and btn:IsA("TextButton") then return btn end
    local rr = descend(PG, {"MainUI","WorldFrame","WorldFrame","MainFrame","RightFrame"}, 2.0)
    if rr then
        for _,n in ipairs(rr:GetDescendants()) do
            if n:IsA("TextButton") then
                local t = (n.Text or n.Name or ""):lower()
                if t:find("expert",1,true) then return n end
            end
        end
    end
    return nil
end

local CHALLENGE_KEYWORDS = {
    "random units","random","everything but imagination","random enemies",
    "flying enemies","flying","juggernaut","boss rush","single placement","single",
    "high cost","increased cost","time limit","limited time","no sell","cannot sell",
    "double hp","more hp"
}

-- Escanea RightFrame para deducir el “hint” de challenge (texto libre del UI)
local function getChallengeTypeHint()
    local rr = descend(PG, {"MainUI","WorldFrame","WorldFrame","MainFrame","RightFrame"}, 2.0)
    if not rr then return "" end
    for _,n in ipairs(rr:GetDescendants()) do
        if n:IsA("TextLabel") and n.Text and #n.Text > 0 then
            local tx = n.Text:lower()
            for _,kw in ipairs(CHALLENGE_KEYWORDS) do
                if tx:find(kw, 1, true) then
                    return kw
                end
            end
        end
    end
    return ""
end

-- Detect current map name by scanning the RightFrame texts against the known map list
local function detectCurrentMapName()
    local maps = {}
    if Filter and type(Filter.listMaps) == "function" then
        maps = Filter.listMaps()
    else
        maps = {
            "Innovation Island","Giant Island","Future City (Ruins)",
            "City of Voldstandig","Hidden Storm Village","City of York",
            "Shadow Tournament"
        }
    end
    local root = descend(PG, {"MainUI","WorldFrame","WorldFrame","MainFrame","RightFrame"}, 2.0)
    if not root then return "" end
    -- pre-lower all candidates
    local lowers = {}
    for _,m in ipairs(maps) do lowers[m] = m:lower() end
    for _,n in ipairs(root:GetDescendants()) do
        if n:IsA("TextLabel") and typeof(n.Text)=="string" and #n.Text>0 then
            local txt = n.Text:lower()
            for orig,low in pairs(lowers) do
                if txt:find(low, 1, true) then
                    return orig
                end
            end
        end
    end
    return ""
end

-- Map loose "type hints" to canonical challenge names used by Filter
local function canonicalChallengeFromHint(hint)
    hint = tostring(hint or ""):lower()
    if hint:find("random",1,true) or hint:find("everything but imagination",1,true) then
        return "Random Units"
    end
    if hint:find("flying",1,true) then
        return "Flying Enemies"
    end
    if hint:find("juggernaut",1,true) then
        return "Juggernaut Enemies"
    end
    if hint:find("single",1,true) then
        return "Single Placement"
    end
    if hint:find("high cost",1,true) or hint:find("increased cost",1,true) then
        return "High Cost"
    end
    return ""
end

local function clickTextButton(btn)
    if not (btn and btn:IsA("TextButton")) then return false end
    local ok = select(1, pcall(function() robustClick(btn) end))
    task.wait(0.04)
    return ok
end

local function scan_challenge(i)
    local scroll = findStageScroll()
    if not scroll then return {ok=false} end
    local node = scroll:FindFirstChild("Challenge"..i)
    local btn  = node and node:FindFirstChild("Button")
    if not (btn and btn:IsA("TextButton")) then return {ok=false} end

    LAST_SELECTED = "Challenge"..i
    clickTextButton(btn)
    waitRewardsRefresh(1.0)

    local expBtn = findExpertButton()
    if expBtn then
        clickTextButton(expBtn)
        waitRewardsRefresh(1.6)
    end

    local typeHint = (getChallengeTypeHint() or ""):lower()
    local canonCh  = canonicalChallengeFromHint(typeHint)
    local mapName  = detectCurrentMapName()

    -- Respetar filtro incluso si no se pudo detectar el challenge (canonCh=="")
    if Filter and mapName ~= "" then
        local allowed = false
        pcall(function()
            if type(Filter.isAllowed) == "function" then
                if canonCh ~= "" then
                    -- Caso normal: challenge detectado
                    allowed = Filter.isAllowed(mapName, canonCh)
                else
                    -- Fallback: si el mapa no tiene NINGÚN challenge seleccionado, debe quedar ignorado
                    if type(Filter.isMapAllowed) == "function" then
                        allowed = Filter.isMapAllowed(mapName)
                    else
                        allowed = false
                    end
                end
            end
        end)
        if not allowed then
            return {ok=true, index=i, filtered=true, map=mapName, challenge=canonCh, has_tb=false}
        end
    end

    local hasTB = false
    pcall(function() hasTB = hasTraitBurner_fast() end)

    return {ok=true, index=i, type_hint=typeHint, challenge=canonCh, map=mapName, has_tb=hasTB}
end

-- ===================== MODULE API (controlled by UI) ============================
local M = {}
local running = false

function M.start()
    if running then return end
    running = true
    ENTERED = false

    task.spawn(function()
        tpToChallengePod()
        descend(PG, {"MainUI","WorldFrame"}, 6.0)

        local FOUND = false
        for i=1,4 do
            if not running or ENTERED then break end
            local res = scan_challenge(i)
            if res.ok then
                -- respetar filtro si ya se aplicó dentro de scan_challenge
                if res.filtered then
                    -- saltado por filtro del usuario
                else
                    local hint = res.type_hint or ""
                    local isRandom = (hint:find("random",1,true) ~= nil)
                                   or (hint:find("everything but imagination",1,true) ~= nil)
                    if res.has_tb and not isRandom then
                        ENTERED = true
                        start_challenge_via_remote("Challenge"..i, CHAPTER, DIFFICULTY)
                        task.wait(0.25)
                        press_start_remote()
                        FOUND = true
                        break
                    end
                end
            end
            task.wait(0.12)
        end

        if not FOUND and running then
            -- ===== Auto-rescan (ligero) =====
            local RESCAN_EVERY_SEC = 5
            local MAX_ROUNDS = 240

            task.spawn(function()
                task.wait(6)
                for _=1,MAX_ROUNDS do
                    if not running or ENTERED then break end
                    local found = false
                    for i=1,4 do
                        if not running or ENTERED then break end
                        local res = scan_challenge(i)
                        if res.ok then
                            -- respetar filtro si ya se aplicó dentro de scan_challenge
                            if res.filtered then
                                -- saltado por filtro del usuario
                            else
                                local hint = res.type_hint or ""
                                local isRandom = (hint:find("random",1,true) ~= nil)
                                               or (hint:find("everything but imagination",1,true) ~= nil)
                                if res.has_tb and not isRandom then
                                    ENTERED = true
                                    start_challenge_via_remote("Challenge"..i, CHAPTER, DIFFICULTY)
                                    task.wait(0.25)
                                    press_start_remote()
                                    found = true
                                    break
                                end
                            end
                        end
                        task.wait(0.12)
                    end
                    if found or not running or ENTERED then break end
                    task.wait(RESCAN_EVERY_SEC)
                end
            end)
        end
    end)
end

function M.stop()
    running = false
    ENTERED = true -- forza la salida de los bucles activos
    print("[FindTB] stopped by UI toggle")
end

return M
