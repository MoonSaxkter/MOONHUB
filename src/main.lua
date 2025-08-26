-- UI con Sistema de Navegación Elegante
-- Interfaz visual mejorada con pestañas y diseño moderno

-- Servicios
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Verificación de LocalPlayer
local player = Players.LocalPlayer
if not player then
  warn("[UI] LocalPlayer = nil. Ejecuta este código como LocalScript.")
  return
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
mainFrame.Size = UDim2.new(0, 600, 0, 560)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Parent = gui
createCorner(mainFrame, 16)
createStroke(mainFrame, COLORS.border, 1, 0.7)

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

-- Description
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

-- ===== FIND TRAIT BURNER MODULE =====
local FindTBModule = {}

-- Module configuration
FindTBModule.config = {
  UI_TIMEOUT_SEC = 20,
  RETRIES_PRESS = 3,
  WAIT_BETWEEN_TRY = 0.35,
  TB_EVENT_WINDOW = 1.3,
  CHAPTER = 1,
  DIFFICULTY = "Hard",
  RESCAN_EVERY_SEC = 5,
  MAX_ROUNDS = 240
}

-- Module state
FindTBModule.state = {
  LAST_SELECTED = "Challenge1",
  ENTERED = false,
  isRunning = false,
  scanTask = nil
}

-- Utility: Path traversal with timeout
function FindTBModule.descend(root, segments, timeout)
  local t0 = tick()
  local node = root
  for _, name in ipairs(segments) do
    while not (node and node:FindFirstChild(name)) do
      if tick() - t0 > (timeout or FindTBModule.config.UI_TIMEOUT_SEC) then
        return nil
      end
      if not node then return nil end
      node.ChildAdded:Wait()
    end
    node = node[name]
  end
  return node
end

-- Get connections safely
function FindTBModule.getConnections()
  local okEnv, env = pcall(function() return getgenv and getgenv() end)
  if okEnv and type(env) == "table" and type(env.getconnections) == "function" then
    return env.getconnections
  end
  if type(getconnections) == "function" then
    return getconnections
  end
  return nil
end

-- Robust click implementation
function FindTBModule.robustClick(btn)
  if not (btn and btn:IsA("TextButton")) then return false end
  
  -- Try firesignal first
  local fs = (getgenv and getgenv().firesignal) or (_G and _G.firesignal)
  if type(fs) == "function" then
    pcall(function()
      if typeof(btn.MouseButton1Click) == "RBXScriptSignal" then fs(btn.MouseButton1Click) end
      if typeof(btn.Activated) == "RBXScriptSignal" then fs(btn.Activated) end
    end)
    return true
  end
  
  -- Try getconnections
  local gc = FindTBModule.getConnections()
  if gc then
    pcall(function()
      for _, signal in ipairs({btn.MouseButton1Click, btn.Activated}) do
        if typeof(signal) == "RBXScriptSignal" then
          for _, c in ipairs(gc(signal)) do
            if c and c.Function and c.Connected ~= false then
              pcall(c.Function)
            end
          end
        end
      end
    end)
    task.wait(0.02)
  end
  
  -- Fallback to VirtualInputManager
  pcall(function()
    local vim = game:GetService("VirtualInputManager")
    local center = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
    vim:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
    vim:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
  end)
  
  return true
end

-- TP to Challenge Pod
function FindTBModule.tpToChallengePod()
  local obj = workspace:FindFirstChild("Map")
    and workspace.Map:FindFirstChild("Buildings")
    and workspace.Map.Buildings:FindFirstChild("ChallengePods")
  
  if obj and obj:FindFirstChild("Pod") and obj.Pod:FindFirstChild("Interact") then
    obj = obj.Pod.Interact
  else
    local cp = obj
    if cp then
      for _, d in ipairs(cp:GetDescendants()) do
        if d.Name == "Interact" then 
          obj = d 
          break 
        end
      end
    end
  end
  
  if not obj then return false end
  
  local ok = pcall(function()
    local RF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetFunction")
    RF:InvokeServer({ Type = "Lobby", Object = obj, Mode = "Pod" })
  end)
  return ok
end

