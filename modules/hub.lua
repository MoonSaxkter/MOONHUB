-- hub.lua - Módulo completo de UI para MoonHub
-- Compatible con main.lua loader

local Hub = {}

-- Servicios necesarios
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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

-- ===== FUNCIÓN BUILD PRINCIPAL =====
function Hub.build(player, Config)
  -- Variables de estado locales
  local lastGems, lastCash, lastTB = nil, nil, nil
  local isDragging = false
  local currentTab = "Features"

  -- === Config helpers (persist in-memory or via provided Config.save) ===
  Config = typeof(Config) == "table" and Config or {}
  Config.data = typeof(Config.data) == "table" and Config.data or {toggles={}, filters={}}
  Config.data.toggles = Config.data.toggles or { findTB=false, autoReplay=false, autoSelect=false }
  Config.data.filters = Config.data.filters or {}
  local function saveConfig()
    if Config and typeof(Config.save) == "function" then
      pcall(function() Config.save(Config.data) end)
    end
  end

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
  mainFrame.Visible = true

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

  -- Contenedor Principal
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
  toggleSwitch.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
  toggleSwitch.Size = UDim2.new(0, 50, 0, 26)
  toggleSwitch.Position = UDim2.new(1, -50, 0.5, 0)
  toggleSwitch.AnchorPoint = Vector2.new(1, 0.5)
  toggleSwitch.Parent = toggleContainer
  createCorner(toggleSwitch, 13)

  -- Toggle Knob
  local toggleKnob = Instance.new("Frame")
  toggleKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
  toggleKnob.Size = UDim2.new(0, 22, 0, 22)
  toggleKnob.Position = UDim2.new(0, 2, 0.5, 0)
  toggleKnob.AnchorPoint = Vector2.new(0, 0.5)
  toggleKnob.Parent = toggleSwitch
  createCorner(toggleKnob, 11)

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

  -- Challenge options
  local CHALLENGE_OPTS = {
    { label = "Flying Enemies",     key = "flying_enemies" },
    { label = "Juggernaut Enemies", key = "juggernaut_enemies" },
    { label = "Single Placement",    key = "single_placement" },
    { label = "High Cost",           key = "high_cost" },
    { label = "Unsellable",          key = "unsellable" },
  }

  -- Persist UI selection in memory
  local FilterSelections = {}

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
    filterList.Size = UDim2.new(1, 0, 0, avail)
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

    -- Selección interna del UI para este mapa
    FilterSelections[map.label] = FilterSelections[map.label] or {}

    -- Build one option row
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
        -- Persist selection to Config.data.filters[map.label]
        local list = {}
        for lbl, on in pairs(FilterSelections[map.label]) do
          if on then table.insert(list, lbl) end
        end
        Config.data.filters[map.label] = list
        saveConfig()
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

    -- Construir todas las opciones
    for _,opt in ipairs(CHALLENGE_OPTS) do
      addOption(opt)
    end

    -- Botón abre/cierra
    btn.MouseButton1Click:Connect(function()
      if popup.Visible then closePopup() else openPopup() end
    end)

    -- Texto inicial del botón
    btn.Text = summarizeSelection(FilterSelections[map.label]) .. " ▾"
  end

  for _,m in ipairs(MAPS) do
    createMapFilter(m)
  end

  -- Close dropdown when clicking outside any open filter row
  UIS.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not openFilterRow then return end
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

  -- Helpers para el toggle de FindTB
  local function setTBVisual(on, tween)
    if on then
      TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, -24, 0.5, 0), AnchorPoint = Vector2.new(0,0.5)
      }):Play()
      TweenService:Create(toggleSwitch, TweenInfo.new(0.2), { BackgroundColor3 = COLORS.accent }):Play()
    else
      TweenService:Create(toggleKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0,0.5)
      }):Play()
      TweenService:Create(toggleSwitch, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(20,20,20) }):Play()
    end
  end

  local function toggleTB()
    isTBActive = not isTBActive
    setTBVisual(isTBActive, true)

    -- Persist toggle
    Config.data.toggles.findTB = isTBActive
    saveConfig()

    -- Notify external finder (kept outside hub to stay ordered)
    local ok = pcall(function()
      if getgenv and getgenv().FindTB and typeof(getgenv().FindTB) == "table" then
        if isTBActive and typeof(getgenv().FindTB.start) == "function" then getgenv().FindTB.start() end
        if (not isTBActive) and typeof(getgenv().FindTB.stop) == "function" then getgenv().FindTB.stop() end
      else
        _G.FindTBActive = isTBActive
      end
    end)
    if not ok then _G.FindTBActive = isTBActive end
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
  macroContainer.Size = UDim2.new(1, 0, 1, -90)
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

  -- Helper functions for filesystem operations (placeholder)
  local function sanitizeName(s)
    s = tostring(s or ""):lower()
    s = s:gsub("[^a-z0-9_]", "_")
    s = s:gsub("_+", "_")
    s = s:gsub("^_+", ""):gsub("_+$", "")
    return s
  end

  local function basename(path)
    if not path then return nil end
    local name = path:match("([^/\\]+)$")
    return name
  end

  local function strip_json(extname)
    return extname and extname:gsub("%.json$", "") or extname
  end

  local function shakeFrame(f)
    if not f or not f.Parent then return end
    local p0 = f.Position
    local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(f, tweenInfo, {Position = p0 + UDim2.new(0, 6, 0, 0)}):Play()
    task.delay(0.05, function()
      TweenService:Create(f, tweenInfo, {Position = p0 + UDim2.new(0, -6, 0, 0)}):Play()
    end)
    task.delay(0.10, function()
      TweenService:Create(f, tweenInfo, {Position = p0}):Play()
    end)
  end

  -- Forward declarations
  local updateStatus
  local selectedMacroName = nil
  local isRecording = false
  local isPlaying = false
  local AutoReplay = { enabled = false, task = nil }
  local AutoSelect = { enabled = false, task = nil, lastPick = nil }

  local function ensureAutoReplayLoop() end
  local function ensureAutoSelectLoop() end  
  local function chooseMacroForContext() return nil end
  local function applySelectedMacro(name) end
  local function saveConfig() end

  local function refreshMacroStatusMessage()
    if updateStatus then
      if AutoReplay and AutoReplay.enabled then
        updateStatus("idle", "Auto replay enabled")
      elseif AutoSelect and AutoSelect.enabled then
        updateStatus("idle", "Auto select macro enabled")
      else
        updateStatus("idle", "Ready to record")
      end
    end
  end

  -- Update status function
  updateStatus = function(state, description)
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

  -- Macro picker dropdown
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

  -- Visual feedback when a macro is selected
  local function flashMacroChosenFeedback()
    local originalBg = selectBtn.BackgroundColor3
    local originalStroke = selectBtnStroke.Color

    local grow = TweenService:Create(selectBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
      Size = UDim2.new(1, -16, 0, 31)
    })
    local shrink = TweenService:Create(selectBtn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
      Size = UDim2.new(1, -20, 0, 28)
    })

    TweenService:Create(selectBtn, TweenInfo.new(0.15), { BackgroundColor3 = COLORS.accent }):Play()
    TweenService:Create(selectBtnStroke, TweenInfo.new(0.15), { Color = COLORS.accent }):Play()
    grow:Play()

    task.delay(0.18, function()
      TweenService:Create(selectBtn, TweenInfo.new(0.20), { BackgroundColor3 = originalBg }):Play()
      TweenService:Create(selectBtnStroke, TweenInfo.new(0.20), { Color = originalStroke }):Play()
      shrink:Play()
    end)
  end

  -- Dropdown list (simplified for placeholder)
  selectBtn.MouseButton1Click:Connect(function()
    print("Macro selector clicked")
    flashMacroChosenFeedback()
  end)

  -- Button container
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

    -- Hover / press effects
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

  -- Create new macro input
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

  nameInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
      print("Create macro:", nameInput.Text)
      updateStatus("idle", "Macro creation placeholder")
    end
  end)

  -- File action buttons
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

    return b
  end

  local wipeBtn = smallActionButton("Wipe macro", COLORS.accent)
  local deleteBtn = smallActionButton("Delete macro", Color3.fromRGB(220, 90, 90))

  -- Auto replay toggle
  local autoReplayBox = Instance.new("Frame")
  autoReplayBox.Name = "AutoReplayBox"
  autoReplayBox.BackgroundColor3 = COLORS.background_secondary
  autoReplayBox.Size = UDim2.new(1, -20, 0, 110)
  autoReplayBox.Position = UDim2.new(0, 10, 0, 560)
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

  local function toggleAutoReplay()
    local wantEnable = not AutoReplay.enabled
    if wantEnable and AutoSelect and AutoSelect.enabled then
      updateStatus("idle", "Disable Auto select macro first")
      shakeFrame(arSwitch)
      return
    end

    AutoReplay.enabled = wantEnable

    Config.data.toggles.autoReplay = AutoReplay.enabled
    saveConfig()

    if AutoReplay.enabled then
      TweenService:Create(arKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Position = UDim2.new(1, -24, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5)
      }):Play()
      TweenService:Create(arSwitch, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.accent}):Play()
    else
      TweenService:Create(arKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0, 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5)
      }):Play()
      TweenService:Create(arSwitch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20,20,20)}):Play()
    end

    refreshMacroStatusMessage()
    print("Auto replay toggled:", AutoReplay.enabled)
  end

  arSwitch.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
      toggleAutoReplay()
    end
  end)

  -- Auto select macro toggle
  local autoSelectBox = Instance.new("Frame")
  autoSelectBox.Name = "AutoSelectBox"
  autoSelectBox.BackgroundColor3 = COLORS.background_secondary
  autoSelectBox.Size = UDim2.new(1, -20, 0, 130)
  autoSelectBox.Position = UDim2.new(0, 10, 0, 680)
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
asSwitch.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
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

