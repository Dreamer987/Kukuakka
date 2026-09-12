--// KATANA CYAN LIGHTNING + ELECTRIC MODE + DASH ELECTRIC
--// Delta / Client Side

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local LocalPlayer=Players.LocalPlayer
local PickItem=workspace:WaitForChild("PickItem")

local CrucibleBlade=PickItem:WaitForChild("Crucible"):WaitForChild("Crucible"):WaitForChild("WeldParts"):WaitForChild("Blade")
local LightningSource=CrucibleBlade:FindFirstChild("Lightning")
local Effect9Source=CrucibleBlade:GetChildren()[9]

local CYAN=Color3.fromRGB(0,220,255)
local CYAN_BRIGHT=Color3.fromRGB(80,255,255)
local SOUND_ID="rbxassetid://71077603322725"

local ELECTRIC_SPEED=30.1
local ELECTRIC_JUMP=59
local ELECTRIC_GRAVITY=121
local ACTIVE_TIME=45
local ELECTRIC_COOLDOWN=90
local DASH_DISTANCE= 16.9
local DASH_COOLDOWN= 4
local DASH_TIME= 0.18

local LastKatana=nil
local ElectricActive=false
local OnElectricCooldown=false
local DashCooldown=false
local ElectricStart=0
local ElectricGui=nil
local PlayerEffectFolder=nil
local OldWalkSpeed=nil
local OldJumpPower=nil
local OldGravity=nil

local function ColorEffect(o)
	if o:IsA("BasePart") then o.Color=CYAN o.Material=Enum.Material.Neon end
	if o:IsA("ParticleEmitter") or o:IsA("Beam") or o:IsA("Trail") then
		o.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,CYAN_BRIGHT),ColorSequenceKeypoint.new(.5,CYAN),ColorSequenceKeypoint.new(1,CYAN_BRIGHT)})
	end
	if o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then o.Color=CYAN end
	if o:IsA("Highlight") then o.FillColor=CYAN o.OutlineColor=CYAN_BRIGHT end
	for _,c in ipairs(o:GetChildren()) do ColorEffect(c) end
end

local function GetBlade(k)
	if not k then return nil end
	local b=k:FindFirstChild("Blade",true)
	if b then return b end
	if k:IsA("BasePart") then return k end
	return k:FindFirstChildWhichIsA("BasePart",true)
end

local function AddKatanaEffects(k)
	local b=GetBlade(k)
	if not b then return end
	for _,o in ipairs(b:GetChildren()) do
		if o.Name=="Lightning_Cyan" or o.Name=="Effect9_Cyan" then o:Destroy() end
	end
	if LightningSource then
		local x=LightningSource:Clone()
		x.Name="Lightning_Cyan" x.Parent=b ColorEffect(x)
	end
	if Effect9Source then
		local x=Effect9Source:Clone()
		x.Name="Effect9_Cyan" x.Parent=b ColorEffect(x)
	end
end

local function PlaySound(parent)
	if not parent then return end
	local s=Instance.new("Sound")
	s.Name="ElectricSound" s.SoundId=SOUND_ID s.Volume=1
	s.RollOffMaxDistance=80 s.RollOffMinDistance=5 s.Parent=parent
	s:Play()
	s.Ended:Connect(function() if s then s:Destroy() end end)
end

local function PlayEquipSound(k)
	PlaySound(GetBlade(k) or k)
end

local function RemovePlayerEffect()
	if PlayerEffectFolder then PlayerEffectFolder:Destroy() PlayerEffectFolder=nil end
end

local function CreatePlayerEffect()
	RemovePlayerEffect()
	local ch=LocalPlayer.Character
	local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	PlayerEffectFolder=Instance.new("Folder")
	PlayerEffectFolder.Name="ElectricMode_PlayerEffect"
	PlayerEffectFolder.Parent=ch
	for i,src in ipairs({LightningSource,Effect9Source}) do
		if src then
			local a=Instance.new("Attachment")
			a.Name="ElectricHolder"..i a.Parent=hrp
			local x=src:Clone()
			x.Name="Player_Cyan_Effect"..i x.Parent=a ColorEffect(x)
		end
	end
