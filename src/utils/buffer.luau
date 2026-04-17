--// Libs
local types = require(script.Parent.Parent:WaitForChild("global"):WaitForChild("types"))

--// Types
export type _writerType = types.writerType
type writerType = _writerType

export type _readerType = types.readerType
type readerType = _readerType

export type _encodeResult = types.encodeResult
type encodeResult = _encodeResult

--// Constants
local INITIAL_SIZE = 128
local T = {
	NIL = 0x00,
	BOOL = 0x01,
	F64 = 0x02,
	F32 = 0x03,
	I8 = 0x04,
	U8 = 0x05,
	I16 = 0x06,
	U16 = 0x07,
	I32 = 0x08,
	U32 = 0x09,
	STRING = 0x0A,
	VECTOR3 = 0x0B,
	VECTOR2 = 0x0C,
	CFRAME_FULL = 0x0D,
	CFRAME_AXIAL = 0x0E,
	COLOR3_F = 0x0F,
	COLOR3_RGB = 0x10,
	BRICKCOLOR = 0x11,
	UDIM = 0x12,
	UDIM2 = 0x13,
	RECT = 0x14,
	NUMRANGE = 0x15,
	NUMSEQ = 0x16,
	COLORSEQ = 0x17,
	INSTANCE = 0x18,
	ENUM = 0x19,
	TABLE = 0x1A,
	ARRAY = 0x1B,
	VECTOR4 = 0x1C,
	REGION3 = 0x1D,
	RAY = 0x1E,
}

--// Functions
function growBuffer(w: writerType, need: number)
	if w._cursor + need <= w._size then
		return
	end

	local newSize = w._size
	while newSize < w._cursor + need do
		newSize *= 2
	end

	local newBuf = buffer.create(newSize)
	buffer.copy(newBuf, 0, w._buf, 0, w._cursor)

	w._buf = newBuf
	w._size = newSize
end

--// Writer Decleration
local writer = {}
writer.__index = writer

--// Writer Functions
function writer.new(): writerType
	local self = setmetatable({
		_buf = buffer.create(INITIAL_SIZE),
		_cursor = 0,
		_size = INITIAL_SIZE,
		_instances = {},
	}, writer) :: any

	return self
end

function writer:writeU8(v: number)
	growBuffer(self, 1)

	buffer.writeu8(self._buf, self._cursor, v)
	self._cursor += 1
end

function writer:writeU16(v: number)
	growBuffer(self, 2)

	buffer.writeu16(self._buf, self._cursor, v)
	self._cursor += 2
end

function writer:writeU32(v: number)
	growBuffer(self, 4)

	buffer.writeu32(self._buf, self._cursor, v)
	self._cursor += 4
end

function writer:writeI8(v: number)
	growBuffer(self, 1)

	buffer.writei8(self._buf, self._cursor, v)
	self._cursor += 1
end

function writer:writeI16(v: number)
	growBuffer(self, 2)

	buffer.writei16(self._buf, self._cursor, v)
	self._cursor += 2
end

function writer:writeI32(v: number)
	growBuffer(self, 4)

	buffer.writei32(self._buf, self._cursor, v)
	self._cursor += 4
end

function writer:writeF32(v: number)
	growBuffer(self, 4)

	buffer.writef32(self._buf, self._cursor, v)
	self._cursor += 4
end

function writer:writeF64(v: number)
	growBuffer(self, 8)

	buffer.writef64(self._buf, self._cursor, v)
	self._cursor += 8
end

function writer:writeString(v: string)
	local len = #v
	self:writeU32(len)

	growBuffer(self, len)

	buffer.writestring(self._buf, self._cursor, v)
	self._cursor += len
end

function writer:writeBool(v: boolean)
	self:writeU8(v and 1 or 0)
end

function writer:writeVector3(v: Vector3)
	self:writeF32(v.X)
	self:writeF32(v.Y)
	self:writeF32(v.Z)
end

function writer:writeVector2(v: Vector2)
	self:writeF32(v.X)
	self:writeF32(v.Y)
end

