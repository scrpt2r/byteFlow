--[[
	******************************************************************************
	* @file		: .../src/utils/constructor.lua
	* @author	: Scrpt2r
	* @date		: April 16 2026
	* @lastEdit	: April 17 2026 18:31
	* @brief	: Buffer packaging system to reduce network trafficing.
	* @version	: 0.2.0
	******************************************************************************
	* @attention
	*
	* Copyright © 2026 Axon Corporation.
	* All rights reserved.
	*
	* This software is licensed under terms that can be found in the LICENSE file
	* in the root directory of this software component.
	* If no LICENSE file comes with this software, it is provided AS-IS.
	*
	******************************************************************************
--]]

--// Services
local runService = game:GetService("RunService")
local messagingService = game:GetService("MessagingService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

--// Libs
local types = require(script.Parent:WaitForChild("libs"):WaitForChild("global"):WaitForChild("types"))
local bufferLib = require(script.Parent:WaitForChild("libs"):WaitForChild("utils"):WaitForChild("buffer"))
local packet = require(script.Parent:WaitForChild("libs"):WaitForChild("utils"):WaitForChild("packet"))
local compress = require(script.Parent:WaitForChild("libs"):WaitForChild("utils"):WaitForChild("compress"))

--// Types
export type _handler = types.handler
type handler = _handler

export type _encodeResult = types.encodeResult
type encodeResult = _encodeResult

--// Variables
local isServer = runService:IsServer()
local isClient = runService:IsClient()

local encode = bufferLib.encode
local decode = bufferLib.decode

local remoteFolder: Folder
local reliableRemote: RemoteEvent
local unreliableRemote: UnreliableRemoteEvent

local _handlers = {} :: { [string]: { handler } }
local _msHandlers = {} :: { [string]: { handler } }

--// Constants
local REMOTE_FOLDER_NAME = "NetRemotes"
local MS_TOPIC_PREFIX = "Net_"

--// Functions
function setupRemotes()
	if isServer then
		local folder = replicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME) :: Folder?

		if not folder then
			folder = Instance.new("Folder")
			folder.Name = REMOTE_FOLDER_NAME
			folder.Parent = replicatedStorage
		end
		remoteFolder = folder :: Folder

		local function getOrCreate(name: string, class: string): Instance
			local inst = folder:FindFirstChild(name)

			if not inst then
				inst = Instance.new(class)
				inst.Name = name
				inst.Parent = folder
			end

			return inst
		end

		reliableRemote = getOrCreate("Reliable", "RemoteEvent") :: RemoteEvent
		unreliableRemote = getOrCreate("Unreliable", "UnreliableRemoteEvent") :: UnreliableRemoteEvent
	else
		remoteFolder = replicatedStorage:WaitForChild(REMOTE_FOLDER_NAME) :: Folder
		reliableRemote = remoteFolder:WaitForChild("Reliable") :: RemoteEvent
		unreliableRemote = remoteFolder:WaitForChild("Unreliable") :: UnreliableRemoteEvent
	end
end

function pack(result: encodeResult): { any }
	local compressed = compress.compress(result.buf)

	local args = { compressed } :: { any }
	for _, inst in result.instances do
		table.insert(args, inst)
	end

	return args
end

function _unpack(args: { any }): encodeResult?
	local compBuf = args[1]

	local decompressed = compress.decompress(compBuf)
	local instances = {} :: { Instance }

	for i = 2, #args do
		if typeof(args[i]) == "Instance" then
			table.insert(instances, args[i] :: Instance)
		end
	end

	return { buf = decompressed, instances = instances }
end

function addHandler(packetName: string, handler: handler)
	if not _handlers[packetName] then
		_handlers[packetName] = {}
	end

	table.insert(_handlers[packetName], handler)
end

function callHandlers(packetName: string, ...: any)
	local list = _handlers[packetName]
	if not list then
		return
	end

	for _, h in list do
		task.spawn(h, ...)
	end
end

function processArgs(args: { any }, senderPlayer: Player?)
	local result = _unpack(args)
	if not result then
		return
	end

	local ok, err = pcall(function()
		local id, values = decode(result)
		local name = packet.name(id)
		local def = packet.getById(id)

		if not def then
			return
		end

		if isServer and def.direction == "c2c" then
			local target = values[1] :: Player?

			if target and target:IsA("Player") then
				local rem = table.clone(values)

				table.remove(rem, 1)
				table.insert(rem, 1, senderPlayer)

				local outResult = encode(id, table.unpack(rem))
				local outArgs = pack(outResult)

				reliableRemote:FireClient(target, table.unpack(outArgs))
			end

			return
		end

		if senderPlayer then
			callHandlers(name, senderPlayer, table.unpack(values))
		else
			callHandlers(name, table.unpack(values))
		end
	end)

	if not ok then
		warn("byteFlow: packet error:", err)
	end
end

