-- UI con Sistema de Navegación Elegante
-- Interfaz visual mejorada con pestañas y diseño moderno

-- Servicios
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VIM = game:GetService("VirtualInputManager")

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

-- === FindTB external module loader (no UI changes) ===
local FIND_TB_URL = "https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/findtb.lua"
_G.FindTBActive = _G.FindTBActive or false
_G.FindTB       = _G.FindTB       or nil -- will hold returned API {stop,status}

local function startFindTB()
  if _G.FindTBActive then return true end
  _G.FindTBActive = true
  local ok, mod = pcall(function()
    return loadstring(game:HttpGet(FIND_TB_URL))()
  end)
  if ok and type(mod) == "table" then
    _G.FindTB = mod
    return true
  else
    warn("[FindTB] Failed to load module:", mod)
    _G.FindTBActive = false
    return false
  end
end

local function stopFindTB()
  _G.FindTBActive = false
  if _G.FindTB and type(_G.FindTB.stop) == "function" then
    pcall(_G.FindTB.stop)
  end
end

local function getFindTBStatus()
  if _G.FindTB and type(_G.FindTB.status) == "function" then
    local ok, s = pcall(_G.FindTB.status)
    if ok then return s end
  end
  return { active = _G.FindTBActive, entered = false, lastSelected = "Challenge1" }
end

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
mainFrame.Size = UDim2.new(0, 600, 0, 450)
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
    
    -- Start FindTB external module
    local ok = startFindTB()
    if not ok then
      -- revert toggle UI if loading failed
      isTBActive = false
      TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0, 2, 0.5, 0)
      }):Play()
      TweenService:Create(toggleSwitch, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(20, 20, 20)
      }):Play()
      return
    end
  else
    -- Animate to OFF
    TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
      Position = UDim2.new(0, 2, 0.5, 0),
      AnchorPoint = Vector2.new(0, 0.5)
    }):Play()
    TweenService:Create(toggleSwitch, TweenInfo.new(0.2), {
      BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    }):Play()
    
    -- Stop FindTB external module
    stopFindTB()
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
macroDesc.Text = "Configure automated actions and macros.\nCustomize your gameplay experience with powerful automation tools."
macroDesc.TextColor3 = COLORS.text_dim
macroDesc.BackgroundTransparency = 1
macroDesc.Font = Enum.Font.SourceSans
macroDesc.TextSize = 14
macroDesc.Size = UDim2.new(1, 0, 0, 40)
macroDesc.Position = UDim2.new(0, 0, 0, 50)
macroDesc.TextXAlignment = Enum.TextXAlignment.Left
macroDesc.TextYAlignment = Enum.TextYAlignment.Top
macroDesc.TextWrapped = true
macroDesc.Parent = macroPage

-- ===== MACRO SYSTEM UI =====
-- Container
local macroUI = Instance.new("Frame")
macroUI.Name = "MacroUI"
macroUI.BackgroundColor3 = COLORS.background_tertiary
macroUI.Size = UDim2.new(1, 0, 0, 210)
macroUI.Position = UDim2.new(0, 0, 0, 100)
macroUI.Parent = macroPage
createCorner(macroUI, 10)
createStroke(macroUI, COLORS.border, 1, 0.8)

-- Top row: buttons
local btnRow = Instance.new("Frame")
btnRow.BackgroundTransparency = 1
btnRow.Size = UDim2.new(1, -20, 0, 36)
btnRow.Position = UDim2.new(0, 10, 0, 10)
btnRow.Parent = macroUI

local function makeButton(text, xOff)
  local b = Instance.new("TextButton")
  b.Text = text
  b.Font = Enum.Font.SourceSansSemibold
  b.TextSize = 14
  b.TextColor3 = COLORS.text_secondary
  b.BackgroundColor3 = COLORS.tab_inactive
  b.Size = UDim2.new(0, 110, 1, 0)
  b.Position = UDim2.new(0, xOff, 0, 0)
  b.AutoButtonColor = false
  b.Parent = btnRow
  createCorner(b, 8)
  createStroke(b, COLORS.border, 1, 0.7)
  b.MouseEnter:Connect(function()
    TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.button_hover}):Play()
  end)
  b.MouseLeave:Connect(function()
    TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.tab_inactive}):Play()
  end)
  return b
end

local recordBtn = makeButton("● Record", 0)
local stopBtn   = makeButton("■ Stop", 120)
local playBtn   = makeButton("▶ Play", 240)

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 14
statusLabel.TextColor3 = COLORS.text_dim
statusLabel.Text = "Status: idle"
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 50)
statusLabel.Parent = macroUI

