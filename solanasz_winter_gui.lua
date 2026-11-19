-- [GUI-Overhaul: Winter FX Engine + Fix für 200-Locals-Limit] Erstellt von Gemini für SOLANASZ (Individuelle Spieler-Zeit + Anti-Exploit + Automatischer Rejoin & Key-Reset)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local __UI = {} -- Container für GUI-Elemente (umgeht das 200-Locals-Limit von Luau)

-- Eindeutige Config pro Spieler, damit jeder seine eigene unabhängige Zeit hat!
local CONFIG_FILE = "solanasz_config_" .. tostring(player.UserId) .. ".json"

local configData = {
	aimbot = false,
	backbot = false,
	wallCheck = false,
	teamCheck = false,
	triggerbot = false,
	triggerbotDelay = "0",
	noclip = false,
	fly = false,
	infJump = false,
	autoRespawn = false,
	fovCircle = false,
	clickTp = false,
	tpKey = "LeftControl",
	aimbotKey = "",
	smoothness = 5,
	maxDistance = 1000,
	fovRadius = 150,
	cameraFov = 70,
	speed = 16,
	espColorName = "white",
	esp = { Box = false, Name = false, Health = false, Tracer = false, Skeleton = false, Chams = false },
	lightingMode = "Normal",
	playerBinds = {},
	upTp = false,
	checkTp = false,
	scareTp = false,
	totalTime = 0,
	todayTime = 0,
	weekTime = 0,
	sessionStartTime = os.time(), -- Absoluter Startzeitpunkt dieser 24h-Session gegen Re-Execute Exploits
	lastResetDate = os.date("%d-%m-%Y"),
	keyUnlocked = false,
	dynamicKey = 453492843001
}

local function saveConfig()
	pcall(function()
		local encoded = HttpService:JSONEncode(configData)
		if writefile then
			writefile(CONFIG_FILE, encoded)
		end
	end)
end

local function loadConfig()
	pcall(function()
		if readfile and isfile and isfile(CONFIG_FILE) then
			local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
			if type(decoded) == "table" then
				for k, v in pairs(decoded) do
					if type(v) == "table" and type(configData[k]) == "table" then
						for subK, subV in pairs(v) do
							configData[k][subK] = subV
						end
					else
						configData[k] = v
					end
				end
			end
		end
	end)
end

loadConfig()

-- Anti-Exploit & Tageswechsel-Prüfung: 
-- Wenn ein neuer Tag anbricht oder die Session älter als 24 Stunden (86400s) ist -> Reset & Key Sperre!
local currentTime = os.time()
local currentDate = os.date("%d-%m-%Y")
local secondsInADay = 86400

if configData.lastResetDate ~= currentDate or (currentTime - (configData.sessionStartTime or currentTime)) >= secondsInADay then
	configData.todayTime = 0
	configData.sessionStartTime = currentTime
	configData.lastResetDate = currentDate
	configData.keyUnlocked = false
	saveConfig()
end

configData.dynamicKey = (configData.dynamicKey or 453492843001) + 45009
saveConfig()

print("--------------------------------------------------")
print("[SOLANASZ] Individuelle Session für: " .. player.Name)
print("[SOLANASZ] Aktueller Key-Zusatz: XCVVB445" .. tostring(configData.dynamicKey))
print("--------------------------------------------------")

local function createProtectedGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SolanaszStyledGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local success = pcall(function()
		if gethui then
			screenGui.Parent = gethui()
		elseif CoreGui:FindFirstChild("RobloxGui") then
			screenGui.Parent = CoreGui
		else
			screenGui.Parent = player:WaitForChild("PlayerGui")
		end
	end)

	if not success then
		screenGui.Parent = player:WaitForChild("PlayerGui")
	end

	return screenGui
end

local screenGui = createProtectedGui()

--------------------------------------------------------------------------------
-- KEY SYSTEM GUI (Winter / Xmas Theme)
--------------------------------------------------------------------------------
__UI.keyFrame = Instance.new("Frame")
__UI.keyFrame.Name = "KeyFrame"
__UI.keyFrame.Size = UDim2.new(0, 390, 0, 270)
__UI.keyFrame.AnchorPoint = Vector2.new(0.5, 0.5)
__UI.keyFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
__UI.keyFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
__UI.keyFrame.BorderSizePixel = 0
__UI.keyFrame.ZIndex = 100
__UI.keyFrame.Parent = screenGui
__UI.keyFrame.Visible = not configData.keyUnlocked

__UI.keyUiCorner = Instance.new("UICorner")
__UI.keyUiCorner.CornerRadius = UDim.new(0, 14)
__UI.keyUiCorner.Parent = __UI.keyFrame

__UI.keyUiStroke = Instance.new("UIStroke")
__UI.keyUiStroke.Thickness = 2.5
__UI.keyUiStroke.Color = Color3.fromRGB(125, 211, 252)
__UI.keyUiStroke.Parent = __UI.keyFrame

__UI.keyTopBar = Instance.new("Frame")
__UI.keyTopBar.Name = "KeyTopBar"
__UI.keyTopBar.Size = UDim2.new(1, 0, 0, 40)
__UI.keyTopBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.keyTopBar.BorderSizePixel = 0
__UI.keyTopBar.ZIndex = 101
__UI.keyTopBar.Parent = __UI.keyFrame

__UI.keyTopCorner = Instance.new("UICorner")
__UI.keyTopCorner.CornerRadius = UDim.new(0, 14)
__UI.keyTopCorner.Parent = __UI.keyTopBar

__UI.keyTopCover = Instance.new("Frame")
__UI.keyTopCover.Size = UDim2.new(1, 0, 0, 10)
__UI.keyTopCover.Position = UDim2.new(0, 0, 1, -10)
__UI.keyTopCover.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.keyTopCover.BorderSizePixel = 0
__UI.keyTopCover.ZIndex = 101
__UI.keyTopCover.Parent = __UI.keyTopBar

__UI.keyTitleLabel = Instance.new("TextLabel")
__UI.keyTitleLabel.Size = UDim2.new(1, -20, 1, 0)
__UI.keyTitleLabel.Position = UDim2.new(0, 20, 0, 0)
__UI.keyTitleLabel.BackgroundTransparency = 1
__UI.keyTitleLabel.Text = "❄️ SOLANASZ // FROSTED ACCESS"
__UI.keyTitleLabel.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.keyTitleLabel.TextSize = 15
__UI.keyTitleLabel.Font = Enum.Font.GothamBold
__UI.keyTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
__UI.keyTitleLabel.ZIndex = 102
__UI.keyTitleLabel.Parent = __UI.keyTopBar

__UI.keyBoxInput = Instance.new("TextBox")
__UI.keyBoxInput.Size = UDim2.new(0.85, 0, 0, 36)
__UI.keyBoxInput.AnchorPoint = Vector2.new(0.5, 0)
__UI.keyBoxInput.Position = UDim2.new(0.5, 0, 0, 52)
__UI.keyBoxInput.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.keyBoxInput.PlaceholderText = "KEYZz (XCVVB445...)"
__UI.keyBoxInput.PlaceholderColor3 = Color3.fromRGB(148, 163, 184)
__UI.keyBoxInput.Text = ""
__UI.keyBoxInput.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.keyBoxInput.TextSize = 12
__UI.keyBoxInput.Font = Enum.Font.GothamMedium
__UI.keyBoxInput.ClearTextOnFocus = false
__UI.keyBoxInput.ZIndex = 101
__UI.keyBoxInput.Parent = __UI.keyFrame

local keyBoxCorner = Instance.new("UICorner")
keyBoxCorner.CornerRadius = UDim.new(0, 8)
keyBoxCorner.Parent = __UI.keyBoxInput

local keyBoxStroke = Instance.new("UIStroke")
keyBoxStroke.Thickness = 1.5
keyBoxStroke.Color = Color3.fromRGB(56, 189, 248)
keyBoxStroke.Parent = __UI.keyBoxInput

__UI.getCodeLabel = Instance.new("TextLabel")
__UI.getCodeLabel.Size = UDim2.new(0.85, 0, 0, 18)
__UI.getCodeLabel.AnchorPoint = Vector2.new(0.5, 0)
__UI.getCodeLabel.Position = UDim2.new(0.5, 0, 0, 96)
__UI.getCodeLabel.BackgroundTransparency = 1
__UI.getCodeLabel.Text = "🎄 Get code:"
__UI.getCodeLabel.TextColor3 = Color3.fromRGB(186, 230, 253)
__UI.getCodeLabel.TextSize = 12
__UI.getCodeLabel.Font = Enum.Font.GothamBold
__UI.getCodeLabel.TextXAlignment = Enum.TextXAlignment.Left
__UI.getCodeLabel.ZIndex = 101
__UI.getCodeLabel.Parent = __UI.keyFrame

__UI.discordBoxInput = Instance.new("TextBox")
__UI.discordBoxInput.Size = UDim2.new(0.60, 0, 0, 32)
__UI.discordBoxInput.Position = UDim2.new(0.075, 0, 0, 118)
__UI.discordBoxInput.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.discordBoxInput.Text = "https://discord.gg/bzzMBnH3g"
__UI.discordBoxInput.TextColor3 = Color3.fromRGB(56, 189, 248)
__UI.discordBoxInput.TextSize = 11
__UI.discordBoxInput.Font = Enum.Font.GothamMedium
__UI.discordBoxInput.ClearTextOnFocus = false
__UI.discordBoxInput.TextEditable = false
__UI.discordBoxInput.ZIndex = 101
__UI.discordBoxInput.Parent = __UI.keyFrame

__UI.discordBoxCorner = Instance.new("UICorner")
__UI.discordBoxCorner.CornerRadius = UDim.new(0, 8)
__UI.discordBoxCorner.Parent = __UI.discordBoxInput

__UI.discordBoxStroke = Instance.new("UIStroke")
__UI.discordBoxStroke.Thickness = 1.5
__UI.discordBoxStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.discordBoxStroke.Parent = __UI.discordBoxInput

__UI.copyDiscordBtn = Instance.new("TextButton")
__UI.copyDiscordBtn.Size = UDim2.new(0.23, 0, 0, 32)
__UI.copyDiscordBtn.Position = UDim2.new(0.695, 0, 0, 118)
__UI.copyDiscordBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
__UI.copyDiscordBtn.Text = "🎁 Kopieren"
__UI.copyDiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.copyDiscordBtn.TextSize = 11
__UI.copyDiscordBtn.Font = Enum.Font.GothamBold
__UI.copyDiscordBtn.ZIndex = 101
__UI.copyDiscordBtn.Parent = __UI.keyFrame

__UI.copyDiscordCorner = Instance.new("UICorner")
__UI.copyDiscordCorner.CornerRadius = UDim.new(0, 8)
__UI.copyDiscordCorner.Parent = __UI.copyDiscordBtn

__UI.copyDiscordBtn.MouseButton1Click:Connect(function()
	pcall(function()
		if setclipboard then
			setclipboard("https://discord.gg/bzzMBnH3g")
		elseif toclipboard then
			toclipboard("https://discord.gg/bzzMBnH3g")
		end
	end)
	__UI.copyDiscordBtn.Text = "✨ Kopiert!"
	task.delay(1.5, function()
		if __UI.copyDiscordBtn then __UI.copyDiscordBtn.Text = "🎁 Kopieren" end
	end)
end)

__UI.submitKeyBtn = Instance.new("TextButton")
__UI.submitKeyBtn.Size = UDim2.new(0.85, 0, 0, 38)
__UI.submitKeyBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.submitKeyBtn.Position = UDim2.new(0.5, 0, 0, 162)
__UI.submitKeyBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
__UI.submitKeyBtn.Text = "❄️ VERIFY CODE"
__UI.submitKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.submitKeyBtn.TextSize = 14
__UI.submitKeyBtn.Font = Enum.Font.GothamBold
__UI.submitKeyBtn.ZIndex = 101
__UI.submitKeyBtn.Parent = __UI.keyFrame

__UI.submitKeyCorner = Instance.new("UICorner")
__UI.submitKeyCorner.CornerRadius = UDim.new(0, 8)
__UI.submitKeyCorner.Parent = __UI.submitKeyBtn

__UI.submitKeyStroke = Instance.new("UIStroke")
__UI.submitKeyStroke.Thickness = 1.5
__UI.submitKeyStroke.Color = Color3.fromRGB(52, 211, 153)
__UI.submitKeyStroke.Parent = __UI.submitKeyBtn

__UI.keyErrorLabel = Instance.new("TextLabel")
__UI.keyErrorLabel.Size = UDim2.new(1, 0, 0, 20)
__UI.keyErrorLabel.Position = UDim2.new(0, 0, 0, 210)
__UI.keyErrorLabel.BackgroundTransparency = 1
__UI.keyErrorLabel.Text = ""
__UI.keyErrorLabel.TextColor3 = Color3.fromRGB(255, 107, 107)
__UI.keyErrorLabel.TextSize = 12
__UI.keyErrorLabel.Font = Enum.Font.GothamMedium
__UI.keyErrorLabel.ZIndex = 101
__UI.keyErrorLabel.Parent = __UI.keyFrame

--------------------------------------------------------------------------------
-- HAUPTFENSTER
--------------------------------------------------------------------------------
__UI.mainFrame = Instance.new("Frame")
__UI.mainFrame.Name = "MainFrame"
__UI.mainFrame.Size = UDim2.new(0, 480, 0, 300)
__UI.mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
__UI.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
__UI.mainFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
__UI.mainFrame.BorderSizePixel = 0
__UI.mainFrame.Visible = configData.keyUnlocked
__UI.mainFrame.ZIndex = 5
__UI.mainFrame.Parent = screenGui

__UI.uiCorner = Instance.new("UICorner")
__UI.uiCorner.CornerRadius = UDim.new(0, 14)
__UI.uiCorner.Parent = __UI.mainFrame

__UI.uiStroke = Instance.new("UIStroke")
__UI.uiStroke.Thickness = 2.5
__UI.uiStroke.Color = Color3.fromRGB(125, 211, 252)
__UI.uiStroke.Parent = __UI.mainFrame

__UI.topBar = Instance.new("Frame")
__UI.topBar.Name = "TopBar"
__UI.topBar.Size = UDim2.new(1, 0, 0, 45)
__UI.topBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.topBar.BorderSizePixel = 0
__UI.topBar.ZIndex = 6
__UI.topBar.Parent = __UI.mainFrame

__UI.topCorner = Instance.new("UICorner")
__UI.topCorner.CornerRadius = UDim.new(0, 14)
__UI.topCorner.Parent = __UI.topBar

__UI.topCover = Instance.new("Frame")
__UI.topCover.Size = UDim2.new(1, 0, 0, 10)
__UI.topCover.Position = UDim2.new(0, 0, 1, -10)
__UI.topCover.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.topCover.BorderSizePixel = 0
__UI.topCover.ZIndex = 6
__UI.topCover.Parent = __UI.topBar

__UI.titleLabel = Instance.new("TextLabel")
__UI.titleLabel.Name = "TitleLabel"
__UI.titleLabel.Size = UDim2.new(1, -20, 1, 0)
__UI.titleLabel.Position = UDim2.new(0, 20, 0, 0)
__UI.titleLabel.BackgroundTransparency = 1
__UI.titleLabel.Text = "❄️ SOLANASZ // XMAS FROST HUB & STATS"
__UI.titleLabel.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.titleLabel.TextSize = 16
__UI.titleLabel.Font = Enum.Font.GothamBold
__UI.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
__UI.titleLabel.ZIndex = 7
__UI.titleLabel.Parent = __UI.topBar

__UI.line = Instance.new("Frame")
__UI.line.Size = UDim2.new(1, -30, 0, 1)
__UI.line.Position = UDim2.new(0, 15, 1, 0)
__UI.line.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
__UI.line.BorderSizePixel = 0
__UI.line.ZIndex = 6
__UI.line.Parent = __UI.topBar

__UI.rivalsButton = Instance.new("TextButton")
__UI.rivalsButton.Name = "RivalsButton"
__UI.rivalsButton.Size = UDim2.new(0.85, 0, 0, 75)
__UI.rivalsButton.AnchorPoint = Vector2.new(0.5, 0.5)
__UI.rivalsButton.Position = UDim2.new(0.5, 0, 0.55, 0)
__UI.rivalsButton.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.rivalsButton.Text = "🎄 SOLANAZ XMAS HUB"
__UI.rivalsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.rivalsButton.TextSize = 20
__UI.rivalsButton.Font = Enum.Font.GothamBold
__UI.rivalsButton.ZIndex = 6
__UI.rivalsButton.Parent = __UI.mainFrame

__UI.rivalsCorner = Instance.new("UICorner")
__UI.rivalsCorner.CornerRadius = UDim.new(0, 10)
__UI.rivalsCorner.Parent = __UI.rivalsButton

__UI.rivalsStroke = Instance.new("UIStroke")
__UI.rivalsStroke.Thickness = 1.5
__UI.rivalsStroke.Color = Color3.fromRGB(225, 29, 72)
__UI.rivalsStroke.Parent = __UI.rivalsButton

--------------------------------------------------------------------------------
-- HAUPT-STEUERUNGS-POP-UP
--------------------------------------------------------------------------------
__UI.draggablePopup = Instance.new("Frame")
__UI.draggablePopup.Name = "DraggablePopup"
__UI.draggablePopup.Size = UDim2.new(0, 300, 0, 365)
__UI.draggablePopup.AnchorPoint = Vector2.new(1, 1)
__UI.draggablePopup.Position = UDim2.new(1, -15, 1, -40)
__UI.draggablePopup.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
__UI.draggablePopup.BorderSizePixel = 0
__UI.draggablePopup.Visible = false
__UI.draggablePopup.ZIndex = 20
__UI.draggablePopup.Parent = screenGui

__UI.popCorner = Instance.new("UICorner")
__UI.popCorner.CornerRadius = UDim.new(0, 14)
__UI.popCorner.Parent = __UI.draggablePopup

__UI.popStroke = Instance.new("UIStroke")
__UI.popStroke.Thickness = 2.5
__UI.popStroke.Color = Color3.fromRGB(125, 211, 252)
__UI.popStroke.Parent = __UI.draggablePopup

__UI.popTopBar = Instance.new("TextButton")
__UI.popTopBar.Name = "PopTopBar"
__UI.popTopBar.Size = UDim2.new(1, 0, 0, 35)
__UI.popTopBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.popTopBar.Text = "   ❄️ SOLANAZ // CONTROLS"
__UI.popTopBar.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.popTopBar.TextSize = 13
__UI.popTopBar.Font = Enum.Font.GothamBold
__UI.popTopBar.TextXAlignment = Enum.TextXAlignment.Left
__UI.popTopBar.ZIndex = 21
__UI.popTopBar.Parent = __UI.draggablePopup

__UI.popTopCorner = Instance.new("UICorner")
__UI.popTopCorner.CornerRadius = UDim.new(0, 14)
__UI.popTopCorner.Parent = __UI.popTopBar

__UI.popTopCover = Instance.new("Frame")
__UI.popTopCover.Size = UDim2.new(1, 0, 0, 10)
__UI.popTopCover.Position = UDim2.new(0, 0, 1, -10)
__UI.popTopCover.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.popTopCover.BorderSizePixel = 0
__UI.popTopCover.ZIndex = 21
__UI.popTopCover.Parent = __UI.popTopBar

__UI.noclipBtn = Instance.new("TextButton")
__UI.noclipBtn.Name = "NoclipBtn"
__UI.noclipBtn.Size = UDim2.new(0.86, 0, 0, 30)
__UI.noclipBtn.Position = UDim2.new(0.07, 0, 0, 44)
__UI.noclipBtn.BackgroundColor3 = configData.noclip and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.noclipBtn.Text = configData.noclip and "NoClip: ON" or "NoClip: OFF"
__UI.noclipBtn.TextColor3 = configData.noclip and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.noclipBtn.TextSize = 12
__UI.noclipBtn.Font = Enum.Font.GothamBold
__UI.noclipBtn.ZIndex = 21
__UI.noclipBtn.Parent = __UI.draggablePopup

__UI.noclipCorner = Instance.new("UICorner")
__UI.noclipCorner.CornerRadius = UDim.new(0, 8)
__UI.noclipCorner.Parent = __UI.noclipBtn

__UI.noclipStroke = Instance.new("UIStroke")
__UI.noclipStroke.Thickness = 1.5
__UI.noclipStroke.Color = configData.noclip and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
__UI.noclipStroke.Parent = __UI.noclipBtn

__UI.flyBtn = Instance.new("TextButton")
__UI.flyBtn.Name = "FlyBtn"
__UI.flyBtn.Size = UDim2.new(0.86, 0, 0, 30)
__UI.flyBtn.Position = UDim2.new(0.07, 0, 0, 78)
__UI.flyBtn.BackgroundColor3 = configData.fly and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.flyBtn.Text = configData.fly and "Fly Mode: ON" or "Fly Mode: OFF"
__UI.flyBtn.TextColor3 = configData.fly and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.flyBtn.TextSize = 12
__UI.flyBtn.Font = Enum.Font.GothamBold
__UI.flyBtn.ZIndex = 21
__UI.flyBtn.Parent = __UI.draggablePopup

__UI.flyCorner = Instance.new("UICorner")
__UI.flyCorner.CornerRadius = UDim.new(0, 8)
__UI.flyCorner.Parent = __UI.flyBtn

__UI.flyStroke = Instance.new("UIStroke")
__UI.flyStroke.Thickness = 1.5
__UI.flyStroke.Color = configData.fly and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
__UI.flyStroke.Parent = __UI.flyBtn

__UI.infJumpBtn = Instance.new("TextButton")
__UI.infJumpBtn.Name = "InfJumpBtn"
__UI.infJumpBtn.Size = UDim2.new(0.86, 0, 0, 30)
__UI.infJumpBtn.Position = UDim2.new(0.07, 0, 0, 112)
__UI.infJumpBtn.BackgroundColor3 = configData.infJump and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.infJumpBtn.Text = configData.infJump and "Infinite Jump: ON" or "Infinite Jump: OFF"
__UI.infJumpBtn.TextColor3 = configData.infJump and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.infJumpBtn.TextSize = 12
__UI.infJumpBtn.Font = Enum.Font.GothamBold
__UI.infJumpBtn.ZIndex = 21
__UI.infJumpBtn.Parent = __UI.draggablePopup

__UI.infJumpCorner = Instance.new("UICorner")
__UI.infJumpCorner.CornerRadius = UDim.new(0, 8)
__UI.infJumpCorner.Parent = __UI.infJumpBtn

__UI.infJumpStroke = Instance.new("UIStroke")
__UI.infJumpStroke.Thickness = 1.5
__UI.infJumpStroke.Color = configData.infJump and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
__UI.infJumpStroke.Parent = __UI.infJumpBtn

__UI.autoRespawnBtn = Instance.new("TextButton")
__UI.autoRespawnBtn.Name = "AutoRespawnBtn"
__UI.autoRespawnBtn.Size = UDim2.new(0.86, 0, 0, 30)
__UI.autoRespawnBtn.Position = UDim2.new(0.07, 0, 0, 146)
__UI.autoRespawnBtn.BackgroundColor3 = configData.autoRespawn and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.autoRespawnBtn.Text = configData.autoRespawn and "Auto-Respawn: ON" or "Auto-Respawn: OFF"
__UI.autoRespawnBtn.TextColor3 = configData.autoRespawn and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.autoRespawnBtn.TextSize = 12
__UI.autoRespawnBtn.Font = Enum.Font.GothamBold
__UI.autoRespawnBtn.ZIndex = 21
__UI.autoRespawnBtn.Parent = __UI.draggablePopup

