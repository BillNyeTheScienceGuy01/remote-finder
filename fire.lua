-- Infinite Road Trip Remote AI Caller (KRNL + Nexus GUI)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Load Nexus GUI (make sure NexusGui is in ReplicatedStorage)
local NexusGui = require(game:GetService("ReplicatedStorage"):WaitForChild("NexusGui"))

-- OpenAI API key input GUI using Nexus GUI
local function getApiKey()
    local ApiGui = NexusGui.CreateGui()
    ApiGui.Name = "ApiKeyGui"

    local frame = NexusGui.CreateFrame()
    frame.Size = UDim2.new(0, 400, 0, 150)
    frame.Position = UDim2.new(0.5, -200, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = ApiGui

    local label = NexusGui.CreateLabel()
    label.Size = UDim2.new(1, 0, 0, 40)
    label.Position = UDim2.new(0, 0, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = "Enter your OpenAI API key:"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 20
    label.Parent = frame

    local textBox = NexusGui.CreateTextBox()
    textBox.Size = UDim2.new(1, -20, 0, 40)
    textBox.Position = UDim2.new(0, 10, 0, 60)
    textBox.PlaceholderText = "sk-..."
    textBox.ClearTextOnFocus = false
    textBox.TextColor3 = Color3.new(1, 1, 1)
    textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = 18
    textBox.TextEditable = true
    textBox.Parent = frame

    local submitBtn = NexusGui.CreateButton()
    submitBtn.Size = UDim2.new(0, 100, 0, 30)
    submitBtn.Position = UDim2.new(1, -110, 1, -40)
    submitBtn.Text = "Submit"
    submitBtn.TextColor3 = Color3.new(1, 1, 1)
    submitBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    submitBtn.Font = Enum.Font.SourceSansBold
    submitBtn.TextSize = 18
    submitBtn.Parent = frame

    local enteredKey = nil
    local waiting = true

    submitBtn.MouseButton1Click:Connect(function()
        local key = textBox.Text
        if key and #key > 10 then
            enteredKey = key
            waiting = false
            ApiGui:Destroy()
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

-- Main GUI Setup
local mainGui = NexusGui.CreateGui()
mainGui.Name = "RemoteAI"

local mainFrame = NexusGui.CreateFrame()
mainFrame.Size = UDim2.new(0, 450, 0, 350)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = mainGui

local title = NexusGui.CreateLabel()
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🚀 Infinite Road Trip Remote AI Caller"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = mainFrame

local remoteLabel = NexusGui.CreateLabel()
remoteLabel.Size = UDim2.new(1, -20, 0, 25)
remoteLabel.Position = UDim2.new(0, 10, 0, 45)
remoteLabel.BackgroundTransparency = 1
remoteLabel.Text = "Select Remote:"
remoteLabel.TextColor3 = Color3.new(1, 1, 1)
remoteLabel.Font = Enum.Font.SourceSans
remoteLabel.TextSize = 18
remoteLabel.TextXAlignment = Enum.TextXAlignment.Left
remoteLabel.Parent = mainFrame

local remoteDropdown = NexusGui.CreateScrollingFrame()
remoteDropdown.Size = UDim2.new(1, -20, 0, 100)
remoteDropdown.Position = UDim2.new(0, 10, 0, 70)
remoteDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
remoteDropdown.BorderSizePixel = 0
remoteDropdown.CanvasSize = UDim2.new(0, 0, 0, 0)
remoteDropdown.ScrollBarThickness = 6
remoteDropdown.Parent = mainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = remoteDropdown

local promptLabel = NexusGui.CreateLabel()
promptLabel.Size = UDim2.new(1, -20, 0, 25)
promptLabel.Position = UDim2.new(0, 10, 0, 180)
promptLabel.BackgroundTransparency = 1
promptLabel.Text = "Enter prompt for OpenAI:"
promptLabel.TextColor3 = Color3.new(1, 1, 1)
promptLabel.Font = Enum.Font.SourceSans
promptLabel.TextSize = 18
promptLabel.TextXAlignment = Enum.TextXAlignment.Left
promptLabel.Parent = mainFrame

local promptBox = NexusGui.CreateTextBox()
promptBox.Size = UDim2.new(1, -20, 0, 60)
promptBox.Position = UDim2.new(0, 10, 0, 210)
promptBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
promptBox.TextColor3 = Color3.new(1, 1, 1)
promptBox.ClearTextOnFocus = false
promptBox.Font = Enum.Font.SourceSans
promptBox.TextSize = 16
promptBox.TextWrapped = true
promptBox.TextEditable = true
promptBox.PlaceholderText = "Example: Send speed = 999"
promptBox.Parent = mainFrame

local fireBtn = NexusGui.CreateButton()
fireBtn.Size = UDim2.new(1, -20, 0, 40)
fireBtn.Position = UDim2.new(0, 10, 0, 280)
fireBtn.Text = "Fire Remote with AI Args"
fireBtn.TextColor3 = Color3.new(1, 1, 1)
fireBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
fireBtn.Font = Enum.Font.SourceSansBold
fireBtn.TextSize = 20
fireBtn.Parent = mainFrame

-- Scan and fill remotes
local remotes = {}
local function scanRemotes()
    remotes = {}
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, obj)
        end
    end
end

local function fillDropdown()
    for _, child in pairs(remoteDropdown:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for i, remote in ipairs(remotes) do
        local btn = NexusGui.CreateButton()
        btn.Size = UDim2.new(1, -10, 0, 25)
        btn.Position = UDim2.new(0, 5, 0, (i-1)*30)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 16
        btn.TextWrapped = true
        btn.Text = remote:GetFullName()
        btn.Parent = remoteDropdown

        btn.MouseButton1Click:Connect(function()
            for _, b in pairs(remoteDropdown:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(90, 140, 90)
            mainFrame:SetAttribute("selectedRemote", remote)
        end)
    end
    remoteDropdown.CanvasSize = UDim2.new(0, 0, 0, #remotes * 30)
end

scanRemotes()
fillDropdown()

-- Fire Remote with AI Args
fireBtn.MouseButton1Click:Connect(function()
    local remote = mainFrame:GetAttribute("selectedRemote")
    local prompt = promptBox.Text
    if not remote then
        warn("No remote selected")
        return
    end
    if prompt == "" then
        warn("Prompt is empty")
        return
    end

    local body = HttpService:JSONEncode({
        model = "gpt-3.5-turbo",
        messages = {
            {role = "system", content = "You are an expert Roblox scripter. When given a prompt about firing a Roblox remote with arguments, respond ONLY with a valid Lua table of the arguments to use, no explanations."},
            {role = "user", content = prompt}
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
        warn("OpenAI API request failed:", response)
        return
    end

    local decoded = nil
    local ok, decodeErr = pcall(function()
        decoded = HttpService:JSONDecode(response)
    end)

    if not ok or not decoded then
        warn("Failed to decode OpenAI response:", decodeErr)
        return
    end

    if not decoded.choices or not decoded.choices[1] or not decoded.choices[1].message then
        warn("Invalid OpenAI response format.")
        return
    end

    local aiText = decoded.choices[1].message.content

    -- Sanitize AI output to extract table-like string
    local rawLua = aiText:match("{.*}") or aiText

    local func, loadErr = loadstring("return "..rawLua)
    if not func then
        warn("Failed to load AI response as Lua:", loadErr)
        return
    end

    local successArgs, args = pcall(func)
    if not successArgs then
        warn("Failed to execute AI response Lua:", args)
        return
    end

    -- Fire remote
    local fireSuccess, fireErr = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(table.unpack(args))
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer(table.unpack(args))
        else
            error("Selected remote is neither RemoteEvent nor RemoteFunction")
        end
    end)

    if not fireSuccess then
        warn("Failed to fire remote:", fireErr)
    else
        print("Remote fired successfully with args:", args)
    end
end)