-- Check for Trait Burner in rewards
function FindTBModule.hasTraitBurner()
  local PATH_REWARD_SCROLL = {
    "MainUI", "WorldFrame", "WorldFrame", "MainFrame", "RightFrame", "InfoFrame", "InfoInner",
    "BoxFrame", "InfoFrame2", "InnerFrame", "CanvasFrame", "CanvasGroup", "BottomFrame",
    "DetailFrame", "RewardFrame", "Rewards", "RewardScroll"
  }
  
  local scroll = FindTBModule.descend(player.PlayerGui, PATH_REWARD_SCROLL, 6.0)
  if not scroll then return false end
  
  -- Deep scan for TB
  for _, n in ipairs(scroll:GetDescendants()) do
    if n:IsA("TextLabel") and n.Text then
      local text = n.Text:lower()
      if text:find("trait burner", 1, true) then
        return true
      end
    end
  end
  
  return false
end

-- Main scan function
function FindTBModule.scanChallenges()
  if not FindTBModule.state.isRunning then return end
  
  -- TP to pod first
  FindTBModule.tpToChallengePod()
  task.wait(2)
  
  -- Scan each challenge
  for i = 1, 4 do
    if not FindTBModule.state.isRunning then break end
    if FindTBModule.state.ENTERED then break end
    
    -- Click challenge button
    local stageScroll = player.PlayerGui:FindFirstChild("MainUI", true)
    if stageScroll then
      stageScroll = stageScroll:FindFirstChild("StageScroll", true)
      if stageScroll then
        local challenge = stageScroll:FindFirstChild("Challenge" .. i)
        if challenge then
          local btn = challenge:FindFirstChild("Button")
          if btn then
            FindTBModule.robustClick(btn)
            task.wait(1)
            
            -- Check for TB
            if FindTBModule.hasTraitBurner() then
              print("[FindTB] Found Trait Burner in Challenge " .. i)
              FindTBModule.state.ENTERED = true
              -- Start challenge
              pcall(function()
                local RF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GetFunction")
                RF:InvokeServer({
                  Chapter = FindTBModule.config.CHAPTER,
                  Type = "Lobby",
                  Name = "Challenge" .. i,
                  Friend = true,
                  Mode = "Pod",
                  Update = true,
                  Difficulty = FindTBModule.config.DIFFICULTY
                })
              end)
              break
            end
          end
        end
      end
    end
    
    task.wait(0.5)
  end
end

-- Start scanning
function FindTBModule.start()
  if FindTBModule.state.isRunning then return end
  
  FindTBModule.state.isRunning = true
  FindTBModule.state.ENTERED = false
  
  print("[FindTB] Starting Trait Burner search...")
  
  -- Initial scan
  FindTBModule.scanChallenges()
  
  -- Auto rescan
  FindTBModule.state.scanTask = task.spawn(function()
    for round = 1, FindTBModule.config.MAX_ROUNDS do
      if not FindTBModule.state.isRunning then break end
      if FindTBModule.state.ENTERED then break end
      
      task.wait(FindTBModule.config.RESCAN_EVERY_SEC)
      FindTBModule.scanChallenges()
    end
  end)
end

-- Stop scanning
function FindTBModule.stop()
  FindTBModule.state.isRunning = false
  if FindTBModule.state.scanTask then
    task.cancel(FindTBModule.state.scanTask)
    FindTBModule.state.scanTask = nil
  end
  print("[FindTB] Stopped Trait Burner search")
end

-- Toggle State Variable
local isTBActive = false

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
    
    -- Start FindTB module
    FindTBModule.start()
  else
    -- Animate to OFF
    TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
      Position = UDim2.new(0, 2, 0.5, 0),
      AnchorPoint = Vector2.new(0, 0.5)
    }):Play()
    TweenService:Create(toggleSwitch, TweenInfo.new(0.2), {
      BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    }):Play()
    
    -- Stop FindTB module
    FindTBModule.stop()
  end
end

-- Make toggle clickable
toggleSwitch.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or 
     input.UserInputType == Enum.UserInputType.Touch then
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
macroContainer.Size = UDim2.new(1, 0, 0, 400)
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