function setupMessaging(packetName: string)
	if not isServer then
		return
	end

	if _msHandlers[packetName] then
		return
	end

	_msHandlers[packetName] = {}

	pcall(function()
		messagingService:SubscribeAsync(MS_TOPIC_PREFIX .. packetName, function(message)
			local data = message.Data :: { any }
			local list = _msHandlers[packetName]

			if list then
				for _, h in list do
					task.spawn(h, table.unpack(data))
				end
			end
		end)
	end)
end

--// Connections
setupRemotes()

if isServer then
	reliableRemote.OnServerEvent:Connect(function(player, ...)
		processArgs({ ... }, player)
	end)
	unreliableRemote.OnServerEvent:Connect(function(player, ...)
		processArgs({ ... }, player)
	end)
else
	reliableRemote.OnClientEvent:Connect(function(...)
		processArgs({ ... }, nil)
	end)
	unreliableRemote.OnClientEvent:Connect(function(...)
		processArgs({ ... }, nil)
	end)
end

--// Lib Decleration
local net = {}

--// Lib Functions
function net.on(packetName: string, handler: handler)
	addHandler(packetName, handler)
end

function net.off(packetName: string, handler: handler?)
	if not handler then
		_handlers[packetName] = {}
		return
	end

	local list = _handlers[packetName]
	if not list then
		return
	end

	for i, h in list do
		if h == handler then
			table.remove(list, i)
			return
		end
	end
end

function net.once(packetName: string, handler: handler)
	local wrapper: handler

	wrapper = function(...)
		net.off(packetName, wrapper)
		handler(...)
	end

	net.on(packetName, wrapper)
end

function net.fire(packetName: string, ...: any)
	local def = packet.get(packetName)
	local id = def.id

	if isClient then
		local result = encode(id, ...)
		local args = pack(result)

		if def.channel == "unreliable" then
			unreliableRemote:FireServer(table.unpack(args))
		else
			reliableRemote:FireServer(table.unpack(args))
		end
	elseif isServer then
		local target = select(1, ...) :: Player
		assert(
			typeof(target) == "Instance" and target:IsA("Player"),
			"byteFlow: Server fire: first argument must be a Player"
		)

		local result = encode(id, select(2, ...))
		local args = pack(result)

		if def.channel == "unreliable" then
			unreliableRemote:FireClient(target, table.unpack(args))
		else
			reliableRemote:FireClient(target, table.unpack(args))
		end
	end
end

function net.broadcast(packetName: string, ...: any)
	assert(isServer, "byteFlow: broadcast can only be used on the server")

	local def = packet.get(packetName)
	local result = encode(def.id, ...)
	local args = pack(result)

	if def.channel == "unreliable" then
		unreliableRemote:FireAllClients(table.unpack(args))
	else
		reliableRemote:FireAllClients(table.unpack(args))
	end
end

function net.fireMany(packetName: string, targets: { Player }, ...: any)
	assert(isServer, "byteFlow: fireMany can only be used on the server")

	local def = packet.get(packetName)
	local result = encode(def.id, ...)
	local args = pack(result)

	for _, player in targets do
		if def.channel == "unreliable" then
			unreliableRemote:FireClient(player, table.unpack(args))
		else
			reliableRemote:FireClient(player, table.unpack(args))
		end
	end
end

function net.fireExpect(packetName: string, expect: Player, ...: any)
	assert(isServer, "byteFlow: fireExpect can only be used on the server")

	local def = packet.get(packetName)
	local result = encode(def.id, ...)
	local args = pack(result)

	for _, player in players:GetPlayers() do
		if player == expect then
			continue
		end

		if def.channel == "unreliable" then
			unreliableRemote:FireClient(player, table.unpack(args))
		else
			reliableRemote:FireClient(player, table.unpack(args))
		end
	end
end

function net.relay(packetName: string, target: Player, ...: any)
	assert(isClient, "byteFlow: relay can only be used on the client")

	local id = packet.id(packetName)
	local result = encode(id, target, ...)
	local args = pack(result)

	reliableRemote:FireServer(table.unpack(args))
end

function net.serverFire(packetName: string, ...: any)
	assert(isServer, "byteFlow: serverFire can only be used on the server")
	setupMessaging(packetName)

	local data = { ... }
	pcall(function()
		messagingService:PublishAsync(MS_TOPIC_PREFIX .. packetName, data)
	end)
end

function net.serverOn(packetName: string, handler: handler)
	assert(isServer, "byteFlow: serverOn can only be used on the server")
	setupMessaging(packetName)

	if not _msHandlers[packetName] then
		_msHandlers[packetName] = {}
	end

	table.insert(_msHandlers[packetName], handler)
end

function net.localFire(packetName: string, ...: any)
	callHandlers(packetName, ...)
end

function net.localOn(packetName: string, handler: handler)
	addHandler(packetName, handler)
end

function net.listPackets()
	return packet.list()
end

function net.messureSize(packetName: string, ...: any)
	local id = packet.id(packetName)
	local result = encode(id, ...)
	local comp = compress.compress(result.buf)

	return {
		raw = buffer.len(result.buf) + 2,
		compressed = buffer.len(comp) + 1,
		instances = #result.instances,
		ratio = compress.ratio(result.buf, comp),
	}
end

return net
