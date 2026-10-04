--!strict
-- The connection to `stud` on this computer. It uses a WebSocket, and falls back
-- to polling over HTTP if the WebSocket client isn't available.

local HttpService = game:GetService("HttpService")

local PORT = 44877

export type Message = { [string]: any }

local Bridge = {}
Bridge.__index = Bridge

function Bridge.new(onMessage: (Message) -> ())
	local self = setmetatable({}, Bridge)
	self.onMessage = onMessage
	self.onStatus = function(_connected: boolean, _detail: string?) end
	self.client = nil :: any
	self.closed = false
	return self
end

function Bridge:connect()
	local ok, client = pcall(function()
		return HttpService:CreateWebStreamClient(Enum.WebStreamClientType.WebSocket, {
			Url = `ws://localhost:{PORT}/plugin`,
		})
	end)
	if not ok then
		self:poll()
		return
	end
	self.client = client
	client.Opened:Connect(function()
		self.onStatus(true, nil)
		self:send({ type = "hello", place = game.Name, placeId = game.PlaceId })
	end)
	client.MessageReceived:Connect(function(text: string)
		self.onMessage(HttpService:JSONDecode(text))
	end)
	client.Closed:Connect(function()
		self.client = nil
		self.onStatus(false, "Waiting for stud")
		if not self.closed then
			task.delay(2, function()
				self:connect()
			end)
		end
	end)
end

function Bridge:send(message: Message)
	local text = HttpService:JSONEncode(message)
	if self.client then
		self.client:Send(text)
	else
		pcall(HttpService.PostAsync, HttpService, `http://localhost:{PORT}/plugin`, text, Enum.HttpContentType.ApplicationJson)
	end
end

function Bridge:poll()
	task.spawn(function()
		while not self.closed do
			local ok, response = pcall(HttpService.RequestAsync, HttpService, {
				Url = `http://localhost:{PORT}/plugin/next`,
				Method = "GET",
			})
			if ok and response.Success then
				self.onStatus(true, nil)
				if response.Body ~= "" then
					self.onMessage(HttpService:JSONDecode(response.Body))
				end
			else
				self.onStatus(false, "Waiting for stud")
				task.wait(2)
			end
		end
	end)
end

function Bridge:close()
	self.closed = true
	if self.client then
		self.client:Close()
	end
end

return Bridge