end

local function UpdateButtons()
	if not ElectricGui then return end
	local eb=ElectricGui:FindFirstChild("ElectricButton",true)
	local db=ElectricGui:FindFirstChild("DashButton",true)
	if eb then
		if ElectricActive then
			eb.Text="⚡ Electric\n"..math.ceil(math.max(0,ACTIVE_TIME-(os.clock()-ElectricStart))).."s"
		elseif OnElectricCooldown then
			eb.Text="⏳ Electric\nCooldown"
		else
			eb.Text="⚡ Electric\nmode"
		end
	end
	if db then db.Text=DashCooldown and "⚡\nWAIT" or "⚡\nDASH" end
end

local function DashElectric()
	if DashCooldown then return end
	local ch=LocalPlayer.Character
	local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
	local hum=ch and ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then return end
	DashCooldown=true
	local start=hrp.Position
	local cf=hrp.CFrame
	local target=start+cf.LookVector*DASH_DISTANCE
	local p=RaycastParams.new()
	p.FilterType=Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances={ch}
	local hit=workspace:Raycast(start,cf.LookVector*DASH_DISTANCE,p)
	if hit then target=hit.Position-cf.LookVector*2 end

	local folder=Instance.new("Folder")
	folder.Name="ElectricDashEffect" folder.Parent=workspace
	local p0=Instance.new("Part")
	p0.Anchored=true p0.CanCollide=false p0.CanQuery=false p0.Transparency=1 p0.Size=Vector3.new(.2,.2,.2) p0.Position=start p0.Parent=folder
	local p1=p0:Clone() p1.Position=target p1.Parent=folder
	local a0=Instance.new("Attachment",p0)
	local a1=Instance.new("Attachment",p1)
	local beam=Instance.new("Beam")
	beam.Attachment0=a0 beam.Attachment1=a1 beam.Width0=1.2 beam.Width1=.1
	beam.LightEmission=1 beam.LightInfluence=0 beam.CurveSize0=2 beam.CurveSize1=-2
	beam.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,CYAN_BRIGHT),ColorSequenceKeypoint.new(.5,CYAN),ColorSequenceKeypoint.new(1,CYAN_BRIGHT)})
	beam.Parent=folder
	for i=1,3 do
		local b=beam:Clone()
		b.Name="ElectricLine"..i b.Width0=.3 b.Width1=.04 b.CurveSize0=math.random(-5,5) b.CurveSize1=math.random(-5,5) b.Parent=folder
	end
	PlaySound(hrp)
	local t=os.clock()
	local con
	con=RunService.RenderStepped:Connect(function()
		if not hrp.Parent then con:Disconnect() return end
		local a=math.clamp((os.clock()-t)/DASH_TIME,0,1)
		local s=1-(1-a)^3
		local pos=start:Lerp(target,s)
		hrp.CFrame=CFrame.new(pos,pos+cf.LookVector)
		if a>=1 then con:Disconnect() end
	end)
	task.delay(.3,function() if folder then folder:Destroy() end end)
	task.delay(DASH_COOLDOWN,function() DashCooldown=false end)
end

