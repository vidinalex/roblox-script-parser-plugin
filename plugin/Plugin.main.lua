
-- Toolbar and Docked UI setup
local toolbar = plugin:CreateToolbar("Script Parser")
local toggleButton = toolbar:CreateButton("OpenParser", "Open Script Parser", "rbxassetid://71067276462408")

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,
	false,
	true,
	340,
	460,
	340,
	460
)

local widget
do
	local ok, created = pcall(function()
		return plugin:CreateDockWidgetPluginGuiAsync("ScriptParserDock", widgetInfo)
	end)
	if ok and created then
		widget = created
	else
		widget = plugin:CreateDockWidgetPluginGui("ScriptParserDock", widgetInfo)
	end
end
widget.Title = "Script Parser"

-- Theme (dark purple)
local DARK_BG = Color3.fromRGB(22, 8, 35)
local DARK_PANEL = Color3.fromRGB(36, 16, 58)
local ACCENT = Color3.fromRGB(156, 102, 255)
local ACCENT_HOVER = Color3.fromRGB(176, 130, 255)
local ACCENT_DOWN = Color3.fromRGB(126, 82, 230)
local ADD_COLOR = Color3.fromRGB(92, 220, 140)
local ADD_HOVER = Color3.fromRGB(116, 235, 160)
local TEXT = Color3.fromRGB(235, 230, 255)
local INPUT_BG = Color3.fromRGB(46, 22, 74)
local HOVER_BG = Color3.fromRGB(30, 12, 46)
local TREE_BG = Color3.fromRGB(26, 10, 40)
local TREE_BG_HOVER = Color3.fromRGB(34, 14, 52)
local ICON_FOLDER = "rbxasset://studio_svg_textures/Shared/InsertableObjects/Dark/Standard/Folder.png"
local ICON_ARROW_COLLAPSED = "rbxasset://textures/DeveloperFramework/arrow_right.png"
local ICON_ARROW_EXPANDED = "rbxasset://textures/DeveloperFramework/button_arrow_down.png"

local function serviceIcon(serviceName)
	return "rbxasset://studio_svg_textures/Shared/InsertableObjects/Dark/Standard/" .. tostring(serviceName) .. ".png"
end

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local ScriptEditorService = nil
pcall(function()
	ScriptEditorService = game:GetService("ScriptEditorService")
end)

local function wireButtonStyle(btn, baseColor, hoverColor, downColor, baseScale, hoverScale, downScale)
	if not btn then
		return
	end

	baseScale = baseScale or 1
	hoverScale = hoverScale or 1.02
	downScale = downScale or 0.98

	local scale = btn:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Scale = baseScale
		scale.Parent = btn
	else
		scale.Scale = baseScale
	end

	local hovered = false
	local function tween(color, scaleValue)
		if color ~= nil then
			TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = color,
			}):Play()
		end
		if scaleValue ~= nil then
			TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Scale = scaleValue,
			}):Play()
		end
	end

	btn.MouseEnter:Connect(function()
		hovered = true
		if btn.Active then
			tween(hoverColor, hoverScale)
		end
	end)

	btn.MouseLeave:Connect(function()
		hovered = false
		if btn.Active then
			tween(baseColor, baseScale)
		end
	end)

	btn.MouseButton1Down:Connect(function()
		if btn.Active then
			tween(downColor, downScale)
		end
	end)

	btn.MouseButton1Up:Connect(function()
		if btn.Active then
			tween(hovered and hoverColor or baseColor, hovered and hoverScale or baseScale)
		end
	end)
end

-- UI
local main = Instance.new("CanvasGroup")
main.Name = "MainGroup"
main.Size = UDim2.fromScale(1, 1)
main.BackgroundColor3 = DARK_BG
main.BorderSizePixel = 0
main.GroupTransparency = 0
main.Parent = widget

local header = Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, -20, 0, 40)
header.Position = UDim2.fromOffset(10, 10)
header.BackgroundTransparency = 1
header.Text = "Roblox Script Parser"
header.TextColor3 = TEXT
header.TextXAlignment = Enum.TextXAlignment.Left
header.Font = Enum.Font.GothamBold
header.TextSize = 18
header.Parent = main

-- Settings panel
local settings = Instance.new("Frame")
settings.Name = "Settings"
settings.Size = UDim2.new(1, -20, 0, 160)
settings.Position = UDim2.fromOffset(10, 52)
settings.BackgroundColor3 = DARK_PANEL
settings.BorderSizePixel = 0
settings.Parent = main

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 8)
settingsCorner.Parent = settings

local settingsPad = Instance.new("UIPadding")
settingsPad.PaddingLeft = UDim.new(0, 10)
settingsPad.PaddingRight = UDim.new(0, 10)
settingsPad.PaddingTop = UDim.new(0, 10)
settingsPad.PaddingBottom = UDim.new(0, 10)
settingsPad.Parent = settings

local hostLabel = Instance.new("TextLabel")
hostLabel.Size = UDim2.new(1, 0, 0, 18)
hostLabel.Position = UDim2.fromOffset(0, 0)
hostLabel.BackgroundTransparency = 1
hostLabel.Text = "Python server (http):"
hostLabel.TextColor3 = TEXT
hostLabel.TextXAlignment = Enum.TextXAlignment.Left
hostLabel.Font = Enum.Font.Gotham
hostLabel.TextSize = 12
hostLabel.Parent = settings

local serverInput = Instance.new("TextBox")
serverInput.Name = "ServerInput"
serverInput.Size = UDim2.new(1, 0, 0, 28)
serverInput.Position = UDim2.fromOffset(0, 20)
serverInput.BackgroundColor3 = INPUT_BG
serverInput.BorderSizePixel = 0
serverInput.Text = "http://127.0.0.1:5000/upload"
serverInput.PlaceholderText = "http://127.0.0.1:5000/upload"
serverInput.TextColor3 = TEXT
serverInput.PlaceholderColor3 = Color3.fromRGB(190, 170, 220)
serverInput.ClearTextOnFocus = false
serverInput.Font = Enum.Font.Gotham
serverInput.TextSize = 14
serverInput.Parent = settings

local serverInputCorner = Instance.new("UICorner")
serverInputCorner.CornerRadius = UDim.new(0, 6)
serverInputCorner.Parent = serverInput

local serverStroke = Instance.new("UIStroke")
serverStroke.Thickness = 1
serverStroke.Color = ACCENT
serverStroke.Transparency = 0.6
serverStroke.Parent = serverInput

local outLabel = Instance.new("TextLabel")
outLabel.Size = UDim2.new(1, 0, 0, 18)
outLabel.Position = UDim2.fromOffset(0, 58)
outLabel.BackgroundTransparency = 1
outLabel.Text = "Output folder name:"
outLabel.TextColor3 = TEXT
outLabel.TextXAlignment = Enum.TextXAlignment.Left
outLabel.Font = Enum.Font.Gotham
outLabel.TextSize = 12
outLabel.Parent = settings

local outputInput = Instance.new("TextBox")
outputInput.Name = "OutputInput"
outputInput.Size = UDim2.new(1, 0, 0, 28)
outputInput.Position = UDim2.fromOffset(0, 78)
outputInput.BackgroundColor3 = INPUT_BG
outputInput.BorderSizePixel = 0
outputInput.Text = (game.Name and #game.Name > 0) and (game.Name .. "_output") or "output"
outputInput.PlaceholderText = "output"
outputInput.TextColor3 = TEXT
outputInput.PlaceholderColor3 = Color3.fromRGB(190, 170, 220)
outputInput.ClearTextOnFocus = false
outputInput.Font = Enum.Font.Gotham
outputInput.TextSize = 14
outputInput.Parent = settings

local outputInputCorner = Instance.new("UICorner")
outputInputCorner.CornerRadius = UDim.new(0, 6)
outputInputCorner.Parent = outputInput

local outputStroke = Instance.new("UIStroke")
outputStroke.Thickness = 1
outputStroke.Color = ACCENT
outputStroke.Transparency = 0.6
outputStroke.Parent = outputInput

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.fromOffset(10, 216)
divider.BackgroundColor3 = ACCENT
divider.BorderSizePixel = 0
divider.Parent = main

local servicesLabel = Instance.new("TextLabel")
servicesLabel.Size = UDim2.new(1, -20, 0, 18)
servicesLabel.Position = UDim2.fromOffset(10, 226)
servicesLabel.BackgroundTransparency = 1
servicesLabel.Text = "Select services to scan:"
servicesLabel.TextColor3 = TEXT
servicesLabel.TextXAlignment = Enum.TextXAlignment.Left
servicesLabel.Font = Enum.Font.Gotham
servicesLabel.TextSize = 12
servicesLabel.Parent = main

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ServiceList"
scroll.Size = UDim2.new(1, -20, 1, -360)
scroll.Position = UDim2.fromOffset(10, 248)
scroll.BackgroundColor3 = DARK_PANEL
scroll.BorderSizePixel = 0
scroll.ClipsDescendants = true
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ScrollBarThickness = 6
scroll.Parent = main

local servicesCorner = Instance.new("UICorner")
servicesCorner.CornerRadius = UDim.new(0, 6)
servicesCorner.Parent = scroll

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 8)
scrollCorner.Parent = scroll

local scrollPadding = Instance.new("UIPadding")
scrollPadding.PaddingLeft = UDim.new(0, 6)
scrollPadding.PaddingRight = UDim.new(0, 6)
scrollPadding.PaddingTop = UDim.new(0, 6)
scrollPadding.PaddingBottom = UDim.new(0, 6)
scrollPadding.Parent = scroll

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

local function createCheckbox(text, initialSelected)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -12, 0, 32)
	button.BackgroundColor3 = DARK_BG
	button.AutoButtonColor = false
	button.Text = ""

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local check = Instance.new("Frame")
	check.Name = "Check"
	check.Size = UDim2.fromOffset(18, 18)
	check.Position = UDim2.fromOffset(10, 7)
	check.BackgroundColor3 = DARK_PANEL
	check.BorderSizePixel = 0
	check.Parent = button

	local checkCorner = Instance.new("UICorner")
	checkCorner.CornerRadius = UDim.new(0, 4)
	checkCorner.Parent = check

	local tick = Instance.new("Frame")
	tick.Name = "Tick"
	tick.Size = UDim2.fromScale(1, 1)
	tick.BackgroundColor3 = ACCENT
	tick.BackgroundTransparency = 1
	tick.BorderSizePixel = 0
	tick.Parent = check

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Position = UDim2.fromOffset(38, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = TEXT
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.Parent = button

	local selected = initialSelected == true

	local function update(instant)
		local checkColor = selected and ACCENT or DARK_PANEL
		local tickTransparency = selected and 0 or 1
		if instant then
			check.BackgroundColor3 = checkColor
			tick.BackgroundTransparency = tickTransparency
		else
			TweenService:Create(check, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = checkColor,
			}):Play()
			TweenService:Create(tick, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = tickTransparency,
			}):Play()
		end
	end

	button.MouseButton1Click:Connect(function()
		selected = not selected
		update(false)
	end)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = HOVER_BG,
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = DARK_BG,
		}):Play()
	end)

	-- initialize visuals to match default
	update(true)

	return button, function() return selected end
end

-- Map of service labels to Instances (ordered like Studio)
local orderedServices = {
	"Workspace",
	"ReplicatedFirst",
	"ReplicatedStorage",
	"ServerScriptService",
	"ServerStorage",
	"StarterPlayer",
	"StarterGui",
	"StarterPack",
}

local serviceProviders = {
	["Workspace"] = workspace,
	["ReplicatedFirst"] = game:GetService("ReplicatedFirst"),
	["ReplicatedStorage"] = game:GetService("ReplicatedStorage"),
	["ServerScriptService"] = game:GetService("ServerScriptService"),
	["ServerStorage"] = game:GetService("ServerStorage"),
	["StarterPlayer"] = game:GetService("StarterPlayer"),
	["StarterGui"] = game:GetService("StarterGui"),
	["StarterPack"] = game:GetService("StarterPack"),
}

-- Build UI checkboxes with defaults (enabled by default except Workspace)
local getters = {}
for _, label in ipairs(orderedServices) do
	local initial = (label ~= "Workspace")
	local row, getter = createCheckbox(label, initial)
	row.Parent = scroll
	getters[label] = getter
end

local includeUiGetter
local includeObjectsGetter
do
	local rowUi, getterUi = createCheckbox("Include UI", false)
	rowUi.Name = "IncludeUiRow"
	rowUi.Size = UDim2.new(0.5, -6, 0, 28)
	rowUi.Position = UDim2.fromOffset(0, 116)
	rowUi.Parent = settings
	includeUiGetter = getterUi

	local rowObj, getterObj = createCheckbox("Include Objects", false)
	rowObj.Name = "IncludeObjectsRow"
	rowObj.Size = UDim2.new(0.5, -6, 0, 28)
	rowObj.Position = UDim2.new(0.5, 6, 0, 116)
	rowObj.Parent = settings
	includeObjectsGetter = getterObj
end

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 18)
statusLabel.Position = UDim2.new(0, 10, 1, -96)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = TEXT
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.Parent = main

local buttonRow = Instance.new("Frame")
buttonRow.Name = "ButtonRow"
buttonRow.Size = UDim2.new(1, -20, 0, 36)
buttonRow.Position = UDim2.new(0, 10, 1, -48)
buttonRow.BackgroundTransparency = 1
buttonRow.BorderSizePixel = 0
buttonRow.ZIndex = 10
buttonRow.Parent = main

