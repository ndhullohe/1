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
local CollectFruits = config["CollectFruit"]
local GachaFruit = config["GachaFruit"]
local CollectChests = config["CollectChest"]
local ChestCount = config["ChestCount"] or 5

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

-- Aguarda PlayerGui carregar
repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")

-- Seleção de time (ANTES de esperar character completo)
task.wait(2)

-- Aguarda tela de seleção com timeout de 30 segundos
local waitStart = os.clock()
repeat task.wait(0.5) until LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)") or LocalPlayer.Character or (os.clock() - waitStart > 30)

if LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)") then
    task.wait(2)
    
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if remotes and remotes:FindFirstChild("CommF_") then
        local attempts = 0
        local maxAttempts = 10
        
        repeat
            attempts = attempts + 1
            pcall(function()
                remotes.CommF_:InvokeServer("SetTeam", Team)
            end)
            
            task.wait(1)
        until not LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)") or attempts >= maxAttempts
    end
end

-- AGORA aguarda character spawnar completamente
repeat task.wait() until LocalPlayer.Character
repeat task.wait() until LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

-- ═══════════════════════════════════════════════════════
-- ARMAZENAMENTO: Guardar Frutas Coletadas (Declarado antes do Gacha)
-- ═══════════════════════════════════════════════════════
local lastStorageTime = 0
local failedStorageFruits = {}
local currentJobId = game.JobId  -- Detecta mudança de servidor

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

        local fruits = {
            ["Rocket Fruit"] = "Rocket-Rocket", ["Spin Fruit"] = "Spin-Spin",
            ["Blade Fruit"] = "Blade-Blade", ["Spring Fruit"] = "Spring-Spring",
            ["Bomb Fruit"] = "Bomb-Bomb", ["Smoke Fruit"] = "Smoke-Smoke",
            ["Spike Fruit"] = "Spike-Spike", ["Flame Fruit"] = "Flame-Flame",
            ["Eagle Fruit"] = "Eagle-Eagle", ["Ice Fruit"] = "Ice-Ice",
            ["Sand Fruit"] = "Sand-Sand", ["Dark Fruit"] = "Dark-Dark",
            ["Diamond Fruit"] = "Diamond-Diamond", ["Light Fruit"] = "Light-Light",
            ["Rubber Fruit"] = "Rubber-Rubber", ["Barrier Fruit"] = "Barrier-Barrier",
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
            ["Spirit Fruit"] = "Spirit-Spirit", ["Leopard Fruit"] = "Leopard-Leopard",
            ["Yeti Fruit"] = "Yeti-Yeti", ["Kitsune Fruit"] = "Kitsune-Kitsune",
            ["Dragon Fruit"] = "Dragon-Dragon",
        }

        for _, tool in ipairs(backpack:GetChildren()) do
            if not failedStorageFruits[tool] and tool:IsA("Tool") then
                local fruitCode = fruits[tool.Name]
                if fruitCode then
                    pcall(function()
                        CommF:InvokeServer("StoreFruit", fruitCode, tool)
                    end)
                    task.wait(0.7)
                    if backpack:FindFirstChild(tool.Name) == tool then
                        failedStorageFruits[tool] = true
                    end
                end
            end
        end
        
        for _, tool in ipairs(character:GetChildren()) do
            if not failedStorageFruits[tool] and tool:IsA("Tool") then
                local fruitCode = fruits[tool.Name]
                if fruitCode then
                    pcall(function()
                        CommF:InvokeServer("StoreFruit", fruitCode, tool)
                    end)
                    task.wait(0.7)
                    if character:FindFirstChild(tool.Name) == tool then
                        failedStorageFruits[tool] = true
                    end
                end
            end
        end
    end)
end

-- Gacha Fruit (1x após escolher time)
if GachaFruit and CommF then
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
-- VISUAL: Destaque no Personagem (ANTES de iniciar movimento)
-- ═══════════════════════════════════════════════════════
local highlightColor = Color3.fromRGB(0, 128, 255)

local function setupHighlight(char)
    if not char then return end
    if char:FindFirstChild("highlight") then return end
    
    local h = Instance.new("Highlight")
    h.Name = "highlight"
    h.Enabled = true
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0.2
    h.FillColor = highlightColor
    h.OutlineColor = highlightColor
    h.Parent = char
end

-- Setup inicial (aguarda character estar pronto)
task.spawn(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        setupHighlight(LocalPlayer.Character)
    end
end)

-- Reconecta ao respawn
if LocalPlayer then
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.spawn(function()
            pcall(function()
                char:WaitForChild("HumanoidRootPart", 10)
                setupHighlight(char)
            end)
        end)
    end)
end

-- ═══════════════════════════════════════════════════════
-- ANTI-SIT: Prevenir Sentar
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
    
    if LocalPlayer then
        LocalPlayer.CharacterAdded:Connect(setupAntiSit)
    end
end)

-- ═══════════════════════════════════════════════════════
-- NOCLIP: Atravessar Paredes Durante Movimento
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
        
        if getgenv().Tweening then
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

-- ═══════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES
-- ═══════════════════════════════════════════════════════
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
    
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name:find("Fruit") then
            return true
        end
    end
    
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item.Name:find("Fruit") then
                return true
            end
        end
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════
-- SISTEMA DE MOVIMENTO: Tween
-- ═══════════════════════════════════════════════════════
local activeTween = nil

local function TweenToPosition(targetCFrame)
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
    local timeout = math.max(3, dist / TweenSpeed + 2)
    while task.wait(0.1) do
        if completed then break end
        if os.clock() - startTime > timeout then
            tw:Cancel()
            activeTween = nil
            break
        end
    end
    return completed
end

function StopTween()
    pcall(function()
        getgenv().Tweening = false
        
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
    end)
