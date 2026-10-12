--[[
##########################################################################
##  PART 1 of 2  --  SERVER SCRIPT
##  Paste everything from here down to the "END OF PART 1" banner
##  into a Script inside ServerScriptService.
##########################################################################
]]

--##[ SERVICES ]##
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--##[ CONFIGURATION ]##
local FLING_FORCE = 85
local FLING_UPWARD_FORCE = 55
local TELEPORT_OFFSET = Vector3.new(0, 3, 5)
local MIN_SPEED = 0
local MAX_SPEED = 200

local ALLOWED_ACTIONS = {
	Fling = true,
	Kill = true,
	Teleport = true,
	SetSpeed = true,
}

--##[ REMOTE SETUP ]##
local remotes = ReplicatedStorage:FindFirstChild("NovaAdminRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "NovaAdminRemotes"
	remotes.Parent = ReplicatedStorage
end

local actionRemote = remotes:FindFirstChild("Action")
if not actionRemote then
	actionRemote = Instance.new("RemoteEvent")
	actionRemote.Name = "Action"
	actionRemote.Parent = remotes
end

--##[ CHARACTER VALIDATION ]##
local function getLivingCharacterParts(player)
	local character = player.Character
	if not character then
		return nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root or humanoid.Health <= 0 then
		return nil, nil
	end

	return humanoid, root
end

--##[ SERVER MESSAGES ]##
local function sendResult(player, success, message)
	actionRemote:FireClient(player, success, message)
end

--##[ FLING ACTION ]##
local function performFling(senderRoot, targetRoot)
	targetRoot:SetNetworkOwner(nil)

	local direction = targetRoot.Position - senderRoot.Position
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(1, 0, 0)
	else
		direction = direction.Unit
	end

	local mass = math.max(targetRoot.AssemblyMass, 1)
	local impulse = direction * FLING_FORCE + Vector3.new(0, FLING_UPWARD_FORCE, 0)
	targetRoot:ApplyImpulse(impulse * mass)
end

--##[ TELEPORT ACTION ]##
local function performTeleport(senderCharacter, targetRoot)
	senderCharacter:PivotTo(targetRoot.CFrame + TELEPORT_OFFSET)
end

--##[ COMMAND HANDLER ]##
actionRemote.OnServerEvent:Connect(function(player, actionName, targetUserId, value)
	if type(actionName) ~= "string" or not ALLOWED_ACTIONS[actionName] then
		return
	end
	if type(targetUserId) ~= "number" then
		return
	end

	local targetPlayer = Players:FindPlayerByUserId(targetUserId)
	if not targetPlayer then
		sendResult(player, false, "That target is not available.")
		return
	end

	local senderHumanoid, senderRoot = getLivingCharacterParts(player)
	local targetHumanoid, targetRoot = getLivingCharacterParts(targetPlayer)

	if not targetHumanoid or not targetRoot then
		sendResult(player, false, "The target does not have a living character.")
		return
	end

	if actionName == "SetSpeed" then
		if type(value) ~= "number" or value ~= value then
			return
		end
		targetHumanoid.WalkSpeed = math.clamp(value, MIN_SPEED, MAX_SPEED)
		sendResult(player, true, targetPlayer.DisplayName .. "'s speed set to " .. math.floor(value))
		return
	end

	if targetPlayer == player then
		sendResult(player, false, "Pick someone other than yourself.")
		return
	end
	if not senderHumanoid or not senderRoot then
		sendResult(player, false, "You need a living character.")
		return
	end

	if actionName == "Fling" then
		performFling(senderRoot, targetRoot)
		sendResult(player, true, "Fling completed.")
	elseif actionName == "Kill" then
		targetHumanoid.Health = 0
		sendResult(player, true, "Kill completed.")
	elseif actionName == "Teleport" then
		performTeleport(player.Character, targetRoot)
		sendResult(player, true, "Teleport completed.")
	end
end)

--[[
##########################################################################
##  END OF PART 1  --  (cut here)
##########################################################################
]]


--[[
##########################################################################
##  PART 2 of 2  --  LOCAL SCRIPT
##  Paste everything from here to the bottom into a LocalScript
##  inside StarterPlayerScripts.
##########################################################################
]]

--##[ SERVICES ]##
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

--##[ CONFIGURATION ]##
local MIN_SPEED = 0
local MAX_SPEED = 200
local DEFAULT_SPEED = 16

local NORMAL_SIZE = Vector2.new(380, 470)
local LARGE_SIZE = Vector2.new(460, 560)
local TITLE_BAR_HEIGHT = 36

--##[ REMOTES ]##
local remotes = ReplicatedStorage:WaitForChild("NovaAdminRemotes")
local actionRemote = remotes:WaitForChild("Action")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local selectedTarget = nil
local selfSpeed = DEFAULT_SPEED

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

-- Title (shifted right to make room for the Mac buttons)
local titleLabel = makeLabel(window, "Nova Admin", UDim2.new(0, 84, 0, 6), UDim2.new(1, -100, 0, 24), 16)

local statusLabel = makeLabel(window, "", UDim2.new(0, 14, 1, -28), UDim2.new(1, -28, 0, 20), 13)

local function setStatus(text, good)
	statusLabel.Text = text
	statusLabel.TextColor3 = good == false and Color3.fromRGB(255, 130, 130) or Color3.fromRGB(150, 230, 170)
end

actionRemote.OnClientEvent:Connect(function(success, message)
	setStatus(message, success)
end)

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
	btn.Size = UDim2.new(0, 90, 1, 0)
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
local currentTab = "Speed"

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

-- Red: close
makeTrafficLight(12, Color3.fromRGB(255, 95, 86), "x", function()
	gui:Destroy()
end)

-- Yellow: minimize
makeTrafficLight(32, Color3.fromRGB(255, 189, 46), "-", function()
	minimized = not minimized
	applyWindowState()
end)

-- Green: enlarge / shrink
makeTrafficLight(52, Color3.fromRGB(39, 201, 63), "+", function()
	if minimized then
		minimized = false
	else
		enlarged = not enlarged
	end
	applyWindowState()
end)

--##[ SLIDER ]##
local function makeSlider(parent, pos, size, minV, maxV, startV, callback)
	local holder = Instance.new("Frame")
	holder.Position = pos
	holder.Size = size
	holder.BackgroundTransparency = 1
	holder.Parent = parent

	local valueLabel = makeLabel(holder, tostring(startV), UDim2.new(1, -50, 0, 0), UDim2.new(0, 50, 0, 16), 13)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right

	local hit = Instance.new("Frame")
	hit.Position = UDim2.new(0, 0, 0, 20)
	hit.Size = UDim2.new(1, 0, 0, 26)
	hit.BackgroundTransparency = 1
	hit.Parent = holder

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.new(0, 0, 0.5, 0)
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
	bar.Parent = hit
	corner(bar, 4)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Color3.fromRGB(90, 130, 255)
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.Parent = bar
	corner(fill, 4)

	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.Parent = bar
	corner(knob, 9)

	local value = startV
	local dragging = false

	local function render()
		local alpha = (value - minV) / (maxV - minV)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = tostring(value)
	end

	local function updateFromX(x)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		value = math.floor(minV + (maxV - minV) * alpha + 0.5)
		render()
		callback(value, false)
	end

	local function isPointer(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end

	hit.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging = true
			window.Draggable = false -- don't drag the window while sliding
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if dragging and isPointer(input) then
			dragging = false
			window.Draggable = true
			callback(value, true)
		end
	end)

	render()
	return holder
end

--##########################################################
--##[ SPEED TAB ]##
--##########################################################

-- Your speed
makeLabel(speedPage, "Your Speed", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), 15)

