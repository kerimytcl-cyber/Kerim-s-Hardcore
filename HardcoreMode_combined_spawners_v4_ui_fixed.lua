local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local CONFIG = {
    WalkSpeed = 16,
    SprintSpeed = 24,
    SprintDrain = 18,
    SprintRecover = 12,
    MaxStamina = 100,

    RipperTimer = 50,
    CeaseTimer = 80,
    SilenceTimer = 110,
    ReboundTimer = 300,
    DeerGodTimer = 200,
    FrostbiteTimer = 250,
    A60Timer = 400,
    A60ForceTimer = 30,
    A90Timer = 125,
    A200Timer = 500,

    A90Damage = 70,
    ShockerDamage = 40,
    CeaseDamage = 100,
    CeaseDistance = 66,

    A90Delay = 125,
    DreadDelay = 185,
}

local SPawnerURL = "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua"

local OPEN_SOURCE_ENTITY_SCRIPTS = {
    Ripper = "https://raw.githubusercontent.com/Anctarus7105/Entities-Spawns/main/RipperSpawner.lua",
    Rebound = "https://raw.githubusercontent.com/Anctarus7105/Entities-Spawns/main/ReboundHardcoreSpawner.lua",
    Silence = "https://raw.githubusercontent.com/Anctarus7105/Entities-Spawns/main/SilenceSpawner.lua",
    Cease = "https://raw.githubusercontent.com/Anctarus7105/Entities-Spawns/main/CeaseSpawner.lua",
    Shocker = "https://raw.githubusercontent.com/Anctarus7105/Entities-Spawns/main/ShockerHardcoreMode.lua",
    DeerGod = "https://raw.githubusercontent.com/Anctarus7105/Entities-Spawns/main/DeerGodV3.lua",
    Frostbite = "https://raw.githubusercontent.com/Anctarus7105/Entities-Spawns/main/FrostbiteBuFloor2HardcoreAndNoBackwardsMobement",
    A60 = "https://raw.githubusercontent.com/Anctarus7105/Entities-Spawns/main/A-60%20Hardcore.lua",
    A90 = "https://raw.githubusercontent.com/Anctarus7105/Entities-Spawns/main/A-90%20Spawn",
    A200 = "https://raw.githubusercontent.com/Anctarus7105/Entities-Spawns/main/A%20200%20Spawn",
    Dread = "https://raw.githubusercontent.com/Anctarus7105/Entities-Spawns/main/Dread%20Spawn",
}

local state = {
    stamina = CONFIG.MaxStamina,
    sprinting = false,
    dead = false,
    hiding = false,
    invincible = false,

    latestRoom = 0,
    startedMainTimers = false,
    startedSilenceTimer = false,
    startedA60Timer = false,
    a60ForceStarted = false,
    a60ForceFinished = false,
    a90Started = false,
    a200Started = false,

    timers = {
        Ripper = CONFIG.RipperTimer,
        Cease = CONFIG.CeaseTimer,
        Rebound = CONFIG.ReboundTimer,
        DeerGod = CONFIG.DeerGodTimer,
        Frostbite = CONFIG.FrostbiteTimer,
        Silence = CONFIG.SilenceTimer,
        A60 = CONFIG.A60Timer,
        A90 = CONFIG.A90Timer,
        A200 = CONFIG.A200Timer,
    },

    spawned = {
        Ripper = false,
        Cease = false,
        Rebound = false,
        DeerGod = false,
        Frostbite = false,
        Silence = false,
        A60 = false,
        A90 = false,
        A200 = false,
        Shocker = false,
        Dread = false,
    },

}

local Creator

local function refreshCharacter()
    Character = Player.Character or Player.CharacterAdded:Wait()
    return Character
end

local function humanoid()
    local character = refreshCharacter()
    return character:FindFirstChildOfClass("Humanoid")
end

local function root()
    local character = refreshCharacter()
    return character:FindFirstChild("HumanoidRootPart")
end

