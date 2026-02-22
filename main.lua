
-- AutoJJs – versão com botão "Exclamação" e começando do 0 (compatível com Exército Brasileiro)

repeat wait() until game:IsLoaded()
wait(1.5)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ======= CRIA GUI NO COREGUI =======
local gui = Instance.new("ScreenGui")
gui.Name = "AutoJJs"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

-- ======= ENVIO NO CHAT (compatível com Exército Brasileiro) =======
local function getChatSender()
    local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
        return function(msg)
            pcall(function()
                chatEvents.SayMessageRequest:FireServer(msg, "All")
            end)
        end
    end

    local TextChatService = game:GetService("TextChatService")
    if TextChatService and TextChatService.ChatInputBarConfiguration then
        return function(msg)
            pcall(function()
                TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
            end)
        end
    end

    return function(msg)
        pcall(function()
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = "[AutoJJs] " .. msg,
                Color = Color3.fromRGB(255,255,255),
                Font = Enum.Font.SourceSansBold,
                TextSize = 18
            })
        end)
    end
end

local sendChat = getChatSender()

-- ======= CONVERSOR DE NÚMERO =======
local units = {"zero","um","dois","três","quatro","cinco","seis","sete","oito","nove",
"dez","onze","doze","treze","quatorze","quinze","dezesseis","dezessete","dezoito","dezenove"}
local tens = {"","","vinte","trinta","quarenta","cinquenta","sessenta","setenta","oitenta","noventa"}
local hundreds = {"","cento","duzentos","trezentos","quatrocentos","quinhentos","seiscentos","setecentos","oitocentos","novecentos"}

local function numberToWords(n)
    n = tonumber(n) or 0
    if n < 20 then return units[n+1]
    elseif n < 100 then
        local d, r = math.floor(n/10), n%10
        return r==0 and tens[d+1] or tens[d+1].." e "..units[r+1]
    elseif n == 100 then return "cem"
    elseif n < 1000 then
        local h, r = math.floor(n/100), n%100
        return r==0 and hundreds[h+1] or hundreds[h+1].." e "..numberToWords(r)
    elseif n < 10000 then
        local th, r = math.floor(n/1000), n%1000
        local prefix = (th==1) and "mil" or numberToWords(th).." mil"
        if r==0 then return prefix end
        return prefix.." "..numberToWords(r)
    end
    return tostring(n)
end

-- ======= VARIÁVEIS =======
local running, maxNum, delay, idx = false, 900, 1, 0
local formatMode = "grammar" -- "grammar" | "upper" | "exclaim"
local jumpAfterSend = false
local minimized = false

-- ======= GUI =======
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,260,0,370)
frame.Position = UDim2.new(0.5,-130,0.5,-180)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true
frame.BorderSizePixel = 0

local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1,0,0,28)
topBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
topBar.BorderSizePixel = 0

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1,-50,1,0)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1
title.Text = "AutoJJs"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(230,230,230)
title.TextXAlignment = Enum.TextXAlignment.Left

local minimizeBtn = Instance.new("TextButton", topBar)
minimizeBtn.Size = UDim2.new(0,30,0,20)
minimizeBtn.Position = UDim2.new(1,-35,0.5,-10)
minimizeBtn.Text = "-"
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
minimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 18
minimizeBtn.BorderSizePixel = 0

local container = Instance.new("Frame", frame)
container.Size = UDim2.new(1,0,1,-28)
container.Position = UDim2.new(0,0,0,28)
container.BackgroundTransparency = 1

local limitBox = Instance.new("TextBox", container)
limitBox.Size = UDim2.new(1,-20,0,28)
limitBox.Position = UDim2.new(0,10,0,10)
limitBox.PlaceholderText = "Limite (padrão 900)"
limitBox.Text = ""
limitBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
limitBox.TextColor3 = Color3.fromRGB(255,255,255)
limitBox.BorderSizePixel = 0

local delayBox = Instance.new("TextBox", container)
delayBox.Size = UDim2.new(1,-20,0,28)
delayBox.Position = UDim2.new(0,10,0,50)
delayBox.PlaceholderText = "Delay (padrão 1s)"
delayBox.Text = ""
delayBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
delayBox.TextColor3 = Color3.fromRGB(255,255,255)
delayBox.BorderSizePixel = 0

local startBtn = Instance.new("TextButton", container)
startBtn.Size = UDim2.new(1,-20,0,30)
startBtn.Position = UDim2.new(0,10,0,90)
startBtn.Text = "Iniciar"
startBtn.BackgroundColor3 = Color3.fromRGB(60,120,60)
startBtn.TextColor3 = Color3.fromRGB(255,255,255)
startBtn.Font = Enum.Font.SourceSansBold

local stopBtn = Instance.new("TextButton", container)
stopBtn.Size = UDim2.new(1,-20,0,30)
stopBtn.Position = UDim2.new(0,10,0,130)
stopBtn.Text = "Parar"
stopBtn.BackgroundColor3 = Color3.fromRGB(120,60,60)
stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
stopBtn.Font = Enum.Font.SourceSansBold

