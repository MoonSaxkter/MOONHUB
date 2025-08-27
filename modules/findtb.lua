-- ############################################################
--  MOONHUB - Find Trait Burner (UI Toggle Controlled)
--  Self-contained implementation (no remote self-fetch)
--  Presses Expert, detects Trait Burner, and sends Start payload.
-- ############################################################

-- ===== Guard: allow Start/Stop from UI toggle =====
if _G.FindTBActive == nil then _G.FindTBActive = false end

-- ===== Services =====
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local PG = LP and LP:WaitForChild("PlayerGui")

-- ===== Config =====
local UI_TIMEOUT_SEC    = 20
local RETRIES_PRESS     = 3
local WAIT_BETWEEN_TRY  = 0.35
local TB_EVENT_WINDOW   = 1.3
local CHAPTER           = 1
local DIFFICULTY        = "Hard"
local AUTO_RESCAN       = true
local RESCAN_EVERY_SEC  = 5
local MAX_ROUNDS        = 240

-- ===== State =====
local workerThread  = nil
local ENTERED       = false
local LAST_SELECTED = "Challenge1"

-- ===== Remotes =====
local RF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetFunction")

-- ------------------------------------------------------------
-- Helpers: safe descendant path
-- ------------------------------------------------------------
local function descend(root, segments, timeout)
    local t0 = tick()
    local node = root
    for _, name in ipairs(segments) do
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
-- Robust click (firesignal -> getconnections -> VirtualInputManager)
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

local function robustClick(btn)
    if not (btn and btn:IsA("TextButton")) then return false end
    local fs = (getgenv and getgenv().firesignal) or (_G and _G.firesignal)
    if type(fs) == "function" then
        pcall(function()
            if typeof(btn.MouseButton1Click) == "RBXScriptSignal" then fs(btn.MouseButton1Click) end
            if typeof(btn.Activated)        == "RBXScriptSignal" then fs(btn.Activated)        end
        end)
        return true
    end
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
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local center = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
        vim:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
        vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
    end)
    return true
end

local function clickTextButton(btn)
    if not (btn and btn:IsA("TextButton")) then return false end
    local ok = select(1, pcall(function() robustClick(btn) end))
    task.wait(0.04)
    return ok
end

-- ------------------------------------------------------------
-- TP to Challenge Pod (server-side remote)
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
            for _, d in ipairs(cp:GetDescendants()) do
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
-- Expert button (sometimes named Hard). Try exact path, then fallback by text.
-- ------------------------------------------------------------
local function findExpertButton()
    local segments = {
        "MainUI","WorldFrame","WorldFrame","MainFrame","RightFrame","InfoFrame",
        "InfoInner","BoxFrame","InfoFrame2","InnerFrame","RecordFrame","RecordInfo",
        "DifficultFrame","Hard","Button" -- many games use "Hard" here but label shows "Expert"
    }
    local btn = descend(PG, segments, 3.0)
    if btn and btn:IsA("TextButton") then return btn end

    local rr = descend(PG, {"MainUI","WorldFrame","WorldFrame","MainFrame","RightFrame"}, 2.0)
    if rr then
        for _,n in ipairs(rr:GetDescendants()) do
            if n:IsA("TextButton") then
                local t = (n.Text or n.Name or ""):lower()
                if t:find("expert",1,true) or t:find("hard",1,true) then
                    return n
                end
            end
        end
    end
    return nil
end

local function waitRewardsRefresh(timeout)
    timeout = timeout or 2.0
    local r = descend(PG, {
        "MainUI","WorldFrame","WorldFrame","MainFrame","RightFrame","InfoFrame","InfoInner",
        "BoxFrame","InfoFrame2","InnerFrame","CanvasFrame","CanvasGroup","BottomFrame",
        "DetailFrame","RewardFrame","Rewards","RewardScroll"
    }, 0.8)
    if not r then task.wait(0.25) return end
    local updated, t0 = false, tick()
    local a = r.DescendantAdded:Connect(function()  updated = true end)
    local b = r.DescendantRemoving:Connect(function() updated = true end)
    repeat RunService.RenderStepped:Wait() until updated or (tick()-t0) > timeout
    pcall(function() a:Disconnect() end)
    pcall(function() b:Disconnect() end)
end

