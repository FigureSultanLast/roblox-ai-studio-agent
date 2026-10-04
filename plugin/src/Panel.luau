--!strict
-- The Stud panel: connection status, the latest turn with its proof, and earlier
-- turns you can rewind to. The terminal shows the same information.

local Panel = {}
Panel.__index = Panel

local GREEN = Color3.fromRGB(127, 212, 154)
local INK = Color3.fromRGB(230, 231, 234)
local DIM = Color3.fromRGB(140, 144, 155)

local function make(class: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(class)
	for key, value in props do
		(instance :: any)[key] = value
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	return instance
end

local function label(text: string, props: { [string]: any }?): TextLabel
	local base = {
		Text = text,
		BackgroundTransparency = 1,
		Font = Enum.Font.BuilderSans,
		TextSize = 14,
		TextColor3 = INK,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		TextWrapped = true,
	}
	for key, value in props or {} do
		base[key] = value
	end
	return make("TextLabel", base)
end

function Panel.new(plugin: Plugin)
	local self = setmetatable({}, Panel)
	local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 340, 560, 280, 360)
	self.widget = plugin:CreateDockWidgetPluginGui("Stud", info)
	self.widget.Title = "Stud"

	self.status = label("Waiting for stud", { TextColor3 = DIM, LayoutOrder = 1 })
	self.turn = label("No turns yet", { Font = Enum.Font.BuilderSansBold, LayoutOrder = 2 })
	self.shot = make("ImageLabel", {
		Size = UDim2.new(1, 0, 0, 170),
		BackgroundColor3 = Color3.fromRGB(42, 45, 52),
		ScaleType = Enum.ScaleType.Crop,
		Visible = false,
		LayoutOrder = 3,
	}, { make("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	self.checks = make("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 4 }, {
		make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	self.earlier = make("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 5 }, {
		make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	make("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(28, 29, 34),
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 4,
		Parent = self.widget,
	}, {
		make("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14) }),
		make("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
		self.status, self.turn, self.shot, self.checks, self.earlier,
	})
	return self
end

function Panel:toggle()
	self.widget.Enabled = not self.widget.Enabled
end

function Panel:setStatus(connected: boolean, detail: string?)
	self.status.Text = if connected then "Connected to stud" else detail or "Waiting for stud"
	self.status.TextColor3 = if connected then GREEN else DIM
end

function Panel:setTurn(turn: { number: number, title: string }, state: string)
	self.turn.Text = `Turn {turn.number} · {turn.title}` .. if state == "failed" then " (not applied)" else ""
	self.shot.Visible = false
	for _, child in self.checks:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

-- proof = { checks = { { passed, text } }, image = content id from the MCP server's store_image }
function Panel:setProof(proof: { checks: { { passed: boolean, text: string } }, image: string? })
	for i, check in proof.checks do
		label(`{if check.passed then "✓" else "✕"}  {check.text}`, {
			TextColor3 = if check.passed then INK else Color3.fromRGB(239, 125, 125),
			LayoutOrder = i,
			Parent = self.checks,
		})
	end
	if proof.image then
		self.shot.Image = proof.image
		self.shot.Visible = true
	end
end

function Panel:setTurns(list: { { number: number, title: string } })
	for _, child in self.earlier:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	for i = #list - 1, math.max(1, #list - 4), -1 do
		local turn = list[i]
		label(`{turn.number}   {turn.title}`, { TextColor3 = DIM, LayoutOrder = #list - i, Parent = self.earlier })
	end
	self.earlier.Visible = #list > 1
end

return Panel
