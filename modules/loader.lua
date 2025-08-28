local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local M = {}

local function _corner(parent, radius)
  local c = Instance.new("UICorner")
  c.CornerRadius = UDim.new(0, radius or 8)
  c.Parent = parent
  return c
end
local function _stroke(parent, color, thickness, transparency)
  local s = Instance.new("UIStroke")
  s.Color = color or Color3.fromRGB(70,70,85)
  s.Thickness = thickness or 1
  s.Transparency = transparency or 0.5
  s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
  s.Parent = parent
  return s
end

local function getUILayer(player)
  local ok, cg = pcall(function() return game:GetService("CoreGui") end)
  if ok and cg then return cg end
  return player:WaitForChild("PlayerGui")
end

local function killBlur(name)
  local Lighting = game:GetService("Lighting")
  local b = Lighting:FindFirstChild(name)
  if b then b:Destroy() end
end

function M.show(player)
  if _G.MOONHUB_NO_LOADER then return end
  killBlur("MoonHubLoaderBlur")
  local layer = getUILayer(player)

  local loaderGui = Instance.new("ScreenGui")
  loaderGui.Name = "MoonHubLoader"; loaderGui.IgnoreGuiInset = true
  loaderGui.DisplayOrder = 1_000_000; loaderGui.ResetOnSpawn = false
  loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  loaderGui.Parent = layer

  local Lighting = game:GetService("Lighting")
  local blur = Instance.new("BlurEffect"); blur.Name = "MoonHubLoaderBlur"
  blur.Size = 6; blur.Parent = Lighting

  local overlay = Instance.new("Frame")
  overlay.BackgroundColor3 = Color3.fromRGB(0,0,0); overlay.BackgroundTransparency = 0.25
  overlay.BorderSizePixel = 0; overlay.Size = UDim2.new(1,0,1,0); overlay.Parent = loaderGui

  local card = Instance.new("Frame")
  card.Size = UDim2.new(0, 420, 0, 136)
  card.Position = UDim2.new(0.5, 0, 0.5, 0); card.AnchorPoint = Vector2.new(0.5, 0.5)
  card.BackgroundColor3 = Color3.fromRGB(25,25,32); card.BackgroundTransparency = 0.08
  card.Parent = loaderGui; _corner(card, 12); _stroke(card, Color3.fromRGB(70,70,85),1,0.5)
  TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {Size = UDim2.new(0, 420, 0, 136)}):Play()

  local logo = Instance.new("ImageLabel")
  logo.BackgroundTransparency = 1; logo.Image = "rbxassetid://102518679256494"
  logo.ScaleType = Enum.ScaleType.Fit; logo.Size = UDim2.new(0, 220, 0, 42)
  logo.Position = UDim2.new(0.5, 40, 0, 8); logo.AnchorPoint = Vector2.new(0.5, 0); logo.Parent = card

  local subtitle = Instance.new("TextLabel")
  subtitle.BackgroundTransparency = 1; subtitle.Text = "Loading…"
  subtitle.Font = Enum.Font.SourceSansSemibold; subtitle.TextSize = 16
  subtitle.TextColor3 = Color3.fromRGB(200,200,210)
  subtitle.Size = UDim2.new(1, -20, 0, 20); subtitle.Position = UDim2.new(0,10,0,56)
  subtitle.Parent = card

  local barBg = Instance.new("Frame")
  barBg.Size = UDim2.new(1, -20, 0, 12); barBg.Position = UDim2.new(0,10,0,98)
  barBg.BackgroundColor3 = Color3.fromRGB(40,40,50); barBg.Parent = card; _corner(barBg, 6)

  local barFill = Instance.new("Frame")
  barFill.Size = UDim2.new(0,0,1,0); barFill.BackgroundColor3 = Color3.fromRGB(150,100,255)
  barFill.Parent = barBg; _corner(barFill, 6)

  local pct = Instance.new("TextLabel")
  pct.BackgroundTransparency = 1; pct.Text = "0%"; pct.Font = Enum.Font.SourceSansBold
  pct.TextSize = 14; pct.TextColor3 = Color3.fromRGB(220,220,230)
  pct.Size = UDim2.new(1,0,0,16); pct.Position = UDim2.new(0,0,0,116); pct.Parent = card

  local function setProgress(n)
    n = math.clamp(n or 0, 0, 100)
    pct.Text = tostring(math.floor(n + 0.5)) .. "%"
    barFill.Size = UDim2.new(n/100, 0, 1, 0)
  end

  -- Heurísticas de “listo”
  local function uiReady()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end
    local main = pg:FindFirstChild("MainUI", true)
    local hasStats = main and main:FindFirstChild("CashFrame", true)
    local hasAny  = #pg:GetChildren() > 0
    return hasStats ~= nil or hasAny
  end

  local MIN_DISPLAY_SEC, SOFT_CAP_PERCENT, FINISH_DURATION = 5.5, 72, 1.25
  local timeoutSec, t0, progress = 75, os.clock(), 0
  setProgress(progress)

  while (os.clock() - t0) < timeoutSec do
    if progress < SOFT_CAP_PERCENT then
      progress = math.min(SOFT_CAP_PERCENT, progress + math.random(1,2))
      setProgress(progress)
    end
    local minTimePassed = (os.clock() - t0) >= MIN_DISPLAY_SEC
    local queue_small   = (ContentProvider.RequestQueueSize or 0) <= 1
    if minTimePassed and uiReady() and queue_small then break end
    task.wait(0.15)
  end

  subtitle.Text = "Ready"
  local start, t = progress, 0
  while t < FINISH_DURATION do
    t += task.wait()
    local alpha = math.clamp(t / FINISH_DURATION, 0, 1)
    setProgress(start + (100 - start) * alpha)
  end

  task.wait(0.15)
  overlay:Destroy()
  if blur and blur.Parent then blur:Destroy() end
  loaderGui:Destroy()
  _G.MOONHUB_LOADER_SHOWN = true
end

return M