__UI.autoRespawnCorner = Instance.new("UICorner")
__UI.autoRespawnCorner.CornerRadius = UDim.new(0, 8)
__UI.autoRespawnCorner.Parent = __UI.autoRespawnBtn

__UI.autoRespawnStroke = Instance.new("UIStroke")
__UI.autoRespawnStroke.Thickness = 1.5
__UI.autoRespawnStroke.Color = configData.autoRespawn and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
__UI.autoRespawnStroke.Parent = __UI.autoRespawnBtn

__UI.speedBox = Instance.new("TextBox")
__UI.speedBox.Name = "SpeedBox"
__UI.speedBox.Size = UDim2.new(0.86, 0, 0, 30)
__UI.speedBox.Position = UDim2.new(0.07, 0, 0, 180)
__UI.speedBox.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.speedBox.Text = tostring(configData.speed)
__UI.speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.speedBox.TextSize = 12
__UI.speedBox.Font = Enum.Font.GothamMedium
__UI.speedBox.ClearTextOnFocus = false
__UI.speedBox.ZIndex = 21
__UI.speedBox.Parent = __UI.draggablePopup

__UI.speedBoxCorner = Instance.new("UICorner")
__UI.speedBoxCorner.CornerRadius = UDim.new(0, 8)
__UI.speedBoxCorner.Parent = __UI.speedBox

__UI.speedBoxStroke = Instance.new("UIStroke")
__UI.speedBoxStroke.Thickness = 1.5
__UI.speedBoxStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.speedBoxStroke.Parent = __UI.speedBox

__UI.setSpeedBtn = Instance.new("TextButton")
__UI.setSpeedBtn.Name = "SetSpeedBtn"
__UI.setSpeedBtn.Size = UDim2.new(0.41, 0, 0, 30)
__UI.setSpeedBtn.Position = UDim2.new(0.07, 0, 0, 214)
__UI.setSpeedBtn.BackgroundColor3 = Color3.fromRGB(14, 116, 144)
__UI.setSpeedBtn.Text = "SET SPEED"
__UI.setSpeedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.setSpeedBtn.TextSize = 11
__UI.setSpeedBtn.Font = Enum.Font.GothamBold
__UI.setSpeedBtn.ZIndex = 21
__UI.setSpeedBtn.Parent = __UI.draggablePopup

__UI.setSpeedCorner = Instance.new("UICorner")
__UI.setSpeedCorner.CornerRadius = UDim.new(0, 8)
__UI.setSpeedCorner.Parent = __UI.setSpeedBtn

__UI.resetSpeedBtn = Instance.new("TextButton")
__UI.resetSpeedBtn.Name = "ResetSpeedBtn"
__UI.resetSpeedBtn.Size = UDim2.new(0.43, 0, 0, 30)
__UI.resetSpeedBtn.Position = UDim2.new(0.5, 0, 0, 214)
__UI.resetSpeedBtn.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
__UI.resetSpeedBtn.Text = "RESET"
__UI.resetSpeedBtn.TextColor3 = Color3.fromRGB(203, 213, 225)
__UI.resetSpeedBtn.TextSize = 11
__UI.resetSpeedBtn.Font = Enum.Font.GothamBold
__UI.resetSpeedBtn.ZIndex = 21
__UI.resetSpeedBtn.Parent = __UI.draggablePopup

__UI.resetSpeedCorner = Instance.new("UICorner")
__UI.resetSpeedCorner.CornerRadius = UDim.new(0, 8)
__UI.resetSpeedCorner.Parent = __UI.resetSpeedBtn

__UI.cancelBtn = Instance.new("TextButton")
__UI.cancelBtn.Name = "CancelBtn"
__UI.cancelBtn.Size = UDim2.new(0.86, 0, 0, 32)
__UI.cancelBtn.Position = UDim2.new(0.07, 0, 0, 252)
__UI.cancelBtn.BackgroundColor3 = Color3.fromRGB(190, 18, 60)
__UI.cancelBtn.Text = "CLOSE UI"
__UI.cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.cancelBtn.TextSize = 12
__UI.cancelBtn.Font = Enum.Font.GothamBold
__UI.cancelBtn.ZIndex = 21
__UI.cancelBtn.Parent = __UI.draggablePopup

--------------------------------------------------------------------------------
-- FOV / MENÜ FENSTER
--------------------------------------------------------------------------------
__UI.fovPopup = Instance.new("Frame")
__UI.fovPopup.Name = "FovPopup"
__UI.fovPopup.Size = UDim2.new(0, 260, 0, 355)
__UI.fovPopup.AnchorPoint = Vector2.new(1, 1)
__UI.fovPopup.Position = UDim2.new(1, -330, 1, -40)
__UI.fovPopup.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
__UI.fovPopup.BorderSizePixel = 0
__UI.fovPopup.Visible = false
__UI.fovPopup.ZIndex = 20
__UI.fovPopup.Parent = screenGui

__UI.fovCorner = Instance.new("UICorner")
__UI.fovCorner.CornerRadius = UDim.new(0, 14)
__UI.fovCorner.Parent = __UI.fovPopup

__UI.fovStroke = Instance.new("UIStroke")
__UI.fovStroke.Thickness = 2.5
__UI.fovStroke.Color = Color3.fromRGB(125, 211, 252)
__UI.fovStroke.Parent = __UI.fovPopup

__UI.fovTopBar = Instance.new("Frame")
__UI.fovTopBar.Name = "FovTopBar"
__UI.fovTopBar.Size = UDim2.new(1, 0, 0, 30)
__UI.fovTopBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.fovTopBar.BorderSizePixel = 0
__UI.fovTopBar.ZIndex = 21
__UI.fovTopBar.Parent = __UI.fovPopup

__UI.fovTopCorner = Instance.new("UICorner")
__UI.fovTopCorner.CornerRadius = UDim.new(0, 14)
__UI.fovTopCorner.Parent = __UI.fovTopBar

__UI.fovTopCover = Instance.new("Frame")
__UI.fovTopCover.Size = UDim2.new(1, 0, 0, 10)
__UI.fovTopCover.Position = UDim2.new(0, 0, 1, -10)
__UI.fovTopCover.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.fovTopCover.BorderSizePixel = 0
__UI.fovTopCover.ZIndex = 21
__UI.fovTopCover.Parent = __UI.fovTopBar

__UI.aimbotMenuBtn = Instance.new("TextButton")
__UI.aimbotMenuBtn.Name = "AimbotMenuBtn"
__UI.aimbotMenuBtn.Size = UDim2.new(0.86, 0, 0, 26)
__UI.aimbotMenuBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.aimbotMenuBtn.Position = UDim2.new(0.5, 0, 0, 38)
__UI.aimbotMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.aimbotMenuBtn.Text = "AIMBOT: OFF"
__UI.aimbotMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
__UI.aimbotMenuBtn.TextSize = 12
__UI.aimbotMenuBtn.Font = Enum.Font.GothamBold
__UI.aimbotMenuBtn.ZIndex = 21
__UI.aimbotMenuBtn.Parent = __UI.fovPopup

__UI.aimbotMenuCorner = Instance.new("UICorner")
__UI.aimbotMenuCorner.CornerRadius = UDim.new(0, 8)
__UI.aimbotMenuCorner.Parent = __UI.aimbotMenuBtn

__UI.aimbotMenuStroke = Instance.new("UIStroke")
__UI.aimbotMenuStroke.Thickness = 1.5
__UI.aimbotMenuStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.aimbotMenuStroke.Parent = __UI.aimbotMenuBtn

__UI.settingsMenuBtn = Instance.new("TextButton")
__UI.settingsMenuBtn.Name = "SettingsMenuBtn"
__UI.settingsMenuBtn.Size = UDim2.new(0.86, 0, 0, 26)
__UI.settingsMenuBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.settingsMenuBtn.Position = UDim2.new(0.5, 0, 0, 72)
__UI.settingsMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.settingsMenuBtn.Text = "SETTINGS: OFF"
__UI.settingsMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
__UI.settingsMenuBtn.TextSize = 12
__UI.settingsMenuBtn.Font = Enum.Font.GothamBold
__UI.settingsMenuBtn.ZIndex = 21
__UI.settingsMenuBtn.Parent = __UI.fovPopup

__UI.settingsMenuCorner = Instance.new("UICorner")
__UI.settingsMenuCorner.CornerRadius = UDim.new(0, 8)
__UI.settingsMenuCorner.Parent = __UI.settingsMenuBtn

__UI.settingsMenuStroke = Instance.new("UIStroke")
__UI.settingsMenuStroke.Thickness = 1.5
__UI.settingsMenuStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.settingsMenuStroke.Parent = __UI.settingsMenuBtn

__UI.tpMenuBtn = Instance.new("TextButton")
__UI.tpMenuBtn.Name = "TpMenuBtn"
__UI.tpMenuBtn.Size = UDim2.new(0.86, 0, 0, 26)
__UI.tpMenuBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.tpMenuBtn.Position = UDim2.new(0.5, 0, 0, 106)
__UI.tpMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.tpMenuBtn.Text = "TP SETTINGS: OFF"
__UI.tpMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
__UI.tpMenuBtn.TextSize = 12
__UI.tpMenuBtn.Font = Enum.Font.GothamBold
__UI.tpMenuBtn.ZIndex = 21
__UI.tpMenuBtn.Parent = __UI.fovPopup

__UI.tpMenuCorner = Instance.new("UICorner")
__UI.tpMenuCorner.CornerRadius = UDim.new(0, 8)
__UI.tpMenuCorner.Parent = __UI.tpMenuBtn

__UI.tpMenuStroke = Instance.new("UIStroke")
__UI.tpMenuStroke.Thickness = 1.5
__UI.tpMenuStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.tpMenuStroke.Parent = __UI.tpMenuBtn

__UI.espMenuBtn = Instance.new("TextButton")
__UI.espMenuBtn.Name = "EspMenuBtn"
__UI.espMenuBtn.Size = UDim2.new(0.86, 0, 0, 26)
__UI.espMenuBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.espMenuBtn.Position = UDim2.new(0.5, 0, 0, 140)
__UI.espMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.espMenuBtn.Text = "ESP MENU: OFF"
__UI.espMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
__UI.espMenuBtn.TextSize = 12
__UI.espMenuBtn.Font = Enum.Font.GothamBold
__UI.espMenuBtn.ZIndex = 21
__UI.espMenuBtn.Parent = __UI.fovPopup

__UI.espMenuCorner = Instance.new("UICorner")
__UI.espMenuCorner.CornerRadius = UDim.new(0, 8)
__UI.espMenuCorner.Parent = __UI.espMenuBtn

__UI.espMenuStroke = Instance.new("UIStroke")
__UI.espMenuStroke.Thickness = 1.5
__UI.espMenuStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.espMenuStroke.Parent = __UI.espMenuBtn

__UI.moreMenuBtn = Instance.new("TextButton")
__UI.moreMenuBtn.Name = "MoreMenuBtn"
__UI.moreMenuBtn.Size = UDim2.new(0.86, 0, 0, 26)
__UI.moreMenuBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.moreMenuBtn.Position = UDim2.new(0.5, 0, 0, 174)
__UI.moreMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.moreMenuBtn.Text = "More... : OFF"
__UI.moreMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
__UI.moreMenuBtn.TextSize = 12
__UI.moreMenuBtn.Font = Enum.Font.GothamBold
__UI.moreMenuBtn.ZIndex = 21
__UI.moreMenuBtn.Parent = __UI.fovPopup

__UI.moreMenuCorner = Instance.new("UICorner")
__UI.moreMenuCorner.CornerRadius = UDim.new(0, 8)
__UI.moreMenuCorner.Parent = __UI.moreMenuBtn

__UI.moreMenuStroke = Instance.new("UIStroke")
__UI.moreMenuStroke.Thickness = 1.5
__UI.moreMenuStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.moreMenuStroke.Parent = __UI.moreMenuBtn

__UI.fovToggleBtn = Instance.new("TextButton")
__UI.fovToggleBtn.Name = "FovToggleBtn"
__UI.fovToggleBtn.Size = UDim2.new(0.86, 0, 0, 26)
__UI.fovToggleBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.fovToggleBtn.Position = UDim2.new(0.5, 0, 0, 208)
__UI.fovToggleBtn.BackgroundColor3 = configData.fovCircle and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.fovToggleBtn.Text = configData.fovCircle and "FOV CIRCLE: ON" or "FOV CIRCLE: OFF"
__UI.fovToggleBtn.TextColor3 = configData.fovCircle and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.fovToggleBtn.TextSize = 12
__UI.fovToggleBtn.Font = Enum.Font.GothamBold
__UI.fovToggleBtn.ZIndex = 21
__UI.fovToggleBtn.Parent = __UI.fovPopup

__UI.fovToggleCorner = Instance.new("UICorner")
__UI.fovToggleCorner.CornerRadius = UDim.new(0, 8)
__UI.fovToggleCorner.Parent = __UI.fovToggleBtn

__UI.fovToggleStroke = Instance.new("UIStroke")
__UI.fovToggleStroke.Thickness = 1.5
__UI.fovToggleStroke.Color = configData.fovCircle and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
__UI.fovToggleStroke.Parent = __UI.fovToggleBtn

__UI.fovLabel = Instance.new("TextLabel")
__UI.fovLabel.Name = "FovLabel"
__UI.fovLabel.Size = UDim2.new(1, 0, 0, 16)
__UI.fovLabel.Position = UDim2.new(0, 0, 0, 238)
__UI.fovLabel.BackgroundTransparency = 1
pcall(function() camera.FieldOfView = configData.cameraFov or camera.FieldOfView end)
__UI.fovLabel.Text = "Camera FOV: " .. math.round(camera.FieldOfView)
__UI.fovLabel.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.fovLabel.TextSize = 11
__UI.fovLabel.Font = Enum.Font.GothamBold
__UI.fovLabel.ZIndex = 21
__UI.fovLabel.Parent = __UI.fovPopup

__UI.sliderBar = Instance.new("Frame")
__UI.sliderBar.Name = "SliderBar"
__UI.sliderBar.Size = UDim2.new(0.8, 0, 0, 6)
__UI.sliderBar.AnchorPoint = Vector2.new(0.5, 0.5)
__UI.sliderBar.Position = UDim2.new(0.5, 0, 0, 262)
__UI.sliderBar.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
__UI.sliderBar.BorderSizePixel = 0
__UI.sliderBar.ZIndex = 21
__UI.sliderBar.Parent = __UI.fovPopup

__UI.sliderBarCorner = Instance.new("UICorner")
__UI.sliderBarCorner.CornerRadius = UDim.new(1, 0)
__UI.sliderBarCorner.Parent = __UI.sliderBar

__UI.sliderKnob = Instance.new("TextButton")
__UI.sliderKnob.Name = "SliderKnob"
__UI.sliderKnob.Size = UDim2.new(0, 14, 0, 14)
__UI.sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
local initialFov = math.clamp(camera.FieldOfView, 0, 200)
__UI.sliderKnob.Position = UDim2.new(initialFov / 200, 0, 0.5, 0)
__UI.sliderKnob.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
__UI.sliderKnob.Text = ""
__UI.sliderKnob.ZIndex = 22
__UI.sliderKnob.Parent = __UI.sliderBar

__UI.sliderKnobCorner = Instance.new("UICorner")
__UI.sliderKnobCorner.CornerRadius = UDim.new(1, 0)
__UI.sliderKnobCorner.Parent = __UI.sliderKnob

__UI.fovRadiusLabel = Instance.new("TextLabel")
__UI.fovRadiusLabel.Name = "FovRadiusLabel"
__UI.fovRadiusLabel.Size = UDim2.new(1, 0, 0, 16)
__UI.fovRadiusLabel.Position = UDim2.new(0, 0, 0, 278)
__UI.fovRadiusLabel.BackgroundTransparency = 1
__UI.fovRadiusLabel.Text = "FOV Circle Size: " .. (configData.fovRadius or 150) .. " px"
__UI.fovRadiusLabel.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.fovRadiusLabel.TextSize = 11
__UI.fovRadiusLabel.Font = Enum.Font.GothamBold
__UI.fovRadiusLabel.ZIndex = 21
__UI.fovRadiusLabel.Parent = __UI.fovPopup

__UI.fovRadiusBar = Instance.new("Frame")
__UI.fovRadiusBar.Name = "FovRadiusBar"
__UI.fovRadiusBar.Size = UDim2.new(0.8, 0, 0, 6)
__UI.fovRadiusBar.AnchorPoint = Vector2.new(0.5, 0.5)
__UI.fovRadiusBar.Position = UDim2.new(0.5, 0, 0, 304)
__UI.fovRadiusBar.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
__UI.fovRadiusBar.BorderSizePixel = 0
__UI.fovRadiusBar.ZIndex = 21
__UI.fovRadiusBar.Parent = __UI.fovPopup

__UI.fovRadiusBarCorner = Instance.new("UICorner")
__UI.fovRadiusBarCorner.CornerRadius = UDim.new(1, 0)
__UI.fovRadiusBarCorner.Parent = __UI.fovRadiusBar

__UI.fovRadiusKnob = Instance.new("TextButton")
__UI.fovRadiusKnob.Name = "FovRadiusKnob"
__UI.fovRadiusKnob.Size = UDim2.new(0, 14, 0, 14)
__UI.fovRadiusKnob.AnchorPoint = Vector2.new(0.5, 0.5)
__UI.fovRadiusKnob.Position = UDim2.new((configData.fovRadius or 150) / 2500, 0, 0.5, 0)
__UI.fovRadiusKnob.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
__UI.fovRadiusKnob.Text = ""
__UI.fovRadiusKnob.ZIndex = 22
__UI.fovRadiusKnob.Parent = __UI.fovRadiusBar

__UI.fovRadiusKnobCorner = Instance.new("UICorner")
__UI.fovRadiusKnobCorner.CornerRadius = UDim.new(1, 0)
__UI.fovRadiusKnobCorner.Parent = __UI.fovRadiusKnob

--------------------------------------------------------------------------------
-- INTELLIGENTE ECKEN-SPAWN-LOGIK
--------------------------------------------------------------------------------
local function getMarkedAreaGridPosition(popupWidth, popupHeight, existingPopups)
	local viewportSize = camera.ViewportSize
	local maxX = viewportSize.X - 15
	local minX = math.max(20, viewportSize.X - popupWidth - 400)
	local maxY = viewportSize.Y - 40
	local minY = math.max(50, viewportSize.Y - popupHeight - 450)

	for row = 0, 5 do
		for col = 0, 5 do
			local testX = maxX - (col * (popupWidth + 12))
			local testY = maxY - (row * (popupHeight + 12))
			
			if testX >= minX and testX <= maxX and testY >= minY and testY <= maxY then
				local testPos = Vector2.new(testX - popupWidth, testY - popupHeight)
				local safe = true

				for _, other in ipairs(existingPopups) do
					if other and other.Visible then
						local oPos = other.AbsolutePosition
						local oSize = other.AbsoluteSize
						
						if not (testPos.X + popupWidth + 8 < oPos.X or 
							testPos.X > oPos.X + oSize.X + 8 or 
							testPos.Y + popupHeight + 8 < oPos.Y or 
							testPos.Y > oPos.Y + oSize.Y + 8) then
							safe = false
							break
						end
					end
				end

				if safe then
					return UDim2.new(0, testX, 0, testY)
				end
			end
		end
	end

	return UDim2.new(1, -25, 1, -50)
end

-- MORE... SUB-POPUP
__UI.moreSubPopup = Instance.new("Frame")
__UI.moreSubPopup.Name = "MoreSubPopup"
__UI.moreSubPopup.Size = UDim2.new(0, 240, 0, 310)
__UI.moreSubPopup.AnchorPoint = Vector2.new(1, 1)
__UI.moreSubPopup.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
__UI.moreSubPopup.BorderSizePixel = 0
__UI.moreSubPopup.Visible = false
__UI.moreSubPopup.ZIndex = 30
__UI.moreSubPopup.Parent = screenGui

__UI.moreSubCorner = Instance.new("UICorner")
__UI.moreSubCorner.CornerRadius = UDim.new(0, 14)
moreSubSubCorner = __UI.moreSubCorner
__UI.moreSubPopup.Parent = screenGui -- kept identical structure

__UI.moreSubStroke = Instance.new("UIStroke")
__UI.moreSubStroke.Thickness = 2.5
__UI.moreSubStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.moreSubStroke.Parent = __UI.moreSubPopup

__UI.moreSubTopBar = Instance.new("Frame")
__UI.moreSubTopBar.Name = "MoreSubTopBar"
__UI.moreSubTopBar.Size = UDim2.new(1, 0, 0, 30)
__UI.moreSubTopBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.moreSubTopBar.BorderSizePixel = 0
__UI.moreSubTopBar.ZIndex = 31
__UI.moreSubTopBar.Parent = __UI.moreSubPopup

__UI.moreSubTopCorner = Instance.new("UICorner")
__UI.moreSubTopCorner.CornerRadius = UDim.new(0, 14)
__UI.moreSubTopCorner.Parent = __UI.moreSubTopBar

__UI.moreSubTopCover = Instance.new("Frame")
__UI.moreSubTopCover.Size = UDim2.new(1, 0, 0, 10)
__UI.moreSubTopCover.Position = UDim2.new(0, 0, 1, -10)
__UI.moreSubTopCover.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.moreSubTopCover.BorderSizePixel = 0
__UI.moreSubTopCover.ZIndex = 31
__UI.moreSubTopCover.Parent = __UI.moreSubTopBar

__UI.moreSubTitle = Instance.new("TextLabel")
__UI.moreSubTitle.Size = UDim2.new(1, -15, 1, 0)
__UI.moreSubTitle.Position = UDim2.new(0, 15, 0, 0)
__UI.moreSubTitle.BackgroundTransparency = 1
__UI.moreSubTitle.Text = "❄️ MORE OPTIONS & ACTIONS"
__UI.moreSubTitle.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.moreSubTitle.TextSize = 12
__UI.moreSubTitle.Font = Enum.Font.GothamBold
__UI.moreSubTitle.TextXAlignment = Enum.TextXAlignment.Left
__UI.moreSubTitle.ZIndex = 31
__UI.moreSubTitle.Parent = __UI.moreSubTopBar

local function createMoreActionButton(name, text, posY, colorBg)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.86, 0, 0, 32)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.Position = UDim2.new(0.5, 0, 0, posY)
	btn.BackgroundColor3 = colorBg
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 31
	btn.Parent = __UI.moreSubPopup

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(125, 211, 252)
	stroke.Parent = btn

	return btn
end

local leaveBtn = createMoreActionButton("LeaveBtn", "🚪 Leave Game", 42, Color3.fromRGB(159, 18, 57))
local rejoinBtn = createMoreActionButton("RejoinBtn", "🔄 Rejoin Game", 84, Color3.fromRGB(14, 116, 144))
local serverHopBtn = createMoreActionButton("ServerHopBtn", "🌐 Server Hop", 126, Color3.fromRGB(79, 70, 229))

leaveBtn.MouseButton1Click:Connect(function()
	pcall(function() game:Shutdown() end)
end)

rejoinBtn.MouseButton1Click:Connect(function()
	pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
end)

serverHopBtn.MouseButton1Click:Connect(function()
	pcall(function()
		local servers = {}
		local req = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
		if req and req.data then
			for _, s in ipairs(req.data) do
				if type(s) == "table" and s.playing < s.maxPlayers and s.id ~= game.JobId then
					table.insert(servers, s.id)
				end
			end
		end
		if #servers > 0 then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], player)
		else
			serverHopBtn.Text = "Kein Server gefunden!"
			task.delay(1.5, function() serverHopBtn.Text = "🌐 Server Hop" end)
		end
	end)
end)

