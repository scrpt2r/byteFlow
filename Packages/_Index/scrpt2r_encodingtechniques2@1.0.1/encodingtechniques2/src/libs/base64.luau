--// Constants
local CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

--// Lib Decleration
local base64 = {}

--// Lib Public Functions
function base64.encode(data: string)
	assert(type(data) == "string", "data must be a string.")

	local result = {}
	local padding = 0

	for i = 1, #data, 3 do
		local b1 = string.byte(data, i)
		local b2 = string.byte(data, i + 1)
		local b3 = string.byte(data, i + 2)

		local n1 = bit32.rshift(b1, 2)
		local n2 = bit32.bor(bit32.lshift(bit32.band(b1, 0x03), 4), b2 and bit32.rshift(b2, 4) or 0)
		local n3 = b2 and bit32.bor(bit32.lshift(bit32.band(b2, 0x0F), 2), b3 and bit32.rshift(b3, 6) or 0) or nil
		local n4 = b3 and bit32.band(b3, 0x3F) or nil

		table.insert(result, string.sub(CHARS, n1 + 1, n1 + 1))
		table.insert(result, string.sub(CHARS, n2 + 1, n2 + 1))

		if n3 ~= nil then
			table.insert(result, string.sub(CHARS, n3 + 1, n3 + 1))
		else
			table.insert(result, "=")
			padding = padding + 1
		end

		if n4 ~= nil then
			table.insert(result, string.sub(CHARS, n4 + 1, n4 + 1))
		else
			table.insert(result, "=")
		end
	end

	return table.concat(result)
end

function base64.decode(b64: string)
	assert(type(b64) == "string", "b64 must be a string")

	local lookup = {}
	for i = 1, #CHARS do
		lookup[string.sub(CHARS, i, i)] = i - 1
	end

	local result = {}
	local i = 1

	while i <= #b64 do
		local c1 = lookup[string.sub(b64, i, i)]
		local c2 = lookup[string.sub(b64, i + 1, i + 1)]

		local c3 = string.sub(b64, i + 2, i + 2)
		local c4 = string.sub(b64, i + 3, i + 3)

		local n3 = lookup[c3]
		local n4 = lookup[c4]

		table.insert(result, string.char(bit32.bor(bit32.lshift(c1, 2), bit32.rshift(c2, 4))))

		if c3 ~= "=" and n3 then
			table.insert(result, string.char(bit32.band(bit32.bor(bit32.lshift(c2, 4), bit32.rshift(n3, 2)), 0xFF)))
		end

		if c4 ~= "=" and n4 then
			table.insert(result, string.char(bit32.band(bit32.bor(bit32.lshift(n3, 6), n4), 0xFF)))
		end

		i = i + 4
	end

	return table.concat(result)
end

return base64