-- ===== FILESYSTEM HELPERS (moved up so dropdown can use them) =====
local FS = {}
do
  local g = getgenv and getgenv() or _G or {}
  FS.writefile  = rawget(g, "writefile") or (rawget(g, "syn") and g.syn.writefile) or (rawget(g, "krnl") and g.krnl.writefile)
  FS.appendfile = rawget(g, "appendfile") or (rawget(g, "syn") and g.syn.appendfile)
  FS.isfile     = rawget(g, "isfile")     or (rawget(g, "syn") and g.syn.isfile)
  FS.isfolder   = rawget(g, "isfolder")   or (rawget(g, "syn") and g.syn.isfolder)
  FS.makefolder = rawget(g, "makefolder") or (rawget(g, "syn") and g.syn.makefolder)
  FS.listfiles  = rawget(g, "listfiles")  or (rawget(g, "syn") and g.syn.listfiles) or rawget(g, "getfiles")
end

local function basename(path)
  if not path then return nil end
  local name = path:match("([^/\\]+)$")
  return name
end

local function strip_json(extname)
  return extname and extname:gsub("%.json$", "") or extname
end

local function ensureFolder(path)
  if FS.isfolder and not FS.isfolder(path) then
    pcall(FS.makefolder, path)
  elseif FS.makefolder then
    pcall(FS.makefolder, path)
  end
end

local function sanitizeName(s)
  s = tostring(s or ""):lower()
  s = s:gsub("[^a-z0-9_]", "_")
  s = s:gsub("_+", "_")
  s = s:gsub("^_+", ""):gsub("_+$", "")
  return s
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
  button.BackgroundColor3 = color
  button.Size = UDim2.new(0, 110, 0, 40)
  button.Position = UDim2.new(0, 0, 0, 0)
  button.AutoButtonColor = false
  button.Parent = buttonContainer
  createCorner(button, 10)
  
  -- Button shadow
  local shadow = Instance.new("Frame")
  shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
  shadow.BackgroundTransparency = 0.7
  shadow.Size = UDim2.new(1, 4, 1, 4)
  shadow.Position = UDim2.new(0, 2, 0, 2)
  shadow.ZIndex = button.ZIndex - 1
  shadow.Parent = button
  createCorner(shadow, 10)
  
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
  
  -- Hover effect
  button.MouseEnter:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.2), {
      Size = UDim2.new(0, 114, 0, 43),
      BackgroundTransparency = 0.1
    }):Play()
    TweenService:Create(shadow, TweenInfo.new(0.2), {
      Size = UDim2.new(1, 6, 1, 6),
      Position = UDim2.new(0, 3, 0, 3)
    }):Play()
  end)
  
  button.MouseLeave:Connect(function()
    TweenService:Create(button, TweenInfo.new(0.2), {
      Size = UDim2.new(0, 110, 0, 40),
      BackgroundTransparency = 0
    }):Play()
    TweenService:Create(shadow, TweenInfo.new(0.2), {
      Size = UDim2.new(1, 4, 1, 4),
      Position = UDim2.new(0, 2, 0, 2)
    }):Play()
  end)
  
  return button, iconLabel
end

