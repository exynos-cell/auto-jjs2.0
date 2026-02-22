-- AutoJJs – Correção: botões independentes combinando corretamente + pulo funcional (mobile & Exército Brasileiro)

repeat task.wait() until game:IsLoaded()
task.wait(1.5)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- ======= CRIA GUI COM FALLBACK =======
local gui
for i = 1, 5 do
	pcall(function()
		gui = Instance.new("ScreenGui")
		gui.Name = "AutoJJs"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = game:GetService("CoreGui")
	end)
	if gui and gui.Parent then break end
	task.wait(0.5)
end

if not gui or not gui.Parent then
	gui = Instance.new("ScreenGui")
	gui.Name = "AutoJJs"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- garante que o GUI permaneça com parent válido
task.spawn(function()
	while task.wait(3) do
		if not gui.Parent then
			pcall(function() gui.Parent = game:GetService("CoreGui") end)
			if not gui.Parent then
				pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
			end
		end
	end
end)

-- ======= ENVIO NO CHAT (compatível) =======
local function getChatSender()
	-- 1. padrão
	local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
	if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
		return function(msg)
			pcall(function()
				chatEvents.SayMessageRequest:FireServer(msg, "All")
			end)
		end
	end
	-- 2. novo sistema
	local ok, TextChatService = pcall(function() return game:GetService("TextChatService") end)
	if ok and TextChatService and TextChatService.ChatInputBarConfiguration then
		return function(msg)
			pcall(function()
				local success, target = pcall(function() return TextChatService.ChatInputBarConfiguration.TargetTextChannel end)
				if success and target and target.SendAsync then
					target:SendAsync(msg)
				end
			end)
		end
	end
	-- 3. fallback visual (aparece localmente no chat)
	return function(msg)
		pcall(function()
			StarterGui:SetCore("ChatMakeSystemMessage", {
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
local useUpper, useGrammar, useExclaim, jumpAfterSend = false, false, false, false
local minimized = false

-- ======= GUI ELEMENTOS =======
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,240,0,350) -- um pouco menor
frame.Position = UDim2.new(0.5,-120,0.5,-170)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true
frame.BorderSizePixel = 0
frame.ZIndex = 5

local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1,0,0,28)
topBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
topBar.BorderSizePixel = 0
topBar.ZIndex = 6

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1,-50,1,0)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1
title.Text = "AutoJJs"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(230,230,230)
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 7

local minimizeBtn = Instance.new("TextButton", topBar)
minimizeBtn.Size = UDim2.new(0,28,0,20)
minimizeBtn.Position = UDim2.new(1,-34,0.5,-10)
minimizeBtn.Text = "-"
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
minimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 18
minimizeBtn.BorderSizePixel = 0
minimizeBtn.ZIndex = 7

local container = Instance.new("Frame", frame)
container.Size = UDim2.new(1,0,1,-28)
container.Position = UDim2.new(0,0,0,28)
container.BackgroundTransparency = 1
container.ZIndex = 5

local limitBox = Instance.new("TextBox", container)
limitBox.Size = UDim2.new(1,-20,0,30)
limitBox.Position = UDim2.new(0,10,0,8)
limitBox.PlaceholderText = "Limite (padrão 900)"
limitBox.Text = ""
limitBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
limitBox.TextColor3 = Color3.fromRGB(255,255,255)
limitBox.BorderSizePixel = 0
limitBox.ZIndex = 6

local delayBox = Instance.new("TextBox", container)
delayBox.Size = UDim2.new(1,-20,0,30)
delayBox.Position = UDim2.new(0,10,0,48)
delayBox.PlaceholderText = "Delay em s (padrão 1)"
delayBox.Text = ""
delayBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
delayBox.TextColor3 = Color3.fromRGB(255,255,255)
delayBox.BorderSizePixel = 0
delayBox.ZIndex = 6

local startBtn = Instance.new("TextButton", container)
startBtn.Size = UDim2.new(1,-20,0,32)
startBtn.Position = UDim2.new(0,10,0,90)
startBtn.Text = "Iniciar"
startBtn.BackgroundColor3 = Color3.fromRGB(60,120,60)
startBtn.TextColor3 = Color3.fromRGB(255,255,255)
startBtn.Font = Enum.Font.SourceSansBold
startBtn.ZIndex = 6

local stopBtn = Instance.new("TextButton", container)
stopBtn.Size = UDim2.new(1,-20,0,32)
stopBtn.Position = UDim2.new(0,10,0,128)
stopBtn.Text = "Parar"
stopBtn.BackgroundColor3 = Color3.fromRGB(120,60,60)
stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
stopBtn.Font = Enum.Font.SourceSansBold
stopBtn.ZIndex = 6

local progress = Instance.new("TextLabel", container)
progress.Size = UDim2.new(1,-20,0,26)
progress.Position = UDim2.new(0,10,0,168)
progress.BackgroundTransparency = 1
progress.TextColor3 = Color3.fromRGB(200,200,200)
progress.Font = Enum.Font.SourceSans
progress.TextSize = 14
progress.Text = "Progresso: 0 / 0"
progress.ZIndex = 6

-- Botões independentes (MAIÚSCULAS, GRAMATICAL, EXCLAMAÇÃO)
local btnRow = Instance.new("Frame", container)
btnRow.Size = UDim2.new(1, -20, 0, 36)
btnRow.Position = UDim2.new(0,10,0,200)
btnRow.BackgroundTransparency = 1
btnRow.ZIndex = 6

