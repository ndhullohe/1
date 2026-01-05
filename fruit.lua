-- [AUTOEXEC] Aguarda game carregar
repeat task.wait() until game:IsLoaded()

-- Aguarda LocalPlayer
repeat task.wait() until game.Players.LocalPlayer
local LocalPlayer = game.Players.LocalPlayer

-- Configurações (lê do executor)
local Team = getgenv().Team
local config = getgenv().MidgardConfig or {}

-- Extrai todas as configurações da tabela única
local TweenSpeed = config["TweenSpeed"] or 300
local ServerHopDelay = config["ServerHopDelay"] or 5
local FruitCollect = config["FruitCollect"]
local FruitCategories = config["FruitCategories"]  -- Categorias permitidas (nil = todas)
local FruitGacha = config["FruitGacha"]
local ChestCollect = config["ChestCollect"]
local ChestCount = config["ChestCount"] or 5
local FactoryRaid = config["FactoryRaid"]  -- Auto Factory Raid
local PirateRaid = config["PirateRaid"]  -- Auto Pirate Raid (Castle)

-- Arma selecionada (atualizada automaticamente)
local SelectWeapon = nil

-- Estados dinâmicos (uso interno do script)
local isTweening = false
local isCollectingChests = false
local isDoingRaid = false

-- Converte FruitCategories em set para lookup rápido
local allowedCategoriesSet = {}
if FruitCategories and type(FruitCategories) == "table" and #FruitCategories > 0 then
    for _, category in ipairs(FruitCategories) do
        allowedCategoriesSet[category] = true
    end
end

-- ═══════════════════════════════════════════════════════
-- CONSTANTES E TABELAS
-- ═══════════════════════════════════════════════════════

-- PlaceIds dos Seas
local SEA_1_PLACEID = 2753915549
local SEA_2_PLACEID = 4442272183
local SEA_3_PLACEID = 7449423635

-- Detecta Sea atual
local CurrentSea = 1
if game.PlaceId == SEA_2_PLACEID then
    CurrentSea = 2
elseif game.PlaceId == SEA_3_PLACEID then
    CurrentSea = 3
end

-- Prioridade de frutas (maior número = maior prioridade)
local fruitPriority = {
    ["Dragon Fruit"] = 42, ["Control Fruit"] = 41, ["Kitsune Fruit"] = 40,
    ["Yeti Fruit"] = 39, ["Tiger Fruit"] = 38, ["Spirit Fruit"] = 37,
    ["Gas Fruit"] = 36, ["Venom Fruit"] = 35, ["Shadow Fruit"] = 34,
    ["Dough Fruit"] = 33, ["T-Rex Fruit"] = 32, ["Mammoth Fruit"] = 31,
    ["Gravity Fruit"] = 30, ["Blizzard Fruit"] = 29, ["Pain Fruit"] = 28,
    ["Lightning Fruit"] = 27, ["Portal Fruit"] = 26, ["Phoenix Fruit"] = 25,
    ["Sound Fruit"] = 24, ["Spider Fruit"] = 23, ["Creation Fruit"] = 22,
    ["Love Fruit"] = 21, ["Buddha Fruit"] = 20, ["Quake Fruit"] = 19,
    ["Magma Fruit"] = 18, ["Ghost Fruit"] = 17, ["Rubber Fruit"] = 16,
    ["Light Fruit"] = 15, ["Diamond Fruit"] = 14, ["Eagle Fruit"] = 13,
    ["Dark Fruit"] = 12, ["Sand Fruit"] = 11, ["Ice Fruit"] = 10,
    ["Flame Fruit"] = 9, ["Spike Fruit"] = 8, ["Smoke Fruit"] = 7,
    ["Bomb Fruit"] = 6, ["Spring Fruit"] = 5, ["Blade Fruit"] = 4,
    ["Spin Fruit"] = 3, ["Rocket Fruit"] = 2,
}