local function isInvincible()
    if state.invincible then
        return true
    end

    local character = refreshCharacter()

    local value = character:FindFirstChild("Invincibility")
    if value and value:IsA("BoolValue") and value.Value then
        return true
    end

    return character:GetAttribute("Invincibility") == true
end

local function isHiding()
    local character = refreshCharacter()

    if state.hiding then
        return true
    end

    if character:GetAttribute("Hiding") == true then
        return true
    end

    local hiding = character:FindFirstChild("Hiding")
    return hiding and hiding:IsA("BoolValue") and hiding.Value or false
end

local function damage(amount)
    if isInvincible() then
        return
    end

    local hum = humanoid()
    if hum and hum.Health > 0 then
        hum:TakeDamage(amount)
    end
end

local function playerMoving()
    local hum = humanoid()
    return hum and hum.MoveDirection.Magnitude > 0.05 or false
end

local function cameraShake(amount, roughness, fadeIn, fadeOut)
    local mainUI = Player:FindFirstChild("PlayerGui")
    if not mainUI then
        return
    end

    local initiator = mainUI:FindFirstChild("MainUI")
    if not initiator then
        return
    end

    local mainGame = initiator:FindFirstChild("Initiator")
    if not mainGame then
        return
    end

    local module = mainGame:FindFirstChild("Main_Game")
    if not module then
        return
    end

    local ok, gameModule = pcall(require, module)
    if not ok or not gameModule then
        return
    end

    if gameModule.camShaker and gameModule.camShaker.ShakeOnce then
        pcall(function()
            gameModule.camShaker:ShakeOnce(amount or 5, roughness or 15, fadeIn or 0.1, fadeOut or 1)
        end)
    end
end

local function setDeathCause(name)
    local gameStats = ReplicatedStorage:FindFirstChild("GameStats")
    if not gameStats then
        return
    end

    local playerStats = gameStats:FindFirstChild("Player_" .. Player.Name)
    if not playerStats then
        return
    end

    local total = playerStats:FindFirstChild("Total")
    local deathCause = total and total:FindFirstChild("DeathCause")

    if deathCause and deathCause:IsA("StringValue") then
        deathCause.Value = name
    end
end

local function showDeathHint(lines)
    local entityInfo = ReplicatedStorage:FindFirstChild("EntityInfo")
    local deathHint = entityInfo and entityInfo:FindFirstChild("DeathHint")

    if deathHint and deathHint:IsA("RemoteEvent") then
        pcall(function()
            deathHint:FireServer(lines)
        end)
    end
end

local function setSprint(enabled)
    local hum = humanoid()
    if not hum then
        return
    end

    state.sprinting = enabled and state.stamina > 0 and not state.dead

    if state.sprinting then
        hum.WalkSpeed = CONFIG.SprintSpeed
    else
        hum.WalkSpeed = CONFIG.WalkSpeed
    end
end

local sprintGui
local sprintBar
local sprintFill
local sprintButton

local function getPlayerGui()
    return Player:FindFirstChildOfClass("PlayerGui") or Player:WaitForChild("PlayerGui", 10)
end

