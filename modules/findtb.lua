-- ===== FIND TB external module bridge (loader + cache) =====
-- Purpose:
--  - Toggle from the UI sets _G/FindTBActive
--  - Bridge lazily loads the *implementation* file once
--  - Implementation may auto-start on load (no start() required)
--  - Safe if the implementation returns nil

local IMPL_URL = "https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/findtb_impl.lua"

local function getFindTBModule()
    -- Reuse cached module if available
    local cached = nil
    pcall(function()
        if getgenv then cached = getgenv()._FindTBMod end
    end)
    if cached ~= nil then
        return cached
    end

    local ok, ret_or_err = pcall(function()
        local src = game:HttpGet(IMPL_URL)
        local fn  = loadstring(src)
        if type(fn) ~= "function" then
            return nil, "loader returned non-function"
        end
        -- Execute implementation. It may return a table OR nil (auto-start style).
        local mod = fn()
        return mod
    end)

    if not ok then
        warn("[FindTB] failed to load implementation: " .. tostring(ret_or_err))
        return nil
    end

    -- Cache whatever we got (table or nil) to avoid refetching
    pcall(function()
        if getgenv then getgenv()._FindTBMod = ret_or_err end
    end)

    return ret_or_err
end

local function startFindTB()
    -- Signal active state for the implementation (it reads this flag)
    pcall(function()
        if getgenv then getgenv().FindTBActive = true end
        _G.FindTBActive = true
    end)

    local mod = getFindTBModule()
    -- Some implementations export start(); others auto-start when FindTBActive=true.
    if type(mod) == "table" and type(mod.start) == "function" then
        local ok, err = pcall(mod.start)
        if not ok then
            warn("[FindTB] start() error: " .. tostring(err))
        end
    else
        -- No explicit start() needed (auto-start style). This is fine.
        print("[FindTB] implementation loaded (auto-start).")
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
    if type(mod) == "table" and type(mod.stop) == "function" then
        local ok, err = pcall(mod.stop)
        if not ok then
            warn("[FindTB] stop() error: " .. tostring(err))
        end
    else
        print("[FindTB] stop signal sent (no explicit stop() in impl).")
    end
end

-- Expose bridge API globally so main UI can call it.
pcall(function()
    if getgenv then
        getgenv().FindTB_Bridge = {
            start = startFindTB,
            stop  = stopFindTB,
        }
    end
end)

return {
    start = startFindTB,
    stop  = stopFindTB,
}