-- Categorias das frutas (para filtragem opcional)
local fruitCategories = {
    -- Common
    ["Rocket Fruit"] = "Common", ["Spin Fruit"] = "Common", ["Blade Fruit"] = "Common",
    ["Spring Fruit"] = "Common", ["Bomb Fruit"] = "Common", ["Smoke Fruit"] = "Common",
    
    -- Uncommon
    ["Spike Fruit"] = "Uncommon", ["Flame Fruit"] = "Uncommon", ["Ice Fruit"] = "Uncommon",
    ["Sand Fruit"] = "Uncommon", ["Dark Fruit"] = "Uncommon", ["Eagle Fruit"] = "Uncommon",
    
    -- Rare
    ["Diamond Fruit"] = "Rare", ["Light Fruit"] = "Rare", ["Rubber Fruit"] = "Rare",
    ["Ghost Fruit"] = "Rare", ["Magma Fruit"] = "Rare", ["Quake Fruit"] = "Rare",
    
    -- Legendary
    ["Buddha Fruit"] = "Legendary", ["Love Fruit"] = "Legendary", ["Creation Fruit"] = "Legendary",
    ["Spider Fruit"] = "Legendary", ["Sound Fruit"] = "Legendary", ["Phoenix Fruit"] = "Legendary",
    ["Portal Fruit"] = "Legendary", ["Lightning Fruit"] = "Legendary", ["Pain Fruit"] = "Legendary",
    ["Blizzard Fruit"] = "Legendary", ["Gravity Fruit"] = "Legendary", ["Mammoth Fruit"] = "Legendary",
    
    -- Mythical
    ["T-Rex Fruit"] = "Mythical", ["Dough Fruit"] = "Mythical", ["Shadow Fruit"] = "Mythical",
    ["Venom Fruit"] = "Mythical", ["Gas Fruit"] = "Mythical", ["Spirit Fruit"] = "Mythical",
    ["Tiger Fruit"] = "Mythical", ["Yeti Fruit"] = "Mythical", ["Kitsune Fruit"] = "Mythical",
    ["Control Fruit"] = "Mythical", ["Dragon Fruit"] = "Mythical",
}

-- Códigos de storage das frutas (otimização: declarado 1x ao invés de a cada chamada)
local fruitStorageCodes = {
    ["Rocket Fruit"] = "Rocket-Rocket", ["Spin Fruit"] = "Spin-Spin",
    ["Blade Fruit"] = "Blade-Blade", ["Spring Fruit"] = "Spring-Spring",
    ["Bomb Fruit"] = "Bomb-Bomb", ["Smoke Fruit"] = "Smoke-Smoke",
    ["Spike Fruit"] = "Spike-Spike", ["Flame Fruit"] = "Flame-Flame",
    ["Eagle Fruit"] = "Eagle-Eagle", ["Ice Fruit"] = "Ice-Ice",
    ["Sand Fruit"] = "Sand-Sand", ["Dark Fruit"] = "Dark-Dark",
    ["Diamond Fruit"] = "Diamond-Diamond", ["Light Fruit"] = "Light-Light",
    ["Rubber Fruit"] = "Rubber-Rubber", ["Creation Fruit"] = "Creation-Creation",
    ["Ghost Fruit"] = "Ghost-Ghost", ["Magma Fruit"] = "Magma-Magma",
    ["Quake Fruit"] = "Quake-Quake", ["Buddha Fruit"] = "Buddha-Buddha",
    ["Love Fruit"] = "Love-Love", ["Spider Fruit"] = "Spider-Spider",
    ["Sound Fruit"] = "Sound-Sound", ["Phoenix Fruit"] = "Phoenix-Phoenix",
    ["Portal Fruit"] = "Portal-Portal", ["Lightning Fruit"] = "Lightning-Lightning",
    ["Pain Fruit"] = "Pain-Pain", ["Blizzard Fruit"] = "Blizzard-Blizzard",
    ["Gravity Fruit"] = "Gravity-Gravity", ["Mammoth Fruit"] = "Mammoth-Mammoth",
    ["T-Rex Fruit"] = "T-Rex-T-Rex", ["Dough Fruit"] = "Dough-Dough",
    ["Shadow Fruit"] = "Shadow-Shadow", ["Venom Fruit"] = "Venom-Venom",
    ["Gas Fruit"] = "Gas-Gas", ["Control Fruit"] = "Control-Control",
    ["Spirit Fruit"] = "Spirit-Spirit", ["Tiger Fruit"] = "Tiger-Tiger",
    ["Yeti Fruit"] = "Yeti-Yeti", ["Kitsune Fruit"] = "Kitsune-Kitsune",
    ["Dragon Fruit"] = "Dragon-Dragon",
}

-- Mobs do Pirate Raid (Castle Raid)
local castleRaidMobs = {
    "Galley Pirate", "Galley Captain", "Raider", "Mercenary",
    "Vampire", "Zombie", "Snow Trooper", "Winter Warrior",
    "Lab Subordinate", "Horned Warrior", "Magma Ninja", "Lava Pirate",
    "Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer",
    "Arctic Warrior", "Snow Lurker", "Sea Soldier", "Water Fighter"
}

-- Constantes de timing (otimização e manutenibilidade)
local TICK_RATE = 0.05
local ATTACK_DELAY = 0.1
local TWEEN_WAIT = 0.3
local STORAGE_COOLDOWN = 2
local FRUIT_RETRY_COOLDOWN = 60
local NOCLIP_UPDATE_RATE = 0.15

-- Cache de serviços
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