local sendBtn = Instance.new("TextButton")
sendBtn.Name = "ExportBtn"
sendBtn.Size = UDim2.new(0.5, -6, 1, 0)
sendBtn.Position = UDim2.fromOffset(0, 0)
sendBtn.BackgroundColor3 = ACCENT
sendBtn.BorderSizePixel = 0
sendBtn.AutoButtonColor = false
sendBtn.Text = "Export"
sendBtn.TextColor3 = TEXT
sendBtn.Font = Enum.Font.GothamBold
sendBtn.TextSize = 16
sendBtn.Parent = buttonRow

local sendCorner = Instance.new("UICorner")
sendCorner.CornerRadius = UDim.new(0, 8)
sendCorner.Parent = sendBtn

local reviewBtn = Instance.new("TextButton")
reviewBtn.Name = "ReviewBtn"
reviewBtn.Size = UDim2.new(0.5, -6, 1, 0)
reviewBtn.Position = UDim2.new(0.5, 6, 0, 0)
reviewBtn.BackgroundColor3 = DARK_PANEL
reviewBtn.BorderSizePixel = 0
reviewBtn.AutoButtonColor = false
reviewBtn.Text = "Review & Sync"
reviewBtn.TextColor3 = TEXT
reviewBtn.Font = Enum.Font.GothamBold
reviewBtn.TextSize = 16
reviewBtn.Parent = buttonRow

local reviewCorner = Instance.new("UICorner")
reviewCorner.CornerRadius = UDim.new(0, 8)
reviewCorner.Parent = reviewBtn

-- Progress bar
local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, -20, 0, 6)
progressBg.Position = UDim2.new(0, 10, 1, -72)
progressBg.BackgroundColor3 = DARK_PANEL
progressBg.BorderSizePixel = 0
progressBg.ZIndex = 1
progressBg.Parent = main

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 3)
progressCorner.Parent = progressBg

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.Position = UDim2.new(0, 0, 0, 0)
progressFill.BackgroundColor3 = ACCENT
progressFill.BorderSizePixel = 0
progressFill.ZIndex = 2
progressFill.Parent = progressBg

local progressFillCorner = Instance.new("UICorner")
progressFillCorner.CornerRadius = UDim.new(0, 3)
progressFillCorner.Parent = progressFill

wireButtonStyle(sendBtn, ACCENT, ACCENT_HOVER, ACCENT_DOWN)
wireButtonStyle(reviewBtn, DARK_PANEL, HOVER_BG, DARK_BG)

-- Review & Sync page (local -> Studio)
local reviewPage = Instance.new("CanvasGroup")
reviewPage.Name = "ReviewPage"
reviewPage.Size = UDim2.fromScale(1, 1)
reviewPage.BackgroundColor3 = DARK_BG
reviewPage.BorderSizePixel = 0
reviewPage.GroupTransparency = 1
reviewPage.Visible = false
reviewPage.Parent = widget

local reviewTitle = Instance.new("TextLabel")
reviewTitle.Name = "ReviewTitle"
reviewTitle.Size = UDim2.new(1, -20, 0, 28)
reviewTitle.Position = UDim2.fromOffset(10, 10)
reviewTitle.BackgroundTransparency = 1
reviewTitle.Text = "Local Changes"
reviewTitle.TextColor3 = TEXT
reviewTitle.TextXAlignment = Enum.TextXAlignment.Left
reviewTitle.Font = Enum.Font.GothamBold
reviewTitle.TextSize = 18
reviewTitle.Parent = reviewPage

local reviewBackBtn = Instance.new("TextButton")
reviewBackBtn.Name = "BackBtn"
reviewBackBtn.Size = UDim2.fromOffset(76, 26)
reviewBackBtn.Position = UDim2.new(1, -86, 0, 12)
reviewBackBtn.BackgroundColor3 = DARK_PANEL
reviewBackBtn.BorderSizePixel = 0
reviewBackBtn.AutoButtonColor = false
reviewBackBtn.Text = "Back"
reviewBackBtn.TextColor3 = TEXT
reviewBackBtn.Font = Enum.Font.GothamBold
reviewBackBtn.TextSize = 14
reviewBackBtn.Parent = reviewPage

local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(0, 8)
backCorner.Parent = reviewBackBtn
wireButtonStyle(reviewBackBtn, DARK_PANEL, HOVER_BG, DARK_BG, 1, 1.02, 0.99)

local reviewSummary = Instance.new("TextLabel")
reviewSummary.Name = "Summary"
reviewSummary.Size = UDim2.new(1, -20, 0, 18)
reviewSummary.Position = UDim2.fromOffset(10, 44)
reviewSummary.BackgroundTransparency = 1
reviewSummary.Text = "No changes loaded"
reviewSummary.TextColor3 = TEXT
reviewSummary.TextXAlignment = Enum.TextXAlignment.Left
reviewSummary.Font = Enum.Font.Gotham
reviewSummary.TextSize = 12
reviewSummary.Parent = reviewPage

local reviewRefreshBtn = Instance.new("TextButton")
reviewRefreshBtn.Name = "RefreshBtn"
reviewRefreshBtn.Size = UDim2.fromOffset(90, 26)
reviewRefreshBtn.Position = UDim2.fromOffset(10, 66)
reviewRefreshBtn.BackgroundColor3 = DARK_PANEL
reviewRefreshBtn.BorderSizePixel = 0
reviewRefreshBtn.AutoButtonColor = false
reviewRefreshBtn.Text = "Refresh"
reviewRefreshBtn.TextColor3 = TEXT
reviewRefreshBtn.Font = Enum.Font.GothamBold
reviewRefreshBtn.TextSize = 14
reviewRefreshBtn.Parent = reviewPage

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 8)
refreshCorner.Parent = reviewRefreshBtn
wireButtonStyle(reviewRefreshBtn, DARK_PANEL, HOVER_BG, DARK_BG, 1, 1.02, 0.99)

local reviewList = Instance.new("ScrollingFrame")
reviewList.Name = "ChangeList"
reviewList.Size = UDim2.new(1, -20, 0, 150)
reviewList.Position = UDim2.fromOffset(10, 100)
reviewList.BackgroundColor3 = DARK_PANEL
reviewList.BorderSizePixel = 0
reviewList.ClipsDescendants = true
reviewList.AutomaticCanvasSize = Enum.AutomaticSize.Y
reviewList.CanvasSize = UDim2.new()
reviewList.ScrollBarThickness = 6
reviewList.Parent = reviewPage

local reviewListCorner = Instance.new("UICorner")
reviewListCorner.CornerRadius = UDim.new(0, 8)
reviewListCorner.Parent = reviewList

local reviewListPadding = Instance.new("UIPadding")
reviewListPadding.PaddingLeft = UDim.new(0, 6)
reviewListPadding.PaddingRight = UDim.new(0, 6)
reviewListPadding.PaddingTop = UDim.new(0, 6)
reviewListPadding.PaddingBottom = UDim.new(0, 6)
reviewListPadding.Parent = reviewList

local reviewListLayout = Instance.new("UIListLayout")
reviewListLayout.Padding = UDim.new(0, 8)
reviewListLayout.FillDirection = Enum.FillDirection.Vertical
reviewListLayout.SortOrder = Enum.SortOrder.LayoutOrder
reviewListLayout.Parent = reviewList

reviewList.Size = UDim2.new(1, -20, 1, -186)

local reviewOpenDiffBtn = Instance.new("TextButton")
reviewOpenDiffBtn.Name = "OpenDiffBtn"
reviewOpenDiffBtn.Size = UDim2.fromOffset(120, 26)
reviewOpenDiffBtn.Position = UDim2.fromOffset(110, 66)
reviewOpenDiffBtn.BackgroundColor3 = DARK_PANEL
reviewOpenDiffBtn.BorderSizePixel = 0
reviewOpenDiffBtn.AutoButtonColor = false
reviewOpenDiffBtn.Text = "Open Diff"
reviewOpenDiffBtn.TextColor3 = TEXT
reviewOpenDiffBtn.Font = Enum.Font.GothamBold
reviewOpenDiffBtn.TextSize = 14
reviewOpenDiffBtn.Parent = reviewPage

local openDiffCorner = Instance.new("UICorner")
openDiffCorner.CornerRadius = UDim.new(0, 8)
openDiffCorner.Parent = reviewOpenDiffBtn
wireButtonStyle(reviewOpenDiffBtn, DARK_PANEL, HOVER_BG, DARK_BG, 1, 1.02, 0.99)

local diffModal = Instance.new("CanvasGroup")
diffModal.Name = "DiffModal"
diffModal.Size = UDim2.new(1, -20, 1, -20)
diffModal.Position = UDim2.fromOffset(10, 10)
diffModal.BackgroundColor3 = DARK_PANEL
diffModal.BorderSizePixel = 0
diffModal.GroupTransparency = 1
diffModal.Visible = false
diffModal.ZIndex = 50
diffModal.Parent = reviewPage

local diffCorner = Instance.new("UICorner")
diffCorner.CornerRadius = UDim.new(0, 10)
diffCorner.Parent = diffModal

local diffHeader = Instance.new("TextLabel")
diffHeader.Name = "DiffHeader"
diffHeader.Size = UDim2.new(1, -120, 0, 28)
diffHeader.Position = UDim2.fromOffset(12, 10)
diffHeader.BackgroundTransparency = 1
diffHeader.Text = "Diff"
diffHeader.TextColor3 = TEXT
diffHeader.TextXAlignment = Enum.TextXAlignment.Left
diffHeader.Font = Enum.Font.GothamBold
diffHeader.TextSize = 16
diffHeader.ZIndex = 51
diffHeader.Parent = diffModal

local diffCloseBtn = Instance.new("TextButton")
diffCloseBtn.Name = "CloseBtn"
diffCloseBtn.Size = UDim2.fromOffset(80, 26)
diffCloseBtn.Position = UDim2.new(1, -92, 0, 10)
diffCloseBtn.BackgroundColor3 = DARK_BG
diffCloseBtn.BorderSizePixel = 0
diffCloseBtn.AutoButtonColor = false
diffCloseBtn.Text = "Close"
diffCloseBtn.TextColor3 = TEXT
diffCloseBtn.Font = Enum.Font.GothamBold
diffCloseBtn.TextSize = 14
diffCloseBtn.ZIndex = 51
diffCloseBtn.Parent = diffModal

local diffCloseCorner = Instance.new("UICorner")
diffCloseCorner.CornerRadius = UDim.new(0, 8)
diffCloseCorner.Parent = diffCloseBtn
wireButtonStyle(diffCloseBtn, DARK_BG, HOVER_BG, DARK_PANEL, 1, 1.02, 0.99)

local diffTabs = Instance.new("Frame")
diffTabs.Name = "Tabs"
diffTabs.Size = UDim2.new(1, -24, 0, 30)
diffTabs.Position = UDim2.fromOffset(12, 44)
diffTabs.BackgroundTransparency = 1
diffTabs.ZIndex = 51
diffTabs.Parent = diffModal

local diffLocalTab = Instance.new("TextButton")
diffLocalTab.Name = "LocalTab"
diffLocalTab.Size = UDim2.new(0.5, -6, 1, 0)
diffLocalTab.Position = UDim2.fromOffset(0, 0)
diffLocalTab.BackgroundColor3 = ACCENT
diffLocalTab.BorderSizePixel = 0
diffLocalTab.AutoButtonColor = false
diffLocalTab.Text = "Local"
diffLocalTab.TextColor3 = TEXT
diffLocalTab.Font = Enum.Font.GothamBold
diffLocalTab.TextSize = 14
diffLocalTab.ZIndex = 52
diffLocalTab.Parent = diffTabs

local diffLocalCorner = Instance.new("UICorner")
diffLocalCorner.CornerRadius = UDim.new(0, 8)
diffLocalCorner.Parent = diffLocalTab
wireButtonStyle(diffLocalTab, nil, nil, nil, 1, 1.02, 0.99)

local diffStudioTab = Instance.new("TextButton")
diffStudioTab.Name = "StudioTab"
diffStudioTab.Size = UDim2.new(0.5, -6, 1, 0)
diffStudioTab.Position = UDim2.new(0.5, 6, 0, 0)
diffStudioTab.BackgroundColor3 = DARK_BG
diffStudioTab.BorderSizePixel = 0
diffStudioTab.AutoButtonColor = false
diffStudioTab.Text = "Studio"
diffStudioTab.TextColor3 = TEXT
diffStudioTab.Font = Enum.Font.GothamBold
diffStudioTab.TextSize = 14
diffStudioTab.ZIndex = 52
diffStudioTab.Parent = diffTabs

local diffStudioCorner = Instance.new("UICorner")
diffStudioCorner.CornerRadius = UDim.new(0, 8)
diffStudioCorner.Parent = diffStudioTab
wireButtonStyle(diffStudioTab, nil, nil, nil, 1, 1.02, 0.99)

local diffScroll = Instance.new("ScrollingFrame")
diffScroll.Name = "DiffScroll"
diffScroll.Size = UDim2.new(1, -24, 1, -92)
diffScroll.Position = UDim2.fromOffset(12, 82)
diffScroll.BackgroundColor3 = DARK_BG
diffScroll.BorderSizePixel = 0
diffScroll.ClipsDescendants = true
diffScroll.ScrollBarThickness = 6
diffScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
diffScroll.CanvasSize = UDim2.new()
diffScroll.ZIndex = 51
diffScroll.Parent = diffModal

local diffScrollCorner = Instance.new("UICorner")
diffScrollCorner.CornerRadius = UDim.new(0, 10)
diffScrollCorner.Parent = diffScroll

local diffScrollPadding = Instance.new("UIPadding")
diffScrollPadding.PaddingLeft = UDim.new(0, 10)
diffScrollPadding.PaddingRight = UDim.new(0, 10)
diffScrollPadding.PaddingTop = UDim.new(0, 10)
diffScrollPadding.PaddingBottom = UDim.new(0, 10)
diffScrollPadding.Parent = diffScroll