local function applySelfSpeed()
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = selfSpeed
	end
end

makeSlider(speedPage, UDim2.new(0, 0, 0, 22), UDim2.new(1, 0, 0, 46), MIN_SPEED, MAX_SPEED, DEFAULT_SPEED,
	function(value)
		selfSpeed = value
		applySelfSpeed()
	end)

localPlayer.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid")
	if selfSpeed ~= DEFAULT_SPEED then
		applySelfSpeed()
	end
end)

-- Selected player's speed (avatar next to it)
makeLabel(speedPage, "Selected Player Speed", UDim2.new(0, 0, 0, 78), UDim2.new(1, 0, 0, 18), 15)

local avatar = Instance.new("ImageLabel")
avatar.Position = UDim2.new(0, 0, 0, 100)
avatar.Size = UDim2.new(0, 48, 0, 48)
avatar.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
avatar.Image = ""
avatar.Parent = speedPage
corner(avatar, 24)

local lastSend = 0
makeSlider(speedPage, UDim2.new(0, 58, 0, 100), UDim2.new(1, -58, 0, 46), MIN_SPEED, MAX_SPEED, DEFAULT_SPEED,
	function(value, final)
		if not selectedTarget then
			if final then setStatus("Select a target first.", false) end
			return
		end
		local now = os.clock()
		if final or now - lastSend > 0.1 then
			lastSend = now
			actionRemote:FireServer("SetSpeed", selectedTarget.UserId, value)
		end
	end)