local progress = Instance.new("TextLabel", container)
progress.Size = UDim2.new(1,-20,0,28)
progress.Position = UDim2.new(0,10,0,170)
progress.BackgroundTransparency = 1
progress.TextColor3 = Color3.fromRGB(200,200,200)
progress.Font = Enum.Font.SourceSans
progress.TextSize = 16
progress.Text = "Progresso: 0 / 0"

-- Botões de formatação
local upperBtn = Instance.new("TextButton", container)
upperBtn.Size = UDim2.new(0.31,0,0,30)
upperBtn.Position = UDim2.new(0,10,0,210)
upperBtn.Text = "MAIÚSCULAS"
upperBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
upperBtn.TextColor3 = Color3.fromRGB(255,255,255)
upperBtn.Font = Enum.Font.SourceSansBold

local gramBtn = Instance.new("TextButton", container)
gramBtn.Size = UDim2.new(0.31,0,0,30)
gramBtn.Position = UDim2.new(0.34,0,0,210)
gramBtn.Text = "Gramatical"
gramBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
gramBtn.TextColor3 = Color3.fromRGB(255,255,255)
gramBtn.Font = Enum.Font.SourceSansBold

local exclBtn = Instance.new("TextButton", container)
exclBtn.Size = UDim2.new(0.31,0,0,30)
exclBtn.Position = UDim2.new(0.68,0,0,210)
exclBtn.Text = "Exclamação"
exclBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
exclBtn.TextColor3 = Color3.fromRGB(255,255,255)
exclBtn.Font = Enum.Font.SourceSansBold

local jumpBtn = Instance.new("TextButton", container)
jumpBtn.Size = UDim2.new(1,-20,0,30)
jumpBtn.Position = UDim2.new(0,10,0,250)
jumpBtn.Text = "Pular após enviar"
jumpBtn.BackgroundColor3 = Color3.fromRGB(90,90,60)
jumpBtn.TextColor3 = Color3.fromRGB(255,255,255)
jumpBtn.Font = Enum.Font.SourceSansBold

-- ======= FUNÇÕES =======
local function toggleButton(btn, state)
    btn.BackgroundColor3 = state and Color3.fromRGB(70,150,70) or Color3.fromRGB(60,60,60)
end

upperBtn.MouseButton1Click:Connect(function()
    formatMode = "upper"
    toggleButton(upperBtn, true)
    toggleButton(gramBtn, false)
    toggleButton(exclBtn, false)
end)

gramBtn.MouseButton1Click:Connect(function()
    formatMode = "grammar"
    toggleButton(upperBtn, false)
    toggleButton(gramBtn, true)
    toggleButton(exclBtn, false)
end)

exclBtn.MouseButton1Click:Connect(function()
    formatMode = "exclaim"
    toggleButton(upperBtn, false)
    toggleButton(gramBtn, false)
    toggleButton(exclBtn, true)
end)

jumpBtn.MouseButton1Click:Connect(function()
    jumpAfterSend = not jumpAfterSend
    toggleButton(jumpBtn, jumpAfterSend)
    jumpBtn.Text = jumpAfterSend and "Pular: ON" or "Pular após enviar"
end)

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    container.Visible = not minimized
    minimizeBtn.Text = minimized and "+" or "-"
    frame.Size = minimized and UDim2.new(0,260,0,28) or UDim2.new(0,260,0,370)
end)

startBtn.MouseButton1Click:Connect(function()
    if running then return end
    running = true
    idx = 0
    maxNum = tonumber(limitBox.Text)
    if not maxNum then maxNum = 900 end
    if maxNum < 0 then maxNum = 0 end
    delay = tonumber(delayBox.Text) or 1
    progress.Text = "Progresso: 0 / " .. maxNum
    spawn(function()
        -- enviar do 0 até maxNum (inclusivo)
        while running and idx <= maxNum do
            local msg = numberToWords(idx)
            if formatMode == "upper" then
                msg = string.upper(msg)
            elseif formatMode == "grammar" then
                -- capitaliza primeira letra e adiciona ponto se não já terminar com pontuação
                if #msg > 0 then
                    msg = msg:sub(1,1):upper() .. msg:sub(2)
                end
                -- adiciona ponto final se não terminar com ., ! ou ?
                local last = msg:sub(-1)
                if last ~= "." and last ~= "!" and last ~= "?" then
                    msg = msg .. "."
                end
            elseif formatMode == "exclaim" then
                if #msg > 0 then
                    msg = msg:sub(1,1):upper() .. msg:sub(2) .. " !"
                else
                    msg = " !"
                end
            end

            pcall(function() sendChat(msg) end)
            progress.Text = "Progresso: " .. idx .. " / " .. maxNum

            if jumpAfterSend then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.Jump = true
                end
            end

            idx = idx + 1
            wait(delay)
        end
        running = false
        progress.Text = "Concluído: " .. (idx-1) .. " / " .. maxNum
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    running = false
    progress.Text = "Parado em: " .. math.max(0, idx-1) .. " / " .. maxNum
end)y
