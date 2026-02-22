local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Função de envio no chat
local function getChatSender()
    local ok, sender = pcall(function()
        local e = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if e and e:FindFirstChild("SayMessageRequest") then
            return function(msg) e.SayMessageRequest:FireServer(msg, "All") end
        end
        local tcs = game:GetService("TextChatService")
        if tcs and tcs:FindFirstChild("SayMessage") then
            return function(msg) pcall(function() tcs.SayMessage:Fire(msg) end) end
        end
    end)
    return sender or function(m) print("CHAT:", m) end
end

local sendChat = getChatSender()

-- Conversor de número para extenso
local units = {"zero","um","dois","três","quatro","cinco","seis","sete","oito","nove",
"dez","onze","doze","treze","quatorze","quinze","dezesseis","dezessete","dezoito","dezenove"}
local tens = {"","", "vinte","trinta","quarenta","cinquenta","sessenta","setenta","oitenta","noventa"}
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

-- Variáveis de controle
local running, maxNum, delay, idx = false, 900, 1, 0
local useUpper = false
local jumpAfterSend = false

-- GUI
local gui = Instance.new("ScreenGui", PlayerGui)
gui.ResetOnSpawn = false
gui.Name = "AutoJJs"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,260,0,320)
frame.Position = UDim2.new(0.5,-130,0.5,-160)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,26)
title.BackgroundColor3 = Color3.fromRGB(20,20,20)
title.Text = "AutoJJs"
title.TextColor3 = Color3.fromRGB(230,230,230)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20

local limitBox = Instance.new("TextBox", frame)
limitBox.Size = UDim2.new(1,-20,0,28)
limitBox.Position = UDim2.new(0,10,0,40)
limitBox.PlaceholderText = "Limite (padrão 900)"
limitBox.Text = ""
limitBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
limitBox.TextColor3 = Color3.fromRGB(255,255,255)
limitBox.BorderSizePixel = 0

local delayBox = Instance.new("TextBox", frame)
delayBox.Size = UDim2.new(1,-20,0,28)
delayBox.Position = UDim2.new(0,10,0,80)
delayBox.PlaceholderText = "Delay (padrão 1s)"
delayBox.Text = ""
delayBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
delayBox.TextColor3 = Color3.fromRGB(255,255,255)
delayBox.BorderSizePixel = 0

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(1,-20,0,30)
startBtn.Position = UDim2.new(0,10,0,120)
startBtn.Text = "Iniciar"
startBtn.BackgroundColor3 = Color3.fromRGB(60,120,60)
startBtn.TextColor3 = Color3.fromRGB(255,255,255)
startBtn.Font = Enum.Font.SourceSansBold

local stopBtn = Instance.new("TextButton", frame)
stopBtn.Size = UDim2.new(1,-20,0,30)
stopBtn.Position = UDim2.new(0,10,0,160)
stopBtn.Text = "Parar"
stopBtn.BackgroundColor3 = Color3.fromRGB(120,60,60)
stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
stopBtn.Font = Enum.Font.SourceSansBold

local progress = Instance.new("TextLabel", frame)
progress.Size = UDim2.new(1,-20,0,28)
progress.Position = UDim2.new(0,10,0,200)
progress.BackgroundTransparency = 1
progress.TextColor3 = Color3.fromRGB(200,200,200)
progress.Font = Enum.Font.SourceSans
progress.TextSize = 16
progress.Text = "Progresso: 0 / 0"

-- Botão de formatação maiúscula
local upperBtn = Instance.new("TextButton", frame)
upperBtn.Size = UDim2.new(0.48,0,0,30)
upperBtn.Position = UDim2.new(0,10,0,240)
upperBtn.Text = "Maiúsculas"
upperBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
upperBtn.TextColor3 = Color3.fromRGB(255,255,255)
upperBtn.Font = Enum.Font.SourceSansBold

-- Botão de formatação gramatical
local gramBtn = Instance.new("TextButton", frame)
gramBtn.Size = UDim2.new(0.48,0,0,30)
gramBtn.Position = UDim2.new(0.52,0,0,240)
gramBtn.Text = "Gramatical"
gramBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
gramBtn.TextColor3 = Color3.fromRGB(255,255,255)
gramBtn.Font = Enum.Font.SourceSansBold

-- Botão de pular
local jumpBtn = Instance.new("TextButton", frame)
jumpBtn.Size = UDim2.new(1,-20,0,30)
jumpBtn.Position = UDim2.new(0,10,0,280)
jumpBtn.Text = "Pular após enviar"
jumpBtn.BackgroundColor3 = Color3.fromRGB(90,90,60)
jumpBtn.TextColor3 = Color3.fromRGB(255,255,255)
jumpBtn.Font = Enum.Font.SourceSansBold

-- Lógica para formatação
upperBtn.MouseButton1Click:Connect(function()
    useUpper = true
end)

gramBtn.MouseButton1Click:Connect(function()
    useUpper = false
end)

-- Lógica para iniciar
startBtn.MouseButton1Click:Connect(function()
    if running then return end
    running = true
    idx = 0
    maxNum = tonumber(limitBox.Text) or 900
    delay = tonumber(delayBox.Text) or 1
    progress.Text = "Progresso: 0 / " .. maxNum
    spawn(function()
        while running and idx < maxNum do
            idx += 1
            local msg = numberToWords(idx)
            if useUpper then
                msg = string.upper(msg)
            else
                -- formatação gramatical: capitaliza primeira letra, ponto final
                msg = msg:sub(1,1):upper() .. msg:sub(2) .. "."
            end
            pcall(function() sendChat(msg) end)
            progress.Text = "Progresso: " .. idx .. " / " .. maxNum
            if jumpAfterSend then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.Jump = true
                end
            end
            wait(delay)
        end
        running = false
        progress.Text = "Concluído: " .. idx .. " / " .. maxNum
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    running = false
    progress.Text = "Parado em: " .. idx .. " / " .. maxNum
end)

jumpBtn.MouseButton1Click:Connect(function()
    jumpAfterSend = not jumpAfterSend
    if jumpAfterSend then
        jumpBtn.Text = "Pular: ON"
    else
        jumpBtn.Text = "Pular após enviar"
    end
end)
