-- AutoJJs – Script atualizado com contador visual de progresso

-- ====== Configurações iniciais ======
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function getChatSender()
    local success, mod = pcall(function()
        local events = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if events and events:FindFirstChild("SayMessageRequest") then
            return function(msg)
                events.SayMessageRequest:FireServer(msg, "All")
            end
        end
        local TextChatService = game:GetService("TextChatService")
        if TextChatService and TextChatService:FindFirstChild("SayMessage") then
            return function(msg)
                pcall(function() TextChatService.SayMessage:Fire(msg) end)
            end
        end
        return nil
    end)
    if success and mod then return mod end
    if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest") then
        local events = ReplicatedStorage.DefaultChatSystemChatEvents
        return function(msg) pcall(function() events.SayMessageRequest:FireServer(msg, "All") end) end
    end
    return function(msg)
        pcall(function() print("Tentativa de enviar chat: "..tostring(msg)) end)
    end
end

local sendChat = getChatSender()

-- ====== Conversor de número ======
local units = {"zero","um","dois","três","quatro","cinco","seis","sete","oito","nove",
               "dez","onze","doze","treze","quatorze","quinze","dezesseis","dezessete","dezoito","dezenove"}
local tens = {"","","vinte","trinta","quarenta","cinquenta","sessenta","setenta","oitenta","noventa"}
local hundreds = {"","cento","duzentos","trezentos","quatrocentos","quinhentos","seiscentos","setecentos","oitocentos","novecentos"}

local function numberToWords(n)
    n = tonumber(n) or 0
    if n < 0 then return "menos "..numberToWords(-n) end
    if n < 20 then return units[n+1] end
    if n < 100 then
        local d = math.floor(n / 10)
        local r = n % 10
        if r == 0 then return tens[d+1] end
        return tens[d+1] .. " e " .. units[r+1]
    end
    if n == 100 then return "cem" end
    if n < 1000 then
        local h = math.floor(n / 100)
        local rem = n % 100
        local prefix = hundreds[h+1]
        if rem == 0 then return prefix end
        return prefix .. " e " .. numberToWords(rem)
    end
    if n < 10000 then
        local th = math.floor(n / 1000)
        local rem = n % 1000
        local prefix = (th == 1) and "mil" or (numberToWords(th) .. " mil")
        if rem == 0 then return prefix end
        if rem < 100 then
            return prefix .. " e " .. numberToWords(rem)
        else
            return prefix .. " " .. numberToWords(rem)
        end
    end
    return tostring(n)
end

-- ====== Estados ======
local isRunning = false
local sendUpper = false
local sendGrammar = true
local sendLower = false
local jumpAfterSend = false
local maxNumber = 50
local delayBetween = 1.0
local currentIndex = 0

-- ====== GUI ======
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoJJsGUI_"..tostring(math.random(1000,9999))
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 440)
Frame.Position = UDim2.new(0.5, -150, 0.5, -220)
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
TopBar.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "AutoJJs"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(230,230,230)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, 0, 1, -36)
Container.Position = UDim2.new(0, 0, 0, 36)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 6
Container.Parent = Frame

local Layout = Instance.new("UIListLayout")
Layout.Parent = Container
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 8)

local function createLabel(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -18, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 15
    lbl.TextColor3 = Color3.fromRGB(220,220,220)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Container
    return lbl
end

local function createButton(text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -18, 0, 36)
    btn.BackgroundColor3 = color or Color3.fromRGB(60,60,60)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = text
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(245,245,245)
    btn.Parent = Container
    return btn
end

createLabel("Limite máximo:")
local LimitBox = Instance.new("TextBox")
LimitBox.Size = UDim2.new(1, -18, 0, 34)
LimitBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
LimitBox.BorderSizePixel = 0
LimitBox.Font = Enum.Font.SourceSans
LimitBox.TextSize = 16
LimitBox.TextColor3 = Color3.fromRGB(240,240,240)
LimitBox.Text = tostring(maxNumber)
LimitBox.ClearTextOnFocus = false
LimitBox.Parent = Container

createLabel("Delay (segundos):")
local DelayBox = Instance.new("TextBox")
DelayBox.Size = UDim2.new(1, -18, 0, 34)
DelayBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
DelayBox.BorderSizePixel = 0
DelayBox.Font = Enum.Font.SourceSans
DelayBox.TextSize = 16
DelayBox.TextColor3 = Color3.fromRGB(240,240,240)
DelayBox.Text = tostring(delayBetween)
DelayBox.ClearTextOnFocus = false
DelayBox.Parent = Container

createLabel("Controles:")
local StartBtn = createButton("Iniciar", Color3.fromRGB(60,120,60))
local StopBtn = createButton("Parar", Color3.fromRGB(120,60,60))

-- === Contador visual ===
local ProgressLabel = createLabel("Progresso: 0 / 0")

local InfoLabel = createLabel("Painel pronto. Teste com limites pequenos.")

-- ====== Funções principais ======
StartBtn.MouseButton1Click:Connect(function()
    if isRunning then return end
    local n = tonumber(LimitBox.Text) or maxNumber
    local d = tonumber(DelayBox.Text) or delayBetween
    maxNumber = math.max(1, math.floor(n))
    delayBetween = math.max(0.05, tonumber(d))
    currentIndex = 0
    ProgressLabel.Text = "Progresso: 0 / " .. maxNumber
    isRunning = true
    spawn(function()
        while isRunning and currentIndex < maxNumber do
            currentIndex += 1
            local msg = numberToWords(currentIndex)
            if sendUpper then msg = string.upper(msg)
            elseif sendLower then msg = string.lower(msg) end
            pcall(function() sendChat(msg) end)
            ProgressLabel.Text = "Progresso: " .. currentIndex .. " / " .. maxNumber
            wait(delayBetween)
        end
        isRunning = false
        ProgressLabel.Text = "Progresso: concluído (" .. currentIndex .. " / " .. maxNumber .. ")"
    end)
end)

StopBtn.MouseButton1Click:Connect(function()
    isRunning = false
    ProgressLabel.Text = "Progresso: interrompido (" .. currentIndex .. " / " .. maxNumber .. ")"
end)