-- List header
local listHeader = Instance.new("TextLabel")
listHeader.BackgroundTransparency = 1
listHeader.TextXAlignment = Enum.TextXAlignment.Left
listHeader.Font = Enum.Font.SourceSansBold
listHeader.TextSize = 14
listHeader.TextColor3 = COLORS.text_primary
listHeader.Text = "Recorded steps"
listHeader.Size = UDim2.new(1, -20, 0, 18)
listHeader.Position = UDim2.new(0, 10, 0, 75)
listHeader.Parent = macroUI

-- Scroll list
local stepsList = Instance.new("ScrollingFrame")
stepsList.BackgroundTransparency = 1
stepsList.BorderSizePixel = 0
stepsList.ScrollBarImageTransparency = 0.2
stepsList.ScrollBarThickness = 4
stepsList.Size = UDim2.new(1, -20, 0, 100)
stepsList.Position = UDim2.new(0, 10, 0, 95)
stepsList.CanvasSize = UDim2.new(0,0,0,0)
stepsList.Parent = macroUI

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = stepsList

-- ===== MACRO RECORDER WIRING (external module only) =====

local MACRO_URL = "https://raw.githubusercontent.com/MoonSaxkter/MOONHUB/main/modules/recordmacro.lua"

-- Preload recorder once (executor context) so UI button doesn't need loadstring later
pcall(function()
  if getgenv then
    if type(getgenv().MoonWave_boot) ~= "function" then
      local src = nil
      -- try executor HTTP first, then game:HttpGet
      pcall(function()
        if syn and syn.request then
          local r = syn.request({Url=MACRO_URL, Method="GET"}); src = r and r.Body
        elseif http and http.request then
          local r = http.request({Url=MACRO_URL, Method="GET"}); src = r and (r.Body or r.body)
        end
      end)
      if not src then
        local okHttp, body = pcall(function() return game:HttpGet(MACRO_URL) end)
        if okHttp then src = body end
      end
      if type(src) == "string" and #src > 0 then
        local ld = (getgenv() and getgenv().loadstring) or loadstring or load
        if type(ld) == "function" then
          local chunk = ld(src)
          if type(chunk) == "function" then
            getgenv().MoonWave_boot = chunk
          end
        end
      end
    end
  end
end)

local function macroStatus(msg)
  statusLabel.Text = "Status: " .. tostring(msg)
end

local function clearList()
  for _,child in ipairs(stepsList:GetChildren()) do
    if child:IsA("TextLabel") then child:Destroy() end
  end
  stepsList.CanvasSize = UDim2.new(0,0,0,0)
end