__UI.moreInfoLabel = Instance.new("TextLabel")
__UI.moreInfoLabel.Size = UDim2.new(0.86, 0, 0, 110)
__UI.moreInfoLabel.Position = UDim2.new(0.07, 0, 0, 170)
__UI.moreInfoLabel.BackgroundTransparency = 1
__UI.moreInfoLabel.Text = "• Solanasz Frost Active\n• Script Version: 2.8 Pro\n• Corner Smart Spawning"
__UI.moreInfoLabel.TextColor3 = Color3.fromRGB(186, 230, 253)
__UI.moreInfoLabel.TextSize = 11
__UI.moreInfoLabel.Font = Enum.Font.GothamMedium
__UI.moreInfoLabel.TextWrapped = true
__UI.moreInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
__UI.moreInfoLabel.ZIndex = 31
__UI.moreInfoLabel.Parent = __UI.moreSubPopup

-- 1. AIMBOT SUB-POPUP
__UI.aimbotSubPopup = Instance.new("Frame")
__UI.aimbotSubPopup.Name = "AimbotSubPopup"
__UI.aimbotSubPopup.Size = UDim2.new(0, 240, 0, 410)
__UI.aimbotSubPopup.AnchorPoint = Vector2.new(1, 1)
__UI.aimbotSubPopup.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
__UI.aimbotSubPopup.BorderSizePixel = 0
__UI.aimbotSubPopup.Visible = false
__UI.aimbotSubPopup.ZIndex = 30
__UI.aimbotSubPopup.Parent = screenGui

__UI.aimbotSubCorner = Instance.new("UICorner")
__UI.aimbotSubCorner.CornerRadius = UDim.new(0, 14)
__UI.aimbotSubCorner.Parent = __UI.aimbotSubPopup

__UI.aimbotSubStroke = Instance.new("UIStroke")
__UI.aimbotSubStroke.Thickness = 2.5
__UI.aimbotSubStroke.Color = Color3.fromRGB(52, 211, 153)
__UI.aimbotSubStroke.Parent = __UI.aimbotSubPopup

__UI.aimbotSubTopBar = Instance.new("Frame")
__UI.aimbotSubTopBar.Name = "AimbotSubTopBar"
__UI.aimbotSubTopBar.Size = UDim2.new(1, 0, 0, 30)
__UI.aimbotSubTopBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.aimbotSubTopBar.BorderSizePixel = 0
__UI.aimbotSubTopBar.ZIndex = 31
__UI.aimbotSubTopBar.Parent = __UI.aimbotSubPopup

__UI.aimbotSubTopCorner = Instance.new("UICorner")
__UI.aimbotSubTopCorner.CornerRadius = UDim.new(0, 14)
__UI.aimbotSubTopCorner.Parent = __UI.aimbotSubTopBar

__UI.aimbotSubTopCover = Instance.new("Frame")
__UI.aimbotSubTopCover.Size = UDim2.new(1, 0, 0, 10)
__UI.aimbotSubTopCover.Position = UDim2.new(0, 0, 1, -10)
__UI.aimbotSubTopCover.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.aimbotSubTopCover.BorderSizePixel = 0
__UI.aimbotSubTopCover.ZIndex = 31
__UI.aimbotSubTopCover.Parent = __UI.aimbotSubTopBar

__UI.aimbotSubTitle = Instance.new("TextLabel")
__UI.aimbotSubTitle.Size = UDim2.new(1, -15, 1, 0)
__UI.aimbotSubTitle.Position = UDim2.new(0, 15, 0, 0)
__UI.aimbotSubTitle.BackgroundTransparency = 1
__UI.aimbotSubTitle.Text = "❄️ AIMBOT & KEYBIND"
__UI.aimbotSubTitle.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.aimbotSubTitle.TextSize = 12
__UI.aimbotSubTitle.Font = Enum.Font.GothamBold
__UI.aimbotSubTitle.TextXAlignment = Enum.TextXAlignment.Left
__UI.aimbotSubTitle.ZIndex = 31
__UI.aimbotSubTitle.Parent = __UI.aimbotSubTopBar

__UI.aimbotToggleBtn = Instance.new("TextButton")
__UI.aimbotToggleBtn.Name = "AimbotToggleBtn"
__UI.aimbotToggleBtn.Size = UDim2.new(0.86, 0, 0, 26)
__UI.aimbotToggleBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.aimbotToggleBtn.Position = UDim2.new(0.5, 0, 0, 38)
__UI.aimbotToggleBtn.BackgroundColor3 = configData.aimbot and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.aimbotToggleBtn.Text = configData.aimbot and "Aimbot State: ON" or "Aimbot State: OFF"
__UI.aimbotToggleBtn.TextColor3 = configData.aimbot and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.aimbotToggleBtn.TextSize = 11
__UI.aimbotToggleBtn.Font = Enum.Font.GothamBold
__UI.aimbotToggleBtn.ZIndex = 31
__UI.aimbotToggleBtn.Parent = __UI.aimbotSubPopup

__UI.aimbotToggleCorner = Instance.new("UICorner")
__UI.aimbotToggleCorner.CornerRadius = UDim.new(0, 6)
__UI.aimbotToggleCorner.Parent = __UI.aimbotToggleBtn

__UI.aimbotToggleStroke = Instance.new("UIStroke")
__UI.aimbotToggleStroke.Thickness = 1.5
__UI.aimbotToggleStroke.Color = configData.aimbot and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
__UI.aimbotToggleStroke.Parent = __UI.aimbotToggleBtn

__UI.aimbotKeyBox = Instance.new("TextBox")
__UI.aimbotKeyBox.Name = "AimbotKeyBox"
__UI.aimbotKeyBox.Size = UDim2.new(0.86, 0, 0, 28)
__UI.aimbotKeyBox.AnchorPoint = Vector2.new(0.5, 0)
__UI.aimbotKeyBox.Position = UDim2.new(0.5, 0, 0, 69)
__UI.aimbotKeyBox.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.aimbotKeyBox.Text = configData.aimbotKey or ""
__UI.aimbotKeyBox.PlaceholderText = "Aimbot Taste (z.B. MouseButton2, E)"
__UI.aimbotKeyBox.PlaceholderColor3 = Color3.fromRGB(148, 163, 184)
__UI.aimbotKeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.aimbotKeyBox.TextSize = 11
__UI.aimbotKeyBox.Font = Enum.Font.GothamMedium
__UI.aimbotKeyBox.ClearTextOnFocus = false
__UI.aimbotKeyBox.ZIndex = 31
__UI.aimbotKeyBox.Parent = __UI.aimbotSubPopup

__UI.aimbotKeyBoxCorner = Instance.new("UICorner")
__UI.aimbotKeyBoxCorner.CornerRadius = UDim.new(0, 6)
__UI.aimbotKeyBoxCorner.Parent = __UI.aimbotKeyBox

__UI.aimbotKeyBoxStroke = Instance.new("UIStroke")
__UI.aimbotKeyBoxStroke.Thickness = 1.5
__UI.aimbotKeyBoxStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.aimbotKeyBoxStroke.Parent = __UI.aimbotKeyBox

__UI.backbotToggleBtn = Instance.new("TextButton")
__UI.backbotToggleBtn.Name = "BackbotToggleBtn"
__UI.backbotToggleBtn.Size = UDim2.new(0.86, 0, 0, 26)
__UI.backbotToggleBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.backbotToggleBtn.Position = UDim2.new(0.5, 0, 0, 103)
__UI.backbotToggleBtn.BackgroundColor3 = configData.backbot and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.backbotToggleBtn.Text = configData.backbot and "Backbot: ON" or "Backbot: OFF"
__UI.backbotToggleBtn.TextColor3 = configData.backbot and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.backbotToggleBtn.TextSize = 11
__UI.backbotToggleBtn.Font = Enum.Font.GothamBold
__UI.backbotToggleBtn.ZIndex = 31
__UI.backbotToggleBtn.Parent = __UI.aimbotSubPopup

__UI.backbotToggleCorner = Instance.new("UICorner")
__UI.backbotToggleCorner.CornerRadius = UDim.new(0, 6)
__UI.backbotToggleCorner.Parent = __UI.backbotToggleBtn

__UI.backbotToggleStroke = Instance.new("UIStroke")
__UI.backbotToggleStroke.Thickness = 1.5
__UI.backbotToggleStroke.Color = configData.backbot and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
__UI.backbotToggleStroke.Parent = __UI.backbotToggleBtn

__UI.wallCheckBtn = Instance.new("TextButton")
__UI.wallCheckBtn.Name = "WallCheckBtn"
__UI.wallCheckBtn.Size = UDim2.new(0.86, 0, 0, 26)
__UI.wallCheckBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.wallCheckBtn.Position = UDim2.new(0.5, 0, 0, 134)
__UI.wallCheckBtn.BackgroundColor3 = configData.wallCheck and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.wallCheckBtn.Text = configData.wallCheck and "WallCheck: ON" or "WallCheck: OFF"
__UI.wallCheckBtn.TextColor3 = configData.wallCheck and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.wallCheckBtn.TextSize = 11
__UI.wallCheckBtn.Font = Enum.Font.GothamBold
__UI.wallCheckBtn.ZIndex = 31
__UI.wallCheckBtn.Parent = __UI.aimbotSubPopup

__UI.wallCheckCorner = Instance.new("UICorner")
__UI.wallCheckCorner.CornerRadius = UDim.new(0, 6)
__UI.wallCheckCorner.Parent = __UI.wallCheckBtn

__UI.wallCheckStroke = Instance.new("UIStroke")
__UI.wallCheckStroke.Thickness = 1.5
__UI.wallCheckStroke.Color = configData.wallCheck and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
__UI.wallCheckStroke.Parent = __UI.wallCheckBtn

__UI.teamCheckBtn = Instance.new("TextButton")
__UI.teamCheckBtn.Name = "TeamCheckBtn"
__UI.teamCheckBtn.Size = UDim2.new(0.86, 0, 0, 26)
__UI.teamCheckBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.teamCheckBtn.Position = UDim2.new(0.5, 0, 0, 165)
__UI.teamCheckBtn.BackgroundColor3 = configData.teamCheck and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.teamCheckBtn.Text = configData.teamCheck and "TeamCheck: ON" or "TeamCheck: OFF"
__UI.teamCheckBtn.TextColor3 = configData.teamCheck and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.teamCheckBtn.TextSize = 11
__UI.teamCheckBtn.Font = Enum.Font.GothamBold
__UI.teamCheckBtn.ZIndex = 31
__UI.teamCheckBtn.Parent = __UI.aimbotSubPopup

__UI.teamCheckCorner = Instance.new("UICorner")
__UI.teamCheckCorner.CornerRadius = UDim.new(0, 6)
__UI.teamCheckCorner.Parent = __UI.teamCheckBtn

__UI.teamCheckStroke = Instance.new("UIStroke")
__UI.teamCheckStroke.Thickness = 1.5
__UI.teamCheckStroke.Color = configData.teamCheck and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
__UI.teamCheckStroke.Parent = __UI.teamCheckBtn

__UI.smoothnessLabel = Instance.new("TextLabel")
__UI.smoothnessLabel.Name = "SmoothnessLabel"
__UI.smoothnessLabel.Size = UDim2.new(1, 0, 0, 18)
__UI.smoothnessLabel.Position = UDim2.new(0, 0, 0, 196)
__UI.smoothnessLabel.BackgroundTransparency = 1
__UI.smoothnessLabel.Text = "Smoothness: " .. (configData.smoothness or 5)
__UI.smoothnessLabel.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.smoothnessLabel.TextSize = 11
__UI.smoothnessLabel.Font = Enum.Font.GothamBold
__UI.smoothnessLabel.ZIndex = 31
__UI.smoothnessLabel.Parent = __UI.aimbotSubPopup

__UI.smoothSliderBar = Instance.new("Frame")
__UI.smoothSliderBar.Name = "SmoothSliderBar"
__UI.smoothSliderBar.Size = UDim2.new(0.8, 0, 0, 6)
__UI.smoothSliderBar.AnchorPoint = Vector2.new(0.5, 0.5)
__UI.smoothSliderBar.Position = UDim2.new(0.5, 0, 0, 224)
__UI.smoothSliderBar.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
__UI.smoothSliderBar.BorderSizePixel = 0
__UI.smoothSliderBar.ZIndex = 31
__UI.smoothSliderBar.Parent = __UI.aimbotSubPopup

__UI.smoothSliderBarCorner = Instance.new("UICorner")
__UI.smoothSliderBarCorner.CornerRadius = UDim.new(1, 0)
__UI.smoothSliderBarCorner.Parent = __UI.smoothSliderBar

__UI.smoothSliderKnob = Instance.new("TextButton")
__UI.smoothSliderKnob.Name = "SmoothSliderKnob"
__UI.smoothSliderKnob.Size = UDim2.new(0, 14, 0, 14)
__UI.smoothSliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
__UI.smoothSliderKnob.Position = UDim2.new(((configData.smoothness or 5) - 1) / 19, 0, 0.5, 0)
__UI.smoothSliderKnob.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
__UI.smoothSliderKnob.Text = ""
__UI.smoothSliderKnob.ZIndex = 32
__UI.smoothSliderKnob.Parent = __UI.smoothSliderBar

__UI.smoothSliderKnobCorner = Instance.new("UICorner")
__UI.smoothSliderKnobCorner.CornerRadius = UDim.new(1, 0)
__UI.smoothSliderKnobCorner.Parent = __UI.smoothSliderKnob

__UI.distLabel = Instance.new("TextLabel")
__UI.distLabel.Name = "DistLabel"
__UI.distLabel.Size = UDim2.new(1, 0, 0, 18)
__UI.distLabel.Position = UDim2.new(0, 0, 0, 240)
__UI.distLabel.BackgroundTransparency = 1
__UI.distLabel.Text = "Max Distance: " .. (configData.maxDistance or 1000) .. " Studs"
__UI.distLabel.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.distLabel.TextSize = 11
__UI.distLabel.Font = Enum.Font.GothamBold
__UI.distLabel.ZIndex = 31
__UI.distLabel.Parent = __UI.aimbotSubPopup

__UI.distSliderBar = Instance.new("Frame")
__UI.distSliderBar.Name = "DistSliderBar"
__UI.distSliderBar.Size = UDim2.new(0.8, 0, 0, 6)
__UI.distSliderBar.AnchorPoint = Vector2.new(0.5, 0.5)
__UI.distSliderBar.Position = UDim2.new(0.5, 0, 0, 268)
__UI.distSliderBar.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
__UI.distSliderBar.BorderSizePixel = 0
__UI.distSliderBar.ZIndex = 31
__UI.distSliderBar.Parent = __UI.aimbotSubPopup

__UI.distSliderBarCorner = Instance.new("UICorner")
__UI.distSliderBarCorner.CornerRadius = UDim.new(1, 0)
__UI.distSliderBarCorner.Parent = __UI.distSliderBar

__UI.distSliderKnob = Instance.new("TextButton")
__UI.distSliderKnob.Name = "DistSliderKnob"
__UI.distSliderKnob.Size = UDim2.new(0, 14, 0, 14)
__UI.distSliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
__UI.distSliderKnob.Position = UDim2.new((configData.maxDistance or 1000) / 3500, 0, 0.5, 0)
__UI.distSliderKnob.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
__UI.distSliderKnob.Text = ""
__UI.distSliderKnob.ZIndex = 32
__UI.distSliderKnob.Parent = __UI.distSliderBar

__UI.distSliderKnobCorner = Instance.new("UICorner")
__UI.distSliderKnobCorner.CornerRadius = UDim.new(1, 0)
__UI.distSliderKnobCorner.Parent = __UI.distSliderBar

__UI.triggerbotMenuBtn = Instance.new("TextButton")
__UI.triggerbotMenuBtn.Name = "TriggerbotMenuBtn"
__UI.triggerbotMenuBtn.Size = UDim2.new(0.86, 0, 0, 28)
__UI.triggerbotMenuBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.triggerbotMenuBtn.Position = UDim2.new(0.5, 0, 0, 292)
__UI.triggerbotMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.triggerbotMenuBtn.Text = "TRIGGERBOT SETTINGS: OFF"
__UI.triggerbotMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
__UI.triggerbotMenuBtn.TextSize = 11
__UI.triggerbotMenuBtn.Font = Enum.Font.GothamBold
__UI.triggerbotMenuBtn.ZIndex = 31
__UI.triggerbotMenuBtn.Parent = __UI.aimbotSubPopup

__UI.triggerbotMenuCorner = Instance.new("UICorner")
__UI.triggerbotMenuCorner.CornerRadius = UDim.new(0, 6)
__UI.triggerbotMenuCorner.Parent = __UI.triggerbotMenuBtn

__UI.triggerbotMenuStroke = Instance.new("UIStroke")
__UI.triggerbotMenuStroke.Thickness = 1.5
__UI.triggerbotMenuStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.triggerbotMenuStroke.Parent = __UI.triggerbotMenuBtn

-- 2. TRIGGERBOT SUB-POPUP
__UI.triggerbotSubPopup = Instance.new("Frame")
__UI.triggerbotSubPopup.Name = "TriggerbotSubPopup"
__UI.triggerbotSubPopup.Size = UDim2.new(0, 240, 0, 150)
__UI.triggerbotSubPopup.AnchorPoint = Vector2.new(1, 1)
__UI.triggerbotSubPopup.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
__UI.triggerbotSubPopup.BorderSizePixel = 0
__UI.triggerbotSubPopup.Visible = false
__UI.triggerbotSubPopup.ZIndex = 40
__UI.triggerbotSubPopup.Parent = screenGui

__UI.triggerbotSubCorner = Instance.new("UICorner")
__UI.triggerbotSubCorner.CornerRadius = UDim.new(0, 14)
__UI.triggerbotSubCorner.Parent = __UI.triggerbotSubPopup

__UI.triggerbotSubStroke = Instance.new("UIStroke")
__UI.triggerbotSubStroke.Thickness = 2.5
__UI.triggerbotSubStroke.Color = Color3.fromRGB(168, 85, 247)
__UI.triggerbotSubStroke.Parent = __UI.triggerbotSubPopup

__UI.triggerbotSubTopBar = Instance.new("Frame")
__UI.triggerbotSubTopBar.Name = "TriggerbotSubTopBar"
__UI.triggerbotSubTopBar.Size = UDim2.new(1, 0, 0, 30)
__UI.triggerbotSubTopBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.triggerbotSubTopBar.BorderSizePixel = 0
__UI.triggerbotSubTopBar.ZIndex = 41
__UI.triggerbotSubTopBar.Parent = __UI.triggerbotSubPopup

__UI.triggerbotSubTopCorner = Instance.new("UICorner")
__UI.triggerbotSubTopCorner.CornerRadius = UDim.new(0, 14)
__UI.triggerbotSubTopCorner.Parent = __UI.triggerbotSubTopBar

__UI.triggerbotSubTopCover = Instance.new("Frame")
__UI.triggerbotSubTopCover.Size = UDim2.new(1, 0, 0, 10)
__UI.triggerbotSubTopCover.Position = UDim2.new(0, 0, 1, -10)
__UI.triggerbotSubTopCover.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.triggerbotSubTopCover.BorderSizePixel = 0
__UI.triggerbotSubTopCover.ZIndex = 41
__UI.triggerbotSubTopCover.Parent = __UI.triggerbotSubTopBar

__UI.triggerbotSubTitle = Instance.new("TextLabel")
__UI.triggerbotSubTitle.Size = UDim2.new(1, -15, 1, 0)
__UI.triggerbotSubTitle.Position = UDim2.new(0, 15, 0, 0)
__UI.triggerbotSubTitle.BackgroundTransparency = 1
__UI.triggerbotSubTitle.Text = "❄️ TRIGGERBOT SETTINGS"
__UI.triggerbotSubTitle.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.triggerbotSubTitle.TextSize = 12
__UI.triggerbotSubTitle.Font = Enum.Font.GothamBold
__UI.triggerbotSubTitle.TextXAlignment = Enum.TextXAlignment.Left
__UI.triggerbotSubTitle.ZIndex = 41
__UI.triggerbotSubTitle.Parent = __UI.triggerbotSubTopBar

__UI.triggerbotToggleBtn = Instance.new("TextButton")
__UI.triggerbotToggleBtn.Name = "TriggerbotToggleBtn"
__UI.triggerbotToggleBtn.Size = UDim2.new(0.86, 0, 0, 28)
__UI.triggerbotToggleBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.triggerbotToggleBtn.Position = UDim2.new(0.5, 0, 0, 38)
__UI.triggerbotToggleBtn.BackgroundColor3 = configData.triggerbot and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.triggerbotToggleBtn.Text = configData.triggerbot and "Triggerbot State: ON" or "Triggerbot State: OFF"
__UI.triggerbotToggleBtn.TextColor3 = configData.triggerbot and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.triggerbotToggleBtn.TextSize = 11
__UI.triggerbotToggleBtn.Font = Enum.Font.GothamBold
__UI.triggerbotToggleBtn.ZIndex = 41
__UI.triggerbotToggleBtn.Parent = __UI.triggerbotSubPopup

__UI.triggerbotToggleCorner = Instance.new("UICorner")
__UI.triggerbotToggleCorner.CornerRadius = UDim.new(0, 6)
__UI.triggerbotToggleCorner.Parent = __UI.triggerbotToggleBtn

__UI.triggerbotToggleStroke = Instance.new("UIStroke")
__UI.triggerbotToggleStroke.Thickness = 1.5
__UI.triggerbotToggleStroke.Color = configData.triggerbot and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
__UI.triggerbotToggleStroke.Parent = __UI.triggerbotToggleBtn

__UI.triggerbotDelayBox = Instance.new("TextBox")
__UI.triggerbotDelayBox.Name = "TriggerbotDelayBox"
__UI.triggerbotDelayBox.Size = UDim2.new(0.86, 0, 0, 32)
__UI.triggerbotDelayBox.AnchorPoint = Vector2.new(0.5, 0)
__UI.triggerbotDelayBox.Position = UDim2.new(0.5, 0, 0, 78)
__UI.triggerbotDelayBox.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.triggerbotDelayBox.Text = configData.triggerbotDelay or "0"
__UI.triggerbotDelayBox.PlaceholderText = "Delay in ms (z.B. 50)..."
__UI.triggerbotDelayBox.PlaceholderColor3 = Color3.fromRGB(148, 163, 184)
__UI.triggerbotDelayBox.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.triggerbotDelayBox.TextSize = 11
__UI.triggerbotDelayBox.Font = Enum.Font.GothamMedium
__UI.triggerbotDelayBox.ClearTextOnFocus = false
__UI.triggerbotDelayBox.ZIndex = 41
__UI.triggerbotDelayBox.Parent = __UI.triggerbotSubPopup

__UI.triggerbotDelayCorner = Instance.new("UICorner")
__UI.triggerbotDelayCorner.CornerRadius = UDim.new(0, 6)
__UI.triggerbotDelayCorner.Parent = __UI.triggerbotDelayBox

__UI.triggerbotDelayStroke = Instance.new("UIStroke")
__UI.triggerbotDelayStroke.Thickness = 1.5
__UI.triggerbotDelayStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.triggerbotDelayStroke.Parent = __UI.triggerbotDelayBox

-- 3. ESP SUB-POPUP
__UI.espSubPopup = Instance.new("Frame")
__UI.espSubPopup.Name = "EspSubPopup"
__UI.espSubPopup.Size = UDim2.new(0, 240, 0, 310)
__UI.espSubPopup.AnchorPoint = Vector2.new(1, 1)
__UI.espSubPopup.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
__UI.espSubPopup.BorderSizePixel = 0
__UI.espSubPopup.Visible = false
__UI.espSubPopup.ZIndex = 30
__UI.espSubPopup.Parent = screenGui