-- Target selector
makeLabel(speedPage, "Target Selector", UDim2.new(0, 0, 0, 160), UDim2.new(1, 0, 0, 18), 15)

local selectedLabel = makeLabel(speedPage, "Selected: none", UDim2.new(0, 0, 0, 182), UDim2.new(1, 0, 0, 18), 13)
selectedLabel.TextColor3 = Color3.fromRGB(170, 200, 255)

local showListButton = makeButton(speedPage, "Show Player List", UDim2.new(0, 0, 0, 206), UDim2.new(1, 0, 0, 32))

local listFrame = Instance.new("ScrollingFrame")
listFrame.Position = UDim2.new(0, 0, 0, 244)
listFrame.Size = UDim2.new(1, 0, 0, 110)
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
	avatar.Image = ""

	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)
		if ok and selectedTarget == player then
			avatar.Image = content
		end
	end)
end

local function refreshPlayerList()
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local all = Players:GetPlayers()
	table.sort(all, function(a, b)
		return string.lower(a.DisplayName) < string.lower(b.DisplayName)
	end)

	for i, plr in ipairs(all) do
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

		entry.MouseButton1Click:Connect(function()
			setTarget(plr)
			listFrame.Visible = false
			showListButton.Text = "Show Player List"
		end)
	end
end

showListButton.MouseButton1Click:Connect(function()
	listFrame.Visible = not listFrame.Visible
	showListButton.Text = listFrame.Visible and "Hide Player List" or "Show Player List"
	if listFrame.Visible then
		refreshPlayerList()
	end
end)

Players.PlayerAdded:Connect(function()
	if listFrame.Visible then refreshPlayerList() end
end)

Players.PlayerRemoving:Connect(function(plr)
	if selectedTarget == plr then
		setTarget(nil)
	end
	task.defer(function()
		if listFrame.Visible then refreshPlayerList() end
	end)
end)

--##########################################################
--##[ ACTIONS TAB ]##
--##########################################################
makeLabel(actionsPage, "Uses the target chosen in the Speed tab.", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 18), 13)

for i, actionName in ipairs({ "Fling", "Kill", "Teleport" }) do
	local btn = makeButton(actionsPage, actionName, UDim2.new(0, 0, 0, 28 + (i - 1) * 42), UDim2.new(1, 0, 0, 36))
	btn.MouseButton1Click:Connect(function()
		if not selectedTarget then
			setStatus("Select a target first.", false)
			return
		end
		actionRemote:FireServer(actionName, selectedTarget.UserId)
	end)
end

switchTab("Speed")

--[[
##########################################################################
##  END OF PART 2
##########################################################################
]]
