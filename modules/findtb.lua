-- Services
local TweenService = game:GetService("TweenService")

-- === FindTB bridge loader (on-demand) ===
local function ensureFindTBBridge()
  -- already present?
  local present = false
  pcall(function()
    present = (getgenv and getgenv().FindTB_Bridge ~= nil)
  end)
  if present then return true end

  -- fetch and run the loader
  local ok, err = pcall(function()
    local src = game:HttpGet("https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/findtb.lua")
    local f = loadstring(src)
    if type(f) == "function" then f() end
  end)
  if not ok then
    warn("[UI] FindTB loader fetch failed: " .. tostring(err))
    return false
  end

  -- confirm presence
  local ready = false
  pcall(function()
    ready = (getgenv and getgenv().FindTB_Bridge ~= nil)
  end)
  if not ready then
    warn("[UI] FindTB_Bridge not available after load.")
  end
  return ready
end

-- ... (rest of the code before toggleTB)

local function toggleTB()
  -- ... (code before start block)

  -- Start FindTB (external bridge)
  if ensureFindTBBridge() then
    pcall(function()
      getgenv().FindTB_Bridge.start()
    end)
  end

  -- ... (code between start and stop blocks)

  -- Stop FindTB (external bridge)
  pcall(function()
    if getgenv and getgenv().FindTB_Bridge then
      getgenv().FindTB_Bridge.stop()
    end
  end)

  -- ... (rest of toggleTB code)
end

-- ... (rest of the code before close button connection)

closeButton.MouseButton1Click:Connect(function()
  -- be nice: stop FindTB if running
  pcall(function()
    if getgenv and getgenv().FindTB_Bridge then
      getgenv().FindTB_Bridge.stop()
    end
  end)
  gui:Destroy()
end)

-- ... (rest of the file)
