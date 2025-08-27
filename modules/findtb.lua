-- ############################################################
-- # FIND TRAIT BURNER (TP + EXPERT + TB FAST + JOIN Remote)
-- # Modo ligero: mínimos logs y menos overhead
-- ############################################################

-- === External toggle guard (controlled from main.lua) ===
if _G.FindTBActive == false then
    return { 
        stop = function() end, 
        status = function() return { active = false, entered = false, lastSelected = "Challenge1" } end 
    }
end
_G.FindTBActive = true

-- ===== Servicios base =====
local Players  = game:GetService("Players")
local Rep      = game:GetService("ReplicatedStorage")
local Run      = game:GetService("RunService")
local vim      = game:GetService("VirtualInputManager")
local LP       = Players.LocalPlayer
local PG       = LP:WaitForChild("PlayerGui")
local RF       = Rep:WaitForChild("Remotes"):WaitForChild("GetFunction")

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
-- EXPERT (Hard.Button)
-- ------------------------------------------------------------
local function pressExpert()
    local segments = {
        "MainUI","WorldFrame","WorldFrame","MainFrame","RightFrame","InfoFrame",
        "InfoInner","BoxFrame","InfoFrame2","InnerFrame","RecordFrame","RecordInfo",
        "DifficultFrame","Hard","Button"
    }
    local btn = descend(PG, segments, 6.0)
    if not btn then return false end
    local ok = false
    for _=1,RETRIES_PRESS do
        ok = select(1, pcall(function() robustClick(btn) end))
        if ok then break end
        task.wait(WAIT_BETWEEN_TRY)
    end
    Run.RenderStepped:Wait(); Run.RenderStepped:Wait()
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

local function getChallengeTypeHint()
    local rr = descend(PG, {"MainUI","WorldFrame","WorldFrame","MainFrame","RightFrame"}, 2.0)
    if not rr then return "" end
    for _,n in ipairs(rr:GetDescendants()) do
        if n:IsA("TextLabel") and n.Text and #n.Text>0 then
            local tx = n.Text:lower()
            for _,kw in ipairs(CHALLENGE_KEYWORDS) do
                if tx:find(kw,1,true) then return kw end
            end
        end
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
    local hasTB = false
    pcall(function() hasTB = hasTraitBurner_fast() end)

    return {ok=true, index=i, type_hint=typeHint, has_tb=hasTB}
end

-- ===================== MAIN FLOW ============================
task.spawn(function()
    if not _G.FindTBActive then return end
    tpToChallengePod()
    descend(PG, {"MainUI","WorldFrame"}, 6.0)

    local FOUND = false
    for i=1,4 do
        if not _G.FindTBActive then break end
        local res = scan_challenge(i)
        if res.ok then
            local hint = res.type_hint or ""
            local isRandom = (hint:find("random",1,true) ~= nil)
                           or (hint:find("everything but imagination",1,true) ~= nil)
            if res.has_tb and not isRandom then
                ENTERED = true
                start_challenge_via_remote("Challenge"..i, CHAPTER, DIFFICULTY)
                FOUND = true
                break
            end
        end
        task.wait(0.12)
    end

    if not FOUND then
        -- silencioso: no imprime nada si no encuentra
    end
end)

print("[ASTD-X] listo (ligero)")

-- ===== Auto-rescan (ligero) =====
local AUTO_RESCAN = true
local RESCAN_EVERY_SEC = 5
local MAX_ROUNDS = 240

if AUTO_RESCAN then
  task.spawn(function()
    task.wait(6)
    for _=1,MAX_ROUNDS do
      if not _G.FindTBActive or ENTERED then break end
      local found = false
      for i=1,4 do
        if not _G.FindTBActive or ENTERED then break end
        local res = scan_challenge(i)
        if res.ok then
          local hint = res.type_hint or ""
          local isRandom = (hint:find("random",1,true) ~= nil)
                         or (hint:find("everything but imagination",1,true) ~= nil)
          if res.has_tb and not isRandom then
            ENTERED = true
            start_challenge_via_remote("Challenge"..i, CHAPTER, DIFFICULTY)
            found = true
            break
          end
        end
        task.wait(0.12)
      end
      if found or ENTERED then break end
      task.wait(RESCAN_EVERY_SEC)
    end
  end)
end

return {
    stop = function()
        _G.FindTBActive = false
        ENTERED = true -- force all loops to end
        print("[FindTB] Module stopped")
    end,
    status = function()
        return {
            active = not not _G.FindTBActive,
            entered = not not ENTERED,
            lastSelected = LAST_SELECTED
        }
    end
}
