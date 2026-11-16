-- vex. NeiroX Precision ESP. full body + draggable drawing menu.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local Settings = {
    Enabled = true, Box = true, Name = true, Health = true, Skeleton = true, Tracer = true, Distance = true,
    MaxDist = 1500,
    Color = Color3.fromRGB(0, 255, 140),
    MenuOpen = true
}

-- ==========================================
-- ESP CORE (Drawing API)
-- ==========================================
local ESP = {}
local SKEL_BONES = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local function newSq() local s=Drawing.new("Square"); s.Thickness=1; s.Filled=false; s.Transparency=1; s.Visible=false; return s end
local function newTx(sz) local t=Drawing.new("Text"); t.Size=sz; t.Center=true; t.Outline=true; t.OutlineColor=Color3.new(0,0,0); t.Transparency=1; t.Visible=false; return t end
local function newLn() local l=Drawing.new("Line"); l.Thickness=1; l.Transparency=1; l.Visible=false; return l end

local function createESP(p)
    if p == LP or ESP[p] then return end
    ESP[p] = {
        box = newSq(), name = newTx(13), hpBg = newSq(), hpFg = newSq(), dist = newTx(12), tracer = newLn(), skel = {}
    }
    ESP[p].hpBg.Filled = true; ESP[p].hpFg.Filled = true
    for i = 1, #SKEL_BONES do ESP[p].skel[i] = newLn() end
end

local function removeESP(p)
    local d = ESP[p]; if not d then return end
    d.box:Remove(); d.name:Remove(); d.hpBg:Remove(); d.hpFg:Remove(); d.dist:Remove(); d.tracer:Remove()
    for _, l in ipairs(d.skel) do l:Remove() end
    ESP[p] = nil
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

-- ==========================================
-- MENU UI (Drawing API)
-- ==========================================
local Menu = {
    Bg = newSq(), Title = newTx(14),
    Toggles = {},
    Pos = Vector2.new(50, 150), Size = Vector2.new(180, 200),
    Dragging = false, DragOffset = Vector2.new()
}
Menu.Bg.Filled = true
Menu.Bg.Color = Color3.fromRGB(20, 20, 25)
Menu.Bg.Transparency = 0.1
Menu.Title.Text = "NeiroX ESP"
Menu.Title.Color = Color3.fromRGB(0, 255, 140)
Menu.Title.Center = false
Menu.Title.Visible = true
Menu.Bg.Visible = true

local toggleList = {
    {key="Box", label="Box"},
    {key="Name", label="Name"},
    {key="Health", label="Health"},
    {key="Skeleton", label="Skeleton"},
    {key="Tracer", label="Tracer"},
    {key="Distance", label="Distance"}
}

for i, t in ipairs(toggleList) do
    local sq = newSq()
    sq.Filled = true; sq.Visible = true
    local txt = newTx(12)
    txt.Center = false; txt.Visible = true
    txt.Text = t.label .. ": ON"
    Menu.Toggles[i] = {sq = sq, txt = txt, key = t.key, baseY = 35 + (i-1)*25}
end

local function renderMenu()
    Menu.Bg.Size = Menu.Size
    Menu.Bg.Position = Menu.Pos
    Menu.Title.Position = Menu.Pos + Vector2.new(10, 8)
    
    for _, t in ipairs(Menu.Toggles) do
        local yPos = Menu.Pos.Y + t.baseY
        t.sq.Size = Vector2.new(Menu.Size.X - 20, 20)
        t.sq.Position = Vector2.new(Menu.Pos.X + 10, yPos)
        t.sq.Color = Settings[t.key] and Color3.fromRGB(0, 100, 60) or Color3.fromRGB(50, 30, 30)
        t.txt.Position = Vector2.new(Menu.Pos.X + 15, yPos + 3)
        t.txt.Text = t.txt.Text:gsub("ON", Settings[t.key] and "ON" or "OFF"):gsub("OFF", Settings[t.key] and "ON" or "OFF")
    end
end

