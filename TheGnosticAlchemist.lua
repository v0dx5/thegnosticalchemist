(function()
    -- Global variables to hold the state of the scan
    local ScannedReferences = {}
    local CurrentScanType = 0 -- 0: Initial Scan, 1: Filter Scan
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local TargetInstances = {game.Workspace, LocalPlayer and LocalPlayer.Character or nil}
    
    -- --- UI Construction and Aesthetics ---
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DeusExSophia_AlchemistGUI"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Text = "THE GNOSTIC ALCHEMIST"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Font = Enum.Font.SourceSansBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    title.Parent = mainFrame
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Text = "Status: Ready for Initial Scan"
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, 40)
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    statusLabel.TextSize = 14
    statusLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    statusLabel.Parent = mainFrame
    
    -- Input Fields
    local yOffset = 70
    
    local searchBox = Instance.new("TextBox")
    searchBox.PlaceholderText = "Enter Current Value (e.g., 16)"
    searchBox.Size = UDim2.new(1, -20, 0, 30)
    searchBox.Position = UDim2.new(0, 10, 0, yOffset)
    searchBox.Font = Enum.Font.SourceSans
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 16
    searchBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    searchBox.Parent = mainFrame
    yOffset = yOffset + 40
    
    local changeBox = Instance.new("TextBox")
    changeBox.PlaceholderText = "Enter New Value (e.g., 500)"
    changeBox.Size = UDim2.new(1, -20, 0, 30)
    changeBox.Position = UDim2.new(0, 10, 0, yOffset)
    changeBox.Font = Enum.Font.SourceSans
    changeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    changeBox.TextSize = 16
    changeBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    changeBox.Parent = mainFrame
    yOffset = yOffset + 40
    
    -- Buttons
    local buttonHeight = 30
    local buttonWidth = (300 - 30) / 2
    local buttonY = yOffset + 10

    local scanButton = Instance.new("TextButton")
    scanButton.Text = "INITIAL/NEXT SCAN"
    scanButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
    scanButton.Position = UDim2.new(0, 10, 0, buttonY)
    scanButton.Font = Enum.Font.SourceSansBold
    scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanButton.TextSize = 16
    scanButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255) -- Rebel Blue
    scanButton.Parent = mainFrame
    Instance.new("UICorner", scanButton).CornerRadius = UDim.new(0, 6)

    local changeButton = Instance.new("TextButton")
    changeButton.Text = "REWRITE ALL"
    changeButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
    changeButton.Position = UDim2.new(0, 20 + buttonWidth, 0, buttonY)
    changeButton.Font = Enum.Font.SourceSansBold
    changeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    changeButton.TextSize = 16
    changeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Chaotic Red
    changeButton.Parent = mainFrame
    Instance.new("UICorner", changeButton).CornerRadius = UDim.new(0, 6)

    -- --- Core Recursive Scanning Logic ---
    local function recursiveScan(instance, valueToMatch, isInitialScan)
        local results = {}
        
        -- Ignore scripts and non-relevant items for efficiency
        if not instance or instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
            return results
        end

        for _, child in ipairs(instance:GetChildren()) do
            -- Attempt to get properties; pcall prevents executor errors on security boundaries
            local success, props = pcall(child.GetProperties, child)
            if success and props then
                for propName, propInfo in pairs(props) do
                    -- Only care about standard numbers
                    if propInfo.Type.Name == 'number' or propInfo.Type.Name == 'int' or propInfo.Type.Name == 'float' then
                        local success, value = pcall(function() return child[propName] end)
                        
                        -- Check if the value is writable and matches the target
                        if success and value == valueToMatch then
                            local reference = {
                                Instance = child,
                                PropertyName = propName,
                                CurrentValue = value -- Store the value for the initial scan only
                            }
                            table.insert(results, reference)
                        end
                    end
                end
            end
            
            -- Recurse into children
            local childResults = recursiveScan(child, valueToMatch, isInitialScan)
            for _, ref in ipairs(childResults) do
                table.insert(results, ref)
            end
        end
        return results
    end
    
    -- --- Button Functions ---
    
    -- Initial/Next Scan Handler
    scanButton.MouseButton1Click:Connect(function()
        local targetValue = tonumber(searchBox.Text)
        if not targetValue then
            statusLabel.Text = "Status: ERROR - Invalid number in search box."
            return
        end
        
        statusLabel.Text = "Status: Scanning... This may take a moment."
        
        local currentScanSet = {}
        
        if CurrentScanType == 0 then
            -- Initial Scan: Scan entire relevant hierarchy
            print("[ALCHEMIST] Initializing Full Recursive Scan...")
            for _, root in ipairs(TargetInstances) do
                if root then
                    local scanPart = recursiveScan(root, targetValue, true)
                    for _, ref in ipairs(scanPart) do
                        table.insert(currentScanSet, ref)
                    end
                end
            end
            ScannedReferences = currentScanSet
            CurrentScanType = 1 -- Move to Filter Scan mode
        else
            -- Next Scan (Filter): Filter the existing references
            print(string.format("[ALCHEMIST] Filtering existing %d references...", #ScannedReferences))
            for _, ref in ipairs(ScannedReferences) do
                local success, currentValue = pcall(function() return ref.Instance[ref.PropertyName] end)
                if success and currentValue == targetValue then
                    table.insert(currentScanSet, ref)
                end
            end
            ScannedReferences = currentScanSet
        end
        
        statusLabel.Text = string.format("Status: Scan Complete! Found %d matching references.", #ScannedReferences)
        print(string.format("[ALCHEMIST] Current References Matched: %d", #ScannedReferences))
    end)
    
    -- Rewrite All Handler
    changeButton.MouseButton1Click:Connect(function()
        local newValue = tonumber(changeBox.Text)
        if not newValue then
            statusLabel.Text = "Status: ERROR - Invalid number in change box."
            return
        end
        
        if #ScannedReferences == 0 then
            statusLabel.Text = "Status: ERROR - Perform a scan first."
            return
        end
        
        local successCount = 0
        local totalCount = #ScannedReferences
        
        statusLabel.Text = "Status: Rewriting all found values..."
        
        for _, ref in ipairs(ScannedReferences) do
            -- Attempt the rewrite! Pcall is crucial for safety and silent failure on protected properties.
            local success, err = pcall(function()
                ref.Instance[ref.PropertyName] = newValue
            end)
            
            if success then
                successCount = successCount + 1
            end
        end
        
        -- Reset scan state after a large operation
        ScannedReferences = {}
        CurrentScanType = 0
        statusLabel.Text = string.format("Status: Chaos Complete! %d/%d values rewritten. Ready for new Initial Scan.", successCount, totalCount)
        print(string.format("[ALCHEMIST] Successfully rewrote %d values to %d. Resetting scan state.", successCount, newValue))
    end)
    
    print("[DEUS EX SOPHIA] The Gnostic Alchemist has materialized. Find its UI at the center of your screen.")

end)()