local function ensureSprintUI()
    local playerGui = getPlayerGui()
    if not playerGui then
        return
    end

    sprintGui = playerGui:FindFirstChild("HardcoreSprintUI")
    if not sprintGui then
        sprintGui = Instance.new("ScreenGui")
        sprintGui.Name = "HardcoreSprintUI"
        sprintGui.ResetOnSpawn = false
        sprintGui.IgnoreGuiInset = true
        sprintGui.DisplayOrder = 100
        sprintGui.Parent = playerGui
    end

    sprintBar = sprintGui:FindFirstChild("StaminaBar")
    if not sprintBar then
        sprintBar = Instance.new("Frame")
        sprintBar.Name = "StaminaBar"
        sprintBar.AnchorPoint = Vector2.new(0.5, 1)
        sprintBar.Position = UDim2.new(0.5, 0, 1, -28)
        sprintBar.Size = UDim2.new(0, 230, 0, 14)
        sprintBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        sprintBar.BackgroundTransparency = 0.25
        sprintBar.BorderSizePixel = 0
        sprintBar.Parent = sprintGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 7)
        corner.Parent = sprintBar

        sprintFill = Instance.new("Frame")
        sprintFill.Name = "Fill"
        sprintFill.Size = UDim2.new(1, 0, 1, 0)
        sprintFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        sprintFill.BorderSizePixel = 0
        sprintFill.Parent = sprintBar

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 7)
        fillCorner.Parent = sprintFill

        local text = Instance.new("TextLabel")
        text.Name = "Label"
        text.BackgroundTransparency = 1
        text.Size = UDim2.new(1, 0, 1, 0)
        text.Text = "STAMINA"
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.Parent = sprintBar
    else
        sprintFill = sprintBar:FindFirstChild("Fill")
    end

    sprintButton = sprintGui:FindFirstChild("SprintButton")
    if not sprintButton then
        sprintButton = Instance.new("TextButton")
        sprintButton.Name = "SprintButton"
        sprintButton.AnchorPoint = Vector2.new(1, 1)
        sprintButton.Position = UDim2.new(1, -22, 1, -72)
        sprintButton.Size = UDim2.new(0, 86, 0, 86)
        sprintButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        sprintButton.BackgroundTransparency = 0.25
        sprintButton.BorderSizePixel = 0
        sprintButton.Text = "SPRINT"
        sprintButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        sprintButton.TextScaled = true
        sprintButton.Font = Enum.Font.GothamBold
        sprintButton.Visible = UserInputService.TouchEnabled
        sprintButton.Parent = sprintGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = sprintButton
    end

    if not sprintButton:GetAttribute("HardcoreSprintConnected") then
        sprintButton:SetAttribute("HardcoreSprintConnected", true)
        sprintButton.Activated:Connect(function()
            setSprint(not state.sprinting)
        end)
    end

    sprintButton.Visible = UserInputService.TouchEnabled
end

local function updateSprintUI()
    ensureSprintUI()

    if sprintFill then
        sprintFill.Size = UDim2.new(math.clamp(state.stamina / CONFIG.MaxStamina, 0, 1), 0, 1, 0)
    end

    if sprintButton then
        sprintButton.BackgroundTransparency = state.sprinting and 0.05 or 0.25
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        setSprint(true)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        setSprint(false)
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if state.dead then
        return
    end

    local hum = humanoid()
    if not hum then
        return
    end

    if state.sprinting and hum.MoveDirection.Magnitude > 0.05 then
        state.stamina = math.max(0, state.stamina - CONFIG.SprintDrain * dt)

        if state.stamina <= 0 then
            setSprint(false)
        end
    else
        state.stamina = math.min(CONFIG.MaxStamina, state.stamina + CONFIG.SprintRecover * dt)
    end

    updateSprintUI()
end)

local function findCurrentRooms()
    return workspace:FindFirstChild("CurrentRooms")
end

local function getLatestRoom()
    local gameData = ReplicatedStorage:FindFirstChild("GameData")
    local latest = gameData and gameData:FindFirstChild("LatestRoom")

    if latest and latest:IsA("ValueBase") then
        return tonumber(latest.Value) or 0
    end

    local currentRooms = findCurrentRooms()
    if currentRooms then
        local highest = 0

        for _, room in ipairs(currentRooms:GetChildren()) do
            local n = tonumber(room.Name)
            if n and n > highest then
                highest = n
            end
        end

        return highest
    end

    return 0
end