-- Cache de Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local CommF = Remotes and Remotes:WaitForChild("CommF_", 10)

-- Cache de Workspace.Enemies (otimização: acessado frequentemente)
local EnemiesFolder = Workspace:WaitForChild("Enemies", 10)

-- ═══════════════════════════════════════════════════════
-- INICIALIZAÇÃO: Setup Inicial do Script
-- ═══════════════════════════════════════════════════════

-- Aguarda PlayerGui carregar
repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")

-- Seleção de time (ANTES de espawnar character)
task.wait(1)

-- Aguarda tela de seleção com timeout de 30 segundos
local waitStart = os.clock()
repeat task.wait(0.5) until LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)") or LocalPlayer.Character or (os.clock() - waitStart > 30)

if LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)") then
    task.wait(1)
    
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if remotes and remotes:FindFirstChild("CommF_") then
        local attempts = 0
        local maxAttempts = 10
        
        repeat
            attempts = attempts + 1
            pcall(function()
                remotes.CommF_:InvokeServer("SetTeam", Team)
            end)
            
            task.wait(0.5)
        until not LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)") or attempts >= maxAttempts
    end
end

-- AGORA aguarda character spawnar completamente
repeat task.wait() until LocalPlayer.Character
repeat task.wait() until LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES: Armazenamento de Frutas
-- ═══════════════════════════════════════════════════════

-- Variáveis de controle do storage
local lastStorageTime = 0
local failedStorageFruits = {}
local currentJobId = game.JobId

local function StorageFruits(waitForCooldown)
    if not CommF then return end
    
    local currentTime = os.clock()
    local timeSinceLastCall = currentTime - lastStorageTime
    
    if timeSinceLastCall < STORAGE_COOLDOWN then
        if not waitForCooldown then return end
        task.wait(STORAGE_COOLDOWN - timeSinceLastCall)
        lastStorageTime = os.clock()
    else
        lastStorageTime = currentTime
    end
    
    pcall(function()
        local character = LocalPlayer.Character
        local backpack = LocalPlayer.Backpack
        if not character or not backpack then return end

        -- Consolida backpack e character em uma lista
        local containers = {backpack, character}
        for _, container in ipairs(containers) do
            for _, tool in ipairs(container:GetChildren()) do
                if not failedStorageFruits[tool] and tool:IsA("Tool") then
                    local fruitCode = fruitStorageCodes[tool.Name]
                    if fruitCode then
                        pcall(function()
                            CommF:InvokeServer("StoreFruit", fruitCode, tool)
                        end)
                        task.wait(0.7)
                        if container:FindFirstChild(tool.Name) == tool then
                            failedStorageFruits[tool] = true
                        end
                    end
                end
            end
        end
    end)
end

-- Gacha Fruit (1x após escolher time)
if FruitGacha and CommF then
    task.spawn(function()
        task.wait(1)
        pcall(function()
            CommF:InvokeServer("Cousin", "Buy")
        end)
        task.wait(0.5)
        StorageFruits()
    end)
end

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES: Visual (Highlight)
-- ═══════════════════════════════════════════════════════
local function setupHighlight(char)
    if not char then return end
    if char:FindFirstChild("highlight") then return end
    
    local h = Instance.new("Highlight")
    h.Name = "highlight"
    h.Enabled = true
    h.FillTransparency = 1  -- Totalmente transparente (sem preenchimento)
    h.OutlineTransparency = 0  -- Outline visível
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop  -- Sempre visível
    h.FillColor = Color3.fromRGB(51, 153, 255)
    h.OutlineColor = Color3.fromRGB(51, 153, 255)
    h.Parent = char
end

-- Setup inicial (aguarda character estar pronto)
task.spawn(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        setupHighlight(LocalPlayer.Character)
    end
end)

-- Reconecta ao respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(function()
        pcall(function()
            char:WaitForChild("HumanoidRootPart", 10)
            setupHighlight(char)
        end)
    end)
