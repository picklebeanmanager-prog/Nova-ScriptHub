--##[ SERVICES ]##
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--##[ CONFIGURATION ]##
local MIN_SPEED = 0
local MAX_SPEED = 200
local DEFAULT_SPEED = 16

local NORMAL_SIZE = Vector2.new(380, 470)
local LARGE_SIZE = Vector2.new(460, 560)
local TITLE_BAR_HEIGHT = 36

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local selectedTarget = nil

--##[ UI HELPERS ]##
local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = obj
	return c
end

local function makeLabel(parent, text, pos, size, textSize)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Position = pos
	l.Size = size
	l.Font = Enum.Font.GothamMedium
	l.TextSize = textSize or 14
	l.TextColor3 = Color3.fromRGB(235, 235, 245)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function makeButton(parent, text, pos, size)
	local b = Instance.new("TextButton")
	b.Text = text
	b.Position = pos
	b.Size = size
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = Color3.fromRGB(70, 90, 200)
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 6)
	return b
end

--##[ SCREEN GUI + WINDOW ]##
local gui = Instance.new("ScreenGui")
gui.Name = "NovaAdminGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local window = Instance.new("Frame")
window.Size = UDim2.new(0, NORMAL_SIZE.X, 0, NORMAL_SIZE.Y)
window.Position = UDim2.new(0, 20, 0.5, -235)
window.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
window.ClipsDescendants = true
window.Active = true
window.Draggable = true
window.Parent = gui
corner(window, 10)

local titleLabel = makeLabel(window, "Nova Admin", UDim2.new(0, 84, 0, 6), UDim2.new(1, -100, 0, 24), 16)
local statusLabel = makeLabel(window, "", UDim2.new(0, 14, 1, -28), UDim2.new(1, -28, 0, 20), 13)

local function setStatus(text, good)
	statusLabel.Text = text
	statusLabel.TextColor3 = good == false and Color3.fromRGB(255, 130, 130) or Color3.fromRGB(150, 230, 170)
end

--##[ TABS ]##
local tabBar = Instance.new("Frame")
tabBar.Position = UDim2.new(0, 14, 0, 40)
tabBar.Size = UDim2.new(1, -28, 0, 30)
tabBar.BackgroundTransparency = 1
tabBar.Parent = window

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.Parent = tabBar

local pages, tabButtons = {}, {}

local function createTab(name)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 80, 1, 0)
	btn.Text = name
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	btn.Parent = tabBar
	corner(btn, 6)

	local page = Instance.new("Frame")
	page.Position = UDim2.new(0, 14, 0, 80)
	page.Size = UDim2.new(1, -28, 1, -112)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = window

	pages[name], tabButtons[name] = page, btn
	return page
end

local function switchTab(name)
	for tabName, page in pairs(pages) do
		page.Visible = (tabName == name)
		tabButtons[tabName].BackgroundColor3 = (tabName == name)
			and Color3.fromRGB(70, 90, 200) or Color3.fromRGB(50, 50, 70)
	end
end

local actionsPage = createTab("Actions")
local speedPage = createTab("Speed")
local flyPage = createTab("Fly")
local currentTab = "Actions"

for name, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		currentTab = name
		switchTab(name)
	end)
end

--##[ MAC-STYLE WINDOW BUTTONS ]##
local minimized = false
local enlarged = false

local function tweenWindowSize(w, h)
	TweenService:Create(
		window,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, w, 0, h) }
	):Play()
end

local function applyWindowState()
	local size = enlarged and LARGE_SIZE or NORMAL_SIZE
	if minimized then
		tweenWindowSize(size.X, TITLE_BAR_HEIGHT)
		tabBar.Visible = false
		statusLabel.Visible = false
		for _, page in pairs(pages) do
			page.Visible = false
		end
	else
		tweenWindowSize(size.X, size.Y)
		tabBar.Visible = true
		statusLabel.Visible = true
		switchTab(currentTab)
	end
end

local function makeTrafficLight(xOffset, color, symbol, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 14, 0, 14)
	btn.Position = UDim2.new(0, xOffset, 0, 11)
	btn.BackgroundColor3 = color
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = Color3.fromRGB(60, 20, 20)
	btn.Parent = window
	corner(btn, 7)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Transparency = 0.8
	stroke.Thickness = 1
	stroke.Parent = btn

	btn.MouseEnter:Connect(function() btn.Text = symbol end)
	btn.MouseLeave:Connect(function() btn.Text = "" end)
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

makeTrafficLight(12, Color3.fromRGB(255, 95, 86), "x", function() gui:Destroy() end)
makeTrafficLight(32, Color3.fromRGB(255, 189, 46), "-", function() minimized = not minimized applyWindowState() end)
makeTrafficLight(52, Color3.fromRGB(39, 201, 63), "+", function() if minimized then minimized = false else enlarged = not enlarged end applyWindowState() end)

--##[ TARGET SELECTOR COMPONENT (Shared between Tabs) ]##
local avatar = Instance.new("ImageLabel")
avatar.Position = UDim2.new(0, 0, 0, 0)
avatar.Size = UDim2.new(0, 48, 0, 48)
avatar.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
avatar.Parent = speedPage
corner(avatar, 24)

makeLabel(speedPage, "Target Control", UDim2.new(0, 58, 0, 0), UDim2.new(1, -58, 0, 18), 15)
local selectedLabel = makeLabel(speedPage, "Selected: none", UDim2.new(0, 58, 0, 22), UDim2.new(1, -58, 0, 18), 13)
selectedLabel.TextColor3 = Color3.fromRGB(170, 200, 255)

local showListButton = makeButton(speedPage, "Show Player List", UDim2.new(0, 0, 0, 60), UDim2.new(1, 0, 0, 32))