local diffText = Instance.new("TextLabel")
diffText.Name = "DiffText"
diffText.Size = UDim2.new(1, -20, 0, 0)
diffText.AutomaticSize = Enum.AutomaticSize.Y
diffText.BackgroundTransparency = 1
diffText.Text = ""
diffText.TextColor3 = TEXT
pcall(function()
	diffText.TextSelectable = true
end)
diffText.TextXAlignment = Enum.TextXAlignment.Left
diffText.TextYAlignment = Enum.TextYAlignment.Top
diffText.Font = Enum.Font.Code
diffText.TextSize = 12
diffText.ZIndex = 52
diffText.Parent = diffScroll

local reviewStatusLabel = Instance.new("TextLabel")
reviewStatusLabel.Name = "ReviewStatus"
reviewStatusLabel.Size = UDim2.new(1, -20, 0, 18)
reviewStatusLabel.Position = UDim2.new(0, 10, 1, -96)
reviewStatusLabel.BackgroundTransparency = 1
reviewStatusLabel.Text = ""
reviewStatusLabel.TextColor3 = TEXT
reviewStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
reviewStatusLabel.Font = Enum.Font.Gotham
reviewStatusLabel.TextSize = 12
reviewStatusLabel.Parent = reviewPage

local reviewProgressBg = Instance.new("Frame")
reviewProgressBg.Name = "ReviewProgressBg"
reviewProgressBg.Size = UDim2.new(1, -20, 0, 6)
reviewProgressBg.Position = UDim2.new(0, 10, 1, -72)
reviewProgressBg.BackgroundColor3 = DARK_PANEL
reviewProgressBg.BorderSizePixel = 0
reviewProgressBg.ZIndex = 1
reviewProgressBg.Parent = reviewPage

local reviewProgressCorner = Instance.new("UICorner")
reviewProgressCorner.CornerRadius = UDim.new(0, 3)
reviewProgressCorner.Parent = reviewProgressBg

local reviewProgressFill = Instance.new("Frame")
reviewProgressFill.Name = "ReviewProgressFill"
reviewProgressFill.Size = UDim2.new(0, 0, 1, 0)
reviewProgressFill.Position = UDim2.new(0, 0, 0, 0)
reviewProgressFill.BackgroundColor3 = ACCENT
reviewProgressFill.BorderSizePixel = 0
reviewProgressFill.ZIndex = 2
reviewProgressFill.Parent = reviewProgressBg

local reviewFillCorner = Instance.new("UICorner")
reviewFillCorner.CornerRadius = UDim.new(0, 3)
reviewFillCorner.Parent = reviewProgressFill

local reviewSyncBtn = Instance.new("TextButton")
reviewSyncBtn.Name = "SyncBtn"
reviewSyncBtn.Size = UDim2.new(1, -20, 0, 36)
reviewSyncBtn.Position = UDim2.new(0, 10, 1, -48)
reviewSyncBtn.BackgroundColor3 = ACCENT
reviewSyncBtn.BorderSizePixel = 0
reviewSyncBtn.AutoButtonColor = false
reviewSyncBtn.Text = "Sync Selected"
reviewSyncBtn.TextColor3 = TEXT
reviewSyncBtn.Font = Enum.Font.GothamBold
reviewSyncBtn.TextSize = 16
reviewSyncBtn.Parent = reviewPage

local reviewSyncCorner = Instance.new("UICorner")
reviewSyncCorner.CornerRadius = UDim.new(0, 8)
reviewSyncCorner.Parent = reviewSyncBtn
wireButtonStyle(reviewSyncBtn, ACCENT, ACCENT_HOVER, ACCENT_DOWN)

local function once(signal, fn)
	local conn
	conn = signal:Connect(function(...)
		conn:Disconnect()
		fn(...)
	end)
end

local exportPage = main
local activePage = exportPage
local pageTweens = {}
local reviewUiEnabled = true
local updateReviewSelectionUi = nil

