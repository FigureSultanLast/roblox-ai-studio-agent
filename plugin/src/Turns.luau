--!strict
-- Every approved turn is applied inside one ChangeHistoryService recording, so a
-- single Ctrl+Z undoes the whole turn. If any change fails, the recording is
-- cancelled and Studio rolls the turn back.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ScriptEditorService = game:GetService("ScriptEditorService")

export type Turn = { number: number, title: string }
export type Change = {
	op: "add" | "set" | "remove" | "source",
	path: string,
	class: string?,
	properties: { [string]: any }?,
	attributes: { [string]: any }?,
	source: string?,
}

local Turns = {
	list = {} :: { Turn },
}

-- "ServerScriptService.CoinService" -> the instance, or nil.
local function resolve(path: string): Instance?
	local node: Instance? = game
	for name in string.gmatch(path, "[^%.]+") do
		node = if node then node:FindFirstChild(name) else nil
	end
	return node
end

local function parentAndName(path: string): (Instance?, string)
	local parentPath, name = string.match(path, "^(.*)%.([^%.]+)$")
	return resolve(parentPath or ""), name or path
end

local function decode(value: any): any
	if typeof(value) ~= "table" then
		return value
	elseif value.Vector3 then
		return Vector3.new(table.unpack(value.Vector3))
	elseif value.Color3 then
		return Color3.fromRGB(table.unpack(value.Color3))
	elseif value.Enum then
		return (Enum :: any)[value.Enum[1]][value.Enum[2]]
	end
	return value
end

local function applyChange(change: Change)
	if change.op == "add" then
		local parent, name = parentAndName(change.path)
		assert(parent, `No parent for {change.path}`)
		local instance = Instance.new(change.class :: string)
		instance.Name = name
		for key, value in change.properties or {} do
			(instance :: any)[key] = decode(value)
		end
		for key, value in change.attributes or {} do
			instance:SetAttribute(key, decode(value))
		end
		instance.Parent = parent
	elseif change.op == "set" then
		local instance = assert(resolve(change.path), `Missing {change.path}`)
		for key, value in change.properties or {} do
			(instance :: any)[key] = decode(value)
		end
		for key, value in change.attributes or {} do
			instance:SetAttribute(key, decode(value))
		end
	elseif change.op == "remove" then
		-- Parent to nil instead of Destroy so the change stays undoable.
		local instance = assert(resolve(change.path), `Missing {change.path}`)
		instance.Parent = nil
	elseif change.op == "source" then
		local script = assert(resolve(change.path), `Missing {change.path}`) :: LuaSourceContainer
		ScriptEditorService:UpdateSourceAsync(script, function()
			return change.source :: string
		end)
	end
end

function Turns.apply(turn: Turn, changes: { Change }): (boolean, string?)
	local recording = ChangeHistoryService:TryBeginRecording(`Stud turn {turn.number}`, turn.title)
	if not recording then
		return false, "Studio is in the middle of another change. Try again in a moment."
	end
	local ok, err = pcall(function()
		for _, change in changes do
			applyChange(change)
		end
	end)
	ChangeHistoryService:FinishRecording(
		recording,
		if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
	)
	if ok then
		table.insert(Turns.list, turn)
	end
	return ok, if ok then nil else tostring(err)
end

-- Undo turns newer than `to`. This only works while the newest undo steps are
-- Stud turns. If you edited by hand since then, stud applies the inverse diff instead.
function Turns.rewind(to: number): (number, string?)
	local undone = 0
	while #Turns.list > 0 and Turns.list[#Turns.list].number > to do
		if not ChangeHistoryService:GetCanUndo() then
			return undone, "Studio has nothing left to undo"
		end
		ChangeHistoryService:Undo()
		table.remove(Turns.list)
		undone += 1
	end
	return undone, nil
end

return Turns
