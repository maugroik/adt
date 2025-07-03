local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Rain-Design/Unnamed/main/Library.lua'))()
Library.Theme = "Tokyo Night"
local Flags = Library.Flags
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local trackedESP = {}
local billboardGUIs = {}
local espConn

local goodshopPosition = nil
local autoCheckEnabled = true

local autoLoadEnabled = false
local autoLoadThread = nil
local autoLoadInterval = 1 -- сек между перемещениями

local roadsFolder = nil
local cachedRoads = {}
local cacheUpdateInterval = 1

-- Функция проверки близости по позиции (чтобы не делать твины если уже рядом)
local function isClose(cframe1, cframe2, tolerance)
    tolerance = tolerance or 1
    return (cframe1.Position - cframe2.Position).Magnitude <= tolerance
end

-- Функция плавного перемещения
local function tweenToPosition(hrp, targetCFrame, duration)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    return tween
end

-- Обновляем позицию выгодного магазина
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
                    if not goodshopPosition or not isClose(goodshopPosition, newPosition, 0.01) then
                        goodshopPosition = newPosition
                        print("Обновлена позиция Выгодного магазина:", goodshopPosition)
                    end
                    break
                end
            end
        end
    end
end

-- Корутина для постоянного обновления позиции выгодного магазина
coroutine.wrap(function()
    while autoCheckEnabled do
        updateGoodshopPosition()
        wait(1)
    end
end)()

local Window = Library:Window({
   Text = "ADT"
})

-- Табы
local teleportTab = Window:Tab({Text = "Телепорты"})
local itemsTab = Window:Tab({Text = "Предметы"})
local visualTab = Window:Tab({Text = "Визуалы"})
local miscTab = Window:Tab({Text = "Разное"})
local autoFarmTab = Window:Tab({Text = "Авто-Фарм"})

-- Секции
local shopSection = teleportTab:Section({Text = "Магазины"})
local itemsSection = itemsTab:Section({Text = "Телепорт Предметов"})
local itemsESPSection = visualTab:Section({Text = "Подсветка"})
local miscSection = miscTab:Section({Text = "Плейс"})
local loadingSection = autoFarmTab:Section({Text = "Прогрузка"})

-- ESP Toggle
itemsESPSection:Toggle({
    Text = "Крышечки",
    Flag = "bottleCapESP",
    Callback = function(state)
        -- Очистка предыдущих ESP и GUI
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

        -- Обрабатываем уже существующие модели
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name == "BottleCap" or obj.Name == "5Pile" or obj.Name == "15Pile") then
                createESP(obj)
            end
        end

        -- Обработка новых моделей
        espConn = workspace.DescendantAdded:Connect(function(desc)
            if desc:IsA("Model") and (desc.Name == "BottleCap" or desc.Name == "5Pile" or desc.Name == "15Pile") then
                task.wait(0.1)
                createESP(desc)
            end
        end)
    end
})

-- Кнопка перезахода
miscSection:Button({
    Text = "Перезайти",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        local PlaceId = game.PlaceId
        local Player = game.Players.LocalPlayer

        TeleportService:Teleport(PlaceId, Player)
    end
})

-- Телепорт крышечек
itemsSection:Button({
    Text = "Крышечки",
    Callback = function()
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

-- Телепорт ценных вещей
itemsSection:Button({
    Text = "Ценные вещи",
    Callback = function()
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
            GreenBox = true,
            CopperOre = true,
            MysteriousBox = true,
            Fan = true,
        }

        local function findAndTeleportValuables(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if targetNames[child.Name] then
                    teleportObject(child)
                end
                findAndTeleportValuables(child)
            end
        end

        findAndTeleportValuables(game)
    end
})

-- Автопрогрузка

-- Обновляем кеш дорог
local function updateRoadsCache()
    cachedRoads = {}

    roadsFolder = workspace:FindFirstChild("RoadPrefabs") and workspace.RoadPrefabs:FindFirstChild("Canyon") and workspace.RoadPrefabs.Canyon:FindFirstChild("Road")

    if not roadsFolder then
        warn("Папка дорог не найдена")
        return
    end

    for _, roadModel in ipairs(roadsFolder:GetChildren()) do
        if roadModel:IsA("Model") then
            local numValue = roadModel:FindFirstChild("num")
            if numValue and numValue:IsA("IntValue") then
                table.insert(cachedRoads, {num = numValue.Value, model = roadModel})
            end
        end
    end

    table.sort(cachedRoads, function(a, b)
        return a.num < b.num
    end)
end

-- Функция запуска автопрогрузки
local function startAutoLoad()
    if autoLoadThread and coroutine.status(autoLoadThread) == "running" then
        return -- Уже работает
    end

    autoLoadEnabled = true

    autoLoadThread = coroutine.create(function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")

        if not hrp then
            warn("HumanoidRootPart не найден")
            autoLoadEnabled = false
            return
        end

        local lastCacheUpdate = os.clock()
        local lastMaxNumber = -math.huge
        local teleportedToEnd = false

        while autoLoadEnabled do
            if not teleportedToEnd then
                local endPart = roadsFolder and roadsFolder:FindFirstChild("End")
                if endPart and endPart:IsA("BasePart") then
                    local targetCFrame = endPart.CFrame + Vector3.new(0, 5, 0)
                    if not isClose(hrp.CFrame, targetCFrame) then
                        local tween = tweenToPosition(hrp, targetCFrame, autoLoadInterval)
                        tween.Completed:Wait()
                        print("Плавно переместился к End")
                    end
                    teleportedToEnd = true
                end
            end

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
                    local targetCFrame = targetPart.CFrame + Vector3.new(0, 5, 0)
                    if not isClose(hrp.CFrame, targetCFrame) then
                        local tween = tweenToPosition(hrp, targetCFrame, autoLoadInterval)
                        tween.Completed:Wait()
                        print("Плавно переместился к дороге №" .. tostring(maxEntry.num))
                        lastMaxNumber = maxEntry.num
                    end
                else
                    warn("В модели нет частей для телепортации")
                end
            end

            task.wait(autoLoadInterval)
        end
    end)

    coroutine.resume(autoLoadThread)
end

-- Остановка автопрогрузки
local function stopAutoLoad()
    autoLoadEnabled = false
end

loadingSection:Toggle({
    Text = "Авто-прогрузка",
    Flag = "autoLoadToggle",
    Callback = function(state)
        if state then
            startAutoLoad()
        else
            stopAutoLoad()
        end
    end
})

loadingSection:Slider({
    Text = "Интервал перемещения (сек)",
    Flag = "autoLoadInterval",
    Min = 0.1,
    Max = 5,
    Default = 1,
    Decimals = 2,
    Callback = function(value)
        autoLoadInterval = value
    end
})

Library:Init()