end

-- ═══════════════════════════════════════════════════════
-- SERVER HOP: Trocar de Servidor Automaticamente
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
-- SISTEMA DE COLETA: Baús
-- ═══════════════════════════════════════════════════════
local function CollectChest(chest)
    if not chest or not chest.Parent then return false end
    
    -- Verificação de saúde ANTES de iniciar tween
    if not IsCharacterAlive() then return false end
    
    getgenv().Tweening = true

    local success = TweenToPosition(chest:GetPivot())

    if not success then
        getgenv().Tweening = false
        return false
    end

    local startTime = os.clock()
    local maxWaitTime = 8
    repeat 
        task.wait(0.1)
        
        -- Verificação de saúde DURANTE espera
        if not IsCharacterAlive() then
            StopTween()
            return false
        end
    until not chest or not chest.Parent or chest:GetAttribute("IsDisabled") or (os.clock() - startTime) > maxWaitTime

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
        
        local ok = CollectChest(chest)
        if ok then
            collected += 1
        end
        task.wait(0.1)
    end
    
    return collected
end

-- ═══════════════════════════════════════════════════════
-- LÓGICA PRINCIPAL: Auto Farm Loop
-- Prioridade: Frutas → Baús → Server Hop
-- ═══════════════════════════════════════════════════════
task.spawn(function()
    -- Aguarda LocalPlayer e Character estarem prontos
    repeat task.wait() until LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    local triedFruits = {}  -- Cache de frutas já tentadas
    local totalChestsCollected = 0  -- Contador persistente de baús

    -- Evento de spawn: Para tween e detecta mudança de servidor
    if LocalPlayer then
        LocalPlayer.CharacterAdded:Connect(function()
            getgenv().IsCollectingChests = false
            StopTween()
            
            -- Limpa cache APENAS se mudou de servidor (JobId diferente)
            if game.JobId ~= currentJobId then
                failedStorageFruits = {}
                totalChestsCollected = 0  -- Reseta contador ao mudar servidor
                currentJobId = game.JobId
            end
            -- Se foi só morte, mantém cache (storage continua cheio)
        end)
    end

    local function FindNearestFruit()
        local char = LocalPlayer.Character
        if not char then return nil end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        
        local playerPos = hrp.Position
        local nearest, minDist = nil, math.huge
        
        for _, v in ipairs(Workspace:GetChildren()) do
            if v:IsA("Model") and not triedFruits[v] then
                local name = v.Name
                if name:find("Fruit") then
                    local handle = v:FindFirstChild("Handle")
                    if handle and handle:IsA("BasePart") then
                        local dist = (handle.Position - playerPos).Magnitude
                        if dist < minDist then
                            minDist = dist
                            nearest = {model = v, handle = handle, distance = dist}
                        end
                    end
                end
            end
        end
        
        return nearest
    end
    
    local function CollectFruit(fruitData)
        if not fruitData or not fruitData.handle or not fruitData.handle.Parent then
            return false
        end
        
        -- Verificação de saúde ANTES de iniciar
        if not IsCharacterAlive() then return false end
        
        getgenv().Tweening = true
        
        local success = TweenToPosition(fruitData.handle.CFrame * CFrame.new(0, 3, 0))
        
        if not success then
            StopTween()
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

        task.wait(0.5)
        
        -- Tenta guardar frutas
        StorageFruits(true)
        task.wait(1.0)
        
        StopTween()
        
        -- Se não conseguiu guardar E a fruta ainda existe no mundo, marca como tentada
        if HasFruitInInventory() and fruitData.model and fruitData.model.Parent then
            triedFruits[fruitData.model] = true
            return false  -- Não coletou com sucesso
        end
        
        return collected or (not fruitData.model.Parent)
    end
    
    while task.wait(1.5) do
        local hasFruitToCollect = false
        
        -- 1) COLETA FRUTAS (se ativado)
        if CollectFruits == true then
            local hasFruits = true
            local fruitsCollected = 0
            
            while hasFruits do
                local fruitData = FindNearestFruit()
                
                if fruitData then
                    hasFruitToCollect = true
                    local success = CollectFruit(fruitData)
                    if success then
                        fruitsCollected = fruitsCollected + 1
                    end
                    task.wait(0.8)
                else
                    hasFruits = false
                end
            end
            
            -- Limpa cache quando não há mais frutas
            triedFruits = {}
        end
        
        -- 2) SEM FRUTAS: Vai para baús ou hop
        if not hasFruitToCollect and (CollectFruits ~= true or not FindNearestFruit()) then
            -- Se coleta de baús está ATIVADA
            if CollectChests == true and not getgenv().IsCollectingChests then
                getgenv().IsCollectingChests = true
                
                while totalChestsCollected < ChestCount do
                    -- Verifica se apareceu fruta (se coleta ativada)
                    if CollectFruits == true and FindNearestFruit() then
                        break
                    end
                    
                    local collected = CollectMultipleChests(ChestCount - totalChestsCollected)
                    totalChestsCollected = totalChestsCollected + collected
                    
                    if totalChestsCollected >= ChestCount or collected == 0 then
                        break
                    end
                    
                    task.wait(0.5)
                end
                
                getgenv().IsCollectingChests = false
                
                -- HOP se atingiu a meta de baús E não há frutas
                local shouldHop = totalChestsCollected >= ChestCount
                if CollectFruits == true then
                    shouldHop = shouldHop and not FindNearestFruit()
                end
                
                if shouldHop then
                    task.wait(ServerHopDelay)
                    pcall(TPReturner)
                end
            else
                -- Se coleta de baús DESATIVADA (false ou nil) e sem frutas, hop direto
                task.wait(ServerHopDelay)
                pcall(TPReturner)
            end
        end
    end
end)