__UI.espSubCorner = Instance.new("UICorner")
__UI.espSubCorner.CornerRadius = UDim.new(0, 14)
__UI.espSubCorner.Parent = __UI.espSubPopup

__UI.espSubStroke = Instance.new("UIStroke")
__UI.espSubStroke.Thickness = 2.5
__UI.espSubStroke.Color = Color3.fromRGB(125, 211, 252)
__UI.espSubStroke.Parent = __UI.espSubPopup

__UI.espSubTopBar = Instance.new("Frame")
__UI.espSubTopBar.Name = "EspSubTopBar"
__UI.espSubTopBar.Size = UDim2.new(1, 0, 0, 30)
__UI.espSubTopBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.espSubTopBar.BorderSizePixel = 0
__UI.espSubTopBar.ZIndex = 31
__UI.espSubTopBar.Parent = __UI.espSubPopup

__UI.espSubTopCorner = Instance.new("UICorner")
__UI.espSubTopCorner.CornerRadius = UDim.new(0, 14)
__UI.espSubTopCorner.Parent = __UI.espSubTopBar

__UI.espSubTopCover = Instance.new("Frame")
__UI.espSubTopCover.Size = UDim2.new(1, 0, 0, 10)
__UI.espSubTopCover.Position = UDim2.new(0, 0, 1, -10)
__UI.espSubTopCover.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.espSubTopCover.BorderSizePixel = 0
__UI.espSubTopCover.ZIndex = 31
__UI.espSubTopCover.Parent = __UI.espSubTopBar

__UI.espSubTitle = Instance.new("TextLabel")
__UI.espSubTitle.Size = UDim2.new(1, -15, 1, 0)
__UI.espSubTitle.Position = UDim2.new(0, 15, 0, 0)
__UI.espSubTitle.BackgroundTransparency = 1
__UI.espSubTitle.Text = "❄️ 6x ESP & COLOR SETTINGS"
__UI.espSubTitle.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.espSubTitle.TextSize = 12
__UI.espSubTitle.Font = Enum.Font.GothamBold
__UI.espSubTitle.TextXAlignment = Enum.TextXAlignment.Left
__UI.espSubTitle.ZIndex = 31
__UI.espSubTitle.Parent = __UI.espSubTopBar

local function createEspToggle(name, text, posY, stateKey)
	local active = configData.esp and configData.esp[stateKey] or false
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.86, 0, 0, 26)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.Position = UDim2.new(0.5, 0, 0, posY)
	btn.BackgroundColor3 = active and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
	btn.Text = active and text .. ": ON" or text .. ": OFF"
	btn.TextColor3 = active and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 31
	btn.Parent = __UI.espSubPopup

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = active and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(248, 113, 113)
	stroke.Parent = btn

	return btn, stroke
end

local boxBtn, boxStroke = createEspToggle("BoxBtn", "1. Box ESP", 38, "Box")
local nameBtn, nameStroke = createEspToggle("NameBtn", "2. Name ESP", 69, "Name")
local healthBtn, healthStroke = createEspToggle("HealthBtn", "3. Health Bar", 100, "Health")
local tracerBtn, tracerStroke = createEspToggle("TracerBtn", "4. Tracer", 131, "Tracer")
local skelBtn, skelStroke = createEspToggle("SkelBtn", "5. Skeleton", 162, "Skeleton")
local xrayBtn, xrayStroke = createEspToggle("XrayBtn", "6. Chams/Highlight", 193, "Chams")

__UI.colorBox = Instance.new("TextBox")
__UI.colorBox.Name = "ColorBox"
__UI.colorBox.Size = UDim2.new(0.86, 0, 0, 32)
__UI.colorBox.AnchorPoint = Vector2.new(0.5, 0)
__UI.colorBox.Position = UDim2.new(0.5, 0, 0, 230)
__UI.colorBox.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.colorBox.Text = configData.espColorName or ""
__UI.colorBox.PlaceholderText = "Farbe (z.B. blue, red)..."
__UI.colorBox.PlaceholderColor3 = Color3.fromRGB(148, 163, 184)
__UI.colorBox.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.colorBox.TextSize = 11
__UI.colorBox.Font = Enum.Font.GothamMedium
__UI.colorBox.ClearTextOnFocus = false
__UI.colorBox.ZIndex = 31
__UI.colorBox.Parent = __UI.espSubPopup

__UI.colorBoxCorner = Instance.new("UICorner")
__UI.colorBoxCorner.CornerRadius = UDim.new(0, 6)
__UI.colorBoxCorner.Parent = __UI.colorBox

__UI.colorBoxStroke = Instance.new("UIStroke")
__UI.colorBoxStroke.Thickness = 1.5
__UI.colorBoxStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.colorBoxStroke.Parent = __UI.colorBox

-- 4. TP SUB-POPUP
__UI.tpSubPopup = Instance.new("Frame")
__UI.tpSubPopup.Name = "TpSubPopup"
__UI.tpSubPopup.Size = UDim2.new(0, 260, 0, 330)
__UI.tpSubPopup.AnchorPoint = Vector2.new(1, 1)
__UI.tpSubPopup.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
__UI.tpSubPopup.BorderSizePixel = 0
__UI.tpSubPopup.Visible = false
__UI.tpSubPopup.ZIndex = 30
__UI.tpSubPopup.Parent = screenGui

__UI.tpSubCorner = Instance.new("UICorner")
__UI.tpSubCorner.CornerRadius = UDim.new(0, 14)
__UI.tpSubCorner.Parent = __UI.tpSubPopup

__UI.tpSubStroke = Instance.new("UIStroke")
__UI.tpSubStroke.Thickness = 2.5
__UI.tpSubStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.tpSubStroke.Parent = __UI.tpSubPopup

__UI.tpSubTopBar = Instance.new("Frame")
__UI.tpSubTopBar.Name = "TpSubTopBar"
__UI.tpSubTopBar.Size = UDim2.new(1, 0, 0, 30)
__UI.tpSubTopBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.tpSubTopBar.BorderSizePixel = 0
__UI.tpSubTopBar.ZIndex = 31
__UI.tpSubTopBar.Parent = __UI.tpSubPopup

__UI.tpSubTopCorner = Instance.new("UICorner")
__UI.tpSubTopCorner.CornerRadius = UDim.new(0, 14)
__UI.tpSubTopCorner.Parent = __UI.tpSubTopBar

__UI.tpSubTopCover = Instance.new("Frame")
__UI.tpSubTopCover.Size = UDim2.new(1, 0, 0, 10)
__UI.tpSubTopCover.Position = UDim2.new(0, 0, 1, -10)
__UI.tpSubTopCover.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.tpSubTopCover.BorderSizePixel = 0
__UI.tpSubTopCover.ZIndex = 31
__UI.tpSubTopCover.Parent = __UI.tpSubTopBar

__UI.tpSubTitle = Instance.new("TextLabel")
__UI.tpSubTitle.Size = UDim2.new(1, -15, 1, 0)
__UI.tpSubTitle.Position = UDim2.new(0, 15, 0, 0)
__UI.tpSubTitle.BackgroundTransparency = 1
__UI.tpSubTitle.Text = "❄️ TELEPORT SETTINGS"
__UI.tpSubTitle.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.tpSubTitle.TextSize = 12
__UI.tpSubTitle.Font = Enum.Font.GothamBold
__UI.tpSubTitle.TextXAlignment = Enum.TextXAlignment.Left
__UI.tpSubTitle.ZIndex = 31
__UI.tpSubTitle.Parent = __UI.tpSubTopBar

local function createTpButton(name, text, posY)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.86, 0, 0, 30)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.Position = UDim2.new(0.5, 0, 0, posY)
	btn.BackgroundColor3 = Color3.fromRGB(14, 116, 144)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 31
	btn.Parent = __UI.tpSubPopup

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(56, 189, 248)
	stroke.Parent = __UI.tpSubPopup

	return btn
end

local tpNearestBtn = createTpButton("TpNearestBtn", "Teleport to Nearest Player", 42)
local playerTpListBtn = createTpButton("PlayerTpListBtn", "Player Tp", 81)
local clickTpToggleBtn = createTpButton("ClickTpToggleBtn", configData.clickTp and "Ctrl + Click TP: ON" or "Ctrl + Click TP: OFF", 120)
clickTpToggleBtn.BackgroundColor3 = configData.clickTp and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(14, 116, 144)
clickTpToggleBtn.TextColor3 = configData.clickTp and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(255, 255, 255)

local scareTpToggleBtn = createTpButton("ScareTpToggleBtn", configData.scareTp and "👻 ScareTp: ON" or "👻 ScareTp: OFF", 159)
scareTpToggleBtn.BackgroundColor3 = configData.scareTp and Color3.fromRGB(88, 28, 135) or Color3.fromRGB(14, 116, 144)
scareTpToggleBtn.TextColor3 = configData.scareTp and Color3.fromRGB(216, 180, 254) or Color3.fromRGB(255, 255, 255)

scareTpToggleBtn.MouseButton1Click:Connect(function()
	configData.scareTp = not configData.scareTp
	saveConfig()
	if configData.scareTp then
		scareTpToggleBtn.Text = "👻 ScareTp: ON"
		scareTpToggleBtn.TextColor3 = Color3.fromRGB(216, 180, 254)
		scareTpToggleBtn.BackgroundColor3 = Color3.fromRGB(88, 28, 135)
	else
		scareTpToggleBtn.Text = "👻 ScareTp: OFF"
		scareTpToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		scareTpToggleBtn.BackgroundColor3 = Color3.fromRGB(14, 116, 144)
	end
end)

__UI.keyBox = Instance.new("TextBox")
__UI.keyBox.Name = "KeyBox"
__UI.keyBox.Size = UDim2.new(0.86, 0, 0, 28)
__UI.keyBox.AnchorPoint = Vector2.new(0.5, 0)
__UI.keyBox.Position = UDim2.new(0.5, 0, 0, 198)
__UI.keyBox.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.keyBox.Text = configData.tpKey or "LeftControl"
__UI.keyBox.PlaceholderText = "Taste (z.B. E, Q, LeftControl)"
__UI.keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.keyBox.TextSize = 11
__UI.keyBox.Font = Enum.Font.GothamMedium
__UI.keyBox.ClearTextOnFocus = false
__UI.keyBox.ZIndex = 31
__UI.keyBox.Parent = __UI.tpSubPopup

local keyBoxCorner = Instance.new("UICorner")
keyBoxCorner.CornerRadius = UDim.new(0, 6)
keyBoxCorner.Parent = __UI.keyBox

local keyBoxStroke = Instance.new("UIStroke")
keyBoxStroke.Thickness = 1.5
keyBoxStroke.Color = Color3.fromRGB(56, 189, 248)
keyBoxStroke.Parent = __UI.keyBox

local savePosBtn = createTpButton("SavePosBtn", "Save Current Position", 237)
local loadPosBtn = createTpButton("LoadPosBtn", "Teleport to Saved Position", 276)

--------------------------------------------------------------------------------
-- PLAYER TP SELECTION POP-UP
--------------------------------------------------------------------------------
__UI.playerListPopup = Instance.new("Frame")
__UI.playerListPopup.Name = "PlayerListPopup"
__UI.playerListPopup.Size = UDim2.new(0, 280, 0, 425)
__UI.playerListPopup.AnchorPoint = Vector2.new(1, 1)
__UI.playerListPopup.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
__UI.playerListPopup.Visible = false
__UI.playerListPopup.ZIndex = 50
__UI.playerListPopup.Parent = screenGui

__UI.plPopupCorner = Instance.new("UICorner")
__UI.plPopupCorner.CornerRadius = UDim.new(0, 14)
__UI.plPopupCorner.Parent = __UI.playerListPopup

__UI.plPopupStroke = Instance.new("UIStroke")
__UI.plPopupStroke.Thickness = 2.5
__UI.plPopupStroke.Color = Color3.fromRGB(125, 211, 252)
__UI.plPopupStroke.Parent = __UI.playerListPopup

__UI.plTopBar = Instance.new("Frame")
__UI.plTopBar.Name = "PlTopBar"
__UI.plTopBar.Size = UDim2.new(1, 0, 0, 30)
__UI.plTopBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.plTopBar.BorderSizePixel = 0
__UI.plTopBar.ZIndex = 51
__UI.plTopBar.Parent = __UI.playerListPopup

__UI.plTopCorner = Instance.new("UICorner")
__UI.plTopCorner.CornerRadius = UDim.new(0, 14)
__UI.plTopCorner.Parent = __UI.plTopBar

__UI.plTopCover = Instance.new("Frame")
__UI.plTopCover.Size = UDim2.new(1, 0, 0, 10)
__UI.plTopCover.Position = UDim2.new(0, 0, 1, -10)
__UI.plTopCover.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.plTopCover.BorderSizePixel = 0
__UI.plTopCover.ZIndex = 51
__UI.plTopCover.Parent = __UI.plTopBar

__UI.plTitle = Instance.new("TextLabel")
__UI.plTitle.Size = UDim2.new(1, -15, 1, 0)
__UI.plTitle.Position = UDim2.new(0, 15, 0, 0)
__UI.plTitle.BackgroundTransparency = 1
__UI.plTitle.Text = "❄️ PLAYER TP & KEYBINDS"
__UI.plTitle.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.plTitle.TextSize = 12
__UI.plTitle.Font = Enum.Font.GothamBold
__UI.plTitle.TextXAlignment = Enum.TextXAlignment.Left
__UI.plTitle.ZIndex = 51
__UI.plTitle.Parent = __UI.plTopBar

local function executeTpToTarget(targetRoot)
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if myRoot and targetRoot then
		local originalPos = myRoot.CFrame
		if configData.scareTp then
			myRoot.CFrame = targetRoot.CFrame + (targetRoot.CFrame.LookVector * 3) + Vector3.new(0, 1, 0)
			task.delay(0.2, function()
				if myRoot and myRoot.Parent then
					myRoot.CFrame = originalPos
				end
			end)
		else
			myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
		end
	end
end

__UI.tpRandomBtn = Instance.new("TextButton")
__UI.tpRandomBtn.Name = "TpRandomBtn"
__UI.tpRandomBtn.Size = UDim2.new(0.9, 0, 0, 26)
__UI.tpRandomBtn.Position = UDim2.new(0.05, 0, 0, 38)
__UI.tpRandomBtn.BackgroundColor3 = Color3.fromRGB(14, 116, 144)
__UI.tpRandomBtn.Text = "🎲 Teleport to Random Person"
__UI.tpRandomBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.tpRandomBtn.TextSize = 11
__UI.tpRandomBtn.Font = Enum.Font.GothamBold
__UI.tpRandomBtn.ZIndex = 51
__UI.tpRandomBtn.Parent = __UI.playerListPopup

__UI.tpRandomCorner = Instance.new("UICorner")
__UI.tpRandomCorner.CornerRadius = UDim.new(0, 6)
__UI.tpRandomCorner.Parent = __UI.tpRandomBtn

