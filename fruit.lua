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

-- Estados dinâmicos (uso interno do script)
local isTweening = false
local isCollectingChests = false

-- ═══════════════════════════════════════════════════════
-- CONSTANTES E TABELAS
-- ═══════════════════════════════════════════════════════

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

-- Cache de serviços (otimização)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

-- Cache de Remotes (usado em várias partes do script)
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local CommF = Remotes and Remotes:WaitForChild("CommF_", 10)

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

function StorageFruits(waitForCooldown)
    if not CommF then return end -- Verifica se CommF_ está disponível
    
    local currentTime = os.clock()
    local timeSinceLastCall = currentTime - lastStorageTime
    
    if timeSinceLastCall < 2 then
        if waitForCooldown then
            local waitTime = 2 - timeSinceLastCall
            task.wait(waitTime)
            lastStorageTime = os.clock()
        else
            return
        end
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
    h.FillColor = Color3.fromRGB(0, 128, 255)
    h.OutlineColor = Color3.fromRGB(0, 128, 255)
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
-- FUNÇÕES: Noclip (Atravessar Paredes)
-- ═══════════════════════════════════════════════════════
task.spawn(function()
    local lastUpdate = 0
    local cachedParts = {}
    local lastCharacter = nil
    
    RunService.Stepped:Connect(function()
        local now = os.clock()
        if now - lastUpdate < 0.15 then return end  -- Limita a ~6-7x por segundo
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
    -- Se FruitCategories não definido ou vazio, permite todas
    if not FruitCategories or type(FruitCategories) ~= "table" or #FruitCategories == 0 then
        return true
    end
    
    local category = fruitCategories[fruitName]
    if not category then return true end  -- Fruta desconhecida = permite
    
    -- Verifica se a categoria está na lista permitida
    for _, allowedCategory in ipairs(FruitCategories) do
        if category == allowedCategory then
            return true
        end
    end
    
    return false
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

    -- Anti-colisão melhorado: desativa colisão de TODAS as partes
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end

    -- Ajuste de altura: alinha Y com o destino antes de mover
    hrp.CFrame = CFrame.new(hrp.Position.X, targetCFrame.Position.Y, hrp.Position.Z)

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

function StopTween()
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
-- LOOP PRINCIPAL: Auto Farm
-- Ordem de execução: Frutas (prioridade) → Baús → Server Hop
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
        
        for _, v in ipairs(Workspace:GetChildren()) do
            if v:IsA("Model") then
                -- Verifica cooldown de retry
                local retryTime = fruitRetryTime[v]
                if not retryTime or currentTime >= retryTime then
                    local name = v.Name
                    if name:find("Fruit") and IsCategoryAllowed(name) then  -- Filtra por categoria
                        local handle = v:FindFirstChild("Handle")
                        if handle and handle:IsA("BasePart") then
                            local dist = (handle.Position - playerPos).Magnitude
                            local priority = fruitPriority[name] or 1
                            
                            -- Prioriza por valor (prioridade), distância só desempata
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
        
        isTweening = true
        
        -- Passa o handle para validação contínua durante tween
        local success = TweenToPosition(fruitData.handle.CFrame * CFrame.new(0, 3, 0), fruitData.handle)
        
        if not success then
            StopTween()
            -- Cooldown de 60s para retry
            fruitRetryTime[fruitData.model] = os.clock() + 60
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
            
            -- Verifica se a fruta foi coletada
            if not fruitData.model.Parent or not fruitData.handle.Parent then
                collected = true
                break
            end
            
            -- Verifica proximidade
            if hrp and (fruitData.handle.Position - hrp.Position).Magnitude < 8 then
                task.wait(0.5)
                break
            end
        until (os.clock() - startWait > 10)

        task.wait(0.3)
        
        -- Tenta guardar frutas
        StorageFruits(true)
        task.wait(0.7)
        
        StopTween()
        
        -- Se não conseguiu guardar E a fruta ainda existe no mundo, adiciona cooldown
        if HasFruitInInventory() and fruitData.model and fruitData.model.Parent then
            fruitRetryTime[fruitData.model] = os.clock() + 60
            return false  -- Não coletou com sucesso
        end
        
        return collected or (not fruitData.model.Parent)
    end
    
    while task.wait(1.5) do
        local hasFruitToCollect = false
        
        -- 1) COLETA FRUTAS (se ativado)
        if FruitCollect then
            local hasFruits = true
            
            while hasFruits do
                local fruitData = FindNearestFruit()
                
                if fruitData then
                    hasFruitToCollect = true
                    FruitCollect(fruitData)
                    task.wait(0.3)
                else
                    hasFruits = false
                end
            end
        end
        
        -- 2) SEM FRUTAS: Vai para baús ou hop
        if not hasFruitToCollect and (not FruitCollect or not FindNearestFruit()) then
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