local recordBtn, recordIcon = createMacroButton("●", "Record", Color3.fromRGB(220, 60, 60))
local playBtn, playIcon   = createMacroButton("▶", "Play",   Color3.fromRGB(60, 180, 75))
local stopBtn, stopIcon   = createMacroButton("■", "Stop",   Color3.fromRGB(100, 100, 120))

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
autoReplayBox.Position = UDim2.new(0, 10, 0, 500) -- just below new macro input
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
    ensureAutoReplayLoop()
  else
    TweenService:Create(arKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5)}):Play()
    TweenService:Create(arSwitch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
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
autoSelectBox.Position = UDim2.new(0, 10, 0, 630) -- placed after Auto replay box
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

-- ===== AUTO SELECT MACRO INFO PANEL =====
-- Info panel explaining macro file naming
local macroInfoPanel = Instance.new("Frame")
macroInfoPanel.Name = "MacroInfoPanel"
macroInfoPanel.BackgroundColor3 = COLORS.background_secondary
macroInfoPanel.Size = UDim2.new(1, -20, 0, 300) -- fixed height to avoid AutomaticSize quirks in ScrollingFrame
macroInfoPanel.Position = UDim2.new(0, 10, 0, 770)
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

local function getMapAndChallenge()
  local mapName, challengeName
  pcall(function()
    -- Try to infer from Workspace
    if workspace:FindFirstChild("Map") then
      mapName = workspace.Map.Name
    end
    -- Use our FindTBModule memory if present
    if FindTBModule and FindTBModule.state and FindTBModule.state.LAST_SELECTED then
      challengeName = tostring(FindTBModule.state.LAST_SELECTED)
    end
    -- Try to read current open stage UI if available
    local main = player.PlayerGui:FindFirstChild("MainUI", true)
    if main then
      local stage = main:FindFirstChild("StageScroll", true)
      if stage and stage.Parent and stage.Parent:FindFirstChild("Title") and stage.Parent.Title:IsA("TextLabel") then
        local t = stage.Parent.Title.Text
        if t and #t > 0 then mapName = t end
      end
    end
  end)
  return (mapName and mapName:lower() or nil), (challengeName and challengeName:lower() or nil)
end

local function chooseMacroForContext()
  local list
  pcall(function()
    if getgenv and getgenv().MacroManager and getgenv().MacroManager.list then
      list = getgenv().MacroManager.list()
    elseif getgenv and getgenv().MacroAPI and getgenv().MacroAPI.list then
      list = getgenv().MacroAPI.list()
    end
  end)
  if type(list) ~= "table" or #list == 0 then return nil end

  local map, chal = getMapAndChallenge()
  local best, bestScore
  for _, name in ipairs(list) do
    local n = tostring(name):lower()
    local score = 0
    if map and n:find(map, 1, true) then score = score + #map end
    if chal and n:find(chal, 1, true) then score = score + #chal end
    if n:find("challenge", 1, true) and chal == nil then score = score + 3 end
    if score > 0 and (not bestScore or score > bestScore) then
      best, bestScore = name, score
    end
  end
  return best
end

local function applySelectedMacro(name)
  if not name then return end
  selectedMacroName = name
  selectBtn.Text = name .. " ▾"
  -- Notify external API of selection if supported
  pcall(function()
    if getgenv and getgenv().MacroAPI and getgenv().MacroAPI.load then
      getgenv().MacroAPI.load(name)
    elseif getgenv and getgenv().MacroManager and getgenv().MacroManager.select then
      getgenv().MacroManager.select(name)
    end
  end)
end

local function ensureAutoSelectLoop()
  if AutoSelect.task ~= nil then return end
  AutoSelect.task = task.spawn(function()
    while AutoSelect.enabled do
      local pick = chooseMacroForContext()
      if pick and pick ~= AutoSelect.lastPick then
        AutoSelect.lastPick = pick
        applySelectedMacro(pick)
        updateStatus("idle", "Auto selected: " .. tostring(pick))
      end
      task.wait(2.0)
    end
    AutoSelect.task = nil
  end)
end

local function toggleAutoSelect()
  AutoSelect.enabled = not AutoSelect.enabled
  if AutoSelect.enabled then
    -- If Auto replay is on, turn it off to avoid conflicts
    if AutoReplay and AutoReplay.enabled then
      toggleAutoReplay()
    end
    TweenService:Create(asKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(1, -24, 0.5, 0)}):Play()
    TweenService:Create(asSwitch, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.accent}):Play()
    -- Immediate pick once enabled
    local initial = chooseMacroForContext()
    if initial then applySelectedMacro(initial) end
    ensureAutoSelectLoop()
  else
    TweenService:Create(asKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 2, 0.5, 0)}):Play()
    TweenService:Create(asSwitch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
  end
end

asSwitch.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    toggleAutoSelect()
  end
end)

-- Prevent enabling Auto replay while Auto select is active
local oldToggleAutoReplay = toggleAutoReplay
toggleAutoReplay = function()
  if AutoSelect and AutoSelect.enabled then
    updateStatus("idle", "Disable Auto select macro first")
    -- Brief flash feedback on the Auto replay switch
    TweenService:Create(arSwitch, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220,80,80)}):Play()
    task.delay(0.2, function()
      TweenService:Create(arSwitch, TweenInfo.new(0.2), {BackgroundColor3 = (AutoReplay.enabled and COLORS.accent) or Color3.fromRGB(20,20,20)}):Play()
    end)
    return
  end
  oldToggleAutoReplay()
end