local upperBtn = Instance.new("TextButton", btnRow)
upperBtn.Size = UDim2.new(0.33, -6, 1, 0)
upperBtn.Position = UDim2.new(0, 0, 0, 0)
upperBtn.Text = "MAIÚSCULAS"
upperBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
upperBtn.TextColor3 = Color3.fromRGB(255,255,255)
upperBtn.Font = Enum.Font.SourceSansBold

local gramBtn = Instance.new("TextButton", btnRow)
gramBtn.Size = UDim2.new(0.33, -6, 1, 0)
gramBtn.Position = UDim2.new(0.335, 3, 0, 0)
gramBtn.Text = "Gramatical"
gramBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
gramBtn.TextColor3 = Color3.fromRGB(255,255,255)
gramBtn.Font = Enum.Font.SourceSansBold

local exclBtn = Instance.new("TextButton", btnRow)
exclBtn.Size = UDim2.new(0.33, -6, 1, 0)
exclBtn.Position = UDim2.new(0.67, 6, 0, 0)
exclBtn.Text = "Exclamação"
exclBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
exclBtn.TextColor3 = Color3.fromRGB(255,255,255)
exclBtn.Font = Enum.Font.SourceSansBold

local jumpBtn = Instance.new("TextButton", container)
jumpBtn.Size = UDim2.new(1,-20,0,32)
jumpBtn.Position = UDim2.new(0,10,0,244)
jumpBtn.Text = "Pular após enviar"
jumpBtn.BackgroundColor3 = Color3.fromRGB(90,90,60)
jumpBtn.TextColor3 = Color3.fromRGB(255,255,255)
jumpBtn.Font = Enum.Font.SourceSansBold
jumpBtn.ZIndex = 6

-- ======= FUNÇÕES AUXILIARES =======
local function toggleButtonVisual(btn, state)
	btn.BackgroundColor3 = state and Color3.fromRGB(70,150,70) or Color3.fromRGB(60,60,60)
end

local function ensureCharacter()
	local char = LocalPlayer.Character
	if not char or not char.Parent then
		char = LocalPlayer.CharacterAdded:Wait()
	end
	return char
end

local function doJump()
	-- tenta pular de formas que costumam funcionar no mobile/executors
	local ok, char = pcall(ensureCharacter)
	if not ok or not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		-- Método direto (mais confiável)
		pcall(function() hum.Jump = true end)
		-- fallback: ChangeState
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
	end
end

-- ======= LÓGICA DOS BOTÕES (independentes) =======
upperBtn.MouseButton1Click:Connect(function()
	useUpper = not useUpper
	toggleButtonVisual(upperBtn, useUpper)
end)

gramBtn.MouseButton1Click:Connect(function()
	useGrammar = not useGrammar
	toggleButtonVisual(gramBtn, useGrammar)
end)

exclBtn.MouseButton1Click:Connect(function()
	useExclaim = not useExclaim
	toggleButtonVisual(exclBtn, useExclaim)
end)

jumpBtn.MouseButton1Click:Connect(function()
	jumpAfterSend = not jumpAfterSend
	toggleButtonVisual(jumpBtn, jumpAfterSend)
	jumpBtn.Text = jumpAfterSend and "Pular: ON" or "Pular após enviar"
end)

minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	container.Visible = not minimized
	minimizeBtn.Text = minimized and "+" or "-"
	frame.Size = minimized and UDim2.new(0,240,0,28) or UDim2.new(0,240,0,350)
end)

-- ======= START / STOP =======
startBtn.MouseButton1Click:Connect(function()
	if running then return end
	running = true
	idx = 0
	maxNum = tonumber(limitBox.Text) or 900
	delay = tonumber(delayBox.Text) or 1
	if maxNum < 0 then maxNum = 0 end
	if delay <= 0 then delay = 0.05 end
	progress.Text = "Progresso: 0 / " .. maxNum

	task.spawn(function()
		-- loop INCLUINDO 0 até maxNum
		while running and idx <= maxNum do
			local base = numberToWords(idx)

			-- aplicar gramática: capitaliza primeira letra e garante pontuação (apenas se useGrammar true)
			if useGrammar then
				if #base > 0 then
					base = base:sub(1,1):upper() .. base:sub(2)
				end
				-- só adiciona ponto se não terminar com pontuação
				local last = base:sub(-1)
				if last ~= "." and last ~= "!" and last ~= "?" then
					base = base .. "."
				end
			end

			-- se exclaim for true: remover pontuação final existente e adicionar " !"
			if useExclaim then
				-- remove pontuação final .,!,? se houver, e também remove espaços finais
				base = base:gsub("%s+$", "") -- trim trailing spaces
				base = base:gsub("[%.%!%?]+$", "")
				-- garante primeira maiúscula caso grammar esteja ligado (se grammar não ligado, mantemos base)
				if #base > 0 and useGrammar then
					base = base:sub(1,1):upper() .. base:sub(2)
				end
				base = base .. " !"
			end

			-- se upper for true: transforma tudo em maiúsculas (faz por último para garantir que exclamação/ponto também fiquem em maiúsculas quando aplicável)
			if useUpper then
				base = string.upper(base)
			end

			pcall(function() sendChat(base) end)
			progress.Text = "Progresso: " .. idx .. " / " .. maxNum

			-- pular
			if jumpAfterSend then
				pcall(doJump)
			end

			idx = idx + 1
			task.wait(delay)
		end

		running = false
		progress.Text = "Concluído: " .. math.max(0, idx - 1) .. " / " .. maxNum
	end)
end)

stopBtn.MouseButton1Click:Connect(function()
	running = false
	progress.Text = "Parado em: " .. math.max(0, idx - 1) .. " / " .. maxNum
end)