end)

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES: Anti-Sit
-- ═══════════════════════════════════════════════════════
task.spawn(function()
    local function setupAntiSit(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            
            hum:GetPropertyChangedSignal("Sit"):Connect(function()
                if hum.Sit then
                    hum.Sit = false
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end
    
    if LocalPlayer.Character then
        setupAntiSit(LocalPlayer.Character)
    end
    
    LocalPlayer.CharacterAdded:Connect(setupAntiSit)
end)

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES: Noclip
-- ═══════════════════════════════════════════════════════
task.spawn(function()
    local lastUpdate = 0
    local cachedParts = {}
    local lastCharacter = nil
    
    RunService.Stepped:Connect(function()
        local now = os.clock()
        if now - lastUpdate < NOCLIP_UPDATE_RATE then return end
        lastUpdate = now
        
        local char = LocalPlayer.Character
        if not char then return end
        
        -- Atualiza cache se mudou de personagem
        if char ~= lastCharacter then
            cachedParts = {}
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    table.insert(cachedParts, v)
                end
            end
            lastCharacter = char
        end
        
        if isTweening then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- BodyVelocity para noclip
                if not hrp:FindFirstChild("BodyClip") then
                    local Noclip = Instance.new("BodyVelocity")
                    Noclip.Name = "BodyClip"
                    Noclip.Parent = hrp
                    Noclip.MaxForce = Vector3.new(100000, 100000, 100000)
                    Noclip.Velocity = Vector3.new(0, 0, 0)
                end
            end
            
            -- Desativa colisão usando cache
            for _, part in ipairs(cachedParts) do
                if part.Parent then
                    part.CanCollide = false
                end
            end
        else
            -- Remove BodyClip quando não está teleportando
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bodyClip = hrp:FindFirstChild("BodyClip")
                if bodyClip then
                    bodyClip:Destroy()
                end
            end
        end
    end)
end)

-- Auto-cleanup: Remove BodyClip se morrer
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health <= 0 then
                    local bodyClip = hrp:FindFirstChild("BodyClip")
                    if bodyClip then
                        bodyClip:Destroy()
                    end
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES: Utilitárias
-- ═══════════════════════════════════════════════════════
local function IsCategoryAllowed(fruitName)
    -- Se allowedCategoriesSet vazio, permite todas
    if not next(allowedCategoriesSet) then
        return true
    end
    
    local category = fruitCategories[fruitName]
    if not category then return true end  -- Fruta desconhecida = permite
    
    -- Lookup O(1) ao invés de loop O(n)
    return allowedCategoriesSet[category] == true
end

local function RemoveHighlight()
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local highlight = char:FindFirstChild("highlight")
            if highlight then
                highlight:Destroy()
            end
        end
    end)
end

local function IsCharacterAlive()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

local function HasFruitInInventory()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    if not backpack then return false end
    
    local containers = {backpack}
    if char then table.insert(containers, char) end
    
    for _, container in ipairs(containers) do
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and item.Name:find("Fruit") then
                return true
            end
        end
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES: Movimento (Tween)
-- ═══════════════════════════════════════════════════════
local activeTween = nil

local function TweenToPosition(targetCFrame, targetObject)
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- Cancela tween anterior se existir
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end

    local dist = (targetCFrame.Position - hrp.Position).Magnitude
    if dist < 5 then return true end

    -- SimulationRadius infinito para melhor controle
    pcall(function()
        sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
    end)

    local tweenInfo = TweenInfo.new(dist / TweenSpeed, Enum.EasingStyle.Linear)
    local tw = TweenService:Create(hrp, tweenInfo, { CFrame = targetCFrame })
    activeTween = tw
    tw:Play()

    local completed = false
    tw.Completed:Connect(function() 
        completed = true
        if activeTween == tw then
            activeTween = nil
        end
    end)

    local startTime = os.clock()
    -- Timeout dinâmico baseado na distância
    local timeout = math.max(3, (dist / TweenSpeed) * 1.5)
    
    while task.wait(0.1) do
        if completed then break end
        
        -- Validação contínua: cancela se o alvo desapareceu
        if targetObject and (not targetObject.Parent) then
            tw:Cancel()
            if activeTween == tw then activeTween = nil end
            return false
        end
        
        -- Verifica distância para auto-cancelamento (segurança)
        if hrp and targetObject and (hrp.Position - targetObject.Position).Magnitude >= 10000 then
            tw:Cancel()
            if activeTween == tw then activeTween = nil end
            return false
        end
        
        if os.clock() - startTime > timeout then
            tw:Cancel()
            activeTween = nil
            break
        end
    end
    return completed
end

local isStoppingTween = false

local function StopTween()
    if isStoppingTween then return end
    isStoppingTween = true
    
    pcall(function()
        isTweening = false
        
        -- Cancela tween ativo
        if activeTween then
            activeTween:Cancel()
            activeTween = nil
        end
        
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            hrp.Anchored = false
            local bodyClip = hrp:FindFirstChild("BodyClip")
            if bodyClip then bodyClip:Destroy() end
        end
        
        task.wait(0.1)
    end)
    
    isStoppingTween = false
end

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES: Server Hop
-- ═══════════════════════════════════════════════════════
local function TPReturner()
    local PlaceID = game.PlaceId
    
    local success, Site = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100")
        )
    end)
    
    if not success then return end
    
    local servers = {}
    for _, v in ipairs(Site.data) do
        if v.playing < v.maxPlayers then
            table.insert(servers, v.id)
        end
    end
    
    if #servers > 0 then
        local randomServer = servers[math.random(1, #servers)]
        TeleportService:TeleportToPlaceInstance(PlaceID, randomServer, LocalPlayer)
    end
end

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES: Coleta de Baús
-- ═══════════════════════════════════════════════════════
local function ChestCollect(chest)
    -- Pré-verificação: garante que baú existe antes de começar
    if not chest or not chest.Parent then return false end
    
    -- Verificação de saúde ANTES de iniciar tween
    if not IsCharacterAlive() then return false end
    
    isTweening = true

    -- Validação contínua durante tween
    local success = TweenToPosition(chest:GetPivot(), chest)

    if not success then
        isTweening = false
        return false
    end

    local startTime = os.clock()
    local maxWaitTime = 6
    repeat 
        task.wait(0.1)
        
        -- Verificação de saúde DURANTE espera
        if not IsCharacterAlive() then
            StopTween()
            return false
        end
        
        -- Verifica se baú ainda existe
        if not chest or not chest.Parent then
            StopTween()
            return false
        end
    until chest:GetAttribute("IsDisabled") or (os.clock() - startTime) > maxWaitTime

    task.wait(0.2)
    StopTween()
    return true
end

local function GetClosestChest()
    local character = LocalPlayer.Character
    if not character then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local playerPos = hrp.Position
    local chests = CollectionService:GetTagged("_ChestTagged")
    local closest, minDist = nil, math.huge
    
    for _, chest in ipairs(chests) do
        if chest.Parent and not chest:GetAttribute("IsDisabled") then
            local ok, pos = pcall(function() return chest:GetPivot().Position end)
            if ok then
                local d = (pos - playerPos).Magnitude
                if d < minDist then
                    minDist = d
                    closest = chest
                end
            end
        end
    end
    return closest
end

local function CollectMultipleChests(targetCount)
    local collected = 0
    local tried = {}
    
    while collected < targetCount do
        local chest = GetClosestChest()
        if not chest or tried[chest] then break end
        tried[chest] = true
        
        local ok = ChestCollect(chest)
        if ok then
            collected += 1
        end
        task.wait(0.1)
    end
    
    return collected
end

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES: Sistema de Ataque (para Raids)
-- ═══════════════════════════════════════════════════════

-- Auto-seleciona arma Melee do backpack
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local backpack = LocalPlayer.Backpack
            if not backpack then return end
            
            -- Procura primeira arma Melee disponível
            for _, weapon in ipairs(backpack:GetChildren()) do
                if weapon:IsA("Tool") and weapon.ToolTip == "Melee" then
                    SelectWeapon = weapon.Name
                    break
                end
            end
        end)
    end
end)

