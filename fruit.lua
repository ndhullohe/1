-- Configurações (valores padrão se não definidos no executor)
if getgenv().Team == nil then getgenv().Team = "Marines" end
if getgenv().CollectFruits == nil then getgenv().CollectFruits = true end
if getgenv().GachaFruit == nil then getgenv().GachaFruit = true end
if getgenv().CollectChests == nil then getgenv().CollectChests = true end
if getgenv().ChestCount == nil then getgenv().ChestCount = 5 end
if getgenv().TweenSpeed == nil then getgenv().TweenSpeed = 300 end
if getgenv().DelayHop == nil then getgenv().DelayHop = 5 end

-- Cache de serviços (otimização)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- Aguarda jogo carregar e setar time
task.spawn(function()
    repeat task.wait() until game:IsLoaded() and LocalPlayer:FindFirstChild("DataLoaded")
    if LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)") then
        local remotes = ReplicatedStorage:WaitForChild("Remotes")
        repeat
            task.wait()
            remotes.CommF_:InvokeServer("SetTeam", getgenv().Team)
            task.wait(3)
        until not LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)")
    end
end)

-- ═══════════════════════════════════════════════════════
-- ARMAZENAMENTO: Guardar Frutas Coletadas (Declarado antes do Gacha)
-- ═══════════════════════════════════════════════════════
local lastStorageTime = 0
local failedStorageFruits = {}
local currentJobId = game.JobId  -- Detecta mudança de servidor

function StorageFruits(waitForCooldown)
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
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruitCode, tool)
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
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruitCode, tool)
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
if getgenv().GachaFruit then
    task.spawn(function()
        task.wait(1)
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Cousin", "Buy")
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
if LocalPlayer.Character then
    setupHighlight(LocalPlayer.Character)
end

-- Reconecta ao respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    setupHighlight(char)
end)

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
    
    LocalPlayer.CharacterAdded:Connect(setupAntiSit)
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
-- FUNÇÃO AUXILIAR: Verificação de Saúde
-- ═══════════════════════════════════════════════════════
local function IsCharacterAlive()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

-- ═══════════════════════════════════════════════════════
-- SISTEMA DE MOVIMENTO: Tween
-- ═══════════════════════════════════════════════════════
local activeTween = nil

local function TweenToPosition(targetCFrame, speed)
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
    speed = getgenv().TweenSpeed  -- Sempre usa o valor da flag
    if dist < 5 then return true end

    local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
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
    local timeout = math.max(3, dist / speed + 2)
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

    local success = TweenToPosition(chest:GetPivot(), getgenv().TweenSpeed)

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

local function CollectChests(targetCount)
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
    if not getgenv().CollectFruits then return end

    local triedFruits = {}  -- Cache de frutas já tentadas
    local totalChestsCollected = 0  -- Contador persistente de baús

    -- Evento de spawn: Para tween e detecta mudança de servidor
    LocalPlayer.CharacterAdded:Connect(function()
        getgenv().IsCollectingChests = false
        StopTween()
        
        -- Limpa cache APENAS se mudou de servidor (JobId diferente)
        if game.JobId ~= currentJobId then
            failedStorageFruits = {}
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
        
        local success = TweenToPosition(fruitData.handle.CFrame * CFrame.new(0, 3, 0), getgenv().TweenSpeed)
        
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
        
        -- Verifica se ainda há frutas no backpack/character (não conseguiu guardar)
        local hasFruitInInventory = false
        local currentChar = LocalPlayer.Character
        local backpack = LocalPlayer.Backpack
        
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item.Name:find("Fruit") then
                hasFruitInInventory = true
                break
            end
        end
        
        if not hasFruitInInventory and currentChar then
            for _, item in ipairs(currentChar:GetChildren()) do
                if item:IsA("Tool") and item.Name:find("Fruit") then
                    hasFruitInInventory = true
                    break
                end
            end
        end
        
        StopTween()
        
        -- Se não conseguiu guardar E a fruta ainda existe no mundo, marca como tentada
        if hasFruitInInventory and fruitData.model and fruitData.model.Parent then
            triedFruits[fruitData.model] = true
            return false  -- Não coletou com sucesso
        end
        
        return collected or (not fruitData.model.Parent)
    end

    while task.wait(1.5) do
        -- Verifica se o farm ainda está ativo
        if not getgenv().CollectFruits then break end
        
        -- 1) PRIORIDADE: COLETAR TODAS AS FRUTAS DISPONÍVEIS
        local hasFruits = true
        local fruitsCollected = 0
        
        while hasFruits do
            local fruitData = FindNearestFruit()
            
            if fruitData then
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
        
        -- 2) SEM FRUTAS: Vai para baús
        if not FindNearestFruit() then
            local shouldCollectChests = getgenv().CollectChests
            local isCollecting = getgenv().IsCollectingChests
            
            if shouldCollectChests and not isCollecting then
                getgenv().IsCollectingChests = true
                local targetCount = getgenv().ChestCount
                
                while totalChestsCollected < targetCount do
                    -- Verifica se apareceu fruta (prioridade)
                    if FindNearestFruit() then
                        break
                    end
                    
                    local collected = CollectChests(targetCount - totalChestsCollected)
                    totalChestsCollected = totalChestsCollected + collected
                    
                    if totalChestsCollected >= targetCount or collected == 0 then
                        break
                    end
                    
                    task.wait(0.5)
                end
                
                getgenv().IsCollectingChests = false
                
                -- HOP se atingiu a meta de baús E não há frutas
                if totalChestsCollected >= targetCount and not FindNearestFruit() then
                    task.wait(getgenv().DelayHop)
                    pcall(TPReturner)
                end
            elseif not shouldCollectChests then
                -- Se coleta de baús desativada e sem frutas, hop direto
                task.wait(getgenv().DelayHop)
                pcall(TPReturner)
            end
            
            task.wait(1.5)
        end
    end
end)

print("[SCRIPT] Carregado | Baús: " .. getgenv().ChestCount .. " | Speed: " .. getgenv().TweenSpeed .. " | Delay: " .. getgenv().DelayHop .. "s")
