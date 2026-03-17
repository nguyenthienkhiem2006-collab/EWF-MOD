--// CONFIG
local KEY_URL = "https://raw.githubusercontent.com/tenban/ewf-mod/main/keys.txt"
local GET_KEY_LINK = "https://linkcuaban.com"

--// LOAD KEY
local validKeys = {}

local success, data = pcall(function()
    return game:HttpGet(KEY_URL)
end)

if success then
    for line in string.gmatch(data, "[^\r\n]+") do
        local key, date = line:match("([^|]+)|([^|]+)")
        if key and date then
            validKeys[key] = date
        end
    end
end

--// CHECK TIME
local function expired(d)
    local y,m,day = d:match("(%d+)%-(%d+)%-(%d+)")
    local now = os.date("*t")

    local exp = os.time({year=y,month=m,day=day})
    local cur = os.time({year=now.year,month=now.month,day=now.day})

    return cur > exp
end

--// KEY GUI
local gui = Instance.new("ScreenGui", game.CoreGui)

local f = Instance.new("Frame", gui)
f.Size = UDim2.new(0,260,0,180)
f.Position = UDim2.new(0.5,-130,0.5,-90)
f.BackgroundColor3 = Color3.fromRGB(20,20,20)
f.Active = true
f.Draggable = true

local t = Instance.new("TextLabel", f)
t.Size = UDim2.new(1,0,0,30)
t.Text = "EWF MOD | KEY"
t.TextColor3 = Color3.new(1,1,1)
t.BackgroundTransparency = 1

local box = Instance.new("TextBox", f)
box.Size = UDim2.new(1,-20,0,35)
box.Position = UDim2.new(0,10,0,50)
box.PlaceholderText = "Nhập key..."

local ok = Instance.new("TextButton", f)
ok.Size = UDim2.new(1,-20,0,30)
ok.Position = UDim2.new(0,10,0,95)
ok.Text = "XÁC NHẬN"

local get = Instance.new("TextButton", f)
get.Size = UDim2.new(1,-20,0,25)
get.Position = UDim2.new(0,10,0,130)
get.Text = "GET KEY"

get.MouseButton1Click:Connect(function()
    setclipboard(GET_KEY_LINK)
    get.Text = "ĐÃ COPY LINK"
end)

local pass = false

ok.MouseButton1Click:Connect(function()
    local k = box.Text

    if validKeys[k] then
        if not expired(validKeys[k]) then
            pass = true
            gui:Destroy()
        else
            ok.Text = "KEY HẾT HẠN"
        end
    else
        ok.Text = "KEY SAI"
    end
end)

repeat task.wait() until pass

--// ===== LOAD MAIN SCRIPT =====
-- (DÁN SCRIPT EWF PRO BÊN DƯỚI)
--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// SETTINGS
local AIM_ENABLED = false
local AIM_STRENGTH = 0.2
local FOV = 120

local ESP_ENABLED = true
local ESP_HEALTH = true
local ESP_NAME = true
local ESP_DISTANCE = true

--// UI
local gui = Instance.new("ScreenGui", game.CoreGui)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,260,0,320)
frame.Position = UDim2.new(0,20,0.5,-160)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "EWF MOD PRO"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

--// TOGGLE UI
local function toggleBtn(text, y, var)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,-20,0,30)
    btn.Position = UDim2.new(0,10,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.new(1,1,1)

    local state = false
    btn.Text = text.." : OFF"

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text.." : "..(state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(40,40,40)
        var(state)
    end)
end

--// TOGGLES
toggleBtn("AIMBOT",40,function(v) AIM_ENABLED = v end)
toggleBtn("ESP",80,function(v) ESP_ENABLED = v end)
toggleBtn("ESP HEALTH",120,function(v) ESP_HEALTH = v end)
toggleBtn("ESP NAME",160,function(v) ESP_NAME = v end)
toggleBtn("ESP DIST",200,function(v) ESP_DISTANCE = v end)

--// FOV BUTTON
local fovBtn = Instance.new("TextButton", frame)
fovBtn.Size = UDim2.new(1,-20,0,30)
fovBtn.Position = UDim2.new(0,10,0,240)
fovBtn.Text = "FOV: "..FOV

fovBtn.MouseButton1Click:Connect(function()
    FOV += 20
    if FOV > 300 then FOV = 60 end
    fovBtn.Text = "FOV: "..FOV
end)

--// ESP TABLE
local espTable = {}

local function createESP(player)
    if player == LocalPlayer then return end

    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false

    local name = Drawing.new("Text")
    name.Size = 13
    name.Center = true
    name.Outline = true

    local hpBar = Drawing.new("Line")
    hpBar.Thickness = 3

    espTable[player] = {box = box, name = name, hp = hpBar}
end

for _,p in pairs(Players:GetPlayers()) do
    createESP(p)
end

Players.PlayerAdded:Connect(createESP)

--// GET TARGET (KHÔNG AIM TEAM)
local function getTarget()
    local closest = nil
    local distMax = FOV

    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            if p.Team == LocalPlayer.Team then continue end

            local pos, onscreen = Camera:WorldToViewportPoint(p.Character.Head.Position)

            if onscreen then
                local dist = (Vector2.new(pos.X,pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude

                if dist < distMax then
                    distMax = dist
                    closest = p
                end
            end
        end
    end

    return closest
end

--// MAIN LOOP
RunService.RenderStepped:Connect(function()
    for player,esp in pairs(espTable) do
        local char = player.Character

        if char and char:FindFirstChild("HumanoidRootPart") then
            local root = char.HumanoidRootPart
            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChild("Humanoid")

            local pos, visible = Camera:WorldToViewportPoint(root.Position)

            if visible and ESP_ENABLED then
                local size = 50

                esp.box.Size = Vector2.new(size, size*1.5)
                esp.box.Position = Vector2.new(pos.X - size/2, pos.Y - size)
                esp.box.Color = (player.Team == LocalPlayer.Team) and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
                esp.box.Visible = true

                if ESP_NAME then
                    esp.name.Text = player.Name
                    esp.name.Position = Vector2.new(pos.X, pos.Y - size - 15)
                    esp.name.Visible = true
                else
                    esp.name.Visible = false
                end

                if ESP_DISTANCE then
                    local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)
                    esp.name.Text = player.Name.." ["..dist.."m]"
                end

                if ESP_HEALTH and humanoid then
                    local hp = humanoid.Health / humanoid.MaxHealth
                    esp.hp.From = Vector2.new(pos.X - size/2 - 5, pos.Y + size)
                    esp.hp.To = Vector2.new(pos.X - size/2 - 5, pos.Y + size - (hp * size*1.5))
                    esp.hp.Color = Color3.fromRGB(0,255,0)
                    esp.hp.Visible = true
                else
                    esp.hp.Visible = false
                end
            else
                esp.box.Visible = false
                esp.name.Visible = false
                esp.hp.Visible = false
            end
        end
    end

    -- AIM
    if AIM_ENABLED then
        local target = getTarget()

        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head.Position
            local cf = Camera.CFrame
            Camera.CFrame = cf:Lerp(CFrame.new(cf.Position, head), AIM_STRENGTH)
        end
    end
end)