-- Update status function
local function updateStatus(state, description)
  statusText.Text = state:upper()
  statusDesc.Text = description
  
  if state == "recording" then
    statusIndicator.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    TweenService:Create(statusPulse, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
      Transparency = 0
    }):Play()
  elseif state == "playing" then
    statusIndicator.BackgroundColor3 = Color3.fromRGB(60, 180, 75)
    TweenService:Create(statusPulse, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
      Transparency = 0
    }):Play()
  else
    statusIndicator.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
    TweenService:Create(statusPulse, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
  end
end

local addActionToList  -- forward declaration for action list appender

local function applyRecorderStatus(msg)
  local s = tostring(msg or "")
  local l = s:lower()

  -- Transient saving indicator on end-signal
  if l:find("end_log:arigato4", 1, true) or l:find("recording finished", 1, true) then
    -- Show a brief saving state
    updateStatus("recording", "Stopping… Saving…")
    task.delay(1.2, function()
      updateStatus("idle", "Recording finished - saved to file")
    end)
    return
  end

  if l:find("saved:", 1, true) then
    updateStatus("idle", s)  -- e.g., "Saved: Moon_Macros/…"
    return
  end

  if l:find("recording", 1, true) then
    updateStatus("recording", s)
  elseif l:find("playing", 1, true) then
    updateStatus("playing", s)
  elseif #s > 0 then
    updateStatus("idle", s)
  else
    updateStatus("idle", "Ready to record")
  end
end

-- Bridge: map recorder action messages to UI list
local function applyRecorderAction(msg)
  if type(msg) == "string" and #msg > 0 then
    addActionToList(msg, "log")
    return
  end

  if type(msg) == "table" and msg.kind then
    local txt = msg.kind
    if msg.data and msg.data.unit then
      txt = txt .. " | " .. tostring(msg.data.unit)
      if msg.data.pk then
        txt = txt .. " @" .. msg.data.pk
      end
    end
    addActionToList(txt, tostring(msg.kind))
  end
end



-- Add action to list
local KINDS_COLORS = {
  place = Color3.fromRGB(120, 200, 120),
  upgrade = Color3.fromRGB(120, 160, 230),
  sell = Color3.fromRGB(230, 120, 120),
  wave_set = Color3.fromRGB(180, 140, 230),
  StartVoteYes = Color3.fromRGB(255, 200, 120),
  SkipVoteYes  = Color3.fromRGB(255, 200, 120),
  end_log_detected = Color3.fromRGB(210, 210, 210),
  ["auto_stop"] = Color3.fromRGB(210, 210, 210),
  log = COLORS.text_primary
}

function addActionToList(actionText, kind)
  local actionItem = Instance.new("TextLabel")
  actionItem.Text = "→ " .. tostring(actionText or "")
  actionItem.TextColor3 = KINDS_COLORS[kind] or COLORS.text_primary
  actionItem.BackgroundTransparency = 1
  actionItem.Font = Enum.Font.SourceSans
  actionItem.TextSize = 12
  actionItem.TextXAlignment = Enum.TextXAlignment.Left
  actionItem.Size = UDim2.new(1, -10, 0, 20)
  actionItem.Parent = actionsList

  -- Ajusta el canvas al contenido real
  actionsList.CanvasSize = UDim2.new(0, 0, 0, actionsLayout.AbsoluteContentSize.Y)

  -- Auto-scroll al final para ver siempre la última acción
  task.defer(function()
    local y = math.max(0, actionsList.AbsoluteCanvasSize.Y - actionsList.AbsoluteSize.Y)
    actionsList.CanvasPosition = Vector2.new(0, y)
  end)
end

-- Register MacroAPI status callback (after functions are defined)
pcall(function()
  if getgenv and getgenv().MacroAPI and getgenv().MacroAPI.onStatus then
    getgenv().MacroAPI.onStatus(function(msg)
      applyRecorderStatus(msg)
    end)
    -- Initialize with current status, if provided
    if type(getgenv().MacroAPI.status) == "function" then
      local st = getgenv().MacroAPI.status()
      if type(st) == "table" and st.statusMsg then
        applyRecorderStatus(st.statusMsg)
      end
    end
  end
end)

-- Register MacroAPI action callback (after functions are defined)
pcall(function()
  if getgenv and getgenv().MacroAPI and getgenv().MacroAPI.onAction then
    getgenv().MacroAPI.onAction(function(msg)
      applyRecorderAction(msg)
    end)
  end
end)

local function countRecordedRows()
  local n = 0
  for _, child in ipairs(actionsList:GetChildren()) do
    if child:IsA("TextLabel") then n = n + 1 end
  end
  return n
end

recordBtn.MouseButton1Click:Connect(function()
  -- Clear previous recordings in the UI list
  for _, child in ipairs(actionsList:GetChildren()) do
    if child:IsA("TextLabel") then child:Destroy() end
  end
  recordedActions = {}

  -- Prefer the external recorder API if available
  local usedAPI = false
  pcall(function()
    if getgenv and getgenv().MacroAPI and getgenv().MacroAPI.start then
      getgenv().MacroAPI.start()
      usedAPI = true
    end
  end)

  if not usedAPI then
    -- Fallback: just switch UI state (no simulated actions)
    if not isRecording and not isPlaying then
      isRecording = true
      updateStatus("recording", "Recording your actions...")
    end
  end
end)

stopBtn.MouseButton1Click:Connect(function()
  local usedAPI = false
  pcall(function()
    if getgenv and getgenv().MacroAPI and getgenv().MacroAPI.stop then
      getgenv().MacroAPI.stop()
      usedAPI = true
    end
  end)

  if not usedAPI then
    if isRecording then
      isRecording = false
      updateStatus("idle", "Recording stopped - " .. tostring(countRecordedRows()) .. " actions")
    elseif isPlaying then
      isPlaying = false
      updateStatus("idle", "Playback stopped")
    end
  end
end)

playBtn.MouseButton1Click:Connect(function()
  if isRecording or isPlaying then return end

  -- Intentar cargar y reproducir usando MacroAPI/MacroManager si existen
  local usedAPI = false
  pcall(function()
    if getgenv and getgenv().MacroAPI then
      -- Cargar el archivo seleccionado si la API lo soporta
      if selectedMacroName and getgenv().MacroAPI.load then
        getgenv().MacroAPI.load(selectedMacroName)
      elseif selectedMacroName and getgenv().MacroManager and getgenv().MacroManager.select then
        getgenv().MacroManager.select(selectedMacroName)
      end
      if getgenv().MacroAPI.play then
        getgenv().MacroAPI.play()
        usedAPI = true
      elseif getgenv().MacroAPI.start then
        -- Algunas implementaciones usan start() para iniciar playback
        getgenv().MacroAPI.start()
        usedAPI = true
      end
    end
  end)

  if usedAPI then
    isPlaying = true
    updateStatus("playing", selectedMacroName and ("Playing: " .. tostring(selectedMacroName)) or "Playing recorded actions...")
    return
  end

  -- Fallback: simulación como antes
  if #actionsList:GetChildren() > 0 then
    isPlaying = true
    updateStatus("playing", "Playing recorded actions...")
    task.spawn(function()
      wait(3)
      isPlaying = false
      updateStatus("idle", "Playback complete")
    end)
  end
end)

-- ===== FUNCIONES DE NAVEGACIÓN =====
local function switchTab(tabName)
  if currentTab == tabName then return end
  
  -- Animar tab anterior
  local oldTab = tabs[currentTab]
  if oldTab then
    TweenService:Create(oldTab.button, TweenInfo.new(0.3), {BackgroundColor3 = COLORS.tab_inactive}):Play()
    TweenService:Create(oldTab.icon, TweenInfo.new(0.3), {TextColor3 = COLORS.text_dim}):Play()
    TweenService:Create(oldTab.label, TweenInfo.new(0.3), {TextColor3 = COLORS.text_primary}):Play()
    oldTab.indicator.Visible = false
  end
  
  -- Animar nueva tab
  local newTab = tabs[tabName]
  if newTab then
    TweenService:Create(newTab.button, TweenInfo.new(0.3), {BackgroundColor3 = COLORS.tab_active}):Play()
    TweenService:Create(newTab.icon, TweenInfo.new(0.3), {TextColor3 = COLORS.text_secondary}):Play()
    TweenService:Create(newTab.label, TweenInfo.new(0.3), {TextColor3 = COLORS.text_secondary}):Play()
    newTab.indicator.Visible = true
  end
  
  -- Cambiar páginas
  if pages[currentTab] then
    pages[currentTab].Visible = false
  end
  if pages[tabName] then
    pages[tabName].Visible = true
  end
  
  -- Reset macro scroll position when opening the Macro System so it doesn't appear mid-way
  if tabName == "Macro System" and macroContainer and macroContainer.CanvasPosition then
    macroContainer.CanvasPosition = Vector2.new(0, 0)
  end
  
  currentTab = tabName
end

-- Conectar eventos de tabs
featuresTab.MouseButton1Click:Connect(function() switchTab("Features") end)
macroTab.MouseButton1Click:Connect(function() switchTab("Macro System") end)

-- Hover effects para tabs
for name, tab in pairs(tabs) do
  tab.button.MouseEnter:Connect(function()
    if currentTab ~= name then
      TweenService:Create(tab.button, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.button_hover}):Play()
    end
  end)
  
  tab.button.MouseLeave:Connect(function()
    if currentTab ~= name then
      TweenService:Create(tab.button, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.tab_inactive}):Play()
    end
  end)
