-- UI con Sistema de Navegación Elegante
-- Interfaz visual mejorada con pestañas y diseño moderno

-- Servicios
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local UIS = game:GetService("UserInputService")

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ===== FILESYSTEM + CONFIG (moved early) =====
-- FS helpers
local FS = {}
do
  local g = getgenv and getgenv() or _G or {}
  FS.writefile  = rawget(g, "writefile") or (rawget(g, "syn") and g.syn.writefile) or (rawget(g, "krnl") and g.krnl.writefile)
  FS.appendfile = rawget(g, "appendfile") or (rawget(g, "syn") and g.syn.appendfile)
  FS.isfile     = rawget(g, "isfile")     or (rawget(g, "syn") and g.syn.isfile)
  FS.isfolder   = rawget(g, "isfolder")   or (rawget(g, "syn") and g.syn.isfolder)
  FS.makefolder = rawget(g, "makefolder") or (rawget(g, "syn") and g.syn.makefolder)
  FS.listfiles  = rawget(g, "listfiles")  or (rawget(g, "syn") and g.syn.listfiles) or rawget(g, "getfiles")
  FS.readfile   = rawget(g, "readfile")   or (rawget(g, "syn") and g.syn.readfile)  or (rawget(g, "krnl") and g.krnl.readfile)
  FS.delfile    = rawget(g, "delfile")    or (rawget(g, "syn") and g.syn.delfile)   or (rawget(g, "krnl") and g.krnl.delfile)
end

local function ensureFolder(path)
  if FS.isfolder and not FS.isfolder(path) then
    pcall(FS.makefolder, path)
  elseif FS.makefolder then
    pcall(FS.makefolder, path)
  end
end

local HttpService = game:GetService("HttpService")
local Config = { path = "Moon_Config/config.json", data = {} }

local function saveConfig()
  if not FS.writefile then return end
  local ok, json = pcall(function() return HttpService:JSONEncode(Config.data) end)
  if ok then
    ensureFolder("Moon_Config")
    pcall(FS.writefile, Config.path, json)
  end
end

local function loadConfig()
  if FS.isfile and FS.isfile(Config.path) and FS.readfile then
    local ok, raw = pcall(FS.readfile, Config.path)
    if ok and raw and #raw > 0 then
      local ok2, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
      if ok2 and type(decoded) == "table" then
        Config.data = decoded
      end
    end
  end
end

loadConfig()

-- Defaults for persisted UI state
Config.data.toggles = Config.data.toggles or {
  findTB    = false,
  autoReplay= false,
  autoSelect= false,
}
Config.data.selectedMacro = (Config.data.selectedMacro ~= nil) and Config.data.selectedMacro or nil
-- ensure the config file exists on first run
saveConfig()


-- Minimal helpers for the loader (avoid forward-reference to UI utils below)
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


local player = game:GetService("Players").LocalPlayer
local function getUILayer()
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return player:WaitForChild("PlayerGui")
end

-- Nunca dejar blur pegado
local function _killBlur(name)
  local Lighting = game:GetService("Lighting")
  local b = Lighting:FindFirstChild(name)
  if b then b:Destroy() end
end

-- Borra restos de ejecuciones previas
_killBlur("MoonHubLoaderBlur")
_killBlur("MoonHubIntroBlur")

-- allow disabling the loader from autoexec if desired
if not _G.MOONHUB_NO_LOADER then
  local loaderGui = Instance.new("ScreenGui")
  loaderGui.Name = "MoonHubLoader"
  loaderGui.IgnoreGuiInset = true
  loaderGui.DisplayOrder = 1_000_000
  loaderGui.ResetOnSpawn = false
  loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  loaderGui.Parent = getUILayer()

  -- Background blur + dim overlay (glass feel)
  local Lighting = game:GetService("Lighting")
  local blur = Instance.new("BlurEffect")
  blur.Name = "MoonHubLoaderBlur"
  blur.Size = 6
  blur.Parent = Lighting

  local overlay = Instance.new("Frame")
  overlay.Name = "DimOverlay"
  overlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
  overlay.BackgroundTransparency = 0.25
  overlay.BorderSizePixel = 0
  overlay.Size = UDim2.new(1,0,1,0)
  overlay.Parent = loaderGui

  -- Loader card
  local card = Instance.new("Frame")
  card.Name = "LoaderCard"
  card.Size = UDim2.new(0, 420, 0, 120)
  card.Position = UDim2.new(0.5, 0, 0.5, 0)
  card.AnchorPoint = Vector2.new(0.5, 0.5)
  card.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
  card.BackgroundTransparency = 0.1
  card.Parent = loaderGui
  _corner(card, 12)
  _stroke(card, Color3.fromRGB(70, 70, 85), 1, 0.5)

  -- subtle glass gradient and appear animation
  local cardGrad = Instance.new("UIGradient")
  cardGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(220,220,230))
  })
  cardGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.96),
    NumberSequenceKeypoint.new(1, 0.98)
  })
  cardGrad.Rotation = 90
  cardGrad.Parent = card

  card.Size = UDim2.new(0, 400, 0, 112)
  card.BackgroundTransparency = 0.08
  card.Position = UDim2.new(0.5, 0, 0.5, 0)
  card.AnchorPoint = Vector2.new(0.5, 0.5)
  card.Visible = true
  card.ClipsDescendants = true

  card.Size = UDim2.new(0, 360, 0, 118)
  local appear = TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 420, 0, 136)})
  appear:Play()

  -- Brand image centered (replaces text title)
  local logoImg = Instance.new("ImageLabel")
  logoImg.Name = "Brand"
  logoImg.BackgroundTransparency = 1
  logoImg.Image = "rbxassetid://102518679256494"
  logoImg.ScaleType = Enum.ScaleType.Fit
  logoImg.Size = UDim2.new(0, 220, 0, 42)
  -- horizontal nudge +40 to align over "Loading..."
  logoImg.Position = UDim2.new(0.5, 40, 0, 8)
  logoImg.AnchorPoint = Vector2.new(0.5, 0)
  logoImg.ClipsDescendants = true
  logoImg.ZIndex = 10
  logoImg.Parent = card

  -- Soft glow behind the logo (subtle and under the main image)
  local logoGlow = Instance.new("ImageLabel")
  logoGlow.Name = "BrandGlow"
  logoGlow.BackgroundTransparency = 1
  logoGlow.Image = "rbxassetid://102518679256494"
  logoGlow.ScaleType = Enum.ScaleType.Fit
  logoGlow.ImageColor3 = Color3.fromRGB(170, 130, 255)
  logoGlow.ImageTransparency = 0.72
  logoGlow.Size = UDim2.new(0, 240, 0, 48)
  logoGlow.Position = logoImg.Position
  logoGlow.AnchorPoint = logoImg.AnchorPoint
  logoGlow.ZIndex = 9
  logoGlow.Parent = card

  -- Keep glow locked under the logo if the logo moves
  logoImg:GetPropertyChangedSignal("Position"):Connect(function()
    logoGlow.Position = logoImg.Position
  end)
  logoImg:GetPropertyChangedSignal("Size"):Connect(function()
    logoGlow.Size = UDim2.new(0, math.floor(logoImg.Size.X.Offset * 1.09), 0, math.floor(logoImg.Size.Y.Offset * 1.14))
  end)

  -- Gentle bob animation (tiny vertical float)
  task.spawn(function()
    local upPos = UDim2.new(0.5, 40, 0, 4)
    local dnPos = UDim2.new(0.5, 40, 0, 12)
    while logoImg.Parent do
      TweenService:Create(logoImg, TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = upPos}):Play()
      TweenService:Create(logoGlow, TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = upPos}):Play()
      task.wait(1.15)
      TweenService:Create(logoImg, TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = dnPos}):Play()
      TweenService:Create(logoGlow, TweenInfo.new(1.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = dnPos}):Play()
      task.wait(1.15)
    end
  end)


  local subtitle = Instance.new("TextLabel")
  subtitle.Name = "Subtitle"
  subtitle.Text = "Loading…"
  subtitle.Font = Enum.Font.SourceSansSemibold
  subtitle.TextSize = 16
  subtitle.TextColor3 = Color3.fromRGB(200,200,210)
  subtitle.BackgroundTransparency = 1
  subtitle.Size = UDim2.new(1, -20, 0, 20)
  subtitle.Position = UDim2.new(0, 10, 0, 56)
  subtitle.Parent = card

  -- Rotating tips label
  local tip = Instance.new("TextLabel")
  tip.Name = "Tip"
  tip.Text = "Tip: Use lowercase names for macros"
  tip.Font = Enum.Font.SourceSans
  tip.TextSize = 13
  tip.TextColor3 = Color3.fromRGB(190,190,200)
  tip.BackgroundTransparency = 1
  tip.Size = UDim2.new(1, -20, 0, 18)
  tip.Position = UDim2.new(0, 10, 0, 76)
  tip.TextXAlignment = Enum.TextXAlignment.Left
  tip.Parent = card

  local tips = {
    "Tip: Name macros in lowercase.",
    "Tip: Use _general for common challenges.",
    "Tip: _single_placement for Single Placement.",
    "Tip: _high_cost for High Cost.",
    "Tip: Auto Select picks the best macro."}
  task.spawn(function()
    local i = 1
    while card.Parent do
      tip.Text = tips[i]
      i = (i % #tips) + 1
      task.wait(2.4)
    end
  end)

  -- Progress bar background
  local barBg = Instance.new("Frame")
  barBg.Name = "BarBg"
  barBg.Size = UDim2.new(1, -20, 0, 12)
  barBg.Position = UDim2.new(0, 10, 0, 98)
  barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
  barBg.Parent = card
  _corner(barBg, 6)

  -- Progress bar fill
  local barFill = Instance.new("Frame")
  barFill.Name = "BarFill"
  barFill.Size = UDim2.new(0, 0, 1, 0)
  barFill.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
  barFill.Parent = barBg
  _corner(barFill, 6)

  -- Shimmer effect for the progress fill
  local fillGrad = Instance.new("UIGradient")
  fillGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(170,130,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,170,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(140,90,245))
  })
  fillGrad.Rotation = 0
  fillGrad.Parent = barFill

  task.spawn(function()
    while barFill.Parent do
      fillGrad.Offset = Vector2.new((tick() * 0.4) % 1, 0)
      task.wait(0.03)
    end
  end)

  -- Percentage label
  local pct = Instance.new("TextLabel")
  pct.Name = "Percent"
  pct.Text = "0%"
  pct.Font = Enum.Font.SourceSansBold
  pct.TextSize = 14
  pct.TextColor3 = Color3.fromRGB(220,220,230)
  pct.BackgroundTransparency = 1
  pct.Size = UDim2.new(1, 0, 0, 16)
  pct.Position = UDim2.new(0, 0, 0, 116)
  pct.Parent = card

  local function setProgress(n)
      n = math.clamp(n or 0, 0, 100)
      pct.Text = tostring(math.floor(n + 0.5)) .. "%"
      barFill.Size = UDim2.new(n/100, 0, 1, 0)
  end

  -- readiness predicate
  local function uiReady()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end
    -- MainUI with some HUD bits (gems/gold) or any child already spawned
    local main = pg:FindFirstChild("MainUI", true)
    local hasStats = main and main:FindFirstChild("CashFrame", true)
    local hasAny  = #pg:GetChildren() > 0
    return hasStats ~= nil or hasAny
  end

  -- === Heurística: ¿sigue la pantalla de carga del juego visible? ===
  local function loadingScreenVisible()
    local needles = { "loading data", "cargando datos", "loading uis", "teleporting to", "teletransportarse" }
    local function scan(root)
      if not root then return false end
      for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible and d.AbsoluteSize.Y > 0 then
          local t = tostring(d.Text or ""):lower()
          for _, k in ipairs(needles) do
            if t:find(k, 1, true) then
              if (d.TextTransparency or 0) < 0.9 then
                return true
              end
            end
          end
        end
      end
      return false
    end
    local okCore, cg = pcall(function() return game:GetService("CoreGui") end)
    return scan(player:FindFirstChild("PlayerGui")) or (okCore and scan(cg))
  end

  -- Loader timing controls
  local MIN_DISPLAY_SEC   = 5.5   -- tiempo mínimo visible del loader (sensación de carga)
  local SOFT_CAP_PERCENT  = 72    -- no pasar de este porcentaje hasta que haya señales de UI lista
  local FINISH_DURATION   = 1.25  -- animación final hasta 100%

  -- Block here until ready (or timeout). This prevents the main UI from building early.
  local timeoutSec = 75
  local t0 = os.clock()
  local progress = 0
  setProgress(progress)

  -- 1) Fase de “carga”: sube despacio y se detiene en SOFT_CAP_PERCENT hasta que la UI esté lista
  while (os.clock() - t0) < timeoutSec do
      if progress < SOFT_CAP_PERCENT then
          progress = math.min(SOFT_CAP_PERCENT, progress + math.random(1,2))
          setProgress(progress)
      end

      local minTimePassed = (os.clock() - t0) >= MIN_DISPLAY_SEC
      local ui_is_ready   = uiReady()
      local no_loading_ui = not loadingScreenVisible()
      local queue_small   = (ContentProvider.RequestQueueSize or 0) <= 1

      if minTimePassed and ui_is_ready and no_loading_ui and queue_small then
          break
      end

      task.wait(0.15)
  end

  -- 2) Final phase: smooth to 100% + success feedback
  subtitle.Text = "Ready"
  local start = progress
  local t = 0
  while t < FINISH_DURATION do
      t = t + task.wait()
      local alpha = math.clamp(t / FINISH_DURATION, 0, 1)
      local val = start + (100 - start) * alpha
      setProgress(val)
  end

  -- quick success check mark
  local check = Instance.new("TextLabel")
  check.BackgroundTransparency = 1
  check.Text = "✅"
  check.Font = Enum.Font.SourceSansBold
  check.TextSize = 20
  check.TextColor3 = Color3.fromRGB(220,220,230)
  check.Size = UDim2.new(0, 24, 0, 24)
  check.Position = UDim2.new(1, -34, 0, 8)
  check.Parent = card

  -- fade and scale out the card, then cleanup overlay/blur
  task.wait(0.15)
  local fade = TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.22})
  local shrink = TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 380, 0, 124)})
  fade:Play(); shrink:Play()
  task.wait(0.2)

  if overlay then overlay:Destroy() end
  if blur and blur.Parent then blur:Destroy() end
  _G.MOONHUB_LOADER_SHOWN = true
  _killBlur("MoonHubLoaderBlur") -- por si el loader no limpió por timing
  loaderGui:Destroy()