local function tweenPage(page, props, duration)
	local existing = pageTweens[page]
	if existing then
		existing:Cancel()
	end
	local tween = TweenService:Create(page, TweenInfo.new(duration or 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	pageTweens[page] = tween
	tween:Play()
	return tween
end

local function setUiEnabled(enabled)
	reviewUiEnabled = enabled

	sendBtn.Active = enabled
	sendBtn.BackgroundColor3 = enabled and ACCENT or DARK_PANEL
	sendBtn.TextTransparency = enabled and 0 or 0.35

	reviewBtn.Active = enabled
	reviewBtn.BackgroundColor3 = enabled and DARK_PANEL or DARK_BG
	reviewBtn.TextTransparency = enabled and 0 or 0.35

	reviewRefreshBtn.Active = enabled
	reviewRefreshBtn.TextTransparency = enabled and 0 or 0.35

	reviewOpenDiffBtn.Active = enabled
	reviewOpenDiffBtn.TextTransparency = enabled and 0 or 0.35

	diffCloseBtn.Active = enabled
	diffCloseBtn.TextTransparency = enabled and 0 or 0.35
	diffLocalTab.Active = enabled
	diffStudioTab.Active = enabled

	if updateReviewSelectionUi then
		updateReviewSelectionUi()
	else
		reviewSyncBtn.Active = enabled
		reviewSyncBtn.BackgroundColor3 = enabled and ACCENT or DARK_PANEL
		reviewSyncBtn.TextTransparency = enabled and 0 or 0.35
	end
end

local function showPage(page, animate)
	if page == activePage then
		return
	end

	local from = activePage
	local to = page
	activePage = to
	local dir = (to == reviewPage) and 1 or -1

	to.Visible = true
	to.GroupTransparency = 1
	to.Position = UDim2.new(0, 18 * dir, 0, 0)

	if animate then
		local outTween = tweenPage(from, { GroupTransparency = 1, Position = UDim2.new(0, -18 * dir, 0, 0) }, 0.14)
		once(outTween.Completed, function()
			from.Visible = false
			from.GroupTransparency = 0
			from.Position = UDim2.fromOffset(0, 0)
		end)
		tweenPage(to, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.18)
	else
		from.Visible = false
		from.GroupTransparency = 0
		from.Position = UDim2.fromOffset(0, 0)
		to.GroupTransparency = 0
		to.Position = UDim2.fromOffset(0, 0)
	end
end

local function setWidgetOpen(open, animate)
	if open then
		widget.Enabled = true
		if animate then
			activePage.Visible = true
			activePage.GroupTransparency = 1
			activePage.Position = UDim2.fromOffset(0, 8)
			tweenPage(activePage, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
		else
			activePage.Visible = true
			activePage.GroupTransparency = 0
			activePage.Position = UDim2.fromOffset(0, 0)
		end
	else
		if not widget.Enabled then
			return
		end
		diffModal.Visible = false
		diffModal.GroupTransparency = 1
		if animate then
			local tween = tweenPage(activePage, { GroupTransparency = 1, Position = UDim2.fromOffset(0, 8) })
			once(tween.Completed, function()
				widget.Enabled = false
				activePage.GroupTransparency = 0
				activePage.Position = UDim2.fromOffset(0, 0)
			end)
		else
			widget.Enabled = false
			activePage.GroupTransparency = 0
			activePage.Position = UDim2.fromOffset(0, 0)
		end
	end
end

local function setProgressAlpha(alpha)
	alpha = math.clamp(alpha, 0, 1)
	local tween = TweenService:Create(progressFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(alpha, 0, 1, 0)
	})
	tween:Play()
end

local function setStatus(textValue)
	statusLabel.Text = textValue
end

local function setReviewStatus(textValue)
	reviewStatusLabel.Text = textValue
end

local function setReviewProgressAlpha(alpha)
	alpha = math.clamp(alpha, 0, 1)
	TweenService:Create(reviewProgressFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(alpha, 0, 1, 0),
	}):Play()
end

-- Utilities
local function isLuaScript(instance)
	return instance:IsA("LuaSourceContainer")
end

local function isUiInstance(instance)
	return instance:IsA("LayerCollector") or instance:IsA("GuiObject") or instance:IsA("UIBase") or instance:IsA("GuiBase2d")
end

local function encodeEnum(enumItem)
	local enumTypeName = nil
	local okType, enumType = pcall(function()
		return enumItem.EnumType
	end)
	if okType and enumType ~= nil then
		local okName, name = pcall(function()
			return enumType.Name
		end)
		if okName and type(name) == "string" and #name > 0 then
			enumTypeName = name
		else
			local s = tostring(enumType)
			enumTypeName = (string.match(s, "^Enum%.(.+)$")) or s
		end
	end
	if type(enumTypeName) ~= "string" or #enumTypeName == 0 then
		enumTypeName = "Unknown"
	end
	return { __t = "Enum", enumType = enumTypeName, name = enumItem.Name }
end

local function encodeValue(value)
	local valueType = typeof(value)
	if valueType == "nil" then
		return nil
	end
	if valueType == "boolean" or valueType == "number" or valueType == "string" then
		return value
	end
	if valueType == "Color3" then
		return { __t = "Color3", r = value.R, g = value.G, b = value.B }
	end
	if valueType == "Vector2" then
		return { __t = "Vector2", x = value.X, y = value.Y }
	end
	if valueType == "Vector3" then
		return { __t = "Vector3", x = value.X, y = value.Y, z = value.Z }
	end
	if valueType == "UDim" then
		return { __t = "UDim", scale = value.Scale, offset = value.Offset }
	end
	if valueType == "UDim2" then
		return {
			__t = "UDim2",
			xScale = value.X.Scale,
			xOffset = value.X.Offset,
			yScale = value.Y.Scale,
			yOffset = value.Y.Offset,
		}
	end
	if valueType == "CFrame" then
		return { __t = "CFrame", c = { value:GetComponents() } }
	end
	if valueType == "Rect" then
		return { __t = "Rect", minX = value.Min.X, minY = value.Min.Y, maxX = value.Max.X, maxY = value.Max.Y }
	end
	if valueType == "NumberRange" then
		return { __t = "NumberRange", min = value.Min, max = value.Max }
	end
	if valueType == "BrickColor" then
		return { __t = "BrickColor", name = value.Name }
	end
	if valueType == "EnumItem" then
		return encodeEnum(value)
	end
	if valueType == "Font" then
		local out = { __t = "Font" }
		local okFamily, family = pcall(function()
			return value.Family
		end)
		if okFamily then
			out.family = family
		end
		local okWeight, weight = pcall(function()
			return value.Weight
		end)
		if okWeight and typeof(weight) == "EnumItem" then
			out.weight = encodeEnum(weight)
		end
		local okStyle, style = pcall(function()
			return value.Style
		end)
		if okStyle and typeof(style) == "EnumItem" then
			out.style = encodeEnum(style)
		end
		return out
	end
	if valueType == "NumberSequence" then
		local points = {}
		for _, kp in ipairs(value.Keypoints) do
			table.insert(points, { t = kp.Time, v = kp.Value, e = kp.Envelope })
		end
		return { __t = "NumberSequence", points = points }
	end
	if valueType == "ColorSequence" then
		local points = {}
		for _, kp in ipairs(value.Keypoints) do
			table.insert(points, { t = kp.Time, r = kp.Value.R, g = kp.Value.G, b = kp.Value.B })
		end
		return { __t = "ColorSequence", points = points }
	end
	if valueType == "table" then
		local out = {}
		for k, v in pairs(value) do
			if type(k) == "string" then
				local encoded = encodeValue(v)
				if encoded ~= nil then
					out[k] = encoded
				end
			end
		end
		return out
	end

	return nil
end

local function decodeValue(value)
	local valueType = typeof(value)
	if value == nil or valueType == "boolean" or valueType == "number" or valueType == "string" then
		return value
	end
	if valueType ~= "table" then
		return nil
	end

	local tag = value.__t
	if tag == "Color3" then
		return Color3.new(value.r or 0, value.g or 0, value.b or 0)
	end
	if tag == "Vector2" then
		return Vector2.new(value.x or 0, value.y or 0)
	end
	if tag == "Vector3" then
		return Vector3.new(value.x or 0, value.y or 0, value.z or 0)
	end
	if tag == "UDim" then
		return UDim.new(value.scale or 0, value.offset or 0)
	end
	if tag == "UDim2" then
		return UDim2.new(value.xScale or 0, value.xOffset or 0, value.yScale or 0, value.yOffset or 0)
	end
	if tag == "CFrame" then
		local components = value.c
		if type(components) == "table" then
			return CFrame.new(unpack(components))
		end
		return CFrame.new()
	end
	if tag == "Rect" then
		return Rect.new(value.minX or 0, value.minY or 0, value.maxX or 0, value.maxY or 0)
	end
	if tag == "NumberRange" then
		return NumberRange.new(value.min or 0, value.max or 0)
	end
	if tag == "BrickColor" then
		return BrickColor.new(tostring(value.name or "Medium stone grey"))
	end
	if tag == "Enum" then
		local enumType = value.enumType
		local name = value.name
		if type(enumType) == "string" and type(name) == "string" then
			local ok, item = pcall(function()
				return Enum[enumType][name]
			end)
			if ok then
				return item
			end
		end
		return nil
	end
	if tag == "Font" then
		local family = value.family
		local weight = decodeValue(value.weight)
		local style = decodeValue(value.style)
		if type(family) == "string" and family ~= "" then
			local ok, font = pcall(function()
				if weight ~= nil and style ~= nil then
					return Font.new(family, weight, style)
				end
				return Font.new(family)
			end)
			if ok then
				return font
			end
		end
		return nil
	end
	if tag == "NumberSequence" then
		local points = {}
		for _, p in ipairs(value.points or {}) do
			table.insert(points, NumberSequenceKeypoint.new(p.t or 0, p.v or 0, p.e or 0))
		end
		return NumberSequence.new(points)
	end
	if tag == "ColorSequence" then
		local points = {}
		for _, p in ipairs(value.points or {}) do
			table.insert(points, ColorSequenceKeypoint.new(p.t or 0, Color3.new(p.r or 0, p.g or 0, p.b or 0)))
		end
		return ColorSequence.new(points)
	end

	local out = {}
	for k, v in pairs(value) do
		if type(k) == "string" and k ~= "__t" then
			out[k] = decodeValue(v)
		end
	end
	return out
end

local function jsonEscape(s)
	return (tostring(s):gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t"))
end

local function isArray(t)
	if type(t) ~= "table" then
		return false
	end
	local n = 0
	for k in pairs(t) do
		if type(k) ~= "number" then
			return false
		end
		if k <= 0 or k % 1 ~= 0 then
			return false
		end
		if k > n then
			n = k
		end
	end
	for i = 1, n do
		if t[i] == nil then
			return false
		end
	end
	return true
end

local function prettyJson(value, depth)
	depth = depth or 0
	local indent = string.rep("  ", depth)
	local nextIndent = string.rep("  ", depth + 1)

	local t = typeof(value)
	if value == nil then
		return "null"
	end
	if t == "boolean" then
		return value and "true" or "false"
	end
	if t == "number" then
		return tostring(value)
	end
	if t == "string" then
		return "\"" .. jsonEscape(value) .. "\""
	end
	if t ~= "table" then
		return "\"<unsupported>\""
	end

	if isArray(value) then
		if #value == 0 then
			return "[]"
		end
		local parts = {}
		for i = 1, #value do
			table.insert(parts, nextIndent .. prettyJson(value[i], depth + 1))
		end
		return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
	end

	local keys = {}
	for k in pairs(value) do
		if type(k) == "string" then
			table.insert(keys, k)
		end
	end
	table.sort(keys, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
	if #keys == 0 then
		return "{}"
	end
	local parts = {}
	for _, k in ipairs(keys) do
		table.insert(parts, nextIndent .. "\"" .. jsonEscape(k) .. "\": " .. prettyJson(value[k], depth + 1))
	end
	return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

local function collectGuiRoots(root)
	local roots = {}
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("LayerCollector") or desc:IsA("GuiObject") then
			local p = desc.Parent
			local nested = false
			while p and p ~= root do
				if p:IsA("LayerCollector") or p:IsA("GuiObject") then
					nested = true
					break
				end
				p = p.Parent
			end
			if not nested then
				table.insert(roots, desc)
			end
		end
	end
	return roots
end

local function collectObjectRoots(root)
	local roots = {}
	for _, child in ipairs(root:GetChildren()) do
		if not isLuaScript(child) and not isUiInstance(child) then
			table.insert(roots, child)
		end
	end
	return roots
end

local GUI_PROPS_BY_ISA = {
	LayerCollector = { "Enabled", "DisplayOrder", "ZIndexBehavior", "ResetOnSpawn", "IgnoreGuiInset" },
	GuiObject = {
		"AnchorPoint",
		"AutomaticSize",
		"BackgroundColor3",
		"BackgroundTransparency",
		"BorderColor3",
		"BorderSizePixel",
		"ClipsDescendants",
		"LayoutOrder",
		"Position",
		"Rotation",
		"Size",
		"SizeConstraint",
		"Visible",
		"ZIndex",
	},
	TextLabel = {
		"Font",
		"FontFace",
		"RichText",
		"Text",
		"TextColor3",
		"TextScaled",
		"TextSize",
		"TextStrokeColor3",
		"TextStrokeTransparency",
		"TextTransparency",
		"TextTruncate",
		"TextWrapped",
		"TextXAlignment",
		"TextYAlignment",
	},
	GuiButton = { "AutoButtonColor", "Modal", "Selectable", "Selected", "Style" },
	TextBox = { "ClearTextOnFocus", "PlaceholderText", "PlaceholderColor3", "MultiLine", "TextEditable" },
	ImageLabel = { "Image", "ImageColor3", "ImageTransparency", "ScaleType", "SliceCenter" },
	ScrollingFrame = {
		"CanvasPosition",
		"CanvasSize",
		"AutomaticCanvasSize",
		"ScrollingDirection",
		"ElasticBehavior",
		"ScrollBarThickness",
		"ScrollBarImageColor3",
		"ScrollBarImageTransparency",
		"HorizontalScrollBarInset",
		"VerticalScrollBarInset",
		"VerticalScrollBarPosition",
		"BottomImage",
		"MidImage",
		"TopImage",
	},
	UIListLayout = { "FillDirection", "HorizontalAlignment", "VerticalAlignment", "SortOrder", "Padding" },
	UIGridLayout = {
		"CellPadding",
		"CellSize",
		"FillDirection",
		"FillDirectionMaxCells",
		"HorizontalAlignment",
		"VerticalAlignment",
		"SortOrder",
		"StartCorner",
	},
	UIPageLayout = {
		"Animated",
		"Circular",
		"EasingDirection",
		"EasingStyle",
		"GamepadInputEnabled",
		"ScrollWheelInputEnabled",
		"TouchInputEnabled",
		"TweenTime",
		"FillDirection",
		"Padding",
	},
	UIFlexLayout = {
		"Direction",
		"Wraps",
		"JustifyContent",
		"AlignItems",
		"AlignContent",
		"HorizontalAlignment",
		"VerticalAlignment",
		"Padding",
	},
	UIPadding = { "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom" },
	UICorner = { "CornerRadius" },
	UIStroke = { "ApplyStrokeMode", "Color", "Thickness", "Transparency", "LineJoin" },
	UIGradient = { "Enabled", "Color", "Transparency", "Rotation", "Offset" },
	UIScale = { "Scale" },
	UIAspectRatioConstraint = { "AspectRatio", "DominantAxis" },
	UITextSizeConstraint = { "MinTextSize", "MaxTextSize" },
}

local OBJECT_PROPS_BY_ISA = {
	BasePart = {
		"Anchored",
		"CanCollide",
		"CanQuery",
		"CanTouch",
		"CastShadow",
		"Color",
		"Material",
		"Reflectance",
		"Size",
		"Transparency",
		"CFrame",
	},
	MeshPart = { "MeshId", "TextureID" },
	SpecialMesh = { "MeshId", "TextureId", "MeshType", "Scale", "Offset" },
	SurfaceAppearance = { "ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap" },
	Decal = { "Texture", "Transparency", "Color3", "Face" },
	Texture = { "Texture", "Transparency", "Color3", "Face", "StudsPerTileU", "StudsPerTileV" },
	Attachment = { "CFrame", "Visible" },
	Light = { "Brightness", "Color", "Enabled", "Shadows" },
	PointLight = { "Range" },
	SpotLight = { "Range", "Angle", "Face" },
	Sound = { "SoundId", "Volume", "PlaybackSpeed", "Looped" },
}

local function readProps(instance, mode)
	local props = {}
	local function addFrom(list)
		for _, propName in ipairs(list) do
			if props[propName] ~= nil then
				continue
			end
			local ok, value = pcall(function()
				return instance[propName]
			end)
			if ok then
				local encoded = encodeValue(value)
				if encoded ~= nil then
					props[propName] = encoded
				end
			end
		end
	end

	if mode == "ui" then
		if instance:IsA("LayerCollector") then
			addFrom(GUI_PROPS_BY_ISA.LayerCollector)
		end
		if instance:IsA("GuiObject") then
			addFrom(GUI_PROPS_BY_ISA.GuiObject)
		end
		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			addFrom(GUI_PROPS_BY_ISA.TextLabel)
		end
		if instance:IsA("GuiButton") then
			addFrom(GUI_PROPS_BY_ISA.GuiButton)
		end
		if instance:IsA("TextBox") then
			addFrom(GUI_PROPS_BY_ISA.TextBox)
		end
		if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
			addFrom(GUI_PROPS_BY_ISA.ImageLabel)
		end
		if instance:IsA("ScrollingFrame") then
			addFrom(GUI_PROPS_BY_ISA.ScrollingFrame)
		end
		for className, list in pairs(GUI_PROPS_BY_ISA) do
			if instance.ClassName == className then
				addFrom(list)
			end
		end
	else
		for className, list in pairs(OBJECT_PROPS_BY_ISA) do
			if instance:IsA(className) then
				addFrom(list)
			end
		end
		if instance.ClassName == "Model" then
			addFrom({ "WorldPivot" })
		end
	end

	return props
end

local function readAttributes(instance)
	local attrs = {}
	local ok, map = pcall(function()
		return instance:GetAttributes()
	end)
	if ok and type(map) == "table" then
		for k, v in pairs(map) do
			if type(k) == "string" then
				local encoded = encodeValue(v)
				if encoded ~= nil then
					attrs[k] = encoded
				end
			end
		end
	end
	return attrs
end

local function serializeInstanceTree(instance, mode, childFilter)
	local node = {
		class = instance.ClassName,
		name = instance.Name,
		props = readProps(instance, mode),
		attrs = readAttributes(instance),
		children = {},
	}

	for _, child in ipairs(instance:GetChildren()) do
		if isLuaScript(child) then
			continue
		end
		if childFilter and not childFilter(child) then
			continue
		end
		table.insert(node.children, serializeInstanceTree(child, mode, childFilter))
	end

	table.sort(node.children, function(a, b)
		return string.lower(tostring(a.name)) < string.lower(tostring(b.name))
	end)

	return node
end

local function getPathSegments(obj)
	local segments = {}
	local current = obj
	while current and current ~= game do
		table.insert(segments, 1, current.Name)
		current = current.Parent
	end
	return segments
end

local function collectScripts(root)
	local results = {}
	for _, descendant in ipairs(root:GetDescendants()) do
		if isLuaScript(descendant) then
			local ok, src = pcall(function()
				return descendant.Source
			end)
			if ok and type(src) == "string" then
				table.insert(results, {
					path = getPathSegments(descendant),
					name = descendant.Name,
					class = descendant.ClassName,
					source = src,
				})
			end
		end
	end
	return results
end

local function buildPayload()
	local selectedRoots = {}
	for _, label in ipairs(orderedServices) do
		local provider = serviceProviders[label]
		local getter = getters[label]
		if provider and getter and getter() then
			table.insert(selectedRoots, {
				service = label,
				items = collectScripts(provider),
			})
		end
	end
	local includeUi = includeUiGetter and includeUiGetter() or false
	local includeObjects = includeObjectsGetter and includeObjectsGetter() or false
	return {
		studioPlaceName = game.Name,
		generatedAt = os.time(),
		outputFolderName = (outputInput.Text and #outputInput.Text > 0) and outputInput.Text or "output",
		exportFlags = {
			scripts = true,
			ui = includeUi,
			objects = includeObjects,
		},
		roots = selectedRoots,
	}
end

local function buildInstancesPayload()
	local instances = {}
	local includeUi = includeUiGetter and includeUiGetter() or false
	local includeObjects = includeObjectsGetter and includeObjectsGetter() or false
	if not includeUi and not includeObjects then
		return {
			studioPlaceName = game.Name,
			generatedAt = os.time(),
			outputFolderName = (outputInput.Text and #outputInput.Text > 0) and outputInput.Text or "output",
			exportFlags = {
				scripts = true,
				ui = false,
				objects = false,
			},
			instances = {},
		}
	end

	for _, label in ipairs(orderedServices) do
		local provider = serviceProviders[label]
		local getter = getters[label]
		if provider and getter and getter() then
			if includeUi then
				for _, rootInst in ipairs(collectGuiRoots(provider)) do
					table.insert(instances, {
						service = label,
						path = getPathSegments(rootInst),
						name = rootInst.Name,
						class = rootInst.ClassName,
						mode = "ui",
						tree = serializeInstanceTree(rootInst, "ui", nil),
					})
				end
			end
			if includeObjects then
				for _, rootInst in ipairs(collectObjectRoots(provider)) do
					table.insert(instances, {
						service = label,
						path = getPathSegments(rootInst),
						name = rootInst.Name,
						class = rootInst.ClassName,
						mode = "object",
						tree = serializeInstanceTree(rootInst, "object", function(child)
							return not isUiInstance(child)
						end),
					})
				end
			end
		end
	end

	return {
		studioPlaceName = game.Name,
		generatedAt = os.time(),
		outputFolderName = (outputInput.Text and #outputInput.Text > 0) and outputInput.Text or "output",
		exportFlags = {
			scripts = true,
			ui = includeUi,
			objects = includeObjects,
		},
		instances = instances,
	}
end

local function postToServer(url, payload)
	local json = HttpService:JSONEncode(payload)
	local response
	local ok, err = pcall(function()
		response = HttpService:PostAsync(url, json, Enum.HttpContentType.ApplicationJson, false)
	end)
	if not ok then
		return false, tostring(err)
	end
	return true, response
end

local function postToServerJson(url, payload)
	local ok, resp = postToServer(url, payload)
	if not ok then
		return false, resp
	end
	local decodedOk, decoded = pcall(function()
		return HttpService:JSONDecode(resp)
	end)
	if not decodedOk then
		return false, "Server did not return JSON: " .. tostring(decoded)
	end
	return true, decoded
end

local function deriveEndpointUrl(url, endpoint)
	local replaced
	local newUrl, n = string.gsub(url, "/upload/?$", "/" .. endpoint)
	replaced = n
	if replaced == 0 then
		newUrl = (string.sub(url, -1) == "/") and (url .. endpoint) or (url .. "/" .. endpoint)
	end
	return newUrl
end

local function getLocalIndex(studioPayload)
	local url = deriveEndpointUrl(serverInput.Text, "local_index")
	local selectedServices = {}
	for _, label in ipairs(orderedServices) do
		local getter = getters[label]
		if getter and getter() then
			table.insert(selectedServices, label)
		end
	end

	local studioPaths = nil
	if type(studioPayload) == "table" and type(studioPayload.roots) == "table" then
		studioPaths = {}
		for _, root in ipairs(studioPayload.roots) do
			if type(root) == "table" and type(root.items) == "table" then
				for _, item in ipairs(root.items) do
					if type(item) == "table" and type(item.path) == "table" then
						table.insert(studioPaths, item.path)
					end
				end
			end
		end
	end

	return postToServerJson(url, {
		outputFolderName = (outputInput.Text and #outputInput.Text > 0) and outputInput.Text or "output",
		services = selectedServices,
		studioPaths = studioPaths,
	})
end

local function getLocalIndexInstances(studioPayload)
	local url = deriveEndpointUrl(serverInput.Text, "local_index_instances")
	local selectedServices = {}
	for _, label in ipairs(orderedServices) do
		local getter = getters[label]
		if getter and getter() then
			table.insert(selectedServices, label)
		end
	end

	local studioPaths = nil
	if type(studioPayload) == "table" and type(studioPayload.instances) == "table" then
		studioPaths = {}
		for _, inst in ipairs(studioPayload.instances) do
			if type(inst) == "table" and type(inst.path) == "table" then
				table.insert(studioPaths, inst.path)
			end
		end
	end

	return postToServerJson(url, {
		outputFolderName = (outputInput.Text and #outputInput.Text > 0) and outputInput.Text or "output",
		services = selectedServices,
		studioPaths = studioPaths,
	})
end

local function getLocalSource(relPath)
	local url = deriveEndpointUrl(serverInput.Text, "local_get")
	return postToServerJson(url, {
		outputFolderName = (outputInput.Text and #outputInput.Text > 0) and outputInput.Text or "output",
		relPath = relPath,
	})
end

local function getLocalInstance(relPath)
	local url = deriveEndpointUrl(serverInput.Text, "local_get_instances")
	return postToServerJson(url, {
		outputFolderName = (outputInput.Text and #outputInput.Text > 0) and outputInput.Text or "output",
		relPath = relPath,
	})
end

local function makeKey(service, pathSegments)
	if type(pathSegments) ~= "table" then
		return tostring(service) .. "|"
	end
	return tostring(service) .. "|" .. table.concat(pathSegments, "\0")
end

local function makeEntryKey(entryType, service, pathSegments)
	return tostring(entryType) .. "|" .. makeKey(service, pathSegments)
end

local function buildStudioSourceMap(payload)
	local map = {}
	for _, root in ipairs(payload.roots or {}) do
		for _, item in ipairs(root.items or {}) do
			local key = makeKey(root.service, item.path)
			map[key] = item.source
		end
	end
	return map
end

-- Chunking support to avoid HttpService 1MB limit
local function flattenEntries(roots)
    local entries = {}
    for _, root in ipairs(roots) do
        for _, item in ipairs(root.items or {}) do
            table.insert(entries, { service = root.service, item = item })
        end
    end
    return entries
end

local function groupEntriesByService(entries)
    local byService = {}
    for _, e in ipairs(entries) do
        local list = byService[e.service]
        if not list then
            list = {}
            byService[e.service] = list
        end
        table.insert(list, e.item)
    end
    local roots = {}
    for service, items in pairs(byService) do
        table.insert(roots, { service = service, items = items })
    end
    return roots
end

local function buildChunkPayload(basePayload, entries)
    return {
        studioPlaceName = basePayload.studioPlaceName,
        generatedAt = basePayload.generatedAt,
        outputFolderName = basePayload.outputFolderName,
        roots = groupEntriesByService(entries),
    }
end

local function buildSkippedPayload(basePayload, skipped)
    return {
        studioPlaceName = basePayload.studioPlaceName,
        generatedAt = basePayload.generatedAt,
        outputFolderName = basePayload.outputFolderName,
        skipped = skipped,
    }
end

local function postSkipped(url, basePayload, skipped)
    if #skipped == 0 then return true, nil end
    local skippedUrl, replaced = string.gsub(url, "/upload/?$", "/skipped")
    if replaced == 0 then
        skippedUrl = (string.sub(url, -1) == "/") and (url .. "skipped") or (url .. "/skipped")
    end
    local payload = buildSkippedPayload(basePayload, skipped)
    return postToServer(skippedUrl, payload)
end

local function postInChunks(url, basePayload)
    local entries = flattenEntries(basePayload.roots or {})
    local total = #entries
    if total == 0 then
        return true, "No scripts"
    end

    local maxBytes = 900 * 1024 -- stay under 1MB
    local maxEntryBytes = 800 * 1024
    local skipped = {}
    local i = 1
    local lastResp = nil
    while i <= total do
        local chunk = {}
        local j = i
        while j <= total do
            local candidate = entries[j]
            -- Pre-test single entry size/encodability
            local singleOk, singleJson = pcall(function()
                return HttpService:JSONEncode(buildChunkPayload(basePayload, { candidate }))
            end)
            if not singleOk or #singleJson > maxEntryBytes then
                table.insert(skipped, {
                    service = candidate.service,
                    name = candidate.item.name,
                    class = candidate.item.class,
                    path = candidate.item.path,
                    reason = singleOk and "entry too large" or "json encode failed",
                })
                j += 1
            else
                table.insert(chunk, candidate)
                local testPayload = buildChunkPayload(basePayload, chunk)
                local okEncode, encoded = pcall(function()
                    return HttpService:JSONEncode(testPayload)
                end)
                if not okEncode then
                    -- remove and skip this one
                    table.remove(chunk, #chunk)
                    table.insert(skipped, {
                        service = candidate.service,
                        name = candidate.item.name,
                        class = candidate.item.class,
                        path = candidate.item.path,
                        reason = "json encode failed",
                    })
                    j += 1
                elseif #encoded > maxBytes then
					-- if first entry already exceeds limit, send it alone
                    if j == i then
                        chunk = { candidate }
                        j += 1
                    else
                        table.remove(chunk, #chunk)
                    end
                    break
                else
                    j += 1
                end
            end
        end

        local payload = buildChunkPayload(basePayload, chunk)
        local ok, resp = postToServer(url, payload)
        lastResp = resp
        if not ok then
            return false, resp
        end

        -- progress update
        local sentCount = j - 1
        if sentCount < i then sentCount = i end
        local alpha = math.clamp(sentCount / total, 0, 1)
        setProgressAlpha(alpha)
        i = sentCount + 1
    end
    -- send skipped metadata if any
    postSkipped(url, basePayload, skipped)
    return true, lastResp
end

local function postInChunksJson(url, basePayload, onProgress)
	local entries = flattenEntries(basePayload.roots or {})
	local total = #entries
	if total == 0 then
		return true, { ok = true, changes = {}, missingLocal = {}, skippedLarge = {}, skippedRequest = {} }
	end

	local maxBytes = 900 * 1024 -- stay under 1MB
	local maxEntryBytes = 800 * 1024
	local skippedRequest = {}

	local allChanges = {}
	local allMissing = {}
	local allSkippedLarge = {}

	local i = 1
	while i <= total do
		local chunk = {}
		local j = i
		while j <= total do
			local candidate = entries[j]
			local singleOk, singleJson = pcall(function()
				return HttpService:JSONEncode(buildChunkPayload(basePayload, { candidate }))
			end)
			if not singleOk or #singleJson > maxEntryBytes then
				table.insert(skippedRequest, {
					service = candidate.service,
					name = candidate.item.name,
					class = candidate.item.class,
					path = candidate.item.path,
					reason = singleOk and "entry too large" or "json encode failed",
				})
				j += 1
			else
				table.insert(chunk, candidate)
				local okEncode, encoded = pcall(function()
					return HttpService:JSONEncode(buildChunkPayload(basePayload, chunk))
				end)
				if not okEncode then
					table.remove(chunk, #chunk)
					table.insert(skippedRequest, {
						service = candidate.service,
						name = candidate.item.name,
						class = candidate.item.class,
						path = candidate.item.path,
						reason = "json encode failed",
					})
					j += 1
				elseif #encoded > maxBytes then
					if j == i then
						chunk = { candidate }
						j += 1
					else
						table.remove(chunk, #chunk)
					end
					break
				else
					j += 1
				end
			end
		end

		if #chunk > 0 then
			local payload = buildChunkPayload(basePayload, chunk)
			local ok, data = postToServerJson(url, payload)
			if not ok then
				return false, data
			end
			if type(data) ~= "table" or data.ok ~= true then
				return false, "Failed: invalid response"
			end

			for _, change in ipairs(data.changes or {}) do
				table.insert(allChanges, change)
			end
			for _, miss in ipairs(data.missingLocal or {}) do
				table.insert(allMissing, miss)
			end
			for _, skip in ipairs(data.skippedLarge or {}) do
				table.insert(allSkippedLarge, skip)
			end
		end

		local sentCount = j - 1
		if sentCount < i then
			sentCount = i
		end
		if onProgress then
			onProgress(math.clamp(sentCount / total, 0, 1))
		end
		i = sentCount + 1
	end

	return true, {
		ok = true,
		changes = allChanges,
		missingLocal = allMissing,
		skippedLarge = allSkippedLarge,
		skippedRequest = skippedRequest,
	}
end

local function buildInstancesChunkPayload(basePayload, instances)
	return {
		studioPlaceName = basePayload.studioPlaceName,
		generatedAt = basePayload.generatedAt,
		outputFolderName = basePayload.outputFolderName,
		instances = instances,
	}
end

local function postInstancesInChunks(url, basePayload, onProgress)
	local instances = basePayload.instances or {}
	local total = #instances
	if total == 0 then
		return true, { ok = true, wrote = 0, skippedRequest = {} }
	end

	local maxBytes = 900 * 1024 -- stay under 1MB
	local maxEntryBytes = 800 * 1024
	local skippedRequest = {}

	local i = 1
	local wrote = 0
	while i <= total do
		local chunk = {}
		local j = i
		while j <= total do
			local candidate = instances[j]
			local singleOk, singleJson = pcall(function()
				return HttpService:JSONEncode(buildInstancesChunkPayload(basePayload, { candidate }))
			end)
			if not singleOk or #singleJson > maxEntryBytes then
				table.insert(skippedRequest, {
					service = candidate.service,
					name = candidate.name,
					class = candidate.class,
					path = candidate.path,
					reason = singleOk and "entry too large" or "json encode failed",
				})
				j += 1
			else
				table.insert(chunk, candidate)
				local okEncode, encoded = pcall(function()
					return HttpService:JSONEncode(buildInstancesChunkPayload(basePayload, chunk))
				end)
				if not okEncode then
					table.remove(chunk, #chunk)
					table.insert(skippedRequest, {
						service = candidate.service,
						name = candidate.name,
						class = candidate.class,
						path = candidate.path,
						reason = "json encode failed",
					})
					j += 1
				elseif #encoded > maxBytes then
					if j == i then
						chunk = { candidate }
						j += 1
					else
						table.remove(chunk, #chunk)
					end
					break
				else
					j += 1
				end
			end
		end

		if #chunk > 0 then
			local payload = buildInstancesChunkPayload(basePayload, chunk)
			local ok, data = postToServerJson(url, payload)
			if not ok then
				return false, data
			end
			if type(data) ~= "table" or data.ok ~= true then
				return false, "Failed: invalid response"
			end
			wrote += (#chunk)
		end

		local sentCount = j - 1
		if sentCount < i then
			sentCount = i
		end
		if onProgress then
			onProgress(math.clamp(sentCount / total, 0, 1))
		end
		i = sentCount + 1
	end

	return true, { ok = true, wrote = wrote, skippedRequest = skippedRequest }
end

local function postInstancesInChunksJson(url, basePayload, onProgress)
	local instances = basePayload.instances or {}
	local total = #instances
	if total == 0 then
		return true, { ok = true, changes = {}, missingLocal = {}, skippedLarge = {}, skippedRequest = {} }
	end

	local maxBytes = 900 * 1024 -- stay under 1MB
	local maxEntryBytes = 800 * 1024
	local skippedRequest = {}

	local allChanges = {}
	local allMissing = {}
	local allSkippedLarge = {}

	local i = 1
	while i <= total do
		local chunk = {}
		local j = i
		while j <= total do
			local candidate = instances[j]
			local singleOk, singleJson = pcall(function()
				return HttpService:JSONEncode(buildInstancesChunkPayload(basePayload, { candidate }))
			end)
			if not singleOk or #singleJson > maxEntryBytes then
				table.insert(skippedRequest, {
					service = candidate.service,
					name = candidate.name,
					class = candidate.class,
					path = candidate.path,
					reason = singleOk and "entry too large" or "json encode failed",
				})
				j += 1
			else
				table.insert(chunk, candidate)
				local okEncode, encoded = pcall(function()
					return HttpService:JSONEncode(buildInstancesChunkPayload(basePayload, chunk))
				end)
				if not okEncode then
					table.remove(chunk, #chunk)
					table.insert(skippedRequest, {
						service = candidate.service,
						name = candidate.name,
						class = candidate.class,
						path = candidate.path,
						reason = "json encode failed",
					})
					j += 1
				elseif #encoded > maxBytes then
					if j == i then
						chunk = { candidate }
						j += 1
					else
						table.remove(chunk, #chunk)
					end
					break
				else
					j += 1
				end
			end
		end

		if #chunk > 0 then
			local payload = buildInstancesChunkPayload(basePayload, chunk)
			local ok, data = postToServerJson(url, payload)
			if not ok then
				return false, data
			end
			if type(data) ~= "table" or data.ok ~= true then
				return false, "Failed: invalid response"
			end

			for _, change in ipairs(data.changes or {}) do
				table.insert(allChanges, change)
			end
			for _, miss in ipairs(data.missingLocal or {}) do
				table.insert(allMissing, miss)
			end
			for _, skip in ipairs(data.skippedLarge or {}) do
				table.insert(allSkippedLarge, skip)
			end
		end

		local sentCount = j - 1
		if sentCount < i then
			sentCount = i
		end
		if onProgress then
			onProgress(math.clamp(sentCount / total, 0, 1))
		end
		i = sentCount + 1
	end

	return true, {
		ok = true,
		changes = allChanges,
		missingLocal = allMissing,
		skippedLarge = allSkippedLarge,
		skippedRequest = skippedRequest,
	}
end

-- Review & Sync (Local -> Studio)
local reviewState = {
	entries = {},
	rowByIndex = {},
	selectedIndex = nil,
	selectedKey = nil,
	diffMode = "local",
	isRefreshing = false,
	treeExpanded = {},
	summaryMissing = 0,
	summarySkipped = 0,
	summaryReqSkipped = 0,
}

local function countSelectedReviewEntries()
	local selected = 0
	for _, entry in ipairs(reviewState.entries) do
		if entry.selected then
			selected += 1
		end
	end
	return selected, #reviewState.entries
end

updateReviewSelectionUi = function()
	local selectedCount, totalCount = countSelectedReviewEntries()
	local missing = tonumber(reviewState.summaryMissing) or 0
	local skipped = tonumber(reviewState.summarySkipped) or 0
	local reqSkipped = tonumber(reviewState.summaryReqSkipped) or 0

	reviewSummary.Text = string.format(
		"%d local changes • %d missing • %d skipped • %d req-skipped • %d selected",
		totalCount,
		missing,
		skipped,
		reqSkipped,
		selectedCount
	)

	reviewSyncBtn.Text = (selectedCount > 0) and ("Sync Selected (" .. tostring(selectedCount) .. ")") or "Sync Selected"

	local canSync = reviewUiEnabled and (selectedCount > 0)
	reviewSyncBtn.Active = canSync
	reviewSyncBtn.BackgroundColor3 = canSync and ACCENT or DARK_PANEL
	reviewSyncBtn.TextTransparency = canSync and 0 or 0.35
end

local function findEntryIndexByKey(key)
	if not key then
		return nil
	end
	for i, entry in ipairs(reviewState.entries) do
		if entry.key == key then
			return i
		end
	end
	return nil
end

local function applyDiffMode(mode)
	reviewState.diffMode = mode

	local MAX_DIFF_PREVIEW_CHARS = 190000
	local function toPreviewText(text)
		text = tostring(text or "")
		local n = #text
		if n <= MAX_DIFF_PREVIEW_CHARS then
			return text
		end
		local suffix = "\n\n[Preview truncated: " .. tostring(n) .. " chars]"
		local keep = MAX_DIFF_PREVIEW_CHARS - #suffix
		if keep < 0 then
			keep = 0
		end
		return string.sub(text, 1, keep) .. suffix
	end

	local entry = reviewState.entries[reviewState.selectedIndex]
	if entry then
		diffHeader.Text = entry.displayName or "Diff"
		if mode == "studio" then
			if entry.entryType == "instance" and entry.studioTree ~= nil then
				diffText.Text = toPreviewText(prettyJson(entry.studioTree))
			else
				diffText.Text = toPreviewText(entry.studioSource or "")
			end
		else
			if entry.localSource ~= nil then
				diffText.Text = toPreviewText(entry.localSource or "")
			elseif entry.relPath and diffModal.Visible then
				diffText.Text = "Loading local file..."
				task.spawn(function()
					local ok, data
					if entry.entryType == "instance" then
						ok, data = getLocalInstance(entry.relPath)
					else
						ok, data = getLocalSource(entry.relPath)
					end

					if ok and type(data) == "table" and data.ok == true then
						if entry.entryType == "instance" then
							entry.localTree = data.tree
							entry.localSource = data.pretty or (data.tree and prettyJson(data.tree)) or ""
						else
							entry.localSource = data.source or ""
						end
						if reviewState.entries[reviewState.selectedIndex] == entry and reviewState.diffMode == "local" and diffModal.Visible then
							diffText.Text = toPreviewText(entry.localSource)
						end
					elseif reviewState.entries[reviewState.selectedIndex] == entry and reviewState.diffMode == "local" and diffModal.Visible then
						diffText.Text = "Failed to load local file."
					end
				end)
			else
				diffText.Text = ""
			end
		end
	else
		diffHeader.Text = "Diff"
		diffText.Text = ""
	end

	local isLocal = (mode ~= "studio")
	diffLocalTab.BackgroundColor3 = isLocal and ACCENT or DARK_BG
	diffStudioTab.BackgroundColor3 = isLocal and DARK_BG or ACCENT
end

local function setDiffOpen(open, animate)
	if open then
		diffModal.Visible = true
		if animate then
			diffModal.GroupTransparency = 1
			tweenPage(diffModal, { GroupTransparency = 0 }, 0.18)
		else
			diffModal.GroupTransparency = 0
		end
	else
		if not diffModal.Visible then
			return
		end
		if animate then
			local tween = tweenPage(diffModal, { GroupTransparency = 1 }, 0.14)
			once(tween.Completed, function()
				diffModal.Visible = false
				diffModal.GroupTransparency = 1
			end)
		else
			diffModal.Visible = false
			diffModal.GroupTransparency = 1
		end
	end
end

local function setNodeExpanded(nodeId, expanded)
	if nodeId == nil then
		return
	end
	reviewState.treeExpanded[nodeId] = expanded == true
end

local function isNodeExpanded(nodeId)
	if nodeId == nil then
		return false
	end
	local v = reviewState.treeExpanded[nodeId]
	if v == nil then
		return true
	end
	return v == true
end

local function clearReviewListUi()
	for _, child in ipairs(reviewList:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	reviewState.rowByIndex = {}
end


local function clearReviewRows()
	for _, child in ipairs(reviewList:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	reviewState.entries = {}
	reviewState.rowByIndex = {}
	reviewState.selectedIndex = nil
	reviewState.selectedKey = nil
	reviewState.summaryMissing = 0
	reviewState.summarySkipped = 0
	reviewState.summaryReqSkipped = 0
	setDiffOpen(false, false)
	applyDiffMode(reviewState.diffMode)
	updateReviewSelectionUi()
end

local function setSelectedReviewIndex(index)
	reviewState.selectedIndex = index
	for i, row in pairs(reviewState.rowByIndex) do
		row.BackgroundColor3 = (i == index) and HOVER_BG or DARK_BG
	end
	local entry = reviewState.entries[index]
	reviewState.selectedKey = entry and entry.key or nil
	applyDiffMode(reviewState.diffMode)
end

local function createReviewRow(entry, index)
	local row = Instance.new("TextButton")
	row.Name = "Row"
	row.Size = UDim2.new(1, -12, 0, 32)
	row.BackgroundColor3 = DARK_BG
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	row.LayoutOrder = index
	row.Parent = reviewList

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local statusTag = Instance.new("TextLabel")
	statusTag.Name = "Status"
	statusTag.Size = UDim2.fromOffset(18, 18)
	statusTag.Position = UDim2.fromOffset(8, 7)
	statusTag.BackgroundColor3 = ACCENT
	statusTag.BorderSizePixel = 0
	statusTag.Text = entry.kind or "M"
	statusTag.TextColor3 = TEXT
	statusTag.Font = Enum.Font.GothamBold
	statusTag.TextSize = 12
	statusTag.Parent = row

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 6)
	statusCorner.Parent = statusTag

	local check = Instance.new("Frame")
	check.Name = "Select"
	check.Size = UDim2.fromOffset(18, 18)
	check.Position = UDim2.new(1, -26, 0, 7)
	check.BackgroundColor3 = DARK_PANEL
	check.BorderSizePixel = 0
	check.Parent = row

	local checkCorner = Instance.new("UICorner")
	checkCorner.CornerRadius = UDim.new(0, 6)
	checkCorner.Parent = check

	local tick = Instance.new("Frame")
	tick.Name = "Tick"
	tick.Size = UDim2.fromScale(1, 1)
	tick.BackgroundColor3 = ACCENT
	tick.BackgroundTransparency = entry.selected and 0 or 1
	tick.BorderSizePixel = 0
	tick.Parent = check

	local tickCorner = Instance.new("UICorner")
	tickCorner.CornerRadius = UDim.new(0, 6)
	tickCorner.Parent = tick

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Label"
	textLabel.Size = UDim2.new(1, -60, 1, 0)
	textLabel.Position = UDim2.fromOffset(32, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = entry.displayName or "Changed Script"
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextColor3 = TEXT
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextSize = 13
	textLabel.TextTruncate = Enum.TextTruncate.AtEnd
	textLabel.Parent = row

	local function updateVisuals(instant)
		local tickTransparency = entry.selected and 0 or 1
		if instant then
			tick.BackgroundTransparency = tickTransparency
		else
			TweenService:Create(tick, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = tickTransparency,
			}):Play()
		end
	end

	row.MouseButton1Click:Connect(function()
		entry.selected = not entry.selected
		updateVisuals(false)
		setSelectedReviewIndex(index)
		updateReviewSelectionUi()
	end)

	row.MouseEnter:Connect(function()
		if reviewState.selectedIndex ~= index then
			TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = HOVER_BG,
			}):Play()
		end
	end)

	row.MouseLeave:Connect(function()
		if reviewState.selectedIndex ~= index then
			TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = DARK_BG,
			}):Play()
		end
	end)

	updateVisuals(true)
	return row
end

local function buildReviewTree()
	local root = { id = "", name = "root", depth = 0, children = {}, files = {}, countM = 0, countA = 0 }

	local function getChild(parent, name)
		local child = parent.children[name]
		if not child then
			local id = (parent.id == "" and name) or (parent.id .. "/" .. name)
			child = { id = id, name = name, children = {}, files = {}, countM = 0, countA = 0 }
			parent.children[name] = child
		end
		return child
	end

	for i, entry in ipairs(reviewState.entries) do
		local pathSegments = entry.path
		if type(pathSegments) == "table" and #pathSegments >= 1 then
			local current = root
			for segIndex = 1, (#pathSegments - 1) do
				current = getChild(current, tostring(pathSegments[segIndex]))
				if entry.kind == "A" then
					current.countA += 1
				else
					current.countM += 1
				end
			end
			current.files[entry.key] = i
		end
	end

	return root
end

local function renderReviewTree(selectKey)
	if reviewState.entries == nil then
		return
	end

	local tree = buildReviewTree()
	clearReviewListUi()

	local function sortKeys(map)
		local keys = {}
		for k in pairs(map) do
			table.insert(keys, k)
		end
		table.sort(keys, function(a, b)
			return string.lower(a) < string.lower(b)
		end)
		return keys
	end

	local function kindColor(kind)
		if kind == "A" then
			return ADD_COLOR
		end
		return ACCENT
	end

	local function folderBadgeText(node)
		local parts = {}
		if node.countM and node.countM > 0 then
			table.insert(parts, "M" .. tostring(node.countM))
		end
		if node.countA and node.countA > 0 then
			table.insert(parts, "A" .. tostring(node.countA))
		end
		return table.concat(parts, " ")
	end

	local function createFolderRow(node, depth, layoutOrder)
		local row = Instance.new("TextButton")
		row.Name = "FolderRow"
		row.Size = UDim2.new(1, -12, 0, 30)
		row.BackgroundColor3 = TREE_BG
		row.BorderSizePixel = 0
		row.AutoButtonColor = false
		row.Text = ""
		row.LayoutOrder = layoutOrder
		row.Parent = reviewList

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = row

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = (node.countM == 0 and (node.countA or 0) > 0) and ADD_COLOR or ACCENT
		stroke.Transparency = 0.75
		stroke.Parent = row

		local indent = 10 + (depth * 14)
		local highlightColor = (node.countM == 0 and (node.countA or 0) > 0) and ADD_COLOR or ACCENT

		local caret = Instance.new("ImageLabel")
		caret.Name = "Caret"
		caret.Size = UDim2.fromOffset(14, 14)
		caret.Position = UDim2.fromOffset(indent + 2, 8)
		caret.BackgroundTransparency = 1
		caret.Image = isNodeExpanded(node.id) and ICON_ARROW_EXPANDED or ICON_ARROW_COLLAPSED
		caret.ImageColor3 = highlightColor
		caret.ImageTransparency = 0
		caret.Parent = row

		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.fromOffset(16, 16)
		icon.Position = UDim2.fromOffset(indent + 18, 7)
		icon.BackgroundTransparency = 1
		icon.Image = (depth == 0) and serviceIcon(node.name) or ICON_FOLDER
		icon.ImageColor3 = (depth == 0) and highlightColor or TEXT
		icon.ImageTransparency = (depth == 0) and 0 or 0.1
		icon.Parent = row

		local labelX = indent + 18 + 18
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, -120 - labelX, 1, 0)
		label.Position = UDim2.fromOffset(labelX, 0)
		label.BackgroundTransparency = 1
		label.Text = node.name
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = TEXT
		label.Font = Enum.Font.GothamBold
		label.TextSize = 13
		label.TextTruncate = Enum.TextTruncate.AtEnd
		label.Parent = row

		local badge = Instance.new("TextLabel")
		badge.Name = "Badge"
		badge.Size = UDim2.fromOffset(72, 18)
		badge.Position = UDim2.new(1, -82, 0, 6)
		badge.BackgroundColor3 = (node.countM == 0 and (node.countA or 0) > 0) and ADD_COLOR or DARK_PANEL
		badge.BorderSizePixel = 0
		badge.Text = folderBadgeText(node)
		badge.TextColor3 = TEXT
		badge.Font = Enum.Font.GothamBold
		badge.TextSize = 12
		badge.TextXAlignment = Enum.TextXAlignment.Center
		badge.Parent = row

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 8)
		badgeCorner.Parent = badge

		local function updateCaret()
			caret.Image = isNodeExpanded(node.id) and ICON_ARROW_EXPANDED or ICON_ARROW_COLLAPSED
		end

		row.MouseEnter:Connect(function()
			TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = TREE_BG_HOVER,
			}):Play()
		end)
		row.MouseLeave:Connect(function()
			TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = TREE_BG,
			}):Play()
		end)

		row.MouseButton1Click:Connect(function()
			setNodeExpanded(node.id, not isNodeExpanded(node.id))
			updateCaret()
			renderReviewTree(reviewState.selectedKey)
		end)
	end

	local function createLeafRow(entry, entryIndex, depth, layoutOrder)
		local row = Instance.new("TextButton")
		row.Name = "LeafRow"
		row.Size = UDim2.new(1, -12, 0, 32)
		row.BackgroundColor3 = DARK_BG
		row.BorderSizePixel = 0
		row.AutoButtonColor = false
		row.Text = ""
		row.LayoutOrder = layoutOrder
		row.Parent = reviewList

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = row

		local indent = 10 + (depth * 14)

		local statusTag = Instance.new("TextLabel")
		statusTag.Name = "Status"
		statusTag.Size = UDim2.fromOffset(18, 18)
		statusTag.Position = UDim2.fromOffset(indent, 7)
		statusTag.BackgroundColor3 = kindColor(entry.kind)
		statusTag.BorderSizePixel = 0
		statusTag.Text = entry.kind or "M"
		statusTag.TextColor3 = TEXT
		statusTag.Font = Enum.Font.GothamBold
		statusTag.TextSize = 12
		statusTag.Parent = row

		local statusCorner = Instance.new("UICorner")
		statusCorner.CornerRadius = UDim.new(0, 6)
		statusCorner.Parent = statusTag

		local check = Instance.new("Frame")
		check.Name = "Select"
		check.Size = UDim2.fromOffset(18, 18)
		check.Position = UDim2.new(1, -26, 0, 7)
		check.BackgroundColor3 = DARK_PANEL
		check.BorderSizePixel = 0
		check.Parent = row

		local checkCorner = Instance.new("UICorner")
		checkCorner.CornerRadius = UDim.new(0, 6)
		checkCorner.Parent = check

		local tick = Instance.new("Frame")
		tick.Name = "Tick"
		tick.Size = UDim2.fromScale(1, 1)
		tick.BackgroundColor3 = kindColor(entry.kind)
		tick.BackgroundTransparency = entry.selected and 0 or 1
		tick.BorderSizePixel = 0
		tick.Parent = check

		local tickCorner = Instance.new("UICorner")
		tickCorner.CornerRadius = UDim.new(0, 6)
		tickCorner.Parent = tick

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Label"
		textLabel.Size = UDim2.new(1, -60 - indent, 1, 0)
		textLabel.Position = UDim2.fromOffset(indent + 26, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = tostring(entry.name or entry.displayName or "Script")
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextColor3 = TEXT
		textLabel.Font = Enum.Font.Gotham
		textLabel.TextSize = 13
		textLabel.TextTruncate = Enum.TextTruncate.AtEnd
		textLabel.Parent = row

		local function updateVisuals(instant)
			local tickTransparency = entry.selected and 0 or 1
			if instant then
				tick.BackgroundTransparency = tickTransparency
			else
				TweenService:Create(tick, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundTransparency = tickTransparency,
				}):Play()
			end
		end

	row.MouseButton1Click:Connect(function()
		entry.selected = not entry.selected
		updateVisuals(false)
		setSelectedReviewIndex(entryIndex)
		updateReviewSelectionUi()
	end)

		row.MouseEnter:Connect(function()
			if reviewState.selectedIndex ~= entryIndex then
				TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = HOVER_BG,
				}):Play()
			end
		end)

		row.MouseLeave:Connect(function()
			if reviewState.selectedIndex ~= entryIndex then
				TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = DARK_BG,
				}):Play()
			end
		end)

		updateVisuals(true)
		reviewState.rowByIndex[entryIndex] = row
	end

	local function addRows(node, depth, layoutOrder)
		for _, childName in ipairs(sortKeys(node.children)) do
			local child = node.children[childName]
			createFolderRow(child, depth, layoutOrder)
			layoutOrder += 1
			if isNodeExpanded(child.id) then
				layoutOrder = addRows(child, depth + 1, layoutOrder)
			end
		end

		local fileKeys = {}
		for k in pairs(node.files) do
			table.insert(fileKeys, k)
		end
		table.sort(fileKeys, function(a, b)
			local ia = node.files[a]
			local ib = node.files[b]
			local ea = reviewState.entries[ia]
			local eb = reviewState.entries[ib]
			return string.lower(tostring(ea and ea.name or "")) < string.lower(tostring(eb and eb.name or ""))
		end)
		for _, fileKey in ipairs(fileKeys) do
			local entryIndex = node.files[fileKey]
			local entry = reviewState.entries[entryIndex]
			if entry then
				createLeafRow(entry, entryIndex, depth, layoutOrder)
				layoutOrder += 1
			end
		end

		return layoutOrder
	end

	-- Default-expand service nodes so the tree is useful immediately
	addRows(tree, 0, 1)

	local idx = findEntryIndexByKey(selectKey) or (reviewState.entries[1] and 1) or nil
	if idx then
		setSelectedReviewIndex(idx)
	end
end

local function getInstanceFromPathSegments(pathSegments)
	if type(pathSegments) ~= "table" or #pathSegments == 0 then
		return nil
	end

	local first = pathSegments[1]
	local current = nil
	local ok, service = pcall(function()
		return game:GetService(first)
	end)
	if ok then
		current = service
	else
		current = game:FindFirstChild(first)
	end
	if not current then
		return nil
	end

	for i = 2, #pathSegments do
		current = current:FindFirstChild(pathSegments[i])
		if not current then
			return nil
		end
	end
	return current
end

local function refreshReview()
	if RunService:IsRunning() then
		setReviewStatus("Disabled during Play mode.")
		return
	end
	if not HttpService.HttpEnabled then
		setReviewStatus("Enable HTTP requests in Studio Settings first.")
		return
	end
	if reviewState.isRefreshing then
		return
	end
	reviewState.isRefreshing = true

	local okRun, err = pcall(function()
		local prevSelectedByKey = {}
		local prevSelectedKey = nil
		do
			for _, entry in ipairs(reviewState.entries) do
				if entry.selected and entry.key then
					prevSelectedByKey[entry.key] = true
				end
			end
			local prev = reviewState.entries[reviewState.selectedIndex]
			if prev and prev.key then
				prevSelectedKey = prev.key
			end
		end

		clearReviewRows()
		setReviewStatus("Scanning Studio...")
		setReviewProgressAlpha(0.15)

		local payload = buildPayload()
		local studioSourceByKey = buildStudioSourceMap(payload)
		local instancePayload = buildInstancesPayload()
		local studioInstanceTreeByKey = {}
		for _, inst in ipairs(instancePayload.instances or {}) do
			local k = makeKey(inst.service, inst.path)
			studioInstanceTreeByKey[k] = inst.tree
		end

		setReviewStatus("Checking local output...")
		setReviewProgressAlpha(0.5)

		local diffUrl = deriveEndpointUrl(serverInput.Text, "diff")
		local ok, data = postInChunksJson(diffUrl, payload, function(alpha)
			setReviewProgressAlpha(0.5 + (alpha * 0.25))
		end)
		if not ok then
			error(tostring(data))
		end
		if type(data) ~= "table" or data.ok ~= true then
			error("invalid response")
		end

		local changes = data.changes or {}
		local missing = data.missingLocal or {}
		local skipped = data.skippedLarge or {}
		local skippedReq = data.skippedRequest or {}

		local reviewKeys = {}

		for i, change in ipairs(changes) do
			local service = change.service
			local pathSegments = change.path
			local studioKey = makeKey(service, pathSegments)
			local displayPath = ""
			if type(pathSegments) == "table" then
				displayPath = table.concat(pathSegments, "/")
			end
			local key = makeKey(service, pathSegments)
			local entry = {
				entryType = "script",
				kind = "M",
				service = service,
				class = change.class,
				name = change.name,
				path = pathSegments,
				file = change.file,
				localSource = change.localSource,
				studioSource = studioSourceByKey[studioKey] or "",
				key = key,
				selected = (prevSelectedByKey[key] ~= nil) and prevSelectedByKey[key] or false,
				displayName = (displayPath ~= "" and displayPath) or tostring(change.name),
			}
			reviewKeys[key] = true
			reviewState.entries[i] = entry
		end

		local function scriptNameFromLuaFilename(filename)
			if type(filename) ~= "string" then
				return nil
			end
			local lower = string.lower(filename)
			if string.sub(lower, -11) == ".server.lua" then
				return string.sub(filename, 1, -12)
			end
			if string.sub(lower, -10) == ".local.lua" then
				return string.sub(filename, 1, -11)
			end
			if string.sub(lower, -11) == ".module.lua" then
				return string.sub(filename, 1, -12)
			end
			if string.sub(lower, -4) == ".lua" then
				return string.sub(filename, 1, -5)
			end
			return filename
		end

		local function resolveAmbiguousLocalLuaPathSegments(localItem, studioSourceByKey)
			if type(localItem) ~= "table" then
				return nil
			end
			local relPath = localItem.relPath
			if type(relPath) ~= "string" or relPath == "" then
				return nil
			end

			local parts = string.split(relPath, "/")
			if #parts < 2 then
				return nil
			end
			local serviceFromRel = parts[1]
			local filename = parts[#parts]
			local scriptName = scriptNameFromLuaFilename(filename)
			if type(scriptName) ~= "string" or scriptName == "" then
				return nil
			end

			local dirs = {}
			for i = 2, (#parts - 1) do
				table.insert(dirs, parts[i])
			end
			if #dirs == 0 then
				return nil
			end
			if string.lower(dirs[#dirs]) ~= string.lower(scriptName) then
				return nil
			end

			local fullSegments = { serviceFromRel }
			for _, seg in ipairs(dirs) do
				table.insert(fullSegments, seg)
			end
			table.insert(fullSegments, scriptName)

			local collapsedSegments = { serviceFromRel }
			for i = 1, (#dirs - 1) do
				table.insert(collapsedSegments, dirs[i])
			end
			table.insert(collapsedSegments, scriptName)

			local fullKey = makeKey(serviceFromRel, fullSegments)
			if studioSourceByKey[fullKey] ~= nil then
				return fullSegments
			end

			local collapsedKey = makeKey(serviceFromRel, collapsedSegments)
			if studioSourceByKey[collapsedKey] ~= nil then
				return collapsedSegments
			end

			-- Default: preserve the folder (avoids dropping real folders like `Signal/Signal.module.lua`).
			return fullSegments
		end

		-- Find local-only scripts (present on disk but not in Studio)
		local okIndex, indexData = getLocalIndex(payload)
		if okIndex and type(indexData) == "table" and indexData.ok == true and type(indexData.items) == "table" then
			for _, localItem in ipairs(indexData.items) do
				local resolvedPath = resolveAmbiguousLocalLuaPathSegments(localItem, studioSourceByKey) or localItem.path
				local key = makeKey(localItem.service, resolvedPath)
				if not reviewKeys[key] and studioSourceByKey[key] == nil then
					local displayPath = ""
					if type(resolvedPath) == "table" then
						displayPath = table.concat(resolvedPath, "/")
					end
					local entry = {
						entryType = "script",
						kind = "A",
						service = localItem.service,
						class = localItem.class,
						name = localItem.name,
						path = resolvedPath,
						relPath = localItem.relPath,
						file = localItem.relPath,
						localSource = nil,
						studioSource = "",
						key = key,
						selected = (prevSelectedByKey[key] ~= nil) and prevSelectedByKey[key] or false,
						displayName = (displayPath ~= "" and displayPath) or tostring(localItem.name),
					}
					table.insert(reviewState.entries, entry)
					reviewKeys[key] = true
				end
			end
		end

		local instanceMissingCount = 0
		local instanceSkippedCount = 0
		local instanceSkippedReqCount = 0
		if (includeUiGetter and includeUiGetter()) or (includeObjectsGetter and includeObjectsGetter()) then
			setReviewStatus("Checking local UI/objects...")
			setReviewProgressAlpha(0.75)
			local instDiffUrl = deriveEndpointUrl(serverInput.Text, "diff_instances")
			local okInst, instData = postInstancesInChunksJson(instDiffUrl, instancePayload, function(alpha)
				setReviewProgressAlpha(0.75 + (alpha * 0.2))
			end)
			if not okInst then
				error(tostring(instData))
			end
			if type(instData) ~= "table" or instData.ok ~= true then
				error("invalid instance response")
			end

			local instChanges = instData.changes or {}
			local instMissing = instData.missingLocal or {}
			local instSkipped = instData.skippedLarge or {}
			local instSkippedReq = instData.skippedRequest or {}
			instanceMissingCount = #instMissing
			instanceSkippedCount = #instSkipped
			instanceSkippedReqCount = #instSkippedReq

			for _, change in ipairs(instChanges) do
				local service = change.service
				local pathSegments = change.path
				local studioKey = makeKey(service, pathSegments)
				local displayPath = ""
				if type(pathSegments) == "table" then
					displayPath = table.concat(pathSegments, "/")
				end
				local key = "instance|" .. makeKey(service, pathSegments)
				local studioTree = studioInstanceTreeByKey[studioKey]
				local entry = {
					entryType = "instance",
					kind = "M",
					service = service,
					class = change.class,
					name = change.name,
					path = pathSegments,
					relPath = change.relPath,
					file = change.file,
					localSource = nil,
					localTree = nil,
					studioTree = studioTree,
					studioSource = "",
					key = key,
					selected = (prevSelectedByKey[key] ~= nil) and prevSelectedByKey[key] or false,
					displayName = (displayPath ~= "" and displayPath) or tostring(change.name),
				}
				table.insert(reviewState.entries, entry)
				reviewKeys[key] = true
			end

			local okInstIndex, instIndexData = getLocalIndexInstances(instancePayload)
			if okInstIndex and type(instIndexData) == "table" and instIndexData.ok == true and type(instIndexData.items) == "table" then
				for _, localItem in ipairs(instIndexData.items) do
					local key = "instance|" .. makeKey(localItem.service, localItem.path)
					if not reviewKeys[key] then
						local inst = getInstanceFromPathSegments(localItem.path)
						if not inst then
							local displayPath = ""
							if type(localItem.path) == "table" then
								displayPath = table.concat(localItem.path, "/")
							end
							local entry = {
								entryType = "instance",
								kind = "A",
								service = localItem.service,
								class = localItem.class,
								name = localItem.name,
								path = localItem.path,
								relPath = localItem.relPath,
								file = localItem.relPath,
								localSource = nil,
								localTree = nil,
								studioTree = nil,
								studioSource = "",
								key = key,
								selected = (prevSelectedByKey[key] ~= nil) and prevSelectedByKey[key] or false,
								displayName = (displayPath ~= "" and displayPath) or tostring(localItem.name),
							}
							table.insert(reviewState.entries, entry)
							reviewKeys[key] = true
						end
					end
				end
			end
		end

		reviewState.summaryMissing = (#missing + instanceMissingCount)
		reviewState.summarySkipped = (#skipped + instanceSkippedCount)
		reviewState.summaryReqSkipped = (#skippedReq + instanceSkippedReqCount)

		renderReviewTree(prevSelectedKey)
		updateReviewSelectionUi()

		setReviewStatus(string.format("Loaded %d changes", #reviewState.entries))
		setReviewProgressAlpha(1)
	end)

	reviewState.isRefreshing = false
	if not okRun then
		setReviewStatus("Failed: " .. tostring(err))
		setReviewProgressAlpha(0)
	end
end

local function getOrCreateContainer(parent, name)
	local child = parent:FindFirstChild(name)
	if child then
		return child
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function createLuaSourceContainerFromPath(pathSegments, className)
	if type(pathSegments) ~= "table" or #pathSegments < 2 then
		return nil
	end

	local serviceName = pathSegments[1]
	local okService, service = pcall(function()
		return game:GetService(serviceName)
	end)
	if not okService or not service then
		return nil
	end

	local parent = service
	for i = 2, (#pathSegments - 1) do
		parent = getOrCreateContainer(parent, tostring(pathSegments[i]))
	end

	local name = tostring(pathSegments[#pathSegments])
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("LuaSourceContainer") then
		return existing
	end
	if existing then
		existing.Name = name .. "_old"
	end

	local okNew, inst = pcall(function()
		return Instance.new(className or "ModuleScript")
	end)
	if not okNew or not inst then
		return nil
	end
	inst.Name = name
	inst.Parent = parent
	return inst
end

local function setLuaSource(instance, newSource)
	newSource = tostring(newSource or "")

	local function tryUpdateOpenDocument()
		if not (ScriptEditorService and ScriptEditorService.GetScriptDocuments) then
			return false
		end
		local okDocs, docs = pcall(function()
			return ScriptEditorService:GetScriptDocuments()
		end)
		if not okDocs or type(docs) ~= "table" then
			return false
		end
		for _, doc in ipairs(docs) do
			local okGet, docScript = pcall(function()
				if doc.GetScript then
					return doc:GetScript()
				end
				return doc.Script
			end)
			if okGet and docScript == instance then
				local okSet = pcall(function()
					doc:SetText(newSource)
				end)
				pcall(function()
					doc:Save()
				end)
				return okSet == true
			end
		end
		return false
	end

	if tryUpdateOpenDocument() then
		pcall(function()
			instance.Source = newSource
		end)
		return true
	end

	if ScriptEditorService and ScriptEditorService.OpenScriptDocumentAsync then
		local okDoc, doc = pcall(function()
			return ScriptEditorService:OpenScriptDocumentAsync(instance)
		end)
		if okDoc and doc then
			local okSet = pcall(function()
				doc:SetText(newSource)
			end)
			pcall(function()
				doc:Save()
			end)
			pcall(function()
				instance.Source = newSource
			end)
			if okSet then
				return true
			end
		end
	end

	local okSet = pcall(function()
		instance.Source = newSource
	end)
	return okSet
end

local function applyInstanceTreeToInstance(instance, tree)
	if not instance or type(tree) ~= "table" then
		return false
	end

	if type(tree.name) == "string" then
		pcall(function()
			instance.Name = tree.name
		end)
	end

	if type(tree.attrs) == "table" then
		for k, v in pairs(tree.attrs) do
			if type(k) == "string" then
				pcall(function()
					instance:SetAttribute(k, decodeValue(v))
				end)
			end
		end
	end

	if type(tree.props) == "table" then
		for propName, encoded in pairs(tree.props) do
			if type(propName) == "string" then
				local decoded = decodeValue(encoded)
				if decoded ~= nil then
					pcall(function()
						instance[propName] = decoded
					end)
				end
			end
		end
	end

	if type(tree.children) == "table" then
		for _, childTree in ipairs(tree.children) do
			if type(childTree) == "table" and type(childTree.name) == "string" and type(childTree.class) == "string" then
				local existing = nil
				for _, child in ipairs(instance:GetChildren()) do
					if child.Name == childTree.name and child.ClassName == childTree.class then
						existing = child
						break
					end
				end
				if not existing then
					local okNew, created = pcall(function()
						return Instance.new(childTree.class)
					end)
					if okNew and created then
						created.Name = childTree.name
						created.Parent = instance
						existing = created
					end
				end
				if existing then
					applyInstanceTreeToInstance(existing, childTree)
				end
			end
		end
	end

	return true
end

local function getOrCreateInstanceParent(pathSegments)
	if type(pathSegments) ~= "table" or #pathSegments < 2 then
		return nil
	end
	local serviceName = tostring(pathSegments[1])
	local okService, service = pcall(function()
		return game:GetService(serviceName)
	end)
	if not okService or not service then
		return nil
	end

	local current = service
	for i = 2, (#pathSegments - 1) do
		local seg = tostring(pathSegments[i])
		local child = current:FindFirstChild(seg)
		if not child then
			child = Instance.new("Folder")
			child.Name = seg
			child.Parent = current
		end
		current = child
	end
	return current
end

local function syncSelectedToStudio()
	if RunService:IsRunning() then
		setReviewStatus("Disabled during Play mode.")
		return
	end

	local selected = {}
	for _, entry in ipairs(reviewState.entries) do
		if entry.selected then
			table.insert(selected, entry)
		end
	end

	if #selected == 0 then
		setReviewStatus("No changes selected.")
		return
	end

	setUiEnabled(false)
	setReviewStatus("Syncing...")
	setReviewProgressAlpha(0)

	ChangeHistoryService:SetWaypoint("Before Local Sync")

	local applied = 0
	local failed = 0

	for i, entry in ipairs(selected) do
		local alpha = math.clamp((i - 1) / #selected, 0, 1)
		setReviewProgressAlpha(alpha)

		if entry.entryType == "instance" then
			if entry.localTree == nil and entry.relPath then
				local okLocal, data = getLocalInstance(entry.relPath)
				if okLocal and type(data) == "table" and data.ok == true then
					entry.localTree = data.tree
					entry.localSource = data.pretty or (data.tree and prettyJson(data.tree)) or ""
				end
			end
			if type(entry.localTree) ~= "table" then
				failed += 1
				continue
			end

			local inst = getInstanceFromPathSegments(entry.path)
			if not inst then
				local parent = getOrCreateInstanceParent(entry.path)
				if parent then
					local className = tostring(entry.class or entry.localTree.class or "Folder")
					local okNew, created = pcall(function()
						return Instance.new(className)
					end)
					if okNew and created then
						local pathSegs = entry.path
						local fallbackName = (type(pathSegs) == "table" and pathSegs[#pathSegs]) or tostring(entry.name or "")
						created.Name = tostring(entry.name or entry.localTree.name or fallbackName)
						created.Parent = parent
						inst = created
					end
				end
			end

			if not inst then
				failed += 1
				continue
			end

			if applyInstanceTreeToInstance(inst, entry.localTree) then
				applied += 1
			else
				failed += 1
			end
		else
			if entry.localSource == nil and entry.relPath then
				local okLocal, data = getLocalSource(entry.relPath)
				if okLocal and type(data) == "table" and data.ok == true then
					entry.localSource = data.source or ""
				end
			end

			local inst
			if entry.kind == "A" then
				inst = createLuaSourceContainerFromPath(entry.path, entry.class)
			else
				inst = getInstanceFromPathSegments(entry.path)
			end

			if not inst or not inst:IsA("LuaSourceContainer") then
				failed += 1
				continue
			end

			if setLuaSource(inst, entry.localSource or "") then
				applied += 1
			else
				failed += 1
			end
		end
	end

	ChangeHistoryService:SetWaypoint("After Local Sync")

	setReviewProgressAlpha(1)
	setReviewStatus(string.format("Synced %d, failed %d", applied, failed))
	setUiEnabled(true)
	setDiffOpen(false, false)
	task.defer(refreshReview)
end

sendBtn.MouseButton1Click:Connect(function()
	if RunService:IsRunning() then
		setStatus("Disabled during Play mode.")
		return
	end
	if not HttpService.HttpEnabled then
		setStatus("Enable HTTP requests in Studio Settings first.")
		return
	end

	setStatus("Scanning...")
	setProgressAlpha(0.15)
	local payload = buildPayload()

	setStatus("Sending...")
	setProgressAlpha(0.6)
	local ok, resp = postInChunks(serverInput.Text, payload)
	if not ok then
		setStatus("Failed: " .. tostring(resp))
		setProgressAlpha(0)
		return
	end

	local includeUi = includeUiGetter and includeUiGetter() or false
	local includeObjects = includeObjectsGetter and includeObjectsGetter() or false
	if includeUi or includeObjects then
		setStatus("Exporting UI/objects...")
		setProgressAlpha(0.75)
		local instPayload = buildInstancesPayload()
		local instUrl = deriveEndpointUrl(serverInput.Text, "upload_instances")
		local okInst, instResp = postInstancesInChunks(instUrl, instPayload, function(alpha)
			setProgressAlpha(0.75 + (alpha * 0.25))
		end)
		if not okInst then
			setStatus("Failed: " .. tostring(instResp))
			setProgressAlpha(0)
			return
		end
		local wrote = (type(instResp) == "table" and instResp.wrote) or 0
		setStatus(string.format("Done: exported scripts + %d instances", wrote))
		setProgressAlpha(1)
		return
	end

	setStatus("Done")
	setProgressAlpha(1)
end)

toggleButton.Click:Connect(function()
	if RunService:IsRunning() then
		setWidgetOpen(false, false)
		setStatus("Disabled during Play mode.")
		return
	end
	setWidgetOpen(not widget.Enabled, true)
end)

reviewBtn.MouseButton1Click:Connect(function()
	if RunService:IsRunning() then
		setStatus("Disabled during Play mode.")
		return
	end
	showPage(reviewPage, true)
	refreshReview()
end)

reviewBackBtn.MouseButton1Click:Connect(function()
	setDiffOpen(false, false)
	showPage(exportPage, true)
end)

reviewRefreshBtn.MouseButton1Click:Connect(function()
	refreshReview()
end)

reviewOpenDiffBtn.MouseButton1Click:Connect(function()
	if reviewState.selectedIndex then
		setDiffOpen(true, true)
		applyDiffMode(reviewState.diffMode)
	else
		setReviewStatus("Select a change first.")
	end
end)

diffCloseBtn.MouseButton1Click:Connect(function()
	setDiffOpen(false, true)
end)

diffLocalTab.MouseButton1Click:Connect(function()
	applyDiffMode("local")
end)

diffStudioTab.MouseButton1Click:Connect(function()
	applyDiffMode("studio")
end)

reviewSyncBtn.MouseButton1Click:Connect(function()
	syncSelectedToStudio()
end)

local function setToolbarButtonEnabled(enabled)
	pcall(function()
		toggleButton.Enabled = enabled
	end)
end

local function applyRunningState(isRunning)
	if isRunning then
		setWidgetOpen(false, false)
		setToolbarButtonEnabled(false)
		setUiEnabled(false)
	else
		setToolbarButtonEnabled(true)
		setUiEnabled(true)
	end
end

local lastRunning = RunService:IsRunning()
applyRunningState(lastRunning)

task.spawn(function()
	while true do
		task.wait(0.25)
		local isRunning = RunService:IsRunning()
		if isRunning ~= lastRunning then
			lastRunning = isRunning
			applyRunningState(isRunning)
		end
	end
end)
