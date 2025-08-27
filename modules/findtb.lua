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

-- UI Elements
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MainGui"
ScreenGui.Parent = game:GetService("CoreGui")

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(0, 10, 0, 10)
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleButton.TextColor3 = Color3.new(1,1,1)
ToggleButton.Text = "Find Trait Burner: OFF"
ToggleButton.Parent = ScreenGui

local toggleActive = false

local function toggleTB()
    toggleActive = not toggleActive
    if toggleActive then
        ToggleButton.Text = "Find Trait Burner: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        -- Start FindTB (module via loadstring)
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
                warn("[UI/FindTB] Failed to start module: " .. tostring(err))
            end
        end)
        local okResume, resumeErr = coroutine.resume(findTBLastThread)
        if not okResume then
            warn("[UI/FindTB] coroutine resume failed: " .. tostring(resumeErr))
        end
    else
        ToggleButton.Text = "Find Trait Burner: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        -- Stop FindTB (signal the module to halt)
        _G.FindTBActive = false
        -- Optional: nothing else to do; the module loop checks this and exits gracefully
    end
end

ToggleButton.MouseButton1Click:Connect(toggleTB)