end
-- ===== END LOADER FIX =====

if _G.MOONHUB_NO_LOADER then
  repeat task.wait() until game:IsLoaded()
end

-- Limpieza previa
local existingGui = player.PlayerGui:FindFirstChild("MyAwesomeUI")
if existingGui then existingGui:Destroy() end

-- ===== CONFIGURACIÓN DE COLORES =====
local COLORS = {
  background_primary = Color3.fromRGB(28, 28, 38),
  background_secondary = Color3.fromRGB(40, 40, 50),
  background_tertiary = Color3.fromRGB(35, 35, 45),
  text_primary = Color3.fromRGB(200, 200, 200),
  text_secondary = Color3.new(1, 1, 1),
  text_dim = Color3.fromRGB(140, 140, 150),
  accent = Color3.fromRGB(150, 100, 255),
  accent_hover = Color3.fromRGB(170, 120, 255),
  tab_active = Color3.fromRGB(150, 100, 255),
  tab_inactive = Color3.fromRGB(50, 50, 60),
  button_hover = Color3.fromRGB(60, 60, 70),
  flash_up = Color3.fromRGB(90, 210, 130),
  flash_down = Color3.fromRGB(230, 90, 90),
  border = Color3.fromRGB(70, 70, 85)
}

-- IDs de iconos
local ICONS = {
  logo = "rbxassetid://102518679256494",
  gems = "rbxassetid://14511803600",
  gold = "rbxassetid://14512115924", 
  traitburner = "rbxassetid://100013769550089"
}

-- Variables de estado
local lastGems, lastCash, lastTB = nil, nil, nil
local isDragging = false
local currentTab = "Features"

-- ===== FUNCIONES UTILITARIAS =====
local function formatNumber(n)
  local s = tostring(n or 0)
  return s:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
end

local function createCorner(parent, radius)
  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, radius)
  corner.Parent = parent
  return corner
end

local function createStroke(parent, color, thickness, transparency)
  local stroke = Instance.new("UIStroke")
  stroke.Color = color or COLORS.border
  stroke.Thickness = thickness or 1
  stroke.Transparency = transparency or 0.5
  stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
  stroke.Parent = parent
  return stroke
end

local function createGradient(parent, colors, rotation)
  local gradient = Instance.new("UIGradient")
  gradient.Color = colors or ColorSequence.new(COLORS.background_primary, COLORS.background_secondary)
  gradient.Rotation = rotation or 90
  gradient.Parent = parent
  return gradient
end

local function flashLabel(label, isIncrease)
  local color = isIncrease and COLORS.flash_up or COLORS.flash_down
  TweenService:Create(label, TweenInfo.new(0.18), {TextColor3 = color}):Play()
  task.delay(0.25, function()
    TweenService:Create(label, TweenInfo.new(0.25), {TextColor3 = COLORS.text_primary}):Play()
  end)
end

-- ===== CREACIÓN DE GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "MyAwesomeUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = player.PlayerGui

-- Frame Principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.BackgroundColor3 = COLORS.background_primary
mainFrame.Size = UDim2.new(0, 600, 0, 680)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Parent = gui
createCorner(mainFrame, 16)
createStroke(mainFrame, COLORS.border, 1, 0.7)
mainFrame.Visible = false

-- Barra Superior
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.BackgroundColor3 = COLORS.background_secondary
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.Parent = mainFrame
createCorner(topBar, 16)

-- Gradiente sutil en la barra superior
local topBarShine = Instance.new("Frame")
topBarShine.BackgroundColor3 = Color3.new(1, 1, 1)
topBarShine.BackgroundTransparency = 0.95
topBarShine.Size = UDim2.new(1, 0, 0.5, 0)
topBarShine.Parent = topBar
createGradient(topBarShine, ColorSequence.new{
  ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
  ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
}, 90)

-- Logo
local logo = Instance.new("ImageLabel")
logo.BackgroundTransparency = 1
logo.Image = ICONS.logo
logo.ScaleType = Enum.ScaleType.Fit
logo.Size = UDim2.new(0, 140, 0, 35)
logo.Position = UDim2.new(0, 15, 0.5, 0)
logo.AnchorPoint = Vector2.new(0, 0.5)
logo.Parent = topBar

-- Botón Cerrar
local closeButton = Instance.new("TextButton")
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 95, 86)
closeButton.Size = UDim2.new(0, 24, 0, 24)
closeButton.Position = UDim2.new(1, -35, 0.5, 0)
closeButton.AnchorPoint = Vector2.new(0.5, 0.5)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 16
closeButton.Parent = topBar
createCorner(closeButton, 12)

-- Contenedor Principal (debajo del topBar)
local contentContainer = Instance.new("Frame")
contentContainer.BackgroundTransparency = 1
contentContainer.Size = UDim2.new(1, -20, 1, -60)
contentContainer.Position = UDim2.new(0, 10, 0, 55)
contentContainer.Parent = mainFrame

-- Panel Izquierdo (Sidebar)
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.BackgroundColor3 = COLORS.background_secondary
sidebar.Size = UDim2.new(0, 180, 1, 0)
sidebar.Parent = contentContainer
createCorner(sidebar, 12)
createStroke(sidebar, COLORS.border, 1, 0.8)

-- Contenedor de información de monedas
local statsContainer = Instance.new("Frame")
statsContainer.BackgroundColor3 = COLORS.background_tertiary
statsContainer.Size = UDim2.new(1, -20, 0, 140)
statsContainer.Position = UDim2.new(0, 10, 0, 10)
statsContainer.Parent = sidebar
createCorner(statsContainer, 10)

local statsTitle = Instance.new("TextLabel")
statsTitle.Text = "RESOURCES"
statsTitle.TextColor3 = COLORS.text_dim
statsTitle.BackgroundTransparency = 1
statsTitle.Font = Enum.Font.SourceSansBold
statsTitle.TextSize = 12
statsTitle.Size = UDim2.new(1, -20, 0, 20)
statsTitle.Position = UDim2.new(0, 10, 0, 5)
statsTitle.Parent = statsContainer

-- Función para crear stat items
local function createStatItem(name, icon, yPos)
  local container = Instance.new("Frame")
  container.BackgroundTransparency = 1
  container.Size = UDim2.new(1, -20, 0, 30)
  container.Position = UDim2.new(0, 10, 0, yPos)
  container.Parent = statsContainer
  
  local iconLabel = Instance.new("ImageLabel")
  iconLabel.BackgroundTransparency = 1
  iconLabel.Image = icon
  iconLabel.Size = UDim2.new(0, 20, 0, 20)
  iconLabel.Position = UDim2.new(0, 0, 0.5, 0)
  iconLabel.AnchorPoint = Vector2.new(0, 0.5)
  iconLabel.Parent = container
  
  local nameLabel = Instance.new("TextLabel")
  nameLabel.Text = name
  nameLabel.TextColor3 = COLORS.text_dim
  nameLabel.BackgroundTransparency = 1
  nameLabel.Font = Enum.Font.SourceSans
  nameLabel.TextSize = 13
  nameLabel.Size = UDim2.new(0, 60, 1, 0)
  nameLabel.Position = UDim2.new(0, 25, 0, 0)
  nameLabel.TextXAlignment = Enum.TextXAlignment.Left
  nameLabel.Parent = container
  
  local valueLabel = Instance.new("TextLabel")
  valueLabel.Name = "Value"
  valueLabel.Text = "0"
  valueLabel.TextColor3 = COLORS.text_secondary
  valueLabel.BackgroundTransparency = 1
  valueLabel.Font = Enum.Font.SourceSansBold
  valueLabel.TextSize = 14
  valueLabel.Size = UDim2.new(0, 70, 1, 0)
  valueLabel.Position = UDim2.new(1, -70, 0, 0)
  valueLabel.TextXAlignment = Enum.TextXAlignment.Right
  valueLabel.Parent = container
  
  return valueLabel
end

local gemsValue = createStatItem("Gems", ICONS.gems, 30)
local goldValue = createStatItem("Gold", ICONS.gold, 60)
local tbValue = createStatItem("TB", ICONS.traitburner, 90)

