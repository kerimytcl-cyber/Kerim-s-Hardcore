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
    ShockerTimer = 30,
    DreadTimer = 185,

    A90Damage = 70,
    ShockerDamage = 40,
    CeaseDamage = 100,
    CeaseDistance = 66,

    A90Delay = 125,
    DreadDelay = 185,
    DreadTimer = 185,
}

local SPawnerURL = "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors%20Entity%20Spawner/Source.lua"

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
    doorCount = 0,
    lastDoorNumber = 0,
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
        Dread = CONFIG.DreadDelay,
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

    active = {},
    resetTokens = {},
    reboundResetDoor = nil,
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

local function findSprintButton()
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        return nil
    end

    local mainUI = playerGui:FindFirstChild("MainUI")
    if not mainUI then
        return nil
    end

    local mobileButtons = mainUI:FindFirstChild("MobileButtons", true)
    if not mobileButtons then
        return nil
    end

    return mobileButtons:FindFirstChild("SprintButton", true)
end

local function setupMobileSprint()
    local button = findSprintButton()
    if not button or not button:IsA("GuiButton") then
        return
    end

    if button:GetAttribute("HardcoreSprintConnected") then
        return
    end

    button:SetAttribute("HardcoreSprintConnected", true)

    button.MouseButton1Down:Connect(function()
        setSprint(not state.sprinting)
    end)
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

    setupMobileSprint()
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

local function darkenRoom(room)
    if not room or not room:IsA("Instance") then
        return
    end

    local number = tonumber(room.Name)
    if not number or number < 53 or number == 100 then
        return
    end

    if room:GetAttribute("HardcoreDarkened") then
        return
    end

    room:SetAttribute("HardcoreDarkened", true)

    for _, object in ipairs(room:GetDescendants()) do
        if object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
            object.Enabled = false
        end
    end
end

local function updateRoomSystems()
    local currentRooms = findCurrentRooms()
    if not currentRooms then
        return
    end

    local latest = getLatestRoom()

    for _, room in ipairs(currentRooms:GetChildren()) do
        preparePathfindNodes(room)

        local number = tonumber(room.Name)
        if number then
            if number >= 53 and number ~= 100 and latest >= 52 then
                darkenRoom(room)
            end
        end
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

