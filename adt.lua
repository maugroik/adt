local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Rain-Design/Unnamed/main/Library.lua'))()
Library.Theme = "Tokyo Night"
local Flags = Library.Flags
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local trackedESP = {}
local billboardGUIs = {}
local espConn
local goodshopPosition = nil
local autoCheckEnabled = true

local function updateGoodshopPosition()
    local modelspoint = workspace:FindFirstChild("modelspoint")
    if not modelspoint then
        warn("modelspoint не найден в workspace")
        return
    end

    for _, model in ipairs(modelspoint:GetChildren()) do
        local building = model:FindFirstChild("building")
        if building then
            local sellLever = building:FindFirstChild("SELL_LEVER")
            if sellLever then
                local targetPart = nil
                if sellLever:IsA("BasePart") then
                    targetPart = sellLever
                elseif sellLever:IsA("Model") then
                    targetPart = sellLever.PrimaryPart
                    if not targetPart then
                        for _, part in ipairs(sellLever:GetChildren()) do
                            if part:IsA("BasePart") then
                                targetPart = part
                                break
                            end
                        end
                    end
                end

                if targetPart then
                    local newPosition = targetPart.CFrame + Vector3.new(0, 5, 0)
                    if not goodshopPosition or not goodshopPosition.Position:FuzzyEq(newPosition.Position, 0.01) then
                        goodshopPosition = newPosition
                        print("Обновлена позиция Выгодного магазина:", goodshopPosition)
                    end
                    break
                end
            end
        end
    end
end

coroutine.wrap(function()
    while autoCheckEnabled do
        updateGoodshopPosition()
        wait(1)
    end
end)()

local Window = Library:Window({
   Text = "ADT"
})

-- ТАБЫ

local teleportTab = Window:Tab({
    Text = "Телепорты"
})

local itemsTab = Window:Tab({
    Text = "Предметы"
})

local visualTab = Window:Tab({
    Text = "Визуалы"
})

local miscTab = Window:Tab({
    Text = "Разное"
})

-- СЕКЦИИ
local shopSection = teleportTab:Section({
   Text = "Магазины"
})

local itemsSection = itemsTab:Section({
    Text = "Телепорт Предметов"
})

local itemsESPSection = visualTab:Section({
    Text = "Подсветка"
})

local miscSection = miscTab:Section({
    Text = "Плейс"
})


itemsESPSection:Toggle({
    Text = "Крышечки",
    Flag = "bottleCapESP",
    Callback = function(state)
        -- Удаление старых ESP и GUI
        for _, v in ipairs(trackedESP) do
            if v then v:Destroy() end
        end
        for _, v in ipairs(billboardGUIs) do
            if v then v:Destroy() end
        end
        table.clear(trackedESP)
        table.clear(billboardGUIs)

        if espConn then
            espConn:Disconnect()
            espConn = nil
        end

        if not state then return end

        local function createESP(model)
            if not model:IsA("Model") then return end
            local name = model.Name
            if name ~= "BottleCap" and name ~= "5Pile" and name ~= "15Pile" then return end

            local part = model:FindFirstChildWhichIsA("BasePart")
            if not part then return end

            -- Highlight
            local highlight = Instance.new("Highlight")
            highlight.Adornee = model
            highlight.FillColor = Color3.fromRGB(0, 170, 255)
            highlight.FillTransparency = 0.25
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = model
            table.insert(trackedESP, highlight)

            -- BillboardGui
            local billboard = Instance.new("BillboardGui")
            billboard.Adornee = part
            billboard.Size = UDim2.new(0, 100, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = model

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextStrokeTransparency = 0.5
            label.TextScaled = true
            label.Font = Enum.Font.Gotham

            if name == "BottleCap" then
                label.Text = "Крышечка"
            elseif name == "5Pile" then
                label.Text = "5х крышечек"
            elseif name == "15Pile" then
                label.Text = "15х крышечек"
            end

            label.Parent = billboard
            table.insert(billboardGUIs, billboard)
        end

        -- Пройтись по уже существующим
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name == "BottleCap" or obj.Name == "5Pile" or obj.Name == "15Pile") then
                createESP(obj)
            end
        end

        -- Новые объекты
        espConn = workspace.DescendantAdded:Connect(function(desc)
            if desc:IsA("Model") and (desc.Name == "BottleCap" or desc.Name == "5Pile" or desc.Name == "15Pile") then
                task.wait(0.1)
                createESP(desc)
            end
        end)
    end
})

miscSection:Button({
    Text = "Перезайти",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        local PlaceId = game.PlaceId
        local Player = game.Players.LocalPlayer

        TeleportService:Teleport(PlaceId, Player)
    end
})


