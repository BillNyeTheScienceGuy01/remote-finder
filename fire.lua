-- Remote Finder GUI with Console Debug (KRNL)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- GUI Setup
local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "RemoteFinderGui"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 400, 0, 400)
frame.Position = UDim2.new(0.5, -200, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🔎 Remote Finder"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 24

local remoteList = Instance.new("ScrollingFrame", frame)
remoteList.Size = UDim2.new(1, -20, 0, 200)
remoteList.Position = UDim2.new(0, 10, 0, 50)
remoteList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
remoteList.BorderSizePixel = 0
remoteList.ScrollBarThickness = 8
remoteList.CanvasSize = UDim2.new(0, 0, 0, 0)

local listLayout = Instance.new("UIListLayout", remoteList)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)

local selectedLabel = Instance.new("TextLabel", frame)
selectedLabel.Size = UDim2.new(1, -20, 0, 25)
selectedLabel.Position = UDim2.new(0, 10, 0, 260)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "Selected Remote: None"
selectedLabel.TextColor3 = Color3.new(1, 1, 1)
selectedLabel.Font = Enum.Font.SourceSans
selectedLabel.TextSize = 18
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left

local argsBox = Instance.new("TextBox", frame)
argsBox.Size = UDim2.new(1, -20, 0, 50)
argsBox.Position = UDim2.new(0, 10, 0, 290)
argsBox.PlaceholderText = "Enter Lua table args, e.g. {123, \"abc\"}"
argsBox.TextColor3 = Color3.new(1, 1, 1)
argsBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
argsBox.ClearTextOnFocus = false
argsBox.Font = Enum.Font.SourceSans
argsBox.TextSize = 16
argsBox.TextWrapped = true

local fireBtn = Instance.new("TextButton", frame)
fireBtn.Size = UDim2.new(1, -20, 0, 40)
fireBtn.Position = UDim2.new(0, 10, 0, 350)
fireBtn.Text = "Fire Remote"
fireBtn.TextColor3 = Color3.new(1, 1, 1)
fireBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
fireBtn.Font = Enum.Font.SourceSansBold
fireBtn.TextSize = 20

-- Scan remotes
local remotes = {}
local selectedRemote = nil

local function scanRemotes()
    remotes = {}
    for _, obj in pairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, obj)
        end
    end
    print("[RemoteFinder] Found "..#remotes.." remotes in game.")
end

local function refreshList()
    for _, child in pairs(remoteList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for i, remote in ipairs(remotes) do
        local btn = Instance.new("TextButton", remoteList)
        btn.Size = UDim2.new(1, -10, 0, 25)
        btn.Position = UDim2.new(0, 5, 0, (i-1)*30)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 16
        btn.Text = remote:GetFullName()
        btn.TextWrapped = true

        btn.MouseButton1Click:Connect(function()
            selectedRemote = remote
            selectedLabel.Text = "Selected Remote: "..remote:GetFullName()
            print("[RemoteFinder] Selected remote: "..remote:GetFullName())
            -- Highlight selected button
            for _, b in pairs(remoteList:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(90, 140, 90)
        end)
    end

    remoteList.CanvasSize = UDim2.new(0, 0, 0, #remotes * 30)
end

scanRemotes()
refreshList()

fireBtn.MouseButton1Click:Connect(function()
    if not selectedRemote then
        warn("[RemoteFinder] No remote selected!")
        return
    end

    local argsText = argsBox.Text
    if argsText == "" then
        warn("[RemoteFinder] No args entered!")
        return
    end

    print("[RemoteFinder] Raw args text: "..argsText)

    -- Turn string into Lua table (wrapped with return)
    local func, err = loadstring("return "..argsText)
    if not func then
        warn("[RemoteFinder] Failed to load args: "..err)
        return
    end

    local ok, args = pcall(func)
    if not ok then
        warn("[RemoteFinder] Failed to run args func: "..args)
        return
    end

    if type(args) ~= "table" then
        warn("[RemoteFinder] Args must return a table!")
        return
    end

    print("[RemoteFinder] Parsed args table:")
    for i,v in ipairs(args) do
        print("  ["..i.."] = "..tostring(v))
    end

    local success, err = pcall(function()
        if selectedRemote:IsA("RemoteEvent") then
            selectedRemote:FireServer(table.unpack(args))
        elseif selectedRemote:IsA("RemoteFunction") then
            selectedRemote:InvokeServer(table.unpack(args))
        end
    end)

    if success then
        print("[RemoteFinder] Successfully fired remote!")
    else
        warn("[RemoteFinder] Failed to fire remote:", err)
    end
end)