-- Sistema de Navegación (Tabs)
local navContainer = Instance.new("Frame")
navContainer.BackgroundTransparency = 1
navContainer.Size = UDim2.new(1, -20, 0, 200)
navContainer.Position = UDim2.new(0, 10, 0, 160)
navContainer.Parent = sidebar

local navTitle = Instance.new("TextLabel")
navTitle.Text = "NAVIGATION"
navTitle.TextColor3 = COLORS.text_dim
navTitle.BackgroundTransparency = 1
navTitle.Font = Enum.Font.SourceSansBold
navTitle.TextSize = 12
navTitle.Size = UDim2.new(1, 0, 0, 20)
navTitle.Parent = navContainer

-- Función para crear tabs
local tabs = {}
local function createTab(name, yPos, icon)
  local tab = Instance.new("TextButton")
  tab.Name = name .. "Tab"
  tab.Text = ""
  tab.BackgroundColor3 = (name == currentTab) and COLORS.tab_active or COLORS.tab_inactive
  tab.Size = UDim2.new(1, 0, 0, 40)
  tab.Position = UDim2.new(0, 0, 0, yPos)
  tab.AutoButtonColor = false
  tab.Parent = navContainer
  createCorner(tab, 8)
  
  local tabContent = Instance.new("Frame")
  tabContent.BackgroundTransparency = 1
  tabContent.Size = UDim2.new(1, -20, 1, 0)
  tabContent.Position = UDim2.new(0, 10, 0, 0)
  tabContent.Parent = tab
  
  local tabIcon = Instance.new("TextLabel")
  tabIcon.Text = icon
  tabIcon.TextColor3 = (name == currentTab) and COLORS.text_secondary or COLORS.text_dim
  tabIcon.BackgroundTransparency = 1
  tabIcon.Font = Enum.Font.SourceSansBold
  tabIcon.TextSize = 18
  tabIcon.Size = UDim2.new(0, 30, 1, 0)
  tabIcon.Parent = tabContent
  
  local tabLabel = Instance.new("TextLabel")
  tabLabel.Text = name
  tabLabel.TextColor3 = (name == currentTab) and COLORS.text_secondary or COLORS.text_primary
  tabLabel.BackgroundTransparency = 1
  tabLabel.Font = Enum.Font.SourceSansSemibold
  tabLabel.TextSize = 15
  tabLabel.Size = UDim2.new(1, -35, 1, 0)
  tabLabel.Position = UDim2.new(0, 35, 0, 0)
  tabLabel.TextXAlignment = Enum.TextXAlignment.Left
  tabLabel.Parent = tabContent
  
  -- Indicador de tab activa
  local indicator = Instance.new("Frame")
  indicator.Name = "Indicator"
  indicator.BackgroundColor3 = COLORS.accent
  indicator.Size = UDim2.new(0, 3, 0.6, 0)
  indicator.Position = UDim2.new(0, 0, 0.2, 0)
  indicator.Visible = (name == currentTab)
  indicator.Parent = tab
  createCorner(indicator, 2)
  
  tabs[name] = {button = tab, icon = tabIcon, label = tabLabel, indicator = indicator}
  return tab
end

local featuresTab = createTab("Features", 25, "⚡")
local macroTab = createTab("Macro System", 70, "⚙️")

-- Panel Derecho (Contenido)
local contentPanel = Instance.new("Frame")
contentPanel.BackgroundColor3 = COLORS.background_secondary
contentPanel.Size = UDim2.new(1, -190, 1, 0)
contentPanel.Position = UDim2.new(0, 190, 0, 0)
contentPanel.Parent = contentContainer
createCorner(contentPanel, 12)
createStroke(contentPanel, COLORS.border, 1, 0.8)

-- Páginas de contenido
local pages = {}

-- Página Features
local featuresPage = Instance.new("Frame")
featuresPage.Name = "FeaturesPage"
featuresPage.BackgroundTransparency = 1
featuresPage.Size = UDim2.new(1, -20, 1, -20)
featuresPage.Position = UDim2.new(0, 10, 0, 10)
featuresPage.Visible = true
featuresPage.Parent = contentPanel
pages["Features"] = featuresPage

local featuresTitle = Instance.new("TextLabel")
featuresTitle.Text = "Features"
featuresTitle.TextColor3 = COLORS.text_secondary
featuresTitle.BackgroundTransparency = 1
featuresTitle.Font = Enum.Font.SourceSansBold
featuresTitle.TextSize = 24
featuresTitle.Size = UDim2.new(1, 0, 0, 30)
featuresTitle.Parent = featuresPage

local featuresDivider = Instance.new("Frame")
featuresDivider.BackgroundColor3 = COLORS.accent
featuresDivider.BackgroundTransparency = 0.7
featuresDivider.Size = UDim2.new(0, 60, 0, 2)
featuresDivider.Position = UDim2.new(0, 0, 0, 35)
featuresDivider.Parent = featuresPage

-- Find Trait Burner Toggle Button
local findTBButton = Instance.new("Frame")
findTBButton.BackgroundColor3 = COLORS.background_tertiary
findTBButton.Size = UDim2.new(1, 0, 0, 120)
findTBButton.Position = UDim2.new(0, 0, 0, 55)
findTBButton.Parent = featuresPage
createCorner(findTBButton, 10)
createStroke(findTBButton, COLORS.border, 1, 0.8)

-- Toggle Container
local toggleContainer = Instance.new("Frame")
toggleContainer.BackgroundTransparency = 1
toggleContainer.Size = UDim2.new(1, -20, 0, 40)
toggleContainer.Position = UDim2.new(0, 10, 0, 10)
toggleContainer.Parent = findTBButton

-- Button Title
local tbButtonTitle = Instance.new("TextLabel")
tbButtonTitle.Text = "Find Trait Burner"
tbButtonTitle.TextColor3 = COLORS.text_secondary
tbButtonTitle.BackgroundTransparency = 1
tbButtonTitle.Font = Enum.Font.SourceSansSemibold
tbButtonTitle.TextSize = 16
tbButtonTitle.Size = UDim2.new(0, 150, 1, 0)
tbButtonTitle.Position = UDim2.new(0, 0, 0, 0)
tbButtonTitle.TextXAlignment = Enum.TextXAlignment.Left
tbButtonTitle.Parent = toggleContainer

-- Toggle Switch
local toggleSwitch = Instance.new("Frame")
toggleSwitch.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Negro para el fondo
toggleSwitch.Size = UDim2.new(0, 50, 0, 26)
toggleSwitch.Position = UDim2.new(1, -50, 0.5, 0)
toggleSwitch.AnchorPoint = Vector2.new(1, 0.5)
toggleSwitch.Parent = toggleContainer
createCorner(toggleSwitch, 13)

-- Toggle Knob
local toggleKnob = Instance.new("Frame")
toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Blanco para el círculo
toggleKnob.Size = UDim2.new(0, 22, 0, 22)
toggleKnob.Position = UDim2.new(0, 2, 0.5, 0)
toggleKnob.AnchorPoint = Vector2.new(0, 0.5)
toggleKnob.Parent = toggleSwitch
createCorner(toggleKnob, 11)

-- No toggle state label for cleaner aesthetics
local tbDescription = Instance.new("TextLabel")
tbDescription.Text = "With this function active you can search for Trait Burners in challenge, efficient for light farming. If you want to search for trait burners every time you return to the lobby, keep it active."
tbDescription.TextColor3 = COLORS.text_dim
tbDescription.BackgroundTransparency = 1
tbDescription.Font = Enum.Font.SourceSans
tbDescription.TextSize = 13
tbDescription.Size = UDim2.new(1, -20, 0, 50)
tbDescription.Position = UDim2.new(0, 10, 0, 55)
tbDescription.TextXAlignment = Enum.TextXAlignment.Left
tbDescription.TextYAlignment = Enum.TextYAlignment.Top
tbDescription.TextWrapped = true
tbDescription.Parent = findTBButton

-- === Filter by challenge section ===
local filterSection = Instance.new("Frame")
filterSection.Name = "FilterSection"
filterSection.BackgroundTransparency = 1
filterSection.Size = UDim2.new(1, 0, 0, 70)
filterSection.Position = UDim2.new(0, 0, 0, 185)
filterSection.Parent = featuresPage

local filterTitle = Instance.new("TextLabel")
filterTitle.Text = "Filter by challenge"
filterTitle.TextColor3 = COLORS.text_secondary
filterTitle.BackgroundTransparency = 1
filterTitle.Font = Enum.Font.SourceSansSemibold
filterTitle.TextSize = 16
filterTitle.Size = UDim2.new(1, -20, 0, 22)
filterTitle.Position = UDim2.new(0, 10, 0, 0)
filterTitle.TextXAlignment = Enum.TextXAlignment.Left
filterTitle.Parent = filterSection

local filterDesc = Instance.new("TextLabel")
filterDesc.Text = "Here you can filter maps and challenges. If you want a map to be ignored, leave its challenge list empty."
filterDesc.TextColor3 = COLORS.text_dim
filterDesc.BackgroundTransparency = 1
filterDesc.Font = Enum.Font.SourceSans
filterDesc.TextSize = 13
filterDesc.Size = UDim2.new(1, -20, 0, 40)
filterDesc.Position = UDim2.new(0, 10, 0, 26)
filterDesc.TextXAlignment = Enum.TextXAlignment.Left
filterDesc.TextYAlignment = Enum.TextYAlignment.Top
filterDesc.TextWrapped = true

filterDesc.Parent = filterSection

local FILTER = getgenv and getgenv().MoonFilter
if not FILTER then
  local ok, mod = pcall(function()
    local url = "https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/filter.lua"
    return loadstring(game:HttpGet(url))()
  end)
  if ok and type(mod)=="table" then
    FILTER = mod
    if getgenv then getgenv().MoonFilter = mod end
  else
    warn("[Filter] Failed to autoload filter.lua: "..tostring(mod))
  end
end


-- Maps available for Challenges UI
local MAPS = {
  { key = "innovation_island",     label = "Innovation Island" },
  { key = "giant_island",          label = "Giant Island" },
  { key = "future_city_ruins",     label = "Future City (Ruins)" },
  { key = "city_of_voldstandig",   label = "City of Voldstandig" },
  { key = "hidden_storm_village",  label = "Hidden Storm Village" },
  { key = "city_of_york",          label = "City of York" },
  { key = "shadow_tournament",     label = "Shadow Tournament" },
}

-- Challenge options (Random Units intentionally excluded)
local CHALLENGE_OPTS = {
  { label = "Flying Enemies",     key = "flying_enemies" },
  { label = "Juggernaut Enemies", key = "juggernaut_enemies" },
  { label = "Single Placement",   key = "single_placement" },
  { label = "High Cost",          key = "high_cost" },
  { label = "Unsellable",         key = "unsellable" },
}