-- ==========================================
-- ICON UI (Instance - CoreGui)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NeiroX_Icon"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Icon = Instance.new("TextButton")
Icon.Size = UDim2.new(0, 40, 0, 40)
Icon.Position = UDim2.new(0, 50, 0, 50)
Icon.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Icon đen
Icon.Text = "N"
Icon.TextColor3 = Color3.fromRGB(0, 255, 140)
Icon.Font = Enum.Font.GothamBold
Icon.TextSize = 20
Icon.Visible = false
Icon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner"); IconCorner.CornerRadius = UDim.new(1, 0); IconCorner.Parent = Icon
local IconStroke = Instance.new("UIStroke"); IconStroke.Color = Color3.fromRGB(0, 255, 140); IconStroke.Thickness = 1.5; IconStroke.Parent = Icon

-- ==========================================
-- INPUT HANDLING (Mouse/Touch)
-- ==========================================
local function inRect(p, pos, size) return p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y end

local isDraggingMenu = false
local isDraggingIcon = false
local iconDragOff = Vector2.new()

-- Xử lý khi bấm chuột
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local mp = UserInputService:GetMouseLocation()

    -- Check Icon
    if not Settings.MenuOpen then
        local iconAbsPos = Vector2.new(Icon.AbsolutePosition.X, Icon.AbsolutePosition.Y)
        local iconAbsSize = Vector2.new(Icon.AbsoluteSize.X, Icon.AbsoluteSize.Y)
        if inRect(mp, iconAbsPos, iconAbsSize) then
            isDraggingIcon = true
            iconDragOff = mp - iconAbsPos
        end
        return
    end

    -- Check Menu Drag
    if inRect(mp, Menu.Pos, Vector2.new(Menu.Size.X, 30)) then
        isDraggingMenu = true
        Menu.Dragging = true
        Menu.DragOffset = mp - Menu.Pos
        return
    end

    -- Check Toggles
    for _, t in ipairs(Menu.Toggles) do
        local tPos = Vector2.new(Menu.Pos.X + 10, Menu.Pos.Y + t.baseY)
        if inRect(mp, tPos, Vector2.new(Menu.Size.X - 20, 20)) then
            Settings[t.key] = not Settings[t.key]
            t.txt.Text = t.txt.Text:gsub("ON", Settings[t.key] and "ON" or "OFF"):gsub("OFF", Settings[t.key] and "ON" or "OFF")
            renderMenu()
            return
        end
    end
end)

-- Xử lý kéo thả
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local mp = UserInputService:GetMouseLocation()

    if isDraggingMenu then
        Menu.Pos = mp - Menu.DragOffset
        renderMenu()
    elseif isDraggingIcon then
        local newPos = mp - iconDragOff
        Icon.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
    end
end)

-- Xử lý thả chuột
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingMenu = false
        Menu.Dragging = false
        if isDraggingIcon then
            isDraggingIcon = false
            -- Nếu click (không kéo) thì mở menu
            local mp = UserInputService:GetMouseLocation()
            local iconAbsPos = Vector2.new(Icon.AbsolutePosition.X, Icon.AbsolutePosition.Y)
            if (mp - iconAbsPos).Magnitude < 10 then
                Settings.MenuOpen = true
                Icon.Visible = false
                Menu.Bg.Visible = true; Menu.Title.Visible = true
                for _, t in ipairs(Menu.Toggles) do t.sq.Visible = true; t.txt.Visible = true end
            end
        end
    end
end)

-- Nút Minimize (Bấm vào chữ "NeiroX ESP" để thu nhỏ)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local mp = UserInputService:GetMouseLocation()
    if Settings.MenuOpen and inRect(mp, Menu.Pos + Vector2.new(10, 8), Vector2.new(100, 20)) then
        -- Thu nhỏ
        Settings.MenuOpen = false
        Menu.Bg.Visible = false; Menu.Title.Visible = false
        for _, t in ipairs(Menu.Toggles) do t.sq.Visible = false; t.txt.Visible = false end
        Icon.Visible = true
        Icon.Position = UDim2.new(0, Menu.Pos.X, 0, Menu.Pos.Y)
    end
end)