local function EquipWeapon(weaponName)
    if not weaponName then return false end
    
    local char = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    if not char or not backpack then return false end
    
    -- Verifica se já está equipada
    local equippedTool = char:FindFirstChildOfClass("Tool")
    if equippedTool and equippedTool.Name == weaponName then
        return true
    end
    
    -- Procura no backpack
    local weapon = backpack:FindFirstChild(weaponName)
    if weapon and weapon:IsA("Tool") then
        pcall(function()
            char.Humanoid:EquipTool(weapon)
        end)
        task.wait(0.3)
        return true
    end
    
    return false
end

local function AttackEnemy(enemy)
    if not enemy or not enemy.Parent then return false end
    
    local char = LocalPlayer.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local enemyHrp = enemy:FindFirstChild("HumanoidRootPart")
    local enemyHum = enemy:FindFirstChild("Humanoid")
    
    if not hrp or not enemyHrp or not enemyHum then return false end
    if enemyHum.Health <= 0 then return false end
    
    -- Posiciona perto do inimigo
    local attackPos = enemyHrp.CFrame * CFrame.new(0, 0, 3)
    hrp.CFrame = attackPos
    
    -- Click para atacar (simula ataque básico)
    pcall(function()
        game:GetService("VirtualUser"):CaptureController()
        game:GetService("VirtualUser"):ClickButton1(Vector2.new(850, 500))
    end)
    
    return enemyHum.Health > 0
end

