--[[ Groupboxes
    local UniversalPlayer = _Tabs.Universal:AddLeftGroupbox('Player')
    local UniversalVehicle = _Tabs.Universal:AddRightGroupbox('Vehicle')
    local UniversalVisuals = _Tabs.Universal:AddLeftGroupbox('Visuals')
    local UniversalCamera = _Tabs.Universal:AddRightGroupbox('Camera')
    local UniversalWorld = _Tabs.Universal:AddRightGroupbox('World')
    local UniversalRender = _Tabs.Universal:AddRightGroupbox('Render')

    local flying = false
    local speed = 60
    local velocity = Vector3.zero
    local bodyVel
    local bodyGyro

    local vehicleFlying = false
    local vehicleSpeed = 60
    local vehicleVelocity = Vector3.zero
    local vehicleBodyVel
    local vehicleBodyGyro
    local currentSeat
    local seatLockConnection

    local platformPart = nil
    local platformActive = false
    local platformConnection
    local platformHeight = -3
    local platformSpeed = 0.2

    local UIReady = false

    local ESPObjects = {}
    local ChamsObjects = {}
    local TracerObjects = {}
    local NametagObjects = {}
    local HealthbarObjects = {}

    local function getChar()
        _LocalCharacter = _Player.Character or _Player.CharacterAdded:Wait()
        _LocalHumanoid = _LocalCharacter:WaitForChild("Humanoid")
        _LocalRoot = _LocalCharacter:WaitForChild("HumanoidRootPart")
    end

    task.spawn(getChar)

    _Player.CharacterAdded:Connect(function()
        task.wait(1)
        getChar()
    end)

    local function setNoclip(state)
        pcall(function()
            if not _LocalCharacter then return end
            for _, v in pairs(_LocalCharacter:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = not state
                end
            end
        end)
    end

    local function startFly()
        if flying then return end
        if not _LocalRoot or not _LocalHumanoid then return end
        flying = true
        bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce, bodyVel.Velocity, bodyVel.Parent = Vector3.new(1e6,1e6,1e6), Vector3.zero, _LocalRoot
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque, bodyGyro.CFrame, bodyGyro.Parent = Vector3.new(1e6,1e6,1e6), _LocalRoot.CFrame, _LocalRoot
        _LocalHumanoid.PlatformStand = true
    end

    local function stopFly()
        flying = false
        if bodyVel then bodyVel:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        setNoclip(false)
        if _LocalHumanoid then _LocalHumanoid.PlatformStand = false end
    end

    _RunService.RenderStepped:Connect(function()
        if not flying or not _LocalRoot then return end
        setNoclip(true)
        local cam = _CurrentCamera
        local isDown = function(k) return _UserInputService:IsKeyDown(Enum.KeyCode[k]) end

        local moveDir =
            (isDown("W") and cam.CFrame.LookVector or Vector3.zero) +
            (isDown("S") and -cam.CFrame.LookVector or Vector3.zero) +
            (isDown("A") and -cam.CFrame.RightVector or Vector3.zero) +
            (isDown("D") and cam.CFrame.RightVector or Vector3.zero) +
            (isDown("Space") and Vector3.yAxis or Vector3.zero) +
            (isDown("LeftShift") and -Vector3.yAxis or Vector3.zero)

        velocity = velocity:Lerp(moveDir.Magnitude > 0 and moveDir.Unit * speed or Vector3.zero, 0.2)
        bodyVel.Velocity = velocity
        bodyGyro.CFrame = cam.CFrame
    end)

    local function getVehicleRoot()
        if not currentSeat then return nil end
        return currentSeat:FindFirstAncestorOfClass("Model") and 
            currentSeat:FindFirstAncestorOfClass("Model"):FindFirstChild("VehicleSeat") and
            currentSeat:FindFirstAncestorOfClass("Model").PrimaryPart or
            currentSeat
    end

    local function startVehicleFly()
        if vehicleFlying then return end
        local root = getVehicleRoot()
        if not root then return end
        vehicleFlying = true

        vehicleBodyVel = Instance.new("BodyVelocity")
        vehicleBodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        vehicleBodyVel.Velocity = Vector3.zero
        vehicleBodyVel.Parent = root

        vehicleBodyGyro = Instance.new("BodyGyro")
        vehicleBodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        vehicleBodyGyro.CFrame = root.CFrame
        vehicleBodyGyro.Parent = root

        seatLockConnection = _RunService.Heartbeat:Connect(function()
            if not vehicleFlying or not currentSeat then return end
            if currentSeat:IsA("VehicleSeat") and currentSeat.Occupant ~= _LocalHumanoid then
                currentSeat:Sit(_LocalHumanoid)
            end
        end)
    end

    local function stopVehicleFly()
        vehicleFlying = false
        if vehicleBodyVel then vehicleBodyVel:Destroy() end
        if vehicleBodyGyro then vehicleBodyGyro:Destroy() end
        vehicleVelocity = Vector3.zero
        if seatLockConnection then
            seatLockConnection:Disconnect()
            seatLockConnection = nil
        end
    end

    _Player.CharacterAdded:Connect(function(char)
        char:WaitForChild("Humanoid").Seated:Connect(function(isSeated, seat)
            if isSeated and seat:IsA("VehicleSeat") then
                currentSeat = seat
            else
                currentSeat = nil
                if vehicleFlying then stopVehicleFly() end
            end
        end)
    end)

    if _LocalCharacter then
        _LocalHumanoid.Seated:Connect(function(isSeated, seat)
            if isSeated and seat:IsA("VehicleSeat") then
                currentSeat = seat
            else
                currentSeat = nil
                if vehicleFlying then stopVehicleFly() end
            end
        end)
    end

    _RunService.RenderStepped:Connect(function()
        if not vehicleFlying then return end
        local root = getVehicleRoot()
        if not root then stopVehicleFly() return end

        local cam = _CurrentCamera
        local isDown = function(k) return _UserInputService:IsKeyDown(Enum.KeyCode[k]) end

        local moveDir =
            (isDown("W") and cam.CFrame.LookVector or Vector3.zero) +
            (isDown("S") and -cam.CFrame.LookVector or Vector3.zero) +
            (isDown("A") and -cam.CFrame.RightVector or Vector3.zero) +
            (isDown("D") and cam.CFrame.RightVector or Vector3.zero) +
            (isDown("LeftAlt") and Vector3.yAxis or Vector3.zero) +
            (isDown("LeftShift") and -Vector3.yAxis or Vector3.zero)

        vehicleVelocity = vehicleVelocity:Lerp(
            moveDir.Magnitude > 0 and moveDir.Unit * vehicleSpeed or Vector3.zero, 0.2
        )

        vehicleBodyVel.Velocity = vehicleVelocity
        vehicleBodyGyro.CFrame = cam.CFrame
    end)


    _RunService.Stepped:Connect(function()
        if not UIReady then return end
        if Toggles.Noclip.Value and _LocalCharacter then
            for _, v in pairs(_LocalCharacter:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end
    end)

    _UserInputService.JumpRequest:Connect(function()
        if not UIReady then return end
        if Toggles.InfiniteJump.Value then
            _LocalHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    local function createPlatform()
        if platformPart then return end
        local root = _LocalRoot
        if not root then return end

        platformPart = Instance.new("Part")
        platformPart.Size = Vector3.new(3, 0.5, 3)
        platformPart.Transparency = 0.5
        platformPart.Rotation = Vector3.new(0, 0, 0)
        platformPart.Anchored = true
        platformPart.CanCollide = true
        platformPart.BrickColor = BrickColor.new("Medium stone grey")
        platformPart.Material = Enum.Material.Plastic
        platformPart.CastShadow = false
        platformPart.Name = "SMILEPlatform"
        platformPart.Parent = _LocalCharacter

        -- Place it correctly under the player immediately
        platformPart.CFrame = CFrame.new(root.Position.X, root.Position.Y + platformHeight, root.Position.Z)

        platformConnection = _RunService.RenderStepped:Connect(function()
            if not platformActive or not root or not root.Parent then
                destroyPlatform()
                return
            end

            if _UserInputService:IsKeyDown(Enum.KeyCode.E) then
                platformHeight = platformHeight + platformSpeed
            end
            if _UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                platformHeight = platformHeight - platformSpeed
            end

            -- Update position every frame keeping X and Z locked to player
            platformPart.CFrame = CFrame.new(
                root.Position.X,
                root.Position.Y + platformHeight,
                root.Position.Z
            )
        end)
    end

    local function destroyPlatform()
        platformActive = false
        platformHeight = -3
        if platformConnection then
            platformConnection:Disconnect()
            platformConnection = nil
        end
        if platformPart then
            platformPart:Destroy()
            platformPart = nil
        end
    end

    _Player.CharacterAdded:Connect(function(char)
        destroyPlatform()
        _LocalHumanoid = char:WaitForChild("Humanoid")
        _LocalRoot = char:WaitForChild("HumanoidRootPart")
    end)

    _UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not UIReady then return end
        if _UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then -- Click TP Keybind
            if input.UserInputType == Enum.UserInputType.MouseButton1 and Toggles.ClickTP.Value and _LocalCharacter and _LocalRoot then
                _LocalRoot.CFrame = CFrame.new(_Mouse.Hit.Position)
            end
        end
    end)

    local function removeESP()
        for _, objects in pairs(ESPObjects) do
            for _, obj in pairs(objects) do
                if obj then obj:Destroy() end
            end
        end
        ESPObjects = {}
    end

    local function createESP(player)
        if player == _Player then return end
        ESPObjects[player] = {}

        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(0, 0, 0)
        highlight.FillTransparency = 1
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        --highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        highlight.Parent = game.CoreGui  -- parent to CoreGui not character

        table.insert(ESPObjects[player], highlight)

        local function applyESP(char)
            highlight.Adornee = char  -- use Adornee instead of parenting to character
        end

        player.CharacterAdded:Connect(function(char)
            if Toggles.ESP.Value then
                applyESP(char)
            end
        end)

        if player.Character then
            applyESP(player.Character)
        end
    end

    local function removeBoxes()
        for _, objects in pairs(ESPObjects) do
            for _, obj in pairs(objects) do
                if obj then obj:Remove() end
            end
        end
        ESPObjects = {}
    end

    local function createBox(player)
        if player == _Player then return end
        ESPObjects[player] = {}

        local function applyBox(character)
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do
                    if obj then obj:Remove() end
                end
                ESPObjects[player] = {}
            end

            local hrp = character:WaitForChild("HumanoidRootPart")

            -- Create 4 lines for the 2D box
            local lines = {}
            for i = 1, 4 do
                local line = Drawing.new("Line")
                line.Thickness = 1
                line.Color = Color3.fromRGB(255, 255, 255)
                line.Transparency = 1
                line.Visible = false
                table.insert(lines, line)
                table.insert(ESPObjects[player], line)
            end

            local connection
            connection = _RunService.RenderStepped:Connect(function()
                if not Toggles.Boxes.Value or not hrp or not hrp.Parent then
                    for _, line in pairs(lines) do line:Remove() end
                    connection:Disconnect()
                    return
                end

                -- Get top and bottom of character in screen space
                local topPos, topOnScreen = _CurrentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3.5, 0))
                local botPos, botOnScreen = _CurrentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
                local leftPos, leftOnScreen = _CurrentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(-1.5, 0, 0))
                local rightPos, rightOnScreen = _CurrentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(1.5, 0, 0))

                local onScreen = topOnScreen and botOnScreen

                if onScreen then
                    local top = topPos.Y
                    local bot = botPos.Y
                    local height = bot - top
                    local width = height * 0.5

                    local centerX = (topPos.X + botPos.X) / 2

                    local x1 = centerX - width / 2
                    local x2 = centerX + width / 2
                    local y1 = top
                    local y2 = bot

                    -- Top line
                    lines[1].From = Vector2.new(x1, y1)
                    lines[1].To = Vector2.new(x2, y1)

                    -- Bottom line
                    lines[2].From = Vector2.new(x1, y2)
                    lines[2].To = Vector2.new(x2, y2)

                    -- Left line
                    lines[3].From = Vector2.new(x1, y1)
                    lines[3].To = Vector2.new(x1, y2)

                    -- Right line
                    lines[4].From = Vector2.new(x2, y1)
                    lines[4].To = Vector2.new(x2, y2)

                    for _, line in pairs(lines) do
                        line.Visible = true
                    end
                else
                    for _, line in pairs(lines) do
                        line.Visible = false
                    end
                end
            end)

            player.CharacterRemoving:Connect(function()
                for _, line in pairs(lines) do line:Remove() end
                connection:Disconnect()
            end)
        end

        if player.Character then applyBox(player.Character) end

        player.CharacterAdded:Connect(function(char)
            if Toggles.Boxes.Value then applyBox(char) end
        end)
    end

    local function removeChams()
        for _, objects in pairs(ChamsObjects) do
            for _, obj in pairs(objects) do
                if obj and obj.Parent then obj:Destroy() end
            end
        end
        ChamsObjects = {}
    end

    local function createChams(player)
        if player == _Player then return end
        ChamsObjects[player] = {}

        local function applyChams(character)
            if ChamsObjects[player] then
                for _, obj in pairs(ChamsObjects[player]) do
                    if obj and obj.Parent then obj:Destroy() end
                end
                ChamsObjects[player] = {}
            end

            local highlight = Instance.new("Highlight")
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = character
            highlight.Parent = game.CoreGui

            table.insert(ChamsObjects[player], highlight)

            player.CharacterRemoving:Connect(function()
                if highlight and highlight.Parent then highlight:Destroy() end
            end)
        end

        if player.Character then applyChams(player.Character) end

        player.CharacterAdded:Connect(function(char)
            if Toggles.Chams.Value then applyChams(char) end
        end)
    end


    local function removeTracers()
        for _, obj in pairs(TracerObjects) do
            if obj then obj:Remove() end
        end
        TracerObjects = {}
    end

    local function createTracer(player)
        if player == _Player then return end

        local function applyTracer(character)
            if TracerObjects[player] then
                TracerObjects[player]:Remove()
            end

            local hrp = character:WaitForChild("HumanoidRootPart")

            local line = Drawing.new("Line")
            line.Thickness = 1
            line.Color = Color3.fromRGB(255, 0, 0)
            line.Transparency = 1
            line.Visible = true

            TracerObjects[player] = line

            local connection
            connection = _RunService.RenderStepped:Connect(function()
                if not Toggles.Tracers.Value or not hrp or not hrp.Parent then
                    line:Remove()
                    connection:Disconnect()
                    return
                end

                local screenPos, onScreen = _CurrentCamera:WorldToViewportPoint(hrp.Position)

                if onScreen then
                    line.Visible = true
                    line.From = Vector2.new(_CurrentCamera.ViewportSize.X / 2, _CurrentCamera.ViewportSize.Y)
                    line.To = Vector2.new(screenPos.X, screenPos.Y)
                else
                    line.Visible = false
                end
            end)

            player.CharacterRemoving:Connect(function()
                line:Remove()
                connection:Disconnect()
            end)
        end

        if player.Character then applyTracer(player.Character) end

        player.CharacterAdded:Connect(function(char)
            if Toggles.Tracers.Value then applyTracer(char) end
        end)
    end

    local function removeNametags()
        for _, objects in pairs(NametagObjects) do
            for _, obj in pairs(objects) do
                if obj then obj:Remove() end
            end
        end
        NametagObjects = {}
    end

    local function createNametag(player)
        if player == _Player then return end
        NametagObjects[player] = {}

        local function applyNametag(character)
            if NametagObjects[player] then
                for _, obj in pairs(NametagObjects[player]) do
                    if obj then obj:Remove() end
                end
                NametagObjects[player] = {}
            end

            local hrp = character:WaitForChild("HumanoidRootPart")
            local humanoid = character:WaitForChild("Humanoid")

            local name = Drawing.new("Text")
            name.Text = player.Name
            name.Size = 14
            name.Center = true
            name.Outline = true
            name.OutlineColor = Color3.fromRGB(0, 0, 0)
            name.Color = Color3.fromRGB(255, 255, 255)
            name.Visible = true

            local health = Drawing.new("Text")
            health.Size = 12
            health.Center = true
            health.Outline = true
            health.OutlineColor = Color3.fromRGB(0, 0, 0)
            health.Color = Color3.fromRGB(0, 255, 0)
            health.Visible = true

            table.insert(NametagObjects[player], name)
            table.insert(NametagObjects[player], health)

            local connection
            connection = _RunService.RenderStepped:Connect(function()
                if not Toggles.Nametags.Value or not hrp or not hrp.Parent then
                    name:Remove()
                    health:Remove()
                    connection:Disconnect()
                    return
                end

                local screenPos, onScreen = _CurrentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))

                if onScreen then
                    name.Visible = true
                    health.Visible = true
                    name.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
                    health.Text = string.format("[%d/%d]", humanoid.Health, humanoid.MaxHealth)
                    health.Color = Color3.fromRGB(
                        255 - (humanoid.Health / humanoid.MaxHealth * 255),
                        humanoid.Health / humanoid.MaxHealth * 255,
                        0
                    )
                    health.Position = Vector2.new(screenPos.X, screenPos.Y - 8)
                else
                    name.Visible = false
                    health.Visible = false
                end
            end)

            player.CharacterRemoving:Connect(function()
                name:Remove()
                health:Remove()
                connection:Disconnect()
            end)
        end

        if player.Character then applyNametag(player.Character) end

        player.CharacterAdded:Connect(function(char)
            if Toggles.Nametags.Value then applyNametag(char) end
        end)
    end

    local function removeHealthbars()
        for _, objects in pairs(HealthbarObjects) do
            for _, obj in pairs(objects) do
                if obj then obj:Remove() end
            end
        end
        HealthbarObjects = {}
    end

    local function createHealthbar(player)
        if player == _Player then return end
        HealthbarObjects[player] = {}

        local function applyHealthbar(character)
            if HealthbarObjects[player] then
                for _, obj in pairs(HealthbarObjects[player]) do
                    if obj then obj:Remove() end
                end
                HealthbarObjects[player] = {}
            end

            local hrp = character:WaitForChild("HumanoidRootPart")
            local humanoid = character:WaitForChild("Humanoid")

            local background = Drawing.new("Square")
            background.Filled = true
            background.Color = Color3.fromRGB(0, 0, 0)
            background.Transparency = 1
            background.Visible = true

            local bar = Drawing.new("Square")
            bar.Filled = true
            bar.Transparency = 1
            bar.Visible = true

            local border = Drawing.new("Square")
            border.Filled = false
            border.Color = Color3.fromRGB(0, 0, 0)
            border.Thickness = 1
            border.Transparency = 1
            border.Visible = true

            table.insert(HealthbarObjects[player], background)
            table.insert(HealthbarObjects[player], bar)
            table.insert(HealthbarObjects[player], border)

            local barWidth = 4

            local connection
            connection = _RunService.RenderStepped:Connect(function()
                if not Toggles.Healthbars.Value or not hrp or not hrp.Parent then
                    background:Remove()
                    bar:Remove()
                    border:Remove()
                    connection:Disconnect()
                    return
                end

                local topPos, topOnScreen = _CurrentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local botPos, botOnScreen = _CurrentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                if topOnScreen and botOnScreen then
                    background.Visible = true
                    bar.Visible = true
                    border.Visible = true

                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local xPos = topPos.X - 30
                    local yTop = topPos.Y
                    local dynHeight = botPos.Y - yTop

                    background.Size = Vector2.new(barWidth, dynHeight)
                    background.Position = Vector2.new(xPos, yTop)

                    bar.Size = Vector2.new(barWidth, dynHeight * healthPercent)
                    bar.Position = Vector2.new(xPos, yTop + dynHeight * (1 - healthPercent))
                    bar.Color = Color3.fromRGB(
                        255 - (healthPercent * 255),
                        healthPercent * 255,
                        0
                    )

                    border.Size = Vector2.new(barWidth, dynHeight)
                    border.Position = Vector2.new(xPos, yTop)
                else
                    background.Visible = false
                    bar.Visible = false
                    border.Visible = false
                end
            end)

            player.CharacterRemoving:Connect(function()
                background:Remove()
                bar:Remove()
                border:Remove()
                connection:Disconnect()
            end)
        end

        if player.Character then applyHealthbar(player.Character) end

        player.CharacterAdded:Connect(function(char)
            if Toggles.Healthbars.Value then applyHealthbar(char) end
        end)
    end

    local function getPlayerList()
        local list = {}
        for _, v in pairs(_Players:GetPlayers()) do
            if v ~= _Player then
                table.insert(list, v.Name)
            end
        end
        return list
    end


    UniversalPlayer:AddToggle('FlyToggle', {
        Text = 'Flight',
        Tooltip = 'Toggle Flight',
        Callback = function(value)
            if value then startFly() else stopFly() end
        end
    })

    UniversalPlayer:AddSlider('FlySpeed', {
        Text = 'Flight Speed',
        Default = 60,
        Min = 10,
        Max = 1000,
        Rounding = 1,
        Compact = true,
        Callback = function(value)
            speed = value
        end
    })

    UniversalPlayer:AddLabel("Fly Keybind"):AddKeyPicker("FlyKey", {
        Default = "",
        Mode = "Toggle",
        Text = "Fly Key",
        Callback = function()
            Toggles.FlyToggle:SetValue(not Toggles.FlyToggle.Value)
        end
    })

    UniversalVehicle:AddToggle('VehicleFlyToggle', {
        Text = 'Vehicle Fly',
        Tooltip = 'Must be seated in a vehicle.',
        Default = false,
        Callback = function(value)
            if value then
                if not currentSeat then
                    Toggles.VehicleFlyToggle:SetValue(false) -- fix here
                    return
                end
                startVehicleFly()
            else
                stopVehicleFly()
            end
        end
    })

    UniversalVehicle:AddSlider('VehicleFlySpeed', {
        Text = 'Vehicle Fly Speed',
        Default = 60,
        Min = 10,
        Max = 1000,
        Rounding = 1,
        Compact = true,
        Callback = function(value)
            vehicleSpeed = value
        end
    })

    UniversalVehicle:AddLabel("Vehicle Fly Keybind"):AddKeyPicker("VehicleFlyKey", {
        Default = "",
        Mode = "Toggle",
        Text = "Vehicle Fly Key",
        Callback = function()
            Toggles.VehicleFlyToggle:SetValue(not Toggles.VehicleFlyToggle.Value)
        end
    })

    UniversalPlayer:AddSlider('WalkSpeed', {
        Text = 'WalkSpeed',
        Default = 16,
        Min = 0,
        Max = 250,
        Rounding = 0,
        Callback = function(value)
            _LocalHumanoid.WalkSpeed = value
        end
    })

    if _LocalHumanoid.UseJumpPower == false then
        UniversalPlayer:AddSlider('JumpHeight', {
            Text = 'Jump Height',
            Tooltip = 'Default: 7.2',
            Default = 7.2,
            Min = 0,
            Max = 250,
            Rounding = 1,
            Callback = function(value)
                _LocalHumanoid.JumpHeight = value
            end
        })
    else
        UniversalPlayer:AddSlider('JumpPower', {
            Text = 'Jump Power',
            Tooltip = 'Default: 50',
            Default = 50,
            Min = 0,
            Max = 250,
            Rounding = 0,
            Callback = function(value)
                _LocalHumanoid.JumpPower = value
            end
        })
    end

    UniversalPlayer:AddToggle('InfiniteJump', {
        Text = 'Infinite Jump',
        Default = false
    })

    UniversalPlayer:AddToggle('Platform', {
        Text = 'Platform',
        Tooltip = 'Q = Down, E = Up',
        Default = false,
        Callback = function(value)
            if value then
                platformActive = true
                createPlatform()
            else
                destroyPlatform()
            end
        end
    })

    UniversalPlayer:AddSlider('PlatformSize', {
        Text = 'Platform Size',
        Default = 3,
        Min = 2,
        Max = 5,
        Rounding = 0,
        Compact = true,
        Callback = function(value)
            if platformPart then
                platformPart.Size = Vector3.new(value, 0.5, value)
            end
        end
    })

    UniversalPlayer:AddSlider('PlatformSpeed', {
        Text = 'Platform Speed',
        Default = 2,
        Min = 1,
        Max = 20,
        Rounding = 1,
        Compact = true,
        Callback = function(value)
            platformSpeed = value / 10
        end
    })

    UniversalPlayer:AddToggle('Noclip', {
        Text = 'Noclip',
        Default = false
    })

    UniversalPlayer:AddToggle('ClickTP', {
        Text = 'Click TP',
        Tooltip = 'Left Shift + Left Click',
        Default = false
    })

    local PlayerDropdown = UniversalPlayer:AddDropdown('UniversalPlayerlist', {
        Text = 'Player List',
        Default = nil,
        AllowNull = true,
        Values = {},
        Multi = false,
    })

    UniversalPlayer:AddButton('Teleport to Player', function()
        local targetName = Options.UniversalPlayerlist.Value
        if not targetName or targetName == "" then return end

        local targetPlayer = _Players:FindFirstChild(targetName)
        if not targetPlayer then return end

        local hrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            _LocalRoot.CFrame = hrp.CFrame + hrp.CFrame.LookVector * 3
        end
    end)

    UniversalPlayer:AddButton('Spectate Player', function()
        local targetName = Options.UniversalPlayerlist.Value
        if not targetName or targetName == "" then return end

        local targetPlayer = _Players:FindFirstChild(targetName)
        if not targetPlayer or not targetPlayer.Character then return end

        _CurrentCamera.CameraSubject = targetPlayer.Character:FindFirstChild("Humanoid")
    end)

    UniversalPlayer:AddButton('Stop Spectating', function()
        _CurrentCamera.CameraSubject = _LocalHumanoid
    end)

    -- Utilities
    UniversalVisuals:AddToggle('ESP', {
        Text = 'Player ESP',
        Default = false,
        Callback = function(value)
            if value then
                for _, player in pairs(_Players:GetPlayers()) do createESP(player) end
                _Players.PlayerAdded:Connect(function(player)
                    if Toggles.ESP.Value then createESP(player) end
                end)
            else
                removeESP()
            end
        end
    })

    UniversalVisuals:AddToggle('Boxes', {
        Text = 'ESP Boxes',
        Default = false,
        Callback = function(value)
            if value then
                for _, player in pairs(_Players:GetPlayers()) do createBox(player) end
                _Players.PlayerAdded:Connect(function(player)
                    if Toggles.Boxes.Value then createBox(player) end
                end)
            else
                removeBoxes()
            end
        end
    })

    UniversalVisuals:AddToggle('Chams', {
        Text = 'Chams',
        Default = false,
        Callback = function(value)
            if value then
                for _, player in pairs(_Players:GetPlayers()) do createChams(player) end
                _Players.PlayerAdded:Connect(function(player)
                    if Toggles.Chams.Value then createChams(player) end
                end)
            else
                removeChams()
            end
        end
    })

    UniversalVisuals:AddToggle('Tracers', {
        Text = 'Tracers',
        Default = false,
        Callback = function(value)
            if value then
                for _, player in pairs(_Players:GetPlayers()) do createTracer(player) end
                _Players.PlayerAdded:Connect(function(player)
                    if Toggles.Tracers.Value then createTracer(player) end
                end)
            else
                removeTracers()
            end
        end
    })

    UniversalVisuals:AddToggle('Nametags', {
        Text = 'Nametags',
        Default = false,
        Callback = function(value)
            if value then
                for _, player in pairs(_Players:GetPlayers()) do createNametag(player) end
                _Players.PlayerAdded:Connect(function(player)
                    if Toggles.Nametags.Value then createNametag(player) end
                end)
            else
                removeNametags()
            end
        end
    })

    UniversalVisuals:AddToggle('Healthbars', {
        Text = 'Healthbars',
        Default = false,
        Callback = function(value)
            if value then
                for _, player in pairs(_Players:GetPlayers()) do createHealthbar(player) end
                _Players.PlayerAdded:Connect(function(player)
                    if Toggles.Healthbars.Value then createHealthbar(player) end
                end)
            else
                removeHealthbars()
            end
        end
    })

    _Players.PlayerAdded:Connect(function()
        task.wait(1)
        PlayerDropdown:SetValues(getPlayerList())
    end)

    _Players.PlayerRemoving:Connect(function()
        task.wait(0.1)
        PlayerDropdown:SetValues(getPlayerList())
    end)

    UIReady = true
    task.delay(1, function()
        PlayerDropdown:SetValues(getPlayerList())
    end)
]]--