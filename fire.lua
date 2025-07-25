-- Infinite Road Trip Remote AI Caller + Preview (KRNL)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- === API Key GUI ===
local function getApiKey()
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "APIKeyPrompt"

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 400, 0, 150)
    frame.Position = UDim2.new(0.5, -200, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.Draggable, frame.Active = true, true

    local label = Instance.new("TextLabel", frame)
    label.Text = "Enter your OpenAI API Key:"
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Position = UDim2.new(0, 0, 0, 10)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 20

    local textbox = Instance.new("TextBox", frame)
    textbox.Size = UDim2.new(1, -20, 0, 30)
    textbox.Position = UDim2.new(0, 10, 0, 50)
    textbox.PlaceholderText = "sk-..."
    textbox.TextColor3 = Color3.new(1,1,1)
    textbox.BackgroundColor3 = Color3.fromRGB(40,40,40)
    textbox.TextSize = 18
    textbox.Text = ""

    local button = Instance.new("TextButton", frame)
    button.Text = "Submit"
    button.Size = UDim2.new(0, 100, 0, 30)
    button.Position = UDim2.new(1, -110, 1, -40)
    button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    button.TextColor3 = Color3.new(1,1,1)

    local key, done = nil, false

    button.MouseButton1Click:Connect(function()
        if textbox.Text:match("^sk%-") then
            key = textbox.Text
            done = true
            gui:Destroy()
        else
            textbox.Text = ""
            textbox.PlaceholderText = "Invalid key, try again"
        end
    end)

    while not done do RunService.Heartbeat:Wait() end
    return key
end

local openAIKey = getApiKey()

-- === Variables ===
local selectedRemote = nil
local remotes = {}

-- === Main GUI ===
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "RemoteAIGui"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 480, 0, 420)
frame.Position = UDim2.new(0.5, -240, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Draggable, frame.Active = true, true

local title = Instance.new("TextLabel", frame)
title.Text = "🚐 Infinite Road Trip AI Remote Caller"
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20

-- Remote List
local dropdown = Instance.new("ScrollingFrame", frame)
dropdown.Position = UDim2.new(0, 10, 0, 45)
dropdown.Size = UDim2.new(1, -20, 0, 100)
dropdown.BackgroundColor3 = Color3.fromRGB(35,35,35)
dropdown.ScrollBarThickness = 6
local listLayout = Instance.new("UIListLayout", dropdown)

-- Prompt Input
local promptBox = Instance.new("TextBox", frame)
promptBox.Position = UDim2.new(0, 10, 0, 155)
promptBox.Size = UDim2.new(1, -20, 0, 60)
promptBox.PlaceholderText = "Prompt (e.g. speed = 999)"
promptBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
promptBox.TextColor3 = Color3.new(1,1,1)
promptBox.TextSize = 16
promptBox.TextWrapped = true
promptBox.ClearTextOnFocus = false

-- Live Preview
local previewLabel = Instance.new("TextLabel", frame)
previewLabel.Position = UDim2.new(0, 10, 0, 225)
previewLabel.Size = UDim2.new(1, -20, 0, 80)
previewLabel.Text = "[Awaiting AI response...]"
previewLabel.TextWrapped = true
previewLabel.TextXAlignment = Enum.TextXAlignment.Left
previewLabel.BackgroundTransparency = 1
previewLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
previewLabel.Font = Enum.Font.Code
previewLabel.TextSize = 14

-- Fire Button
local fireBtn = Instance.new("TextButton", frame)
fireBtn.Position = UDim2.new(0, 10, 0, 320)
fireBtn.Size = UDim2.new(1, -20, 0, 40)
fireBtn.Text = "⚡ Fire Remote with AI Args"
fireBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
fireBtn.TextColor3 = Color3.new(1,1,1)
fireBtn.Font = Enum.Font.SourceSansBold
fireBtn.TextSize = 20

-- === Populate Remote List ===
for _, obj in ipairs(game:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        table.insert(remotes, obj)
    end
end

for _, remote in ipairs(remotes) do
    local btn = Instance.new("TextButton", dropdown)
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.Text = remote:GetFullName()
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 14

    btn.MouseButton1Click:Connect(function()
        selectedRemote = remote
        for _, b in pairs(dropdown:GetChildren()) do
            if b:IsA("TextButton") then
                b.BackgroundColor3 = Color3.fromRGB(60,60,60)
            end
        end
        btn.BackgroundColor3 = Color3.fromRGB(90,140,90)
    end)
end

dropdown.CanvasSize = UDim2.new(0, 0, 0, #remotes * 26)

-- === Fire Button Logic ===
fireBtn.MouseButton1Click:Connect(function()
    if not selectedRemote then
        previewLabel.Text = "⚠️ No remote selected!"
        return
    end
    if promptBox.Text == "" then
        previewLabel.Text = "⚠️ Enter a prompt first!"
        return
    end

    -- API Request
    local body = HttpService:JSONEncode({
        model = "gpt-3.5-turbo",
        messages = {
            { role = "system", content = "ONLY respond with a valid Lua table like {speed = 999}, and nothing else." },
            { role = "user", content = promptBox.Text }
        },
        temperature = 0.1,
        max_tokens = 300
    })

    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer "..openAIKey
    }

    local success, response = pcall(function()
        return game:HttpPost("https://api.openai.com/v1/chat/completions", body, false, headers)
    end)

    if not success then
        previewLabel.Text = "❌ OpenAI error: "..tostring(response)
        return
    end

    local parsed = HttpService:JSONDecode(response)
    local rawLua = parsed.choices[1].message.content
    local code = rawLua:match("{.*}") or rawLua

    previewLabel.Text = "🧠 AI Args:\n"..code

    local fn, err = loadstring("return "..code)
    if not fn then
        previewLabel.Text = "❌ Lua parse error:\n"..err
        return
    end

    local ok, args = pcall(fn)
    if not ok then
        previewLabel.Text = "❌ Lua exec error:\n"..tostring(args)
        return
    end

    local fireSuccess, fireErr = pcall(function()
        if selectedRemote:IsA("RemoteEvent") then
            selectedRemote:FireServer(table.unpack(args))
        else
            selectedRemote:InvokeServer(table.unpack(args))
        end
    end)

    if fireSuccess then
        previewLabel.Text = "✅ Fired "..selectedRemote.Name.." with args:\n"..code
    else
        previewLabel.Text = "❌ Remote fire error:\n"..tostring(fireErr)
    end
end)
