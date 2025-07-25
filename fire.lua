--// 📦 All-in-One: Infinite Road Trip Remote AI Caller with Nexus GUI
--// ✅ Features: Nexus GUI layout, OpenAI key entry, draggable UI, remote firing
--// 📌 Paste into KRNL and run

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--// 🧱 Mini Nexus GUI Core
local NexusGui = {}
function NexusGui:CreateWindow(titleText, size, position)
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    ScreenGui.Name = "NexusWindow"

    local Frame = Instance.new("Frame", ScreenGui)
    Frame.Size = size or UDim2.new(0, 450, 0, 350)
    Frame.Position = position or UDim2.new(0.5, -225, 0.5, -175)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true

    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 20

    return ScreenGui, Frame
end

--// 🔐 API Key Input
local function GetOpenAIKey()
    local gui, frame = NexusGui:CreateWindow("🔑 Enter OpenAI API Key", UDim2.new(0, 400, 0, 150))

    local input = Instance.new("TextBox", frame)
    input.Size = UDim2.new(1, -20, 0, 40)
    input.Position = UDim2.new(0, 10, 0, 50)
    input.PlaceholderText = "sk-..."
    input.TextColor3 = Color3.new(1, 1, 1)
    input.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    input.Font = Enum.Font.SourceSans
    input.TextSize = 18
    input.Text = ""

    local submit = Instance.new("TextButton", frame)
    submit.Size = UDim2.new(0, 100, 0, 30)
    submit.Position = UDim2.new(1, -110, 1, -40)
    submit.Text = "Submit"
    submit.TextColor3 = Color3.new(1, 1, 1)
    submit.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    submit.Font = Enum.Font.SourceSansBold
    submit.TextSize = 18

    local key = nil
    local waiting = true

    submit.MouseButton1Click:Connect(function()
        if #input.Text > 10 then
            key = input.Text
            waiting = false
            gui:Destroy()
        else
            input.Text = ""
            input.PlaceholderText = "Invalid key!"
        end
    end)

    while waiting do RunService.Heartbeat:Wait() end
    return key
end

--// 🌐 OpenAI Request
local function GetAIArgs(openAIKey, prompt)
    local body = HttpService:JSONEncode({
        model = "gpt-3.5-turbo",
        messages = {
            {role = "system", content = "ONLY return Lua table args like {speed = 999}. NO explanation."},
            {role = "user", content = prompt}
        },
        temperature = 0.1,
        max_tokens = 300
    })

    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. openAIKey
    }

    local success, result = pcall(function()
        return game:HttpPost("https://api.openai.com/v1/chat/completions", body, false, headers)
    end)
    
    if not success then return nil, "OpenAI API request failed" end

    local decoded = HttpService:JSONDecode(result)
    local raw = decoded.choices[1].message.content
    local luaCode = raw:match("%b{}") or raw
    local fn, err = loadstring("return " .. luaCode)
    if not fn then return nil, "Failed to parse AI response: "..err end

    local ok, args = pcall(fn)
    if not ok then return nil, "Failed to evaluate args: "..tostring(args) end

    return args
end

--// 🧠 Remote AI GUI
local function LaunchRemoteGUI(openAIKey)
    local gui, frame = NexusGui:CreateWindow("🚐 Remote AI Caller")

    local remotes = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, obj)
        end
    end

    local selectedRemote = nil

    local remoteLabel = Instance.new("TextLabel", frame)
    remoteLabel.Position = UDim2.new(0, 10, 0, 40)
    remoteLabel.Size = UDim2.new(1, -20, 0, 25)
    remoteLabel.Text = "Select a Remote:"
    remoteLabel.TextColor3 = Color3.new(1, 1, 1)
    remoteLabel.BackgroundTransparency = 1
    remoteLabel.Font = Enum.Font.SourceSans
    remoteLabel.TextSize = 18
    remoteLabel.TextXAlignment = Enum.TextXAlignment.Left

    local remoteList = Instance.new("ScrollingFrame", frame)
    remoteList.Position = UDim2.new(0, 10, 0, 65)
    remoteList.Size = UDim2.new(1, -20, 0, 100)
    remoteList.CanvasSize = UDim2.new(0, 0, 0, #remotes * 30)
    remoteList.ScrollBarThickness = 6
    remoteList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

    local layout = Instance.new("UIListLayout", remoteList)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    for _, remote in pairs(remotes) do
        local btn = Instance.new("TextButton", remoteList)
        btn.Size = UDim2.new(1, -10, 0, 25)
        btn.Text = remote:GetFullName()
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 16

        btn.MouseButton1Click:Connect(function()
            selectedRemote = remote
            for _, b in pairs(remoteList:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(0, 120, 80)
        end)
    end

    local promptBox = Instance.new("TextBox", frame)
    promptBox.Position = UDim2.new(0, 10, 0, 175)
    promptBox.Size = UDim2.new(1, -20, 0, 60)
    promptBox.PlaceholderText = "Prompt for OpenAI (e.g. set speed to 999)"
    promptBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    promptBox.TextColor3 = Color3.new(1, 1, 1)
    promptBox.Font = Enum.Font.SourceSans
    promptBox.TextSize = 16
    promptBox.TextWrapped = true
    promptBox.ClearTextOnFocus = false

    local preview = Instance.new("TextLabel", frame)
    preview.Position = UDim2.new(0, 10, 0, 240)
    preview.Size = UDim2.new(1, -20, 0, 60)
    preview.Text = "Waiting for AI..."
    preview.BackgroundTransparency = 1
    preview.TextColor3 = Color3.fromRGB(200, 255, 200)
    preview.Font = Enum.Font.SourceSans
    preview.TextSize = 14
    preview.TextWrapped = true

    local fireBtn = Instance.new("TextButton", frame)
    fireBtn.Position = UDim2.new(0, 10, 0, 310)
    fireBtn.Size = UDim2.new(1, -20, 0, 30)
    fireBtn.Text = "Fire Remote"
    fireBtn.TextColor3 = Color3.new(1, 1, 1)
    fireBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
    fireBtn.Font = Enum.Font.SourceSansBold
    fireBtn.TextSize = 18

    fireBtn.MouseButton1Click:Connect(function()
        if not selectedRemote then
            preview.Text = "❌ No remote selected!"
            return
        end
        if promptBox.Text == "" then
            preview.Text = "❌ Enter a prompt!"
            return
        end

        preview.Text = "🧠 Thinking..."
        local args, err = GetAIArgs(openAIKey, promptBox.Text)

        if not args then
            preview.Text = "❌ Error: " .. err
            return
        end

        preview.Text = "✅ Args: " .. HttpService:JSONEncode(args)

        pcall(function()
            if selectedRemote:IsA("RemoteEvent") then
                selectedRemote:FireServer(unpack(args))
            elseif selectedRemote:IsA("RemoteFunction") then
                selectedRemote:InvokeServer(unpack(args))
            end
        end)
    end)
end

--// 🚀 Launch!
local key = GetOpenAIKey()
LaunchRemoteGUI(key)
