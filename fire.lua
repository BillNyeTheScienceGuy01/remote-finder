-- Nexus GUI + Remote Caller + OpenAI API Example (KRNL compatible)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer

-- Load Nexus GUI (assuming it is in ReplicatedStorage or somewhere accessible)
local NexusGui = require(ReplicatedStorage:WaitForChild("NexusGui"))

-- Container for API key (local only)
local ApiKey = nil

-- Helper function to create API Key entry window
local function createApiKeyWindow()
    local window = NexusGui.CreateWindow("Enter OpenAI API Key", UDim2.new(0, 400, 0, 150))

    local textBox = window:AddTextBox("API Key")
    textBox.PlaceholderText = "sk-..."

    local submitBtn = window:AddButton("Submit")
    submitBtn.OnClick:Connect(function()
        if textBox.Text ~= "" then
            ApiKey = textBox.Text
            window:Destroy()
            createMainGui() -- load main GUI after API key input
        else
            NexusGui.CreateNotification("Please enter a valid API key.")
        end
    end)
end

-- Helper function to call OpenAI API for prompt -> JSON
local function queryOpenAI(prompt)
    local url = "https://api.openai.com/v1/chat/completions"
    local headers = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer "..ApiKey
    }
    local body = HttpService:JSONEncode({
        model = "gpt-4o-mini", -- or whichever model you want
        messages = {
            {role = "system", content = "You are a helpful assistant that converts natural language into Roblox remote fire JSON arguments."},
            {role = "user", content = prompt}
        },
        temperature = 0,
        max_tokens = 300
    })

    local success, response = pcall(function()
        return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false, headers)
    end)
    if success then
        local decoded = HttpService:JSONDecode(response)
        local content = decoded.choices and decoded.choices[1].message.content
        return content -- expect this to be JSON string
    else
        return nil, response
    end
end

-- Main Remote Caller GUI
function createMainGui()
    local window = NexusGui.CreateWindow("Remote Caller", UDim2.new(0, 500, 0, 400))

    -- Dropdown or list of all remotes found in ReplicatedStorage & Workspace
    local remotes = {}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, obj)
        end
    end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, obj)
        end
    end

    local remoteDropdown = window:AddDropdown("Select Remote", remotes, function(selectedRemote)
        window.SelectedRemote = selectedRemote
    end)
    if #remotes > 0 then
        window.SelectedRemote = remotes[1]
    end

    -- TextBox for natural language prompt
    local promptBox = window:AddTextBox("Describe what to do with the remote (e.g. 'fire with speed 100')")
    promptBox.Text = ""

    -- Fire Button
    local fireBtn = window:AddButton("Fire Remote")

    fireBtn.OnClick:Connect(function()
        if not window.SelectedRemote then
            NexusGui.CreateNotification("Select a remote first!")
            return
        end

        local prompt = promptBox.Text
        if prompt == "" then
            NexusGui.CreateNotification("Enter a prompt for the remote arguments.")
            return
        end

        local jsonArgs, err = queryOpenAI(prompt)
        if not jsonArgs then
            NexusGui.CreateNotification("OpenAI API Error: "..tostring(err))
            return
        end

        -- Try to decode JSON and apply
        local args
        local success, err2 = pcall(function()
            args = HttpService:JSONDecode(jsonArgs)
        end)

        if not success then
            NexusGui.CreateNotification("Failed to decode JSON from API:\n"..jsonArgs)
            return
        end

        -- Fire remote
        local ok, fireErr = pcall(function()
            if window.SelectedRemote:IsA("RemoteEvent") then
                window.SelectedRemote:FireServer(unpack(args))
            elseif window.SelectedRemote:IsA("RemoteFunction") then
                window.SelectedRemote:InvokeServer(unpack(args))
            end
        end)
        if not ok then
            NexusGui.CreateNotification("Failed to fire remote:\n"..tostring(fireErr))
        else
            NexusGui.CreateNotification("Remote fired successfully!")
        end
    end)
end

-- Start with API Key Window
createApiKeyWindow()
