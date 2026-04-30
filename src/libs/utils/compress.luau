--[[
	******************************************************************************
	* @file		: .../src/utils/compress.lua
	* @author	: Scrpt2r
	* @date		: April 16 2026
	* @lastEdit	: April 17 2026 18:29
	* @brief	: Buffer byte size decreaser.
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

--// Constants
local COMPRESS_THRESHOLD = 64
local WINDOW_SIZE = 4096
local MIN_MATCH = 3
local MAX_MATCH = 18

local COMPRESSED_MAGIC = 0xC0
local RAW_MAGIC = 0x00

--// Functions
function compress(input: buffer): buffer
	local inputLen = buffer.len(input)

	if inputLen < COMPRESS_THRESHOLD then
		local out = buffer.create(inputLen + 1)

		buffer.writeu8(out, 0, RAW_MAGIC)
		buffer.copy(out, 1, input, 0, inputLen)

		return out
	end

	local outData = {} :: { number }
	local i = 0

	local flagBytePos = 0
	local flagBit = 0
	local flagByte = 0

	local function startFlagByte()
		flagBytePos = #outData + 1
		table.insert(outData, 0)

		flagBit = 0
		flagByte = 0
	end

	local function setFlag(isMatch: boolean)
		if isMatch then
			flagByte = flagByte + (1 * (2 ^ (7 - flagBit)))
		end

		flagBit += 1

		if flagBit == 8 then
			outData[flagBytePos] = math.floor(flagByte) % 256

			flagByte = 0
			flagBit = 0
			flagBytePos = 0
		end
	end

	local function flushFlag()
		if flagBytePos > 0 and flagBit > 0 then
			outData[flagBytePos] = math.floor(flagByte) % 256
		end
	end

	startFlagByte()

	while i < inputLen do
		local bestLen = 0
		local bestOffset = 0
		local windowStart = math.max(0, i - WINDOW_SIZE)

		if i >= MIN_MATCH then
			local byte0 = buffer.readu8(input, i)

			for j = windowStart, i, -1 do
				if buffer.readu8(input, j) == byte0 then
					local len = 0

					while
						len < MAX_MATCH
						and (i + len) < inputLen
						and buffer.readu8(input, j + len) == buffer.readu8(input, i + len)
					do
						len += 1
					end

					if len > bestLen then
						bestLen = len
						bestOffset = i - j
					end
				end
			end
		end

		if bestLen >= MIN_MATCH then
			setFlag(true)

			local lenCode = (bestLen - MIN_MATCH) % 16
			local offsetHigh = math.floor(bestOffset / 256) % 16
			local offsetLow = bestOffset % 256

			table.insert(outData, lenCode * 16 + offsetHigh)
			table.insert(outData, offsetLow)

			if flagBit == 0 and flagBytePos == 0 then
				startFlagByte()
			end

			i += bestLen
		else
			setFlag(false)

			table.insert(outData, buffer.readu8(input, i))

			if flagBit == 0 and flagBytePos == 0 then
				startFlagByte()
			end

			i += 1
		end
	end

	flushFlag()

	local outLen = #outData + 1
	local outBuf = buffer.create(outLen)

	buffer.writeu8(outBuf, 0, COMPRESSED_MAGIC)

	for idx, byte in outData do
		buffer.writeu8(outBuf, idx, byte % 256)
	end

	if outLen >= inputLen + 1 then
		local raw = buffer.create(inputLen + 1)

		buffer.writeu8(raw, 0, RAW_MAGIC)
		buffer.copy(raw, 1, input, 0, inputLen)

		return raw
	end

	return outBuf
end

function decompress(input: buffer): buffer
	local magic = buffer.readu8(input, 0)

	if magic == RAW_MAGIC then
		local dataLen = buffer.len(input) - 1
		local out = buffer.create(dataLen)

		buffer.copy(out, 0, input, 1, dataLen)

		return out
	end

	if magic ~= COMPRESSED_MAGIC then
		return input
	end

	local inputLen = buffer.len(input)
	local i = 1
	local out = {} :: { number }

	while i < inputLen do
		local flagByte = buffer.readu8(input, i)
		i += 1

		for bit = 7, 0, -1 do
			if i >= inputLen then
				break
			end

			local isMatch = (math.floor(flagByte / (2 ^ bit)) % 2) == 1

			if isMatch then
				if i + 1 >= inputLen then
					break
				end

				local byte1 = buffer.readu8(input, i)
				local byte2 = buffer.readu8(input, i + 1)
				i += 2

				local lenCode = math.floor(byte1 / 16)
				local offsetHigh = byte1 % 16
				local offsetLow = byte2
				local matchLen = lenCode + MIN_MATCH
				local offset = offsetHigh * 256 + offsetLow

				local startPos = #out - offset + 1
				for k = 0, matchLen - 1 do
					local srcIdx = startPos + k

					if srcIdx >= 1 and srcIdx <= #out then
						table.insert(out, out[srcIdx])
					end
				end
			else
				table.insert(out, buffer.readu8(input, i))
				i += 1
			end
		end
	end

	local outBuf = buffer.create(#out)

	for idx, byte in out do
		buffer.writeu8(outBuf, idx - 1, byte)
	end

	return outBuf
end

function ratio(original: buffer, compressed: buffer): string
	local orig = buffer.len(original)
	local comp = buffer.len(compressed)
	local pct = math.floor((1 - comp / orig) * 100)

	return string.format("%d → %d bytes (%s%d%%)", orig, comp, pct >= 0 and "-" or "+", math.abs(pct))
end

return {
	compress = compress,
	decompress = decompress,
	ratio = ratio,
	THRESHOLD = COMPRESS_THRESHOLD,
}