end

-- ===== FUNCIONALIDAD DE ARRASTRE =====
local function makeDraggable(frame, handle)
  local dragStart, startPos = nil, nil
  
  handle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
      isDragging = true
      dragStart = input.Position
      startPos = frame.Position
    end
  end)
  
  UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
      isDragging = false
    end
  end)
  
  UIS.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                       input.UserInputType == Enum.UserInputType.Touch) then
      local delta = input.Position - dragStart
      frame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
      )
    end
  end)
end

makeDraggable(mainFrame, topBar)

local function toNumberSafe(v)
  if v == nil then return nil end
  if type(v) == "number" then return v end
  if type(v) == "string" then
    local digits = v:gsub("%D", "")
    return tonumber(digits)
  end
  return nil
end

-- ===== ACTUALIZACIÓN DE VALORES =====
local function updateValues(gems, gold, tb)
  local g = toNumberSafe(gems)
  local c = toNumberSafe(gold)
  local t = toNumberSafe(tb)

  if g ~= nil then
    if lastGems and g ~= lastGems then
      flashLabel(gemsValue, g > lastGems)
    end
    gemsValue.Text = formatNumber(g)
    lastGems = g
  end

  if c ~= nil then
    if lastCash and c ~= lastCash then
      flashLabel(goldValue, c > lastCash)
    end
    goldValue.Text = formatNumber(c)
    lastCash = c
  end

  if t ~= nil then
    if lastTB and t ~= lastTB then
      flashLabel(tbValue, t > lastTB)
    end
    tbValue.Text = formatNumber(t)
    lastTB = t
  end