local function startMacroRecorder()
  local already = false
  pcall(function()
    if getgenv and (getgenv().MoonWave_v07t or getgenv().MoonWave_v07sUPG or getgenv().MoonWave_v06cUPG) then
      already = true
    end
  end)
  if not already then
    local function http_get(url)
      local body
      pcall(function()
        if syn and syn.request then
          local r = syn.request({Url=url, Method="GET"}); body = r and r.Body
        elseif http and http.request then
          local r = http.request({Url=url, Method="GET"}); body = r and (r.Body or r.body)
        end
      end)
      if not body then
        local ok2, res = pcall(function() return game:HttpGet(url) end)
        if ok2 then body = res end
      end
      return body
    end

    local function to_func(ret1, ret2)
      if type(ret1) == "function" then return ret1 end
      if type(ret1) == "table" and type(ret1.func) == "function" then return ret1.func end
      if type(ret2) == "function" then return ret2 end
      return nil
    end

    local function try_compile(src)
      -- Try executor-specific loaders first
      local f
      pcall(function()
        if syn and type(syn.loadstring)=="function" then f = syn.loadstring(src) end
      end)
      f = to_func(f)
      if f then return f end

      pcall(function()
        if fluxus and type(fluxus.loadstring)=="function" then f = fluxus.loadstring(src) end
      end)
      f = to_func(f)
      if f then return f end

      pcall(function()
        if KRNL_LOADED and type(loadstring)=="function" then f = loadstring(src) end
      end)
      f = to_func(f)
      if f then return f end

      pcall(function()
        if getgenv and type(getgenv().loadstring)=="function" then f = getgenv().loadstring(src) end
      end)
      f = to_func(f)
      if f then return f end

      if type(loadstring) == "function" then
        local f1, e1 = loadstring(src)
        f = to_func(f1, e1); if f then return f end
      end

      -- Luau load variants
      if type(load) == "function" then
        local env = (getfenv and getfenv()) or _G
        local f2, e2 = load(src, "@recorder", "t", env)
        f = to_func(f2, e2); if f then return f end
        local f3, e3 = load(src)
        f = to_func(f3, e3); if f then return f end
      end

      return nil
    end

    local ok, err = pcall(function()
      local src = http_get(MACRO_URL)
      assert(type(src)=="string" and #src>0, "empty http body")
      local chunk = try_compile(src)
      if type(chunk) ~= "function" then
        local head = tostring(src):sub(1,120):gsub("\n"," ")
        warn("[MacroUI] Preview(120): ", head)
        error("no loader available (executor restricts loadstring)")
      end
      return chunk()
    end)
    if not ok then
      warn("[MacroUI] Failed to load recorder:", err)
      macroStatus("error loading")
      return
    end
  end

  -- Hook UI status callback so the recorder can update our label (finished, manual stop, etc.)
  pcall(function()
    if getgenv and getgenv().MoonWave_API and type(getgenv().MoonWave_API.onStatus) == "function" then
      getgenv().MoonWave_API.onStatus(function(msg)
        macroStatus(msg)
      end)
      local last = (getgenv() and getgenv().MoonWave_Status) or nil
      macroStatus(last or "Recording...")
    else
      macroStatus("Recording adelante")
    end
  end)
end

local function stopMacroRecorder()
  pcall(function()
    if getgenv and getgenv().MoonWave_API and type(getgenv().MoonWave_API.stop) == "function" then
      getgenv().MoonWave_API.stop()
    end
  end)
  -- status will be updated by the recorder via onStatus callback
end

-- Hook buttons ONLY to external recorder
recordBtn.MouseButton1Click:Connect(function()
  startMacroRecorder()
end)

stopBtn.MouseButton1Click:Connect(function()
  stopMacroRecorder()
end)

playBtn.MouseButton1Click:Connect(function()
  macroStatus("play (coming soon)")
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

-- ===== ACTUALIZACIÓN DE VALORES =====
local function updateValues(gems, gold, tb)
  if gems ~= nil then
    if lastGems and gems ~= lastGems then
      flashLabel(gemsValue, gems > lastGems)
    end
    gemsValue.Text = formatNumber(gems)
    lastGems = gems
  end
  
  if gold ~= nil then
    if lastCash and gold ~= lastCash then
      flashLabel(goldValue, gold > lastCash)
    end
    goldValue.Text = formatNumber(gold)
    lastCash = gold
  end
  
  if tb ~= nil then
    if lastTB and tb ~= lastTB then
      flashLabel(tbValue, tb > lastTB)
    end
    tbValue.Text = formatNumber(tb)
    lastTB = tb
  end
end

-- ===== LECTURA DE VALORES DEL JUEGO =====
local function extractNumber(text)
  if type(text) == "number" then return text end
  if type(text) == "string" then
    local digits = text:gsub("%D", "")
    return tonumber(digits)
  end
  if type(text) == "table" then
    -- Try common fields; if none, return nil to avoid writing 'table: 0x..' to labels
    local candidates = {text.Value, text.amount, text.Amount, text.val}
    for _,v in ipairs(candidates) do
      local n = (type(v) == "number") and v
              or (type(v) == "string" and tonumber((v:gsub("%D",""))))
      if n then return n end
    end
    return nil
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
        updateValues(extractNumber(data.Premium), extractNumber(data.Cash), nil)
        
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

-- Escaneo periódico para Trait Burners
task.spawn(function()
  while wait(2) do
    for _, label in ipairs(player.PlayerGui:GetDescendants()) do
      if label:IsA("TextLabel") and label.Visible then
        local text = tostring(label.Text or ""):lower()
        if text:match("trait%s*burner") then
          local parent = label.Parent
          if parent then
            for _, sibling in ipairs(parent:GetDescendants()) do
              if sibling:IsA("TextLabel") and sibling ~= label then
                local value = extractNumber(sibling.Text)
                if value and value > 0 then
                  updateValues(nil, nil, value)
                  break
                end
              end
            end
          end
        end
      end
    end
  end
end)

-- ===== BOTÓN CERRAR =====
closeButton.MouseButton1Click:Connect(function()
  -- ensure macro system stops cleanly (external recorder)
  pcall(function()
    if getgenv and getgenv().MoonWave_API and type(getgenv().MoonWave_API.stop) == "function" then
      getgenv().MoonWave_API.stop()
    end
  end)
  gui:Destroy()
end)