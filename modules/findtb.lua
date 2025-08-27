-- ===== FIND TB external module bridge (loader + cache) =====
local function getFindTBModule()
    -- Reuse cached module if available
    local cached = nil
    pcall(function()
        if getgenv then cached = getgenv()._FindTBMod end
    end)
    if cached and type(cached) == "table" then
        return cached
    end

    local url = "https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/findtb.lua"
    local ok, ret = pcall(function()
        local src = game:HttpGet(url)
        local fn = loadstring(src)
        if type(fn) ~= "function" then
            return nil, "loader returned non-function"
        end
        -- Ensure the module returns its API table
        local mod = fn()
        return mod
    end)

    if not ok or type(ret) ~= "table" then
        warn("[FindTB] failed to load external module: " .. tostring(ret))
        return nil
    end

    -- Cache for subsequent uses
    pcall(function()
        if getgenv then getgenv()._FindTBMod = ret end
    end)

    return ret
end

local function startFindTB()
    -- Signal active state for the module (it reads this flag)
    pcall(function()
        if getgenv then getgenv().FindTBActive = true end
        _G.FindTBActive = true
    end)

    local mod = getFindTBModule()
    if mod and type(mod.start) == "function" then
        local ok, err = pcall(mod.start)
        if not ok then
            warn("[FindTB] start() error: " .. tostring(err))
        end
    else
        warn("[FindTB] module missing start()")
    end
end

local function stopFindTB()
    pcall(function()
        if getgenv then getgenv().FindTBActive = false end
        _G.FindTBActive = false
    end)

    local mod = nil
    pcall(function()
        if getgenv then mod = getgenv()._FindTBMod end
    end)
    if mod and type(mod.stop) == "function" then
        local ok, err = pcall(mod.stop)
        if not ok then
            warn("[FindTB] stop() error: " .. tostring(err))
        end
    end
end
-- ===== end bridge =====

-- Toggle Functionality
local function toggleTB()
    isTBActive = not isTBActive
    if isTBActive then
        -- Animate to ON
        TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Position = UDim2.new(1, -24, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5)
        }):Play()
        TweenService:Create(toggleSwitch, TweenInfo.new(0.2), {
            BackgroundColor3 = COLORS.accent
        }):Play()

        -- Start external FindTB module
        startFindTB()
    else
        -- Animate to OFF
        TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0, 2, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5)
        }):Play()
        TweenService:Create(toggleSwitch, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        }):Play()

        -- Stop external FindTB module
        stopFindTB()
    end
end
