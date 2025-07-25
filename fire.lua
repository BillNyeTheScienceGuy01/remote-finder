-- Infinite Road Trip Remote AI Caller (KRNL - Fixed)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local selectedRemote = nil -- ⛏️ FIXED: Now using a real Lua variable

-- GUI: API Key Input
local function getApiKey()
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "ApiKeyGui"

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 400, 0, 150)
    frame.Position = UDim2.new(0.5, -200, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.Active = true
    frame.Draggable = true

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 40)
    label.Position = UDim2.new(0, 0, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = "Enter your OpenAI API key:"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 20

    local textBox = Instance.new("TextBox", frame)
    textBox.Size = UDim2.new(1, -20, 0, 40)
    textBox.Position = UDim2.new(0, 10, 0, 60)
    textBox.PlaceholderText = "sk-..."
    textBox.TextColor3 = Color3.new(1, 1, 1)
    textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = 18

    local submit = Instance.new("TextButton", frame)
    submit.Size = UDim2.new(0, 100, 0, 30)
    submit.Position = UDim2.new(1, -110, 1, -40)
    submit.Text = "Submit"
    submit.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    submit.TextColor3 = Color3.new(1, 1, 1)
    submit.Font = Enum.Font.SourceSansBold
    submit.TextSize = 18

    local enteredKey
    local waiting = true

    submit.MouseButton1Click:Connect(function()
        local key = textBox.Text
        if key and #key > 10 then
            enteredKey = key
            waiting = false
            gui:Destroy()
        else
            textBox.Text = ""
            textBox.PlaceholderText = "Invalid key, try again."
        end
    end)

    while waiting do
        RunService.Heartbeat:Wait()
    end

    return enteredKey
end

local openAIKey = getApiKey()

-- GUI: Main Panel
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "RemoteAI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 450, 0, 350)
frame.Position = UDim2.new(0.5, -225, 0.5, -175)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 35)
title.Text = "🚀 Infinite Road Trip Remote AI Caller"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.BackgroundTransparency = 1

-- Remote Dropdown
local dropdown = Instance.new("ScrollingFrame", frame)
dropdown.Size = UDim2.new(1, -20, 0, 100)
dropdown.Position = UDim2.new(0, 10, 0, 50)
dropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
dropdown.ScrollBarThickness = 6
dropdown.BorderSizePixel = 0

local layout = Instance.new("UIListLayout", dropdown)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Prompt input
local promptBox = Instance.new("TextBox", frame)
promptBox.Size = UDim2.new(1, -20, 0, 60)
promptBox.Position = UDim2.new(0, 10, 0, 160)
promptBox.PlaceholderText = "ex: set speed to 999"
promptBox.TextColor3 = Color3.new(1, 1, 1)
promptBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
promptBox.Font = Enum.Font.SourceSans
promptBox.TextSize = 16
promptBox.TextWrapped = true
promptBox.ClearTextOnFocus = false

-- Fire button
local fireBtn = Instance.new("TextButton", frame)
fireBtn.Size = UDim2.new(1, -20, 0, 40)
fireBtn.Position = UDim2.new(0, 10, 0, 240)
fireBtn.Text = "🔥 Fire Remote with AI Args"
fireBtn.TextColor3 = Color3.new(1, 1, 1)
fireBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 70)
fireBtn.Font = Enum.Font.SourceSansBold
fireBtn.TextSize = 18

-- Scan and fill remotes
local function scanRemotes()
    local remotes = {}
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, obj)
        end
    end

    for _, btn in pairs(dropdown:GetChildren()) do
        if btn:IsA("TextButton") then btn:Destroy() end
    end

    for _, remote in ipairs(remotes) do
        local btn = Instance.new("TextButton", dropdown)
        btn.Size = UDim2.new(1, -10, 0, 25)
        btn.Text = remote:GetFullName()
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 16

        btn.MouseButton1Click:Connect(function()
            for _, b in pairs(dropdown:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(90, 140, 90)
            selectedRemote = remote
            print("[SELECTED]:", remote:GetFullName())
        end)
    end

    dropdown.CanvasSize = UDim2.new(0, 0, 0, #remotes * 30)
end

scanRemotes()

-- Fire logic
fireBtn.MouseButton1Click:Connect(function()
    if not selectedRemote then
        warn("No remote selected")
        return
    end
    if promptBox.Text == "" then
        warn("Prompt is empty")
        return
    end

    local request = {
        model = "gpt-3.5-turbo",
        messages = {
            {
                role = "system",
                content = "You are an expert Roblox scripter. When given a prompt about firing a Roblox remote with arguments, respond ONLY with a valid Lua table of the arguments to use, no explanations."
            },
            {
                role = "user",
                content = promptBox.Text
            }
        },
        temperature = 0.2,
        max_tokens = 300
    }

    local body = HttpService:JSONEncode(request)
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. openAIKey
    }

    local success, response = pcall(function()
        return game:HttpPost("https://api.openai.com/v1/chat/completions", body, false, headers)
    end)

    if not success then
        warn("OpenAI failed:", response)
        return
    end

    local json = HttpService:JSONDecode(response)
    local rawLua = json.choices[1].message.content
    print("[OPENAI RAW]:", rawLua)

    local fn, err = loadstring("return " .. rawLua)
    if not fn then
        warn("Failed to parse AI output:", err)
        return
    end

    local ok, args = pcall(fn)
    if not ok then
        warn("Failed to convert args:", args)
        return
    end

    local fireOk, fireErr = pcall(function()
        if selectedRemote:IsA("RemoteEvent") then
            selectedRemote:FireServer(table.unpack(args))
        elseif selectedRemote:IsA("RemoteFunction") then
            selectedRemote:InvokeServer(table.unpack(args))
        end
    end)

    if not fireOk then
        warn("Remote fire failed:", fireErr)
    else
        print("🔥 Fired remote with AI-generated args!")
    end
end)
