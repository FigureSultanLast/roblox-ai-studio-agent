--!strict
-- Stud companion plugin.
--
-- Studio's built-in MCP server lets `stud` read the place and run playtests. This
-- plugin adds the rest: it applies an approved turn as one undo step, remembers
-- turns for /rewind, and shows the proof panel. It only talks to `stud` on localhost.

local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

-- Play sessions get their own copy of every plugin. Only the edit copy connects.
if RunService:IsRunning() then
	return
end

local Bridge = require(script.Bridge)
local Turns = require(script.Turns)
local Panel = require(script.Panel)

local panel = Panel.new(plugin)
local toolbar = plugin:CreateToolbar("Stud")
local button = toolbar:CreateButton("Stud", "Show the Stud panel", "")
button.ClickableWhenViewportHidden = true
button.Click:Connect(function()
	panel:toggle()
end)

local bridge
bridge = Bridge.new(function(message)
	if message.type == "apply" then
		local ok, err = Turns.apply(message.turn, message.changes)
		bridge:send({ id = message.id, type = "applied", ok = ok, error = err })
		panel:setTurn(message.turn, if ok then "working" else "failed")
	elseif message.type == "rewind" then
		local undone, err = Turns.rewind(message.to)
		bridge:send({ id = message.id, type = "rewound", undone = undone, error = err })
		panel:setTurns(Turns.list)
	elseif message.type == "proof" then
		panel:setProof(message.proof)
	elseif message.type == "selection" then
		local paths = {}
		for _, instance in Selection:Get() do
			table.insert(paths, instance:GetFullName())
		end
		bridge:send({ id = message.id, type = "selection", paths = paths })
	end
end)

bridge.onStatus = function(connected: boolean, detail: string?)
	panel:setStatus(connected, detail)
end

Selection.SelectionChanged:Connect(function()
	bridge:send({ type = "selection_changed", count = #Selection:Get() })
end)

bridge:connect()
plugin.Unloading:Connect(function()
	bridge:close()
end)
