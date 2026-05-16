# encodingTechniques

Collection of encoding and bitwise techniques

## Structure

```
soundHandler.luau/ ← entry point
  ├─ libs ← xor.luau / base64.luau
```

## Usage

```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local xor = require(replicatedStorage.encodingTechniques).xor 
local base64 = require(replicatedStorage.encodingTechniques).base64

local text = "Hello World!"

local bEncoded = base64.encode(text)
local bDecoded = base64.decode(bEncoded)

local encodedHex = xor.encodeHex(text, bEncoded)
local decodedHex = xor.decodeHex(encodedHex, bEncoded)

local encodedText = xor.encodeText(text, bEncoded)
local decodedText = xor.decodeText(encodedText, bEncoded)

print(bEncoded) -- SGVsbG8gV29ybGQh
print(bDecoded) -- Hello World!

print(encodedHex) -- 1B223A1F0D676F08245E5D58
print(decodedHex) -- Hello World!

print(encodedText) --[[":
				       go$^]X]]
print(decodedText) -- Hello World!
```

```lua
local replicatedStorage = game:GetService("ReplicatedStorage")

local xor = require(replicatedStorage.encodingTechniques).xor
local base64 = require(replicatedStorage.encodingTechniques).base64

function encodeToHex(text: string, key: string)
	local k1 = base64.encode(key)
	local k2 = base64.encode(k1)
	
	local step1 = xor.encodeText(text, k1)
	local step2 = xor.encodeHex(step1, k2)

	return step2
end

function encodeToText(text: string, key: string)
	local k1 = base64.encode(key)
	local k2 = base64.encode(k1)
	
	local step1 = xor.encodeHex(text, k1)
	local step2 = xor.encodeText(step1, k2)
	
	return step2
end

function decodeFromHex(encoded: string, key: string)
	local k1 = base64.encode(key)
	local k2 = base64.encode(k1)

	local step1 = xor.decodeHex(encoded, k2)
	local text = xor.decodeText(step1, k1)

	return text
end

function decodeFromText(encoded: string, key: string)
	local k1 = base64.encode(key)
	local k2 = base64.encode(k1)

	local step1 = xor.decodeText(encoded, k2)
	local text = xor.decodeHex(step1, k1)

	return text
end


local text = "Hello World!"
local key = "roblox"

local hex = encodeToHex(text, key)
local normal = encodeToText(text, key)

local decodeHex = decodeFromHex(hex, key)
local decodeText = decodeFromText(normal, key)

print(hex) -- 723A65306C3024135E550C75
print(normal) -- [[kp
                   Tbz}g
                   owwPfzyze]]

print(decodeHex) -- Hello World!
print(decodeText) -- Hello World!
```