function writer:writeCFrame(v: CFrame)
	local pos = v.Position
	self:writeF32(pos.X)
	self:writeF32(pos.Y)
	self:writeF32(pos.Z)

	local rx, ry, rz = v:ToEulerAnglesXYZ()
	self:writeF32(rx)
	self:writeF32(ry)
	self:writeF32(rz)
end

function writer:writeColor3(v: Color3, compact: boolean?)
	if compact then
		self:writeU8(math.round(v.R * 255))
		self:writeU8(math.round(v.G * 255))
		self:writeU8(math.round(v.B * 255))
	else
		self:writeF32(v.R)
		self:writeF32(v.G)
		self:writeF32(v.B)
	end
end

function writer:writeUDim(v: UDim)
	self:writeF32(v.Scale)
	self:writeI32(v.Offset)
end

function writer:writeUDim2(v: UDim2)
	self:writeF32(v.X.Scale)
	self:writeI32(v.X.Offset)
	self:writeF32(v.Y.Scale)
	self:writeI32(v.Y.Offset)
end

function writer:writeRect(v: Rect)
	self:writeF32(v.Min.X)
	self:writeF32(v.Min.Y)
	self:writeF32(v.Max.X)
	self:writeF32(v.Max.Y)
end

function writer:writeNumRange(v: NumberRange)
	self:writeF32(v.Min)
	self:writeF32(v.Max)
end

