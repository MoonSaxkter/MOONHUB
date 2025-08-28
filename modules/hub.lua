

-- hub.lua — UI module wrapper
-- Este archivo convierte tu UI en un módulo limpio que exporta `build(player, Config)`.
-- De momento es un stub seguro: crea un ScreenGui/Frame y devuelve los handlers.
-- Más adelante, pega aquí tu UI real dentro de `M.build`.


-- UI color palette
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

local M = {}

--- Construye el Hub UI.
-- @param player Player
-- @param Config table con { data=..., load=function() end, save=function() end }
function M.build(player, Config)
  -- 🔒 Importante: NO llames aquí a loaders ni a cosas globales.
  -- Solo crea la UI y, si quieres, lee/escribe de Config con Config.load()/Config.save().

  -- GUI raíz
  local gui = Instance.new("ScreenGui")
  gui.Name = "MyAwesomeUI"
  gui.ResetOnSpawn = false
  gui.DisplayOrder = 9999
  gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  gui.Parent = player:WaitForChild("PlayerGui")

  -- Contenedor principal (stub)
  local mainFrame = Instance.new("Frame")
  mainFrame.Name = "MainFrame"
  mainFrame.Size = UDim2.new(0, 600, 0, 680)
  mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
  mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
  mainFrame.BackgroundColor3 = COLORS.background_primary
  mainFrame.Parent = gui

    ----------------------------------------------------------------
  -- === LAYOUT BÁSICO: sidebar + tabs + contenido (hub.lua) ===
  ----------------------------------------------------------------

  -- Contenedor principal (debajo del top bar)
  local contentContainer = Instance.new("Frame")
  contentContainer.BackgroundTransparency = 1
  contentContainer.Size = UDim2.new(1, -20, 1, -20)
  contentContainer.Position = UDim2.new(0, 10, 0, 10)
  contentContainer.Parent = mainFrame

  -- Panel Izquierdo (Sidebar)
  local sidebar = Instance.new("Frame")
  sidebar.Name = "Sidebar"
  sidebar.BackgroundColor3 = COLORS.background_secondary
  sidebar.Size = UDim2.new(0, 180, 1, 0)
  sidebar.Parent = contentContainer
  do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = sidebar
    local s = Instance.new("UIStroke"); s.Color = COLORS.border; s.Thickness = 1; s.Transparency = 0.8; s.Parent = sidebar
  end

  -- Sistema de Navegación (Título + contenedor)
  local navContainer = Instance.new("Frame")
  navContainer.BackgroundTransparency = 1
  navContainer.Size = UDim2.new(1, -20, 0, 200)
  navContainer.Position = UDim2.new(0, 10, 0, 10)
  navContainer.Parent = sidebar

  local navTitle = Instance.new("TextLabel")
  navTitle.Text = "NAVIGATION"
  navTitle.TextColor3 = COLORS.text_dim
  navTitle.BackgroundTransparency = 1
  navTitle.Font = Enum.Font.SourceSansBold
  navTitle.TextSize = 12
  navTitle.Size = UDim2.new(1, 0, 0, 20)
  navTitle.Parent = navContainer

  -- Helper: crear un tab botón en la sidebar
  local tabs = {}
  local function createTab(name, yPos, emoji)
    local tab = Instance.new("TextButton")
    tab.Name = name .. "Tab"
    tab.Text = ""
    tab.AutoButtonColor = false
    tab.BackgroundColor3 = COLORS.tab_inactive
    tab.Size = UDim2.new(1, 0, 0, 38)
    tab.Position = UDim2.new(0, 0, 0, yPos)
    tab.Parent = navContainer
    do
      local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = tab
    end

    local inner = Instance.new("Frame")
    inner.BackgroundTransparency = 1
    inner.Size = UDim2.new(1, -20, 1, 0)
    inner.Position = UDim2.new(0, 10, 0, 0)
    inner.Parent = tab

    local icon = Instance.new("TextLabel")
    icon.BackgroundTransparency = 1
    icon.Text = emoji or "•"
    icon.TextColor3 = COLORS.text_dim
    icon.Font = Enum.Font.SourceSansBold
    icon.TextSize = 18
    icon.Size = UDim2.new(0, 26, 1, 0)
    icon.Parent = inner

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = COLORS.text_primary
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.Parent = inner

    local indicator = Instance.new("Frame")
    indicator.BackgroundColor3 = COLORS.accent
    indicator.Size = UDim2.new(0, 3, 0.6, 0)
    indicator.Position = UDim2.new(0, 0, 0.2, 0)
    indicator.Visible = false
    indicator.Parent = tab
    do
      local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 2); c.Parent = indicator
    end

    tabs[name] = {button = tab, icon = icon, label = label, indicator = indicator}
    return tab
  end

  -- Crea tus tabs aquí
  local featuresTab = createTab("Features", 30, "⚡")
  local macroTab    = createTab("Macro System", 74, "⚙️")

  -- Panel Derecho (Contenido)
  local contentPanel = Instance.new("Frame")
  contentPanel.BackgroundColor3 = COLORS.background_secondary
  contentPanel.Size = UDim2.new(1, -190, 1, 0)
  contentPanel.Position = UDim2.new(0, 190, 0, 0)
  contentPanel.Parent = contentContainer
  do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = contentPanel
    local s = Instance.new("UIStroke"); s.Color = COLORS.border; s.Thickness = 1; s.Transparency = 0.8; s.Parent = contentPanel
  end

  -- Páginas
  local pages = {}

  local featuresPage = Instance.new("Frame")
  featuresPage.Name = "FeaturesPage"
  featuresPage.BackgroundTransparency = 1
  featuresPage.Size = UDim2.new(1, -20, 1, -20)
  featuresPage.Position = UDim2.new(0, 10, 0, 10)
  featuresPage.Visible = true
  featuresPage.Parent = contentPanel
  pages["Features"] = featuresPage

  local macroPage = Instance.new("Frame")
  macroPage.Name = "MacroPage"
  macroPage.BackgroundTransparency = 1
  macroPage.Size = UDim2.new(1, -20, 1, -20)
  macroPage.Position = UDim2.new(0, 10, 0, 10)
  macroPage.Visible = false
  macroPage.Parent = contentPanel
  pages["Macro System"] = macroPage

  -- Títulos de demostración (puedes reemplazar con tu UI real)
  do
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = "Features"
    t.TextColor3 = COLORS.text_secondary
    t.Font = Enum.Font.SourceSansBold
    t.TextSize = 22
    t.Size = UDim2.new(1, 0, 0, 26)
    t.Parent = featuresPage
  end
  do
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Text = "Macro System"
    t.TextColor3 = COLORS.text_secondary
    t.Font = Enum.Font.SourceSansBold
    t.TextSize = 22
    t.Size = UDim2.new(1, 0, 0, 26)
    t.Parent = macroPage
  end

  -- Estado y navegación
  local TweenService = game:GetService("TweenService")
  local currentTabName = "Features"

  local function switchTab(tabName)
    if currentTabName == tabName then return end

    -- Apaga tab actual
    local old = tabs[currentTabName]
    if old then
      TweenService:Create(old.button, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.tab_inactive}):Play()
      TweenService:Create(old.icon,   TweenInfo.new(0.2), {TextColor3 = COLORS.text_dim}):Play()
      TweenService:Create(old.label,  TweenInfo.new(0.2), {TextColor3 = COLORS.text_primary}):Play()
      old.indicator.Visible = false
    end

    -- Enciende tab nueva
    local newt = tabs[tabName]
    if newt then
      TweenService:Create(newt.button, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.tab_active}):Play()
      TweenService:Create(newt.icon,   TweenInfo.new(0.2), {TextColor3 = COLORS.text_secondary}):Play()
      TweenService:Create(newt.label,  TweenInfo.new(0.2), {TextColor3 = COLORS.text_secondary}):Play()
      newt.indicator.Visible = true
    end

    -- Cambia páginas
    for name, page in pairs(pages) do
      page.Visible = (name == tabName)
    end

    currentTabName = tabName
  end

  -- Estado visual inicial del tab activo
  do
    local t = tabs[currentTabName]
    if t then
      t.button.BackgroundColor3 = COLORS.tab_active
      t.icon.TextColor3 = COLORS.text_secondary
      t.label.TextColor3 = COLORS.text_secondary
      t.indicator.Visible = true
    end
  end

  -- Click handlers
  featuresTab.MouseButton1Click:Connect(function()
    switchTab("Features")
  end)
  macroTab.MouseButton1Click:Connect(function()
    switchTab("Macro System")
  end)
  ----------------------------------------------------------------
  -- === FIN BLOQUE LAYOUT BÁSICO ===
  ----------------------------------------------------------------

  -- (Aquí pegarás toda tu UI real: colores, sidebar, tabs, filtros, macros, etc.)
  -- Asegúrate de terminar con mainFrame.Visible = true
  mainFrame.Visible = true

  -- Devuelve referencias útiles por si las necesitas desde fuera
  return {
    gui  = gui,
    root = mainFrame,
  }
end

return M
