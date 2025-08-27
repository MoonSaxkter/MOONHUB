-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local FINDTB_URL = "https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/findtb.lua"

-- Modules & State
local findTBLastThread = nil

function FindTB_Start()
    _G.FindTBActive = true
    if findTBLastThread and coroutine.status(findTBLastThread) ~= "dead" then
        -- let old run finish; the module reads _G.FindTBActive each loop
    end
    findTBLastThread = coroutine.create(function()
        local ok, err = pcall(function()
            local src = game:HttpGet(FINDTB_URL)
            local fn = loadstring(src)
            if type(fn) == "function" then fn() end
        end)
        if not ok then
            warn("[FindTB] Failed to start module: " .. tostring(err))
        end
    end)
    local okResume, resumeErr = coroutine.resume(findTBLastThread)
    if not okResume then
        warn("[FindTB] coroutine resume failed: " .. tostring(resumeErr))
    end
end

function FindTB_Stop()
    _G.FindTBActive = false
end