function writer:writeInstance(v: Instance)
	table.insert(self._instances, v)
	self:writeU16(#self._instances - 1)
end

function writer:writeEnum(v: EnumItem)
	self:writeString(tostring(v.EnumType) .. "." .. v.Name)
end

function writer:writeValue(v: any)
	local t = typeof(v)

	if v == nil then
		self:writeU8(T.NIL)
	elseif t == "boolean" then
		self:writeU8(T.BOOL)
		self:writeBool(v)
	elseif t == "number" then
		if v == math.floor(v) and v >= -2147483648 and v <= 2147483647 then
			if v >= -128 and v <= 127 then
				self:writeU8(T.I8)
				self:writeI8(v)
			elseif v >= -32768 and v <= 32767 then
				self:writeU8(T.I16)
				self:writeI16(v)
			elseif v >= 0 and v <= 65535 then
				self:writeU8(T.U16)
				self:writeU16(v)
			else
				self:writeU8(T.I32)
				self:writeI32(v)
			end
		else
			local f32 = buffer.create(4)
			buffer.writef32(f32, 0, v)

			if math.abs(buffer.readf32(f32, 0) - v) < 1e-6 then
				self:writeU8(T.F32)
				self:writeF32(v)
			else
				self:writeU8(T.F64)
				self:writeF64(v)
			end
		end
	elseif t == "string" then
		self:writeU8(T.STRING)
		self:writeString(v)
	elseif t == "Vector3" then
		self:writeU8(T.VECTOR3)
		self:writeVector3(v)
	elseif t == "Vector2" then
		self:writeU8(T.VECTOR2)
		self:writeVector2(v)
	elseif t == "CFrame" then
		self:writeU8(T.CFRAME_FULL)
		self:writeCFrame(v)
	elseif t == "Color3" then
		local isRGB = (v.R * 255) == math.floor(v.R * 255)

		if isRGB then
			self:writeU8(T.COLOR3_RGB)
			self:writeColor3(v, true)
		else
			self:writeU8(T.COLOR3_F)
			self:writeColor3(v, false)
		end
	elseif t == "BrickColor" then
		self:writeU8(T.BRICKCOLOR)
		self:writeU16(v.Number)
	elseif t == "UDim" then
		self:writeU8(T.UDIM)
		self:writeUDim(v)
	elseif t == "UDim2" then
		self:writeU8(T.UDIM2)
		self:writeUDim2(v)
	elseif t == "Rect" then
		self:writeU8(T.RECT)
		self:writeRect(v)
	elseif t == "NumberRange" then
		self:writeU8(T.NUMRANGE)
		self:writeNumRange(v)
	elseif t == "NumberSequence" then
		self:writeU8(T.NUMSEQ)

		local kps = v.Keypoints
		self:writeU8(#kps)

		for _, kp in kps do
			self:writeF32(kp.Time)
			self:writeF32(kp.Value)
			self:writeF32(kp.Envelope)
		end
	elseif t == "ColorSequence" then
		self:writeU8(T.COLORSEQ)

		local kps = v.Keypoints
		self:writeU8(#kps)

		for _, kp in kps do
			self:writeF32(kp.Time)
			self:writeColor3(kp.Value, false)
		end
	elseif t == "Instance" then
		self:writeU8(T.INSTANCE)
		self:writeInstance(v)
	elseif t == "EnumItem" then
		self:writeU8(T.ENUM)
		self:writeEnum(v)
	elseif t == "Vector4" then
		self:writeU8(T.VECTOR4)
		self:writeF32(v.X)
		self:writeF32(v.Y)
		self:writeF32(v.Z)
		self:writeF32(v.W)
	elseif t == "Region3" then
		self:writeU8(T.REGION3)
		self:writeVector3(v.CFrame.Position)
		self:writeVector3(v.Size)
	elseif t == "Ray" then
		self:writeU8(T.RAY)
		self:writeVector3(v.Origin)
		self:writeVector3(v.Direction)
	elseif t == "table" then
		local isArray = true
		local count = 0

		for k in v do
			count += 1

			if type(k) ~= "number" or k ~= math.floor(k) then
				isArray = false
				break
			end
		end
		isArray = isArray and (count == #v)

		if isArray then
			self:writeU8(T.ARRAY)
			self:writeU32(#v)

			for _, item in v do
				self:writeValue(item)
			end
		else
			self:writeU8(T.TABLE)
			self:writeU32(count)

			for k, item in v do
				self:writeValue(k)
				self:writeValue(item)
			end
		end
	else
		self:writeU8(T.NIL)
	end
end

function writer:toResult(): encodeResult
	local out = buffer.create(self._cursor)
	buffer.copy(out, 0, self._buf, 0, self._cursor)

	return { buf = out, instances = self._instances }
end

--// Reader Decleration
local reader = {}
reader.__index = reader

--// Reader Functions
function reader.new(buf: buffer, instances: { Instance }): readerType
	return setmetatable({
		_buf = buf,
		_cursor = 0,
		_size = buffer.len(buf),
		_instances = instances or {},
	}, reader) :: any
end

function reader:readU8(): number
	return (function()
		local v = buffer.readu8(self._buf, self._cursor)
		self._cursor += 1

		return v
	end)()
end

function reader:readU16(): number
	return (function()
		local v = buffer.readu16(self._buf, self._cursor)
		self._cursor += 2

		return v
	end)()
end

function reader:readU32(): number
	return (function()
		local v = buffer.readu32(self._buf, self._cursor)
		self._cursor += 4

		return v
	end)()
end

function reader:readI8(): number
	return (function()
		local v = buffer.readi8(self._buf, self._cursor)
		self._cursor += 1

		return v
	end)()
end

function reader:readI16(): number
	return (function()
		local v = buffer.readi16(self._buf, self._cursor)
		self._cursor += 2

		return v
	end)()
end

function reader:readI32(): number
	return (function()
		local v = buffer.readi32(self._buf, self._cursor)
		self._cursor += 4

		return v
	end)()
end

function reader:readF32(): number
	return (function()
		local v = buffer.readf32(self._buf, self._cursor)
		self._cursor += 4

		return v
	end)()
end

function reader:readF64(): number
	return (function()
		local v = buffer.readf64(self._buf, self._cursor)
		self._cursor += 8

		return v
	end)()
end

function reader:readString(): string
	local len = self:readU32()
	local s = buffer.readstring(self._buf, self._cursor, len)
	self._cursor += len

	return s
end

function reader:readBool(): boolean
	return self:readU8() == 1
end

function reader:isEOF(): boolean
	return self._cursor >= self._size
end

function reader:readValue(): any
	if self:isEOF() then
		return nil
	end

	local tag = self:readU8()

	if tag == T.NIL then
		return nil
	elseif tag == T.BOOL then
		return self:readBool()
	elseif tag == T.F64 then
		return self:readF64()
	elseif tag == T.F32 then
		return self:readF32()
	elseif tag == T.I8 then
		return self:readI8()
	elseif tag == T.U8 then
		return self:readU8()
	elseif tag == T.I16 then
		return self:readI16()
	elseif tag == T.U16 then
		return self:readU16()
	elseif tag == T.I32 then
		return self:readI32()
	elseif tag == T.U32 then
		return self:readU32()
	elseif tag == T.STRING then
		return self:readString()
	elseif tag == T.VECTOR3 then
		return Vector3.new(self:readF32(), self:readF32(), self:readF32())
	elseif tag == T.VECTOR2 then
		return Vector2.new(self:readF32(), self:readF32())
	elseif tag == T.CFRAME_FULL then
		local px, py, pz = self:readF32(), self:readF32(), self:readF32()
		local rx, ry, rz = self:readF32(), self:readF32(), self:readF32()

		return CFrame.new(px, py, pz) * CFrame.fromEulerAnglesXYZ(rx, ry, rz)
	elseif tag == T.COLOR3_F then
		return Color3.new(self:readF32(), self:readF32(), self:readF32())
	elseif tag == T.COLOR3_RGB then
		return Color3.fromRGB(self:readU8(), self:readU8(), self:readU8())
	elseif tag == T.BRICKCOLOR then
		return BrickColor.new(self:readU16())
	elseif tag == T.UDIM then
		return UDim.new(self:readF32(), self:readI32())
	elseif tag == T.UDIM2 then
		return UDim2.new(self:readF32(), self:readI32(), self:readF32(), self:readI32())
	elseif tag == T.RECT then
		return Rect.new(self:readF32(), self:readF32(), self:readF32(), self:readF32())
	elseif tag == T.NUMRANGE then
		return NumberRange.new(self:readF32(), self:readF32())
	elseif tag == T.NUMSEQ then
		local count = self:readU8()
		local kps = {} :: { NumberSequenceKeypoint }

		for _ = 1, count do
			table.insert(kps, NumberSequenceKeypoint.new(self:readF32(), self:readF32(), self:readF32()))
		end

		return NumberSequence.new(kps)
	elseif tag == T.COLORSEQ then
		local count = self:readU8()
		local kps = {} :: { ColorSequenceKeypoint }

		for _ = 1, count do
			local t2 = self:readF32()
			local c = Color3.new(self:readF32(), self:readF32(), self:readF32())

			table.insert(kps, ColorSequenceKeypoint.new(t2, c))
		end

		return ColorSequence.new(kps)
	elseif tag == T.INSTANCE then
		local idx = self:readU16()
		return self._instances[idx + 1]
	elseif tag == T.ENUM then
		local str = self:readString()
		local parts = string.split(str, ".")

		local ok, enumItem = pcall(function()
			return (Enum :: any)[parts[1]][parts[2]]
		end)

		return ok and enumItem or nil
	elseif tag == T.REGION3 then
		local pos = Vector3.new(self:readF32(), self:readF32(), self:readF32())
		local size = Vector3.new(self:readF32(), self:readF32(), self:readF32())

		return Region3.new(pos - size / 2, pos + size / 2)
	elseif tag == T.RAY then
		local origin = Vector3.new(self:readF32(), self:readF32(), self:readF32())
		local dir = Vector3.new(self:readF32(), self:readF32(), self:readF32())

		return Ray.new(origin, dir)
	elseif tag == T.ARRAY then
		local count = self:readU32()
		local arr = {}

		for i = 1, count do
			arr[i] = self:readValue()
		end

		return arr
	elseif tag == T.TABLE then
		local count = self:readU32()
		local tbl = {}

		for _ = 1, count do
			local k = self:readValue()
			local v = self:readValue()

			tbl[k] = v
		end

		return tbl
	else
		return nil
	end
end

--// Helper Functions
function encode(packetId: number, ...: any): buffer
	local w = writer.new()
	w:writeU16(packetId)

	for i = 1, select("#", ...) do
		w:writeValue(select(i, ...))
	end

	return w:toResult()
end

function decode(result: encodeResult): (number, { any })
	local r = reader.new(result.buf, result.instances)
	local id = r:readU16()

	local values = {} :: { any }
	while not r:isEOF() do
		table.insert(values, r:readValue())
	end

	return id, values
end

return {
	writer = writer,
	reader = reader,
	encode = encode,
	decode = decode,
	T = T,
}