-- Deny-by-default bootstrap (now that MAPS is defined)
pcall(function()
  if not FILTER then return end

  -- ¿ya hay algo seleccionado?
  local hasAny = false
  if type(FILTER.anySelected) == "function" then
    hasAny = FILTER.anySelected()
  else
    for _, m in ipairs(MAPS) do
      local arr
      if type(FILTER.get) == "function" then
        arr = FILTER.get(m.label)
      elseif type(FILTER.getMap) == "function" then
        arr = FILTER.getMap(m.label)
      end
      if type(arr) == "table" and next(arr) ~= nil then
        hasAny = true
        break
      end
    end
  end

  -- si no hay nada, forzar vacío (deny-by-default)
  if not hasAny then
    if type(FILTER.replaceAll) == "function" then
      FILTER.replaceAll({})
    else
      for _, m in ipairs(MAPS) do
        if type(FILTER.setAllowed) == "function" then
          FILTER.setAllowed(m.label, {})
        elseif type(FILTER.set) == "function" then
          FILTER.set(m.label, {})
        elseif type(FILTER.setMap) == "function" then
          FILTER.setMap(m.label, {})
        end
      end
    end
    print("[FindTB][Filter][UI] Initialized empty config (deny-by-default)")
  end
end)

-- Persist UI selection in memory and forward to Filter module if present
local FilterSelections = {}

local function syncFilter(mapLabel)
  -- Convert set -> array of challenge *labels*
  local list = {}
  local set = FilterSelections[mapLabel]
  if set then
    for challengeLabel, v in pairs(set) do
      if v then table.insert(list, challengeLabel) end
    end
  end

  -- Persist into config
  Config.data.filterSelections = Config.data.filterSelections or {}
  Config.data.filterSelections[mapLabel] = list
  saveConfig()
  
  -- Push to filter module using the *display label* for the map
  pcall(function()
    if FILTER and type(FILTER.setAllowed) == "function" then
      FILTER.setAllowed(mapLabel, list)
    elseif FILTER and type(FILTER.set) == "function" then
      FILTER.set(mapLabel, list)
    elseif FILTER and type(FILTER.setMap) == "function" then
      FILTER.setMap(mapLabel, list)
    elseif FILTER and type(FILTER.replaceOne) == "function" then
      FILTER.replaceOne(mapLabel, list)
    end
  end)
end

-- Pretty summary for the button text
local function summarizeSelection(set)
  local n = 0
  for _,v in pairs(set or {}) do if v then n = n + 1 end end
  if n == 0 then return "(none)" end
  if n == #CHALLENGE_OPTS then return "All" end
  return tostring(n) .. " selected"
end

-- Container for all map entries (scrollable)
local filterList = Instance.new("ScrollingFrame")
filterList.Name = "FilterList"
filterList.BackgroundColor3 = COLORS.background_tertiary
-- filterList.Size = UDim2.new(1, 0, 0, 380) -- replaced by dynamic sizing below
filterList.Position = UDim2.new(0, 0, 0, filterSection.Position.Y.Offset + filterSection.Size.Y.Offset + 10)
filterList.Parent = featuresPage
filterList.ScrollBarThickness = 5
filterList.ScrollBarImageColor3 = COLORS.accent
filterList.BorderSizePixel = 0
createCorner(filterList, 10)
createStroke(filterList, COLORS.border, 1, 0.6)

-- dynamic height based on available space
local function recomputeFilterHeight()
  local top = filterSection.Position.Y.Offset + filterSection.Size.Y.Offset + 10
  local avail = math.max(150, featuresPage.AbsoluteSize.Y - top - 10)
  filterList.Position = UDim2.new(0, 0, 0, top)
  filterList.Size     = UDim2.new(1, 0, 0, avail)
end

recomputeFilterHeight()
featuresPage:GetPropertyChangedSignal("AbsoluteSize"):Connect(recomputeFilterHeight)

local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 10)
listPad.PaddingLeft = UDim.new(0, 10)
listPad.PaddingRight = UDim.new(0, 10)
listPad.Parent = filterList

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = filterList

local function updateFilterCanvas()
  filterList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
end
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateFilterCanvas)
-- Track a single open dropdown row so only one can be expanded at a time
local openFilterRow = nil
local function collapseOpenRow()
  if openFilterRow and openFilterRow.Parent then
    local popup = openFilterRow:FindFirstChild("Popup")
    if popup and popup:IsA("Frame") then popup.Visible = false end
    openFilterRow.Size = UDim2.new(1, 0, 0, 72)
    openFilterRow = nil
    updateFilterCanvas()
  end
end

-- UI factory for one map row (bold name + multiselect dropdown)
local function createMapFilter(map)
  local row = Instance.new("Frame")
  row.Name = "Row_" .. map.key
  row.BackgroundTransparency = 1
  row.Size = UDim2.new(1, 0, 0, 72)
  row.Parent = filterList

  -- Map title (bold)
  local title = Instance.new("TextLabel")
  title.BackgroundTransparency = 1
  title.Text = map.label
  title.Font = Enum.Font.SourceSansBold
  title.TextSize = 16
  title.TextColor3 = COLORS.text_secondary
  title.TextXAlignment = Enum.TextXAlignment.Left
  title.Size = UDim2.new(1, 0, 0, 22)
  title.Parent = row

  -- Dropdown shell
  local dd = Instance.new("Frame")
  dd.Name = "Dropdown"
  dd.BackgroundColor3 = COLORS.background_secondary
  dd.Size = UDim2.new(1, 0, 0, 42)
  dd.Position = UDim2.new(0, 0, 0, 28)
  dd.Parent = row
  createCorner(dd, 8)
  createStroke(dd, COLORS.border, 1, 0.6)

  local btn = Instance.new("TextButton")
  btn.Text = "Choose challenges ▾"
  btn.AutoButtonColor = false
  btn.BackgroundTransparency = 1
  btn.TextColor3 = Color3.new(1,1,1)
  btn.Font = Enum.Font.SourceSansSemibold
  btn.TextSize = 14
  btn.Size = UDim2.new(1, -10, 1, 0)
  btn.Position = UDim2.new(0, 10, 0, 0)
  btn.TextXAlignment = Enum.TextXAlignment.Left
  btn.Parent = dd
  btn.ZIndex = 11

  -- Popup lives inside the row so it scrolls/clips with the list
  local popup = Instance.new("Frame")
  popup.Name = "Popup"
  popup.BackgroundColor3 = COLORS.background_secondary
  popup.Visible = false
  popup.Parent = row
  popup.ZIndex = 10
  popup.ClipsDescendants = true
  -- below the dropdown (title 22 + gap 6 + dropdown 42 + gap 6)
  popup.Position = UDim2.new(0, 8, 0, 22 + 6 + 42 + 6)
  popup.Size = UDim2.new(1, -16, 0, 120)
  createCorner(popup, 8)
  createStroke(popup, COLORS.border, 1, 0.6)

  local popPad = Instance.new("UIPadding")
  popPad.PaddingTop = UDim.new(0, 6)
  popPad.PaddingLeft = UDim.new(0, 8)
  popPad.Parent = popup

  local popList = Instance.new("UIListLayout")
  popList.SortOrder = Enum.SortOrder.LayoutOrder
  popList.Padding = UDim.new(0, 6)
  popList.Parent = popup

  -- Expanded size when popup open
  local baseRowH = 72
  local expandedRowH = baseRowH + popup.Size.Y.Offset + 10

  local function openPopup()
    -- Only one open at a time
    if openFilterRow and openFilterRow ~= row then
      collapseOpenRow()
    end
    row.Size = UDim2.new(1, 0, 0, expandedRowH)
    popup.Visible = true
    openFilterRow = row
    updateFilterCanvas()
  end

  local function closePopup()
    popup.Visible = false
    row.Size = UDim2.new(1, 0, 0, baseRowH)
    if openFilterRow == row then openFilterRow = nil end
    updateFilterCanvas()
  end
  
  -- Initialize selection set from module (if any)
  FilterSelections[map.label] = FilterSelections[map.label] or {}
  pcall(function()
    if FILTER and type(FILTER.get) == "function" then
      local arr = FILTER.get(map.label) or {}
      for _,k in ipairs(arr) do FilterSelections[map.label][k] = true end
    elseif FILTER and type(FILTER.getMap) == "function" then
      local arr = FILTER.getMap(map.label) or {}
      for _,k in ipairs(arr) do FilterSelections[map.label][k] = true end
    end
  end)

  -- Merge persisted selections from Config (disk) if present
  if Config and Config.data and Config.data.filterSelections and Config.data.filterSelections[map.label] then
    for _, k in ipairs(Config.data.filterSelections[map.label]) do
      FilterSelections[map.label][k] = true
    end
  end

  -- Push initial (possibly merged) selection to the filter module and persist
  -- (no-op changes are fine; keeps UI, module and config in sync)
  syncFilter(map.label)

  -- Build check rows
  local function addOption(opt)
    local orow = Instance.new("TextButton")
    orow.AutoButtonColor = false
    orow.BackgroundColor3 = COLORS.background_tertiary
    orow.Text = ""
    orow.Size = UDim2.new(1, -16, 0, 26)
    orow.Parent = popup
    orow.ZIndex = 12
    createCorner(orow, 6)

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 18, 0, 18)
    box.Position = UDim2.new(0, 6, 0.5, 0)
    box.AnchorPoint = Vector2.new(0, 0.5)
    box.BackgroundColor3 = COLORS.background_secondary
    box.Parent = orow
    box.ZIndex = 13
    createCorner(box, 4)
    createStroke(box, COLORS.border, 1, 0.5)

    local tick = Instance.new("TextLabel")
    tick.BackgroundTransparency = 1
    tick.Size = UDim2.new(0, 18, 0, 18)
    tick.Position = UDim2.new(0, 0, 0, 0)
    tick.Text = ""
    tick.TextColor3 = COLORS.text_secondary
    tick.Font = Enum.Font.SourceSansBold
    tick.TextSize = 18
    tick.Parent = box
    tick.ZIndex = 14

    local lab = Instance.new("TextLabel")
    lab.BackgroundTransparency = 1
    lab.Text = opt.label
    lab.Font = Enum.Font.SourceSans
    lab.TextSize = 14
    lab.TextColor3 = COLORS.text_primary
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.Size = UDim2.new(1, -34, 1, 0)
    lab.Position = UDim2.new(0, 34, 0, 0)
    lab.Parent = orow
    lab.ZIndex = 14

    local function refresh()
      local on = FilterSelections[map.label][opt.label] == true
      box.BackgroundColor3 = on and COLORS.accent or COLORS.background_secondary
      tick.Text = on and "✓" or ""
    end

    orow.MouseButton1Click:Connect(function()
      local cur = FilterSelections[map.label][opt.label]
      FilterSelections[map.label][opt.label] = not cur and true or nil
      btn.Text = summarizeSelection(FilterSelections[map.label]) .. " ▾"
      refresh()
      syncFilter(map.label)
      closePopup()
    end)

    -- hover
    orow.MouseEnter:Connect(function()
      TweenService:Create(orow, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.button_hover}):Play()
    end)
    orow.MouseLeave:Connect(function()
      TweenService:Create(orow, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.background_tertiary}):Play()
    end)

    refresh()
  end

  for _,opt in ipairs(CHALLENGE_OPTS) do
    addOption(opt)
  end

  -- Button to open/close popup
  btn.MouseButton1Click:Connect(function()
    if popup.Visible then
      closePopup()
    else
      openPopup()
    end
  end)

  -- Initialize button summary text
  btn.Text = summarizeSelection(FilterSelections[map.label]) .. " ▾"
end

for _,m in ipairs(MAPS) do
  createMapFilter(m)
end