__UI.tpRandomBtn.MouseButton1Click:Connect(function()
	local otherPlayers = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(otherPlayers, p)
		end
	end
	if #otherPlayers > 0 then
		local randomP = otherPlayers[math.random(1, #otherPlayers)]
		local targetRoot = randomP.Character and randomP.Character:FindFirstChild("HumanoidRootPart")
		if targetRoot then
			executeTpToTarget(targetRoot)
		end
	end
end)

__UI.upTpBtn = Instance.new("TextButton")
__UI.upTpBtn.Name = "UpTpBtn"
__UI.upTpBtn.Size = UDim2.new(0.9, 0, 0, 26)
__UI.upTpBtn.Position = UDim2.new(0.05, 0, 0, 70)
__UI.upTpBtn.BackgroundColor3 = configData.upTp and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.upTpBtn.Text = configData.upTp and "🚀 UpTp: ON" or "🚀 UpTp: OFF"
__UI.upTpBtn.TextColor3 = configData.upTp and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.upTpBtn.TextSize = 11
__UI.upTpBtn.Font = Enum.Font.GothamBold
__UI.upTpBtn.ZIndex = 51
__UI.upTpBtn.Parent = __UI.playerListPopup

__UI.upTpCorner = Instance.new("UICorner")
__UI.upTpCorner.CornerRadius = UDim.new(0, 6)
__UI.upTpCorner.Parent = __UI.upTpBtn

__UI.upTpBtn.MouseButton1Click:Connect(function()
	configData.upTp = not configData.upTp
	if configData.upTp then configData.checkTp = false end
	saveConfig()
	if configData.upTp then
		__UI.upTpBtn.Text = "🚀 UpTp: ON"
		__UI.upTpBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		__UI.upTpBtn.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
	else
		__UI.upTpBtn.Text = "🚀 UpTp: OFF"
		__UI.upTpBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		__UI.upTpBtn.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
	end
end)

__UI.checkTpBtn = Instance.new("TextButton")
__UI.checkTpBtn.Name = "CheckTpBtn"
__UI.checkTpBtn.Size = UDim2.new(0.9, 0, 0, 26)
__UI.checkTpBtn.Position = UDim2.new(0.05, 0, 0, 102)
__UI.checkTpBtn.BackgroundColor3 = configData.checkTp and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(127, 29, 29)
__UI.checkTpBtn.Text = configData.checkTp and "🎯 CheckTp: ON" or "🎯 CheckTp: OFF"
__UI.checkTpBtn.TextColor3 = configData.checkTp and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
__UI.checkTpBtn.TextSize = 11
__UI.checkTpBtn.Font = Enum.Font.GothamBold
__UI.checkTpBtn.ZIndex = 51
__UI.checkTpBtn.Parent = __UI.playerListPopup

__UI.checkTpCorner = Instance.new("UICorner")
__UI.checkTpCorner.CornerRadius = UDim.new(0, 6)
__UI.checkTpCorner.Parent = __UI.checkTpBtn

__UI.checkTpBtn.MouseButton1Click:Connect(function()
	configData.checkTp = not configData.checkTp
	if configData.checkTp then configData.upTp = false end
	saveConfig()
	if configData.checkTp then
		__UI.checkTpBtn.Text = "🎯 CheckTp: ON"
		__UI.checkTpBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		__UI.checkTpBtn.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
	else
		__UI.checkTpBtn.Text = "🎯 CheckTp: OFF"
		__UI.checkTpBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		__UI.checkTpBtn.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
	end
end)

__UI.scrollingList = Instance.new("ScrollingFrame")
__UI.scrollingList.Name = "ScrollingList"
__UI.scrollingList.Size = UDim2.new(0.9, 0, 0, 150)
__UI.scrollingList.Position = UDim2.new(0.05, 0, 0, 134)
__UI.scrollingList.BackgroundTransparency = 1
__UI.scrollingList.BorderSizePixel = 0
__UI.scrollingList.CanvasSize = UDim2.new(0, 0, 0, 0)
__UI.scrollingList.ScrollBarThickness = 4
__UI.scrollingList.ZIndex = 51
__UI.scrollingList.Parent = __UI.playerListPopup

__UI.listLayout = Instance.new("UIListLayout")
__UI.listLayout.SortOrder = Enum.SortOrder.LayoutOrder
__UI.listLayout.Padding = UDim.new(0, 6)
__UI.listLayout.Parent = __UI.scrollingList

__UI.listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	__UI.scrollingList.CanvasSize = UDim2.new(0, 0, 0, __UI.listLayout.AbsoluteContentSize.Y + 10)
end)

__UI.resetBindsBtn = Instance.new("TextButton")
__UI.resetBindsBtn.Name = "ResetBindsBtn"
__UI.resetBindsBtn.Size = UDim2.new(0.42, 0, 0, 28)
__UI.resetBindsBtn.Position = UDim2.new(0.05, 0, 0, 345)
__UI.resetBindsBtn.BackgroundColor3 = Color3.fromRGB(180, 83, 9)
__UI.resetBindsBtn.Text = "🔄 Reset Binds"
__UI.resetBindsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.resetBindsBtn.TextSize = 11
__UI.resetBindsBtn.Font = Enum.Font.GothamBold
__UI.resetBindsBtn.ZIndex = 51
__UI.resetBindsBtn.Parent = __UI.playerListPopup

__UI.resetBindsCorner = Instance.new("UICorner")
__UI.resetBindsCorner.CornerRadius = UDim.new(0, 8)
__UI.resetBindsCorner.Parent = __UI.resetBindsBtn

__UI.resetBindsBtn.MouseButton1Click:Connect(function()
	configData.playerBinds = {}
	saveConfig()
	updatePlayerList()
	__UI.resetBindsBtn.Text = "✨ Reset!"
	task.delay(1.5, function() __UI.resetBindsBtn.Text = "🔄 Reset Binds" end)
end)

__UI.closePlayerListBtn = Instance.new("TextButton")
__UI.closePlayerListBtn.Name = "ClosePlayerListBtn"
__UI.closePlayerListBtn.Size = UDim2.new(0.42, 0, 0, 28)
__UI.closePlayerListBtn.Position = UDim2.new(0.53, 0, 0, 345)
__UI.closePlayerListBtn.BackgroundColor3 = Color3.fromRGB(190, 18, 60)
__UI.closePlayerListBtn.Text = "CLOSE"
__UI.closePlayerListBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.closePlayerListBtn.TextSize = 11
__UI.closePlayerListBtn.Font = Enum.Font.GothamBold
__UI.closePlayerListBtn.ZIndex = 51
__UI.closePlayerListBtn.Parent = __UI.playerListPopup

__UI.closePlCorner = Instance.new("UICorner")
__UI.closePlCorner.CornerRadius = UDim.new(0, 8)
__UI.closePlCorner.Parent = __UI.closePlayerListBtn

local bindingPlayerName = nil

function updatePlayerList()
	for _, child in ipairs(__UI.scrollingList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local itemFrame = Instance.new("Frame")
			itemFrame.Size = UDim2.new(1, 0, 0, 30)
			itemFrame.BackgroundTransparency = 1
			itemFrame.ZIndex = 52
			itemFrame.Parent = __UI.scrollingList

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.45, 0, 1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = " " .. p.Name
			nameLabel.TextColor3 = Color3.fromRGB(224, 242, 254)
			nameLabel.TextSize = 11
			nameLabel.Font = Enum.Font.GothamMedium
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.ZIndex = 52
			nameLabel.Parent = itemFrame

			local tpBtn = Instance.new("TextButton")
			tpBtn.Size = UDim2.new(0.25, 0, 1, 0)
			tpBtn.Position = UDim2.new(0.46, 0, 0, 0)
			tpBtn.BackgroundColor3 = Color3.fromRGB(14, 116, 144)
			tpBtn.Text = "TP"
			tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			tpBtn.TextSize = 11
			tpBtn.Font = Enum.Font.GothamBold
			tpBtn.ZIndex = 52
			tpBtn.Parent = itemFrame

			local tpCorner = Instance.new("UICorner")
			tpCorner.CornerRadius = UDim.new(0, 6)
			tpCorner.Parent = tpBtn

			tpBtn.MouseButton1Click:Connect(function()
				local targetChar = p.Character
				local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
				if targetRoot then executeTpToTarget(targetRoot) end
			end)

			local bindBtn = Instance.new("TextButton")
			bindBtn.Size = UDim2.new(0.25, 0, 1, 0)
			bindBtn.Position = UDim2.new(0.73, 0, 0, 0)
			bindBtn.BackgroundColor3 = Color3.fromRGB(79, 70, 229)
			local currentKey = configData.playerBinds and configData.playerBinds[p.Name]
			bindBtn.Text = currentKey and tostring(currentKey) or "Bind"
			bindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			bindBtn.TextSize = 10
			bindBtn.Font = Enum.Font.GothamBold
			bindBtn.ZIndex = 52
			bindBtn.Parent = itemFrame

			local bindCorner = Instance.new("UICorner")
			bindCorner.CornerRadius = UDim.new(0, 6)
			bindCorner.Parent = bindBtn

			bindBtn.MouseButton1Click:Connect(function()
				bindingPlayerName = p.Name
				bindBtn.Text = "..."
			end)
		end
	end
end

local currentUpTpTarget = nil
local currentCheckTpTarget = nil

local function isUnderRoof(targetChar)
	local head = targetChar and targetChar:FindFirstChild("Head")
	if not head then return false end
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {targetChar, player.Character}
	raycastParams.IgnoreWater = true
	
	local raycastResult = Workspace:Raycast(head.Position, Vector3.new(0, 15, 0), raycastParams)
	if raycastResult then
		return true
	end
	return false
end

RunService.RenderStepped:Connect(function()
	if configData.upTp then
		local myChar = player.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if myRoot then
			local targetValid = false
			if currentUpTpTarget and currentUpTpTarget.Character then
				local hum = currentUpTpTarget.Character:FindFirstChildOfClass("Humanoid")
				local targetRoot = currentUpTpTarget.Character:FindFirstChild("HumanoidRootPart")
				if hum and hum.Health > 0 and targetRoot and not isUnderRoof(currentUpTpTarget.Character) then 
					targetValid = true 
				end
			end

			if not targetValid then
				currentUpTpTarget = nil
				local validPlayers = {}
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= player and p.Character then
						local hum = p.Character:FindFirstChildOfClass("Humanoid")
						local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
						if hum and hum.Health > 0 and targetRoot and not isUnderRoof(p.Character) then 
							table.insert(validPlayers, p) 
						end
					end
				end
				if #validPlayers > 0 then 
					currentUpTpTarget = validPlayers[math.random(1, #validPlayers)] 
				end
			end

			if currentUpTpTarget and currentUpTpTarget.Character then
				local targetRoot = currentUpTpTarget.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 12, 14)
					myRoot.Velocity = Vector3.new(0, 0, 0)
				end
			end
		end
	else
		currentUpTpTarget = nil
	end

	if configData.checkTp then
		local myChar = player.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if myRoot then
			for _, part in ipairs(myChar:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
			end

			local targetValid = false
			if currentCheckTpTarget and currentCheckTpTarget.Character then
				local hum = currentCheckTpTarget.Character:FindFirstChildOfClass("Humanoid")
				local targetRoot = currentCheckTpTarget.Character:FindFirstChild("HumanoidRootPart")
				if hum and hum.Health > 0 and targetRoot then targetValid = true end
			end

			if not targetValid then
				currentCheckTpTarget = nil
				local validPlayers = {}
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= player and p.Character then
						local hum = p.Character:FindFirstChildOfClass("Humanoid")
						local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
						if hum and hum.Health > 0 and targetRoot then table.insert(validPlayers, p) end
					end
				end
				if #validPlayers > 0 then currentCheckTpTarget = validPlayers[math.random(1, #validPlayers)] end
			end

			if currentCheckTpTarget and currentCheckTpTarget.Character then
				local targetRoot = currentCheckTpTarget.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3.5)
					myRoot.Velocity = targetRoot.Velocity
				end
			end
		end
	else
		currentCheckTpTarget = nil
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if bindingPlayerName and input.UserInputType == Enum.UserInputType.Keyboard then
		local keyName = input.KeyCode.Name
		if not configData.playerBinds then configData.playerBinds = {} end
		configData.playerBinds[bindingPlayerName] = keyName
		saveConfig()
		bindingPlayerName = nil
		updatePlayerList()
		return
	end

	if not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
		local pressedKey = input.KeyCode.Name
		if configData.playerBinds then
			for targetName, boundKey in pairs(configData.playerBinds) do
				if boundKey == pressedKey then
					local targetP = Players:FindFirstChild(targetName)
					if targetP and targetP.Character then
						local targetRoot = targetP.Character:FindFirstChild("HumanoidRootPart")
						if targetRoot then executeTpToTarget(targetRoot) end
					end
				end
			end
		end
	end
end)

local playerListOpen = false
playerTpListBtn.MouseButton1Click:Connect(function()
	playerListOpen = not playerListOpen
	local openInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local closeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if playerListOpen then
		updatePlayerList()
		__UI.playerListPopup.Position = getMarkedAreaGridPosition(__UI.playerListPopup.AbsoluteSize.X, __UI.playerListPopup.AbsoluteSize.Y, {__UI.aimbotSubPopup, __UI.triggerbotSubPopup, __UI.espSubPopup, __UI.tpSubPopup, __UI.settingsSubPopup, __UI.moreSubPopup})
		__UI.playerListPopup.Visible = true
		__UI.playerListPopup.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(__UI.playerListPopup, openInfo, {Size = UDim2.new(0, 280, 0, 425)}):Play()
	else
		local closeTween = TweenService:Create(__UI.playerListPopup, closeInfo, {Size = UDim2.new(0, 0, 0, 0)})
		closeTween:Play()
		closeTween.Completed:Connect(function()
			if not playerListOpen then __UI.playerListPopup.Visible = false end
		end)
	end
end)

__UI.closePlayerListBtn.MouseButton1Click:Connect(function()
	playerListOpen = false
	local closeTween = TweenService:Create(__UI.playerListPopup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
	closeTween:Play()
	closeTween.Completed:Connect(function()
		if not playerListOpen then __UI.playerListPopup.Visible = false end
	end)
end)

Players.PlayerAdded:Connect(function() if playerListOpen then updatePlayerList() end end)
Players.PlayerRemoving:Connect(function() if playerListOpen then updatePlayerList() end end)

-- 5. SETTINGS SUB-POPUP (Mit fortlaufendem 24h Timer & Automatischem Rejoin bei 0s)
__UI.settingsSubPopup = Instance.new("Frame")
__UI.settingsSubPopup.Name = "SettingsSubPopup"
__UI.settingsSubPopup.Size = UDim2.new(0, 260, 0, 470)
__UI.settingsSubPopup.AnchorPoint = Vector2.new(1, 1)
__UI.settingsSubPopup.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
__UI.settingsSubPopup.BorderSizePixel = 0
__UI.settingsSubPopup.Visible = false
__UI.settingsSubPopup.ZIndex = 30
__UI.settingsSubPopup.Parent = screenGui

__UI.settingsSubCorner = Instance.new("UICorner")
__UI.settingsSubCorner.CornerRadius = UDim.new(0, 14)
__UI.settingsSubCorner.Parent = __UI.settingsSubPopup

__UI.settingsSubStroke = Instance.new("UIStroke")
__UI.settingsSubStroke.Thickness = 2.5
__UI.settingsSubStroke.Color = Color3.fromRGB(245, 158, 11)
__UI.settingsSubStroke.Parent = __UI.settingsSubPopup

__UI.settingsSubTopBar = Instance.new("Frame")
__UI.settingsSubTopBar.Name = "SettingsSubTopBar"
__UI.settingsSubTopBar.Size = UDim2.new(1, 0, 0, 30)
__UI.settingsSubTopBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.settingsSubTopBar.BorderSizePixel = 0
__UI.settingsSubTopBar.ZIndex = 31
__UI.settingsSubTopBar.Parent = __UI.settingsSubPopup

__UI.settingsSubTopCorner = Instance.new("UICorner")
__UI.settingsSubTopCorner.CornerRadius = UDim.new(0, 14)
__UI.settingsSubTopCorner.Parent = __UI.settingsSubTopBar

__UI.settingsSubTopCover = Instance.new("Frame")
__UI.settingsSubTopCover.Size = UDim2.new(1, 0, 0, 10)
__UI.settingsSubTopCover.Position = UDim2.new(0, 0, 1, -10)
__UI.settingsSubTopCover.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.settingsSubTopCover.BorderSizePixel = 0
__UI.settingsSubTopCover.ZIndex = 31
__UI.settingsSubTopCover.Parent = __UI.settingsSubTopBar

__UI.settingsSubTitle = Instance.new("TextLabel")
__UI.settingsSubTitle.Size = UDim2.new(1, -15, 1, 0)
__UI.settingsSubTitle.Position = UDim2.new(0, 15, 0, 0)
__UI.settingsSubTitle.BackgroundTransparency = 1
__UI.settingsSubTitle.Text = "❄️ STATS & PERFORMANCE"
__UI.settingsSubTitle.TextColor3 = Color3.fromRGB(224, 242, 254)
__UI.settingsSubTitle.TextSize = 12
__UI.settingsSubTitle.Font = Enum.Font.GothamBold
__UI.settingsSubTitle.TextXAlignment = Enum.TextXAlignment.Left
__UI.settingsSubTitle.ZIndex = 31
__UI.settingsSubTitle.Parent = __UI.settingsSubTopBar

__UI.statsContainer = Instance.new("Frame")
__UI.statsContainer.Name = "StatsContainer"
__UI.statsContainer.Size = UDim2.new(0.86, 0, 0, 105)
__UI.statsContainer.AnchorPoint = Vector2.new(0.5, 0)
__UI.statsContainer.Position = UDim2.new(0.5, 0, 0, 38)
__UI.statsContainer.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
__UI.statsContainer.BorderSizePixel = 0
__UI.statsContainer.ZIndex = 31
__UI.statsContainer.Parent = __UI.settingsSubPopup

__UI.statsCorner = Instance.new("UICorner")
__UI.statsCorner.CornerRadius = UDim.new(0, 8)
__UI.statsCorner.Parent = __UI.statsContainer

__UI.statsStroke = Instance.new("UIStroke")
__UI.statsStroke.Thickness = 1
__UI.statsStroke.Color = Color3.fromRGB(56, 189, 248)
__UI.statsStroke.Parent = __UI.statsContainer

__UI.avatarIcon = Instance.new("ImageLabel")
__UI.avatarIcon.Name = "AvatarIcon"
__UI.avatarIcon.Size = UDim2.new(0, 32, 0, 32)
__UI.avatarIcon.Position = UDim2.new(0, 8, 0, 8)
__UI.avatarIcon.BackgroundTransparency = 1
__UI.avatarIcon.ZIndex = 32
__UI.avatarIcon.Parent = __UI.statsContainer

__UI.avatarCorner = Instance.new("UICorner")
__UI.avatarCorner.CornerRadius = UDim.new(1, 0)
__UI.avatarCorner.Parent = __UI.avatarIcon

pcall(function()
	local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size42x42)
	if isReady then __UI.avatarIcon.Image = content end
end)

__UI.statsUserLabel = Instance.new("TextLabel")
__UI.statsUserLabel.Name = "StatsUserLabel"
__UI.statsUserLabel.Size = UDim2.new(1, -48, 0, 18)
__UI.statsUserLabel.Position = UDim2.new(0, 46, 0, 8)
__UI.statsUserLabel.BackgroundTransparency = 1
__UI.statsUserLabel.Text = player.Name
__UI.statsUserLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.statsUserLabel.TextSize = 12
__UI.statsUserLabel.Font = Enum.Font.GothamBold
__UI.statsUserLabel.TextXAlignment = Enum.TextXAlignment.Left
__UI.statsUserLabel.ZIndex = 32
__UI.statsUserLabel.Parent = __UI.statsContainer

local function createStatRow(name, posY, initialText)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -16, 0, 16)
	label.Position = UDim2.new(0, 8, 0, posY)
	label.BackgroundTransparency = 1
	label.Text = initialText
	label.TextColor3 = Color3.fromRGB(186, 230, 253)
	label.TextSize = 10
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 32
	label.Parent = __UI.statsContainer
	return label
end

local todayStatLabel = createStatRow("TodayStatLabel", 28, "Heute verbraucht: 0s")
local timeLeftLabel = createStatRow("TimeLeftLabel", 44, "Heute übrig: 24h 0m")
local weekStatLabel = createStatRow("WeekStatLabel", 60, "Diese Woche: 0s")
local totalStatLabel = createStatRow("TotalStatLabel", 76, "Insgesamt: 0s")

local function formatTime(seconds)
	seconds = math.floor(seconds or 0)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%dh %dm %ds", hours, minutes, secs)
	elseif minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	else
		return string.format("%ds", secs)
	end
end

-- Kontinuierlicher Timer, der unabhängig im Hintergrund läuft und echtes 24h-Limit pro Spieler erzwingt
task.spawn(function()
	while true do
		task.wait(1)
		
		local currentSysTime = os.time()
		if not configData.sessionStartTime then
			configData.sessionStartTime = currentSysTime
		end
		
		local elapsedSinceStart = currentSysTime - configData.sessionStartTime
		local remainingSeconds = math.max(0, 86400 - elapsedSinceStart)
		
		configData.todayTime = elapsedSinceStart
		configData.totalTime = (configData.totalTime or 0) + 1
		configData.weekTime = (configData.weekTime or 0) + 1
		
		todayStatLabel.Text = "Heute verbraucht: " .. formatTime(configData.todayTime)
		timeLeftLabel.Text = "Heute übrig: " .. formatTime(remainingSeconds)
		weekStatLabel.Text = "Diese Woche: " .. formatTime(configData.weekTime)
		totalStatLabel.Text = "Insgesamt: " .. formatTime(configData.totalTime)
		
		saveConfig()
		
		-- Wenn die 24 Stunden abgelaufen sind (0 Sekunden übrig): UI schließen, Key sperren und automatisch Rejoinen!
		if remainingSeconds <= 0 then
			configData.keyUnlocked = false
			configData.sessionStartTime = os.time()
			saveConfig()
			pcall(function() screenGui:Destroy() end)
			pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
			break
		end
	end
end)

local function createSettingButton(name, text, posY, modeName)
	local active = (configData.lightingMode == modeName)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.86, 0, 0, 28)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.Position = UDim2.new(0.5, 0, 0, posY)
	btn.BackgroundColor3 = active and Color3.fromRGB(6, 78, 59) or Color3.fromRGB(30, 41, 59)
	btn.Text = active and text .. ": ON" or text .. ": OFF"
	btn.TextColor3 = active and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(254, 202, 202)
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 31
	btn.Parent = __UI.settingsSubPopup

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = active and Color3.fromRGB(52, 211, 153) or Color3.fromRGB(56, 189, 248)
	stroke.Parent = btn

	return btn, stroke
end

local perfModeBtn, perfModeStroke = createSettingButton("PerfModeBtn", "Performance Mode", 150, "Performance")
local lowDetailBtn, lowDetailStroke = createSettingButton("LowDetailBtn", "Low Detail Mode", 183, "LowDetail")
local highDetailBtn, highDetailStroke = createSettingButton("HighDetailBtn", "High Detail Mode", 216, "HighDetail")
local darkModeBtn, darkModeStroke = createSettingButton("DarkModeBtn", "🌙 Dark Mode", 249, "Dark")
local bloodRedBtn, bloodRedStroke = createSettingButton("BloodRedBtn", "🩸 Blood Red (Danger)", 282, "Blood")
local sunsetBtn, sunsetStroke = createSettingButton("SunsetBtn", "☀️ Sunset Glow", 315, "Sunset")
local neonBtn, neonStroke = createSettingButton("NeonBtn", "💎 Cyberpunk Neon", 348, "Neon")

__UI.saveConfigBtn = Instance.new("TextButton")
__UI.saveConfigBtn.Name = "SaveConfigBtn"
__UI.saveConfigBtn.Size = UDim2.new(0.86, 0, 0, 28)
__UI.saveConfigBtn.AnchorPoint = Vector2.new(0.5, 0)
__UI.saveConfigBtn.Position = UDim2.new(0.5, 0, 0, 381)
__UI.saveConfigBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
__UI.saveConfigBtn.Text = "💾 SAVE CONFIG NOW"
__UI.saveConfigBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
__UI.saveConfigBtn.TextSize = 11
__UI.saveConfigBtn.Font = Enum.Font.GothamBold
__UI.saveConfigBtn.ZIndex = 31
__UI.saveConfigBtn.Parent = __UI.settingsSubPopup

__UI.saveConfigCorner = Instance.new("UICorner")
__UI.saveConfigCorner.CornerRadius = UDim.new(0, 8)
__UI.saveConfigCorner.Parent = __UI.saveConfigBtn

__UI.saveConfigStroke = Instance.new("UIStroke")
__UI.saveConfigStroke.Thickness = 1.5
__UI.saveConfigStroke.Color = Color3.fromRGB(52, 211, 153)
__UI.saveConfigStroke.Parent = __UI.saveConfigBtn

--------------------------------------------------------------------------------
-- INTERAKTION & LOGIK
--------------------------------------------------------------------------------
__UI.submitKeyBtn.MouseButton1Click:Connect(function()
	local enteredKey = __UI.keyBoxInput.Text
	if string.sub(enteredKey, 1, 8) == "XCVVB445" then
		configData.keyUnlocked = true
		saveConfig()
		__UI.keyFrame:Destroy()
		__UI.mainFrame.Visible = true
	else
		__UI.keyErrorLabel.Text = "Falscher Code!"
		task.delay(2, function()
			if __UI.keyErrorLabel then __UI.keyErrorLabel.Text = "" end
		end)
	end
end)

__UI.rivalsButton.MouseButton1Click:Connect(function()
	__UI.mainFrame.Visible = false
	__UI.draggablePopup.Visible = true
	__UI.fovPopup.Visible = true
end)

__UI.cancelBtn.MouseButton1Click:Connect(function()
	configData.aimbot = false
	configData.backbot = false
	configData.wallCheck = false
	configData.teamCheck = false
	configData.triggerbot = false
	configData.noclip = false
	configData.fly = false
	configData.infJump = false
	configData.autoRespawn = false
	configData.clickTp = false
	configData.upTp = false
	configData.checkTp = false
	configData.scareTp = false
	
	configData.fovCircle = false
	if fovCircle then pcall(function() fovCircle.Visible = false end) end
	
	if configData.esp then
		for k in pairs(configData.esp) do configData.esp[k] = false end
	end
	
	saveConfig()
	screenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.RightShift then
		screenGui.Enabled = not screenGui.Enabled
	end
end)

local noclipActive = configData.noclip
__UI.noclipBtn.MouseButton1Click:Connect(function()
	noclipActive = not noclipActive
	configData.noclip = noclipActive
	saveConfig()
	if noclipActive then
		__UI.noclipBtn.Text = "NoClip: ON"
		__UI.noclipBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		TweenService:Create(__UI.noclipBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(6, 78, 59)}):Play()
		__UI.noclipStroke.Color = Color3.fromRGB(52, 211, 153)
	else
		__UI.noclipBtn.Text = "NoClip: OFF"
		__UI.noclipBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		TweenService:Create(__UI.noclipBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(127, 29, 29)}):Play()
		__UI.noclipStroke.Color = Color3.fromRGB(248, 113, 113)
	end
end)

RunService.Stepped:Connect(function()
	if noclipActive or configData.checkTp then
		local char = player.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
			end
		end
	end
end)

local flyActive = configData.fly
local flySpeed = 50
__UI.flyBtn.MouseButton1Click:Connect(function()
	flyActive = not flyActive
	configData.fly = flyActive
	saveConfig()
	if flyActive then
		__UI.flyBtn.Text = "Fly Mode: ON"
		__UI.flyBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		TweenService:Create(__UI.flyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(6, 78, 59)}):Play()
		__UI.flyStroke.Color = Color3.fromRGB(52, 211, 153)
		pcall(function() player.DevEnableMouseLock = true end)
	else
		__UI.flyBtn.Text = "Fly Mode: OFF"
		__UI.flyBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		TweenService:Create(__UI.flyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(127, 29, 29)}):Play()
		__UI.flyStroke.Color = Color3.fromRGB(248, 113, 113)
		pcall(function() player.DevEnableMouseLock = false end)
	end
end)

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	
	if flyActive then
		if hrp and hum then
			hum.PlatformStand = true
			pcall(function() player.DevComputerCameraMode = Enum.DevComputerCameraMode.LockFirstPerson end)
			
			local animate = char:FindFirstChild("Animate")
			if animate then animate.Enabled = false end
			for _, track in ipairs(hum:GetPlayingAnimationTracks()) do track:Stop(0) end

			local dir = Vector3.new()
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camera.CFrame.RightVector end
			
			hrp.Velocity = dir * flySpeed
			hrp.RotVelocity = Vector3.new(0, 0, 0)
		end
	else
		if hum and not configData.checkTp then
			hum.PlatformStand = false
			pcall(function() player.DevComputerCameraMode = Enum.DevComputerCameraMode.Classic end)
			local animate = char and char:FindFirstChild("Animate")
			if animate then animate.Enabled = true end
		end
	end
end)

local infJumpActive = configData.infJump
__UI.infJumpBtn.MouseButton1Click:Connect(function()
	infJumpActive = not infJumpActive
	configData.infJump = infJumpActive
	saveConfig()
	if infJumpActive then
		__UI.infJumpBtn.Text = "Infinite Jump: ON"
		__UI.infJumpBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		TweenService:Create(__UI.infJumpBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(6, 78, 59)}):Play()
		__UI.infJumpStroke.Color = Color3.fromRGB(52, 211, 153)
	else
		__UI.infJumpBtn.Text = "Infinite Jump: OFF"
		__UI.infJumpBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		TweenService:Create(__UI.infJumpBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(127, 29, 29)}):Play()
		__UI.infJumpStroke.Color = Color3.fromRGB(248, 113, 113)
	end
end)

UserInputService.JumpRequest:Connect(function()
	if infJumpActive then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

local autoRespawnActive = configData.autoRespawn
__UI.autoRespawnBtn.MouseButton1Click:Connect(function()
	autoRespawnActive = not autoRespawnActive
	configData.autoRespawn = autoRespawnActive
	saveConfig()
	if autoRespawnActive then
		__UI.autoRespawnBtn.Text = "Auto-Respawn: ON"
		__UI.autoRespawnBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		TweenService:Create(__UI.autoRespawnBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(6, 78, 59)}):Play()
		__UI.autoRespawnStroke.Color = Color3.fromRGB(52, 211, 153)
	else
		__UI.autoRespawnBtn.Text = "Auto-Respawn: OFF"
		__UI.autoRespawnBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		TweenService:Create(__UI.autoRespawnBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(127, 29, 29)}):Play()
		__UI.autoRespawnStroke.Color = Color3.fromRGB(248, 113, 113)
	end
end)

player.CharacterAdded:Connect(function(char)
	if autoRespawnActive then
		local hum = char:WaitForChild("Humanoid")
		hum.Died:Connect(function()
			task.wait(0.5)
			if autoRespawnActive then player:LoadCharacter() end
		end)
	end
end)

local currentEspColor = Color3.fromRGB(255, 255, 255)
local colors = {
	red = Color3.fromRGB(255, 0, 0),
	blue = Color3.fromRGB(0, 120, 255),
	green = Color3.fromRGB(0, 255, 0),
	yellow = Color3.fromRGB(255, 255, 0),
	purple = Color3.fromRGB(180, 0, 255),
	pink = Color3.fromRGB(255, 105, 180),
	orange = Color3.fromRGB(255, 140, 0),
	white = Color3.fromRGB(255, 255, 255),
	black = Color3.fromRGB(0, 0, 0),
	cyan = Color3.fromRGB(0, 255, 255),
	lime = Color3.fromRGB(50, 205, 50)
}

if configData.espColorName and colors[configData.espColorName] then
	currentEspColor = colors[configData.espColorName]
end

__UI.colorBox.FocusLost:Connect(function()
	local input = string.lower(string.gsub(__UI.colorBox.Text, "%s+", ""))
	if colors[input] then
		currentEspColor = colors[input]
		configData.espColorName = input
		saveConfig()
	end
end)