itemsSection:Button({
    Text = "Крышечки",
    Callback = function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        local offsetY = 0.5
        local count = 0

        local function teleportObject(obj)
            local targetPart
            if obj:IsA("Model") then
                targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            elseif obj:IsA("BasePart") then
                targetPart = obj
            end

            if targetPart then
                targetPart.CFrame = hrp.CFrame * CFrame.new(0, offsetY * count, -5)
                count = count + 1
            end
        end

        local function findAndTeleportBottleCaps(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if child.Name == "BottleCap" then
                    teleportObject(child)
                end
                findAndTeleportBottleCaps(child)
            end
        end

        findAndTeleportBottleCaps(game)
    end
})

itemsSection:Button({
    Text = "Ценные вещи",
    Callback = function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        local offsetY = 0.5
        local count = 0

        local function teleportObject(obj)
            local targetPart
            if obj:IsA("Model") then
                targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            elseif obj:IsA("BasePart") then
                targetPart = obj
            end

            if targetPart then
                targetPart.CFrame = hrp.CFrame * CFrame.new(0, offsetY * count, -5)
                count = count + 1
            end
        end

        local targetNames = {
            RadioactiveBarrel = true,
            Shield = true,
            vaz = true,
            vaza = true,
            toilet = true
        }

        for _, obj in ipairs(workspace:GetChildren()) do
            if targetNames[obj.Name] then
                teleportObject(obj)
            end
        end
    end
})




-- Кнопка "Переработка"
shopSection:Button({
    Text = "Переработка",
    Callback = function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local scrapRecycler = workspace:FindFirstChild("RoadPrefabs") and workspace.RoadPrefabs:FindFirstChild("ScrapRecycler")

        if hrp and scrapRecycler then
            local targetPart = scrapRecycler.PrimaryPart

            if not targetPart then
                for _, part in ipairs(scrapRecycler:GetChildren()) do
                    if part:IsA("BasePart") then
                        targetPart = part
                        break
                    end
                end
            end

            if targetPart then
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 5, 0)
            else
                warn("В ScrapRecycler нет частей (BasePart) для телепортации")
            end
        else
            warn("Не найден ScrapRecycler или HumanoidRootPart")
        end
    end
})

-- Кнопка "Выгодный магазин"
shopSection:Button({
    Text = "Выгодный магазин",
    Callback = function()
        if goodshopPosition then
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = goodshopPosition
                print("Телепортирован к последней позиции Выгодного магазина")
            else
                warn("HumanoidRootPart не найден")
            end
        else
            warn("Позиция Выгодного магазина еще не найдена")
        end
    end
})

-- Новый таб "Авто-Фарм"
local autoFarmTab = Window:Tab({
    Text = "Авто-Фарм"
})

local loadingSection = autoFarmTab:Section({
    Text = "Прогрузка"
})

local autoLoadEnabled = false
local autoLoadThread = nil
local autoLoadInterval = 1 -- значение по умолчанию, секунд между телепортами

local roadsFolder = nil
local cachedRoads = {}
local cacheUpdateInterval = autoLoadInterval -- обновлять кеш раз в 0.1 секунд

local function updateRoadsCache()
    cachedRoads = {}
    if not roadsFolder then return end
    for _, child in ipairs(roadsFolder:GetChildren()) do
        local num = tonumber(child.Name)
        if num then
            table.insert(cachedRoads, {num = num, model = child})
        end
    end
    table.sort(cachedRoads, function(a,b) return a.num < b.num end)
end

loadingSection:Slider({
    Text = "Интервал (сек.)",
    Min = 0.1,
    Max = 5,
    Default = autoLoadInterval,
    Float = 1,
    Callback = function(value)
        autoLoadInterval = value
    end
})

loadingSection:Toggle({
    Text = "Авто-Прогрузка",
    Flag = "AutoLoadToggle",
    Callback = function(state)
        autoLoadEnabled = state
        if autoLoadEnabled then
            roadsFolder = Workspace:FindFirstChild("models")
            roadsFolder = roadsFolder and roadsFolder:FindFirstChild("roads")
            if not roadsFolder then
                warn("models.roads не найден")
                autoLoadEnabled = false
                return
            end

            updateRoadsCache() -- сразу кешируем

            autoLoadThread = coroutine.create(function()
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then
                    warn("HumanoidRootPart не найден")
                    autoLoadEnabled = false
                    return
                end

                local lastCacheUpdate = os.clock()
                local lastMaxNumber = -math.huge
                local teleportedToEnd = false

                while autoLoadEnabled do
                    -- Проверяем и телепортируем к End, если еще не телепортировались
                    if not teleportedToEnd then
                        local endPart = workspace:FindFirstChild("RoadPrefabs") 
                                        and workspace.RoadPrefabs:FindFirstChild("Canyon") 
                                        and workspace.RoadPrefabs.Canyon:FindFirstChild("Road") 
                                        and workspace.RoadPrefabs.Canyon.Road:FindFirstChild("End")
                        if endPart and endPart:IsA("BasePart") then
                            hrp.CFrame = endPart.CFrame + Vector3.new(0, 5, 0)
                            print("Телепортирован к RoadPrefabs.Canyon.Road.End")
                            teleportedToEnd = true
                            task.wait(1) -- пауза, чтобы игрок успел телепортироваться
                        end
                    end

                    -- Обновляем кеш каждые cacheUpdateInterval секунд
                    if os.clock() - lastCacheUpdate > cacheUpdateInterval then
                        updateRoadsCache()
                        lastCacheUpdate = os.clock()
                    end

                    local maxEntry = cachedRoads[#cachedRoads]
                    if maxEntry and maxEntry.num > lastMaxNumber then
                        local targetModel = maxEntry.model
                        local targetPart = targetModel.PrimaryPart
                        if not targetPart then
                            for _, part in ipairs(targetModel:GetChildren()) do
                                if part:IsA("BasePart") then
                                    targetPart = part
                                    break
                                end
                            end
                        end

                        if targetPart then
                            hrp.CFrame = targetPart.CFrame + Vector3.new(0, 5, 0)
                            print("Телепортирован к дороге с номером: " .. tostring(maxEntry.num))
                            lastMaxNumber = maxEntry.num
                        else
                            warn("В модели нет частей для телепортации")
                        end
                    end

                    task.wait(autoLoadInterval)
                end
            end)

            coroutine.resume(autoLoadThread)
        else
            autoLoadEnabled = false
        end
    end
})
