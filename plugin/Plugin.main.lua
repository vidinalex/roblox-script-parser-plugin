
-- Toolbar and Docked UI setup
local toolbar = plugin:CreateToolbar("Script Parser")
local toggleButton = toolbar:CreateButton("OpenParser", "Open Script Parser", "rbxassetid://71067276462408")

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Left,
	true,
	true,
	340,
	460,
	340,
	460
)

local widget = plugin:CreateDockWidgetPluginGui("ScriptParserDock", widgetInfo)
widget.Title = "Script Parser"

-- Theme (dark purple)
local DARK_BG = Color3.fromRGB(22, 8, 35)
local DARK_PANEL = Color3.fromRGB(36, 16, 58)
local ACCENT = Color3.fromRGB(156, 102, 255)
local TEXT = Color3.fromRGB(235, 230, 255)
local INPUT_BG = Color3.fromRGB(46, 22, 74)

local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

-- UI
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromScale(1, 1)
main.BackgroundColor3 = DARK_BG
main.BorderSizePixel = 0
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
settings.Size = UDim2.new(1, -20, 0, 170)
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
divider.Position = UDim2.fromOffset(10, 226)
divider.BackgroundColor3 = ACCENT
divider.BorderSizePixel = 0
divider.Parent = main

local _includeTagsRow
local includeTagsGetter

local servicesLabel = Instance.new("TextLabel")
servicesLabel.Size = UDim2.new(1, -20, 0, 18)
servicesLabel.Position = UDim2.fromOffset(10, 236)
servicesLabel.BackgroundTransparency = 1
servicesLabel.Text = "Select services to scan:"
servicesLabel.TextColor3 = TEXT
servicesLabel.TextXAlignment = Enum.TextXAlignment.Left
servicesLabel.Font = Enum.Font.Gotham
servicesLabel.TextSize = 12
servicesLabel.Parent = main

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "ServiceList"
scroll.Size = UDim2.new(1, -20, 1, -284)
scroll.Position = UDim2.fromOffset(10, 258)
scroll.BackgroundColor3 = DARK_PANEL
scroll.BorderSizePixel = 0
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.ScrollBarThickness = 6
scroll.Parent = main

local servicesCorner = Instance.new("UICorner")
servicesCorner.CornerRadius = UDim.new(0, 6)
servicesCorner.Parent = servicesLabel

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
	tick.Visible = false
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

	local function update()
		check.BackgroundColor3 = selected and ACCENT or DARK_PANEL
		tick.Visible = selected
	end

	button.MouseButton1Click:Connect(function()
		selected = not selected
		update()
	end)

	-- initialize visuals to match default
	update()

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

-- Include Tags option inside settings (as a compact checkbox)
do
	local row, getter = createCheckbox("Include Tags", false)
	row.Size = UDim2.new(1, 0, 0, 28)
	row.Position = UDim2.fromOffset(0, 116)
	row.Parent = settings
	_includeTagsRow = row
	includeTagsGetter = getter
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

local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(1, -20, 0, 36)
sendBtn.Position = UDim2.new(0, 10, 1, -48)
sendBtn.BackgroundColor3 = ACCENT
sendBtn.BorderSizePixel = 0
sendBtn.Text = "Scan and Send"
sendBtn.TextColor3 = TEXT
sendBtn.Font = Enum.Font.GothamBold
sendBtn.TextSize = 16
sendBtn.ZIndex = 10
sendBtn.Parent = main

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

local TweenService = game:GetService("TweenService")
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

-- Utilities
local function isLuaScript(instance)
	return instance:IsA("LuaSourceContainer")
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
				local tags = {}
				local tagOk, tagList = pcall(function()
					return CollectionService:GetTags(descendant)
				end)
				if tagOk and type(tagList) == "table" then
					tags = tagList
				end
				table.insert(results, {
					path = getPathSegments(descendant),
					name = descendant.Name,
					class = descendant.ClassName,
					source = src,
					tags = tags,
				})
			end
		end
	end
	return results
end

local function buildPayload()
	local selectedRoots = {}
	for label, provider in pairs(serviceProviders) do
		if getters[label]() then
			local items = collectScripts(provider)
			table.insert(selectedRoots, {
				service = label,
				items = items,
			})
		end
	end
	return {
		studioPlaceName = game.Name,
		generatedAt = os.time(),
		outputFolderName = (outputInput.Text and #outputInput.Text > 0) and outputInput.Text or "output",
		includeTags = includeTagsGetter and includeTagsGetter() or false,
		roots = selectedRoots,
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
        includeTags = basePayload.includeTags,
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
    local skippedUrl = string.gsub(url, "/upload$", "/skipped")
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
        local _sizeOk = true
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
                -- if first entry already exceeds limit, send it alone and hope server accepts
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

sendBtn.MouseButton1Click:Connect(function()
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
	if ok then
		setStatus("Done: " .. tostring(resp))
		setProgressAlpha(1)
	else
		setStatus("Failed: " .. tostring(resp))
		setProgressAlpha(0)
	end
end)

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)