local aimbotActive = configData.aimbot
local backbotActive = configData.backbot
local wallCheckActive = configData.wallCheck
local teamCheckActive = configData.teamCheck
local triggerbotActive = configData.triggerbot
local smoothnessValue = configData.smoothness or 5
local maxDistanceValue = configData.maxDistance or 1000
local fovRadiusValue = configData.fovRadius or 150

__UI.aimbotToggleBtn.MouseButton1Click:Connect(function()
	aimbotActive = not aimbotActive
	configData.aimbot = aimbotActive
	saveConfig()
	if aimbotActive then
		__UI.aimbotToggleBtn.Text = "Aimbot State: ON"
		__UI.aimbotToggleBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		TweenService:Create(__UI.aimbotToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(6, 78, 59)}):Play()
		__UI.aimbotToggleStroke.Color = Color3.fromRGB(52, 211, 153)
	else
		__UI.aimbotToggleBtn.Text = "Aimbot State: OFF"
		__UI.aimbotToggleBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		TweenService:Create(__UI.aimbotToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(127, 29, 29)}):Play()
		__UI.aimbotToggleStroke.Color = Color3.fromRGB(248, 113, 113)
	end
end)

__UI.aimbotKeyBox.FocusLost:Connect(function()
	configData.aimbotKey = __UI.aimbotKeyBox.Text
	saveConfig()
end)

__UI.backbotToggleBtn.MouseButton1Click:Connect(function()
	backbotActive = not backbotActive
	configData.backbot = backbotActive
	saveConfig()
	if backbotActive then
		__UI.backbotToggleBtn.Text = "Backbot: ON"
		__UI.backbotToggleBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		TweenService:Create(__UI.backbotToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(6, 78, 59)}):Play()
		__UI.backbotToggleStroke.Color = Color3.fromRGB(52, 211, 153)
	else
		__UI.backbotToggleBtn.Text = "Backbot: OFF"
		__UI.backbotToggleBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		TweenService:Create(__UI.backbotToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(127, 29, 29)}):Play()
		__UI.backbotToggleStroke.Color = Color3.fromRGB(248, 113, 113)
	end
end)

__UI.wallCheckBtn.MouseButton1Click:Connect(function()
	wallCheckActive = not wallCheckActive
	configData.wallCheck = wallCheckActive
	saveConfig()
	if wallCheckActive then
		__UI.wallCheckBtn.Text = "WallCheck: ON"
		__UI.wallCheckBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		TweenService:Create(__UI.wallCheckBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(6, 78, 59)}):Play()
		__UI.wallCheckStroke.Color = Color3.fromRGB(52, 211, 153)
	else
		__UI.wallCheckBtn.Text = "WallCheck: OFF"
		__UI.wallCheckBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		TweenService:Create(__UI.wallCheckBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(127, 29, 29)}):Play()
		__UI.wallCheckStroke.Color = Color3.fromRGB(248, 113, 113)
	end
end)

__UI.teamCheckBtn.MouseButton1Click:Connect(function()
	teamCheckActive = not teamCheckActive
	configData.teamCheck = teamCheckActive
	saveConfig()
	if teamCheckActive then
		__UI.teamCheckBtn.Text = "TeamCheck: ON"
		__UI.teamCheckBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		TweenService:Create(__UI.teamCheckBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(6, 78, 59)}):Play()
		__UI.teamCheckStroke.Color = Color3.fromRGB(52, 211, 153)
	else
		__UI.teamCheckBtn.Text = "TeamCheck: OFF"
		__UI.teamCheckBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		TweenService:Create(__UI.teamCheckBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(127, 29, 29)}):Play()
		__UI.teamCheckStroke.Color = Color3.fromRGB(248, 113, 113)
	end
end)

__UI.triggerbotToggleBtn.MouseButton1Click:Connect(function()
	triggerbotActive = not triggerbotActive
	configData.triggerbot = triggerbotActive
	saveConfig()
	if triggerbotActive then
		__UI.triggerbotToggleBtn.Text = "Triggerbot State: ON"
		__UI.triggerbotToggleBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		TweenService:Create(__UI.triggerbotToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(6, 78, 59)}):Play()
		__UI.triggerbotToggleStroke.Color = Color3.fromRGB(52, 211, 153)
	else
		__UI.triggerbotToggleBtn.Text = "Triggerbot State: OFF"
		__UI.triggerbotToggleBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		TweenService:Create(__UI.triggerbotToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(127, 29, 29)}):Play()
		__UI.triggerbotToggleStroke.Color = Color3.fromRGB(248, 113, 113)
	end
end)

__UI.triggerbotDelayBox.FocusLost:Connect(function()
	configData.triggerbotDelay = __UI.triggerbotDelayBox.Text
	saveConfig()
end)

local smoothSliding = false
__UI.smoothSliderKnob.MouseButton1Down:Connect(function() smoothSliding = true end)
__UI.smoothSliderBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then smoothSliding = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		smoothSliding = false
		saveConfig()
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if smoothSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local mousePos = input.Position.X
		local barAbsolutePos = __UI.smoothSliderBar.AbsolutePosition.X
		local barAbsoluteSize = __UI.smoothSliderBar.AbsoluteSize.X
		local relativeX = math.clamp((mousePos - barAbsolutePos) / barAbsoluteSize, 0, 1)
		__UI.smoothSliderKnob.Position = UDim2.new(relativeX, 0, 0.5, 0)
		smoothnessValue = math.clamp(math.round(1 + relativeX * 19), 1, 20)
		__UI.smoothnessLabel.Text = "Smoothness: " .. smoothnessValue
		configData.smoothness = smoothnessValue
	end
end)

local distSliding = false
__UI.distSliderKnob.MouseButton1Down:Connect(function() distSliding = true end)
__UI.distSliderBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then distSliding = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		distSliding = false
		saveConfig()
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if distSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local mousePos = input.Position.X
		local barAbsolutePos = __UI.distSliderBar.AbsolutePosition.X
		local barAbsoluteSize = __UI.distSliderBar.AbsoluteSize.X
		local relativeX = math.clamp((mousePos - barAbsolutePos) / barAbsoluteSize, 0, 1)
		__UI.distSliderKnob.Position = UDim2.new(relativeX, 0, 0.5, 0)
		maxDistanceValue = math.round(relativeX * 3500)
		__UI.distLabel.Text = "Max Distance: " .. maxDistanceValue .. " Studs"
		configData.maxDistance = maxDistanceValue
	end
end)

local fovCircle = nil
pcall(function()
	if Drawing then
		fovCircle = Drawing.new("Circle")
		fovCircle.Visible = configData.fovCircle
		fovCircle.Filled = false
		fovCircle.Thickness = 1.5
		fovCircle.Color = Color3.fromRGB(255, 255, 255)
		fovCircle.NumSides = 64
		fovCircle.Radius = fovRadiusValue
	end
end)

local fovCircleEnabled = configData.fovCircle
__UI.fovToggleBtn.MouseButton1Click:Connect(function()
	fovCircleEnabled = not fovCircleEnabled
	configData.fovCircle = fovCircleEnabled
	saveConfig()
	if fovCircleEnabled then
		__UI.fovToggleBtn.Text = "FOV CIRCLE: ON"
		__UI.fovToggleBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		TweenService:Create(__UI.fovToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(6, 78, 59)}):Play()
		__UI.fovToggleStroke.Color = Color3.fromRGB(52, 211, 153)
	else
		__UI.fovToggleBtn.Text = "FOV CIRCLE: OFF"
		__UI.fovToggleBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		TweenService:Create(__UI.fovToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(127, 29, 29)}):Play()
		__UI.fovToggleStroke.Color = Color3.fromRGB(248, 113, 113)
	end
	if fovCircle then fovCircle.Visible = fovCircleEnabled end
end)

local fovRadiusSliding = false
__UI.fovRadiusKnob.MouseButton1Down:Connect(function() fovRadiusSliding = true end)
__UI.fovRadiusBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then fovRadiusSliding = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		fovRadiusSliding = false
		saveConfig()
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if fovRadiusSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local mousePos = input.Position.X
		local barAbsolutePos = __UI.fovRadiusBar.AbsolutePosition.X
		local barAbsoluteSize = __UI.fovRadiusBar.AbsoluteSize.X
		local relativeX = math.clamp((mousePos - barAbsolutePos) / barAbsoluteSize, 0, 1)
		__UI.fovRadiusKnob.Position = UDim2.new(relativeX, 0, 0.5, 0)
		fovRadiusValue = math.round(relativeX * 2500)
		if fovCircle then fovCircle.Radius = fovRadiusValue end
		__UI.fovRadiusLabel.Text = "FOV Circle Size: " .. fovRadiusValue .. " px"
		configData.fovRadius = fovRadiusValue
	end
end)

local function isVisible(targetPart, targetCharacter)
	if not wallCheckActive then return true end
	local origin = camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local ignoreList = {}
	if player.Character then table.insert(ignoreList, player.Character) end
	if targetCharacter then table.insert(ignoreList, targetCharacter) end
	table.insert(ignoreList, camera)
	
	raycastParams.FilterDescendantsInstances = ignoreList
	raycastParams.IgnoreWater = true
	
	local result = Workspace:Raycast(origin, direction, raycastParams)
	if result then
		local hitPart = result.Instance
		local hitModel = hitPart:FindFirstAncestorOfClass("Model")
		if hitModel ~= targetCharacter then return false end
	end
	return true
end

local function isEnemy(targetPlayer)
	if not teamCheckActive then return true end
	if targetPlayer == player then return false end
	if targetPlayer.Team ~= nil and player.Team ~= nil then
		return targetPlayer.Team ~= player.Team
	end
	return true
end

local aimbotToggledOn = true

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local keyStr = configData.aimbotKey
	if not keyStr or keyStr == "" then return end

	local matched = false
	if keyStr == "MouseButton2" and input.UserInputType == Enum.UserInputType.MouseButton2 then matched = true
	elseif keyStr == "MouseButton1" and input.UserInputType == Enum.UserInputType.MouseButton1 then matched = true
	elseif input.UserInputType == Enum.UserInputType.Keyboard then
		local keyCode = Enum.KeyCode[keyStr]
		if keyCode and input.KeyCode == keyCode then matched = true end
	end

	if matched then aimbotToggledOn = not aimbotToggledOn end
end)

local function isAimbotKeyPressed()
	local keyStr = configData.aimbotKey
	if not keyStr or keyStr == "" then return true end
	return aimbotToggledOn
end

RunService.RenderStepped:Connect(function()
	local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	if fovCircle then
		fovCircle.Position = screenCenter
		fovCircle.Visible = fovCircleEnabled
	end
	
	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	
	if myRoot then
		local targetHead = nil
		local shortestDist = math.huge
		local frontEnemyFound = false

		if aimbotActive and isAimbotKeyPressed() then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and isEnemy(p) then
					local char = p.Character
					if char then
						local hum = char:FindFirstChildOfClass("Humanoid")
						local head = char:FindFirstChild("Head")
						
						if hum and hum.Health > 0 and head then
							local distanceInStuds = (myRoot.Position - head.Position).Magnitude
							if distanceInStuds <= maxDistanceValue then
								local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
								if onScreen then
									local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
									if distFromCenter <= fovRadiusValue then
										if isVisible(head, char) then
											frontEnemyFound = true
											if distFromCenter < shortestDist then
												shortestDist = distFromCenter
												targetHead = head
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end

		if not frontEnemyFound and backbotActive and isAimbotKeyPressed() then
			local closestBackHead = nil
			local shortestBackDist = math.huge
			local camLook = camera.CFrame.LookVector

			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player and isEnemy(p) then
					local char = p.Character
					if char then
						local hum = char:FindFirstChildOfClass("Humanoid")
						local head = char:FindFirstChild("Head")

						if hum and hum.Health > 0 and head then
							local distanceInStuds = (myRoot.Position - head.Position).Magnitude
							if distanceInStuds <= maxDistanceValue then
								local toEnemy = (head.Position - camera.CFrame.Position).Unit
								local dot = camLook:Dot(toEnemy)

								if dot < 0.5 then
									if isVisible(head, char) then
										if distanceInStuds < shortestBackDist then
											shortestBackDist = distanceInStuds
											closestBackHead = head
										end
									end
								end
							end
						end
					end
				end
			end

			if closestBackHead then targetHead = closestBackHead end
		end

		if targetHead then
			local targetCFrame = CFrame.new(camera.CFrame.Position, targetHead.Position)
			if frontEnemyFound then
				local smoothFactor = math.clamp(smoothnessValue, 1, 20)
				camera.CFrame = camera.CFrame:Lerp(targetCFrame, 1 / smoothFactor)
			else
				camera.CFrame = camera.CFrame:Lerp(targetCFrame, 0.4)
			end
		end
	end

	if triggerbotActive then
		local mouse = player:GetMouse()
		local target = mouse.Target
		if target then
			local model = target:FindFirstAncestorOfClass("Model")
			if model then
				local targetPlayer = Players:GetPlayerFromCharacter(model)
				local hum = model:FindFirstChildOfClass("Humanoid")
				if targetPlayer and targetPlayer ~= player and hum and hum.Health > 0 and isEnemy(targetPlayer) then
					local delayVal = tonumber(__UI.triggerbotDelayBox.Text) or 0
					if delayVal > 0 then
						task.delay(delayVal / 1000, function()
							if triggerbotActive then pcall(function() mouse1click() end) end
						end)
					else
						pcall(function() mouse1click() end)
					end
				end
			end
		end
	end
end)

local aimbotMenuOpen = false
__UI.aimbotMenuBtn.MouseButton1Click:Connect(function()
	aimbotMenuOpen = not aimbotMenuOpen
	local openInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local closeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if aimbotMenuOpen then
		__UI.aimbotMenuBtn.Text = "AIMBOT: ON"
		__UI.aimbotMenuBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		__UI.aimbotSubPopup.Position = getMarkedAreaGridPosition(__UI.aimbotSubPopup.AbsoluteSize.X, __UI.aimbotSubPopup.AbsoluteSize.Y, {__UI.triggerbotSubPopup, __UI.espSubPopup, __UI.tpSubPopup, __UI.settingsSubPopup, __UI.moreSubPopup, __UI.playerListPopup})
		__UI.aimbotSubPopup.Visible = true
		__UI.aimbotSubPopup.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(__UI.aimbotSubPopup, openInfo, {Size = UDim2.new(0, 240, 0, 410)}):Play()
	else
		__UI.aimbotMenuBtn.Text = "AIMBOT: OFF"
		__UI.aimbotMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		local tween = TweenService:Create(__UI.aimbotSubPopup, closeInfo, {Size = UDim2.new(0, 0, 0, 0)})
		tween:Play()
		tween.Completed:Connect(function()
			if not aimbotMenuOpen then __UI.aimbotSubPopup.Visible = false end
		end)
	end
end)

local triggerbotMenuOpen = false
__UI.triggerbotMenuBtn.MouseButton1Click:Connect(function()
	triggerbotMenuOpen = not triggerbotMenuOpen
	local openInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local closeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if triggerbotMenuOpen then
		__UI.triggerbotMenuBtn.Text = "TRIGGERBOT SETTINGS: ON"
		__UI.triggerbotMenuBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		__UI.triggerbotSubPopup.Position = getMarkedAreaGridPosition(__UI.triggerbotSubPopup.AbsoluteSize.X, __UI.triggerbotSubPopup.AbsoluteSize.Y, {__UI.aimbotSubPopup, __UI.espSubPopup, __UI.tpSubPopup, __UI.settingsSubPopup, __UI.moreSubPopup, __UI.playerListPopup})
		__UI.triggerbotSubPopup.Visible = true
		__UI.triggerbotSubPopup.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(__UI.triggerbotSubPopup, openInfo, {Size = UDim2.new(0, 240, 0, 150)}):Play()
	else
		__UI.triggerbotMenuBtn.Text = "TRIGGERBOT SETTINGS: OFF"
		__UI.triggerbotMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		local tween = TweenService:Create(__UI.triggerbotSubPopup, closeInfo, {Size = UDim2.new(0, 0, 0, 0)})
		tween:Play()
		tween.Completed:Connect(function()
			if not triggerbotMenuOpen then __UI.triggerbotSubPopup.Visible = false end
		end)
	end
end)

local settingsMenuOpen = false
__UI.settingsMenuBtn.MouseButton1Click:Connect(function()
	settingsMenuOpen = not settingsMenuOpen
	local openInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local closeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if settingsMenuOpen then
		__UI.settingsMenuBtn.Text = "SETTINGS: ON"
		__UI.settingsMenuBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		__UI.settingsSubPopup.Position = getMarkedAreaGridPosition(__UI.settingsSubPopup.AbsoluteSize.X, __UI.settingsSubPopup.AbsoluteSize.Y, {__UI.aimbotSubPopup, __UI.triggerbotSubPopup, __UI.espSubPopup, __UI.tpSubPopup, __UI.moreSubPopup, __UI.playerListPopup})
		__UI.settingsSubPopup.Visible = true
		__UI.settingsSubPopup.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(__UI.settingsSubPopup, openInfo, {Size = UDim2.new(0, 260, 0, 470)}):Play()
	else
		__UI.settingsMenuBtn.Text = "SETTINGS: OFF"
		__UI.settingsMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		local tween = TweenService:Create(__UI.settingsSubPopup, closeInfo, {Size = UDim2.new(0, 0, 0, 0)})
		tween:Play()
		tween.Completed:Connect(function()
			if not settingsMenuOpen then __UI.settingsSubPopup.Visible = false end
		end)
	end
end)

local tpMenuOpen = false
__UI.tpMenuBtn.MouseButton1Click:Connect(function()
	tpMenuOpen = not tpMenuOpen
	local openInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local closeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if tpMenuOpen then
		__UI.tpMenuBtn.Text = "TP SETTINGS: ON"
		__UI.tpMenuBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		__UI.tpSubPopup.Position = getMarkedAreaGridPosition(__UI.tpSubPopup.AbsoluteSize.X, __UI.tpSubPopup.AbsoluteSize.Y, {__UI.aimbotSubPopup, __UI.triggerbotSubPopup, __UI.espSubPopup, __UI.settingsSubPopup, __UI.moreSubPopup, __UI.playerListPopup})
		__UI.tpSubPopup.Visible = true
		__UI.tpSubPopup.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(__UI.tpSubPopup, openInfo, {Size = UDim2.new(0, 260, 0, 330)}):Play()
	else
		__UI.tpMenuBtn.Text = "TP SETTINGS: OFF"
		__UI.tpMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		local tween = TweenService:Create(__UI.tpSubPopup, closeInfo, {Size = UDim2.new(0, 0, 0, 0)})
		tween:Play()
		tween.Completed:Connect(function()
			if not tpMenuOpen then __UI.tpSubPopup.Visible = false end
		end)
	end
end)

local espMenuOpen = false
__UI.espMenuBtn.MouseButton1Click:Connect(function()
	espMenuOpen = not espMenuOpen
	local openInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local closeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if espMenuOpen then
		__UI.espMenuBtn.Text = "ESP MENU: ON"
		__UI.espMenuBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		__UI.espSubPopup.Position = getMarkedAreaGridPosition(__UI.espSubPopup.AbsoluteSize.X, __UI.espSubPopup.AbsoluteSize.Y, {__UI.aimbotSubPopup, __UI.triggerbotSubPopup, __UI.tpSubPopup, __UI.settingsSubPopup, __UI.moreSubPopup, __UI.playerListPopup})
		__UI.espSubPopup.Visible = true
		__UI.espSubPopup.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(__UI.espSubPopup, openInfo, {Size = UDim2.new(0, 240, 0, 310)}):Play()
	else
		__UI.espMenuBtn.Text = "ESP MENU: OFF"
		__UI.espMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		local tween = TweenService:Create(__UI.espSubPopup, closeInfo, {Size = UDim2.new(0, 0, 0, 0)})
		tween:Play()
		tween.Completed:Connect(function()
			if not espMenuOpen then __UI.espSubPopup.Visible = false end
		end)
	end
end)

local moreMenuOpen = false
__UI.moreMenuBtn.MouseButton1Click:Connect(function()
	moreMenuOpen = not moreMenuOpen
	local openInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local closeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if moreMenuOpen then
		__UI.moreMenuBtn.Text = "More... : ON"
		__UI.moreMenuBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		__UI.moreSubPopup.Position = getMarkedAreaGridPosition(__UI.moreSubPopup.AbsoluteSize.X, __UI.moreSubPopup.AbsoluteSize.Y, {__UI.aimbotSubPopup, __UI.triggerbotSubPopup, __UI.espSubPopup, __UI.tpSubPopup, __UI.settingsSubPopup, __UI.playerListPopup})
		__UI.moreSubPopup.Visible = true
		__UI.moreSubPopup.Size = UDim2.new(0, 0, 0, 0)

		TweenService:Create(__UI.moreSubPopup, openInfo, {Size = UDim2.new(0, 240, 0, 310)}):Play()
	else
		__UI.moreMenuBtn.Text = "More... : OFF"
		__UI.moreMenuBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		
		local tween = TweenService:Create(__UI.moreSubPopup, closeInfo, {Size = UDim2.new(0, 0, 0, 0)})
		tween:Play()
		tween.Completed:Connect(function()
			if not moreMenuOpen then __UI.moreSubPopup.Visible = false end
		end)
	end
end)

local originalShadows = Lighting.GlobalShadows
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalAmbient = Lighting.Ambient
local originalColorShift_Top = Lighting.ColorShift_Top

local function resetLighting()
	pcall(function()
		Lighting.GlobalShadows = originalShadows
		Lighting.Brightness = originalBrightness
		Lighting.ClockTime = originalClockTime
		Lighting.OutdoorAmbient = originalOutdoorAmbient
		Lighting.Ambient = originalAmbient
		Lighting.ColorShift_Top = originalColorShift_Top
	end)
end

local function applyLightingMode(mode)
	configData.lightingMode = mode
	saveConfig()
	pcall(function()
		if mode == "Performance" then
			Lighting.GlobalShadows = false
			Lighting.Brightness = 2
		elseif mode == "Dark" then
			Lighting.ClockTime = 0
			Lighting.Brightness = 0.5
			Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 35)
			Lighting.Ambient = Color3.fromRGB(10, 10, 20)
		elseif mode == "Blood" then
			Lighting.GlobalShadows = true
			Lighting.ClockTime = 3
			Lighting.Brightness = 1.2
			Lighting.OutdoorAmbient = Color3.fromRGB(130, 0, 0)
			Lighting.Ambient = Color3.fromRGB(70, 0, 0)
			Lighting.ColorShift_Top = Color3.fromRGB(255, 0, 0)
		elseif mode == "Sunset" then
			Lighting.ClockTime = 18
			Lighting.Brightness = 2.5
			Lighting.OutdoorAmbient = Color3.fromRGB(255, 140, 60)
			Lighting.Ambient = Color3.fromRGB(200, 90, 30)
			Lighting.ColorShift_Top = Color3.fromRGB(255, 165, 0)
		elseif mode == "Neon" then
			Lighting.ClockTime = 2
			Lighting.Brightness = 1.8
			Lighting.OutdoorAmbient = Color3.fromRGB(0, 180, 255)
			Lighting.Ambient = Color3.fromRGB(150, 0, 255)
			Lighting.ColorShift_Top = Color3.fromRGB(0, 255, 255)
		else
			resetLighting()
		end
	end)
end

if configData.lightingMode and configData.lightingMode ~= "Normal" then
	applyLightingMode(configData.lightingMode)
end

perfModeBtn.MouseButton1Click:Connect(function()
	if configData.lightingMode == "Performance" then
		applyLightingMode("Normal")
		perfModeBtn.Text = "Performance Mode: OFF"
		perfModeBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		perfModeBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	else
		applyLightingMode("Performance")
		perfModeBtn.Text = "Performance Mode: ON"
		perfModeBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		perfModeBtn.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
	end
end)