end

-- ===== LECTURA DE VALORES DEL JUEGO =====
local function extractNumber(text)
  if type(text) == "number" then return text end
  if type(text) == "string" then
    local digits = text:gsub("%D", "")
    return tonumber(digits)
  end
  return nil
end

-- Buscar y conectar al RemoteEvent
task.spawn(function()
  local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
  if not remotes then return end
  
  local updateEvent = remotes:WaitForChild("UpdateEvent", 5)
  if updateEvent and updateEvent:IsA("RemoteEvent") then
    updateEvent.OnClientEvent:Connect(function(data)
      if type(data) == "table" then
        updateValues(toNumberSafe(data.Premium) or toNumberSafe(data.Gems), toNumberSafe(data.Cash), nil)
        
        local tb = data["Trait Burner"] or data.TraitBurner or data.TB
        if tb then
          updateValues(nil, nil, extractNumber(tb))
        end
      end
    end)
  end
end)

-- Leer del HUD existente
task.spawn(function()
  wait(1)
  local mainUI = player.PlayerGui:FindFirstChild("MainUI", true)
  if not mainUI then return end
  
  local function findPath(...)
    local current = mainUI
    for _, name in ipairs({...}) do
      current = current:FindFirstChild(name)
      if not current then return nil end
    end
    return current
  end
  
  local premiumLabel = findPath("MenuFrame", "BottomFrame", "BottomExpand", "CashFrame", "Premium", "ExpandFrame", "TextLabel")
  local cashLabel = findPath("MenuFrame", "BottomFrame", "BottomExpand", "CashFrame", "Cash", "ExpandFrame", "TextLabel")
  
  if premiumLabel then
    local function updateGems()
      updateValues(extractNumber(premiumLabel.Text), nil, nil)
    end
    updateGems()
    premiumLabel:GetPropertyChangedSignal("Text"):Connect(updateGems)
  end
  
  if cashLabel then
    local function updateGold()
      updateValues(nil, extractNumber(cashLabel.Text), nil)
    end
    updateGold()
    cashLabel:GetPropertyChangedSignal("Text"):Connect(updateGold)
  end
end)


-- ===== BOTÓN CERRAR =====
closeButton.MouseButton1Click:Connect(function()
  gui:Destroy()
end)