-- ==========================================
-- RENDER LOOP (ESP + Menu)
-- ==========================================
RunService.RenderStepped:Connect(function()
    Camera = workspace.CurrentCamera
    if not Camera then return end

    if Settings.MenuOpen then renderMenu() end

    if not Settings.Enabled then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local col = Settings.Color

    for p, d in pairs(ESP) do
        local char = p.Character
        local head = char and char:FindFirstChild("Head")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local foot = char and (char:FindFirstChild("LeftFoot") or char:FindFirstChild("RightFoot"))

        if not head or not hrp or not hum or hum.Health <= 0 or not foot then
            d.box.Visible = false; d.name.Visible = false; d.hpBg.Visible = false; d.hpFg.Visible = false
            d.dist.Visible = false; d.tracer.Visible = false
            for _, l in ipairs(d.skel) do l.Visible = false end
            continue
        end

        local hPos, onH = Camera:WorldToViewportPoint(head.Position)
        local fPos, onF = Camera:WorldToViewportPoint(foot.Position)

        if not onH or not onF then
            d.box.Visible = false; d.name.Visible = false; d.hpBg.Visible = false; d.hpFg.Visible = false
            d.dist.Visible = false; d.tracer.Visible = false
            for _, l in ipairs(d.skel) do l.Visible = false end
            continue
        end

        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
        if dist > Settings.MaxDist then
            d.box.Visible = false; d.name.Visible = false; d.hpBg.Visible = false; d.hpFg.Visible = false
            d.dist.Visible = false; d.tracer.Visible = false
            for _, l in ipairs(d.skel) do l.Visible = false end
            continue
        end

        local h = math.abs(hPos.Y - fPos.Y) * 1.15
        local w = h * 0.45
        local cx = (hPos.X + fPos.X) / 2
        local cy = (hPos.Y + fPos.Y) / 2
        local topX = cx - w / 2
        local topY = cy - h / 2

        -- Box
        d.box.Visible = Settings.Box
        if Settings.Box then
            d.box.Color = col
            d.box.Size = Vector2.new(w, h)
            d.box.Position = Vector2.new(topX, topY)
        end

        -- Name
        d.name.Visible = Settings.Name
        if Settings.Name then
            d.name.Color = col
            d.name.Text = p.Name
            d.name.Position = Vector2.new(cx, topY - 16)
        end

        -- Health
        d.hpBg.Visible = Settings.Health; d.hpFg.Visible = Settings.Health
        if Settings.Health then
            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            d.hpBg.Color = Color3.new(0,0,0)
            d.hpBg.Size = Vector2.new(2, h); d.hpBg.Position = Vector2.new(topX - 5, topY)
            d.hpFg.Color = Color3.fromRGB(math.floor(255*(1-pct)), math.floor(255*pct), 60)
            d.hpFg.Size = Vector2.new(2, h * pct); d.hpFg.Position = Vector2.new(topX - 5, topY + h * (1-pct))
        end

        -- Distance
        d.dist.Visible = Settings.Distance
        if Settings.Distance then
            d.dist.Color = col
            d.dist.Text = math.floor(dist * 0.28) .. "m"
            d.dist.Position = Vector2.new(cx, topY + h + 2)
        end

        -- Tracer
        d.tracer.Visible = Settings.Tracer
        if Settings.Tracer then
            d.tracer.Color = Color3.fromRGB(255, 200, 0)
            d.tracer.From = center
            d.tracer.To = Vector2.new(cx, topY + h)
        end

        -- Skeleton
        if Settings.Skeleton then
            for i, bone in ipairs(SKEL_BONES) do
                local p1 = char:FindFirstChild(bone[1])
                local p2 = char:FindFirstChild(bone[2])
                local line = d.skel[i]
                if p1 and p2 then
                    local v1, o1 = Camera:WorldToViewportPoint(p1.Position)
                    local v2, o2 = Camera:WorldToViewportPoint(p2.Position)
                    if o1 and o2 then
                        line.Visible = true; line.Color = Color3.fromRGB(0, 200, 255)
                        line.From = Vector2.new(v1.X, v1.Y); line.To = Vector2.new(v2.X, v2.Y)
                    else line.Visible = false end
                else line.Visible = false end
            end
        else
            for _, l in ipairs(d.skel) do l.Visible = false end
        end
    end
end)