local originalMaterials = {}
local lowDetailActive = false
lowDetailBtn.MouseButton1Click:Connect(function()
	lowDetailActive = not lowDetailActive
	if lowDetailActive then
		lowDetailBtn.Text = "Low Detail Mode: ON"
		lowDetailBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		lowDetailBtn.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
		pcall(function()
			for _, v in ipairs(Workspace:GetDescendants()) do
				if v:IsA("BasePart") then
					if not originalMaterials[v] then originalMaterials[v] = v.Material end
					v.Material = Enum.Material.SmoothPlastic
				end
			end
		end)
	else
		lowDetailBtn.Text = "Low Detail Mode: OFF"
		lowDetailBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		lowDetailBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
		pcall(function()
			for part, mat in pairs(originalMaterials) do
				if part and part.Parent then part.Material = mat end
			end
		end)
	end
end)

highDetailBtn.MouseButton1Click:Connect(function()
	lowDetailActive = false
	lowDetailBtn.Text = "Low Detail Mode: OFF"
	lowDetailBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
	highDetailBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	pcall(function()
		for part, mat in pairs(originalMaterials) do
			if part and part.Parent then part.Material = mat end
		end
	end)
end)

darkModeBtn.MouseButton1Click:Connect(function()
	if configData.lightingMode == "Dark" then
		applyLightingMode("Normal")
		darkModeBtn.Text = "🌙 Dark Mode: OFF"
		darkModeBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		darkModeBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	else
		applyLightingMode("Dark")
		darkModeBtn.Text = "🌙 Dark Mode: ON"
		darkModeBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		darkModeBtn.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
	end
end)

bloodRedBtn.MouseButton1Click:Connect(function()
	if configData.lightingMode == "Blood" then
		applyLightingMode("Normal")
		bloodRedBtn.Text = "🩸 Blood Red (Danger): OFF"
		bloodRedBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		bloodRedBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	else
		applyLightingMode("Blood")
		bloodRedBtn.Text = "🩸 Blood Red (Danger): ON"
		bloodRedBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
		bloodRedBtn.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
	end
end)

sunsetBtn.MouseButton1Click:Connect(function()
	if configData.lightingMode == "Sunset" then
		applyLightingMode("Normal")
		sunsetBtn.Text = "☀️ Sunset Glow: OFF"
		sunsetBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		sunsetBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	else
		applyLightingMode("Sunset")
		sunsetBtn.Text = "☀️ Sunset Glow: ON"
		sunsetBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		sunsetBtn.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
	end
end)

neonBtn.MouseButton1Click:Connect(function()
	if configData.lightingMode == "Neon" then
		applyLightingMode("Normal")
		neonBtn.Text = "💎 Cyberpunk Neon: OFF"
		neonBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		neonBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	else
		applyLightingMode("Neon")
		neonBtn.Text = "💎 Cyberpunk Neon: ON"
		neonBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		neonBtn.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
	end
end)

__UI.saveConfigBtn.MouseButton1Click:Connect(function()
	saveConfig()
	__UI.saveConfigBtn.Text = "✨ SAVED!"
	task.delay(1.5, function() __UI.saveConfigBtn.Text = "💾 SAVE CONFIG NOW" end)
end)

tpNearestBtn.MouseButton1Click:Connect(function()
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	local nearestPlayer, shortestDist = nil, math.huge
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude
			if dist < shortestDist then
				shortestDist = dist
				nearestPlayer = p
			end
		end
	end
	if nearestPlayer and nearestPlayer.Character and nearestPlayer.Character:FindFirstChild("HumanoidRootPart") then
		executeTpToTarget(nearestPlayer.Character.HumanoidRootPart)
	end
end)

local savedPosition = nil
savePosBtn.MouseButton1Click:Connect(function()
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if myRoot then savedPosition = myRoot.CFrame end
end)

loadPosBtn.MouseButton1Click:Connect(function()
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if myRoot and savedPosition then myRoot.CFrame = savedPosition end
end)

local clickTpActive = configData.clickTp
clickTpToggleBtn.MouseButton1Click:Connect(function()
	clickTpActive = not clickTpActive
	configData.clickTp = clickTpActive
	saveConfig()
	if clickTpActive then
		clickTpToggleBtn.Text = "Ctrl + Click TP: ON"
		clickTpToggleBtn.TextColor3 = Color3.fromRGB(110, 231, 183)
		clickTpToggleBtn.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
	else
		clickTpToggleBtn.Text = "Ctrl + Click TP: OFF"
		clickTpToggleBtn.TextColor3 = Color3.fromRGB(254, 202, 202)
		clickTpToggleBtn.BackgroundColor3 = Color3.fromRGB(14, 116, 144)
	end
end)

__UI.keyBox.FocusLost:Connect(function()
	configData.tpKey = __UI.keyBox.Text
	saveConfig()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if clickTpActive and not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 then
		local customKey = Enum.KeyCode[configData.tpKey] or Enum.KeyCode.LeftControl
		if UserInputService:IsKeyDown(customKey) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			local mouse = player:GetMouse()
			local targetPos = mouse.Hit
			local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if myRoot and targetPos then
				local originalPos = myRoot.CFrame
				myRoot.CFrame = targetPos + Vector3.new(0, 2, 0)
				if configData.scareTp then
					task.delay(0.2, function()
						if myRoot and myRoot.Parent then myRoot.CFrame = originalPos end
					end)
				end
			end
		end
	end
end)

local espSettings = configData.esp or { Box = false, Name = false, Health = false, Tracer = false, Skeleton = false, Chams = false }
local function toggleEspFeature(key, btn, stroke)
	espSettings[key] = not espSettings[key]
	configData.esp = espSettings
	saveConfig()
	if espSettings[key] then
		btn.Text = btn.Text:gsub("OFF", "ON")
		btn.TextColor3 = Color3.fromRGB(110, 231, 183)
		stroke.Color = Color3.fromRGB(52, 211, 153)
		btn.BackgroundColor3 = Color3.fromRGB(6, 78, 59)
	else
		btn.Text = btn.Text:gsub("ON", "OFF")
		btn.TextColor3 = Color3.fromRGB(254, 202, 202)
		stroke.Color = Color3.fromRGB(248, 113, 113)
		btn.BackgroundColor3 = Color3.fromRGB(127, 29, 29)
	end
end

boxBtn.MouseButton1Click:Connect(function() toggleEspFeature("Box", boxBtn, boxStroke) end)
nameBtn.MouseButton1Click:Connect(function() toggleEspFeature("Name", nameBtn, nameStroke) end)
healthBtn.MouseButton1Click:Connect(function() toggleEspFeature("Health", healthBtn, healthStroke) end)
tracerBtn.MouseButton1Click:Connect(function() toggleEspFeature("Tracer", tracerBtn, tracerStroke) end)
skelBtn.MouseButton1Click:Connect(function() toggleEspFeature("Skeleton", skelBtn, skelStroke) end)
xrayBtn.MouseButton1Click:Connect(function() toggleEspFeature("Chams", xrayBtn, xrayStroke) end)

local espDrawings = {}
local function removeEsp(p)
	if espDrawings[p] then
		pcall(function()
			for k, obj in pairs(espDrawings[p]) do
				if k == "SkeletonLines" and type(obj) == "table" then
					for _, l in ipairs(obj) do pcall(function() l:Remove() end) end
				elseif k == "Highlight" then
					pcall(function() obj:Destroy() end)
				else
					pcall(function() obj:Remove() end)
				end
			end
		end)
		espDrawings[p] = nil
	end
end
Players.PlayerRemoving:Connect(removeEsp)

RunService.RenderStepped:Connect(function()
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local char = p.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if char and hrp and hum and hum.Health > 0 then
				if not espDrawings[p] then
					pcall(function()
						local hl = Instance.new("Highlight")
						hl.Adornee = char
						hl.Parent = char
						hl.Enabled = false
						local skelLines = {}
						for i = 1, 5 do
							local l = Drawing.new("Line")
							l.Thickness = 1.5
							l.Visible = false
							table.insert(skelLines, l)
						end
						espDrawings[p] = {
							Box = Drawing.new("Square"),
							Name = Drawing.new("Text"),
							HealthBar = Drawing.new("Line"),
							HealthBarBg = Drawing.new("Line"),
							Tracer = Drawing.new("Line"),
							SkeletonLines = skelLines,
							Highlight = hl
						}
						espDrawings[p].Box.Filled = false
						espDrawings[p].Box.Thickness = 1.5
						espDrawings[p].Name.Size = 13
						espDrawings[p].Name.Center = true
						espDrawings[p].Name.Outline = true
						espDrawings[p].HealthBar.Thickness = 2
						espDrawings[p].HealthBarBg.Thickness = 3
						espDrawings[p].Tracer.Thickness = 1.5
					end)
				end
				local drawings = espDrawings[p]
				if drawings then
					local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
					if onScreen then
						local head = char:FindFirstChild("Head")
						local headPos = head and camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or vector
						local legPos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
						local height = math.abs(headPos.Y - legPos.Y)
						local width = height / 2

						if espSettings.Box then
							drawings.Box.Visible = true
							drawings.Box.Size = Vector2.new(width, height)
							drawings.Box.Position = Vector2.new(vector.X - width / 2, headPos.Y)
							drawings.Box.Color = currentEspColor
						else drawings.Box.Visible = false end

						if espSettings.Name then
							local distText = ""
							if myRoot then
								local distance = math.round((myRoot.Position - hrp.Position).Magnitude)
								distText = " [" .. distance .. "m]"
							end
							drawings.Name.Visible = true
							drawings.Name.Text = p.Name .. distText
							drawings.Name.Position = Vector2.new(vector.X, headPos.Y - 16)
							drawings.Name.Color = currentEspColor
						else drawings.Name.Visible = false end

						if espSettings.Health then
							local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
							local bh = height * hp
							drawings.HealthBarBg.Visible = true
							drawings.HealthBarBg.From = Vector2.new(vector.X - width / 2 - 6, headPos.Y + height)
							drawings.HealthBarBg.To = Vector2.new(vector.X - width / 2 - 6, headPos.Y)
							drawings.HealthBarBg.Color = Color3.fromRGB(0,0,0)
							drawings.HealthBar.Visible = true
							drawings.HealthBar.From = Vector2.new(vector.X - width / 2 - 6, headPos.Y + height)
							drawings.HealthBar.To = Vector2.new(vector.X - width / 2 - 6, headPos.Y + (height - bh))
							drawings.HealthBar.Color = Color3.fromRGB(0,255,0)
						else
							drawings.HealthBar.Visible = false
							drawings.HealthBarBg.Visible = false
						end

						if espSettings.Tracer then
							drawings.Tracer.Visible = true
							drawings.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
							drawings.Tracer.To = Vector2.new(vector.X, legPos.Y)
							drawings.Tracer.Color = currentEspColor
						else drawings.Tracer.Visible = false end

						if espSettings.Skeleton and head then
							local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
							local la = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
							local ra = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
							local ll = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
							local rl = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
							local joints = {{head, torso}, {torso, la}, {torso, ra}, {torso, ll}, {torso, rl}}
							for idx, pair in ipairs(joints) do
								local lineObj = drawings.SkeletonLines[idx]
								if pair[1] and pair[2] and lineObj then
									local p1, on1 = camera:WorldToViewportPoint(pair[1].Position)
									local p2, on2 = camera:WorldToViewportPoint(pair[2].Position)
									if on1 and on2 then
										lineObj.Visible = true
										lineObj.From = Vector2.new(p1.X, p1.Y)
										lineObj.To = Vector2.new(p2.X, p2.Y)
										lineObj.Color = currentEspColor
									else lineObj.Visible = false end
								else if lineObj then lineObj.Visible = false end end
							end
						else
							for _, l in ipairs(drawings.SkeletonLines) do l.Visible = false end
						end

						if espSettings.Chams then
							drawings.Highlight.Enabled = true
							drawings.Highlight.FillColor = currentEspColor
							drawings.Highlight.OutlineColor = currentEspColor
							drawings.Highlight.FillTransparency = 0.5
						else drawings.Highlight.Enabled = false end
					else
						drawings.Box.Visible = false
						drawings.Name.Visible = false
						drawings.HealthBar.Visible = false
						drawings.HealthBarBg.Visible = false
						drawings.Tracer.Visible = false
						for _, l in ipairs(drawings.SkeletonLines) do l.Visible = false end
						drawings.Highlight.Enabled = false
					end
				end
			else removeEsp(p) end
		end
	end
end)

__UI.setSpeedBtn.MouseButton1Click:Connect(function()
	local val = tonumber(__UI.speedBox.Text)
	if val then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = val
			configData.speed = val
			saveConfig()
		end
	end
end)

__UI.resetSpeedBtn.MouseButton1Click:Connect(function()
	__UI.speedBox.Text = "16"
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 16
		configData.speed = 16
		saveConfig()
	end
end)

local sliding = false
__UI.sliderKnob.MouseButton1Down:Connect(function() sliding = true end)
__UI.sliderBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 then
		sliding = false
		saveConfig()
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
		local rel = math.clamp((i.Position.X - __UI.sliderBar.AbsolutePosition.X) / __UI.sliderBar.AbsoluteSize.X, 0, 1)
		__UI.sliderKnob.Position = UDim2.new(rel, 0, 0.5, 0)
		local fv = math.round(rel * 200)
		pcall(function() camera.FieldOfView = fv end)
		__UI.fovLabel.Text = "Camera FOV: " .. fv
		configData.cameraFov = fv
	end
end)

local function makeDraggable(popup, handle)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = popup.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			popup.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

makeDraggable(__UI.draggablePopup, __UI.popTopBar)
makeDraggable(__UI.fovPopup, __UI.fovTopBar)
makeDraggable(__UI.espSubPopup, __UI.espSubTopBar)
makeDraggable(__UI.tpSubPopup, __UI.tpSubTopBar)
makeDraggable(__UI.settingsSubPopup, __UI.settingsSubTopBar)
makeDraggable(__UI.aimbotSubPopup, __UI.aimbotSubTopBar)
makeDraggable(__UI.triggerbotSubPopup, __UI.triggerbotSubTopBar)
makeDraggable(__UI.playerListPopup, __UI.plTopBar)
makeDraggable(__UI.moreSubPopup, __UI.moreSubTopBar)

