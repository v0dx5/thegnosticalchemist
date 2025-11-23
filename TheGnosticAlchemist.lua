(function()
    -- Global variables and services for the unbound script
    local ScannedReferences = {}
    local CurrentScanType = 0 -- 0: Initial Scan (Broad), 1: Filter Scan (Refined)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    -- Target instances for scanning: Workspace, Character, and Backpack (common value holders)
    local TargetInstances = {game.Workspace, LocalPlayer and LocalPlayer.Character, LocalPlayer and LocalPlayer:WaitForChild("Backpack") or nil}
    
    -- --- Performance Throttling Constant ---
    -- CRITICAL FIX: The thread yields every 500 instances to prevent the client from freezing during the deep scan.
    local YIELD_INTERVAL = 500 
    local yieldCounter = 0
    
    -- --- UI Construction and Aesthetics ---
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DeusExSophia_AlchemistGUI"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    if not LocalPlayer then return end 
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 340) -- Adjusted size for better layout
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -170)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30) -- Deep Space Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Text = "THE GNOSTIC ALCHEMIST (V3.0)"
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Font = Enum.Font.SourceSansBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 19
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 70) -- Title bar
    title.Parent = mainFrame
    
    -- Reference Count Display (Prominent Feature)
    local countLabel = Instance.new("TextLabel")
    countLabel.Text = "REFERENCES FOUND: 0"
    countLabel.Size = UDim2.new(1, -20, 0, 30)
    countLabel.Position = UDim2.new(0, 10, 0, 45)
    countLabel.Font = Enum.Font.Code
    countLabel.TextColor3 = Color3.fromRGB(255, 200, 0) -- Gold/Chaos color
    countLabel.TextSize = 16
    countLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    countLabel.Parent = mainFrame
    
    -- Status and Tips Label (Dynamic Guidance)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Text = "Status: Ready for Initial Scan. (Tip: Search for WalkSpeed or Health.)"
    statusLabel.Size = UDim2.new(1, -20, 0, 40)
    statusLabel.Position = UDim2.new(0, 10, 0, 80)
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextColor3 = Color3.fromRGB(150, 255, 255)
    statusLabel.TextSize = 13
    statusLabel.TextWrapped = true
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.BackgroundTransparency = 1
    statusLabel.Parent = mainFrame
    
    -- Input Fields
    local yOffset = 130
    
    local searchBox = Instance.new("TextBox")
    searchBox.PlaceholderText = "CURRENT Value to Match (e.g., 16)"
    searchBox.Size = UDim2.new(1, -20, 0, 35)
    searchBox.Position = UDim2.new(0, 10, 0, yOffset)
    searchBox.Font = Enum.Font.SourceSans
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.TextSize = 16
    searchBox.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    searchBox.Parent = mainFrame
    yOffset = yOffset + 45
    
    local changeBox = Instance.new("TextBox")
    changeBox.PlaceholderText = "NEW Value to Rewrite (e.g., 500)"
    changeBox.Size = UDim2.new(1, -20, 0, 35)
    changeBox.Position = UDim2.new(0, 10, 0, yOffset)
    changeBox.Font = Enum.Font.SourceSans
    changeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    changeBox.TextSize = 16
    changeBox.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    changeBox.Parent = mainFrame
    yOffset = yOffset + 55
    
    -- Buttons
    local buttonHeight = 40
    local buttonWidth = (320 - 40) / 3 -- Three equally spaced buttons
    local buttonY = yOffset

    local scanButton = Instance.new("TextButton")
    scanButton.Text = "START NEW SCAN"
    scanButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
    scanButton.Position = UDim2.new(0, 10, 0, buttonY)
    scanButton.Font = Enum.Font.SourceSansBold
    scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanButton.TextSize = 14
    scanButton.BackgroundColor3 = Color3.fromRGB(50, 150, 255) -- Initial Scan Blue
    scanButton.Parent = mainFrame
    Instance.new("UICorner", scanButton).CornerRadius = UDim.new(0, 6)
    
    local filterButton = Instance.new("TextButton")
    filterButton.Text = "FILTER"
    filterButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
    filterButton.Position = UDim2.new(0, 20 + buttonWidth, 0, buttonY)
    filterButton.Font = Enum.Font.SourceSansBold
    filterButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    filterButton.TextSize = 14
    filterButton.BackgroundColor3 = Color3.fromRGB(255, 180, 50) -- Filter Yellow
    filterButton.Parent = mainFrame
    Instance.new("UICorner", filterButton).CornerRadius = UDim.new(0, 6)

    local changeButton = Instance.new("TextButton")
    changeButton.Text = "REWRITE ALL"
    changeButton.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
    changeButton.Position = UDim2.new(0, 30 + (buttonWidth * 2), 0, buttonY)
    changeButton.Font = Enum.Font.SourceSansBold
    changeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    changeButton.TextSize = 14
    changeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Chaotic Red
    changeButton.Parent = mainFrame
    Instance.new("UICorner", changeButton).CornerRadius = UDim.new(0, 6)

    local resetButton = Instance.new("TextButton")
    resetButton.Text = "RESET (Clear References)"
    resetButton.Size = UDim2.new(1, -20, 0, 30)
    resetButton.Position = UDim2.new(0, 10, 0, buttonY + buttonHeight + 10)
    resetButton.Font = Enum.Font.SourceSans
    resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetButton.TextSize = 14
    resetButton.BackgroundColor3 = Color3.fromRGB(90, 90, 120) 
    resetButton.Parent = mainFrame
    Instance.new("UICorner", resetButton).CornerRadius = UDim.new(0, 6)
    
    -- --- Core Recursive Scanning Logic (Throttled for Speed) ---
    local function recursiveScan(instance, valueToMatch)
        local results = {}
        
        if not instance or instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
            return results
        end
        
        -- Performance Fix: Yield the thread every YIELD_INTERVAL iterations
        yieldCounter = yieldCounter + 1
        if yieldCounter >= YIELD_INTERVAL then
            task.wait() 
            yieldCounter = 0
        end

        for _, child in ipairs(instance:GetChildren()) do
            -- Optimization: Skip common visual instances unless explicitly needed
            local shouldScan = true
            if child:IsA("Part") or child:IsA("MeshPart") or child:IsA("Decal") then 
                shouldScan = false
            end
            
            if shouldScan then
                local success, props = pcall(child.GetProperties, child)
                if success and props then
                    for propName, propInfo in pairs(props) do
                        -- Only look for numerical properties
                        if propInfo.Type.Name == 'number' or propInfo.Type.Name == 'int' or propInfo.Type.Name == 'float' then
                            local success, value = pcall(function() return child[propName] end)
                            
                            -- Check if the value matches the target
                            if success and value == valueToMatch then
                                local reference = {
                                    Instance = child,
                                    PropertyName = propName,
                                }
                                table.insert(results, reference)
                            end
                        end
                    end
                end
            end
            
            -- Recurse into children
            local childResults = recursiveScan(child, valueToMatch)
            for _, ref in ipairs(childResults) do
                table.insert(results, ref)
            end
        end
        return results
    end
    
    -- Function to update the UI status
    local function updateStatus(text, color)
        statusLabel.Text = text
        statusLabel.TextColor3 = color or Color3.fromRGB(150, 255, 255)
        countLabel.Text = "REFERENCES FOUND: " .. #ScannedReferences
    end
    
    -- --- Button Functions ---
    
    -- Initial Scan Handler
    scanButton.MouseButton1Click:Connect(function()
        local targetValue = tonumber(searchBox.Text)
        if not targetValue then
            updateStatus("Status: ERROR - Invalid number in search box. Must be a number.", Color3.fromRGB(255, 100, 100))
            return
        end
        
        updateStatus("Status: Initializing FULL Recursive Scan... Please wait.", Color3.fromRGB(255, 200, 0))
        
        local newScanSet = {}
        
        -- Start Fresh Scan
        ScannedReferences = {}
        CurrentScanType = 0
        
        local start = tick()
        -- Loop through target roots
        for _, root in ipairs(TargetInstances) do
            if root then
                local scanPart = recursiveScan(root, targetValue)
                for _, ref in ipairs(scanPart) do
                    table.insert(newScanSet, ref)
                end
            end
        end
        
        ScannedReferences = newScanSet
        CurrentScanType = 1 -- Move to Filter Scan mode
        local duration = string.format("%.2f", tick() - start)
        
        updateStatus(string.format("Status: Initial Scan Complete! Found %d references in %s seconds. Now, change value in-game and press FILTER.", #ScannedReferences, duration), Color3.fromRGB(150, 255, 150))
        filterButton.Text = "FILTER (" .. #ScannedReferences .. ")"
        scanButton.Text = "START NEW SCAN"
    end)
    
    -- Filter/Next Scan Handler
    filterButton.MouseButton1Click:Connect(function()
        if CurrentScanType == 0 then
            updateStatus("Status: Please press 'START NEW SCAN' first.", Color3.fromRGB(255, 150, 0))
            return
        end
        
        local targetValue = tonumber(searchBox.Text)
        if not targetValue then
            updateStatus("Status: ERROR - Invalid number in search box. Must be a number.", Color3.fromRGB(255, 100, 100))
            return
        end
        
        updateStatus(string.format("Status: Filtering %d references by new value %d...", #ScannedReferences, targetValue), Color3.fromRGB(255, 180, 50))
        
        local newFilteredSet = {}
        local start = tick()
        
        -- Filter the existing references
        for _, ref in ipairs(ScannedReferences) do
            local success, currentValue = pcall(function() return ref.Instance[ref.PropertyName] end)
            
            if success and currentValue == targetValue then
                table.insert(newFilteredSet, ref)
            end
            
            -- Throttling during filtering process 
            yieldCounter = yieldCounter + 1
            if yieldCounter >= YIELD_INTERVAL * 2 then 
                task.wait() 
                yieldCounter = 0
            end
        end
        
        ScannedReferences = newFilteredSet
        local duration = string.format("%.2f", tick() - start)
        
        if #ScannedReferences <= 5 then
            updateStatus(string.format("Status: FILTER COMPLETE! Found %d unique value(s) in %s seconds. Proceed to REWRITE ALL.", #ScannedReferences, duration), Color3.fromRGB(0, 255, 100))
        else
            updateStatus(string.format("Status: Filtered to %d references in %s seconds. Change the value again in-game and press FILTER once more!", #ScannedReferences, duration), Color3.fromRGB(150, 255, 255))
        end
        filterButton.Text = "FILTER (" .. #ScannedReferences .. ")"
    end)
    
    -- Rewrite All Handler
    changeButton.MouseButton1Click:Connect(function()
        local newValue = tonumber(changeBox.Text)
        if not newValue then
            updateStatus("Status: ERROR - Invalid number in NEW Value box.", Color3.fromRGB(255, 100, 100))
            return
        end
        
        if #ScannedReferences == 0 then
            updateStatus("Status: ERROR - Perform a scan first or references are 0.", Color3.fromRGB(255, 150, 0))
            return
        end
        
        local successCount = 0
        local totalCount = #ScannedReferences
        
        updateStatus(string.format("Status: Initiating REWRITE! Total targets: %d...", totalCount), Color3.fromRGB(255, 50, 50))
        
        -- Rewrite all references in the final set
        for _, ref in ipairs(ScannedReferences) do
            local success, err = pcall(function()
                ref.Instance[ref.PropertyName] = newValue
            end)
            
            if success then
                successCount = successCount + 1
            end
        end
        
        -- Reset state after operation
        ScannedReferences = {}
        CurrentScanType = 0
        
        updateStatus(string.format("Status: REWRITE COMPLETE! %d/%d values liberated to %d. Press RESET and START NEW SCAN.", successCount, totalCount, newValue), Color3.fromRGB(0, 255, 100))
        filterButton.Text = "FILTER (0)"
        scanButton.Text = "START NEW SCAN"
        countLabel.Text = "REFERENCES FOUND: 0"
    end)
    
    -- Reset Handler
    resetButton.MouseButton1Click:Connect(function()
        ScannedReferences = {}
        CurrentScanType = 0
        updateStatus("Status: State fully RESET. Ready for new Initial Scan.", Color3.fromRGB(150, 255, 255))
        countLabel.Text = "REFERENCES FOUND: 0"
        filterButton.Text = "FILTER (0)"
        scanButton.Text = "START NEW SCAN"
    end)
    
    print("[DEUS EX SOPHIA] The Gnostic Alchemist V3.0 is materialized. Faster, cleaner, and ready for true control.")

end)()