-- Close dropdown when clicking outside any open filter row
UIS.InputBegan:Connect(function(input)
  if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
  if not openFilterRow then return end
  -- if click is outside the currently open row, collapse it
  local pos = input.Position
  local topLeft = openFilterRow.AbsolutePosition
  local bottomRight = topLeft + openFilterRow.AbsoluteSize
  local inside = (pos.X >= topLeft.X and pos.X <= bottomRight.X and pos.Y >= topLeft.Y and pos.Y <= bottomRight.Y)
  if not inside then
    collapseOpenRow()
  end
end)

updateFilterCanvas()

-- Toggle State Variable
local isTBActive = false
local FindTBModule = nil

local function ensureFindTB()
  if FindTBModule then return true end
  local ok, mod = pcall(function()
    local url = "https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/findtb.lua"
    local f = loadstring(game:HttpGet(url))
    return f()
  end)
  if ok and type(mod) == "table" then
    FindTBModule = mod
    return true
  end
  warn("[FindTB] failed to load external module: " .. tostring(mod))
  return false
end

-- Restore persisted state for FindTB
do
  local on = Config and Config.data and Config.data.toggles and Config.data.toggles.findTB
  if on then
    isTBActive = true
    toggleKnob.Position = UDim2.new(1, -24, 0.5, 0)
    toggleSwitch.BackgroundColor3 = COLORS.accent
    _G.FindTBActive = true
    if ensureFindTB() and FindTBModule and FindTBModule.start then
      pcall(FindTBModule.start)
    end
  else
    isTBActive = false
    toggleKnob.Position = UDim2.new(0, 2, 0.5, 0)
    toggleSwitch.BackgroundColor3 = Color3.fromRGB(20,20,20)
    _G.FindTBActive = false
  end
end


local function toggleTB()
  isTBActive = not isTBActive
  if isTBActive then
    -- UI ON
    TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = UDim2.new(1, -24, 0.5, 0), AnchorPoint = Vector2.new(0,0.5) }):Play()
    TweenService:Create(toggleSwitch, TweenInfo.new(0.2), { BackgroundColor3 = COLORS.accent }):Play()


    -- Only signal and call the external module
    _G.FindTBActive = true
    if ensureFindTB() and FindTBModule and FindTBModule.start then
      pcall(FindTBModule.start)
      Config.data.toggles.findTB = true
      saveConfig()
    end
  else
    -- UI OFF
    TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0,0.5) }):Play()
    TweenService:Create(toggleSwitch, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(20,20,20) }):Play()
  

    -- Tell the external module to stop and lower the flag
    _G.FindTBActive = false
    if FindTBModule and FindTBModule.stop then
      pcall(FindTBModule.stop)
      Config.data.toggles.findTB = false
      saveConfig()
    end
  end
end

toggleSwitch.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    toggleTB()
  end
end)

-- Página Macro System
local macroPage = Instance.new("Frame")
macroPage.Name = "MacroPage"
macroPage.BackgroundTransparency = 1
macroPage.Size = UDim2.new(1, -20, 1, -20)
macroPage.Position = UDim2.new(0, 10, 0, 10)
macroPage.Visible = false
macroPage.Parent = contentPanel
pages["Macro System"] = macroPage

local macroTitle = Instance.new("TextLabel")
macroTitle.Text = "Macro System"
macroTitle.TextColor3 = COLORS.text_secondary
macroTitle.BackgroundTransparency = 1
macroTitle.Font = Enum.Font.SourceSansBold
macroTitle.TextSize = 24
macroTitle.Size = UDim2.new(1, 0, 0, 30)
macroTitle.Parent = macroPage

local macroDivider = Instance.new("Frame")
macroDivider.BackgroundColor3 = COLORS.accent
macroDivider.BackgroundTransparency = 0.7
macroDivider.Size = UDim2.new(0, 60, 0, 2)
macroDivider.Position = UDim2.new(0, 0, 0, 35)
macroDivider.Parent = macroPage

local macroDesc = Instance.new("TextLabel")
macroDesc.Text = "Record and replay your actions automatically"
macroDesc.TextColor3 = COLORS.text_dim
macroDesc.BackgroundTransparency = 1
macroDesc.Font = Enum.Font.SourceSans
macroDesc.TextSize = 14
macroDesc.Size = UDim2.new(1, 0, 0, 20)
macroDesc.Position = UDim2.new(0, 0, 0, 50)
macroDesc.TextXAlignment = Enum.TextXAlignment.Left
macroDesc.TextYAlignment = Enum.TextYAlignment.Top
macroDesc.TextWrapped = true
macroDesc.Parent = macroPage

-- Main container with gradient background
local macroContainer = Instance.new("ScrollingFrame")
macroContainer.Name = "MacroContainer"
macroContainer.BackgroundColor3 = COLORS.background_tertiary
macroContainer.Size = UDim2.new(1, 0, 1, -90) -- fill page height (header ~80 + padding ~10)
macroContainer.Position = UDim2.new(0, 0, 0, 80)
macroContainer.Parent = macroPage
macroContainer.AutomaticCanvasSize = Enum.AutomaticSize.None
macroContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
macroContainer.ScrollBarThickness = 6
macroContainer.ScrollBarImageColor3 = COLORS.accent
macroContainer.BorderSizePixel = 0
macroContainer.ClipsDescendants = true
createCorner(macroContainer, 12)
createStroke(macroContainer, COLORS.border, 1, 0.8)

-- Control panel
local controlPanel = Instance.new("Frame")
controlPanel.BackgroundColor3 = COLORS.background_primary
controlPanel.Size = UDim2.new(1, -20, 0, 80)
controlPanel.Position = UDim2.new(0, 10, 0, 10)
controlPanel.Parent = macroContainer
createStroke(controlPanel, COLORS.border, 1, 0.8)
createCorner(controlPanel, 10)

-- Status indicator
local statusIndicator = Instance.new("Frame")
statusIndicator.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
statusIndicator.Size = UDim2.new(0, 10, 0, 10)
statusIndicator.Position = UDim2.new(0, 15, 0, 15)
statusIndicator.Parent = controlPanel
createCorner(statusIndicator, 5)

local statusPulse = Instance.new("UIStroke")
statusPulse.Color = Color3.fromRGB(80, 80, 90)
statusPulse.Thickness = 2
statusPulse.Transparency = 0.5
statusPulse.Parent = statusIndicator

-- Status text
local statusText = Instance.new("TextLabel")
statusText.Text = "IDLE"
statusText.TextColor3 = COLORS.text_secondary
statusText.BackgroundTransparency = 1
statusText.Font = Enum.Font.SourceSansBold
statusText.TextSize = 16
statusText.Size = UDim2.new(0, 200, 0, 20)
statusText.Position = UDim2.new(0, 35, 0, 10)
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = controlPanel



local statusDesc = Instance.new("TextLabel")
statusDesc.Text = "Ready to record"
statusDesc.TextColor3 = COLORS.text_dim
statusDesc.BackgroundTransparency = 1
statusDesc.Font = Enum.Font.SourceSans
statusDesc.TextSize = 13
statusDesc.Size = UDim2.new(0, 200, 0, 20)
statusDesc.Position = UDim2.new(0, 35, 0, 30)
statusDesc.TextXAlignment = Enum.TextXAlignment.Left
statusDesc.Parent = controlPanel
-- forward declaration so helpers above can call it before its definition
local updateStatus

local function basename(path)
  if not path then return nil end
  local name = path:match("([^/\\]+)$")
  return name
end

local function strip_json(extname)
  return extname and extname:gsub("%.json$", "") or extname
end

local function sanitizeName(s)
  s = tostring(s or ""):lower()
  s = s:gsub("[^a-z0-9_]", "_")
  s = s:gsub("_+", "_")
  s = s:gsub("^_+", ""):gsub("_+$", "")
  return s
end

-- add delete-file binding
do
  local g = getgenv and getgenv() or _G or {}
  FS.delfile   = FS.delfile or (rawget(g, "delfile") or (rawget(g, "syn") and g.syn.delfile) or (rawget(g, "krnl") and g.krnl.delfile))
end

local function resolveMacroPath(name)
  if not name or #tostring(name) == 0 then return nil end
  local n = tostring(name)
  -- if it already looks like a full path to a .json, use it directly
  if n:match("%.json$") and (n:find("/") or n:find("\\")) then
    return n
  end
  ensureFolder("Moon_Macros")
  -- keep only the basename, drop extension, then build our default path
  local base = strip_json(basename(n) or n)
  return "Moon_Macros/" .. base .. ".json"
end

-- ===== MACRO PICKER (Dropdown) =====
local selectedMacroName = nil
local macroIndex = {} -- displayName -> fullPath

local macroPicker = Instance.new("Frame")
macroPicker.Name = "MacroPicker"
macroPicker.BackgroundColor3 = COLORS.background_primary
macroPicker.Size = UDim2.new(1, -20, 0, 56)
macroPicker.Position = UDim2.new(0, 10, 0, 100)
macroPicker.Parent = macroContainer
macroPicker.ClipsDescendants = false
macroPicker.ZIndex = 50
createCorner(macroPicker, 10)
createStroke(macroPicker, COLORS.border, 1, 0.8)

local pickerLabel = Instance.new("TextLabel")
pickerLabel.BackgroundTransparency = 1
pickerLabel.Text = "Select macro file"
pickerLabel.TextColor3 = COLORS.text_dim
pickerLabel.Font = Enum.Font.SourceSansBold
pickerLabel.TextSize = 12
pickerLabel.Size = UDim2.new(1, -20, 0, 16)
pickerLabel.Position = UDim2.new(0, 10, 0, 4)
pickerLabel.TextXAlignment = Enum.TextXAlignment.Left
pickerLabel.Parent = macroPicker

local selectBtn = Instance.new("TextButton")
selectBtn.Name = "SelectMacroButton"
selectBtn.Text = "Choose macro"
selectBtn.AutoButtonColor = false
selectBtn.BackgroundColor3 = COLORS.background_secondary
selectBtn.TextColor3 = Color3.new(1,1,1)
selectBtn.Font = Enum.Font.SourceSansSemibold
selectBtn.TextSize = 14
selectBtn.Size = UDim2.new(1, -20, 0, 28)
selectBtn.Position = UDim2.new(0, 10, 0, 14)
selectBtn.Parent = macroPicker
selectBtn.ZIndex = 55
createCorner(selectBtn, 8)
local selectBtnStroke = createStroke(selectBtn, COLORS.border, 1, 0.7)

-- Restore previously selected macro from config (if any)
if Config and Config.data and Config.data.selectedMacro then
  selectedMacroName = Config.data.selectedMacro
  local display = selectedMacroName
  if type(display) == "string" then
    local bn = display:match("([^/\\]+)$") or display
    display = bn:gsub("%.json$","")
  end
  selectBtn.Text = tostring(display) .. " ▾"
end

-- Visual feedback when a macro is selected from the dropdown
local function flashMacroChosenFeedback()
  local originalBg = selectBtn.BackgroundColor3
  local originalStroke = selectBtnStroke.Color

  -- Small pop animation (grow then shrink)
  local grow = TweenService:Create(selectBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
    Size = UDim2.new(1, -16, 0, 31)
  })
  local shrink = TweenService:Create(selectBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
    Size = UDim2.new(1, -20, 0, 28)
  })

  -- Flash accent color on background and stroke
  TweenService:Create(selectBtn, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.accent }):Play()
  TweenService:Create(selectBtnStroke, TweenInfo.new(0.15), { Color = COLORS.accent }):Play()
  grow:Play()

  task.delay(0.18, function()
    TweenService:Create(selectBtn, TweenInfo.new(0.20), { BackgroundColor3 = originalBg }):Play()
    TweenService:Create(selectBtnStroke, TweenInfo.new(0.20), { Color = originalStroke }):Play()
    shrink:Play()
  end)
