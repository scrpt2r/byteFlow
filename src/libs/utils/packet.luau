--[[
	******************************************************************************
	* @file		: .../src/utils/packet.lua
	* @author	: Scrpt2r
	* @date		: April 16 2026
	* @lastEdit	: April 17 2026 18:30
	* @brief	: Packet handler for ByteFlow.
	* @version	: 0.1.5
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

--// Libs
local types = require(script.Parent.Parent:WaitForChild("global"):WaitForChild("types"))

--// Types
export type _channel = types.channel
type channel = _channel

export type _direction = types.direction
type direction = _direction

export type _packetDef = types.packetDef
type packetDef = _packetDef

--// Variables
local _byName = {} :: { [string]: packetDef }
local _byId = {} :: { [string]: packetDef }
local _nextId = 1

--// Lib Decleration
local packet = {}

--// Lib Functions
function packet.define(name: string, opts: { channel: channel?, direction: direction? }): packetDef
	if _byName[name] then
		return _byName[name]
	end

	local def = {
		id = _nextId,
		name = name,
		channel = opts.channel or "reliable",
		direction = opts.direction or "c2s",
	} :: packetDef

	_byName[name] = def
	_byId[_nextId] = def
	_nextId += 1

	return def
end

function packet.id(name: string): number
	local def = _byName[name]
	return def.id
end

function packet.name(id: number): string
	local def = _byId[id]
	return def and def.name or ("UNKNOWN_" .. tostring(id))
end

function packet.get(name: string): packetDef
	local def = _byName[name]
	return def
end

function packet.getById(id: number): packetDef?
	return _byId[id]
end

function packet.list(): { packetDef }
	local result = {} :: { packetDef }

	for _, def in _byName do
		table.insert(result, def)
	end

	table.sort(result, function(a, b)
		return a.id < b.id
	end)

	return result
end

return packet