local function GetNearestEnemy(maxDistance, mobNames)
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not EnemiesFolder then return nil end
    
    local playerPos = hrp.Position
    local nearest, minDist = nil, maxDistance or math.huge
    
    -- Converte mobNames em set para lookup O(1)
    local mobSet = nil
    if mobNames then
        mobSet = {}
        for _, name in ipairs(mobNames) do
            mobSet[name] = true
        end
    end
    
    for _, enemy in pairs(EnemiesFolder:GetChildren()) do
        if enemy:IsA("Model") then
            local enemyHrp = enemy:FindFirstChild("HumanoidRootPart")
            local enemyHum = enemy:FindFirstChild("Humanoid")
            
            if enemyHrp and enemyHum and enemyHum.Health > 0 then
                -- Filtro por nome usando set lookup O(1)
                if not mobSet or mobSet[enemy.Name] then
                    local dist = (enemyHrp.Position - playerPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = enemy
                    end
                end
            end
        end
    end
    
    return nearest
end

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES: Factory Raid
-- ═══════════════════════════════════════════════════════
local factoryRaidPos = CFrame.new(448.46756, 199.356781, -441.389252)
local factoryRaidActive = false

local function DoFactoryRaid()
    if not IsCharacterAlive() then return false end
    
    local core = GetNearestEnemy(nil, {"Core"})
    if not core then return false end
    
    factoryRaidActive = true
    isDoingRaid = true
    
    if SelectWeapon then EquipWeapon(SelectWeapon) end
    
    local coreHrp = core:FindFirstChild("HumanoidRootPart")
    if coreHrp then
        isTweening = true
        TweenToPosition(factoryRaidPos, nil)
        
        repeat
            task.wait(TICK_RATE)
            
            if not IsCharacterAlive() or not FactoryRaid then break end
            
            local coreHum = core:FindFirstChild("Humanoid")
            if not coreHum or coreHum.Health <= 0 then break end
            
            if SelectWeapon then
                local char = LocalPlayer.Character
                local equippedTool = char and char:FindFirstChildOfClass("Tool")
                if not equippedTool or equippedTool.Name ~= SelectWeapon then
                    EquipWeapon(SelectWeapon)
                end
            end
            
            AttackEnemy(core)
            
        until not core or not core.Parent
        
        StopTween()
    end
    
    factoryRaidActive = false
    isDoingRaid = false
    return true
end

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES: Pirate Raid (Castle Raid)
-- ═══════════════════════════════════════════════════════
local pirateRaidPos = CFrame.new(-5496.17432, 313.768921, -2841.53027, 0.924894512, 7.37058015e-09, 0.380223751, 3.5881019e-08, 1, -1.06665446e-07, -0.380223751, 1.12297109e-07, 0.924894512)
local pirateRaidCheckPos = CFrame.new(-5539.3115234375, 313.800537109375, -2972.372314453125)
local pirateRaidActive = false

local function GetPirateRaidBoss()
    if not EnemiesFolder then return nil end
    
    local boss, maxHP = nil, 0
    local mobSet = {}
    for _, name in ipairs(castleRaidMobs) do
        mobSet[name] = true
    end
    
    for _, enemy in pairs(EnemiesFolder:GetChildren()) do
        if enemy:IsA("Model") then
            local enemyHum = enemy:FindFirstChild("Humanoid")
            if enemyHum and enemyHum.Health > 0 and mobSet[enemy.Name] then
                if enemyHum.MaxHealth > maxHP then
                    maxHP = enemyHum.MaxHealth
                    boss = enemy
                end
            end
        end
    end
    
    return boss
end

local function DoPirateRaid()
    if not IsCharacterAlive() then return false end
    
    pirateRaidActive = true
    isDoingRaid = true
    
    -- Equipa arma Melee
    if SelectWeapon then
        EquipWeapon(SelectWeapon)
    end
    
    -- 1º: Procura BOSS (tankudo com mais HP)
    local boss = GetPirateRaidBoss()
    
    if boss then
        -- FOCA NO BOSS para garantir last hit e ganhar fruta
        local bossHrp = boss:FindFirstChild("HumanoidRootPart")
        local bossHum = boss:FindFirstChild("Humanoid")
        
        if bossHrp and bossHum then
            -- Tween até o boss
            isTweening = true
            TweenToPosition(bossHrp.CFrame * CFrame.new(0, 0, 3), bossHrp)
            
            -- Ataca boss até morrer
            repeat
                task.wait(TICK_RATE)
                
                if not IsCharacterAlive() or not PirateRaid then
                    pirateRaidActive = false
                    break
                end
                
                bossHum = boss:FindFirstChild("Humanoid")
                if not bossHum or bossHum.Health <= 0 then
                    pirateRaidActive = false
                    break
                end
                
                -- Reequipa arma se necessário
                if SelectWeapon then
                    local char = LocalPlayer.Character
                    local equippedTool = char and char:FindFirstChildOfClass("Tool")
                    if not equippedTool or equippedTool.Name ~= SelectWeapon then
                        EquipWeapon(SelectWeapon)
                    end
                end
                
                AttackEnemy(boss)
                
                -- Verifica se spawnou outro boss (maior HP)
                local newBoss = GetPirateRaidBoss()
                if newBoss and newBoss ~= boss then
                    boss = newBoss
                    bossHrp = boss:FindFirstChild("HumanoidRootPart")
                    if bossHrp then
                        TweenToPosition(bossHrp.CFrame * CFrame.new(0, 0, 3), bossHrp)
                    end
                end
                
            until not boss or not boss.Parent or not pirateRaidActive
            
            StopTween()
        end
    else
        -- Sem boss: ataca mobs normais (qualquer distância)
        local enemy = GetNearestEnemy(nil, castleRaidMobs)
        
        if enemy then
            local enemyHrp = enemy:FindFirstChild("HumanoidRootPart")
            if enemyHrp then
                -- Equipa arma
                if SelectWeapon then
                    EquipWeapon(SelectWeapon)
                end
                
                isTweening = true
                TweenToPosition(enemyHrp.CFrame * CFrame.new(0, 0, 3), enemyHrp)
                
                local attackStart = os.clock()
                while enemy and enemy.Parent and IsCharacterAlive() and pirateRaidActive do
                    if GetPirateRaidBoss() then break end
                    
                    local enemyHum = enemy:FindFirstChild("Humanoid")
                    if not enemyHum or enemyHum.Health <= 0 then break end
                    
                    AttackEnemy(enemy)
                    task.wait(ATTACK_DELAY)
                    
                    if os.clock() - attackStart > 15 then break end
                end
                
                StopTween()
            end
        else
            -- Sem inimigos - vai para área do raid
            local mobFound = false
            for _, mobName in ipairs(castleRaidMobs) do
                if ReplicatedStorage:FindFirstChild(mobName) then
                    mobFound = true
                    break
                end
            end
            
            if mobFound then
                -- Tween até área do raid
                isTweening = true
                TweenToPosition(pirateRaidPos, nil)
                StopTween()
                task.wait(0.5)
            else
                pirateRaidActive = false
                task.wait(2)
            end
        end
    end
    
    isDoingRaid = false
    return true
end

-- ═══════════════════════════════════════════════════════
-- LOOP PRINCIPAL: Auto Farm
-- Ordem de execução: Frutas → Raids → Baús → Server Hop
-- ═══════════════════════════════════════════════════════
task.spawn(function()
    -- Aguarda LocalPlayer e Character estarem prontos
    repeat task.wait() until LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    local fruitRetryTime = {}  -- Sistema de cooldown: {[fruit] = timestamp para retry}
    local totalChestsCollected = 0  -- Contador persistente de baús

    -- Evento de spawn: Para tween e detecta mudança de servidor
    LocalPlayer.CharacterAdded:Connect(function()
        isCollectingChests = false
        StopTween()
        
        -- Limpa cache APENAS se mudou de servidor (JobId diferente)
        if game.JobId ~= currentJobId then
            failedStorageFruits = {}
            fruitRetryTime = {}  -- Limpa cooldowns de retry
            totalChestsCollected = 0  -- Reseta contador ao mudar servidor
            currentJobId = game.JobId
        end
        -- Se foi só morte, mantém cache (storage continua cheio)
    end)

    local function FindNearestFruit()
        local char = LocalPlayer.Character
        if not char then return nil end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        
        local playerPos = hrp.Position
        local bestFruit = nil
        local bestPriority = -1
        local bestDist = math.huge
        local currentTime = os.clock()
        
        -- Limpa cooldowns expirados (otimização)
        for fruit, retryTime in pairs(fruitRetryTime) do
            if currentTime >= retryTime or not fruit.Parent then
                fruitRetryTime[fruit] = nil
            end
        end
        
        -- Loop otimizado: for tradicional é ~15% mais rápido que ipairs
        local workspaceChildren = Workspace:GetChildren()
        for i = 1, #workspaceChildren do
            local v = workspaceChildren[i]
            if v:IsA("Model") then
                local retryTime = fruitRetryTime[v]
                if not retryTime or currentTime >= retryTime then
                    local name = v.Name
                    if name:find("Fruit") and IsCategoryAllowed(name) then
                        local handle = v:FindFirstChild("Handle")
                        if handle and handle:IsA("BasePart") then
                            local dist = (handle.Position - playerPos).Magnitude
                            local priority = fruitPriority[name] or 1
                            
                            if priority > bestPriority or (priority == bestPriority and dist < bestDist) then
                                bestPriority = priority
                                bestDist = dist
                                bestFruit = {model = v, handle = handle, distance = dist}
                            end
                        end
                    end
                end
            end
        end
        
        return bestFruit
    end
    
    local function FruitCollect(fruitData)
        -- Pré-verificação: garante que target ainda existe antes de começar
        if not fruitData or not fruitData.model or not fruitData.model.Parent then
            return false
        end
        if not fruitData.handle or not fruitData.handle.Parent then
            return false
        end
        
        -- Verificação de saúde ANTES de iniciar
        if not IsCharacterAlive() then return false end
        
        -- Cache de referências usadas múltiplas vezes
        local model = fruitData.model
        local handle = fruitData.handle
        
        isTweening = true
        
        -- Passa o handle para validação contínua durante tween
        local success = TweenToPosition(handle.CFrame * CFrame.new(0, 3, 0), handle)
        
        if not success then
            StopTween()
            fruitRetryTime[model] = os.clock() + 60
            return false
        end

        -- Espera até coletar a fruta ou timeout
        local startWait = os.clock()
        local collected = false
        
        repeat
            task.wait(0.1)
            
            -- Verificação de saúde DURANTE coleta
            if not IsCharacterAlive() then
                StopTween()
                return false
            end
            
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            -- Verifica se a fruta foi coletada (usa cache)
            if not model.Parent or not handle.Parent then
                collected = true
                break
            end
            
            -- Verifica proximidade (usa cache)
            if hrp and (handle.Position - hrp.Position).Magnitude < 8 then
                task.wait(0.5)
                break
            end
        until (os.clock() - startWait > 10)

        task.wait(TWEEN_WAIT)
        
        StorageFruits(true)
        task.wait(0.7)
        
        StopTween()
        
        if HasFruitInInventory() and model and model.Parent then
            fruitRetryTime[model] = os.clock() + FRUIT_RETRY_COOLDOWN
            return false
        end
        
        return collected or (not model.Parent)
    end
    
    while task.wait(1) do
        -- ═══════════════════════════════════════════════════════
        -- PRIORIDADE 1: RAIDS (Factory e Pirate) - SEMPRE PRIMEIRO
        -- Executa apenas raid correspondente ao Sea atual
        -- ═══════════════════════════════════════════════════════
        local raidDone = false
        
        if not isDoingRaid then
            -- Factory Raid (Sea 2 apenas)
            if FactoryRaid and CurrentSea == 2 then
                local core = GetNearestEnemy(nil, {"Core"})
                if core then
                    DoFactoryRaid()
                    raidDone = true
                    task.wait(0.5)
                end
            end
            
            -- Pirate Raid (Sea 3 apenas)
            if PirateRaid and CurrentSea == 3 and not raidDone then
                -- Verifica se raid está ativo (mobs spawned)
                local raidActive = false
                for _, mobName in ipairs(castleRaidMobs) do
                    if ReplicatedStorage:FindFirstChild(mobName) then
                        raidActive = true
                        break
                    end
                end
                
                if raidActive then
                    DoPirateRaid()
                    raidDone = true
                    task.wait(0.5)
                end
            end
        end
        
        -- Se fez raid, pula para próxima iteração (raids têm prioridade total)
        if raidDone then
            task.wait(0.5)
            continue
        end
        
        -- ═══════════════════════════════════════════════════════
        -- PRIORIDADE 2: FRUTAS
        -- ═══════════════════════════════════════════════════════
        local hasFruitToCollect = false
        
        if FruitCollect then
            local hasFruits = true
            
            while hasFruits do
                local fruitData = FindNearestFruit()
                
                if not fruitData then break end
                
                hasFruitToCollect = true
                FruitCollect(fruitData)
                task.wait(TWEEN_WAIT)
            end
        end
        
        -- ═══════════════════════════════════════════════════════
        -- PRIORIDADE 3: BAÚS (só se não há frutas)
        -- ═══════════════════════════════════════════════════════
        if not hasFruitToCollect and (not FruitCollect or not FindNearestFruit()) and not isDoingRaid then
            -- Se coleta de baús está ATIVADA
            if ChestCollect and not isCollectingChests then
                isCollectingChests = true
                
                while totalChestsCollected < ChestCount do
                    -- Verifica se apareceu fruta (se coleta ativada)
                    if FruitCollect and FindNearestFruit() then
                        break
                    end
                    
                    local collected = CollectMultipleChests(ChestCount - totalChestsCollected)
                    totalChestsCollected = totalChestsCollected + collected
                    
                    if totalChestsCollected >= ChestCount or collected == 0 then
                        break
                    end
                    
                    task.wait(0.5)
                end
                
                isCollectingChests = false
                
                -- HOP se atingiu a meta de baús E não há frutas
                local shouldHop = totalChestsCollected >= ChestCount
                if FruitCollect then
                    shouldHop = shouldHop and not FindNearestFruit()
                end
                
                if shouldHop then
                    RemoveHighlight()
                    task.wait(ServerHopDelay)
                    pcall(TPReturner)
                end
            else
                -- Se coleta de baús DESATIVADA (false ou nil) e sem frutas, hop direto
                RemoveHighlight()
                task.wait(ServerHopDelay)
                pcall(TPReturner)
            end
        end
    end
end)