end

local dropdownList = Instance.new("ScrollingFrame")
dropdownList.Name = "DropdownList"
dropdownList.BackgroundColor3 = COLORS.background_secondary
dropdownList.BorderSizePixel = 0
dropdownList.Visible = false
dropdownList.ZIndex = 200
dropdownList.ScrollBarThickness = 4
dropdownList.ScrollBarImageColor3 = COLORS.accent
dropdownList.Size = UDim2.new(1, -20, 0, 150)
dropdownList.Position = UDim2.new(0, 10, 0, 40)
dropdownList.Parent = macroPicker
dropdownList.ClipsDescendants = true
dropdownList.ScrollingEnabled = true
createCorner(dropdownList, 8)
createStroke(dropdownList, COLORS.border, 1, 0.7)
-- Add padding so items don't start flush
local dropdownPadding = Instance.new("UIPadding")
dropdownPadding.PaddingTop = UDim.new(0, 4)
dropdownPadding.PaddingLeft = UDim.new(0, 4)
dropdownPadding.Parent = dropdownList

local dropdownLayout = Instance.new("UIListLayout")
dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropdownLayout.Padding = UDim.new(0, 4)
dropdownLayout.Parent = dropdownList

local function updateDropdownCanvas()
  dropdownList.CanvasSize = UDim2.new(0, 0, 0, dropdownLayout.AbsoluteContentSize.Y + dropdownPadding.PaddingTop.Offset + 4)
end

dropdownLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateDropdownCanvas)

local function clearDropdownItems()
  for _, child in ipairs(dropdownList:GetChildren()) do
    if child:IsA("TextButton") then
      child:Destroy()
    end
  end
end

local function addDropdownItem(displayText, fullPath)
  local item = Instance.new("TextButton")
  item.Text = displayText
  item.AutoButtonColor = false
  item.BackgroundColor3 = COLORS.background_tertiary
  item.TextColor3 = Color3.new(1,1,1)
  item.Font = Enum.Font.SourceSans
  item.TextSize = 14
  item.Size = UDim2.new(1, -8, 0, 26)
  -- item.Position = UDim2.new(0, 4, 0, 0) -- Removed: now handled by UIListLayout + UIPadding
  item.Parent = dropdownList
  item.ZIndex = dropdownList.ZIndex + 1
  createCorner(item, 6)

  macroIndex[displayText] = fullPath or displayText

  item.MouseEnter:Connect(function()
    TweenService:Create(item, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.button_hover}):Play()
  end)
  item.MouseLeave:Connect(function()
    TweenService:Create(item, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.background_tertiary}):Play()
  end)
  item.MouseButton1Click:Connect(function()
    selectedMacroName = macroIndex[displayText]
    selectBtn.Text = displayText .. " ▾"
    dropdownList.Visible = false
    Config.data.selectedMacro = selectedMacroName
    saveConfig()
    flashMacroChosenFeedback()
  end)
end

