--// Lib Decleration
local types = {}

export type writerType = {
	_buf: buffer,
	_cursor: number,
	_size: number,

	writeU8: (self: writerType, v: number) -> (),
	writeU16: (self: writerType, v: number) -> (),
	writeU32: (self: writerType, v: number) -> (),
	writeI8: (self: writerType, v: number) -> (),
	writeI16: (self: writerType, v: number) -> (),
	writeI32: (self: writerType, v: number) -> (),
	writeI64: (self: writerType, v: number) -> (),
	writeString: (self: writerType, v: string) -> (),
	writeBool: (self: writerType, v: boolean) -> (),

	writeVector3: (self: writerType, v: Vector3) -> (),
	writeVector2: (self: writerType, v: Vector2) -> (),
	writeCFrame: (self: writerType, v: CFrame) -> (),
	writeColor3: (self: writerType, v: Color3, compact: boolean?) -> (),
	writeUDim: (self: writerType, v: UDim) -> (),
	writeUDim2: (self: writerType, v: UDim2) -> (),
	writeRect: (self: writerType, v: Rect) -> (),
	writeNumRange: (self: writerType, v: NumberRange) -> (),
	writeInstance: (self: writerType, v: Instance) -> (),
	writeEnum: (self: writerType, v: EnumItem) -> (),
	writeValue: (self: writerType, v: any) -> (),

	toBuffer: (self: writerType) -> buffer,
}

export type readerType = {
	_buf: buffer,
	_cursor: number,
	_size: number,

	readU8: (self: readerType) -> number,
	readU16: (self: readerType) -> number,
	readU32: (self: readerType) -> number,
	readI8: (self: readerType) -> number,
	readI16: (self: readerType) -> number,
	readI32: (self: readerType) -> number,
	readF32: (self: readerType) -> number,
	readF64: (self: readerType) -> number,
	readString: (self: readerType) -> string,
	readBool: (self: readerType) -> boolean,
	readValue: (self: readerType) -> any,
	isEOF: (self: readerType) -> boolean,
}

export type encodeResult = { buf: buffer, instances: { Instance } }

export type channel = "reliable" | "unreliable"

export type direction = "c2s" | "s2c" | "s2s" | "c2c" | "broadcast"

export type packetDef = {
	id: number,
	name: string,
	channel: channel,
	direction: direction,
}

export type handler = (...any) -> ()

return types