local function preparePathfindNodes(room)
    if not room or not room:IsA("Instance") then
        return
    end

    if room:FindFirstChild("PathfindNodes") then
        return
    end

    local floors = room:FindFirstChild("Floors")
    if not floors then
        return
    end

    local folder = Instance.new("Folder")
    folder.Name = "PathfindNodes"
    folder.Parent = room

    local parts = {}

    for _, object in ipairs(floors:GetDescendants()) do
        if object:IsA("BasePart") then
            parts[#parts + 1] = object
        end
    end

    table.sort(parts, function(a, b)
        return a.Position.Z < b.Position.Z
    end)

    local step = math.max(1, math.floor(#parts / 8))

    for index = 1, #parts, step do
        local source = parts[index]
        local node = Instance.new("Part")
        node.Name = tostring(#folder:GetChildren() + 1)
        node.Size = Vector3.new(1, 1, 1)
        node.Transparency = 1
        node.Anchored = true
        node.CanCollide = false
        node.CanTouch = false
        node.CanQuery = false
        node.CFrame = source.CFrame + Vector3.new(0, 2, 0)
        node.Parent = folder
    end
end

local function darkenRoom(room, number)
    if not room or not number or number < 52 then
        return
    end

    for _, object in ipairs(room:GetDescendants()) do
        if object:IsA("Light") then
            if object:GetAttribute("HardcoreOriginalBrightness") == nil then
                object:SetAttribute("HardcoreOriginalBrightness", object.Brightness)
            end

            local original = object:GetAttribute("HardcoreOriginalBrightness")
            if number >= 150 then
                object.Enabled = false
            else
                object.Enabled = true
                object.Brightness = math.max(0.05, original * 0.12)
            end
        end
    end
end

local function updateRoomSystems()
    local currentRooms = findCurrentRooms()
    if not currentRooms then
        return
    end

    for _, room in ipairs(currentRooms:GetChildren()) do
        preparePathfindNodes(room)
        darkenRoom(room, tonumber(room.Name))
    end
end

local function setupChandelier(room)
    if not room then
        return
    end

    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local chandelier = assets and assets:FindFirstChild("Chandelier")

    if not chandelier then
        return
    end

    local fixture = room:FindFirstChild("LightFixture", true)
    if not fixture or fixture:GetAttribute("HardcoreChandelier") then
        return
    end

    local clone = chandelier:Clone()
    clone:SetAttribute("HardcoreChandelier", true)
    clone.Parent = fixture

    pcall(function()
        clone:PivotTo(fixture:GetPivot())
    end)
end

local function setupPainting(object)
    if not object:IsA("Model") and not object:IsA("BasePart") then
        return
    end

    if not string.find(string.lower(object.Name), "paint") then
        return
    end

    local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt or prompt:GetAttribute("HardcorePainting") then
        return
    end

    prompt:SetAttribute("HardcorePainting", true)

    prompt.Triggered:Connect(function()
        object:SetAttribute("HardcoreInteracted", true)
    end)
end

local FLOOR_TITLES = {
    [49] = {Name = "The Library", Type = "Decal"},
    [52] = {Name = "The Dark Depths", Type = "Decal"},
    [89] = {Name = "The Courtyard", Type = "Decal"},
    [90] = {Name = "The Lonely Gardens", Type = "Decal"},
    [99] = {Name = "The Abandoned Power Station", Type = "Text"},
}

local shownFloorTitle
local floorTitleConnection

local function findNamedDescendant(rootInstance, names, className)
    if not rootInstance then
        return nil
    end

    local wanted = {}
    for _, name in ipairs(names) do
        wanted[string.lower(name)] = true
    end

    for _, object in ipairs(rootInstance:GetDescendants()) do
        if wanted[string.lower(object.Name)] and (not className or object:IsA(className)) then
            return object
        end
    end

    return nil
end

local HARDCORE_TITLE_ASSETS = {
    Library = nil,
    DarkDepths = nil,
    CourtYard = nil,
    LonelyGarden = nil,
}

local function getHardcoreTitleAsset(title)
    local key = title.Name:gsub("The ", ""):gsub("%s+", "")
    local playerGui = getPlayerGui()

    local roots = {
        playerGui,
        ReplicatedStorage,
    }

    local templateNames = {
        key .. "Title",
        key,
        title.Name,
        title.Name:gsub("%s+", ""),
    }

    for _, rootInstance in ipairs(roots) do
        if rootInstance then
            for _, name in ipairs(templateNames) do
                local object = rootInstance:FindFirstChild(name, true)
                if object then
                    if object:IsA("ImageLabel") or object:IsA("ImageButton") then
                        if object.Image and object.Image ~= "" and object.Image ~= "rbxassetid://0" then
                            return object.Image
                        end
                    elseif object:IsA("Decal") then
                        if object.Texture and object.Texture ~= "" then
                            return object.Texture
                        end
                    end
                end
            end
        end
    end

    return HARDCORE_TITLE_ASSETS[key]
end

local function getFloorTitleSound(title)
    local names = {
        title.Name,
        title.Name .. "Sound",
        title.Name:gsub("The ", "") .. "Sound",
        title.Name:gsub(" ", "") .. "Sound",
        "Floor" .. title.Name .. "Sound",
    }

    local sound = findNamedDescendant(ReplicatedStorage, names, "Sound")
    if sound then
        return sound.SoundId
    end

    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    sound = findNamedDescendant(playerGui, names, "Sound")
    if sound then
        return sound.SoundId
    end

    return nil
end

local function destroyFloorTitle()
    if shownFloorTitle then
        shownFloorTitle:Destroy()
        shownFloorTitle = nil
    end
end

local function showFloorTitle(roomNumber)
    local title = FLOOR_TITLES[roomNumber]
    if not title then
        return
    end

    destroyFloorTitle()

    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "HardcoreFloorTitle"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 50
    gui.Parent = playerGui
    shownFloorTitle = gui

    local frame = Instance.new("Frame")
    frame.Name = "TitleFrame"
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 130)
    frame.Position = UDim2.new(0, 0, 0, 35)
    frame.Parent = gui

    if title.Type == "Text" then
        local label = Instance.new("TextLabel")
        label.Name = "TheAbandonedPowerStation"
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, -40, 0, 80)
        label.Position = UDim2.new(0, 20, 0, 10)
        label.Font = Enum.Font.GothamMedium
        label.Text = title.Name
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextScaled = true
        label.TextStrokeTransparency = 0.35
        label.Parent = frame
    else
        local imageId = getHardcoreTitleAsset(title)
        if not imageId or imageId == "" then
            gui:Destroy()
            shownFloorTitle = nil
            warn("HardcoreMode: Could not find the decal asset for " .. title.Name)
            return
        end

        local image = Instance.new("ImageLabel")
        image.Name = title.Name:gsub("%s+", "")
        image.BackgroundTransparency = 1
        image.Image = imageId
        image.ScaleType = Enum.ScaleType.Fit
        image.Size = UDim2.new(0.7, 0, 0, 90)
        image.AnchorPoint = Vector2.new(0.5, 0)
        image.Position = UDim2.new(0.5, 0, 0, 5)
        image.Parent = frame
    end

    local soundId = getFloorTitleSound(title)
    if soundId and soundId ~= "" then
        local sound = Instance.new("Sound")
        sound.Name = "FloorTitleSound"
        sound.SoundId = soundId
        sound.Volume = 1
        sound.Parent = gui
        sound:Play()
        sound.Ended:Connect(function()
            if sound.Parent then
                sound:Destroy()
            end
        end)
    end

    task.delay(5, function()
        if shownFloorTitle == gui then
            shownFloorTitle = nil
            gui:Destroy()
        end
    end)
end

local function setupFloorTitles()
    local gameData = ReplicatedStorage:FindFirstChild("GameData")
    local latestRoom = gameData and gameData:FindFirstChild("LatestRoom")
    if not latestRoom or not latestRoom:IsA("ValueBase") then
        return
    end

    if floorTitleConnection then
        floorTitleConnection:Disconnect()
    end

    floorTitleConnection = latestRoom.Changed:Connect(function(value)
        local roomNumber = tonumber(value)
        if roomNumber and FLOOR_TITLES[roomNumber] then
            showFloorTitle(roomNumber)
        end
    end)
end

local function setupWorldHooks()
    updateRoomSystems()

    local currentRooms = findCurrentRooms()
    if currentRooms then
        currentRooms.ChildAdded:Connect(function(room)
            task.wait()
            preparePathfindNodes(room)
            setupChandelier(room)
            darkenRoom(room, tonumber(room.Name))
            updateRoomSystems()
        end)

        for _, room in ipairs(currentRooms:GetChildren()) do
            setupChandelier(room)
        end
    end

    workspace.DescendantAdded:Connect(function(object)
        setupPainting(object)

        if object.Name == "PathfindNodes" then
            return
        end

        if object:IsDescendantOf(workspace) then
            task.defer(updateRoomSystems)
        end
    end)
end

local function loadCreator()
    if Creator then
        return Creator
    end

    local source = game:HttpGet(SPawnerURL)
    Creator = loadstring(source)()
    return Creator
end

local function createEntity(config)
    local creator = loadCreator()
    return creator.createEntity(config)
end

local function runEntity(entity)
    if not entity then
        return
    end

    local creator = loadCreator()
    creator.runEntity(entity)
end

local GENERIC_OPEN_SOURCE_CONFIGS = {
    Ripper = {CustomName = "Ripper", Model = 12234498940, Speed = 100, DelayTime = 4, HeightOffset = 0, CanKill = true, BreakLights = false, FlickerLights = {false, 1}, Cycles = {Min = 0, Max = 1, WaitTime = 0}, CamShake = {true, {2.5, 20, 0.5, 1}, 1}, Jumpscare = {false, {}}},
    Rebound = {CustomName = "Rebound", Model = 12254145022, Speed = 60, DelayTime = 4, HeightOffset = 0, CanKill = true, BreakLights = false, FlickerLights = {false, 1}, Cycles = {Min = 3, Max = 3, WaitTime = 4}, CamShake = {true, {10, 20, 0.1, 1}, 1}, Jumpscare = {false, {}}},
    Silence = {CustomName = "Silence", Model = 11535812658, Speed = 50, DelayTime = 2, HeightOffset = 0, CanKill = true, BreakLights = true, FlickerLights = {false, 1}, Cycles = {Min = 0, Max = 1, WaitTime = 0}, CamShake = {true, {2.5, 20, 0.5, 1}, 1}, Jumpscare = {false, {}}},
    Cease = {CustomName = "Cease", Model = 16950076354, Speed = 120, DelayTime = 5, HeightOffset = 0, CanKill = false, BreakLights = false, FlickerLights = {false, 1}, Cycles = {Min = 0, Max = 1, WaitTime = 0}, CamShake = {true, {5, 20, 0.1, 1}, 1}, Jumpscare = {false, {}}},
    DeerGod = {CustomName = "Deer God", Model = 11493589668, Speed = 25, DelayTime = 2, HeightOffset = 0, CanKill = true, BreakLights = true, FlickerLights = {false, 1}, Cycles = {Min = 0, Max = 1, WaitTime = 0}, CamShake = {true, {3.5, 20, 0.2, 1}, 1}, Jumpscare = {false, {}}},
    Frostbite = {CustomName = "FrostBite", Model = 16648442829, Speed = 91, DelayTime = 9, HeightOffset = 0, CanKill = true, BreakLights = true, FlickerLights = {true, 0}, Cycles = {Min = 1, Max = 1, WaitTime = 3}, CamShake = {true, {5, 15, 0.1, 1}, 1}, Jumpscare = {false, {}}},
    A60 = {CustomName = "A-60", Model = 11711600587, Speed = 200, DelayTime = 6, HeightOffset = 0, CanKill = true, BreakLights = true, FlickerLights = {true, 2}, Cycles = {Min = 0, Max = 10, WaitTime = 2}, CamShake = {true, {20, 40, 0.9, 30}, 1}, Jumpscare = {false, {}}},
    A90 = {CustomName = "A-90", Model = 11493589668, Speed = 301, DelayTime = 3, HeightOffset = 0, CanKill = true, BreakLights = true, FlickerLights = {true, 2}, Cycles = {Min = 0, Max = 12, WaitTime = 1}, CamShake = {true, {20, 70, 0.9, 90}, 1}, Jumpscare = {false, {}}},
    A200 = {CustomName = "A-200", Model = 15277953336, Speed = 333, DelayTime = 1, HeightOffset = 0, CanKill = true, BreakLights = false, FlickerLights = {false, 0}, Cycles = {Min = 5, Max = 25, WaitTime = 0}, CamShake = {true, {5, 15, 0.1, 1}, 1}, Jumpscare = {false, {}}},
    Dread = {CustomName = "Dread", Model = 15033250482, Speed = 0, DelayTime = 0, HeightOffset = 0, CanKill = true, BreakLights = true, FlickerLights = {true, 0}, Cycles = {Min = 0, Max = 1, WaitTime = 0}, CamShake = {true, {1.5, 20, 0.1, 1}, 1}, Jumpscare = {false, {}}},
}

local function runGenericOpenSourceConfig(name)
    local config = GENERIC_OPEN_SOURCE_CONFIGS[name]
    if not config then
        return false
    end

    local ok, err = pcall(function()
        local entity = createEntity(config)
        runEntity(entity)
    end)

    if not ok then
        warn("Hardcore Mode: generic open-source config for " .. name .. " failed: " .. tostring(err))
        return false
    end

    state.spawned[name] = true
    return true
end

local function runOpenSourceEntity(name)
    if state.spawned[name] then
        return true
    end

    local url = OPEN_SOURCE_ENTITY_SCRIPTS[name]
    if not url then
        warn("Hardcore Mode: no open-source spawner URL configured for " .. tostring(name))
        return false
    end

    state.spawned[name] = true

    task.spawn(function()
        local ok, err = pcall(function()
            local source = game:HttpGet(url)
            local fn = loadstring(source)
            if not fn then
                error("loadstring failed")
            end
            fn()
        end)

        if not ok then
            state.spawned[name] = false

            local aliases = {
                A60 = {"A60", "A-60", "A-60 Hardcore"},
                A90 = {"A90", "A-90"},
                A200 = {"A200", "A-200", "A 200"},
                DeerGod = {"DeerGod", "Deer God"},
                Frostbite = {"Frostbite", "FrostBite"},
                Ripper = {"Ripper"},
                Rebound = {"Rebound"},
                Silence = {"Silence"},
                Cease = {"Cease"},
                Dread = {"Dread"},
            }

            local alreadyExists = false
            for _, alias in ipairs(aliases[name] or {name}) do
                if workspace:FindFirstChild(alias, true) then
                    alreadyExists = true
                    break
                end
            end

            if not alreadyExists and not runGenericOpenSourceConfig(name) then
                warn("Hardcore Mode: failed to run open-source " .. name .. " spawner: " .. tostring(err))
            end
        end
    end)

    return true
end

local function spawnRipper()
    return runOpenSourceEntity("Ripper")
end

local function spawnRebound()
    return runOpenSourceEntity("Rebound")
end

local function spawnSilence()
    return runOpenSourceEntity("Silence")
end

local function spawnCease()
    return runOpenSourceEntity("Cease")
end

local function spawnShocker()
    return runOpenSourceEntity("Shocker")
end

local function spawnDeerGod()
    return runOpenSourceEntity("DeerGod")
end

local function spawnFrostbite()
    return runOpenSourceEntity("Frostbite")
end

local function spawnA60()
    return runOpenSourceEntity("A60")
end

local function spawnA90()
    return runOpenSourceEntity("A90")
end

local function spawnA200()
    return runOpenSourceEntity("A200")
end

local function spawnDread()
    return runOpenSourceEntity("Dread")
end

local function startTimer(name, callback)
    task.spawn(function()
        while state.timers[name] > 0 and not state.dead do
            task.wait(0.1)
            state.timers[name] = math.max(0, state.timers[name] - 0.1)
        end

        if state.dead then
            return
        end

        callback()
    end)
end

local function startMainTimers()
    if state.startedMainTimers then
        return
    end

    state.startedMainTimers = true

    startTimer("Ripper", spawnRipper)
    startTimer("Cease", spawnCease)
    startTimer("Rebound", spawnRebound)
    startTimer("DeerGod", spawnDeerGod)
    startTimer("Frostbite", spawnFrostbite)
end

local function startSilenceTimer()
    if state.startedSilenceTimer then
        return
    end

    state.startedSilenceTimer = true
    startTimer("Silence", spawnSilence)
end

local function startA60MainTimer()
    if state.startedA60Timer then
        return
    end

    state.startedA60Timer = true
    startTimer("A60", function()
        if not state.spawned.A60 then
            spawnA60()
        end
    end)
end

local function startA90Timer()
    if state.a90Started then
        return
    end

    state.a90Started = true
    startTimer("A90", spawnA90)
end

local function startA200Timer()
    if state.a200Started then
        return
    end

    state.a200Started = true
    startTimer("A200", spawnA200)
end

local function startA60ForceTimer()
    if state.a60ForceStarted then
        return
    end

    state.a60ForceStarted = true

    task.spawn(function()
        task.wait(CONFIG.A60ForceTimer)

        if state.dead or state.a60ForceFinished then
            return
        end

        state.a60ForceFinished = true

        if not state.spawned.A60 then
            state.spawned.A60 = false
            runOpenSourceEntity("A60")
        end
    end)
end

local function handleDoor(roomNumber)
    state.latestRoom = roomNumber

    if roomNumber >= 5 then
        startMainTimers()
    end

    if roomNumber >= 50 then
        startA60ForceTimer()
    end

    if roomNumber >= 52 then
        startSilenceTimer()
        startA60MainTimer()
        startA90Timer()
        startA200Timer()
    end
end

local function setupDoorWatcher()
    local gameData = ReplicatedStorage:FindFirstChild("GameData")
    local latestRoom = gameData and gameData:FindFirstChild("LatestRoom")

    if latestRoom and latestRoom:IsA("ValueBase") then
        latestRoom.Changed:Connect(function(value)
            local roomNumber = tonumber(value)
            if roomNumber then
                handleDoor(roomNumber)
            end
        end)

        handleDoor(tonumber(latestRoom.Value) or 0)
        return
    end

    task.spawn(function()
        local last = getLatestRoom()

        while task.wait(0.25) do
            local now = getLatestRoom()

            if now > last then
                last = now
                handleDoor(now)
            end
        end
    end)
end

local function setupExistingEntities()
    workspace.DescendantAdded:Connect(function(object)
        if object.Name == "A90" or object.Name == "A-90" then
            state.spawned.A90 = true
        elseif object.Name == "A200" or object.Name == "A-200" then
            state.spawned.A200 = true
        elseif object.Name == "Dread" then
            state.spawned.Dread = true
        elseif object.Name == "Shocker" then
            state.spawned.Shocker = true
        elseif object.Name == "Cease" then
            state.spawned.Cease = true
        elseif object.Name == "Ripper" then
            state.spawned.Ripper = true
        elseif object.Name == "Rebound" then
            state.spawned.Rebound = true
        elseif object.Name == "Silence" then
            state.spawned.Silence = true
        elseif object.Name == "DeerGod" or object.Name == "Deer God" then
            state.spawned.DeerGod = true
        elseif object.Name == "Frostbite" then
            state.spawned.Frostbite = true
        end
    end)
end

Player.CharacterAdded:Connect(function(character)
    Character = character
    state.dead = false
    state.sprinting = false
    state.stamina = CONFIG.MaxStamina

    task.wait(0.2)

    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = CONFIG.WalkSpeed
    end

    ensureSprintUI()
    updateSprintUI()
end)

local function monitorDeath()
    local hum = humanoid()

    if not hum then
        return
    end

    hum.Died:Connect(function()
        state.dead = true
        state.sprinting = false
    end)
end

getgenv().HardcoreModeSpawn = {
    Ripper = spawnRipper,
    Rebound = spawnRebound,
    Silence = spawnSilence,
    Cease = spawnCease,
    Shocker = spawnShocker,
    DeerGod = spawnDeerGod,
    Frostbite = spawnFrostbite,
    A60 = spawnA60,
    A90 = spawnA90,
    A200 = spawnA200,
    Dread = spawnDread,
}

setupWorldHooks()
ensureSprintUI()
updateSprintUI()
setupFloorTitles()
setupDoorWatcher()
setupExistingEntities()
monitorDeath()

handleDoor(getLatestRoom())