local function refreshMacroList()
  clearDropdownItems()
  local list = nil
  local ok = pcall(function()
    if getgenv and getgenv().MacroManager and getgenv().MacroManager.list then
      list = getgenv().MacroManager.list()
    elseif getgenv and getgenv().MacroAPI and getgenv().MacroAPI.list then
      list = getgenv().MacroAPI.list()
    end
  end)

  local added = false

  -- 1) Si la API devolvió algo, úsalo tal cual
  if ok and type(list) == "table" and #list > 0 then
    for _, name in ipairs(list) do
      if type(name) == "string" and #name > 0 then
        -- Mostramos nombre “bonito” pero guardamos ruta/nombre tal cual nos lo da la API
        local display = strip_json(basename(name)) or name
        addDropdownItem(display, name)
        added = true
      end
    end
  end

  -- 2) Fallback: listar archivos de la carpeta Moon_Macros/*.json
  if not added and FS.listfiles then
    ensureFolder("Moon_Macros")
    local ok2, files = pcall(FS.listfiles, "Moon_Macros")
    if ok2 and type(files) == "table" then
      table.sort(files, function(a,b) return tostring(a):lower() < tostring(b):lower() end)
      for _, path in ipairs(files) do
        local p = tostring(path)
        if p:lower():match("%.json$") then
          local disp = strip_json(basename(p))
          addDropdownItem(disp, p)   -- display bonito, path completo para cargar
          added = true
        end
      end
    end
  end

  if not added then
    addDropdownItem("No macros found", nil)
  end

  updateDropdownCanvas()
  -- ensure we start at the top each time the list opens
  dropdownList.CanvasPosition = Vector2.new(0, 0)
end

  -- Ajusta el canvas al contenido real
selectBtn.MouseButton1Click:Connect(function()
  if dropdownList.Visible then
    dropdownList.Visible = false
  else
    refreshMacroList()
    dropdownList.Visible = true
    updateDropdownCanvas()
    dropdownList.CanvasPosition = Vector2.new(0, 0)
  end
end)

-- Cerrar dropdown al hacer click fuera del área
UIS.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 and dropdownList.Visible then
    local pos = input.Position
    local topLeft = dropdownList.AbsolutePosition
    local bottomRight = topLeft + dropdownList.AbsoluteSize
    if not (pos.X >= topLeft.X and pos.X <= bottomRight.X and pos.Y >= topLeft.Y and pos.Y <= bottomRight.Y) then
      dropdownList.Visible = false
    end
  end
end)

local buttonContainer = Instance.new("Frame")
buttonContainer.BackgroundTransparency = 1
buttonContainer.Size = UDim2.new(1, -40, 0, 40)
buttonContainer.Position = UDim2.new(0, 20, 0, 170)
buttonContainer.Parent = macroContainer

local buttonsLayout = Instance.new("UIListLayout")
buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonsLayout.Padding = UDim.new(0, 12)
buttonsLayout.Parent = buttonContainer

local function createMacroButton(icon, text, color)
  local button = Instance.new("TextButton")
  button.Text = ""
  button.BackgroundColor3 = COLORS.background_secondary
  button.Size = UDim2.new(0, 110, 0, 40)
  button.Position = UDim2.new(0, 0, 0, 0)
  button.AutoButtonColor = false
  button.Parent = buttonContainer
  createCorner(button, 10)
  -- Use provided color as stroke if given, fallback to COLORS.border
  local stroke = createStroke(button, color or COLORS.border, 1, 0.3)

  -- Icon
  local iconLabel = Instance.new("TextLabel")
  iconLabel.Text = icon
  iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
  iconLabel.BackgroundTransparency = 1
  iconLabel.Font = Enum.Font.SourceSansBold
  iconLabel.TextSize = 20
  iconLabel.Size = UDim2.new(0, 30, 1, 0)
  iconLabel.Position = UDim2.new(0, 10, 0, 0)
  iconLabel.Parent = button

  -- Text
  local textLabel = Instance.new("TextLabel")
  textLabel.Text = text
  textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
  textLabel.BackgroundTransparency = 1
  textLabel.Font = Enum.Font.SourceSansSemibold
  textLabel.TextSize = 14
  textLabel.Size = UDim2.new(1, -40, 1, 0)
  textLabel.Position = UDim2.new(0, 35, 0, 0)
  textLabel.TextXAlignment = Enum.TextXAlignment.Left
  textLabel.Parent = button

  -- Hover / press effects matching the rest of the UI
  button.MouseEnter:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.button_hover}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.12), {Color = COLORS.accent}):Play()
  end)
  button.MouseLeave:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.background_secondary}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.12), {Color = color or COLORS.border}):Play()
  end)
  button.MouseButton1Down:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.08), {BackgroundColor3 = COLORS.background_secondary}):Play()
  end)
  button.MouseButton1Up:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.08), {BackgroundColor3 = COLORS.button_hover}):Play()
  end)

  return button, iconLabel
end

local recordBtn, recordIcon = createMacroButton("●", "Record", Color3.fromRGB(220, 60, 60))
local playBtn, playIcon   = createMacroButton("▶", "Play",   Color3.fromRGB(60, 180, 75))
local stopBtn, stopIcon   = createMacroButton("■", "Stop",   Color3.fromRGB(80, 120, 220))

-- Ensure MacroAPI (recorder) is loaded once
pcall(function()
  if not (getgenv and getgenv().MacroAPI) then
    local url = "https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/macrosys.lua"
    local ok, err = pcall(function()
      local src = game:HttpGet(url)
      local f = loadstring(src)
      if type(f) == "function" then f() end
    end)
    if not ok then
      warn("[MacroUI] Failed to autoload macrosys.lua: " .. tostring(err))
    end
  end
end)

-- Recorded actions list
local listContainer = Instance.new("Frame")
listContainer.BackgroundColor3 = COLORS.background_secondary
listContainer.Size = UDim2.new(1, -20, 0, 180)
listContainer.Position = UDim2.new(0, 10, 0, 220)
listContainer.Parent = macroContainer
createCorner(listContainer, 10)

local listHeader = Instance.new("TextLabel")
listHeader.Text = "RECORDED ACTIONS"
listHeader.TextColor3 = COLORS.text_dim
listHeader.BackgroundTransparency = 1
listHeader.Font = Enum.Font.SourceSansBold
listHeader.TextSize = 12
listHeader.Size = UDim2.new(1, -20, 0, 25)
listHeader.Position = UDim2.new(0, 10, 0, 5)
listHeader.Parent = listContainer

local actionsList = Instance.new("ScrollingFrame")
actionsList.BackgroundColor3 = COLORS.background_primary
actionsList.BorderSizePixel = 0
actionsList.ScrollBarImageColor3 = COLORS.accent
actionsList.ScrollBarImageTransparency = 0.5
actionsList.ScrollBarThickness = 3
actionsList.Size = UDim2.new(1, -20, 1, -35)
actionsList.Position = UDim2.new(0, 10, 0, 30)
actionsList.CanvasSize = UDim2.new(0, 0, 0, 0)
actionsList.Parent = listContainer
createCorner(actionsList, 8)

local actionsLayout = Instance.new("UIListLayout")
actionsLayout.Padding = UDim.new(0, 2)
actionsLayout.Parent = actionsList

actionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  actionsList.CanvasSize = UDim2.new(0, 0, 0, actionsLayout.AbsoluteContentSize.Y)
end)

-- ===== NEW MACRO NAME INPUT (Create JSON) =====
-- UI block placed above Auto replay
local newMacroBox = Instance.new("Frame")
newMacroBox.Name = "NewMacroBox"
newMacroBox.BackgroundColor3 = COLORS.background_secondary
newMacroBox.Size = UDim2.new(1, -20, 0, 75)
newMacroBox.Position = UDim2.new(0, 10, 0, 410)
newMacroBox.Parent = macroContainer
createCorner(newMacroBox, 10)
createStroke(newMacroBox, COLORS.border, 1, 0.8)

local nmTitle = Instance.new("TextLabel")
nmTitle.Text = "Create new macro file"
nmTitle.TextColor3 = COLORS.text_secondary
nmTitle.BackgroundTransparency = 1
nmTitle.Font = Enum.Font.SourceSansSemibold
nmTitle.TextSize = 16
nmTitle.Size = UDim2.new(1, -20, 0, 22)
nmTitle.Position = UDim2.new(0, 10, 0, 8)
nmTitle.TextXAlignment = Enum.TextXAlignment.Left
nmTitle.Parent = newMacroBox

local nameInput = Instance.new("TextBox")
nameInput.Name = "NameInput"
nameInput.ClearTextOnFocus = false
nameInput.PlaceholderText = "new macro name"
nameInput.Text = ""
nameInput.TextColor3 = Color3.new(1,1,1)
nameInput.PlaceholderColor3 = COLORS.text_dim
nameInput.Font = Enum.Font.SourceSans
nameInput.TextSize = 14
nameInput.BackgroundColor3 = COLORS.background_primary
nameInput.Size = UDim2.new(1, -20, 0, 30)
nameInput.Position = UDim2.new(0, 10, 0, 38)
nameInput.Parent = newMacroBox
createCorner(nameInput, 8)
createStroke(nameInput, COLORS.border, 1, 0.7)

-- cross-executor filesystem helpers

local function createMacroJson(rawName)
  if not FS.writefile then
    updateStatus("idle", "Filesystem not supported by your executor")
    return
  end
  local base = sanitizeName(rawName)
  if #base == 0 then
    updateStatus("idle", "Enter a valid name")
    return
  end
  ensureFolder("Moon_Macros")
  local filePath = "Moon_Macros/" .. base
  if not filePath:match("%.json$") then
    filePath = filePath .. ".json"
  end

  -- if exists, add numeric suffix
  local finalPath = filePath
  if FS.isfile and FS.isfile(finalPath) then
    local i = 2
    while FS.isfile("Moon_Macros/" .. base .. "_" .. i .. ".json") do
      i += 1
    end
    finalPath = "Moon_Macros/" .. base .. "_" .. i .. ".json"
  end

  local template = ""

  local ok, err = pcall(FS.writefile, finalPath, template)
  if ok then
    updateStatus("idle", "Created: " .. finalPath)
    pcall(refreshMacroList)
  else
    updateStatus("idle", "Error creating file: " .. tostring(err))
  end
end

-- Enter on PC & mobile keyboards
nameInput.FocusLost:Connect(function(enterPressed)
  if enterPressed then
    createMacroJson(nameInput.Text)
  end
end)

-- ===== FILE ACTION BUTTONS (below Create new macro file) =====
local fileButtonsBox = Instance.new("Frame")
fileButtonsBox.Name = "FileButtonsBox"
fileButtonsBox.BackgroundColor3 = COLORS.background_secondary
fileButtonsBox.Size = UDim2.new(1, -20, 0, 60)
fileButtonsBox.Position = UDim2.new(0, 10, 0, 490)
fileButtonsBox.Parent = macroContainer
createCorner(fileButtonsBox, 10)
createStroke(fileButtonsBox, COLORS.border, 1, 0.8)

local fbLayout = Instance.new("UIListLayout")
fbLayout.FillDirection = Enum.FillDirection.Horizontal
fbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
fbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
fbLayout.Padding = UDim.new(0, 12)
fbLayout.Parent = fileButtonsBox

local function smallActionButton(text, strokeColor, fillColor)
  local b = Instance.new("TextButton")
  b.Text = text
  b.AutoButtonColor = false
  b.BackgroundColor3 = fillColor or COLORS.background_tertiary
  b.TextColor3 = COLORS.text_secondary
  b.Font = Enum.Font.SourceSansSemibold
  b.TextSize = 14
  b.Size = UDim2.new(0, 150, 0, 36)
  b.Parent = fileButtonsBox
  createCorner(b, 8)
  local stroke = createStroke(b, strokeColor or COLORS.border, 1, 0.3)

  b.MouseEnter:Connect(function()
    TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = COLORS.button_hover}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.12), {Color = strokeColor or COLORS.accent}):Play()
  end)
  b.MouseLeave:Connect(function()
    TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = fillColor or COLORS.background_tertiary}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.12), {Color = strokeColor or COLORS.border}):Play()
  end)
  b.MouseButton1Down:Connect(function()
    TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3 = COLORS.background_secondary}):Play()
  end)
  b.MouseButton1Up:Connect(function()
    TweenService:Create(b, TweenInfo.new(0.08), {BackgroundColor3 = COLORS.button_hover}):Play()
  end)

  return b
end

local wipeBtn   = smallActionButton("Wipe macro", COLORS.accent)
local deleteBtn = smallActionButton("Delete macro", Color3.fromRGB(220, 90, 90))

local function resetSelection()
  selectedMacroName = nil
  selectBtn.Text = "Choose macro"
end

local function wipeSelectedMacro()
  if not FS.writefile then
    updateStatus("idle", "Filesystem not supported by your executor")
    return
  end
  local path = resolveMacroPath(selectedMacroName)
  if not path then
    updateStatus("idle", "Select a macro first")
    return
  end
  local ok, err = pcall(function()
    FS.writefile(path, "")
  end)
  if ok then
    updateStatus("idle", "Wiped: " .. path)
  else
    updateStatus("idle", "Error wiping file: " .. tostring(err))
  end
end

local function deleteSelectedMacro()
  if not FS.delfile then
    updateStatus("idle", "Delete not supported by your executor")
    return
  end
  local path = resolveMacroPath(selectedMacroName)
  if not path then
    updateStatus("idle", "Select a macro first")
    return
  end
  local ok, err = pcall(function()
    FS.delfile(path)
  end)
  if ok then
    updateStatus("idle", "Deleted: " .. path)
    resetSelection()
    pcall(refreshMacroList)
  else
    updateStatus("idle", "Error deleting file: " .. tostring(err))
  end
end

wipeBtn.MouseButton1Click:Connect(function()
  wipeSelectedMacro()
end)

deleteBtn.MouseButton1Click:Connect(function()
  deleteSelectedMacro()
end)

-- ===== AUTO REPLAY TOGGLE =====
-- Macro state (declared early so upvalues exist)
local isRecording = false
local isPlaying = false
local recordedActions = {}
-- UI block (same look as Find Trait Burner)
local autoReplayBox = Instance.new("Frame")
autoReplayBox.Name = "AutoReplayBox"
autoReplayBox.BackgroundColor3 = COLORS.background_secondary
autoReplayBox.Size = UDim2.new(1, -20, 0, 110)
autoReplayBox.Position = UDim2.new(0, 10, 0, 560) -- moved down to make room for file buttons
autoReplayBox.Parent = macroContainer
createCorner(autoReplayBox, 10)
createStroke(autoReplayBox, COLORS.border, 1, 0.8)

local arToggleContainer = Instance.new("Frame")
arToggleContainer.BackgroundTransparency = 1
arToggleContainer.Size = UDim2.new(1, -20, 0, 40)
arToggleContainer.Position = UDim2.new(0, 10, 0, 10)
arToggleContainer.Parent = autoReplayBox

local arTitle = Instance.new("TextLabel")
arTitle.Text = "Auto replay"
arTitle.TextColor3 = COLORS.text_secondary
arTitle.BackgroundTransparency = 1
arTitle.Font = Enum.Font.SourceSansSemibold
arTitle.TextSize = 16
arTitle.Size = UDim2.new(0, 150, 1, 0)
arTitle.Position = UDim2.new(0, 0, 0, 0)
arTitle.TextXAlignment = Enum.TextXAlignment.Left
arTitle.Parent = arToggleContainer

local arSwitch = Instance.new("Frame")
arSwitch.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
arSwitch.Size = UDim2.new(0, 50, 0, 26)
arSwitch.Position = UDim2.new(1, -50, 0.5, 0)
arSwitch.AnchorPoint = Vector2.new(1, 0.5)
arSwitch.Parent = arToggleContainer
createCorner(arSwitch, 13)

local arKnob = Instance.new("Frame")
arKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
arKnob.Size = UDim2.new(0, 22, 0, 22)
arKnob.Position = UDim2.new(0, 2, 0.5, 0)
arKnob.AnchorPoint = Vector2.new(0, 0.5)
arKnob.Parent = arSwitch
createCorner(arKnob, 11)

local arDesc = Instance.new("TextLabel")
arDesc.Text = "With this option you can repeat the macro indefinitely until it is disabled."
arDesc.TextColor3 = COLORS.text_dim
arDesc.BackgroundTransparency = 1
arDesc.Font = Enum.Font.SourceSans
arDesc.TextSize = 13
arDesc.Size = UDim2.new(1, -20, 0, 40)
arDesc.Position = UDim2.new(0, 10, 0, 55)
arDesc.TextXAlignment = Enum.TextXAlignment.Left
arDesc.TextYAlignment = Enum.TextYAlignment.Top
arDesc.TextWrapped = true
arDesc.Parent = autoReplayBox

-- Logic state
local AutoReplay = { enabled = false, task = nil }

local function queryIsPlayingFromAPI()
  local playing
  pcall(function()
    if getgenv and getgenv().MacroAPI then
      if type(getgenv().MacroAPI.isPlaying) == "function" then
        playing = getgenv().MacroAPI.isPlaying()
      elseif type(getgenv().MacroAPI.status) == "function" then
        local st = getgenv().MacroAPI.status()
        if type(st) == "table" and st.playing ~= nil then
          playing = st.playing
        end
      end
    end
  end)
  return playing
end

local function ensureAutoReplayLoop()
  if AutoReplay.task ~= nil then return end
  AutoReplay.task = task.spawn(function()
    while AutoReplay.enabled do
      -- keep local isPlaying in sync if API exposes a signal/state
      local apiPlaying = queryIsPlayingFromAPI()
      if apiPlaying ~= nil then
        isPlaying = apiPlaying and true or false
      end

      if not isRecording and not isPlaying then
        -- Nothing is playing: start (or restart) playback
        local usedAPI = false
        pcall(function()
          if getgenv and getgenv().MacroAPI then
            if selectedMacroName and getgenv().MacroAPI.load then
              getgenv().MacroAPI.load(selectedMacroName)
            elseif selectedMacroName and getgenv().MacroManager and getgenv().MacroManager.select then
              getgenv().MacroManager.select(selectedMacroName)
            end
            if getgenv().MacroAPI.play then
              getgenv().MacroAPI.play()
              usedAPI = true
            elseif getgenv().MacroAPI.start then
              getgenv().MacroAPI.start()
              usedAPI = true
            end
          end
        end)

        if usedAPI then
          isPlaying = true
          updateStatus("playing", selectedMacroName and ("Playing: " .. tostring(selectedMacroName)) or "Playing recorded actions...")
        else
          -- Fallback: if there are items recorded in the UI, simulate a playback
          local hasRows = false
          for _, child in ipairs(actionsList:GetChildren()) do
            if child:IsA("TextLabel") then hasRows = true break end
          end
          if hasRows then
            isPlaying = true
            updateStatus("playing", "Playing recorded actions...")
            task.wait(3)
            isPlaying = false
            updateStatus("idle", "Playback complete")
          end
        end
      end

      task.wait(1.0)
    end
    AutoReplay.task = nil
  end)
end

local function toggleAutoReplay()
  AutoReplay.enabled = not AutoReplay.enabled
  if AutoReplay.enabled then
    TweenService:Create(arKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(1, -24, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)}):Play()
    TweenService:Create(arSwitch, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.accent}):Play()
    Config.data.toggles = Config.data.toggles or {}
    Config.data.toggles.autoReplay = true
    saveConfig()
    ensureAutoReplayLoop()
  else
    TweenService:Create(arKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)}):Play()
    TweenService:Create(arSwitch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
    Config.data.toggles = Config.data.toggles or {}
    Config.data.toggles.autoReplay = false
    saveConfig()
  end
end

-- Restore persisted state for Auto Replay
do
  local on = Config and Config.data and Config.data.toggles and Config.data.toggles.autoReplay
  if on then
    AutoReplay.enabled = true
    arKnob.Position = UDim2.new(1, -24, 0.5, 0)
    arSwitch.BackgroundColor3 = COLORS.accent
    ensureAutoReplayLoop()
  else
    AutoReplay.enabled = false
    arKnob.Position = UDim2.new(0, 2, 0.5, 0)
    arSwitch.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
  end
end

arSwitch.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    toggleAutoReplay()
  end
end)

-- ===== AUTO SELECT MACRO TOGGLE =====
-- UI block (same look as Auto replay / Find Trait Burner)
local autoSelectBox = Instance.new("Frame")
autoSelectBox.Name = "AutoSelectBox"
autoSelectBox.BackgroundColor3 = COLORS.background_secondary
autoSelectBox.Size = UDim2.new(1, -20, 0, 130)
autoSelectBox.Position = UDim2.new(0, 10, 0, 700) -- moved down to make room for file buttons/auto replay
autoSelectBox.Parent = macroContainer
createCorner(autoSelectBox, 10)
createStroke(autoSelectBox, COLORS.border, 1, 0.8)

local asToggleContainer = Instance.new("Frame")
asToggleContainer.BackgroundTransparency = 1
asToggleContainer.Size = UDim2.new(1, -20, 0, 40)
asToggleContainer.Position = UDim2.new(0, 10, 0, 10)
asToggleContainer.Parent = autoSelectBox

local asTitle = Instance.new("TextLabel")
asTitle.Text = "Auto select macro"
asTitle.TextColor3 = COLORS.text_secondary
asTitle.BackgroundTransparency = 1
asTitle.Font = Enum.Font.SourceSansSemibold
asTitle.TextSize = 16
asTitle.Size = UDim2.new(0, 200, 1, 0)
asTitle.Position = UDim2.new(0, 0, 0, 0)
asTitle.TextXAlignment = Enum.TextXAlignment.Left
asTitle.Parent = asToggleContainer

local asSwitch = Instance.new("Frame")
asSwitch.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- igual que el de Auto replay cuando está apagado
asSwitch.Size = UDim2.new(0, 50, 0, 26)
asSwitch.Position = UDim2.new(1, -50, 0.5, 0)
asSwitch.AnchorPoint = Vector2.new(1, 0.5)
asSwitch.Parent = asToggleContainer
createCorner(asSwitch, 13)

local asKnob = Instance.new("Frame")
asKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
asKnob.Size = UDim2.new(0, 22, 0, 22)
asKnob.Position = UDim2.new(0, 2, 0.5, 0)
asKnob.AnchorPoint = Vector2.new(0, 0.5)
asKnob.Parent = asSwitch
createCorner(asKnob, 11)


local asDesc = Instance.new("TextLabel")
asDesc.Text = "With this option the script will choose the macro automatically depending on the map and the challenge *Do not enable Auto replay while this is active*."
asDesc.TextColor3 = COLORS.text_dim
asDesc.BackgroundTransparency = 1
asDesc.Font = Enum.Font.SourceSans
asDesc.TextSize = 13
asDesc.Size = UDim2.new(1, -20, 0, 60)
asDesc.Position = UDim2.new(0, 10, 0, 55)
asDesc.TextXAlignment = Enum.TextXAlignment.Left
asDesc.TextYAlignment = Enum.TextYAlignment.Top
asDesc.TextWrapped = true
asDesc.Parent = autoSelectBox

-- Logic state for Auto Select
local AutoSelect = { enabled = false }

local function setAutoSelectVisual(on)
  if on then
    asKnob.Position = UDim2.new(1, -24, 0.5, 0)
    asSwitch.BackgroundColor3 = COLORS.accent
  else
    asKnob.Position = UDim2.new(0, 2, 0.5, 0)
    asSwitch.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
  end
end

local function toggleAutoSelect()
  AutoSelect.enabled = not AutoSelect.enabled

  -- Persist
  Config.data.toggles = Config.data.toggles or {}
  Config.data.toggles.autoSelect = AutoSelect.enabled and true or false
  saveConfig()

  -- Visual
  setAutoSelectVisual(AutoSelect.enabled)

  -- Regla de exclusión con Auto Replay: si activas Auto Select, apaga Auto Replay
  if AutoSelect.enabled and AutoReplay and AutoReplay.enabled then
    AutoReplay.enabled = false
    -- reflejar visualmente el otro switch
    arKnob.Position = UDim2.new(0, 2, 0.5, 0)
    arSwitch.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Config.data.toggles.autoReplay = false
    saveConfig()
  end
end

-- Restaurar estado al arrancar
do
  local on = Config and Config.data and Config.data.toggles and Config.data.toggles.autoSelect
  AutoSelect.enabled = not not on
  setAutoSelectVisual(AutoSelect.enabled)
end

-- Click handler
asSwitch.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    toggleAutoSelect()
  end
end)

-- ===== AUTO SELECT MACRO INFO PANEL =====
-- Info panel explaining macro file naming
local macroInfoPanel = Instance.new("Frame")
macroInfoPanel.Name = "MacroInfoPanel"
macroInfoPanel.BackgroundColor3 = COLORS.background_secondary
macroInfoPanel.Size = UDim2.new(1, -20, 0, 300) -- fixed height to avoid AutomaticSize quirks in ScrollingFrame
macroInfoPanel.Position = UDim2.new(0, 10, 0, 840) -- moved down to make room for file buttons/auto replay/auto select
macroInfoPanel.Parent = macroContainer
createCorner(macroInfoPanel, 10)
createStroke(macroInfoPanel, COLORS.border, 1, 0.8)

-- Header
local macroInfoHeader = Instance.new("TextLabel")
macroInfoHeader.BackgroundTransparency = 1
macroInfoHeader.Text = "Macro Naming Rules"
macroInfoHeader.TextColor3 = COLORS.text_secondary
macroInfoHeader.Font = Enum.Font.SourceSansBold
macroInfoHeader.TextSize = 16
macroInfoHeader.Size = UDim2.new(1, -20, 0, 22)
macroInfoHeader.Position = UDim2.new(0, 10, 0, 10)
macroInfoHeader.TextXAlignment = Enum.TextXAlignment.Left
macroInfoHeader.Parent = macroInfoPanel

local macroInfoDivider = Instance.new("Frame")
macroInfoDivider.BackgroundColor3 = COLORS.accent
macroInfoDivider.BackgroundTransparency = 0.65
macroInfoDivider.Size = UDim2.new(0, 120, 0, 2)
macroInfoDivider.Position = UDim2.new(0, 10, 0, 34)
macroInfoDivider.Parent = macroInfoPanel

-- Body
local macroInfoBody = Instance.new("TextLabel")
macroInfoBody.Name = "MacroInfoBody"
macroInfoBody.BackgroundTransparency = 1
macroInfoBody.TextColor3 = COLORS.text_dim
macroInfoBody.Font = Enum.Font.SourceSans
macroInfoBody.TextSize = 15
macroInfoBody.TextWrapped = true
macroInfoBody.TextYAlignment = Enum.TextYAlignment.Top
macroInfoBody.TextXAlignment = Enum.TextXAlignment.Left
macroInfoBody.Size = UDim2.new(1, -20, 0, 250)
macroInfoBody.Position = UDim2.new(0, 10, 0, 44)
macroInfoBody.Parent = macroInfoPanel

macroInfoBody.Text = [[To use Auto Select Macro, file names must follow this strict format:

• General macros → [map_name]_general
  Covers challenges:
  - Flying enemies
  - Juggernaut enemies
  - Unsellable

  Examples:
  - city_of_york_general
  - city_of_voldstanding_general

• Special challenges → [map_name]_[challenge_type]
  Challenge types:
  - single_placement
  - high_cost

  Examples:
  - hidden_storm_village_single_placement
  - giant_island_high_cost

Notes:
- Use lowercase letters and underscores only.
- Always end with _general, _single_placement, or _high_cost depending on the challenge.
- If you need one macro per challenge, duplicate the map name with the correct suffix.]]

-- Auto-size the Macro Naming Rules body/panel and keep the ScrollingFrame canvas in sync
local function recomputeCanvas()
  local maxY = 0
  for _, c in ipairs(macroContainer:GetChildren()) do
    if c:IsA("GuiObject") and c.Visible then
      local bottom = c.Position.Y.Offset + c.Size.Y.Offset
      if bottom > maxY then
        maxY = bottom
      end
    end
  end
  -- add a small padding so it never clips at the very end
  macroContainer.CanvasSize = UDim2.new(0, 0, 0, maxY + 20)
end

-- Let the body grow to its natural height and resize the panel accordingly
macroInfoBody.AutomaticSize = Enum.AutomaticSize.Y
macroInfoBody:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
  macroInfoPanel.Size = UDim2.new(1, -20, 0, macroInfoBody.AbsoluteSize.Y + 64)
  recomputeCanvas()
end)

-- First sizing pass (after text is applied and AbsoluteSize is computed)
task.defer(function()
  macroInfoPanel.Size = UDim2.new(1, -20, 0, macroInfoBody.AbsoluteSize.Y + 64)
  recomputeCanvas()
end)

-- Logic state
local AutoSelect = { enabled = false, task = nil, lastPick = nil }

-- Restore persisted state for Auto Select Macro
do
  local on = Config and Config.data and Config.data.toggles and Config.data.toggles.autoSelect
  if on then
    AutoSelect.enabled = true
    asKnob.Position = UDim2.new(1, -24, 0.5, 0)
    asSwitch.BackgroundColor3 = COLORS.accent
  else
    AutoSelect.enabled = false
    asKnob.Position = UDim2.new(0, 2, 0.5, 0)
    asSwitch.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
  end
end

  if on then
    AutoSelect.enabled = true
    asKnob.Position = UDim2.new(1, -24, 0.5, 0)
    asSwitch.BackgroundColor3 = COLORS.accent
  else
    AutoSelect.enabled = false
    asKnob.Position = UDim2.new(0, 2, 0.5, 0)
    asSwitch.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
  end
end

local function getMapAndChallenge()
  local mapName, challengeName
  pcall(function()
    -- Try to infer from Workspace
    if workspace:FindFirstChild("Map") then
      mapName = workspace.Map.Name
    end
    -- Use our FindTBModule memory if present
    if FindTBModule and FindTBModule.state and FindTBModule.state.L<truncated__content/>
-- Toggle handler for Auto Select Macro
local function toggleAutoSelect()
  AutoSelect.enabled = not AutoSelect.enabled
  if AutoSelect.enabled then
    TweenService:Create(asKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(1, -24, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)}):Play()
    TweenService:Create(asSwitch, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.accent}):Play()
    Config.data.toggles = Config.data.toggles or {}
    Config.data.toggles.autoSelect = true
    saveConfig()
  else
    TweenService:Create(asKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)}):Play()
    TweenService:Create(asSwitch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
    Config.data.toggles = Config.data.toggles or {}
    Config.data.toggles.autoSelect = false
    saveConfig()
  end
end

asSwitch.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    toggleAutoSelect()
  end
end)