local function setupWorldHooks()
    updateRoomSystems()

    local currentRooms = findCurrentRooms()
    if currentRooms then
        currentRooms.ChildAdded:Connect(function(room)
            task.wait()
            preparePathfindNodes(room)
            setupChandelier(room)
            if getLatestRoom() >= 52 then
                darkenRoom(room)
            end
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

local function isSeekActive()
    return workspace:FindFirstChild("SeekMoving", true) ~= nil
        or workspace:FindFirstChild("SeekMovingNewClone", true) ~= nil
end

local function getGameCurrentRoom()
    local gameData = ReplicatedStorage:FindFirstChild("GameData")
    local latest = gameData and gameData:FindFirstChild("LatestRoom")
    if latest and latest:IsA("ValueBase") then
        return tonumber(latest.Value) or 0
    end
    return state.latestRoom or 0
end

local function normalSpawnBlocked()
    local room = getGameCurrentRoom()
    return room == 50 or room == 100 or isSeekActive()
end

local function a60SpawnBlocked()
    local room = getGameCurrentRoom()
    if isSeekActive() then
        return true
    end
    return room == 100
end

local function findEntityModels(name)
    local aliases = {
        Ripper = {"Ripper", "RipperMoving"},
        Rebound = {"Rebound", "ReboundMoving"},
        Silence = {"Silence", "SilenceMoving"},
        Cease = {"Cease", "CeaseMoving"},
        Shocker = {"Shocker", "ShockerMoving"},
        DeerGod = {"DeerGod", "Deer God", "DeerGodMoving"},
        Frostbite = {"Frostbite", "FrostbiteMoving"},
        A60 = {"A-60", "A60", "A-60Moving", "A60Moving"},
        A90 = {"A-90", "A90", "A-90Moving", "A90Moving"},
        A200 = {"A-200", "A200", "A-200Moving", "A200Moving"},
        Dread = {"Dread", "DreadMoving"},
    }

    local wanted = aliases[name] or {name}
    local result = {}

    for _, object in ipairs(workspace:GetDescendants()) do
        for _, alias in ipairs(wanted) do
            if object.Name == alias and (object:IsA("Model") or object:IsA("BasePart")) then
                result[#result + 1] = object
                break
            end
        end
    end

    return result
end

local function entityIsActive(name)
    local models = findEntityModels(name)
    return #models > 0
end

local function fullyStopRebound()
    state.active.Rebound = false
    state.spawned.Rebound = false

    for _, object in ipairs(findEntityModels("Rebound")) do
        pcall(function()
            object:SetAttribute("Running", false)
            object:SetAttribute("Paused", true)
            object:SetAttribute("Despawning", true)
            object:Destroy()
        end)
    end

    task.spawn(function()
        local stopUntil = os.clock() + 8
        while os.clock() < stopUntil do
            for _, object in ipairs(findEntityModels("Rebound")) do
                pcall(function()
                    object:SetAttribute("Running", false)
                    object:SetAttribute("Paused", true)
                    object:SetAttribute("Despawning", true)
                    object:Destroy()
                end)
            end
            task.wait(0.05)
        end
    end)
end

local LOCATION_SOUND_NAMES = {
    [49] = "LA_The Library",
    [52] = "LA_The Dark Depths",
    [89] = "LA_The CourtYard",
    [90] = "LA_The Lonely Garden",
    [99] = "LA_The Abandoned Power Station",
}

local LOCATION_SOUND_IDS = {
    [49] = "rbxassetid://1835274270",
    [89] = "rbxassetid://7132953277",
    [90] = "rbxassetid://1847269119",
    [99] = "rbxassetid://1837449237",
}

local function playLocationSound(roomNumber)
    local sounds = ReplicatedStorage:FindFirstChild("Sounds")
    local wantedName = LOCATION_SOUND_NAMES[roomNumber]

    if sounds and wantedName then
        local existing = sounds:FindFirstChild(wantedName, true)
        if existing and existing:IsA("Sound") then
            local clone = existing:Clone()
            clone.Name = "HardcoreLocationSound"
            clone.Parent = game:GetService("SoundService")
            clone:Play()
            task.delay(math.max(10, clone.TimeLength + 1), function()
                if clone.Parent then
                    clone:Destroy()
                end
            end)
            return true
        end
    end

    local soundId = LOCATION_SOUND_IDS[roomNumber]
    if soundId then
        local sound = Instance.new("Sound")
        sound.Name = "HardcoreLocationSound"
        sound.SoundId = soundId
        sound.Volume = 1
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        task.delay(10, function()
            if sound.Parent then
                sound:Destroy()
            end
        end)
        return true
    end

    return false
end

local function showFallbackLocationTitle(text, imageId, soundId, duration)
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        return
    end

    local old = playerGui:FindFirstChild("HardcoreLocationTitle")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "HardcoreLocationTitle"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 10000
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local image = Instance.new("ImageLabel")
    image.Name = "Location"
    image.BackgroundTransparency = 1
    image.AnchorPoint = Vector2.new(0.5, 0)
    image.Position = UDim2.new(0.5, 0, 0.075, 0)
    image.Size = UDim2.new(0, 500, 0, 100)
    image.Image = imageId or ""
    image.ImageTransparency = 1
    image.ScaleType = Enum.ScaleType.Fit
    image.Parent = gui

    local label = Instance.new("TextLabel")
    label.Name = "Text"
    label.BackgroundTransparency = 1
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.Position = UDim2.new(0.5, 0, 0.075, 0)
    label.Size = UDim2.new(0.9, 0, 0, 70)
    label.Font = Enum.Font.GothamMedium
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.TextTransparency = 1
    label.Parent = gui

    TweenService:Create(image, TweenInfo.new(0.5), {ImageTransparency = imageId and 0 or 1}):Play()
    TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = imageId and 1 or 0}):Play()

    if soundId then
        playLocationSound(soundId, "HardcoreLocationSound")
    end

    task.delay(duration or 4, function()
        if not gui.Parent then
            return
        end
        TweenService:Create(image, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
        TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        task.wait(0.55)
        gui:Destroy()
    end)
end

local LOCATION_EVENTS = {
    [49] = {text = "The Library"},
    [52] = {text = "The Dark Depths"},
    [89] = {text = "The Courtyard"},
    [90] = {text = "The Lonely Gardens"},
    [99] = {text = "The Abandoned Power Station", textOnly = true},
}

local function showLocationTitle(roomNumber)
    local data = LOCATION_EVENTS[roomNumber]
    if not data then
        return
    end

    local mainUI = Player:FindFirstChildOfClass("PlayerGui")
    mainUI = mainUI and mainUI:FindFirstChild("MainUI")
    local mainGame = mainUI and mainUI:FindFirstChild("Initiator")
    mainGame = mainGame and mainGame:FindFirstChild("Main_Game")

    if mainGame then
        local ok, module = pcall(require, mainGame)
        if ok and module and type(module.titlelocation) == "function" then
            local success = pcall(function()
                module.titlelocation(data.text, true)
            end)
            if success then
                playLocationSound(roomNumber)
                return
            end
        end
    end

    playLocationSound(roomNumber)
    showFallbackLocationTitle(data.text, nil, nil, data.textOnly and 5 or 4)
end

local function resetTimer(name)
    state.timers[name] = CONFIG[name .. "Timer"]
    state.resetTokens[name] = (state.resetTokens[name] or 0) + 1
end

local function entityResetDelay(name)
    if name == "Rebound" then
        return nil
    elseif name == "A200" then
        return 60
    end
    return 30
end

local function entityCanSpawn(name)
    if name == "A60" then
        return not a60SpawnBlocked()
    end
    if name == "Shocker" then
        return true
    end
    return not normalSpawnBlocked()
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
    A60 = {
        CustomName = "A-60",
        Model = 11711600587,
        Speed = 200,
        DelayTime = 6,
        HeightOffset = 0,
        CanKill = true,
        BreakLights = true,
        FlickerLights = {true, 2},
        Cycles = {Min = 0, Max = 10, WaitTime = 2},
        CamShake = {true, {20, 40, 0.9, 30}, 1},
        Jumpscare = {false, {}},
    },
    A90 = {
        CustomName = "A-90",
        Model = 11493589668,
        Speed = 301,
        DelayTime = 3,
        HeightOffset = 0,
        CanKill = true,
        BreakLights = true,
        FlickerLights = {true, 2},
        Cycles = {Min = 0, Max = 12, WaitTime = 1},
        CamShake = {true, {20, 70, 0.9, 90}, 1},
        Jumpscare = {false, {}},
    },
    A200 = {
        CustomName = "A-200",
        Model = 11436355542,
        Speed = 600,
        DelayTime = 6,
        HeightOffset = 0,
        CanKill = true,
        BreakLights = true,
        FlickerLights = {true, 5},
        Cycles = {Min = 2, Max = 16, WaitTime = 0},
        CamShake = {true, {5, 15, 0.1, 1}, 1},
        Jumpscare = {false, {}},
    },
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
    if state.active[name] or entityIsActive(name) then
        return false
    end

    local url = OPEN_SOURCE_ENTITY_SCRIPTS[name]
    if not url then
        warn("Hardcore Mode: no open-source spawner URL configured for " .. tostring(name))
        return false
    end

    state.active[name] = true
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
            state.active[name] = false
            state.spawned[name] = false
            if not runGenericOpenSourceConfig(name) then
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

local function waitForEntitySpawn(name, timeout)
    local finish = os.clock() + (timeout or 15)
    while os.clock() < finish and not state.dead do
        if entityIsActive(name) then
            return true
        end
        task.wait(0.05)
    end
    return entityIsActive(name)
end

local function startEntityTimer(name, callback, canSpawnOverride)
    task.spawn(function()
        while not state.dead do
            task.wait(0.1)
            state.timers[name] = math.max(0, (state.timers[name] or CONFIG[name .. "Timer"] or 30) - 0.1)

            if state.timers[name] <= 0 then
                local allowed = canSpawnOverride and canSpawnOverride() or entityCanSpawn(name)

                if allowed then
                    local didSpawn = callback()

                    if didSpawn then
                        waitForEntitySpawn(name, 15)

                        local delayTime = entityResetDelay(name)
                        if name == "Rebound" then
                            state.reboundResetDoor = state.doorCount + 3
                        elseif delayTime then
                            task.delay(delayTime, function()
                                if not state.dead then
                                    resetTimer(name)
                                    state.active[name] = false
                                    state.spawned[name] = false
                                end
                            end)
                        end
                    else
                        resetTimer(name)
                    end
                else
                    resetTimer(name)
                end
            end
        end
    end)
end

local function startMainTimers()
    if state.startedMainTimers then
        return
    end

    state.startedMainTimers = true

    startEntityTimer("Ripper", spawnRipper)
    startEntityTimer("Cease", spawnCease)
    startEntityTimer("Rebound", spawnRebound)
    startEntityTimer("DeerGod", spawnDeerGod)
    startEntityTimer("Frostbite", spawnFrostbite)
end

local function startSilenceTimer()
    if state.startedSilenceTimer then
        return
    end

    state.startedSilenceTimer = true
    startEntityTimer("Silence", spawnSilence)
end

local function startA60MainTimer()
    if state.startedA60Timer then
        return
    end

    state.startedA60Timer = true
    startEntityTimer("A60", spawnA60)
end

local function startA90Timer()
    if state.a90Started then
        return
    end

    state.a90Started = true
    startEntityTimer("A90", spawnA90)
end

local function startA200Timer()
    if state.a200Started then
        return
    end

    state.a200Started = true
    startEntityTimer("A200", spawnA200)
end

local function startShockerTimer()
    if state.shockerStarted then
        return
    end

    state.shockerStarted = true
    state.timers.Shocker = CONFIG.ShockerTimer

    task.spawn(function()
        while not state.dead do
            task.wait(0.1)
            state.timers.Shocker = math.max(0, state.timers.Shocker - 0.1)
            if state.timers.Shocker <= 0 then
                if spawnShocker() then
                    waitForEntitySpawn("Shocker", 15)
                    task.delay(30, function()
                        if not state.dead then
                            state.timers.Shocker = CONFIG.ShockerTimer
                            state.active.Shocker = false
                            state.spawned.Shocker = false
                        end
                    end)
                else
                    state.timers.Shocker = CONFIG.ShockerTimer
                end
            end
        end
    end)
end

local function startDreadTimer()
    if state.dreadStarted then
        return
    end

    state.dreadStarted = true
    startEntityTimer("Dread", spawnDread)
end

local function startA60ForceTimer()
    if state.a60ForceStarted then
        return
    end

    state.a60ForceStarted = true

    task.spawn(function()
        while not state.dead and not state.a60ForceFinished do
            task.wait(0.1)
            state.a60ForceRemaining = (state.a60ForceRemaining or CONFIG.A60ForceTimer) - 0.1

            if state.a60ForceRemaining <= 0 then
                if not a60SpawnBlocked() then
                    if spawnA60() then
                        waitForEntitySpawn("A60", 15)
                        state.a60ForceFinished = true
                    else
                        state.a60ForceRemaining = CONFIG.A60ForceTimer
                    end
                else
                    state.a60ForceRemaining = CONFIG.A60ForceTimer
                end
            end
        end
    end)
end

local function handleDoor(roomNumber)
    if roomNumber < state.lastDoorNumber then
        return
    end

    if roomNumber > state.lastDoorNumber then
        state.doorCount = state.doorCount + (roomNumber - state.lastDoorNumber)
        state.lastDoorNumber = roomNumber
    end

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
        startDreadTimer()
    end

    showLocationTitle(roomNumber)
    updateRoomSystems()

    if state.reboundResetDoor and state.doorCount >= state.reboundResetDoor then
        state.reboundResetDoor = nil
        state.active.Rebound = false
        state.spawned.Rebound = false
        resetTimer("Rebound")
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
        local names = {
            ["A90"] = "A90", ["A-90"] = "A90",
            ["A200"] = "A200", ["A-200"] = "A200",
            ["A-60"] = "A60", ["A60"] = "A60",
            ["Dread"] = "Dread", ["Shocker"] = "Shocker",
            ["Cease"] = "Cease", ["Ripper"] = "Ripper",
            ["Rebound"] = "Rebound", ["Silence"] = "Silence",
            ["DeerGod"] = "DeerGod", ["Deer God"] = "DeerGod",
            ["Frostbite"] = "Frostbite",
        }

        local entityName = names[object.Name]
        if entityName then
            state.active[entityName] = true
            state.spawned[entityName] = true
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

    setupMobileSprint()
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
setupDoorWatcher()
setupExistingEntities()
monitorDeath()

RunService.Heartbeat:Connect(function()
    if state.active.Rebound and (isSeekActive() or getGameCurrentRoom() == 50 or getGameCurrentRoom() == 100) then
        fullyStopRebound()
        state.reboundResetDoor = nil
        resetTimer("Rebound")
    end
end)

startShockerTimer()
handleDoor(getLatestRoom())