-- ------------------------------------------------------------
-- TB detection (lightweight)
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
    RunService.RenderStepped:Wait()
  end
  pcall(function() conn:Disconnect() end)
  if found then return true end
  return deepScanForTB(scroll)
end

-- ------------------------------------------------------------
-- Server payloads to start the challenge
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

local function confirm_start_payload()
    -- This is the second payload observed in logs:
    -- {"Start":true,"Type":"Lobby","Update":true,"Mode":"Pod"}
    local ok, err = pcall(function()
        RF:InvokeServer({Start = true, Type = "Lobby", Update = true, Mode = "Pod"})
    end)
    return ok
end

-- ------------------------------------------------------------
-- Stage scroll + scan logic
-- ------------------------------------------------------------
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

local function scan_challenge(i)
    local scroll = findStageScroll()
    if not scroll then return {ok=false} end
    local node = scroll:FindFirstChild("Challenge"..i)
    local btn  = node and node:FindFirstChild("Button")
    if not (btn and btn:IsA("TextButton")) then return {ok=false} end

    LAST_SELECTED = "Challenge"..i

    -- 1) Open challenge card
    clickTextButton(btn)
    waitRewardsRefresh(0.8)

    -- 2) Press Expert/Hard with retries and validate by forcing a refresh
    local expBtn = findExpertButton()
    if expBtn then
        local pressed = false
        for r=1,RETRIES_PRESS do
            clickTextButton(expBtn)
            RunService.RenderStepped:Wait()
            waitRewardsRefresh(1.0)
            -- Force UI to refresh the reward list by re-opening the same card
            clickTextButton(btn)
            waitRewardsRefresh(1.0)
            -- If after pressing Expert and refreshing we can see TB, we stop retrying later
            pressed = true
            -- break is intentionally deferred; we'll still run TB check below
            if pressed then break end
        end
    end

    -- 3) TB detection
    local hasTB = false
    pcall(function() hasTB = hasTraitBurner_fast() end)

    return {ok=true, index=i, has_tb=hasTB}
end

-- ------------------------------------------------------------
-- Worker
-- ------------------------------------------------------------
local function run_worker()
    tpToChallengePod()
    descend(PG, {"MainUI","WorldFrame"}, 6.0)

    ENTERED = false
    local FOUND = false

    for i=1,4 do
        if not _G.FindTBActive or ENTERED then break end
        local res = scan_challenge(i)
        if res.ok and res.has_tb then
            ENTERED = true
            start_challenge_via_remote("Challenge"..i, CHAPTER, DIFFICULTY)
            task.wait(0.3)
            confirm_start_payload()
            FOUND = true
            break
        end
        task.wait(0.12)
    end

    if AUTO_RESCAN and (not FOUND) then
        task.spawn(function()
            task.wait(6)
            for _=1,MAX_ROUNDS do
                if not _G.FindTBActive or ENTERED then break end
                local found = false
                for i=1,4 do
                    if not _G.FindTBActive or ENTERED then break end
                    local res = scan_challenge(i)
                    if res.ok and res.has_tb then
                        ENTERED = true
                        start_challenge_via_remote("Challenge"..i, CHAPTER, DIFFICULTY)
                        task.wait(0.3)
                        confirm_start_payload()
                        found = true
                        break
                    end
                    task.wait(0.12)
                end
                if found or ENTERED then break end
                task.wait(RESCAN_EVERY_SEC)
            end
        end)
    end
end

-- ------------------------------------------------------------
-- Public API exposed for UI toggle
-- ------------------------------------------------------------
function FindTB_Start()
    if _G.FindTBActive then return end
    _G.FindTBActive = true
    if workerThread and coroutine.status(workerThread) ~= "dead" then
        -- let the previous finish naturally; new run will start
    end
    workerThread = coroutine.create(function()
        local ok, err = pcall(run_worker)
        if not ok then warn("[FindTB] Worker error: "..tostring(err)) end
    end)
    local okResume, resumeErr = coroutine.resume(workerThread)
    if not okResume then
        warn("[FindTB] coroutine resume failed: " .. tostring(resumeErr))
    end
end

function FindTB_Stop()
    _G.FindTBActive = false
    ENTERED = true -- stop loops quickly
end

return {
    start = FindTB_Start,
    stop  = FindTB_Stop,
    status = function()
        return {active = not not _G.FindTBActive, entered = not not ENTERED, lastSelected = LAST_SELECTED}
    end
}