local listFrame = Instance.new("ScrollingFrame")
listFrame.Position = UDim2.new(0, 0, 0, 100)
listFrame.Size = UDim2.new(1, 0, 0, 230)
listFrame.BackgroundColor3 = Color3.fromRGB(36, 36, 50)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 5
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Visible = false
listFrame.Parent = speedPage
corner(listFrame, 6)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

local function setTarget(player)
	selectedTarget = player
	if not player then
		selectedLabel.Text = "Selected: none"
		avatar.Image = ""
		return
	end
	selectedLabel.Text = "Selected: " .. player.DisplayName .. " (@" .. player.Name .. ")"
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and selectedTarget == player then avatar.Image = content end
	end)
end

local function refreshPlayerList()
	for _, child in ipairs(listFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	local all = Players:GetPlayers()
	table.sort(all, function(a, b) return string.lower(a.DisplayName) < string.lower(b.DisplayName) end)
	for i, plr in ipairs(all) do
		if plr ~= localPlayer then
			local entry = Instance.new("TextButton")
			entry.LayoutOrder = i
			entry.Size = UDim2.new(1, -8, 0, 28)
			entry.Text = plr.DisplayName .. "  (@" .. plr.Name .. ")"
			entry.Font = Enum.Font.Gotham
			entry.TextSize = 13
			entry.TextColor3 = Color3.new(1, 1, 1)
			entry.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
			entry.Parent = listFrame
			corner(entry, 5)
			entry.MouseButton1Click:Connect(function() setTarget(plr) listFrame.Visible = false showListButton.Text = "Show Player List" end)
		end
	end
end

showListButton.MouseButton1Click:Connect(function()
	listFrame.Visible = not listFrame.Visible
	showListButton.Text = listFrame.Visible and "Hide Player List" or "Show Player List"
	if listFrame.Visible then refreshPlayerList() end
end)

Players.PlayerAdded:Connect(function() if listFrame.Visible then refreshPlayerList() end end)
Players.PlayerRemoving:Connect(function(plr) if selectedTarget == plr then setTarget(nil) end task.defer(function() if listFrame.Visible then refreshPlayerList() end end) end)

--##[ CLIENT FLING ENGINE ]##
local function clientFling(targetPlr, duration)
	local myChar = localPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")

	local targetChar = targetPlr.Character
	local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

	if not myRoot or not targetRoot or not myHum then return end

	local oldCFrame = myRoot.CFrame
	local oldVelocity = myRoot.AssemblyLinearVelocity

	local bV = Instance.new("AngularVelocity")
	bV.MaxTorque = math.huge
	bV.AngularVelocity = Vector3.new(0, 99999, 0)
	bV.RelativeTo = Enum.ActuatorRelativeTo.Attachment0

	local att = Instance.new("Attachment")
	att.Parent = myRoot
	bV.Attachment0 = att
	bV.Parent = myRoot

	local startTime = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if os.clock() - startTime > duration or not targetRoot or not myRoot then
			connection:Disconnect()
			bV:Destroy()
			att:Destroy()
			myRoot.CFrame = oldCFrame
			myRoot.AssemblyLinearVelocity = oldVelocity
			return
		end

		myRoot.AssemblyLinearVelocity = Vector3.new(9999, 9999, 9999)
		myRoot.CFrame = targetRoot.CFrame * CFrame.new(math.random(-1,1)/10, 0, math.random(-1,1)/10)
	end)
end

--##[ ACTIONS TAB ]##
Vær forsigtig med at bruge denne kode.
makeLabel(actionsPage, "Globale handlinger (Brug player-listen under Speed).", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), 13)
for i, actionName in ipairs({ "Fling", "Kill", "Teleport" }) do
local btn = makeButton(actionsPage, actionName, UDim2.new(0, 0, 0, 28 + (i - 1) * 42), UDim2.new(1, 0, 0, 36))
btn.MouseButton1Click:Connect(function()
if not selectedTarget then
setStatus("Vælg en spiller under 'Speed' fanen først.", false)
return
end
if actionName == "Fling" then
setStatus("Flinger " .. selectedTarget.DisplayName .. "...", true)
clientFling(selectedTarget, 1.5)
elseif actionName == "Kill" then
setStatus("Prøver at dræbe via Void Fling...", true)
clientFling(selectedTarget, 3.0)
elseif actionName == "Teleport" then
local targetChar = selectedTarget.Character
local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
local myChar = localPlayer.Character
if myChar and targetRoot then
myChar:PivotTo(targetRoot.CFrame + Vector3.new(0, 3, 5))
setStatus("Teleporteret til " .. selectedTarget.DisplayName, true)
else
setStatus("Kunne ikke finde målets karakter.", false)
end
end
end)
end
--##[ FLY TAB ]##
makeLabel(flyPage, "Eksterne Fly-moduler", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), 15)
makeLabel(flyPage, "Indlæser eksternt script til flyvning via Pastebin.", UDim2.new(0, 0, 0, 20), UDim2.new(1, 0, 0, 16), 12).TextColor3 = Color3.fromRGB(150, 150, 160)
local loadFlyBtn = makeButton(flyPage, "Load Fly GUI V3", UDim2.new(0, 0, 0, 46), UDim2.new(1, 0, 0, 40))
loadFlyBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87) -- Grøn farve til eksterne scripts
loadFlyBtn.MouseButton1Click:Connect(function()
setStatus("Henter Fly GUI V3...", true)
local success, err = pcall(function()
loadstring(game:HttpGet("https://pastebin.com/raw/GSb9JLkm"))()
end)
if success then
setStatus("Fly GUI V3 indlæst!", true)
else
setStatus("Fejl ved indlæsning af Fly GUI: " .. tostring(err), false)
end
end)
switchTab("Actions")