local function toggleAutoSelect()
  local wantEnable = not AutoSelect.enabled
  if wantEnable and AutoReplay and AutoReplay.enabled then
    updateStatus("idle", "Disable Auto replay first")
    shakeFrame(asSwitch)
    return
  end

  AutoSelect.enabled = wantEnable
  Config.data.toggles.autoSelect = AutoSelect.enabled
  saveConfig()

  if AutoSelect.enabled then
    TweenService:Create(asKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
      Position = UDim2.new(1, -24, 0.5, 0),
      AnchorPoint = Vector2.new(0, 0.5)
    }):Play()
    TweenService:Create(asSwitch, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.accent}):Play()
  else
    TweenService:Create(asKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
      Position = UDim2.new(0, 2, 0.5, 0),
      AnchorPoint = Vector2.new(0, 0.5)
    }):Play()
    TweenService:Create(asSwitch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20,20,20)}):Play()
  end

  refreshMacroStatusMessage()
  print("Auto select toggled:", AutoSelect.enabled)
end

asSwitch.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    toggleAutoSelect()
  end
end)

  -- Info panel: Macro naming rules
  local macroInfoPanel = Instance.new("Frame")
  macroInfoPanel.Name = "MacroInfoPanel"
  macroInfoPanel.BackgroundColor3 = COLORS.background_secondary
  macroInfoPanel.Size = UDim2.new(1, -20, 0, 300)
  macroInfoPanel.Position = UDim2.new(0, 10, 0, 820)
  macroInfoPanel.Parent = macroContainer
  createCorner(macroInfoPanel, 10)
  createStroke(macroInfoPanel, COLORS.border, 1, 0.8)

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

  -- Update canvas size for macro container
  local function recomputeCanvas()
    local maxY = 0
    for _, c in ipairs(macroContainer:GetChildren()) do
      if c:IsA("GuiObject") and c.Visible then
        local bottom = c.Position.Y.Offset + c.Size.Y.Offset
        if bottom > maxY then maxY = bottom end
      end
    end
    macroContainer.CanvasSize = UDim2.new(0, 0, 0, maxY + 40)
  end

  recomputeCanvas()
  -- === Restore persisted toggle states ===
  task.spawn(function()
    local tg = Config.data.toggles or {}

    -- FindTB
    if tg.findTB then
      isTBActive = true
      setTBVisual(true, false)
      -- signal external if present
      pcall(function()
        if getgenv and getgenv().FindTB and typeof(getgenv().FindTB.start)=="function" then getgenv().FindTB.start() end
      end)
    else
      setTBVisual(false, false)
    end

    -- Auto Replay
    if tg.autoReplay then
      AutoReplay.enabled = true
      arKnob.Position = UDim2.new(1, -24, 0.5, 0)
      arSwitch.BackgroundColor3 = COLORS.accent
    else
      AutoReplay.enabled = false
      arKnob.Position = UDim2.new(0, 2, 0.5, 0)
      arSwitch.BackgroundColor3 = Color3.fromRGB(20,20,20)
    end

    -- Auto Select
    if tg.autoSelect then
      AutoSelect.enabled = true
      asKnob.Position = UDim2.new(1, -24, 0.5, 0)
      asSwitch.BackgroundColor3 = COLORS.accent
    else
      AutoSelect.enabled = false
      asKnob.Position = UDim2.new(0, 2, 0.5, 0)
      asSwitch.BackgroundColor3 = Color3.fromRGB(20,20,20)
    end

    -- If both are somehow on, prefer Auto Select
    if AutoReplay.enabled and AutoSelect.enabled then
      AutoReplay.enabled = false
      Config.data.toggles.autoReplay = false
      arKnob.Position = UDim2.new(0, 2, 0.5, 0)
      arSwitch.BackgroundColor3 = Color3.fromRGB(20,20,20)
      saveConfig()
    end

    -- Normalize status text based on final state
    if AutoReplay.enabled then
      updateStatus("idle", "Auto replay enabled")
    elseif AutoSelect.enabled then
      updateStatus("idle", "Auto select macro enabled")
    else
      updateStatus("idle", "Ready to record")
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
    
    -- Reset macro scroll position when opening the Macro System
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

  -- ===== ACTUALIZACIÓN DE VALORES =====
  local function toNumberSafe(v)
    if v == nil then return nil end
    if type(v) == "number" then return v end
    if type(v) == "string" then
      local digits = v:gsub("%D", "")
      return tonumber(digits)
    end
    return nil
  end

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
    task.wait(1)
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

  -- Retornar la UI construida
  return {
    root = gui,
    mainFrame = mainFrame,
    pages = pages,
    
    -- API para expandir funcionalidad
    addFeature = function(featureUI)
      if featureUI and featuresPage then
        featureUI.Parent = featuresPage
      end
    end,
    
    addMacroComponent = function(macroUI)
      if macroUI and macroPage then
        macroUI.Parent = macroPage
      end
    end,
    
    -- Referencias útiles para conectar lógica externa
    toggles = {
      findTB = {
        active = function() return isTBActive end,
        set = function(state)
          isTBActive = state and true or false
          setTBVisual(isTBActive)
          Config.data.toggles.findTB = isTBActive
          saveConfig()
        end
      },
      autoReplay = {
        active = function() return AutoReplay.enabled end,
        set = function(state)
          if state and AutoSelect.enabled then return end -- keep mutual exclusion
          AutoReplay.enabled = state and true or false
          arKnob.Position = AutoReplay.enabled and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
          arSwitch.BackgroundColor3 = AutoReplay.enabled and COLORS.accent or Color3.fromRGB(20,20,20)
          Config.data.toggles.autoReplay = AutoReplay.enabled
          saveConfig()
          refreshMacroStatusMessage()
        end
      },
      autoSelect = {
        active = function() return AutoSelect.enabled end,
        set = function(state)
          if state and AutoReplay.enabled then return end
          AutoSelect.enabled = state and true or false
          asKnob.Position = AutoSelect.enabled and UDim2.new(1, -24, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
          asSwitch.BackgroundColor3 = AutoSelect.enabled and COLORS.accent or Color3.fromRGB(20,20,20)
          Config.data.toggles.autoSelect = AutoSelect.enabled
          saveConfig()
          refreshMacroStatusMessage()
        end
      }
    },
    
    filterSelections = FilterSelections
  }
end

-- Retornar el módulo
return Hub