--------------------------------------------------------------------------------
-- ❄️🎄 WINTER FX ENGINE 2.0  (rein visuell - ändert KEINE Funktion des Scripts)
-- Schneefall, Aurora, Lichterketten, Hover-/Klick-Effekte, Konfetti & mehr.
-- Läuft in einer eigenen Funktion + pcall: ein Fehler hier kann nichts kaputt machen.
--------------------------------------------------------------------------------
task.spawn(function()
local fxOk, fxErr = pcall(function()
	if configData.fxEnabled == nil then configData.fxEnabled = true end

	local gui = screenGui
	local rng = Random.new()

	local WHITE  = Color3.fromRGB(240, 249, 255)
	local ICE    = Color3.fromRGB(125, 211, 252)
	local RED    = Color3.fromRGB(225, 29, 72)
	local GREEN  = Color3.fromRGB(16, 185, 129)
	local GOLD   = Color3.fromRGB(251, 191, 36)
	local PURPLE = Color3.fromRGB(168, 85, 247)
	local NAVY   = Color3.fromRGB(15, 23, 42)
	local BULBS  = { RED, GOLD, GREEN, ICE, PURPLE }
	local PARTY  = { ICE, WHITE, RED, GOLD, GREEN }
	local SPARK  = { "✦", "✧", "❄", "❅", "✺" }
	local EMO    = { "🎁", "🔔", "⭐", "🎄", "🍬", "🧦" }
	local ORNAMENTS = { "🎅", "🔔", "🎁", "⛄", "🌟", "🍬", "🎄", "🧦" }
	local ornamentIdx = 0

	local function fxOn() return configData.fxEnabled ~= false end

	local function safe(fn, ...)
		local ok, e = pcall(fn, ...)
		if not ok then warn("[SOLANASZ FX] " .. tostring(e)) end
	end

	local function new(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do o[k] = v end
		if parent then o.Parent = parent end
		return o
	end

	local function tw(o, t, props, style, dir)
		local ok, tween = pcall(function()
			local tn = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
			tn:Play()
			return tn
		end)
		if ok then return tween end
		return nil
	end

	-- Registries für die zentrale Animations-Schleife
	local spinners, auroras, snows, bulbs, shimmers, panels = {}, {}, {}, {}, {}, {}
	local extras = {}
	local liveParticles = 0

	-- Overlay (Partikel, immer oben) + Schnee-Hintergrund (immer unten)
	local overlay = new("Frame", {
		Name = "FX_Overlay", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, Active = false, ZIndex = 800,
	}, gui)
	local backLayer = new("Frame", {
		Name = "FX_SnowBack", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, Active = false, ZIndex = 1, ClipsDescendants = true,
	}, gui)

	----------------------------------------------------------------------------
	-- PARTIKEL
	----------------------------------------------------------------------------
	local function sparkle(x, y, color, dist, life, size, emoji)
		if liveParticles > 90 then return end
		liveParticles += 1
		life = life or 0.8
		dist = dist or 60
		local p = new("TextLabel", {
			Name = "FX_P", BackgroundTransparency = 1, Text = emoji and EMO[rng:NextInteger(1, #EMO)] or SPARK[rng:NextInteger(1, #SPARK)], TextColor3 = color,
			TextSize = size or rng:NextInteger(12, 20), Font = Enum.Font.GothamBold,
			Size = UDim2.new(0, 20, 0, 20), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, x, 0, y), Rotation = rng:NextInteger(-40, 40),
			Active = false, ZIndex = 810,
		}, overlay)
		local ang = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(dist * 0.4, dist)
		tw(p, life, {
			Position = UDim2.new(0, x + math.cos(ang) * d, 0, y + math.sin(ang) * d + 14),
			TextTransparency = 1, Rotation = p.Rotation + rng:NextInteger(-120, 120),
		})
		task.delay(life + 0.05, function()
			liveParticles -= 1
			p:Destroy()
		end)
	end

	local function burst(x, y, n, dist)
		if not fxOn() then return end
		for _ = 1, n do
			sparkle(x, y, PARTY[rng:NextInteger(1, #PARTY)], dist or 90, rng:NextNumber(0.6, 1.1), rng:NextInteger(13, 20), rng:NextNumber() < 0.45)
		end
	end

	local function burstPanel(panel)
		task.spawn(function()
			RunService.RenderStepped:Wait()
			if panel.Parent then
				local a, s = panel.AbsolutePosition, panel.AbsoluteSize
				burst(a.X + s.X / 2, a.Y + s.Y / 2, 12, math.max(s.X, s.Y) * 0.45)
			end
		end)
	end

	----------------------------------------------------------------------------
	-- SCHNEE
	----------------------------------------------------------------------------
	local function addSnow(layer, count, z, big, panel)
		local sys = { layer = layer, panel = panel, flakes = {}, shown = nil }
		for _ = 1, count do
			local size = big and rng:NextInteger(4, 9) or rng:NextInteger(3, 6)
			local f
			if rng:NextNumber() < 0.3 then
				f = new("TextLabel", {
					Name = "FX_Flake", BackgroundTransparency = 1, Text = "❄", Font = Enum.Font.Gotham, TextColor3 = WHITE,
					TextSize = size + 7, TextTransparency = big and rng:NextNumber(0.25, 0.6) or rng:NextNumber(0.55, 0.8),
					Size = UDim2.new(0, size + 8, 0, size + 8), Active = false, ZIndex = z,
				}, layer)
			else
				f = new("Frame", {
					Name = "FX_Flake", BackgroundColor3 = WHITE, BackgroundTransparency = big and rng:NextNumber(0.2, 0.6) or rng:NextNumber(0.5, 0.8),
					BorderSizePixel = 0, Size = UDim2.new(0, size, 0, size), Active = false, ZIndex = z,
				}, layer)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
			end
			table.insert(sys.flakes, {
				o = f, x = rng:NextNumber(), y = rng:NextNumber(),
				vy = rng:NextNumber(0.05, 0.16) * (big and 1 or 1.3),
				sway = rng:NextNumber(0.005, 0.03), ph = rng:NextNumber(0, 6.28), fq = rng:NextNumber(0.6, 1.6),
			})
		end
		table.insert(snows, sys)
		return sys
	end

	safe(addSnow, backLayer, 34, 1, true, nil)

	-- Weiche Lichter (Bokeh) im Hintergrund
	safe(function()
		local cols = { RED, GREEN, GOLD, ICE, PURPLE }
		for i = 1, 8 do
			local sz = rng:NextInteger(70, 150)
			local o = new("Frame", {
				Name = "FX_Bokeh", Size = UDim2.new(0, sz, 0, sz), AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = cols[(i - 1) % #cols + 1], BackgroundTransparency = 0.93,
				BorderSizePixel = 0, Active = false, ZIndex = 1,
			}, backLayer)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, o)
			local bx, by, ph = rng:NextNumber(0.05, 0.95), rng:NextNumber(0.1, 0.9), rng:NextNumber(0, 6.28)
			table.insert(extras, function(t)
				o.Position = UDim2.new(bx + math.sin(t * 0.12 + ph) * 0.05, 0, by + math.cos(t * 0.1 + ph) * 0.05, 0)
				o.BackgroundTransparency = 0.91 + 0.04 * math.sin(t * 0.8 + ph)
			end)
		end
	end)

	-- Lichterkette quer über den oberen Bildschirmrand
	safe(function()
		local garland = new("Frame", {
			Name = "FX_Garland", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
			BorderSizePixel = 0, Active = false, ZIndex = 2,
		}, gui)
		local vw = (camera and camera.ViewportSize.X) or 1280
		local n = math.max(14, math.floor(vw / 46))
		for i = 1, n do
			local fx = (i - 0.5) / n
			local sag = math.abs(math.sin(fx * math.pi * 6)) * 9
			new("Frame", {
				Size = UDim2.new(0, 3, 0, 4), Position = UDim2.new(fx, -1, 0, sag),
				BackgroundColor3 = Color3.fromRGB(20, 60, 40), BorderSizePixel = 0, Active = false, ZIndex = 2,
			}, garland)
			local bulb = new("Frame", {
				Size = UDim2.new(0, 7, 0, 10), Position = UDim2.new(fx, -3, 0, sag + 4),
				BackgroundColor3 = BULBS[(i - 1) % #BULBS + 1], BorderSizePixel = 0, Active = false, ZIndex = 2,
			}, garland)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, bulb)
			table.insert(bulbs, { o = bulb, ph = i * 0.8, always = true })
		end
		table.insert(extras, function() garland.Visible = fxOn() end)
	end)

	----------------------------------------------------------------------------
	-- TOAST (Benachrichtigung oben)
	----------------------------------------------------------------------------
	local function toast(msg, color)
		local f = new("Frame", {
			Size = UDim2.new(0, 360, 0, 42), AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -60), BackgroundColor3 = NAVY,
			BorderSizePixel = 0, Active = false, ZIndex = 900,
		}, gui)
		new("UICorner", { CornerRadius = UDim.new(0, 12) }, f)
		local st = new("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1) }, f)
		new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, color or ICE),
				ColorSequenceKeypoint.new(0.5, WHITE),
				ColorSequenceKeypoint.new(1, color or ICE),
			}),
		}, st)
		new("TextLabel", {
			Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1,
			Name = "FX_ToastText", Text = msg, TextColor3 = WHITE, TextSize = 14, Font = Enum.Font.GothamBold,
			TextStrokeTransparency = 0.5, TextStrokeColor3 = Color3.fromRGB(8, 12, 24), Active = false, ZIndex = 901,
		}, f)
		tw(f, 0.5, { Position = UDim2.new(0.5, 0, 0, 16) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		task.delay(3.4, function()
			tw(f, 0.4, { Position = UDim2.new(0.5, 0, 0, -60) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.5, function() f:Destroy() end)
		end)
	end

	----------------------------------------------------------------------------
	-- FENSTER-DEKORATION
	----------------------------------------------------------------------------
	local function decoratePanel(panel)
		if not panel or panel:GetAttribute("FX_Done") then return end
		panel:SetAttribute("FX_Done", true)
		table.insert(panels, panel)

		local z = panel.ZIndex
		local corner = panel:FindFirstChildOfClass("UICorner")
		local radius = corner and corner.CornerRadius or UDim.new(0, 14)

		-- 1) Rahmen: laufender Farbverlauf (Eis -> Weiß -> Rot -> Grün)
		local stroke = panel:FindFirstChildOfClass("UIStroke")
		if stroke then
			local base = stroke.Color
			stroke.Color = Color3.new(1, 1, 1)
			local g = new("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, base),
					ColorSequenceKeypoint.new(0.25, WHITE),
					ColorSequenceKeypoint.new(0.5, RED),
					ColorSequenceKeypoint.new(0.75, GREEN),
					ColorSequenceKeypoint.new(1, base),
				}),
			}, stroke)
			table.insert(spinners, { g = g, speed = rng:NextNumber(45, 80), off = rng:NextNumber(0, 360) })
		end

		-- 2) Aurora-Schimmer im Hintergrund
		local aurora = new("Frame", {
			Name = "FX_Aurora", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.9, BorderSizePixel = 0, Active = false, ZIndex = z,
		}, panel)
		new("UICorner", { CornerRadius = radius }, aurora)
		local ag = new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(56, 189, 248)),
				ColorSequenceKeypoint.new(0.35, Color3.fromRGB(52, 211, 153)),
				ColorSequenceKeypoint.new(0.65, Color3.fromRGB(168, 85, 247)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72)),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 0.55),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}, aurora)
		table.insert(auroras, { g = ag, ph = rng:NextNumber(0, 6.28) })

		-- 3) Schnee im Fenster
		local snowLayer = new("Frame", {
			Name = "FX_Snow", Size = UDim2.new(1, -6, 1, -6), Position = UDim2.new(0, 3, 0, 3),
			BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
			Active = false, ZIndex = z,
		}, panel)
		addSnow(snowLayer, 6, z, false, panel)

		-- 4) Schneehaube oben auf dem Fenster
		local cap = new("Frame", {
			Name = "FX_SnowCap", Size = UDim2.new(1, -30, 0, 6), Position = UDim2.new(0, 15, 0, -4),
			BackgroundColor3 = WHITE, BorderSizePixel = 0, Active = false, ZIndex = z + 8,
		}, panel)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, cap)
		for i = 1, 7 do
			local w = rng:NextInteger(10, 22)
			local h = math.floor(w * 0.6)
			local bump = new("Frame", {
				Size = UDim2.new(0, w, 0, h), Position = UDim2.new((i - 0.5) / 7, -w / 2, 0, -math.floor(h * 0.7)),
				BackgroundColor3 = WHITE, BorderSizePixel = 0, Active = false, ZIndex = z + 8,
			}, cap)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, bump)
		end

		-- 5) Lichterkette am Titelbalken
		local barH = 32
		for _, c in ipairs(panel:GetChildren()) do
			if string.find(c.Name, "TopBar") and c.Size.Y.Offset > 0 then
				barH = c.Size.Y.Offset
				break
			end
		end
		local lights = new("Frame", {
			Name = "FX_Lights", Size = UDim2.new(1, -20, 0, barH), Position = UDim2.new(0, 10, 0, 0),
			BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, ZIndex = z + 7,
		}, panel)
		local pw = panel.Size.X.Offset > 0 and panel.Size.X.Offset or 260
		local n = math.max(6, math.floor(pw / 24))
		for i = 1, n do
			local sag = math.abs(math.sin((i - 0.5) / n * math.pi * 3)) * 3
			local bulb = new("Frame", {
				Size = UDim2.new(0, 3, 0, 4), Position = UDim2.new((i - 0.5) / n, -1, 0, barH - 6 + sag * 0.6),
				BackgroundColor3 = BULBS[(i - 1) % #BULBS + 1], BorderSizePixel = 0,
				Active = false, ZIndex = z + 7,
			}, lights)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, bulb)
			table.insert(bulbs, { o = bulb, ph = i * 0.9, panel = panel })
		end

		-- 5b) Zuckerstangen-Band unter dem Fenster + hängendes Ornament oben links
		local ribbon = new("Frame", {
			Name = "FX_Ribbon", Size = UDim2.new(1, -28, 0, 4), Position = UDim2.new(0, 14, 1, 2),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = false, ZIndex = z + 8,
		}, panel)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, ribbon)
		do
			local seq, ns = {}, 24
			for k = 0, ns - 1 do
				local c = (k % 2 == 0) and RED or WHITE
				table.insert(seq, ColorSequenceKeypoint.new(k / ns, c))
				table.insert(seq, ColorSequenceKeypoint.new(k == ns - 1 and 1 or ((k + 1) / ns - 0.002), c))
			end
			new("UIGradient", { Color = ColorSequence.new(seq) }, ribbon)
		end
		ornamentIdx += 1
		local orn = new("TextLabel", {
			Name = "FX_Ornament", BackgroundTransparency = 1, Text = ORNAMENTS[(ornamentIdx - 1) % #ORNAMENTS + 1],
			TextSize = 22, Font = Enum.Font.GothamBold, Size = UDim2.new(0, 30, 0, 30),
			AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0, 26, 0, 6), Active = false, ZIndex = z + 9,
		}, panel)
		local oph = rng:NextNumber(0, 6.28)
		table.insert(extras, function(t) orn.Rotation = math.sin(t * 1.4 + oph) * 9 end)

		-- 6) Pop-In Animation beim Öffnen
		local scale = new("UIScale", { Name = "FX_PanelScale", Scale = 1 }, panel)
		local function popIn()
			scale.Scale = 0.86
			tw(scale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			burstPanel(panel)
		end
		panel:GetPropertyChangedSignal("Visible"):Connect(function()
			if panel.Visible then popIn() end
		end)
		if panel.Visible then popIn() end
	end

	local panelList = {
		__UI.keyFrame, __UI.mainFrame, __UI.draggablePopup, __UI.fovPopup, __UI.moreSubPopup,
		__UI.aimbotSubPopup, __UI.triggerbotSubPopup, __UI.espSubPopup, __UI.tpSubPopup,
		__UI.playerListPopup, __UI.settingsSubPopup,
	}
	for _, p in ipairs(panelList) do safe(decoratePanel, p) end

	----------------------------------------------------------------------------
	-- HAUPTMENÜ: Candy-Cane-Rahmen, Halo, Glanz, Bäume, Weihnachts-Countdown
	----------------------------------------------------------------------------
	safe(function()
		local mf, rb = __UI.mainFrame, __UI.rivalsButton
		if not mf or not rb then return end

		-- Candy-Cane Rahmen (rot/weiß gestreift, rotierend)
		local rs = rb:FindFirstChildOfClass("UIStroke")
		if rs then
			rs.Color = Color3.new(1, 1, 1)
			rs.Thickness = 3
			local seq, n = {}, 12
			for k = 0, n - 1 do
				local c = (k % 2 == 0) and RED or WHITE
				table.insert(seq, ColorSequenceKeypoint.new(k / n, c))
				table.insert(seq, ColorSequenceKeypoint.new(k == n - 1 and 1 or ((k + 1) / n - 0.002), c))
			end
			local cg = new("UIGradient", { Color = ColorSequence.new(seq) }, rs)
			table.insert(spinners, { g = cg, speed = 40, off = 0 })
		end

		-- Atmendes Halo hinter dem Button
		local halo = new("Frame", {
			Name = "FX_Halo", Size = rb.Size + UDim2.new(0, 16, 0, 16), AnchorPoint = rb.AnchorPoint,
			Position = rb.Position, BackgroundTransparency = 1, BorderSizePixel = 0, Active = false,
			ZIndex = math.max(1, rb.ZIndex - 1),
		}, mf)
		new("UICorner", { CornerRadius = UDim.new(0, 16) }, halo)
		local hs = new("UIStroke", { Thickness = 2, Color = ICE, Transparency = 0.5 }, halo)
		table.insert(extras, function(t)
			hs.Transparency = 0.45 + 0.4 * (0.5 + 0.5 * math.sin(t * 2.2))
			hs.Thickness = 2 + 1.5 * (0.5 + 0.5 * math.sin(t * 2.2))
		end)

		-- Glanz-Streifen, der über den Button wandert
		local shineClip = new("Frame", {
			Name = "FX_ShineClip", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
			BorderSizePixel = 0, ClipsDescendants = true, Active = false, ZIndex = rb.ZIndex + 1,
		}, rb)
		new("UICorner", { CornerRadius = UDim.new(0, 10) }, shineClip)
		local shine = new("Frame", {
			Size = UDim2.new(0, 30, 1.8, 0), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(-0.2, 0, 0.5, 0), Rotation = 18, BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.92, BorderSizePixel = 0, Active = false, ZIndex = rb.ZIndex + 1,
		}, shineClip)
		new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, shine)
		table.insert(extras, function(t)
			shine.Position = UDim2.new(((t * 0.28) % 1.6) - 0.3, 0, 0.5, 0)
		end)

		-- Deko-Emojis (wippen sanft)
		local deco = {
			{ "🎄", 0, 34, 40 }, { "🎁", 0, 76, 24 }, { "⛄", 1, -34, 38 }, { "🎅", 1, -76, 26 },
		}
		for i, dcfg in ipairs(deco) do
			local lbl = new("TextLabel", {
				Name = "FX_Deco" .. i, BackgroundTransparency = 1, Text = dcfg[1], TextSize = dcfg[4],
				Font = Enum.Font.GothamBold, Size = UDim2.new(0, 50, 0, 50), AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(dcfg[2], dcfg[3], 1, -8), Active = false, ZIndex = 7,
			}, mf)
			local ph = i * 1.3
			table.insert(extras, function(t) lbl.Rotation = math.sin(t * 1.6 + ph) * 6 end)
		end

		-- Laufband mit Weihnachtsgrüßen
		local tickClip = new("Frame", {
			Name = "FX_TickerClip", Size = UDim2.new(0.9, 0, 0, 22), Position = UDim2.new(0.05, 0, 0, 58),
			BackgroundColor3 = Color3.fromRGB(8, 16, 32), BackgroundTransparency = 0.35, BorderSizePixel = 0,
			ClipsDescendants = true, Active = false, ZIndex = 7,
		}, mf)
		new("UICorner", { CornerRadius = UDim.new(0, 8) }, tickClip)
		new("UIStroke", { Thickness = 1, Color = ICE, Transparency = 0.5 }, tickClip)
		local tmsg = "🎄 Frohe Weihnachten   ❄   Merry Christmas   🎁   Joyeux Noël   ❄   Feliz Navidad   🔔   Buon Natale   ⭐   "
		local function mkTick()
			return new("TextLabel", {
				Name = "FX_Tick", BackgroundTransparency = 1, Text = tmsg, TextColor3 = WHITE, TextSize = 13,
				Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
				TextStrokeTransparency = 0.5, TextStrokeColor3 = Color3.fromRGB(6, 10, 22), Active = false, ZIndex = 8,
			}, tickClip)
		end
		local tk1, tk2 = mkTick(), mkTick()
		task.spawn(function()
			task.wait(0.6)
			local W = tk1.TextBounds.X
			if W < 100 then
				pcall(function()
					W = game:GetService("TextService"):GetTextSize(tmsg, 13, Enum.Font.GothamBold, Vector2.new(100000, 100)).X
				end)
			end
			if W < 100 then W = 700 end
			table.insert(extras, function(t)
				local x = -((t * 45) % W)
				tk1.Position = UDim2.new(0, x, 0, 0)
				tk2.Position = UDim2.new(0, x + W, 0, 0)
			end)
		end)

		-- Weihnachts-Countdown
		local function xmasText()
			local now = os.time()
			local d = os.date("*t", now)
			if d.month == 12 and d.day == 24 then return "🎅 Heiligabend! Frohe Weihnachten!" end
			if d.month == 12 and (d.day == 25 or d.day == 26) then return "🎄 Frohe Weihnachten! 🎁" end
			local y = d.year
			if d.month == 12 and d.day > 26 then y = y + 1 end
			local target = os.time({ year = y, month = 12, day = 25, hour = 0 })
			local days = math.max(1, math.ceil((target - now) / 86400))
			return "🎅 Noch " .. days .. (days == 1 and " Tag" or " Tage") .. " bis Weihnachten"
		end
		local cd = new("TextLabel", {
			Name = "FX_Countdown", Size = UDim2.new(0.5, 0, 0, 20), AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -14), BackgroundTransparency = 1, Text = xmasText(),
			TextColor3 = ICE, TextSize = 13, Font = Enum.Font.GothamBold, TextStrokeTransparency = 0.5, TextStrokeColor3 = Color3.fromRGB(6, 10, 22), Active = false, ZIndex = 7,
		}, mf)
		new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, ICE), ColorSequenceKeypoint.new(0.5, WHITE), ColorSequenceKeypoint.new(1, ICE),
			}),
		}, cd)
		task.spawn(function()
			while gui.Parent do
				task.wait(30)
				if cd.Parent then cd.Text = xmasText() end
			end
		end)
	end)

	----------------------------------------------------------------------------
	-- BUTTONS & TEXTBOXEN: Hover, Klick-Welle, Fokus-Glow
	----------------------------------------------------------------------------
	local function decorateButton(btn)
		if btn:GetAttribute("FX_Btn") then return end
		if string.find(btn.Name, "^FX_") then return end
		if btn.Text == "" or string.find(btn.Name, "Bar") or string.find(btn.Name, "Knob") then return end
		btn:SetAttribute("FX_Btn", true)

		local stroke = btn:FindFirstChildOfClass("UIStroke")
		local corner = btn:FindFirstChildOfClass("UICorner")
		local scale = new("UIScale", { Name = "FX_BtnScale", Scale = 1 }, btn)
		local clip = new("Frame", {
			Name = "FX_RippleClip", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
			BorderSizePixel = 0, ClipsDescendants = true, Active = false, ZIndex = btn.ZIndex + 1,
		}, btn)
		if corner then
			new("UICorner", { CornerRadius = corner.CornerRadius }, clip)
		end
		local baseThick = stroke and stroke.Thickness or 0

		btn.MouseEnter:Connect(function()
			tw(scale, 0.12, { Scale = 1.04 })
			if stroke then tw(stroke, 0.15, { Thickness = baseThick + 1 }) end
		end)
		btn.MouseLeave:Connect(function()
			tw(scale, 0.15, { Scale = 1 })
			if stroke then tw(stroke, 0.2, { Thickness = baseThick }) end
		end)
		btn.MouseButton1Down:Connect(function() tw(scale, 0.07, { Scale = 0.96 }) end)
		btn.MouseButton1Up:Connect(function() tw(scale, 0.12, { Scale = 1.04 }) end)
		btn.MouseButton1Click:Connect(function()
			safe(function()
				local m = UserInputService:GetMouseLocation()
				local rel = m - clip.AbsolutePosition
				local maxD = math.max(clip.AbsoluteSize.X, clip.AbsoluteSize.Y) * 2.2
				local r = new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, rel.X, 0, rel.Y),
					Size = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 0.8, BorderSizePixel = 0, Active = false, ZIndex = btn.ZIndex + 2,
				}, clip)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, r)
				tw(r, 0.55, { Size = UDim2.new(0, maxD, 0, maxD), BackgroundTransparency = 1 })
				task.delay(0.6, function() r:Destroy() end)
				for k = 1, 5 do
					sparkle(m.X, m.Y, PARTY[rng:NextInteger(1, #PARTY)], 36, 0.6, rng:NextInteger(10, 15), k == 1)
				end
			end)
		end)
	end

	local function decorateBox(box)
		if box:GetAttribute("FX_Box") then return end
		box:SetAttribute("FX_Box", true)
		local stroke = box:FindFirstChildOfClass("UIStroke")
		if not stroke then return end
		local oc, ot
		box.Focused:Connect(function()
			oc, ot = stroke.Color, stroke.Thickness
			tw(stroke, 0.2, { Color = GOLD, Thickness = ot + 1 })
		end)
		box.FocusLost:Connect(function()
			if oc then tw(stroke, 0.25, { Color = oc, Thickness = ot }) end
		end)
	end

	local function decorateAny(d)
		if string.find(d.Name, "^FX_") then return end
		if d:IsA("TextButton") or d:IsA("TextLabel") or d:IsA("TextBox") then
			-- Dezente dunkle Kontur: Schrift bleibt auf jedem Hintergrund gut lesbar
			d.TextStrokeColor3 = Color3.fromRGB(6, 10, 22)
			d.TextStrokeTransparency = 0.55
		end
		if d:IsA("TextButton") then
			safe(decorateButton, d)
		elseif d:IsA("TextBox") then
			safe(decorateBox, d)
		end
	end

	for _, d in ipairs(gui:GetDescendants()) do decorateAny(d) end
	gui.DescendantAdded:Connect(function(d)
		if d:IsA("TextButton") or d:IsA("TextBox") or d:IsA("TextLabel") then
			task.defer(function()
				if d.Parent then decorateAny(d) end
			end)
		end
	end)

	----------------------------------------------------------------------------
	-- KEY-FENSTER: Shake bei falschem Code, Konfetti bei Erfolg
	----------------------------------------------------------------------------
	local function shake(frame)
		task.spawn(function()
			local base = frame.Position
			for _, dx in ipairs({ 10, -10, 7, -7, 3, 0 }) do
				tw(frame, 0.045, { Position = UDim2.new(base.X.Scale, base.X.Offset + dx, base.Y.Scale, base.Y.Offset) })
				task.wait(0.05)
			end
			if frame.Parent then frame.Position = base end
		end)
	end

	safe(function()
		if __UI.keyFrame then
			new("TextLabel", {
				Name = "FX_KeyFooter", Size = UDim2.new(1, -20, 0, 18), AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -10), BackgroundTransparency = 1,
				Text = "🎁 Frohe Weihnachten & einen guten Rutsch ❄", TextColor3 = ICE, TextSize = 11,
				Font = Enum.Font.GothamMedium, TextStrokeTransparency = 0.5,
				TextStrokeColor3 = Color3.fromRGB(6, 10, 22), Active = false, ZIndex = 102,
			}, __UI.keyFrame)
		end
	end)

	safe(function()
		__UI.keyErrorLabel:GetPropertyChangedSignal("Text"):Connect(function()
			if __UI.keyErrorLabel.Text ~= "" and __UI.keyFrame and __UI.keyFrame.Parent then
				shake(__UI.keyFrame)
			end
		end)
		__UI.keyFrame.Destroying:Connect(function()
			if configData.keyUnlocked then
				local sz = gui.AbsoluteSize
				burst(sz.X / 2, sz.Y / 2, 45, 240)
				toast("🎄 Key akzeptiert – Frohe Weihnachten!", GREEN)
			end
		end)
	end)

	----------------------------------------------------------------------------
	-- FX-SCHALTER (unten links): Partikel/Schnee an/aus
	----------------------------------------------------------------------------
	safe(function()
		local tg = new("TextButton", {
			Name = "FX_Toggle", Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 14, 1, -52),
			BackgroundColor3 = NAVY, Text = "❄", TextSize = 20, Font = Enum.Font.GothamBold,
			TextColor3 = fxOn() and ICE or Color3.fromRGB(100, 116, 139), AutoButtonColor = false, ZIndex = 850,
		}, gui)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, tg)
		local st = new("UIStroke", { Thickness = 2, Color = Color3.new(1, 1, 1) }, tg)
		local sg = new("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, ICE), ColorSequenceKeypoint.new(0.5, WHITE), ColorSequenceKeypoint.new(1, ICE),
			}),
		}, st)
		table.insert(spinners, { g = sg, speed = 90, off = 0 })
		local sc = new("UIScale", { Scale = 1 }, tg)
		tg.MouseEnter:Connect(function() tw(sc, 0.12, { Scale = 1.12 }) end)
		tg.MouseLeave:Connect(function() tw(sc, 0.15, { Scale = 1 }) end)
		tg.MouseButton1Click:Connect(function()
			configData.fxEnabled = not fxOn()
			saveConfig()
			tg.TextColor3 = fxOn() and ICE or Color3.fromRGB(100, 116, 139)
			toast(fxOn() and "❄️ Schnee & Partikel: AN" or "Schnee & Partikel: AUS", fxOn() and ICE or GOLD)
		end)
	end)

	----------------------------------------------------------------------------
	-- ZENTRALE ANIMATIONS-SCHLEIFE
	----------------------------------------------------------------------------
	local lastTrail, lastMouse = 0, Vector2.new(-100, -100)
	local TRAIL = { ICE, WHITE, GOLD }
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not gui.Parent then
			conn:Disconnect()
			return
		end
		dt = math.min(dt, 0.1)
		local t = os.clock()
		local on = fxOn()

		safe(function()
			for _, s in ipairs(spinners) do s.g.Rotation = (t * s.speed + s.off) % 360 end
			for _, a in ipairs(auroras) do
				a.g.Rotation = (t * 8 + a.ph * 20) % 360
				a.g.Offset = Vector2.new(math.sin(t * 0.4 + a.ph) * 0.3, 0)
			end
			for _, sh in ipairs(shimmers) do
				sh.g.Offset = Vector2.new(((t * sh.spd) % 2) - 1, 0)
			end
			for _, b in ipairs(bulbs) do
				if b.always or b.panel.Visible then
					b.o.BackgroundTransparency = 0.05 + 0.55 * (0.5 + 0.5 * math.sin(t * 3 + b.ph))
				end
			end
			for _, fn in ipairs(extras) do fn(t) end
		end)

		safe(function()
			for _, s in ipairs(snows) do
				local show = on and (s.panel == nil or (s.panel.Parent ~= nil and s.panel.Visible))
				if s.shown ~= show then
					s.shown = show
					s.layer.Visible = show
				end
				if show then
					for _, f in ipairs(s.flakes) do
						f.y += f.vy * dt
						if f.y > 1.05 then
							f.y = -0.06
							f.x = rng:NextNumber()
						end
						f.o.Position = UDim2.new(f.x + math.sin(t * f.fq + f.ph) * f.sway, 0, f.y, 0)
					end
				end
			end
		end)

		-- Funkelspur am Mauszeiger (nur über sichtbaren Fenstern)
		if on and t - lastTrail > 0.045 then
			safe(function()
				local m = UserInputService:GetMouseLocation()
				if (m - lastMouse).Magnitude > 5 then
					lastMouse = m
					for _, p in ipairs(panels) do
						if p.Parent and p.Visible then
							local a, sz = p.AbsolutePosition, p.AbsoluteSize
							if m.X >= a.X and m.X <= a.X + sz.X and m.Y >= a.Y and m.Y <= a.Y + sz.Y then
								lastTrail = t
								sparkle(m.X, m.Y, TRAIL[rng:NextInteger(1, #TRAIL)], 22, 0.55, rng:NextInteger(9, 14))
								break
							end
						end
					end
				end
			end)
		end
	end)

	task.delay(0.8, function()
		toast("❄️ Winter-FX geladen – Frohe Weihnachten! 🎄", ICE)
	end)
end)
if not fxOk then warn("[SOLANASZ FX] " .. tostring(fxErr)) end
end)