local function CreateGui()
	if ElectricGui then ElectricGui:Destroy() end
	local gui=Instance.new("ScreenGui")
	gui.Name="ElectricModeGui" gui.ResetOnSpawn=false gui.IgnoreGuiInset=true gui.Parent=game:GetService("CoreGui")
	ElectricGui=gui

	local e=Instance.new("TextButton")
	e.Name="ElectricButton" e.Size=UDim2.new(0,150,0,50) e.Position=UDim2.new(0,20,.5,-70)
	e.BackgroundColor3=Color3.fromRGB(15,30,35) e.TextColor3=CYAN_BRIGHT e.Text="⚡ Electric\nmode" e.TextSize=15 e.Font=Enum.Font.GothamBold e.Parent=gui
	Instance.new("UICorner",e).CornerRadius=UDim.new(0,12)
	local es=Instance.new("UIStroke",e) es.Color=CYAN es.Thickness=2

	e.MouseButton1Click:Connect(function()
		if ElectricActive or OnElectricCooldown then return end
		ElectricActive=true ElectricStart=os.clock()
		local ch=LocalPlayer.Character local h=ch and ch:FindFirstChildOfClass("Humanoid")
		if h then OldWalkSpeed=h.WalkSpeed OldJumpPower=h.JumpPower end
		OldGravity=workspace.Gravity
		CreatePlayerEffect()
		task.spawn(function()
			task.wait(ACTIVE_TIME)
			if not ElectricActive then return end
			ElectricActive=false RemovePlayerEffect()
			local c=LocalPlayer.Character local h2=c and c:FindFirstChildOfClass("Humanoid")
			if h2 then h2.WalkSpeed=OldWalkSpeed or h2.WalkSpeed h2.UseJumpPower=true h2.JumpPower=OldJumpPower or h2.JumpPower end
			workspace.Gravity=OldGravity or workspace.Gravity
			OnElectricCooldown=true
			task.wait(ELECTRIC_COOLDOWN)
			OnElectricCooldown=false
		end)
	end)

	local d=Instance.new("TextButton")
	d.Name="DashButton" d.Size=UDim2.new(0,68,0,68) d.Position=UDim2.new(1,-90,1,-150)
	d.BackgroundColor3=Color3.fromRGB(0,85,100) d.TextColor3=CYAN_BRIGHT d.Text="⚡\nDASH" d.TextSize=13 d.Font=Enum.Font.GothamBold d.Parent=gui
	Instance.new("UICorner",d).CornerRadius=UDim.new(1,0)
	local ds=Instance.new("UIStroke",d) ds.Color=CYAN_BRIGHT ds.Thickness=2
	d.MouseButton1Click:Connect(DashElectric)
end

RunService.Heartbeat:Connect(function()
	if ElectricActive then
		local ch=LocalPlayer.Character local h=ch and ch:FindFirstChildOfClass("Humanoid")
		if h then h.WalkSpeed=ELECTRIC_SPEED h.UseJumpPower=true h.JumpPower=ELECTRIC_JUMP end
		workspace.Gravity=ELECTRIC_GRAVITY
	end
	UpdateButtons()
end)

local function CheckKatana()
	local ch=LocalPlayer.Character if not ch then return end
	local k=ch:FindFirstChild("Katana")
	if k and LastKatana~=k then
		LastKatana=k task.wait(.1)
		AddKatanaEffects(k) PlayEquipSound(k) CreateGui()
	elseif not k and LastKatana then
		LastKatana=nil
		if ElectricGui then ElectricGui:Destroy() ElectricGui=nil end
	end
end

local function SetupCharacter(ch)
	LastKatana=nil
	ch.ChildAdded:Connect(function(x)
		if x.Name=="Katana" then
			task.wait(.1)
			if x.Parent==ch then
				LastKatana=x AddKatanaEffects(x) PlayEquipSound(x) CreateGui()
			end
		end
	end)
	ch.ChildRemoved:Connect(function(x)
		if x.Name=="Katana" then
			LastKatana=nil
			if ElectricGui then ElectricGui:Destroy() ElectricGui=nil end
		end
	end)
	task.delay(.3,CheckKatana)
end

if LocalPlayer.Character then SetupCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(ch)
	if ElectricGui then ElectricGui:Destroy() ElectricGui=nil end
	SetupCharacter(ch)
end)

task.spawn(function()
	while task.wait(.25) do CheckKatana() end
end)

print("⚡ KATANA CYAN + ELECTRIC MODE + DASH ELECTRIC LOADED")
