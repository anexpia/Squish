--!native
--!optimize 2

-- !!!!!!
-- MAKE SURE TO HAVE THIS SETTING DISABLED WHEN NOT NEEDED BECAUSE IT KILLS PERFORMANCE.

-- This setting makes it so every ser() function validates the arguments provided.
-- This is to make it easier to identify exactly where errors are happening when serializing.
-- Currently does not affect des() functions.

local VALIDATION_ENABLED = false
-- !!!!!!

local has4wideVectors = pcall(function() return vector.create(0,0,0).w end)
local kcachemtbl = {__mode = "k"}
local kvcachemtbl = {__mode = "kv"}
local vcachemtbl = {__mode = "v"}

export type Cursor = { 
	[number]: buffer,

	pos: number,
	size: number,

	refs: {any}?,
	reflookup: {[any]: number}?,
	reflastindex: number?,
	
	serdeduplookup: {[any]: number}?,
	desdeduplookup: {[number]: {value: any, s: number}}?,

	name: string?,
	validationscopes: {string}?,
}

export type SerDes<T> = {

	read type: string?,
	read name: string?,
	
	read structure: any,

	read multypeinfo: {
		read toindex: {[string]: number}?,
		read toserdes: {[number]: any}?,

		read literals: {any}?,
		read literalsMap: {[any]: number}?,

		read hassubtypes: boolean?,
		read numberfastpath: boolean?,
	}?, 

	read __T: T?,

	read ser: typeof(
		-- Serializes the provided value(s) into the buffer, as defined by the schema.
		function(cursor: Cursor, ...: T): () end
	),

	read des: typeof(
		-- Deserializes and returns the value(s) from the buffer, as defined by the schema.
		function(cursor: Cursor, ...: any): T end
	),
}

type TupleSerDes<T...> = {
	read type: string?,
	read name: string?,
	
	read structure: any,
	
	read ser: typeof(
		-- Serializes the provided value(s) into the buffer, as defined by the schema.
		function(cursor: Cursor, ...: T...): () end
	),

	read des: typeof(
		-- Deserializes and returns the value(s) from the buffer, as defined by the schema.
		function(cursor: Cursor, ...: any): T... end
	),
}

-- regex: --\[roblox\]<<[\s\S]*?-->>\n?
--[roblox]<<

export type SquishRaycastResult = {
	Distance: number,
	Position: Vector3,
	Normal: Vector3,
	Material: Enum.Material,
	Instance: BasePart?,
}

type RaycastResultSerDes = {
	read type: "RaycastResult",
	read name: "RaycastResult",

	read __T: RaycastResult,

	read ser: typeof(
		-- Serializes the provided RaycastResult into the buffer, as defined by the schema.
		function(cursor: Cursor, result: RaycastResult): () end
	),

	read des: typeof(
		-- Deserializes and returns the RaycastResult from the buffer, in table form.
		function(cursor: Cursor): SquishRaycastResult return nil :: any end
	),
}

-->>

type Length = number

type AnyTable = {[any]: any}
type NeverTable = {never}

type function optional(t: type, default: type)
	if (not t) or t.tag == "nil" or t.tag == "unknown" or t.tag == "any" then return default end
	return t
end

export type function UnwrapSerdes(t: type): type
	if t:is("table") then
		local desFunc = t:readproperty(types.singleton("des"))

		if desFunc and desFunc:is("function") then
			local rets = desFunc:returns()
			return (rets.head and rets.head[1]) or types.unknown
		end
	end

	print(`Expected a SerDes, but got {t.tag}.`)
	return types.never
end

type function safeUnwrapSerdes(t: type): (boolean, type)
	if t:is("table") then
		local desFunc = t:readproperty(types.singleton("des"))

		if desFunc and desFunc:is("function") then
			local rets = desFunc:returns()
			return true, (rets.head and rets.head[1]) or types.unknown
		end
	end

	return false, t
end

local function subtypeof(v: any, t: string?)
	if t == nil then t = typeof(v) end 

	if t == "EnumItem" then
		t = `EnumItem:{tostring(v.EnumType)}`
	end
	--elseif t == "Instance" then
	--	t = `Instance:{v.ClassName}`
	--end

	return t
end

local function getParameterAndContext(parameter: string | number, context: string?)
	if not context then context = `Squish.{debug.info(3, "n")}()` end 
	if type(parameter) == "number" then parameter = `parameter {parameter}` end 

	return parameter, context
end

-- Asserts that the value 'v' is a number or nil and does a formatted error message if otherwise.
local function assertIsLength(v: any, parameter: string | number, context: string?)
	if v == nil then return end 
	if type(v) == "number" then return end 

	parameter, context = getParameterAndContext(parameter, context)
	error(`Expected {parameter} to be a number in {context}, but got {typeof(v)}.`, 0)

	-- local istable = type(v) == 'table'
	-- local isserdes = istable and type(rawget(v, "ser")) == "function" and type(rawget(v, "des")) == "function"
	-- local isnumberserdes = isserdes and ((not v.type) or v.type == "number")

	-- if isnumberserdes then
	-- 	return
	-- end 

	-- parameter, context = getParameterAndContext(parameter, context)

	-- if istable then
	-- 	if isserdes then
	-- 		error(`Expected {parameter} to be a number or length SerDes in {context}, but got a SerDes of type {v.type}.`, 0)
	-- 	else 
	-- 		error(`Expected {parameter} to be a number or length SerDes in {context}, but got a table without either or both 'ser' and 'des' fields.`, 0)
	-- 	end
	-- else 
	-- 	error(`Expected {parameter} to be a number or length SerDes in {context}, but got {typeof(v)}.`, 0)
	-- end
end


-- Asserts that the SerDes 'v' is of type 't' (or nil) and does a formatted error message if otherwise.
local function assertSerdesType(serdes: SerDes<any>, t: string, parameter: string | number, context: string?)
	local serdestype = serdes.type
	if serdestype == nil or serdestype == t then return end 

	parameter, context = getParameterAndContext(parameter, context)

	error(`Expected {parameter} to be a SerDes of type {t} in {context}, but got {serdestype}.`, 0)
end

-- Asserts that the value 'v' is a SerDes and does a formatted error message if otherwise.
local function assertIsSerdes(v: any, parameter: string | number, context: string?)
	if v == nil then return end 
	local istable = type(v) == 'table'

	if istable and type(rawget(v, "ser")) == "function" and type(rawget(v, "des")) == "function" then
		return
	end 

	parameter, context = getParameterAndContext(parameter, context)

	if istable then
		error(`Expected {parameter} to be a SerDes in {context}, but got a table without either or both 'ser' and 'des' fields.`, 0)
	else 
		error(`Expected {parameter} to be a SerDes in {context}, but got {typeof(v)}.`, 0)
	end
end

-- Asserts that the value 'v' is of type 't' and does a formatted error message if otherwise.
local function assertSchemaType(v: any, t: string, parameter: string | number, context: string?)
	if typeof(v) == t then return end 

	parameter, context = getParameterAndContext(parameter, context)

	error(`Expected {parameter} to be {t} in {context}, but got {typeof(v)}.`, 0)
end

local function reverseArray<T>(t: {T}): {T}
	local len = #t
	local result = table.create(len) 

	for i, v in t do 
		result[len - (i - 1)] = v
	end

	return result
end

-- Returns the buffer used in the cursor.
local function getbuf(cursor: Cursor): buffer
	return cursor[1]
end

-- Overrides the buffer used in the cursor.
local function setbuf(cursor: Cursor, to: buffer): ()
	cursor[1] = to
end

-- Returns current position of the cursor.
local function getpos(cursor: Cursor): number
	return cursor.pos
end

-- Sets current position of the cursor.
local function setpos(cursor: Cursor, to: number): ()
	cursor.pos = to
end

-- Increments the cursor by 'n' and returns the position <strong>before</strong> incrementing.
local function incrementpos(cursor: Cursor, n: number)
	local pos = cursor.pos
	cursor.pos = pos + n
	return pos
end

-- Decrements the cursor by 'n' and returns the position <strong>after</strong> decrementing.
local function decrementpos(cursor: Cursor, n: number)
	local pos = cursor.pos - n
	cursor.pos = pos
	return pos
end

-- Creates a new cursor for use in schemas.
local function newcursor(size: number?, pos: number?): Cursor
	local buf = buffer.create((size or 8))

	return { buf, pos = pos or 0, size = size or 8}
end

-- Creates a new cursor using the provided buffer. 
-- The buffer is <strong>not cloned</strong>.
local function frombuffer(buf: buffer, pos: number?, references: { any }?): Cursor
	local len = buffer.len(buf)
	return { buf, pos = pos or len, size = len, refs = references, }
end

-- Returns a copy of the cursor's buffer.
local function tobuffer(cursor: Cursor): buffer
	local pos = getpos(cursor)
	local newbuf = buffer.create(pos)
	buffer.copy(newbuf, 0, getbuf(cursor), 0, pos)
	return newbuf
end

-- Opens a validation scope when VALIDATION_ENABLED is true for purpose of type checking and error finding.
local function beginValidationScope(cursor: Cursor, name: string)
	if not VALIDATION_ENABLED then return end 
	
	local scopes = cursor.validationscopes :: {string}
	if scopes == nil then 
		scopes = {}
		cursor.validationscopes = scopes
	end

	table.insert(scopes, name)
end

-- Overrides the name of the current validation scope.
local function overrideValidationScopeName(cursor: Cursor, name: string)
	if not VALIDATION_ENABLED then return end 
	
	local scopes = cursor.validationscopes :: {string}
	if scopes == nil then 
		scopes = {}
		cursor.validationscopes = scopes
	end

	scopes[math.max(#scopes, 1)] = name
end

-- Pops the current validation scope.
local function exitValidationScope(cursor: Cursor)
	if not VALIDATION_ENABLED then return end 
	
	local scopes = cursor.validationscopes :: {string}
	if scopes == nil then 
		scopes = {}
		cursor.validationscopes = scopes
	end

	table.remove(scopes)
end

-- Does a formatted error, using validation scopes if enabled and cursor name if provided.
local function reportValidationError(cursor: Cursor, err: string)
	if VALIDATION_ENABLED then
		local scopes = cursor.validationscopes :: {string}
		if scopes == nil then 
			scopes = {}
			cursor.validationscopes = scopes
		end

		local scopes = table.clone(scopes)
		for i, scope in scopes do 
			scopes[i] = `"{scope}"`
		end

		local pathtoscope = table.concat(scopes, " -> ")
		error(`SCHEMA ERROR:{if cursor.name then " [" .. cursor.name .. "]" else ""} {pathtoscope}: {err}`, 0)
	else 
		error(`SCHEMA ERROR:{if cursor.name then " [" .. cursor.name .. "]:" else ""} {err}`, 0)
	end
end

-- Asserts that the value 'v' is of type 't' and does a formatted error message if otherwise.
local function assertSerializeType(cursor: Cursor, value: any, type: string)
	if typeof(value) ~= type then
		reportValidationError(cursor, `Expected value ({value}) to be of type {type}, but got {typeof(value)}.`)
	end
end

-- Attempts to allocate 'n' bytes to the cursor's buffer if the buffer's length is less than (pos + n).
local function tryrealloc(cursor: Cursor, n: number)
	local pos = getpos(cursor)
	local targetlen = pos + n

	if cursor.size < targetlen then
		local oldbuf = getbuf(cursor)
		local len = targetlen // (1 / 1.5)
		
		cursor.size = len

		local newbuf = buffer.create(len)
		buffer.copy(newbuf, 0, oldbuf, 0, pos)
		setbuf(cursor, newbuf)
	end
end

local function pushu1(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 1)
	buffer.writeu8(buf, pos, x)
end

local function popu1(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 1)
	return buffer.readu8(buf, pos)
end

local function pushu2(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 2)
	buffer.writeu16(buf, pos, x)
end

local function popu2(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 2)
	return buffer.readu16(buf, pos)
end

local function pushu3(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 3)
	buffer.writeu8(buf, pos, x)
	buffer.writeu16(buf, pos + 1, x // 256)
end

local function popu3(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 3)
	local x1 = buffer.readu8(buf, pos)
	local x2 = buffer.readu16(buf, pos + 1)
	return x1 + x2 * 256
end

local function pushu4(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 4)
	buffer.writeu32(buf, pos, x)
end

local function popu4(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 4)
	return buffer.readu32(buf, pos)
end

local function pushu5(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 5)
	buffer.writeu8(buf, pos, x)
	buffer.writeu32(buf, pos + 1, x // 256)
end

local function popu5(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 5)
	local x1 = buffer.readu8(buf, pos)
	local x2 = buffer.readu32(buf, pos + 1)
	return x1 + x2 * 256
end

local function pushu6(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 6)
	buffer.writeu16(buf, pos, x)
	buffer.writeu32(buf, pos + 2, x // (256 ^ 2))
end

local function popu6(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 6)
	local x1 = buffer.readu16(buf, pos)
	local x2 = buffer.readu32(buf, pos + 2)
	return x1 + x2 * (256 ^ 2)
end

local function pushu7(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 7)
	buffer.writeu8(buf, pos, x)
	buffer.writeu16(buf, pos + 1, x // 256)
	buffer.writeu32(buf, pos + 3, x // (256 ^ 3))
end

local function popu7(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 7)
	local x1 = buffer.readu8(buf, pos)
	local x2 = buffer.readu16(buf, pos + 1)
	local x3 = buffer.readu32(buf, pos + 3)
	return x1 + x2 * 256 + x3 * (256 ^ 3)
end

local function pushu8(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 8)
	buffer.writeu32(buf, pos, x)
	buffer.writeu32(buf, pos + 4, x // (256 ^ 4))
end

local function popu8(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 8)
	local x1 = buffer.readu32(buf, pos)
	local x2 = buffer.readu32(buf, pos + 4)
	return x1 + x2 * (256 ^ 4)
end

local function pushi1(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 1)
	buffer.writei8(buf, pos, x)
end

local function popi1(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 1)
	return buffer.readi8(buf, pos)
end

local function pushi2(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 2)
	buffer.writei16(buf, pos, x)
end

local function popi2(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 2)
	return buffer.readi16(buf, pos)
end

local function pushi3(cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 3)
	buffer.writeu8(buf, pos, x % 256)
	buffer.writeu16(buf, pos + 1, x // 256)
end

local function popi3(cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 3)
	local x1 = buffer.readu8(buf, pos)
	local x2 = buffer.readu16(buf, pos + 1)
	local x = x1 + x2 * 256
	return if x >= 2 ^ 23 then x - (2 ^ 24) else x
end

local function pushi4(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 4)
	buffer.writei32(buf, pos, x)
end

local function popi4(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 4)
	return buffer.readi32(buf, pos)
end

local function pushi5(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 5)
	buffer.writeu8(buf, pos, x)
	buffer.writeu32(buf, pos + 1, x // 256)
end

local function popi5(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 5)
	local x1 = buffer.readu8(buf, pos)
	local x2 = buffer.readu32(buf, pos + 1)
	local x = x1 + x2 * 256
	return if x >= 2 ^ 39 then x - (2 ^ 40) else x
end

local function pushi6(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 6)
	buffer.writeu16(buf, pos, x)
	buffer.writeu32(buf, pos + 2, x // (256 ^ 2))
end

local function popi6(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 6)
	local x1 = buffer.readu16(buf, pos)
	local x2 = buffer.readu32(buf, pos + 2)
	local x = x1 + x2 * (256 ^ 2)
	return if x >= 2 ^ 47 then x - (2 ^ 48) else x
end

local function pushi7(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 7)
	buffer.writeu8(buf, pos, x)
	buffer.writeu16(buf, pos + 1, x // 256)
	buffer.writeu32(buf, pos + 3, x // (256 ^ 3))
end

local function popi7(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 7)
	local x1 = buffer.readu8(buf, pos)
	local x2 = buffer.readu16(buf, pos + 1) * 256 + x1
	local x3 = buffer.readu32(buf, pos + 3) * (256 ^ 3)
	local x = x2 + x3
	return if x >= 2 ^ 55 then x3 - (2 ^ 56) + x2 else x -- subtract before adding x2 to avoid some precision loss in negative numbers
end

local function pushi8(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 8)
	buffer.writeu32(buf, pos, x)
	buffer.writeu32(buf, pos + 4, x // (256 ^ 4))
end

local function popi8(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 8)
	local x1 = buffer.readu32(buf, pos)
	local x2 = buffer.readu32(buf, pos + 4) * (256 ^ 4)
	local x = x1 + x2
	return if x >= 2 ^ 63 then x2 - (2 ^ 64) + x1 else x -- subtract before adding x1 to avoid some precision loss in negative numbers
end

local function popf2(cursor: Cursor): number
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 2)

	local n = buffer.readu16(buf, pos)

	local mantissa: number, exponent: number, sign: number = bit32.extract(n, 0, 10), 
															 bit32.extract(n, 10, 5), 
															 bit32.extract(n, 15, 1)

	if mantissa == 0b0000000000 then
		if exponent == 0b00000 then return 0
		elseif exponent == 0b11111 then 
			return if sign == 1 then -math.huge else math.huge 
		end
	elseif exponent == 0b11111 then return 0/0 end 

	local value: number = ((mantissa / 1024) + 1) * 2 ^ (exponent - 15)

	if sign == 1 then return -value end 
	return value
end

local function pushf2(cursor: Cursor, x: number): ()
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 2)

	if x == 0 then buffer.writeu16(buf, pos, 0)
	elseif x >= 65520 then buffer.writeu16(buf, pos, 0b0_11111_0000000000)
	elseif x <= -65520 then buffer.writeu16(buf, pos, 0b1_11111_0000000000)
	elseif math.isnan(x) then buffer.writeu16(buf, pos, 0b0_11111_0000000001)
	else
		local sign: number = 0

		if x < 0 then 
			sign = 1 
			x = -x 
		end

		local mantissa: number, exponent: number = math.frexp(x)
		if exponent < -14 then -- safeguard against tiny exponents like -20
			buffer.writeu16(buf, pos, 0)
			return 
		end

		buffer.writeu16(buf, pos, bit32.bor((mantissa * 2048 - 1023.5), (exponent + 14) * 2^10, (sign) * 2^15))
	end
end

local function pushf4(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 4)
	buffer.writef32(buf, pos, x)
end

local function popf4(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 4)
	return buffer.readf32(buf, pos)
end

local function pushf8(cursor: Cursor, x: number)
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, 8)
	buffer.writef64(buf, pos, x)
end

local function popf8(cursor: Cursor)
	local buf = getbuf(cursor)
	local pos = decrementpos(cursor, 8)
	return buffer.readf64(buf, pos)
end

local function pushbool(cursor: Cursor, bool: boolean)
	pushu1(cursor, if bool then 1 else 0)
end

local function popbool(cursor: Cursor): (boolean)
	return bit32.btest(popu1(cursor), 1)
end

local function pushboolpacknocursor(
	buf: buffer,
	pos: number,
	a: boolean?,
	b: boolean?,
	c: boolean?,
	d: boolean?,
	e: boolean?,
	f: boolean?,
	g: boolean?,
	h: boolean?
)
	local y = if a then 1 else 0
	if b then y += 2 end
	if c then y += 4 end
	if d then y += 8 end
	if e then y += 16 end
	if f then y += 32 end
	if g then y += 64 end
	if h then y += 128 end
	
	buffer.writeu8(buf, pos, y)
end

local function pushboolpack(
	cursor: Cursor,
	a: boolean?,
	b: boolean?,
	c: boolean?,
	d: boolean?,
	e: boolean?,
	f: boolean?,
	g: boolean?,
	h: boolean?
)
	local y = if a then 1 else 0
	if b then y += 2 end
	if c then y += 4 end
	if d then y += 8 end
	if e then y += 16 end
	if f then y += 32 end
	if g then y += 64 end
	if h then y += 128 end
	
	pushu1(cursor, y)
end

local function popboolpack(cursor: Cursor): (boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean)
	local x = popu1(cursor)
	return bit32.btest(x, 2^0), bit32.btest(x, 2^1), bit32.btest(x, 2^2), bit32.btest(x, 2^3), 
			bit32.btest(x, 2^4), bit32.btest(x, 2^5), bit32.btest(x, 2^6), bit32.btest(x, 2^7)
end

local pushvlqrealloc, popvlq
do
	local BASE = 2 ^ 7
	function pushvlqrealloc(cursor: Cursor, x: number)
		local count = 0
		if x >= 2^49 then
			count = 8
		else
			local t_x: number = x

			if t_x >= 2^28 then
				count = 4
				t_x //= 2^28
			end

			local bits = 32 - bit32.countlz(bit32.bor(t_x, 1))
			count += (bits + 6) // 7
		end
		
		tryrealloc(cursor, count)
		
		local buf, pos = getbuf(cursor), incrementpos(cursor, count)
		buffer.writeu8(buf, pos, x % BASE)

		for i = 1, count - 1 do
			x //= BASE
			buffer.writeu8(buf, pos + i, (x % BASE) + BASE)
		end
	end

	function popvlq(cursor: Cursor)
		local buf, pos = getbuf(cursor), getpos(cursor)

		pos -= 1
		local b1: number = buffer.readu8(buf, pos)
		local v1 = b1 % BASE
		if b1 < BASE then
			setpos(cursor, pos)
			return v1
		end

		pos -= 1
		local b2: number = buffer.readu8(buf, pos)
		local v2 = v1 * BASE + (b2 % BASE)
		if b2 < BASE then
			setpos(cursor, pos)
			return v2
		end

		pos -= 1
		local b3: number = buffer.readu8(buf, pos)
		local v3 = v2 * BASE + (b3 % BASE)
		if b3 < BASE then
			setpos(cursor, pos)
			return v3
		end

		pos -= 1
		local b4: number = buffer.readu8(buf, pos)
		local v4 = v3 * BASE + (b4 % BASE)
		if b4 < BASE then
			setpos(cursor, pos)
			return v4
		end

		pos -= 1
		local b5: number = buffer.readu8(buf, pos)
		local v5 = v4 * BASE + (b5 % BASE)
		if b5 < BASE then
			setpos(cursor, pos)
			return v5
		end

		pos -= 1
		local b6: number = buffer.readu8(buf, pos)
		local v6 = v5 * BASE + (b6 % BASE)
		if b6 < BASE then
			setpos(cursor, pos)
			return v6
		end

		pos -= 1
		local b7: number = buffer.readu8(buf, pos)
		local v7 = v6 * BASE + (b7 % BASE)
		if b7 < BASE then
			setpos(cursor, pos)
			return v7
		end

		pos -= 1
		local b8: number = buffer.readu8(buf, pos)
		local v8 = v7 * BASE + (b8 % BASE)

		setpos(cursor, pos)
		return v8
	end
end

local function pushstr(cursor: Cursor, x: string, length: number?)
	local len = length or #x
	local buf = getbuf(cursor)
	local pos = incrementpos(cursor, len)
	buffer.writestring(buf, pos, x)

	if not length then
		pushvlqrealloc(cursor, len)
	end
end

local function popstr(cursor: Cursor, length: number?)
	local len = length or popvlq(cursor)
	local buf = getbuf(cursor)
	local pos = getpos(cursor) - len
	setpos(cursor, pos)
	return buffer.readstring(buf, pos, len)
end

local function pushbuf(cursor: Cursor, x: buffer, length: number?)
	local len = length or buffer.len(x)
	tryrealloc(cursor, len)

	local buf = getbuf(cursor)
	local pos = getpos(cursor)
	buffer.copy(buf, pos, x, 0, len)
	setpos(cursor, pos + len)

	if not length then
		pushvlqrealloc(cursor, len)
	end
end

local function popbuf(cursor: Cursor, length: number?)
	local len = length or popvlq(cursor)
	local buf = getbuf(cursor)
	local pos = getpos(cursor) - len
	setpos(cursor, pos)

	local new = buffer.create(len)
	buffer.copy(new, 0, buf, pos, len)
	return new
end

-- Assigns a unique id to the referenced value, which refers to its index in the references table.
local function pushref(cursor: Cursor, v: any)
	local reflookup = cursor.reflookup

	if reflookup == nil then 
		reflookup = {}

		if cursor.refs then
			for i, v in cursor.refs do 
				reflookup[v] = i 
			end

			cursor.reflookup = reflookup
			cursor.reflastindex = #cursor.refs
		else 
			cursor.refs = {}
			cursor.reflookup = reflookup
			cursor.reflastindex = 1 -- start from 1 to avoid remoteevents stringify'ing the array.
		end
	end 

	local pos = reflookup[v]
	if not pos then
		pos = cursor.reflastindex
		cursor.reflastindex += 1

		cursor.refs[pos] = v 
		reflookup[v] = pos 	
	end

	pushvlqrealloc(cursor, pos)
end

-- Pops value from references table using vlq.
local function popref(cursor: Cursor)
	local idx = popvlq(cursor)
	local refs = cursor.refs 

	if refs then return refs[idx] end
	return nil
end

-- Prints the bytes of the buffer and the position of the cursor. 
-- If validation is enabled, will print current scope.
local function printcursor(cursor: Cursor): ()
	local buf = getbuf(cursor)
	local pos = getpos(cursor)

	local bytes = { string.byte(buffer.tostring(buf), 1, -1) }
	local offset = 7
	for i = 1, pos do
		local byte = bytes[i]
		local digits = if byte == 0 then 1 else math.ceil(math.log10(1 + byte))
		offset += digits + 1
	end

	local lastByte = bytes[pos + 1]
	if lastByte then
		local lastDigits = if lastByte == 0 then 1 else math.ceil(math.log10(1 + lastByte))
		offset += lastDigits // 2
	end

	if #bytes == 0 or pos == buffer.len(buf) then
		table.insert(bytes, ' ' :: any)
	end

	print(`Pos: {pos} / {buffer.len(buf)}\nBuf: \{ {table.concat(bytes, ' ')} \}\n{string.rep(' ', offset)}^`)
	if VALIDATION_ENABLED and cursor.validationscopes and #cursor.validationscopes > 0 then
		print("Current scope depth:", table.concat(cursor.validationscopes, "->"))
	end
end

local function serbitarr(cursor: Cursor, bits: { boolean }, length: number?)
	local bitCount = length or #bits
	if bitCount == 0 then
		return
	end

	local bitsOver = bitCount % 8

	local buf, pos = getbuf(cursor), incrementpos(cursor, (bitCount + 7) // 8)

	local bytesInBits = bitCount - bitsOver
	for i = 0, bytesInBits - 1, 8 do
		pushboolpacknocursor(buf, pos, bits[i + 1], bits[i + 2], bits[i + 3], bits[i + 4], bits[i + 5], bits[i + 6], bits[i + 7], bits[i + 8])
		pos += 1
	end

	if bitsOver > 0 then
		local byte = 0
		for i = 0, 7 do 
			if i >= bitsOver then break end 
			if bits[bytesInBits + i + 1] then
				byte += bit32.lshift(1, i)
			end
		end

		buffer.writeu8(buf, pos, byte)
	end
end

local function desbitarr(cursor: Cursor, bitCount: number): { boolean }
	if bitCount == 0 then
		return {}
	end

	local arr = table.create(bitCount, false)
	local bytes = bitCount // 8
	local buf, pos = getbuf(cursor), decrementpos(cursor, (bitCount + 7) // 8)

	for i = 0, bytes - 1 do 
		local j = i * 8

		local x = buffer.readu8(buf, pos + i)
		arr[j + 1], arr[j + 2], arr[j + 3], arr[j + 4], arr[j + 5], arr[j + 6], arr[j + 7], arr[j + 8] = 
			bit32.btest(x, 2^0), bit32.btest(x, 2^1), bit32.btest(x, 2^2), bit32.btest(x, 2^3), 
			bit32.btest(x, 2^4), bit32.btest(x, 2^5), bit32.btest(x, 2^6), bit32.btest(x, 2^7)
	end

	local bitsOver = bitCount % 8

	if bitsOver > 0 then
		local j = bytes * 8
		local x = buffer.readu8(buf, pos + bytes)

		for i = 0, 7 do 
			if i >= bitsOver then break end 
			if bit32.btest(x, 2^i) then arr[j + i + 1] = true end
		end
	end

	return arr
end

local Squish = {}

Squish.print = printcursor
Squish.cursor = newcursor

Squish.frombuffer = frombuffer
Squish.tobuffer = tobuffer

Squish.util = {
	tryrealloc = tryrealloc,
	setpos = setpos,
	getpos = getpos,
	setbuf = setbuf,
	getbuf = getbuf,

	serbitarr = serbitarr,
	desbitarr = desbitarr,

	pushu1 = pushu1, popu1 = popu1,
	pushu2 = pushu2, popu2 = popu2,
	pushu3 = pushu3, popu3 = popu3,
	pushu4 = pushu4, popu4 = popu4,
	pushu5 = pushu5, popu5 = popu5,
	pushu6 = pushu6, popu6 = popu6,
	pushu7 = pushu7, popu7 = popu7,
	pushu8 = pushu8, popu8 = popu8,

	pushi1 = pushi1, popi1 = popi1,
	pushi2 = pushi2, popi2 = popi2,
	pushi3 = pushi3, popi3 = popi3,
	pushi4 = pushi4, popi4 = popi4,
	pushi5 = pushi5, popi5 = popi5,
	pushi6 = pushi6, popi6 = popi6,
	pushi7 = pushi7, popi7 = popi7,
	pushi8 = pushi8, popi8 = popi8,

	pushf2 = pushf2, popf2 = popf2,
	pushf4 = pushf4, popf4 = popf4,
	pushf8 = pushf8, popf8 = popf8,

	pushbool = pushbool, popbool = popbool,
	pushboolpack = pushboolpack, popboolpack = popboolpack,
	pushvlqrealloc = pushvlqrealloc, popvlq = popvlq,
	pushstr = pushstr, popstr = popstr,
	pushbuf = pushbuf, popbuf = popbuf,

	pushref = pushref, popref = popref,
}

Squish.validation = {
	assertSchemaType = assertSchemaType,
	assertIsSerdes = assertIsSerdes,
	assertSerdesType = assertSerdesType,

	assertSerializeType = assertSerializeType,

	scopesEnabled = VALIDATION_ENABLED,
	beginValidationScope = beginValidationScope,
	exitValidationScope = exitValidationScope,
	overrideValidationScopeName = overrideValidationScopeName,
}


function Squish.T<T>(x: SerDes<T>): T
	return x :: any
end

local booleanCache
do
	booleanCache = {
		type = "boolean",
		name = "boolean",
		ser = function(cursor: Cursor, bool: boolean)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "boolean") assertSerializeType(cursor, bool, "boolean") end

			tryrealloc(cursor, 1)
			pushbool(cursor, bool)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popbool,
	}

	-- Returns SerDes for boolean values.
	function Squish.boolean(): SerDes<boolean>
		return booleanCache
	end
end

local booleanpackCache
do
	booleanpackCache = {
		type = "boolean",
		name = "boolpack",
		ser = function(cursor: Cursor, a: boolean?, b: boolean?, c: boolean?, d: boolean?, e: boolean?, f: boolean?, g: boolean?, h: boolean?)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "pack") end

			tryrealloc(cursor, 1)
			pushboolpack(cursor, a, b, c, d, e, f, g, h)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popboolpack,
	}

	-- Returns SerDes for up to 8 boolean values at a time.
	function Squish.boolpack(): TupleSerDes<boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean>
		return booleanpackCache
	end
end

do
	local u8 = {
		type = "number",
		name = "u8",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "u8") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 1)
			pushu1(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popu1,
	}

	-- Returns SerDes for unsigned 8-bit integers. (1 bytes)
	function Squish.u8(): SerDes<number>
		return u8
	end

	local u16 = {
		type = "number",
		name = "u16",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "u16") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 2)
			pushu2(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popu2,
	}

	-- Returns SerDes for unsigned 16-bit integers. (2 bytes)
	function Squish.u16(): SerDes<number>
		return u16
	end

	local u24 = {
		type = "number",
		name = "u24",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "u24") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 3)
			pushu3(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popu3,
	}

	-- Returns SerDes for unsigned 24-bit integers. (3 bytes)
	function Squish.u24(): SerDes<number>
		return u24
	end

	local u32 = {
		type = "number",
		name = "u32",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "u32") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 4)
			pushu4(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popu4,
	}

	-- Returns SerDes for unsigned 32-bit integers. (4 bytes)
	function Squish.u32(): SerDes<number>
		return u32
	end

	local u40 = {
		type = "number",
		name = "u40",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "u40") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 5)
			pushu5(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popu5,
	}

	-- Returns SerDes for unsigned 40-bit integers. (5 bytes)
	function Squish.u40(): SerDes<number>
		return u40
	end

	local u48 = {
		type = "number",
		name = "u48",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "u48") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 6)
			pushu6(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popu6,
	}

	-- Returns SerDes for unsigned 48-bit integers. (6 bytes)
	function Squish.u48(): SerDes<number>
		return u48
	end

	local u56 = {
		type = "number",
		name = "u56",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "u56") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 7)
			pushu7(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popu7,
	}

	-- Returns SerDes for unsigned 56-bit integers. Not recommended to use. (7 bytes)
	function Squish.u56(): SerDes<number>
		return u56
	end

	local u64 = {
		type = "number",
		name = "u64",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "u64") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 8)
			pushu8(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popu8,
	}

	-- Returns SerDes for unsigned 64-bit integers. Not recommended to use. (8 bytes)
	function Squish.u64(): SerDes<number>
		return u64
	end
end

do
	local i8 = {
		type = "number",
		name = "i8",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "i8") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 1)
			pushi1(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popi1,
	}
	-- Returns SerDes for signed 8-bit integers. (1 bytes)
	function Squish.i8(): SerDes<number>
		return i8
	end

	local i16 = {
		type = "number",
		name = "i16",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "i16") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 2)
			pushi2(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popi2,
	}
	-- Returns SerDes for signed 16-bit integers. (2 bytes)
	function Squish.i16(): SerDes<number>
		return i16
	end

	local i24 = {
		type = "number",
		name = "i24",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "i24") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 3)
			pushi3(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popi3,
	}
	-- Returns SerDes for signed 24-bit integers. (3 bytes)
	function Squish.i24(): SerDes<number>
		return i24
	end

	local i32 = {
		type = "number",
		name = "i32",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "i32") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 4)
			pushi4(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popi4,
	}
	-- Returns SerDes for signed 32-bit integers. (4 bytes)
	function Squish.i32(): SerDes<number>
		return i32
	end

	local i40 = {
		type = "number",
		name = "i40",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "i40") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 5)
			pushi5(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popi5,
	}
	-- Returns SerDes for signed 40-bit integers. (5 bytes)
	function Squish.i40(): SerDes<number>
		return i40
	end

	local i48 = {
		type = "number",
		name = "i48",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "i48") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 6)
			pushi6(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popi6,
	}
	-- Returns SerDes for signed 48-bit integers. (6 bytes)
	function Squish.i48(): SerDes<number>
		return i48
	end

	local i56 = {
		type = "number",
		name = "i56",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "i56") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 7)
			pushi7(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popi7,
	}
	-- Returns SerDes for signed 56-bit integers. Not recommended to use. (7 bytes)
	function Squish.i56(): SerDes<number>
		return i56
	end

	local i64 = {
		type = "number",
		name = "i64",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "i64") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 8)
			pushi8(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popi8,
	}
	-- Returns SerDes for signed 64-bit integers. Not recommended to use. (8 bytes)
	function Squish.i64(): SerDes<number>
		return i64
	end
end

do
	local f16 = {
		type = "number",
		name = "f16",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "f16") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 2)
			pushf2(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popf2,
	}
	-- Returns SerDes for 16-bit float numbers. (2 bytes)
	function Squish.f16(): SerDes<number>
		return f16
	end

	local f32 = {
		type = "number",
		name = "f32",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "f32") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 4)
			pushf4(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popf4,
	}
	-- Returns SerDes for 32-bit float numbers. (4 bytes)
	function Squish.f32(): SerDes<number>
		return f32
	end

	local f64 = {
		type = "number",
		name = "f64",
		ser = function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "f64") assertSerializeType(cursor, x, "number") end

			tryrealloc(cursor, 8)
			pushf8(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popf8,
	}
	-- Returns SerDes for 64-bit float numbers. (8 bytes)
	function Squish.f64(): SerDes<number>
		return f64
	end
end

local function getNumberSizePushPop(serdes: SerDes<number>): (number?, index<SerDes<number>, "ser">, index<SerDes<number>, "des">)
	if not serdes then return end 

	if serdes == Squish.f64() then
		return 8, pushf8, popf8
	elseif serdes == Squish.f32() then
		return 4, pushf4, popf4

		-- unsigned ints
	elseif serdes == Squish.u8() then
		return 1, pushu1, popu1
	elseif serdes == Squish.u16() then
		return 2, pushu2, popu2
	elseif serdes == Squish.u24() then
		return 3, pushu3, popu3
	elseif serdes == Squish.u32() then
		return 4, pushu4, popu4
	elseif serdes == Squish.u40() then
		return 5, pushu5, popu5
	elseif serdes == Squish.u48() then
		return 6, pushu6, popu6
	elseif serdes == Squish.u56() then
		return 7, pushu7, popu7
	elseif serdes == Squish.u64() then
		return 8, pushu8, popu8

		-- signed ints
	elseif serdes == Squish.i8() then
		return 1, pushi1, popi1
	elseif serdes == Squish.i16() then
		return 2, pushi2, popi2
	elseif serdes == Squish.i24() then
		return 3, pushi3, popi3
	elseif serdes == Squish.i32() then
		return 4, pushi4, popi4
	elseif serdes == Squish.i40() then
		return 5, pushi5, popi5
	elseif serdes == Squish.i48() then
		return 6, pushi6, popi6
	elseif serdes == Squish.i56() then
		return 7, pushi7, popi7
	elseif serdes == Squish.i64() then
		return 8, pushi8, popi8
	else
		return nil, serdes.ser, serdes.des
	end
end

local function getUnsignedByteSize(n: number): number
	local c = 0

	if n > 2^32 then
		c = 4
		n //= 2^32
	end

	local bitcount = 32 - bit32.countlz(bit32.bor(n, 1))
	local bytes = bit32.rshift(bitcount + 7, 3)

	return c + bytes
end

local common_serInt, common_desInt

do
	local rangeCache = setmetatable({}, kcachemtbl)

	-- Encodes an number in the interval [min, max] using uints with as few bytes as possible
	-- If a serdes is provided, it is used instead of the minimal serdes needed being used. 
	-- Enabling 'restricted' clamps the provided numbers when serializing to the range.
	function Squish.range(min: number, max: number, serdes: SerDes<number>?, restricted: boolean?): SerDes<number>
		local hash = `{min}_{max}{if restricted then "t" else "f"}`

		assertSchemaType(min, "number", 1)
		assertSchemaType(max, "number", 2)

		local rangeCache = rangeCache
		if serdes then
			assertIsSerdes(serdes, 3)
			local subcache = rangeCache[serdes] 
			if subcache == nil then subcache = setmetatable({}, kvcachemtbl) rangeCache[serdes] = subcache end
			rangeCache = subcache
		end

		local cached = rangeCache[hash]

		if cached then
			return cached
		end

		local push, pop, bytes

		if serdes then
			assert(min < max, 'min must be less than max')

			bytes, push, pop = getNumberSizePushPop(serdes)
		else
			assert(min == min // 1 and max == max // 1 and min < max, 'min and max must be integers, and min < max')

			local difference = max - min
			if difference < 256 ^ 1 then
				push, pop, bytes = pushu1, popu1, 1
			elseif difference < 256 ^ 2 then
				push, pop, bytes = pushu2, popu2, 2
			elseif difference < 256 ^ 3 then
				push, pop, bytes = pushu3, popu3, 3
			elseif difference < 256 ^ 4 then
				push, pop, bytes = pushu4, popu4, 4
			elseif difference < 256 ^ 5 then
				push, pop, bytes = pushu5, popu5, 5
			elseif difference < 256 ^ 6 then
				push, pop, bytes = pushu6, popu6, 6
			elseif difference < 256 ^ 7 then
				push, pop, bytes = pushu7, popu7, 7
			else
				push, pop, bytes = pushu8, popu8, 8
			end
		end

		local range: SerDes<number> = {
			type = "number",
			name = "range",
			structure = {min, max, serdes, restricted},
			ser = function(cursor: Cursor, x: number)
				if VALIDATION_ENABLED then beginValidationScope(cursor, `range[{hash}]`) assertSerializeType(cursor, x, "number") end
				if restricted then x = math.clamp(x, min, max) end

				tryrealloc(cursor, bytes)
				push(cursor, x - min)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = if restricted then 
				function(cursor)
					local v = pop(cursor) + min
					return math.clamp(v, min, max)
				end
				else 
				function(cursor)
					return pop(cursor) + min
				end,
		}
		rangeCache[hash] = range

		return range
	end
end

do 
	local cache = setmetatable({}, kvcachemtbl)

	function common_serInt(cursor: Cursor, x: number): number
		local isnegative = x < 0
		if isnegative then x = -x end

		local size = getUnsignedByteSize(x)
		tryrealloc(cursor, size + 1)

		if size == 1 then
			pushu1(cursor, x)
		elseif size == 2 then
			pushu2(cursor, x)
		elseif size == 3 then
			pushu3(cursor, x)
		elseif size == 4 then
			pushu4(cursor, x)
		elseif size == 5 then
			pushu5(cursor, x)
		elseif size == 6 then
			pushu6(cursor, x)
		elseif size == 7 then
			pushu7(cursor, x)
		else 
			pushu8(cursor, x)
		end

		if isnegative then size += 16 end

		return size - 1
	end

	function common_desInt(cursor: Cursor, id: number, floatallowed: boolean)
		local value
		local isnegative = id >= 16

		if isnegative then id -= 16 end

		if id == 0 then
			value = popu1(cursor)
		elseif id == 1 then
			value = popu2(cursor)
		elseif id == 2 then
			value = popu3(cursor)
		elseif id == 3 then
			value = popu4(cursor)
		elseif id == 4 then
			value = popu5(cursor)
		elseif id == 5 then
			value = popu6(cursor)
		elseif id == 6 then
			value = popu7(cursor)
		elseif id == 15 and floatallowed then
			value = math.huge
		else
			value = popu8(cursor)
		end

		return if isnegative then -value else value
	end

	-- Returns SerDes for numbers, dynamically optimizing to the smallest possible representation.
	-- You can disable encoding as float by providing 'false' to the parameter.
	function Squish.number(floatAllowed: boolean?): SerDes<number>
		if floatAllowed == nil then floatAllowed = true end

		if cache[floatAllowed] then
			return cache[floatAllowed]
		end

		local serdes
		
		if floatAllowed then
			serdes = {		
				type = "number",
				ser = function(cursor: Cursor, x: number)
					if VALIDATION_ENABLED then beginValidationScope(cursor, "number") assertSerializeType(cursor, x, "number") end

					local isfinite = math.isfinite(x)
					if (not isfinite) then
						if math.isnan(x) then
							tryrealloc(cursor, 1)
							pushu1(cursor, 13)
						else
							tryrealloc(cursor, 1)
							pushu1(cursor, if x == math.huge then 11 else 12)
						end
					elseif (x % 1 ~= 0 or x >= 2^64 or x <= -2^64) then
						local m, e = math.frexp(x)
						
						if e >= -13 and e <= 16 and (m * 2^11) % 1 == 0 then
							tryrealloc(cursor, 3)
							pushf2(cursor, x)
							pushu1(cursor, 8)
						elseif e >= -125 and e <= 128 and (m * 2^24) % 1 == 0 then
							tryrealloc(cursor, 5)
							pushf4(cursor, x)
							pushu1(cursor, 9)
						else
							tryrealloc(cursor, 9)
							pushf8(cursor, x)
							pushu1(cursor, 10)
						end
					else 
						pushu1(cursor, common_serInt(cursor, x))
					end

					if VALIDATION_ENABLED then exitValidationScope(cursor) end
				end,

				des = function(cursor: Cursor): number
					local id = popu1(cursor)

					if id == 8 then return popf2(cursor)
					elseif id == 9 then return popf4(cursor)
					elseif id == 10 then return popf8(cursor)
					elseif id == 11 then return math.huge
					elseif id == 12 then return -math.huge 
					elseif id == 13 then return math.nan
					else return common_desInt(cursor, id, true)
					end
				end,
			}
		else
			serdes = {		
				type = "number",
				ser = function(cursor: Cursor, x: number)
					if VALIDATION_ENABLED then beginValidationScope(cursor, "number") assertSerializeType(cursor, x, "number") end

					pushu1(cursor, common_serInt(cursor, x))

					if VALIDATION_ENABLED then exitValidationScope(cursor) end
				end,

				des = function(cursor: Cursor): number
					return common_desInt(cursor, popu1(cursor), false)
				end,
			}
		end

		serdes.name, serdes.structure = "number", floatAllowed

		cache[floatAllowed] = serdes	
		return serdes
	end
end

do
	local byteto6bitlookup = {}
	local bit6tocharlookup = {}
	
	do 
		local v = 0
		
		for i = 48, 57 do 
			byteto6bitlookup[i] = v
			bit6tocharlookup[v] = string.char(i)
			v += 1
		end

		for i = 65, 90 do 
			byteto6bitlookup[i] = v
			bit6tocharlookup[v] = string.char(i)
			v += 1
		end

		for i = 97, 122 do 
			byteto6bitlookup[i] = v
			bit6tocharlookup[v] = string.char(i)
			v += 1
		end
	end

	local function byteTo6Bit(byte: number?): number
		return byteto6bitlookup[byte] or 62
	end

	local function bit6ToChar(byte: number?): string
		return bit6tocharlookup[byte] or ""
	end
	
	-- Packs the string into 6 bits per character, reducing length by average of 25%.
	-- Only supports uppercase & lowercase letters and numbers.
	local function packString6Bit(str: string): (buffer, number)
		local len = #str
		local buflen = math.ceil(len * 0.75)

		local b = buffer.create(buflen)
		local offset = 0

		for i = 1, len, 4 do
			local a1, a2, a3, a4 = string.byte(str, i, i + 3)

			local c1 = byteTo6Bit(a1)
			local c2 = byteTo6Bit(a2)

			local b1 = bit32.bor(bit32.lshift(c1, 2), bit32.rshift(c2, 4))

			buffer.writeu8(b, offset, b1)

			if a2 then
				local c3 = byteTo6Bit(a3)
				local b2 = bit32.bor(bit32.lshift(bit32.band(c2, 15), 4), bit32.rshift(c3, 2))

				buffer.writeu8(b, offset + 1, b2)

				if a3 then 
					local c4 = byteTo6Bit(a4)
					local b3 = bit32.bor(bit32.lshift(bit32.band(c3, 3), 6), c4)

					buffer.writeu8(b, offset + 2, b3)
				end

			end

			offset += 3
		end

		return b, buflen
	end
	
	-- Unpacks a 6-bit packed string into original form.
	local function unpackString6Bit(buf: buffer): string
		local result = ""
		local bufLen = buffer.len(buf)

		for offset = 0, bufLen - 1, 3 do
			local bytesLeft = bufLen - offset

			local b1 = buffer.readu8(buf, offset)
			local c1 = bit32.rshift(b1, 2)

			result ..= bit6ToChar(c1)

			if bytesLeft >= 2 then
				local b2 = buffer.readu8(buf, offset + 1)
				local c2 = bit32.bor(bit32.lshift(bit32.band(b1, 3), 4), bit32.rshift(b2, 4))
				result ..= bit6ToChar(c2)

				if bytesLeft >= 3 then
					local b3 = buffer.readu8(buf, offset + 2)
					local c3 = bit32.bor(bit32.lshift(bit32.band(b2, 15), 2), bit32.rshift(b3, 6))
					local c4 = bit32.band(b3, 63)

					result ..= bit6ToChar(c3)
					result ..= bit6ToChar(c4) 
				end
			end
		end

		return result
	end

	local stringSerDes: SerDes<string> = {
		type = "string",
		name = "string",
		ser = function(cursor: Cursor, x: string)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "string") assertSerializeType(cursor, x, "string") end

			local len = #x
			
			tryrealloc(cursor, len)
			buffer.writestring(getbuf(cursor), incrementpos(cursor, len), x)
			pushvlqrealloc(cursor, len)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popstr,
	}
	
	local stringCache = setmetatable({}, kvcachemtbl)
	local str = {}
	function str.convert(str: string, inAlphabet: string, outAlphabet: string): string
		local sourceDigits = {}
		for i = 1, #inAlphabet do
			sourceDigits[string.byte(inAlphabet, i)] = i - 1
		end

		local targetDigits = {}
		for i = 1, #outAlphabet do
			targetDigits[i - 1] = string.byte(outAlphabet, i)
		end

		local inputDigits = {}
		for i = 1, #str do
			table.insert(inputDigits, sourceDigits[string.byte(str, i)])
		end

		local output = {}
		local sourceBase = #inAlphabet
		local targetBase = #outAlphabet
		local carry, value
		while #inputDigits > 0 do
			carry = 0

			for i = 1, #inputDigits do
				value = inputDigits[i] + carry * sourceBase
				inputDigits[i] = value // targetBase
				carry = value % targetBase
			end

			while #inputDigits > 0 and inputDigits[1] == 0 do
				table.remove(inputDigits, 1)
			end

			table.insert(output, 1, string.char(targetDigits[carry]))
		end

		return table.concat(output)
	end
	function str.alphabet(source: string): string
		local lookup = {}
		local alphabet = table.create(#source)
		for i = 1, #source do
			local char = string.sub(source, i, i)
			if not lookup[char] then
				lookup[char] = true
				table.insert(alphabet, char)
			end
		end
		table.sort(alphabet)
		return table.concat(alphabet)
	end

	str.packintoalphanumeric = packString6Bit
	str.unpackalphanumeric = unpackString6Bit

	str.binary = '01'
	str.octal = '01234567'
	str.decimal = '0123456789'
	str.duodecimal = '0123456789AB'
	str.hexadecimal = '0123456789ABCDEF'
	local utf8Characters = table.create(256)
	for i = 0, 255 do
		utf8Characters[i + 1] = string.char(i)
	end
	str.utf8 = table.concat(utf8Characters)
	str.lower = 'abcdefghijklmnopqrstuvwxyz'
	str.upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	str.letters = str.lower .. str.upper
	str.punctuation = ' .,?!:;\'"-_'
	str.english = str.letters .. str.punctuation
	str.filepath = str.letters .. ':/'
	str.datastore = ' !#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~'

	-- Returns SerDes for string values, with optional parameter for how long the string will always be.
	setmetatable(str, {__call = function(_, length: number?): SerDes<string>
		if not length then
			return stringSerDes
		end

		assertSchemaType(length, "number", 1, "Squish.string()")

		if stringCache[length] then
			return stringCache[length]
		end

		local serdes: SerDes<string> = {
			type = "string",
			name = "string",
			structure = length,
			ser = function(cursor: Cursor, x: string)
				if VALIDATION_ENABLED then beginValidationScope(cursor, `string[{length}]`) assertSerializeType(cursor, x, "string") end

				tryrealloc(cursor, length)
				pushstr(cursor, x, length)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): string
				return popstr(cursor, length)
			end,
		}
		stringCache[length] = serdes
		return serdes
	end})

	Squish.string = str
end

do 
	local nilCache = {
		type = "nil",
		name = "Nil",
		ser = function(cursor: Cursor)
			tryrealloc(cursor, 1)
			incrementpos(cursor, 1)
		end,
		des = function(cursor: Cursor): nil
			decrementpos(cursor, 1)
			return nil
		end,
	}
	
	-- Returns SerDes that does nothing. that's it.
	function Squish.Nil(): SerDes<nil>
		return nilCache
	end
end

local optMap = setmetatable({}, kvcachemtbl)
do
	local optCache = setmetatable({}, kvcachemtbl)

	-- Returns a copy of the provided SerDes which optionally accepts 'nil' value.
	function Squish.opt<T>(serdes: SerDes<T>): SerDes<T?>
		if optCache[serdes] then
			return optCache[serdes]
		end

		assertIsSerdes(serdes, 1)

		local optSerDes: SerDes<T?> = {
			type = serdes.type,
			name = "opt",
			structure = serdes,
			ser = function(cursor: Cursor, x: any)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "opt") end

				if x == nil then
					tryrealloc(cursor, 1)
					pushu1(cursor, 0)
				else
					serdes.ser(cursor, x)
					tryrealloc(cursor, 1)
					pushu1(cursor, 1)
				end

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor)
				if bit32.btest(popu1(cursor), 1) then
					return serdes.des(cursor)
				else
					return nil
				end
			end,
		}
		optCache[serdes] = optSerDes
		optCache[optSerDes] = optSerDes -- incase opt(opt())
		optMap[optSerDes] = serdes
		return optSerDes
	end

	function Squish.unopt<T>(serdes: SerDes<T?>): SerDes<T>
		return optMap[serdes] or serdes
	end
end

local dedupMap = setmetatable({}, kvcachemtbl)
do
	local dedupCache = setmetatable({}, kvcachemtbl)

	-- Returns a copy of the provided SerDes which can deduplicate the value if provided more than once.
	-- Cannot be used with optional, boolean, nil, and Instance SerDes.
	function Squish.dedup<T>(serdes: SerDes<T>): SerDes<T>
		if dedupCache[serdes] then
			return dedupCache[serdes]
		end
		
		assertIsSerdes(serdes, 1)
		
		if optMap[serdes] then
			error(`Cannot create dedup SerDes for optional SerDes, You have to reverse the order.`)
		elseif serdes.type == "boolean" or serdes.type == "nil" or serdes.name == "Instance" then
			error(`Cannot create dedup SerDes for type {serdes.type}.`)
		end

		local dedupSerDes: SerDes<T> = {
			type = serdes.type,
			name = "dedup",
			structure = serdes,
			ser = function(cursor: Cursor, x: any)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "dedup") end
				
				local deduplookup: {[any]: number} = cursor.serdeduplookup
				if not deduplookup then
					deduplookup = {}
					cursor.serdeduplookup = deduplookup
				end
				
				local deduppos: number? = deduplookup[x]
				
				-- checking is dedupinfo is less than current position inc of des() being used, moving cursor to before the deduplicated value's position.
				if deduppos and deduppos < getpos(cursor) then
					pushvlqrealloc(cursor, deduppos + 1) -- adding 1 because 0 is being used to indicate no deduplication.
				else 
					serdes.ser(cursor, x)
					deduplookup[x] = getpos(cursor)
					
					tryrealloc(cursor, 1)
					pushu1(cursor, 0)
				end
				
				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor)
				local e = popvlq(cursor)
				
				local deduplookup = cursor.desdeduplookup
				if not deduplookup then
					deduplookup = {}
					cursor.desdeduplookup = deduplookup
				end
				
				local returnpos
				local startpos
				
				if e == 0 then
					startpos = getpos(cursor)
					local info = deduplookup[startpos]
					
					if info then
						setpos(cursor, info.s)
						return info.value
					end
				else 
					startpos = e - 1
					local info = deduplookup[startpos]
					
					if info then return info.value
					else 
						returnpos = getpos(cursor)
						setpos(cursor, startpos)
					end
				end
				
				local value = serdes.des(cursor)
				deduplookup[startpos] = {
					s = getpos(cursor),
					value = value,
				}
				
				if returnpos then
					setpos(cursor, returnpos)
				end
				
				return value
			end,
		}
		
		dedupCache[serdes] = dedupSerDes
		dedupCache[dedupSerDes] = dedupSerDes -- incase dedup(dedup())
		dedupMap[dedupSerDes] = serdes
		return dedupSerDes
	end
end

do
	local refSerDes: SerDes<any> = {
		name = "ref",
		
		ser = pushref, 
		des = popref,
	}

	-- Returns SerDes that pushes / pops values from cursor.refs array.
	function Squish.ref(): SerDes<any>
		return refSerDes
	end
end

do
	local bufSerDes: SerDes<buffer> = {
		type = "buffer",
		name = "buffer",
		ser = function(cursor: Cursor, x: buffer)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "buffer") assertSerializeType(cursor, x, "buffer") end

			tryrealloc(cursor, buffer.len(x))
			pushbuf(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popbuf,
	}

	local bufCache = setmetatable({}, kvcachemtbl)

	-- Returns SerDes for buffer values, with optional parameter for how long the buffer will always be.
	function Squish.buffer(length: number?): SerDes<buffer>
		if not length then
			return bufSerDes
		end

		assertSchemaType(length, "number", 1)

		if bufCache[length] then
			return bufCache[length]
		end

		local serdes: SerDes<buffer> = {
			type = "buffer",
			name = "buffer",
			structure = length,
			ser = function(cursor: Cursor, x: buffer)
				if VALIDATION_ENABLED then beginValidationScope(cursor, `buffer[{length}]`) assertSerializeType(cursor, x, "buffer") end

				tryrealloc(cursor, length)
				pushbuf(cursor, x, length)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): buffer
				return popbuf(cursor, length)
			end,
		}
		bufCache[length] = serdes
		return serdes
	end


end

do
	local vlqCache: SerDes<number> = {
		type = "number",
		name = "vlq",
		ser = if VALIDATION_ENABLED then function(cursor: Cursor, x: number)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "vlq") assertSerializeType(cursor, x, "number") end

			pushvlqrealloc(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end else pushvlqrealloc,
		des = popvlq,
	}

	-- Returns SerDes for unsigned integer of any size, used for serializing and deserializing variable lengths.
	function Squish.vlq(): SerDes<number>
		return vlqCache
	end
end 


do
	local arrayCache = setmetatable({}, kcachemtbl)
	
	-- Returns SerDes for arrays, with parameters for which SerDes to use and optional fixed length / serdes for the array.
	function Squish.array<T>(serdes: SerDes<T>, length: Length?): SerDes<{ T }>
		local cached = arrayCache[serdes]
		local key = length or "unbounded"

		assertIsSerdes(serdes, 1)
		assertIsLength(length, 2)

		if cached then
			if cached[key] then
				return cached[key]
			end
		else
			cached = setmetatable({}, kvcachemtbl)
			arrayCache[serdes] = cached
		end

		local underlyingSerDes = optMap[serdes]
		if underlyingSerDes then
			if underlyingSerDes.type == "boolean" then
				local arr: SerDes<{ boolean? }> = {
					type = "table",
					name = "array",

					structure = {serdes, length},

					ser = function(cursor: Cursor, xs: {boolean?})
						if VALIDATION_ENABLED then beginValidationScope(cursor, "optboolarray") assertSerializeType(cursor, xs, "table") end

						local n = length or table.maxn(xs)
						local bools = table.create(n)
						local flags = table.create(n, false)
						for i = 1, n do
							local x = xs[i]
							if x ~= nil then
								table.insert(bools, x)
								flags[i] = true
							end
						end
						local actualBoolCount = #bools
						local boolBytes = (actualBoolCount + 7) // 8
						local flagBytes = (n + 7) // 8
						tryrealloc(cursor, boolBytes + flagBytes)
						serbitarr(cursor, bools)
						serbitarr(cursor, flags)
						
						if not length then
							pushvlqrealloc(cursor, n)
						end

						if VALIDATION_ENABLED then exitValidationScope(cursor) end
					end,
					des = function(cursor: Cursor, result: AnyTable?): {boolean?}
						local n = length or popvlq(cursor)
						local flags = desbitarr(cursor, n)

						local actualBoolCount = 0
						for _, flag in flags do
							actualBoolCount += if flag then 1 else 0
						end
						local bools = desbitarr(cursor, actualBoolCount)

						local xs = result or table.create(n)
						local j = 1
						for i, flag in flags do
							if flag then
								xs[i] = bools[j]
								j += 1
							end
						end
						return xs
					end,
				}
				cached[key] = arr
				return arr :: any
			else
				local arr: SerDes<{ T? }> = {
					type = "table",
					name = "array",

					structure = {serdes, length},

					ser = function(cursor: Cursor, xs: { any }): ()
						if VALIDATION_ENABLED then beginValidationScope(cursor, "optarray") assertSerializeType(cursor, xs, "table") end

						local push = underlyingSerDes.ser

						local n = length or table.maxn(xs)
						local flags = table.create(n, false)
						for i = 1, n do
							local x = xs[i]

							if VALIDATION_ENABLED then overrideValidationScopeName(cursor, `optarray i:{i} | val:{x}`) end

							if x ~= nil then
								push(cursor, x :: any)
								flags[i] = true
							end
						end
						local flagBytes = (n + 7) // 8
						tryrealloc(cursor, flagBytes)
						serbitarr(cursor, flags)
						if not length then
							pushvlqrealloc(cursor, n)
						end

						if VALIDATION_ENABLED then exitValidationScope(cursor) end
					end,
					des = function(cursor: Cursor, result: AnyTable?): {T?}
						local pop = underlyingSerDes.des

						local n = length or popvlq(cursor)
						local flags = desbitarr(cursor, n)

						local xs = result or table.create(n)
						for i = n, 1, -1 do
							if flags[i] then
								xs[i] = pop(cursor)
							end
						end
						return xs :: any
					end,
				}
				cached[key] = arr
				return arr :: any
			end
		elseif serdes.type == "boolean" then
			local arr: SerDes<{ boolean }> = {
				type = "table",
				name = "array",

				structure = {serdes, length},

				ser = function(cursor: Cursor, xs: {boolean})
					if VALIDATION_ENABLED then beginValidationScope(cursor, "boolarray") assertSerializeType(cursor, xs, "table") end

					local n = length or table.maxn(xs)
					tryrealloc(cursor, (n + 7) // 8)
					serbitarr(cursor, xs, n)

					if not length then
						pushvlqrealloc(cursor, n)
					end

					if VALIDATION_ENABLED then exitValidationScope(cursor) end
				end,
				des = function(cursor: Cursor, result: AnyTable?): {boolean}
					local n = length or popvlq(cursor)
					
					local xs = desbitarr(cursor, n)
					if result then 
						table.move(xs, 1, n, 1, result)
						return result
					end
					
					return xs
				end,
			}
			cached[key] = arr
			return arr :: any
		else
			local arr: SerDes<{ T }> = {
				type = "table",
				name = "array",

				structure = {serdes, length},

				ser = function(cursor: Cursor, xs: {any})
					if VALIDATION_ENABLED then beginValidationScope(cursor, "array") assertSerializeType(cursor, xs, "table") end

					local push = serdes.ser

					local n = length or table.maxn(xs)
					for i = 1, n do
						local x = xs[i]
						if VALIDATION_ENABLED then overrideValidationScopeName(cursor, `array i:{i} | val:{x}`) end

						push(cursor, x)
					end

					if not length then
						pushvlqrealloc(cursor, n)					
					end

					if VALIDATION_ENABLED then exitValidationScope(cursor) end
				end,
				des = function(cursor: Cursor, result: AnyTable?): {any}
					local pop = serdes.des

					local n = length or popvlq(cursor)
					local xs = result or table.create(n)
					for i = n, 1, -1 do
						xs[i] = pop(cursor)
					end
					return xs
				end,
			}
			cached[key] = arr
			return arr
		end
	end
end

do
	type function unwrapTuple(f: type)
		local args = f:parameters()
		local head = args.head :: {type}
				
		for i, t in head do 
			local success, t = safeUnwrapSerdes(t) 
			if not success then
				print(`Expected provided parameter [{i}] to be a SerDes, but got {t.tag}.`)
				return NeverTable
			end
			
			head[i] = t
		end

		local s = TupleSerDes(unpack(head))

		return s
	end

	-- Returns SerDes for multiple values at a time.
	-- <strong>Example:</strong> <em>Squish.tuple(Squish.string(), Squish.u8(), Squish.bool()).</em>
	function Squish.tuple<T...>(...: T...): unwrapTuple<(T...) -> ()>
		local serdesargs: { SerDes<any> } = { ... }

		for i, serdes in serdesargs do 
			assertIsSerdes(serdes, i)
		end

		local count = #serdesargs
		if count == 1 then return serdesargs[1] end

		local reversedserdes = reverseArray(serdesargs)

		local tuple: SerDes<any> = {
			type = nil,
			name = "tuple",

			structure = serdesargs,

			ser = function(cursor: Cursor, ...: any)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "tuple") end

				for i, serdes in serdesargs do 
					local v = select(i, ...)
					if VALIDATION_ENABLED then overrideValidationScopeName(cursor, `tuple i:{i} | val:{v}`) end
					serdes.ser(cursor, v)
				end

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor)
				local result = table.create(count)

				for i, serdes in reversedserdes do 
					result[count - (i - 1)] = serdes.des(cursor)
				end

				return unpack(result, 1, count)
			end,
		}

		return tuple 
	end
end

do
	type function UnwrapRecord(defType: type)
		if not defType:is("table") then
			if defType.tag == "any" then return AnyTable end
			print("records expect a table containing string:SerDes pairs.")
			return NeverTable
		end

		local props = defType:properties()
		local newProps = {}

		local desKey = types.singleton("des")
		local missingvalues = true

		for keyType, propData in props do
			if not (keyType:is("singleton") and typeof(keyType:value()) == "string") then
				print("Expected key to be a string, but got " .. keyType.tag)
				return NeverTable
			end

			local serdesType = propData.read

			if serdesType then

				if serdesType:is("table") then
					local desFunc = serdesType:readproperty(desKey)

					if desFunc and desFunc:is("function") then
						missingvalues = false

						local rets = desFunc:returns()
						local unwrappedType = (rets.head and rets.head[1]) or types.unknown

						newProps[keyType] = { read = unwrappedType, write = unwrappedType }
						continue
					end
				end

				print(`Expected record definition valuetype to be SerDes, but got {serdesType.tag} for {keyType:value()}`)
				return NeverTable
			else 
				print(`Expected record definition valuetype to be SerDes, but got nothing for {keyType:value()}`)
				return NeverTable
			end

		end

		if missingvalues then
			local indexer = defType:indexer()

			if indexer then
				local index = indexer.index
				local readresult = indexer.readresult
				local success, readresult = safeUnwrapSerdes(readresult) 

				if (index.tag == "string" or index.tag == "any") and (success or readresult.tag == "any") then
					return types.newtable(nil, {index = index, readresult = readresult, writeresult = readresult})
				end

				print(`Expected to be provided a record containing string:SerDes pairs, but got a table with {index.tag}:{if success then "SerDes" else readresult.tag} pairs.`)
			else 
				print("Expected to be provided a record containing string:SerDes pairs, but got nothing.")
			end

			return NeverTable
		end

		return types.newtable(newProps)
	end

	type anyRecordTable = {[string]: any}

	type StructProperty = {
		name: string,
		ser: index<SerDes<any>, "ser">,
		des: index<SerDes<any>, "des">
	}

	local function sortPropertyHandler(a1: StructProperty, a2: StructProperty)
		return a1.name < a2.name
	end

	-- Returns SerDes for fixed string:value dictionaries.
	-- <strong>Example:</strong> <em>Squish.record{ UserId = Squish.u32(), Name = Squish.string() }</em>
	function Squish.record<T>(schema: T): SerDes<UnwrapRecord<T>>
		local properties: {StructProperty} = {}
		local optProperties: {StructProperty} = {}
		local boolProperties: {string} = {}
		local optboolProperties: {string} = {}

		local basicstructure: {[string]: any} = {}

		assertSchemaType(schema, "table", 1)

		for name, serdes in schema do
			assertSchemaType(name, "string", "record")
			assertIsSerdes(serdes, `record.{name}`)

			local optVal = optMap[serdes]

			if optVal then
				if optVal.type == "boolean" then
					table.insert(optboolProperties, name)
				else
					table.insert(optProperties, {
						name = name,
						ser = optVal.ser,
						des = optVal.des
					})
				end
			else
				basicstructure[name] = false 

				if serdes.type == "boolean" then
					table.insert(boolProperties, name)
				else
					table.insert(properties, {
						name = name,
						ser = serdes.ser,
						des = serdes.des
					})
				end
			end
		end

		table.sort(properties, sortPropertyHandler)
		local reverseproperties = reverseArray(properties)

		local boolCount = #boolProperties
		local hasbool = boolCount > 0
		table.sort(boolProperties)

		local optCount = #optProperties
		table.sort(optProperties, sortPropertyHandler)

		local optboolCount = #optboolProperties
		local hasoptbool = optboolCount > 0
		table.sort(optboolProperties)

		local hasanybool = hasbool or hasoptbool
		local hasOpt = hasoptbool or optCount > 0

		return {
			type = "table",
			name = "record",

			structure = schema,

			ser = function(cursor: Cursor, record: anyRecordTable)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "record") assertSerializeType(cursor, record, "table") end

				for _, prop: StructProperty in properties do
					local name = prop.name
					local val = record[name]

					if VALIDATION_ENABLED then overrideValidationScopeName(cursor, `record key:{name} | val:{val}`) end

					prop.ser(cursor, val)
				end

				local bools = hasanybool and table.create(boolCount + optboolCount)

				for i, prop in boolProperties do
					local val = record[prop]
					bools[i] = val
				end

				if hasOpt then
					local flags = table.create(optboolCount + optCount, false)
					local actualBoolCount = boolCount

					if hasoptbool then
						for i, prop in optboolProperties do
							local val = record[prop]
							local valueexists = val ~= nil 

							flags[i] = valueexists
							if valueexists then
								actualBoolCount += 1
								bools[actualBoolCount] = val
							end
						end
					end

					for i, prop in optProperties do
						local name = prop.name
						local f = i + optboolCount
						local val = record[name]
						local valueexists = val ~= nil 

						flags[f] = valueexists
						if valueexists then
							if VALIDATION_ENABLED then overrideValidationScopeName(cursor, `record optkey:{name} | val:{val}`) end

							prop.ser(cursor, val)
						end
					end

					tryrealloc(cursor, actualBoolCount + optCount)

					if hasanybool then serbitarr(cursor, bools, actualBoolCount) end
					serbitarr(cursor, flags, optboolCount + optCount)

				elseif hasbool then
					tryrealloc(cursor, boolCount)
					serbitarr(cursor, bools, boolCount)
				end

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor: Cursor, result: AnyTable?): UnwrapRecord<T>
				local new: anyRecordTable = result or table.clone(basicstructure)
				local bools, flags

				if hasOpt then
					flags = desbitarr(cursor, optboolCount + optCount)

					-- no need to check if we have any bools, nothing will happen if none exist.

					local actualBoolCount = boolCount
					for i = 1, optboolCount do
						if flags[i] then actualBoolCount += 1 end
					end

					bools = desbitarr(cursor, actualBoolCount)

					for i = optboolCount, 1, -1 do
						local flag = flags[i]
						if flag then
							local prop = optboolProperties[i]
							new[prop] = bools[actualBoolCount]
							actualBoolCount -= 1
						end
					end

					for i = optCount, 1, -1 do
						local flag = flags[i + optboolCount]
						if flag then
							local prop = optProperties[i]
							new[prop.name] = prop.des(cursor)
						end
					end

				elseif hasbool then
					bools = desbitarr(cursor, boolCount)
				end

				-- if boolproperties has anything then bools exists, no need to check if we got bools.
				for i, prop in boolProperties do
					new[prop] = bools[i]
				end

				for _, prop in reverseproperties do
					new[prop.name] = prop.des(cursor)
				end

				return new
			end,
		}
	end
end

do
	local mapCache = setmetatable({}, kcachemtbl)

	-- Returns a SerDes for dictionaries, with optional parameter for how long the map should always be.
	-- Serialization of keys and values is determined by keySerDes and valueSerDes.
	-- if the type of a key or value is not supported, it may error or behave unpredictably.
	function Squish.map<K, V>(keySerDes: SerDes<K>, valueSerDes: SerDes<V>, length: Length?): SerDes<{ [K]: V }>

		assertIsSerdes(keySerDes, 1)
		assertIsSerdes(valueSerDes, 2)
		assertIsLength(length, 3)

		keySerDes = Squish.unopt(keySerDes)
		valueSerDes = Squish.unopt(valueSerDes)

		local cache = mapCache[keySerDes]
		local subcache = cache and cache[valueSerDes]
		local key = length or 0

		if subcache then
			local old = subcache[key]
			if old then return old end
		else
			subcache = setmetatable({}, vcachemtbl)

			if cache then cache[valueSerDes] = subcache
			else
				cache = setmetatable({[valueSerDes] = subcache}, kcachemtbl)
				mapCache[keySerDes] = cache
			end
		end

		local map = {
			type = "table",
			name = "map",

			structure = {keySerDes, valueSerDes, length},

			ser = function(cursor: Cursor, map: AnyTable)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "map") end

				local size = 0
				for k, v in map :: any do
					if VALIDATION_ENABLED then overrideValidationScopeName(cursor, `map key:{k} | val:{v}`) end

					valueSerDes.ser(cursor, v);
					keySerDes.ser(cursor, k)
					size += 1
				end

				if not length then
					pushvlqrealloc(cursor, size)
				elseif size ~= length then
					reportValidationError(cursor, `Expected map length to be equal to {length}, but got {size}.`)
				end

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor: Cursor, result: AnyTable?): {[K]: V}
				local map = result or {}

				local size = length or popvlq(cursor)

				for _ = 1, size do
					local key = keySerDes.des(cursor)
					local value = valueSerDes.des(cursor)

					if key ~= nil then
						map[key] = value
					end
				end

				return map :: any
			end,
		}

		subcache[key] = map 

		return map
	end
end

local nilidkey, nanidkey = table.freeze{}, table.freeze{}
	
local literalsmap_mtbl = {
	__index = function(self, key)
		if key == nil then return rawget(self, nilidkey)
		elseif key ~= key then return rawget(self, nanidkey) end 
			
		return nil
	end,
}
	
do
	
	-- Returns SerDes for only values that are provided to this function. 
	function Squish.literal<T>(array: {T}): SerDes<T>
		local map = {}
		local literals = {}

		for i, literal in array do
			local id = i - 1

			if literal ~= literal then map[nanidkey] = id
			else map[literal] = id end

			literals[id] = literal
		end

		if map[nanidkey] then
			setmetatable(map, literalsmap_mtbl)
		end

		local serdes: SerDes<any> = {
			type = nil,
			name = "literal",
			
			multypeinfo = {
				literals = literals,
				literalsMap = map,
			},

			ser = function(cursor: Cursor, literal: any)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "literal") end 
				local v = map[literal]

				if not v then
					reportValidationError(cursor, `{literal} is not a valid option for this literals SerDes.`)
				end

				tryrealloc(cursor, 1)
				pushu1(cursor, v)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end 
			end,

			des = function(cursor)
				return literals[popu1(cursor)]
			end,
		}

		return serdes
	end

	-- Adds the provided literals to the SerDes.
	function Squish.addliterals(serdes: SerDes<any>, ...: any)
		serdes = Squish.unopt(serdes)
		
		local info = serdes.multypeinfo
		assert(info and info.literals and info.literalsMap, "SerDes does not support adding literals.")

		local literals = info.literals
		local literalsMap = info.literalsMap

		local lastidx = table.maxn(literals)
		if lastidx == 0 and literals[0] == nil then lastidx = -1 end
		
		for i = 1, select("#", ...) do 
			local v = select(i, ...)

			if literalsMap[v] then continue end
			if v ~= v and literalsMap[nanidkey] then continue end
			if v == nil and literalsMap[nilidkey] then continue end

			lastidx += 1
			literals[lastidx] = v 

			if v ~= v then
				literalsMap[nanidkey] = lastidx
				setmetatable(literalsMap, literalsmap_mtbl)
			elseif v == nil then 
				literalsMap[nilidkey] = lastidx
				setmetatable(literalsMap, literalsmap_mtbl)
			else 
				literalsMap[v] = lastidx
			end
		end
	end
end 

do
	local tableCache = setmetatable({}, kvcachemtbl)
	local writingArray = {}

	-- Returns SerDes for arbitrary tables of any shape. supporting mixed tables, gaps, and circular references.
	function Squish.table<T>(serdes: SerDes<T>): SerDes<{[T]: T}>
		assertIsSerdes(serdes, 1)
		if tableCache[serdes] then return tableCache[serdes] end

		local tbl: SerDes<{[any]: any}> = {
			type = "table",
			name = "table",

			structure = serdes,
			
			ser = function(cursor: Cursor, x: {[any]: any})
				if VALIDATION_ENABLED then beginValidationScope(cursor, "table") assertSerializeType(cursor, x, "table") end

				local scanlist = cursor.scanlist
				if not scanlist then
					scanlist = {{ tbl = x, serdes = serdes }}
					cursor.scanlist = scanlist
					cursor.scancount = 1
					cursor.valuelookup = {[x] = 1}
				else
					local scanpos = cursor.valuelookup[x]
					
					if not scanpos then
						scanpos = cursor.scancount + 1
						cursor.scancount = scanpos
						scanlist[scanpos] = {tbl = x, serdes = serdes}
						cursor.valuelookup[x] = scanpos
					end
					
					pushvlqrealloc(cursor, scanpos)

					if VALIDATION_ENABLED then exitValidationScope(cursor) end
					return
				end

				local i = 1
				while i <= cursor.scancount do
					local current = scanlist[i]
					local currentTable = current.tbl
					local currentSerdes = current.serdes
					
					local arraylen = #currentTable
					local dictlen = 0
					
					local startpos = getpos(cursor)

					local doingArray = arraylen > 0
					local lastidx = 0
					
					for k, v in currentTable do 
						if doingArray then 
							local diff = k - lastidx
							if diff > 1 then 
								-- a gap, reconcile.
								for i = 2, diff do currentSerdes.ser(cursor, nil) end
							end

							currentSerdes.ser(cursor, v)
							lastidx = k

							if k == arraylen then doingArray = false end
							continue
						end

						dictlen += 1

						currentSerdes.ser(cursor, k)
						currentSerdes.ser(cursor, v)
					end

					pushvlqrealloc(cursor, arraylen)
					pushvlqrealloc(cursor, dictlen)
					
					local chunklen = getpos(cursor) - startpos
					pushvlqrealloc(cursor, chunklen)

					i += 1
				end

				pushvlqrealloc(cursor, cursor.scancount)

				cursor.scanlist = nil
				cursor.scancount = nil
				cursor.valuelookup = nil

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor: Cursor, result: AnyTable?): {[any]: any}
				local scanlist = cursor.scanlist

				if not scanlist then
					scanlist = {}
					cursor.scanlist = scanlist
				else
					local scanpos = popvlq(cursor)
					local current = scanlist[scanpos]

					if current then
						if not current.serdes then
							current.serdes = serdes
						end
						return current.tbl
					end
					
					return {} -- corrupted table? 
				end

				local scancount = popvlq(cursor)

				for idx = scancount, 1, -1 do
					local chunklen = popvlq(cursor)
					local end_pos = getpos(cursor)
					
					scanlist[idx] = {
						tbl = if idx == 1 and result then result else {},
						end_pos = end_pos
					}
					
					setpos(cursor, end_pos - chunklen)
				end

				local end_of_tables = getpos(cursor)

				for idx = 1, scancount do
					local current = scanlist[idx]
					local currentTable = current.tbl
					local currentSerdes = current.serdes or serdes

					setpos(cursor, current.end_pos)

					local dictlen = popvlq(cursor)
					local arraylen = popvlq(cursor)

					for _ = 1, dictlen do
						local v = currentSerdes.des(cursor)
						local k = currentSerdes.des(cursor)
						if k ~= nil then currentTable[k] = v end
					end

					for i = arraylen, 1, -1 do
						writingArray[i] = currentSerdes.des(cursor)
					end

					table.move(writingArray, 1, arraylen, 1, currentTable)
				end

				setpos(cursor, end_of_tables)

				cursor.scanlist = nil
				table.clear(writingArray)

				local rootTable = scanlist[1].tbl
				return rootTable :: any
			end,
		}
		
		tableCache[serdes] = tbl
		return tbl
	end
end

do
	local vectortype = if Vector3 then "Vector3" else "vector"
	local maxvectorsize = if has4wideVectors then 4 else 3

	local f32 = Squish.f32()
	
	local vectorCache = {
		[2] = {[f32] = { -- optimized default
			type = vectortype,
			name = "vector",
			structure = {2, f32},

			ser = function(cursor: Cursor, x: Vector2)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "vector (2)") assertSerializeType(cursor, x, vectortype) end

				tryrealloc(cursor, 8)
				local buf, pos = getbuf(cursor), incrementpos(cursor, 8)
				buffer.writef32(buf, pos, x.y)
				buffer.writef32(buf, pos + 4, x.x)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor: Cursor): vector
				local buf, pos = getbuf(cursor), incrementpos(cursor, -8)
				local x, y = buffer.readf32(buf, pos - 4), buffer.readf32(buf, pos - 8)
				return vector.create(x, y)
			end
		}},
		
		[3] = {[f32] = { -- optimized default
			type = vectortype,
			name = "vector",
			structure = {3, f32},

			ser = function(cursor: Cursor, x: vector)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "vector (3)") assertSerializeType(cursor, x, vectortype) end

				tryrealloc(cursor, 12)
				local buf, pos = getbuf(cursor), incrementpos(cursor, 12)
				buffer.writef32(buf, pos, x.z)
				buffer.writef32(buf, pos + 4, x.y)
				buffer.writef32(buf, pos + 8, x.x)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor: Cursor): vector
				local buf, pos = getbuf(cursor), incrementpos(cursor, -12)
				local x, y, z = buffer.readf32(buf, pos - 4), buffer.readf32(buf, pos - 8), buffer.readf32(buf, pos - 12)
				return vector.create(x, y, z)
			end
		}},
		
		[4] = if has4wideVectors then {
			[f32] = { -- optimized default
				type = vectortype,
				name = "vector",
				structure = {4, f32},

				ser = function(cursor: Cursor, x: vector)
					if VALIDATION_ENABLED then beginValidationScope(cursor, "vector (4)") assertSerializeType(cursor, x, vectortype) end

					tryrealloc(cursor, 16)
					local buf, pos = getbuf(cursor), incrementpos(cursor, 16)
					buffer.writef32(buf, pos, x.w)
					buffer.writef32(buf, pos + 4, x.z)
					buffer.writef32(buf, pos + 8, x.y)
					buffer.writef32(buf, pos + 12, x.x)

					if VALIDATION_ENABLED then exitValidationScope(cursor) end
				end,

				des = function(cursor: Cursor): vector
					local buf, pos = getbuf(cursor), incrementpos(cursor, -16)
					local x, y, z, w = buffer.readf32(buf, pos - 4), buffer.readf32(buf, pos - 8), buffer.readf32(buf, pos - 12), buffer.readf32(buf, pos - 16)
					return vector.create(x, y, z, w)
				end
			}
		} else nil
	}

	-- Returns SerDes for vector datatype, with optional parameters for the length of vector (2, 3, and 4 if supported) and which SerDes to use.
	-- SerDes defaults to f32.
	function Squish.vector(length: number?, serdes: SerDes<number>?): SerDes<vector>
		if length == nil then
			length = maxvectorsize
		else 
			assertSchemaType(length, "number", 1)
			if length < 2 or length > maxvectorsize then
				error(`Expected vector length to be between 2 and {maxvectorsize}, got {length}.`)
			end
		end
		
		if serdes == nil then serdes = f32
		else 
			assertIsSerdes(serdes, 2) 
			assertSerdesType(serdes, "number")	
		end
		
		local cache = vectorCache[length]

		if cache[serdes] then
			return cache[serdes]
		end

		local size, push, pop = getNumberSizePushPop(serdes)
		if size then size *= length end
		local vec: SerDes<vector>
		
		if length == 2 then
			vec = {
				type = vectortype,

				ser = function(cursor: Cursor, x: vector)
					if VALIDATION_ENABLED then beginValidationScope(cursor, "vector (2)") assertSerializeType(cursor, x, vectortype) end

					local push = push

					if size then tryrealloc(cursor, size) end
					push(cursor, x.y)
					push(cursor, x.x)

					if VALIDATION_ENABLED then exitValidationScope(cursor) end
				end,

				des = function(cursor: Cursor): vector
					local pop = pop
					return vector.create(pop(cursor), pop(cursor))
				end
			}
		elseif length == 3 then
			vec = {
				type = vectortype,

				ser = function(cursor: Cursor, x: vector)
					local push = push
					if VALIDATION_ENABLED then beginValidationScope(cursor, "vector (3)") assertSerializeType(cursor, x, vectortype) end

					if size then tryrealloc(cursor, size) end
					push(cursor, x.z)
					push(cursor, x.y)
					push(cursor, x.x)

					if VALIDATION_ENABLED then exitValidationScope(cursor) end
				end,

				des = function(cursor: Cursor): vector
					local pop = pop
					return vector.create(pop(cursor), pop(cursor), pop(cursor))
				end
			}
		elseif has4wideVectors and length == 4 then
			vec = {
				type = vectortype,

				ser = function(cursor: Cursor, x: vector)
					local push = push 
					if VALIDATION_ENABLED then beginValidationScope(cursor, "vector (4)") assertSerializeType(cursor, x, vectortype) end

					if size then tryrealloc(cursor, size) end
					push(cursor, x.w)
					push(cursor, x.z)
					push(cursor, x.y)
					push(cursor, x.x)

					if VALIDATION_ENABLED then exitValidationScope(cursor) end
				end,

				des = function(cursor: Cursor): vector
					local pop = pop
					return vector.create(pop(cursor), pop(cursor), pop(cursor), pop(cursor))
				end
			}
		else 
			error(`length {size} is not supported for Squish.vector().`)
		end

		vec.name, vec.structure = "vector", {length, serdes}

		cache[serdes] = vec
		return vec
	end

	-- Wrapper for Squish.vector(3).
	function Squish.Vector3(serdes: SerDes<number>?): SerDes<Vector3>
		return Squish.vector(3, serdes)
	end
end

--[roblox]<<

if Vector2 ~= nil then
	local f32 = Squish.f32()

	local vector2Cache = {
		[f32] = { -- optimized default
			type = "Vector2",
			name = "Vector2",
			structure = f32,

			ser = function(cursor: Cursor, x: Vector2)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "Vector2") assertSerializeType(cursor, x, "Vector2") end

				tryrealloc(cursor, 8)
				local buf, pos = getbuf(cursor), incrementpos(cursor, 8)
				buffer.writef32(buf, pos, x.Y)
				buffer.writef32(buf, pos + 4, x.X)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor: Cursor): Vector2
				local buf, pos = getbuf(cursor), incrementpos(cursor, -8)
				local x, y = buffer.readf32(buf, pos - 4), buffer.readf32(buf, pos - 8)
				return Vector2.new(x, y)
			end
		}
	}

	-- Returns SerDes for 'Vector2' datatype, with optional parameter for which SerDes to use.
	-- <strong>Not the same as Squish.vector(2)</strong>, this is a different datatype unfortunately.
	-- Defaults to f32.
	function Squish.Vector2(serdes: SerDes<number>?): SerDes<Vector2>
		if serdes == nil then serdes = f32
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if vector2Cache[serdes] then
			return vector2Cache[serdes]
		end

		local size, push, pop = getNumberSizePushPop(serdes)
		if size then size *= 2 end 

		local vec: SerDes<Vector2> = {
			type = "Vector2",
			name = "Vector2",
			structure = serdes,

			ser = function(cursor: Cursor, x: Vector2)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "Vector2") assertSerializeType(cursor, x, "Vector2") end

				local push = push

				if size then tryrealloc(cursor, size) end
				push(cursor, x.Y)
				push(cursor, x.X)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor: Cursor): Vector2
				local pop = pop
				return Vector2.new(pop(cursor), pop(cursor))
			end
		}

		vector2Cache[serdes] = vec
		return vec
	end
end

if Axes ~= nil then
	local axesCache: SerDes<Axes> = {
		type = "Axes",
		name = "Axes",
		ser = function(cursor: Cursor, axes: Axes)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "Axes") assertSerializeType(cursor, axes, "Axes") end

			tryrealloc(cursor, 2)
			pushboolpack(cursor, axes.Back, axes.Bottom, axes.Front, axes.Left, axes.Right, axes.Top)
			pushboolpack(cursor, axes.X, axes.Y, axes.Z)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): Axes
			local x, y, z = popboolpack(cursor)
			local back, bottom, front, left, right, top = popboolpack(cursor)
			return Axes.new(
				x and Enum.Axis.X :: any,
				y and Enum.Axis.Y :: any,
				z and Enum.Axis.Z :: any,
				back and Enum.NormalId.Back :: any,
				bottom and Enum.NormalId.Bottom :: any,
				front and Enum.NormalId.Front :: any,
				left and Enum.NormalId.Left :: any,
				right and Enum.NormalId.Right :: any,
				top and Enum.NormalId.Top :: any
			)
		end,
	}

	-- Returns SerDes for 'Axes' datatype.
	function Squish.Axes(): SerDes<Axes>
		return axesCache
	end
end

if BrickColor ~= nil then
	local brickcolorCache: SerDes<BrickColor> = {
		type = "BrickColor",
		name = "BrickColor",
		ser = function(cursor: Cursor, brickcolor: BrickColor)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "BrickColor") assertSerializeType(cursor, brickcolor, "BrickColor") end

			tryrealloc(cursor, 2)
			pushu2(cursor, brickcolor.Number)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): BrickColor
			local number = popu2(cursor)
			return BrickColor.new(number)
		end,
	}

	-- Returns SerDes for 'BrickColor' datatype.
	function Squish.BrickColor(): SerDes<BrickColor>
		return brickcolorCache
	end

end

local enumitem
if Enum ~= nil then
	type enuminfo = {
		enum: Enum,

		packedname: string,
		packedlen: number,

		idsToItems: {EnumItem},
		itemsToIds: {[EnumItem]: number},
	}
	local packintoalphanumeric = Squish.string.packintoalphanumeric
	local unpackalphanumeric = Squish.string.unpackalphanumeric

	local nametoenum = {}
	local enuminfo: {[Enum]: enuminfo} = {}
	local unpackcache: {[string]: string} = {}

	local enuminfometa = {
		__index = function(t, key: string)
			if key == "packedname" or key == "packedlen" then
				local enumname = tostring(rawget(t, "enum"))
				local buf, len = packintoalphanumeric(enumname)
				local packedname = buffer.tostring(buf)

				t.packedname = packedname 
				t.packedlen = len 

				unpackcache[packedname] = enumname

				return if key == "packedname" then packedname else len
			end

			return
		end,
	}

	local function GetInfoForEnum(enum: Enum)
		local info = enuminfo[enum]
		if info then
			return info
		end

		local sortedItems = enum:GetEnumItems()
		table.sort(sortedItems, function(a, b) return a.Value < b.Value end)

		local itemsToIds = {}
		local idsToItems = table.create(#sortedItems)
		for i, item in sortedItems do
			itemsToIds[item] = i
			idsToItems[i] = item
		end

		local info = setmetatable({
			enum = enum,
			idsToItems = idsToItems,
			itemsToIds = itemsToIds,
		}, enuminfometa)

		enuminfo[enum] = info
		return info
	end

	for _, enum in Enum:GetEnums() do 
		nametoenum[tostring(enum)] = enum
	end

	local enumItemCache = {
		[""] = {
			type = "EnumItem",
			name = "EnumItem",
			ser = function(cursor: Cursor, x: EnumItem)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "EnumItem") assertSerializeType(cursor, x, "EnumItem") end

				local enumtype = x.EnumType
				local info = GetInfoForEnum(enumtype)

				local name, len = info.packedname, info.packedlen
				tryrealloc(cursor, len)
				buffer.writestring(getbuf(cursor), incrementpos(cursor, len), name)
				pushvlqrealloc(cursor, len)

				pushvlqrealloc(cursor, info.itemsToIds[x])

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor: Cursor): EnumItem
				local id = popvlq(cursor)
				local str = popstr(cursor)

				local name = unpackcache[str]
				if name == nil then
					name = unpackalphanumeric(buffer.fromstring(str))
					unpackcache[str] = name
				end

				local enum = nametoenum[name]

				if enum then
					local info = GetInfoForEnum(enum)
					return info.idsToItems[id]
				end

				return
			end,
		}
	}
	-- Returns SerDes for 'EnumItem' datatype. with optional parameter for the enumitem type to serialize.
	-- Will serialize any enumitem if the enum type is not specified.
	-- <strong>Example:</strong> <em>Squish.EnumItem(Enum.Material)</em>
	function Squish.EnumItem<T>(enum: T | Enum): SerDes<optional<T, EnumItem>>
		if enum == nil then return enumItemCache[""] end 

		if typeof(enum) == "EnumItem" then enum = enum.EnumType end 
		assert(typeof(enum) == "Enum", `Expected parameter 1 to be an Enum, but got {subtypeof(enum)}.`)

		if enumItemCache[enum] then
			return enumItemCache[enum]
		end

		local info = GetInfoForEnum(enum)

		local itemsToIds = info.itemsToIds
		local idsToItems = info.idsToItems

		local t = `EnumItem:{tostring(enum)}`

		local item: SerDes<EnumItem> = {
			type = t,
			name = "EnumItem",
			structure = enum,
			ser = function(cursor: Cursor, item: EnumItem)
				if VALIDATION_ENABLED then beginValidationScope(cursor, t) end
				local id = itemsToIds[item]

				if not id then reportValidationError(cursor, `{item} is not a valid option for {t}.`) end

				pushvlqrealloc(cursor, id)
				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor)
				local itemId = popvlq(cursor)
				return idsToItems[itemId]
			end,
		}

		enumItemCache[enum] = item
		return item
	end

	enumitem = Squish.EnumItem
end

if CatalogSearchParams ~= nil then
	local assettypeserdes = enumitem(Enum.AssetType)
	local salestypefilterserdes = enumitem(Enum.SalesTypeFilter)
	local categoryfilterserdes = enumitem(Enum.CatalogCategoryFilter)
	local sortaggregationserdes = enumitem(Enum.CatalogSortAggregation)
	local sorttypeserdes = enumitem(Enum.CatalogSortType)

	local catalogSearchParamsCache: SerDes<CatalogSearchParams> = {
		type = "CatalogSearchParams",
		name = "CatalogSearchParams",
		ser = function(cursor: Cursor, params: CatalogSearchParams)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "CatalogSearchParams") assertSerializeType(cursor, params, "CatalogSearchParams") end

			tryrealloc(cursor, 1 + 1 + 4 + 4 + #params.CreatorName + #params.SearchKeyword)
			pushbool(cursor, params.IncludeOffSale)
			pushu1(cursor, params.Limit)
			pushu4(cursor, params.MinPrice)
			pushu4(cursor, params.MaxPrice)
			pushstr(cursor, params.CreatorName)
			pushstr(cursor, params.SearchKeyword)
			sorttypeserdes.ser(cursor, params.SortType)
			sortaggregationserdes.ser(cursor, params.SortAggregation)
			categoryfilterserdes.ser(cursor, params.CategoryFilter)
			salestypefilterserdes.ser(cursor, params.SalesTypeFilter)
			for _, assetType in params.AssetTypes do
				assettypeserdes.ser(cursor, assetType)
			end
			pushvlqrealloc(cursor, #params.AssetTypes)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): CatalogSearchParams
			local params = CatalogSearchParams.new()
			local assetCount = popvlq(cursor)
			local assetTypes = table.create(assetCount)
			for i = assetCount, 1, -1 do
				assetTypes[i] = assettypeserdes.des(cursor) :: Enum.AssetType
			end
			params.AssetTypes = assetTypes

			params.SalesTypeFilter = salestypefilterserdes.des(cursor)
			params.CategoryFilter = categoryfilterserdes.des(cursor) :: Enum.CatalogCategoryFilter
			params.SortAggregation = sortaggregationserdes.des(cursor)
			params.SortType = sorttypeserdes.des(cursor) :: Enum.CatalogSortType
			params.SearchKeyword = popstr(cursor)
			params.CreatorName = popstr(cursor)
			params.MaxPrice = popu4(cursor)
			params.MinPrice = popu4(cursor)
			params.Limit = popu1(cursor)
			params.IncludeOffSale = popbool(cursor)
			return params
		end,
	}

	-- Returns SerDes for 'CatalogSearchParams' datatype.
	function Squish.CatalogSearchParams(): SerDes<CatalogSearchParams>
		return catalogSearchParamsCache
	end

end

if CFrame ~= nil then
	local idToRotation = {
		CFrame.Angles(0, 0, 0),
		CFrame.Angles(math.rad(90), 0, 0),
		CFrame.Angles(0, math.rad(180), math.rad(180)),
		CFrame.Angles(math.rad(-90), 0, 0),
		CFrame.Angles(0, math.rad(180), math.rad(90)),
		CFrame.Angles(0, math.rad(90), math.rad(90)),
		CFrame.Angles(0, 0, math.rad(90)),
		CFrame.Angles(0, math.rad(-90), math.rad(90)),
		CFrame.Angles(math.rad(-90), math.rad(-90), 0),
		CFrame.Angles(0, math.rad(-90), 0),
		CFrame.Angles(math.rad(90), math.rad(-90), 0),
		CFrame.Angles(0, math.rad(90), math.rad(180)),
		CFrame.Angles(0, math.rad(-90), math.rad(180)),
		CFrame.Angles(0, math.rad(180), math.rad(0)),
		CFrame.Angles(math.rad(-90), math.rad(-180), math.rad(0)),
		CFrame.Angles(0, math.rad(0), math.rad(180)),
		CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
		CFrame.Angles(0, math.rad(0), math.rad(-90)),
		CFrame.Angles(0, math.rad(-90), math.rad(-90)),
		CFrame.Angles(0, math.rad(-180), math.rad(-90)),
		CFrame.Angles(0, math.rad(90), math.rad(-90)),
		CFrame.Angles(math.rad(90), math.rad(90), 0),
		CFrame.Angles(0, math.rad(90), 0),
		CFrame.Angles(math.rad(-90), math.rad(90), 0),
	}

	local rotationToId = {}
	
	for i, v in idToRotation do
		local axis, theta = v:ToAxisAngle()
		local hashcheckvec = vector.floor(((axis :: vector) * theta) * 1000) / 1000
		rotationToId[hashcheckvec] = i
	end

	local range = (2^15 - 0.5)
	local invrange = 1/range
	local ToAxisAngle = CFrame.identity.ToAxisAngle
	
	local function SerRotation(cursor: Cursor, cframe: CFrame, sizeoffset: number?)
		local axis, theta = ToAxisAngle(cframe)
		local hashcheckvec = vector.floor(((axis :: vector) * theta) * 1000) / 1000
		local specialId = rotationToId[hashcheckvec]

		if specialId then
			tryrealloc(cursor, 1 + (sizeoffset or 0))				
			pushu1(cursor, specialId)
		else
			axis *= math.sin(theta / 2)
			tryrealloc(cursor, 7 + (sizeoffset or 0))
			local z = ((axis.Z + 1) * range) // 1
			local y = ((axis.Y + 1) * range) // 1
			local x = ((axis.X + 1) * range) // 1

			local buf, pos = getbuf(cursor), incrementpos(cursor, 7)
			buffer.writeu16(buf, pos, z)
			buffer.writeu16(buf, pos + 2, y)
			buffer.writeu16(buf, pos + 4, x)
			buffer.writeu8(buf, pos + 6, 0)
		end
	end

	local function DesRotation(cursor: Cursor, x: number?, y: number?, z: number?)
		local specialId = popu1(cursor)
		if specialId ~= 0 then return idToRotation[specialId] + Vector3.new(x, y, z) end

		local buf, pos = getbuf(cursor), incrementpos(cursor, -6)
		local qx = (buffer.readu16(buf, pos - 2) * invrange) - 1
		local qy = (buffer.readu16(buf, pos - 4) * invrange) - 1
		local qz = (buffer.readu16(buf, pos - 6) * invrange) - 1

		local qw = math.sqrt(1 - math.clamp((qx * qx) + (qy * qy) + (qz * qz), 0, 1))

		return CFrame.new(x, y, z, qx, qy, qz, qw)
	end

	local f32 = Squish.f32()
	
	local cframeCache = {
		[f32] = { -- optimized default
			type = "CFrame",
			name = "CFrame",
			structure = f32,
			ser = function(cursor: Cursor, cframe: CFrame)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "CFrame") assertSerializeType(cursor, cframe, "CFrame") end 

				SerRotation(cursor, cframe, 12)

				local pos = cframe.Position
				local buf, bufpos = getbuf(cursor), incrementpos(cursor, 12)
				buffer.writef32(buf, bufpos, pos.Z)
				buffer.writef32(buf, bufpos + 4, pos.Y)
				buffer.writef32(buf, bufpos + 8, pos.X)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): CFrame
				local buf, bufpos = getbuf(cursor), incrementpos(cursor, -12)
				local x, y, z = buffer.readf32(buf, bufpos - 4), buffer.readf32(buf, bufpos - 8), buffer.readf32(buf, bufpos - 12)

				return DesRotation(cursor, x, y, z)
			end
		},
		
		[false] = {
			type = "CFrame",
			name = "CFrame",
			structure = false,
			ser = if VALIDATION_ENABLED then
				function(cursor: Cursor, cframe: CFrame)
					if VALIDATION_ENABLED then beginValidationScope(cursor, "Rotation") assertSerializeType(cursor, cframe, "CFrame") end 

					SerRotation(cursor, cframe, 0)

					if VALIDATION_ENABLED then exitValidationScope(cursor) end
				end
				else SerRotation,
			des = DesRotation,
		},
	}

	-- Returns SerDes for 'CFrame' datatype, with optional parameter for which SerDes to use for the positional component.
	-- If <strong>false</strong> is provided to the serdes parameter, positional component is not saved.
	-- Defaults to f32.
	function Squish.CFrame(positionSerdes: SerDes<number> | false | nil): SerDes<CFrame>
		if positionSerdes == nil then positionSerdes = f32
		elseif positionSerdes ~= false then
			assertIsSerdes(positionSerdes, 1) 
			assertSerdesType(positionSerdes, "number")
		end
		
		if cframeCache[positionSerdes] then
			return cframeCache[positionSerdes]
		end
		
		local size, push, pop = getNumberSizePushPop(positionSerdes)
		if size == nil then size = 0 else size *= 3 end 
		
		local cframeserdes: SerDes<CFrame> = {
			type = "CFrame",
			name = "CFrame",
			structure = positionSerdes,
			ser = function(cursor: Cursor, cframe: CFrame)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "CFrame") assertSerializeType(cursor, cframe, "CFrame") end 

				local push = push 
				
				SerRotation(cursor, cframe, size)

				local pos = cframe.Position
				push(cursor, pos.Z)
				push(cursor, pos.Y)
				push(cursor, pos.X)
				
				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,
			
			des = function(cursor): CFrame
				local pop = pop
				return DesRotation(cursor, pop(cursor), pop(cursor), pop(cursor))
			end
		} :: any

		cframeCache[positionSerdes] = cframeserdes
		return cframeserdes
	end

	
	-- Wrapper for Squish.CFrame(false).
	function Squish.rotation(): SerDes<CFrame>
		return Squish.CFrame(false)
	end
end

if Color3 ~= nil then
	local color3Cache: SerDes<Color3> = {
		type = "Color3",
		name = "Color3",
		ser = function(cursor: Cursor, x: Color3)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "Color3") assertSerializeType(cursor, x, "Color3") end

			tryrealloc(cursor, 3)
			local buf, pos = getbuf(cursor), incrementpos(cursor, 3)
			buffer.writeu8(buf, pos, math.round(x.B * 255))
			buffer.writeu8(buf, pos + 1, math.round(x.G * 255))
			buffer.writeu8(buf, pos + 2, math.round(x.R * 255))

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = function(cursor: Cursor): Color3
			local buf, pos = getbuf(cursor), incrementpos(cursor, -3) 
			local r, g, b = buffer.readu8(buf, pos - 1), buffer.readu8(buf, pos - 2), buffer.readu8(buf, pos - 3)
			
			return Color3.fromRGB(r, g, b)
		end,
	}

	local color3f16Cache: SerDes<Color3> = {
		type = "Color3",
		name = "Color3f16",
		ser = function(cursor: Cursor, x: Color3)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "Color3") assertSerializeType(cursor, x, "Color3") end

			tryrealloc(cursor, 6)
			pushf2(cursor, x.B)
			pushf2(cursor, x.G)
			pushf2(cursor, x.R)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = function(cursor: Cursor): Color3
			return Color3.new(popf2(cursor), popf2(cursor), popf2(cursor))
		end,
	}

	-- Returns SerDes for 'Color3' datatype.
	function Squish.Color3(): SerDes<Color3>
		return color3Cache
	end

	function Squish.Color3f16(): SerDes<Color3>
		return color3f16Cache
	end
end

local pushcolorsequencekeypoint, popcolorsequencekeypoint
if ColorSequenceKeypoint ~= nil then
	function pushcolorsequencekeypoint(cursor, keypoint)
		local x = keypoint.Value
		
		local buf, pos = getbuf(cursor), incrementpos(cursor, 5)
		buffer.writeu8(buf, pos, math.round(x.R * 255))
		buffer.writeu8(buf, pos + 1, math.round(x.G * 255))
		buffer.writeu8(buf, pos + 2, math.round(x.B * 255))
		buffer.writeu16(buf, pos + 3, math.round(keypoint.Time * 65535))
	end

	function popcolorsequencekeypoint(cursor)
		local buf, pos = getbuf(cursor), decrementpos(cursor, 5)
		
		local color = Color3.fromRGB(buffer.readu8(buf, pos), buffer.readu8(buf, pos + 1), buffer.readu8(buf, pos + 2))
		local time = buffer.readu16(buf, pos + 3) / 65535

		return ColorSequenceKeypoint.new(time, color)
	end

	local colorSequenceKeypointCache: SerDes<ColorSequenceKeypoint> = {
		type = "ColorSequenceKeypoint",
		name = "ColorSequenceKeypoint",
		ser = function(cursor: Cursor, x: ColorSequenceKeypoint)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "ColorSequenceKeypoint") assertSerializeType(cursor, x, "ColorSequenceKeypoint") end

			tryrealloc(cursor, 5)
			pushcolorsequencekeypoint(cursor, x)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = popcolorsequencekeypoint,
	}

	-- Returns SerDes for 'ColorSequenceKeypoint' datatype.
	function Squish.ColorSequenceKeypoint(): SerDes<ColorSequenceKeypoint>
		return colorSequenceKeypointCache
	end

end

if ColorSequence ~= nil then
	local colorSequenceCache: SerDes<ColorSequence> = {
		type = "ColorSequence",
		name = "ColorSequence",
		ser = function(cursor: Cursor, sequence: ColorSequence)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "ColorSequence") assertSerializeType(cursor, sequence, "ColorSequence") end

			tryrealloc(cursor, 5 * #sequence.Keypoints)
			for _, keypoint in sequence.Keypoints do
				pushcolorsequencekeypoint(cursor, keypoint)
			end
			pushvlqrealloc(cursor, #sequence.Keypoints)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): ColorSequence
			local keypointCount = popvlq(cursor)
			local keypoints = table.create(keypointCount)
			for i = keypointCount, 1, -1 do
				keypoints[i] = popcolorsequencekeypoint(cursor)
			end
			return ColorSequence.new(keypoints)
		end,
	}

	-- Returns SerDes for 'ColorSequence' datatype.
	function Squish.ColorSequence(): SerDes<ColorSequence>
		return colorSequenceCache
	end

end

if DateTime ~= nil then
	local dateTimeCache: SerDes<DateTime> = {
		type = "DateTime",
		name = "DateTime",
		ser = function(cursor: Cursor, date: DateTime)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "DateTime") assertSerializeType(cursor, date, "DateTime") end

			tryrealloc(cursor, 6)
			pushu6(cursor, date.UnixTimestampMillis)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,
		des = function(cursor): DateTime
			return DateTime.fromUnixTimestampMillis(popu6(cursor))
		end,
	}

	-- Returns SerDes for 'DateTime' datatype.
	function Squish.DateTime(): SerDes<DateTime>
		return dateTimeCache
	end

end

if Faces ~= nil then
	local facesCache: SerDes<Faces> = {
		type = "Faces",
		name = "Faces",
		ser = function(cursor: Cursor, face: Faces)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "Faces") assertSerializeType(cursor, face, "Faces") end

			tryrealloc(cursor, 1)
			pushboolpack(cursor, face.Back, face.Bottom, face.Front, face.Left, face.Right, face.Top)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): Faces
			local back, bottom, front, left, right, top = popboolpack(cursor)
			return Faces.new(
				back and Enum.NormalId.Back :: any,
				bottom and Enum.NormalId.Bottom :: any,
				front and Enum.NormalId.Front :: any,
				left and Enum.NormalId.Left :: any,
				right and Enum.NormalId.Right :: any,
				top and Enum.NormalId.Top :: any
			)
		end,
	}

	-- Returns SerDes for 'Faces' datatype.
	function Squish.Faces(): SerDes<Faces>
		return facesCache
	end

end

if FloatCurveKey ~= nil then
	local enumserdes = enumitem(Enum.KeyInterpolationMode)
	local enumser, enumdes = enumserdes.ser, enumserdes.des 

	local floatCurveKeyCache: SerDes<FloatCurveKey> = {
		type = "FloatCurveKey",
		name = "FloatCurveKey",
		ser = function(cursor: Cursor, key: FloatCurveKey)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "FloatCurveKey") assertSerializeType(cursor, key, "FloatCurveKey") end

			enumser(cursor, key.Interpolation)
			tryrealloc(cursor, 8)
			pushf4(cursor, key.Value)
			pushf4(cursor, key.Time)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): FloatCurveKey
			return FloatCurveKey.new(popf4(cursor), popf4(cursor), enumdes(cursor) :: any)
		end,
	}

	-- Returns SerDes for 'FloatCurveKey' datatype.
	function Squish.FloatCurveKey(): SerDes<FloatCurveKey>
		return floatCurveKeyCache
	end

end

if Font ~= nil then
	local styleenumserdes = enumitem(Enum.FontStyle)
	local styleenumser, styleenumdes = styleenumserdes.ser, styleenumserdes.des 

	local weightenumserdes = enumitem(Enum.FontWeight)
	local weightenumser, weightenumdes = weightenumserdes.ser, weightenumserdes.des 

	local fontCache: SerDes<Font> = {
		type = "Font",
		name = "Font",
		ser = function(cursor: Cursor, font: Font)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "Font") assertSerializeType(cursor, font, "Font") end

			local assetId = string.match(font.Family, "^rbxassetid://(%d+)$")
			local id = 0

			if assetId then
				tryrealloc(cursor, 5) -- u4 num, u1 id
				pushu4(cursor, tonumber(assetId) :: number)
			else
				local builtinName = string.match(font.Family, "^rbxasset://fonts/families/(.+).json$")
				local towrite 

				if builtinName then
					id = 1
					towrite = builtinName
				else
					id = 2 
					towrite = font.Family
				end

				tryrealloc(cursor, #towrite + 1) -- string, u1 id
				pushstr(cursor, towrite)
			end

			pushu1(cursor, id)
			weightenumser(cursor, font.Weight)
			styleenumser(cursor, font.Style)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): Font
			local style = styleenumdes(cursor) :: Enum.FontStyle
			local weight = weightenumdes(cursor) :: Enum.FontWeight
			local fontType = popu1(cursor)
			local familyUri

			if fontType == 0 then
				familyUri = `rbxassetid://{popu4(cursor)}`
			elseif fontType == 1 then
				familyUri = `rbxasset://fonts/families/{popstr(cursor)}.json`
			else
				familyUri = popstr(cursor)
			end

			return Font.new(familyUri, weight, style)
		end,
	}

	-- Returns SerDes for 'Font' datatype.
	function Squish.Font(): SerDes<Font>
		return fontCache
	end

end

if NumberRange ~= nil then
	local numberRangeCache = setmetatable({}, kvcachemtbl)

	-- Returns SerDes for 'NumberRange' datatype, with optional parameter for which SerDes to use.
	-- Defaults to f32.
	function Squish.NumberRange(serdes: SerDes<number>?): SerDes<NumberRange>
		if serdes == nil then serdes = Squish.f32()
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if numberRangeCache[serdes] then
			return numberRangeCache[serdes]
		end

		local size, push, pop = getNumberSizePushPop(serdes)
		if size then size *= 2 end

		local numrange: SerDes<NumberRange> = {
			type = "NumberRange",
			name = "NumberRange",
			structure = serdes,
			ser = function(cursor: Cursor, range: NumberRange)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "NumberRange") assertSerializeType(cursor, range, "NumberRange") end

				local push = push
				
				if size then tryrealloc(cursor, size) end

				push(cursor, range.Max)
				push(cursor, range.Min)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): NumberRange
				local pop = pop
				return NumberRange.new(pop(cursor), pop(cursor))
			end,
		}
		numberRangeCache[serdes] = numrange
		return numrange
	end

end

local numbersequencekeypoint
if NumberSequenceKeypoint ~= nil then
	local numberSequenceKeypointCache = setmetatable({}, kvcachemtbl)
	
	local u16max = (2 ^ 16) - 1

	-- Returns SerDes for 'NumberSequenceKeypoint' datatype, with optional parameter for which SerDes to use.
	-- Defaults to f32.
	function Squish.NumberSequenceKeypoint(serdes: SerDes<number>?): SerDes<NumberSequenceKeypoint>
		if serdes == nil then serdes = Squish.f32()
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if numberSequenceKeypointCache[serdes] then
			return numberSequenceKeypointCache[serdes]
		end

		local size, push, pop = getNumberSizePushPop(serdes)
		if size then size *= 2 end

		local sequencekeypoint: SerDes<NumberSequenceKeypoint> = {
			type = "NumberSequenceKeypoint",
			name = "NumberSequenceKeypoint",
			structure = serdes,
			ser = function(cursor: Cursor, keypoint: NumberSequenceKeypoint)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "NumberSequenceKeypoint") assertSerializeType(cursor, keypoint, "NumberSequenceKeypoint") end

				local push = push

				if size then tryrealloc(cursor, size) end
				push(cursor, keypoint.Value)
				push(cursor, keypoint.Envelope)
				
				tryrealloc(cursor, 2)
				pushu2(cursor, math.round(keypoint.Time * u16max))

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): NumberSequenceKeypoint
				local pop = pop 

				local keypointTime = popu2(cursor) / u16max
				local envelope = pop(cursor)
				local value = pop(cursor)
				return NumberSequenceKeypoint.new(keypointTime, value, envelope)
			end,
		}
		numberSequenceKeypointCache[serdes] = sequencekeypoint
		return sequencekeypoint
	end
	numbersequencekeypoint = Squish.NumberSequenceKeypoint

end

if NumberSequence ~= nil then
	local numberSequenceCache = setmetatable({}, kvcachemtbl)

	-- Returns SerDes for 'NumberSequence' datatype, with optional parameter for which SerDes to use.
	-- Defaults to f32.
	function Squish.NumberSequence(serdes: SerDes<number>): SerDes<NumberSequence>
		if serdes == nil then serdes = Squish.f32()
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if numberSequenceCache[serdes] then
			return numberSequenceCache[serdes]
		end

		local pushrealloc, pop = numbersequencekeypoint(serdes).ser, numbersequencekeypoint(serdes).des

		local numsequence: SerDes<NumberSequence> = {
			type = "NumberSequence",
			name = "NumberSequence",
			structure = serdes,
			ser = function(cursor: Cursor, sequence: NumberSequence)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "NumberSequence") assertSerializeType(cursor, sequence, "NumberSequence") end

				local pushrealloc = pushrealloc
				for _, keypoint in sequence.Keypoints do
					pushrealloc(cursor, keypoint)
				end
				pushvlqrealloc(cursor, #sequence.Keypoints)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): NumberSequence
				local count = popvlq(cursor)
				local keypoints = table.create(count)
				for i = count, 1, -1 do
					keypoints[i] = pop(cursor)
				end
				return NumberSequence.new(keypoints)
			end,
		}

		numberSequenceCache[serdes] = numsequence
		return numsequence
	end

end

if OverlapParams ~= nil then
	local filtertypeserdes = enumitem(Enum.RaycastFilterType)
	
	local overlapParamsCache: SerDes<OverlapParams> = {
		type = "OverlapParams",
		name = "OverlapParams",
		ser = function(cursor: Cursor, params: OverlapParams)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "OverlapParams") assertSerializeType(cursor, params, "OverlapParams") end

			local collisiongroup = params.CollisionGroup

			tryrealloc(cursor, 3 + #collisiongroup)
			pushboolpack(cursor, params.BruteForceAllSlow, params.RespectCanCollide)
			pushu2(cursor, params.MaxParts)

			pushstr(cursor, collisiongroup)
			filtertypeserdes.ser(cursor, params.FilterType)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): OverlapParams
			local params = OverlapParams.new()

			params.FilterType = filtertypeserdes.des(cursor)
			params.CollisionGroup = popstr(cursor)

			params.MaxParts = popu2(cursor)
			params.BruteForceAllSlow, params.RespectCanCollide = popboolpack(cursor)
			return params
		end,
	}

	-- Returns SerDes for 'OverlapParams' datatype.
	function Squish.OverlapParams(): SerDes<OverlapParams>
		return overlapParamsCache
	end

end

if RaycastParams ~= nil then
	local filtertypeserdes = enumitem(Enum.RaycastFilterType)

	local raycastParamsCache: SerDes<RaycastParams> = {
		type = "RaycastParams",
		name = "RaycastParams",
		ser = function(cursor: Cursor, params: RaycastParams)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "RaycastParams") assertSerializeType(cursor, params, "RaycastParams") end

			local collisiongroup = params.CollisionGroup

			tryrealloc(cursor, 1 + #collisiongroup)
			pushboolpack(cursor, params.BruteForceAllSlow, params.RespectCanCollide, params.IgnoreWater)

			pushstr(cursor, collisiongroup)
			filtertypeserdes.ser(cursor, params.FilterType)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): RaycastParams
			local params = RaycastParams.new()

			params.FilterType = filtertypeserdes.des(cursor)
			params.CollisionGroup = popstr(cursor)

			params.BruteForceAllSlow, params.RespectCanCollide, params.IgnoreWater = popboolpack(cursor)

			return params
		end,
	}

	-- Returns SerDes for 'RaycastParams' datatype.
	function Squish.RaycastParams(): SerDes<RaycastParams>
		return raycastParamsCache
	end

end

if PathWaypoint ~= nil then
	local pathWaypointCache = setmetatable({}, kvcachemtbl)

	-- Returns SerDes for 'PathWaypoint' datatype, with optional parameter for which SerDes to use for the positional component.
	-- Defaults to f32.
	function Squish.PathWaypoint(serdes: SerDes<number>?): SerDes<PathWaypoint>
		if serdes == nil then serdes = Squish.f32()
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if pathWaypointCache[serdes] then
			return pathWaypointCache[serdes]
		end

		local size, push, pop = getNumberSizePushPop(serdes)
		if size then size *= 3 else size = 0 end

		local enumserdes = enumitem(Enum.PathWaypointAction)

		local enumser, enumdes = enumserdes.ser, enumserdes.des

		local path: SerDes<PathWaypoint> = {
			type = "PathWaypoint",
			name = "PathWaypoint",
			structure = serdes,
			ser = function(cursor: Cursor, waypoint: PathWaypoint)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "PathWaypoint") assertSerializeType(cursor, waypoint, "PathWaypoint") end

				local push = push

				tryrealloc(cursor, (#waypoint.Label) + size)
				pushstr(cursor, waypoint.Label)
				enumser(cursor, waypoint.Action)
				push(cursor, waypoint.Position.Z)
				push(cursor, waypoint.Position.Y)
				push(cursor, waypoint.Position.X)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): PathWaypoint
				local pop = pop 

				return PathWaypoint.new(
					Vector3.new(pop(cursor), pop(cursor), pop(cursor)),
					enumdes(cursor),
					popstr(cursor)
				)
			end,
		}
		pathWaypointCache[serdes] = path
		return path
	end

end

if PhysicalProperties ~= nil then
	local physicalPropertiesCache: SerDes<PhysicalProperties> = {
		type = "PhysicalProperties",
		name = "PhysicalProperties",
		ser = function(cursor: Cursor, props: PhysicalProperties)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "PhysicalProperties") assertSerializeType(cursor, props, "PhysicalProperties") end

			tryrealloc(cursor, 20)
			pushf4(cursor, props.ElasticityWeight)
			pushf4(cursor, props.FrictionWeight)
			pushf4(cursor, props.Elasticity)
			pushf4(cursor, props.Friction)
			pushf4(cursor, props.Density)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): PhysicalProperties
			return PhysicalProperties.new(popf4(cursor), popf4(cursor), popf4(cursor), popf4(cursor), popf4(cursor))
		end,
	}

	-- Returns SerDes for 'PhysicalProperties' datatype.
	function Squish.PhysicalProperties(): SerDes<PhysicalProperties>
		return physicalPropertiesCache
	end

end

if Ray ~= nil then
	local rayCache = setmetatable({}, kvcachemtbl)

	-- Returns SerDes for 'Ray' datatype, with optional parameter for which SerDes to use.
	-- Defaults to f32.
	function Squish.Ray(serdes: SerDes<number>?): SerDes<Ray>
		if serdes == nil then serdes = Squish.f32()
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if rayCache[serdes] then
			return rayCache[serdes]
		end

		local size, push, pop = getNumberSizePushPop(serdes)
		if size then size *= 6 end

		local raycached: SerDes<Ray> = {
			type = "Ray",
			name = "Ray",
			structure = serdes,
			ser = function(cursor: Cursor, ray: Ray)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "Ray") assertSerializeType(cursor, ray, "Ray") end

				local push = push 

				if size then tryrealloc(cursor, size) end

				push(cursor, ray.Direction.Z)
				push(cursor, ray.Direction.Y)
				push(cursor, ray.Direction.X)
				push(cursor, ray.Origin.Z)
				push(cursor, ray.Origin.Y)
				push(cursor, ray.Origin.X)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): Ray
				local pop = pop 

				return Ray.new(Vector3.new(pop(cursor), pop(cursor), pop(cursor)), Vector3.new(pop(cursor), pop(cursor), pop(cursor)))
			end,
		}
		rayCache[serdes] = raycached
		return raycached
	end

end

if RaycastParams ~= nil then
	local raycastResultCache = setmetatable({}, kvcachemtbl)

	-- Returns SerDes for 'RaycastResult' datatype, with optional parameter for which SerDes to use for the positional component.
	-- Defaults to f32.
	function Squish.RaycastResult(serdes: SerDes<number>?): RaycastResultSerDes
		if serdes == nil then serdes = Squish.f32()
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if raycastResultCache[serdes] then
			return raycastResultCache[serdes]
		end

		local size, push, pop = getNumberSizePushPop(serdes)
		if size then size *= 6 else size = 0 end

		local ins: SerDes<BasePart> = Squish.Instance("BasePart")
		local material = Squish.EnumItem(Enum.Material)

		local insser, insdes = ins.ser, ins.des
		local matser, matdes = material.ser, material.des

		local raycastresult: RaycastResultSerDes = {
			type = "RaycastResult",
			name = "RaycastResult",
			structure = serdes,
			ser = function(cursor: Cursor, result: RaycastResult)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "RaycastResult") assertSerializeType(cursor, result, "RaycastResult") end

				local push = push

				insser(cursor, result.Instance :: BasePart)

				tryrealloc(cursor, 4 + size)
				pushf4(cursor, result.Distance)

				push(cursor, result.Position.Z)
				push(cursor, result.Position.Y)
				push(cursor, result.Position.X)

				push(cursor, result.Normal.Z)
				push(cursor, result.Normal.Y)
				push(cursor, result.Normal.X)

				matser(cursor, result.Material)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): SquishRaycastResult
				local pop = pop 

				return {
					Material = matdes(cursor) :: any,
					Normal = Vector3.new(pop(cursor), pop(cursor), pop(cursor)),
					Position = Vector3.new(pop(cursor), pop(cursor), pop(cursor)),
					Distance = popf4(cursor),
					Instance = insdes(cursor),
				}
			end,
		}

		raycastResultCache[serdes] = raycastresult
		return raycastresult
	end

end

if Rect ~= nil then
	local rectCache = setmetatable({}, kvcachemtbl)

	-- Returns SerDes for 'Rect' datatype, with optional parameter for which SerDes to use.
	-- Defaults to f32.
	function Squish.Rect(serdes: SerDes<number>?): SerDes<Rect>
		if serdes == nil then serdes = Squish.f32()
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if rectCache[serdes] then
			return rectCache[serdes]
		end

		local size, push, pop = getNumberSizePushPop(serdes)
		if size then size *= 4 end

		local rectserdes: SerDes<Rect> = {
			type = "Rect",
			name = "Rect",
			structure = serdes,
			ser = function(cursor: Cursor, rect: Rect)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "Rect") assertSerializeType(cursor, rect, "Rect") end

				local push = push 

				if size then tryrealloc(cursor, size) end

				push(cursor, rect.Max.Y)
				push(cursor, rect.Max.X)
				push(cursor, rect.Min.Y)
				push(cursor, rect.Min.X)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): Rect
				local pop = pop 

				return Rect.new(pop(cursor), pop(cursor), pop(cursor), pop(cursor))
			end,
		}
		rectCache[serdes] = rectserdes
		return rectserdes
	end

end

if Region3 ~= nil then
	local region3Cache = setmetatable({}, kvcachemtbl)

	-- Returns SerDes for 'Region3' datatype, with optional parameter for which SerDes to use.
	-- Defaults to f32.
	function Squish.Region3(serdes: SerDes<number>?): SerDes<Region3>
		if serdes == nil then serdes = Squish.f32()
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if region3Cache[serdes] then
			return region3Cache[serdes]
		end

		local size, push, pop = getNumberSizePushPop(serdes)
		if size then size *= 6 end

		local reg: SerDes<Region3> = {
			type = "Region3",
			name = "Region3",
			structure = serdes,
			ser = function(cursor: Cursor, region: Region3)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "Region3") assertSerializeType(cursor, region, "Region3") end

				local push = push 

				if size then tryrealloc(cursor, size) end

				local size = region.Size
				push(cursor, size.Z)
				push(cursor, size.Y)
				push(cursor, size.X)
				local pos = region.CFrame.Position
				push(cursor, pos.Z)
				push(cursor, pos.Y)
				push(cursor, pos.X)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): Region3
				local pop = pop 

				local position = Vector3.new(pop(cursor), pop(cursor), pop(cursor))
				local size = 0.5 * Vector3.new(pop(cursor), pop(cursor), pop(cursor))
				return Region3.new(position - size, position + size)
			end,
		}
		region3Cache[serdes] = reg
		return reg
	end

end

if Region3int16 ~= nil then
	local region3int16Cache: SerDes<Region3int16> = {
		type = "Region3int16",
		name = "Region3int16",
		ser = function(cursor: Cursor, region: Region3int16)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "Region3int16") assertSerializeType(cursor, region, "Region3int16") end

			tryrealloc(cursor, 12)
			local max = region.Max
			pushi2(cursor, max.Z)
			pushi2(cursor, max.Y)
			pushi2(cursor, max.X)
			local min = region.Min
			pushi2(cursor, min.Z)
			pushi2(cursor, min.Y)
			pushi2(cursor, min.X)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): Region3int16
			local min = Vector3int16.new(popi2(cursor), popi2(cursor), popi2(cursor))
			local max = Vector3int16.new(popi2(cursor), popi2(cursor), popi2(cursor))
			return Region3int16.new(min, max)
		end,
	}

	-- Returns SerDes for 'Region3int16' datatype.
	function Squish.Region3int16(): SerDes<Region3int16>
		return region3int16Cache
	end

end

if RotationCurveKey ~= nil then
	local rotationCurveKeyCache = setmetatable({}, kvcachemtbl)
	local interpolationmodeserdes = enumitem(Enum.KeyInterpolationMode)

	-- Returns SerDes for 'RotationCurveKey' datatype, with optional parameter for which SerDes to use.
	-- Defaults to f32.
	function Squish.RotationCurveKey(serdes: SerDes<number>): SerDes<RotationCurveKey>
		if serdes == nil then serdes = Squish.f32()
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if rotationCurveKeyCache[serdes] then
			return rotationCurveKeyCache[serdes]
		end
		
		local cfserdes = Squish.CFrame(serdes)
		local pushrealloc, pop = cfserdes.ser, cfserdes.des

		local rot: SerDes<RotationCurveKey> = {
			type = "RotationCurveKey",
			name = "RotationCurveKey",
			structure = serdes,
			ser = function(cursor: Cursor, key: RotationCurveKey)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "RotationCurveKey") assertSerializeType(cursor, key, "RotationCurveKey") end

				interpolationmodeserdes.ser(cursor, key.Interpolation)
				pushrealloc(cursor, key.Value)
				tryrealloc(cursor, 4)
				pushf4(cursor, key.Time)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): RotationCurveKey
				return RotationCurveKey.new(
					popf4(cursor),
					pop(cursor),
					interpolationmodeserdes.des(cursor)
				)
			end,
		}
		rotationCurveKeyCache[serdes] = rot
		return rot
	end

end

if TweenInfo ~= nil then
	local easingdirectionserdes = enumitem(Enum.EasingDirection)
	local easingstyleserdes = enumitem(Enum.EasingStyle)
	
	local tweenInfoCache: SerDes<TweenInfo> = {
		type = "TweenInfo",
		name = "TweenInfo",
		ser = function(cursor: Cursor, info: TweenInfo)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "TweenInfo") assertSerializeType(cursor, info, "TweenInfo") end

			tryrealloc(cursor, 9)
			pushf4(cursor, info.DelayTime)
			pushf4(cursor, info.Time)
			pushbool(cursor, info.Reverses)
			pushvlqrealloc(cursor, info.RepeatCount)
			easingdirectionserdes.ser(cursor, info.EasingDirection)
			easingstyleserdes.ser(cursor, info.EasingStyle)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): TweenInfo
			local easing = easingstyleserdes.des(cursor)
			local direction = easingdirectionserdes.des(cursor)
			local repeats = popvlq(cursor)
			local reverses = popbool(cursor)
			local duration = popf4(cursor)
			local delayTime = popf4(cursor)
			return TweenInfo.new(duration, easing, direction, repeats, reverses, delayTime)
		end,
	}

	-- Returns SerDes for 'TweenInfo' datatype.
	function Squish.TweenInfo(): SerDes<TweenInfo>
		return tweenInfoCache
	end

end

if UDim ~= nil then
	local udimCache = setmetatable({}, kvcachemtbl)

	-- Returns SerDes for 'UDim' datatype, with optional parameter for which SerDes to use.
	-- Defaults to f32.
	function Squish.UDim(serdes: SerDes<number>?): SerDes<UDim>
		if serdes == nil then serdes = Squish.f32()
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if udimCache[serdes] then
			return udimCache[serdes]
		end

		local size, push, pop = getNumberSizePushPop(serdes)
		if size then size *= 2 end

		local udim: SerDes<UDim> = {
			type = "UDim",
			name = "UDim",
			structure = serdes,
			ser = function(cursor: Cursor, u: UDim)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "UDim") assertSerializeType(cursor, u, "UDim") end

				local push = push 

				if size then tryrealloc(cursor, size) end

				push(cursor, u.Offset)
				push(cursor, u.Scale)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): UDim
				local pop = pop 

				return UDim.new(pop(cursor), pop(cursor))
			end,
		}

		udimCache[serdes] = udim
		return udim
	end

end

if UDim2 ~= nil then
	local udim2Cache = setmetatable({}, kvcachemtbl)

	-- Returns SerDes for 'UDim2' datatype, with optional parameter for which SerDes to use.
	-- Defaults to f32.
	function Squish.UDim2(serdes: SerDes<number>?): SerDes<UDim2>
		if serdes == nil then serdes = Squish.f32()
		else 
			assertIsSerdes(serdes, 1) 
			assertSerdesType(serdes, "number")	
		end

		if udim2Cache[serdes] then
			return udim2Cache[serdes]
		end

		local size, push, pop = getNumberSizePushPop(serdes)
		if size then size *= 4 end

		local udim2: SerDes<UDim2> = {
			type = "UDim2",
			name = "UDim2",
			structure = serdes,
			ser = function(cursor: Cursor, u: UDim2)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "UDim2") assertSerializeType(cursor, u, "UDim2") end

				local push = push 

				if size then tryrealloc(cursor, size) end
				
				push(cursor, u.Y.Offset)
				push(cursor, u.Y.Scale)
				push(cursor, u.X.Offset)
				push(cursor, u.X.Scale)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor): UDim2
				local pop = pop 

				return UDim2.new(pop(cursor), pop(cursor), pop(cursor), pop(cursor))
			end,
		}

		udim2Cache[serdes] = udim2
		return udim2
	end

end

if Vector2int16 ~= nil then
	local vector2int16Cache: SerDes<Vector2int16> = {
		type = "Vector2int16",
		name = "Vector2int16",
		ser = function(cursor: Cursor, v: Vector2int16)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "Vector2int16") assertSerializeType(cursor, v, "Vector2int16") end

			tryrealloc(cursor, 4)
			pushi2(cursor, v.Y)
			pushi2(cursor, v.X)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): Vector2int16
			return Vector2int16.new(popi2(cursor), popi2(cursor))
		end,
	}

	-- Returns SerDes for 'Vector2int16' datatype.
	function Squish.Vector2int16(): SerDes<Vector2int16>
		return vector2int16Cache
	end

end

if Vector3int16 ~= nil then
	local vector3int16Cache: SerDes<Vector3int16> = {
		type = "Vector3int16",
		name = "Vector3int16",
		ser = function(cursor: Cursor, v: Vector3int16)
			if VALIDATION_ENABLED then beginValidationScope(cursor, "Vector3int16") assertSerializeType(cursor, v, "Vector3int16") end

			tryrealloc(cursor, 6)
			pushi2(cursor, v.Z)
			pushi2(cursor, v.Y)
			pushi2(cursor, v.X)

			if VALIDATION_ENABLED then exitValidationScope(cursor) end
		end,

		des = function(cursor): Vector3int16
			return Vector3int16.new(popi2(cursor), popi2(cursor), popi2(cursor))
		end,
	}

	-- Returns SerDes for 'Vector3int16' datatype.
	function Squish.Vector3int16(): SerDes<Vector3int16>
		return vector3int16Cache
	end

end

if Instance ~= nil then
	--[[gen:
	
	local t = {"type RobloxClasses = {\n\t"}
	local output = {}

	for _, c in game.ReflectionService:GetClasses() do table.insert(t, `{c.Name}: {c.Name},`) end
	for i = 1, #t, 10 do 
		output[1 + (i // 10)] = `{t[i] or ""} {t[i + 1] or ""} {t[i + 2] or ""} {t[i + 3] or ""} {t[i + 4] or ""} {t[i + 5] or ""} {t[i + 6] or ""} {t[i + 7] or ""} {t[i + 8] or ""} {t[i + 9] or ""}`
	end

	print(table.concat(output, "\n\t") .. "\n}")
	
	]]
	
	type RobloxClasses = {
	Accessory: Accessory, AccessoryDescription: AccessoryDescription, Accoutrement: Accoutrement, Actor: Actor, AdGui: AdGui, AdPortal: AdPortal, AdService: AdService, AdvancedDragger: AdvancedDragger, AirController: AirController,
	AlignOrientation: AlignOrientation, AlignPosition: AlignPosition, AnalyticsService: AnalyticsService, AngularVelocity: AngularVelocity, Animation: Animation, AnimationClip: AnimationClip, AnimationClipProvider: AnimationClipProvider, AnimationConstraint: AnimationConstraint, AnimationController: AnimationController, AnimationFromVideoCreatorService: AnimationFromVideoCreatorService,
	AnimationGraphDefinition: AnimationGraphDefinition, AnimationNode: AnimationNode, AnimationNodeDefinition: AnimationNodeDefinition, AnimationRigData: AnimationRigData, AnimationTrack: AnimationTrack, Animator: Animator, Annotation: Annotation, ArcHandles: ArcHandles, AssetDeliveryProxy: AssetDeliveryProxy, AssetPatchSettings: AssetPatchSettings,
	AssetService: AssetService, Atmosphere: Atmosphere, AtmosphereSensor: AtmosphereSensor, Attachment: Attachment, AudioAnalyzer: AudioAnalyzer, AudioChannelMixer: AudioChannelMixer, AudioChannelSplitter: AudioChannelSplitter, AudioChorus: AudioChorus, AudioCompressor: AudioCompressor, AudioDeviceInput: AudioDeviceInput,
	AudioDeviceOutput: AudioDeviceOutput, AudioDistortion: AudioDistortion, AudioEcho: AudioEcho, AudioEmitter: AudioEmitter, AudioEqualizer: AudioEqualizer, AudioFader: AudioFader, AudioFilter: AudioFilter, AudioFlanger: AudioFlanger, AudioGate: AudioGate, AudioLimiter: AudioLimiter,
	AudioListener: AudioListener, AudioPages: AudioPages, AudioPitchShifter: AudioPitchShifter, AudioPlayer: AudioPlayer, AudioRecorder: AudioRecorder, AudioReverb: AudioReverb, AudioSearchParams: AudioSearchParams, AudioSpeechToText: AudioSpeechToText, AudioTextToSpeech: AudioTextToSpeech, AudioTremolo: AudioTremolo,
	AuroraScriptService: AuroraScriptService, AvatarCreationService: AvatarCreationService, AvatarEditorService: AvatarEditorService, Backpack: Backpack, BackpackItem: BackpackItem, BadgeService: BadgeService, BallSocketConstraint: BallSocketConstraint, BanHistoryPages: BanHistoryPages, BaseCoreGuiConfiguration: BaseCoreGuiConfiguration, BasePart: BasePart,
	BasePlayerGui: BasePlayerGui, BaseRemoteEvent: BaseRemoteEvent, BaseScript: BaseScript, BaseWrap: BaseWrap, Beam: Beam, BevelMesh: BevelMesh, BillboardGui: BillboardGui, BinaryStringValue: BinaryStringValue, BindableEvent: BindableEvent, BindableFunction: BindableFunction,
	BlockMesh: BlockMesh, BloomEffect: BloomEffect, BlurEffect: BlurEffect, BodyAngularVelocity: BodyAngularVelocity, BodyColors: BodyColors, BodyForce: BodyForce, BodyGyro: BodyGyro, BodyMover: BodyMover, BodyPartDescription: BodyPartDescription, BodyPosition: BodyPosition,
	BodyThrust: BodyThrust, BodyVelocity: BodyVelocity, Bone: Bone, BoolValue: BoolValue, BoxHandleAdornment: BoxHandleAdornment, BrickColorValue: BrickColorValue, BrowserService: BrowserService, BubbleChatConfiguration: BubbleChatConfiguration, BubbleChatMessageProperties: BubbleChatMessageProperties, BuoyancySensor: BuoyancySensor,
	CFrameValue: CFrameValue, CacheableContentProvider: CacheableContentProvider, Camera: Camera, CanvasGroup: CanvasGroup, Capture: Capture, CaptureService: CaptureService, CapturesPages: CapturesPages, CapturesViewConfiguration: CapturesViewConfiguration, CatalogPages: CatalogPages, ChangeHistoryService: ChangeHistoryService,
	ChannelTabsConfiguration: ChannelTabsConfiguration, CharacterAppearance: CharacterAppearance, CharacterMesh: CharacterMesh, Chat: Chat, ChatInputBarConfiguration: ChatInputBarConfiguration, ChatWindowConfiguration: ChatWindowConfiguration, ChatWindowMessageProperties: ChatWindowMessageProperties, ChorusSoundEffect: ChorusSoundEffect, ClickDetector: ClickDetector, ClientReplicator: ClientReplicator,
	ClimbController: ClimbController, Clothing: Clothing, Clouds: Clouds, ClusterPacketCache: ClusterPacketCache, CollectionService: CollectionService, Color3Value: Color3Value, ColorCorrectionEffect: ColorCorrectionEffect, ColorGradingEffect: ColorGradingEffect, CommerceService: CommerceService, CompositeValueCurve: CompositeValueCurve,
	CompressorSoundEffect: CompressorSoundEffect, ConeHandleAdornment: ConeHandleAdornment, ConfigService: ConfigService, ConfigSnapshot: ConfigSnapshot, Configuration: Configuration, ConfigureServerService: ConfigureServerService, Constraint: Constraint, ContentProvider: ContentProvider, ContextActionService: ContextActionService, Controller: Controller,
	ControllerBase: ControllerBase, ControllerManager: ControllerManager, ControllerPartSensor: ControllerPartSensor, ControllerSensor: ControllerSensor, ControllerService: ControllerService, CookiesService: CookiesService, CoreGuiConfiguration: CoreGuiConfiguration, CoreScriptDebuggingManagerHelper: CoreScriptDebuggingManagerHelper, CornerWedgePart: CornerWedgePart, CreatorStoreService: CreatorStoreService,
	CurveAnimation: CurveAnimation, CustomEvent: CustomEvent, CustomEventReceiver: CustomEventReceiver, CylinderHandleAdornment: CylinderHandleAdornment, CylinderMesh: CylinderMesh, CylindricalConstraint: CylindricalConstraint, DataModel: DataModel, DataModelMesh: DataModelMesh, DataModelSession: DataModelSession, DataStore: DataStore,
	DataStoreGetOptions: DataStoreGetOptions, DataStoreIncrementOptions: DataStoreIncrementOptions, DataStoreInfo: DataStoreInfo, DataStoreKey: DataStoreKey, DataStoreKeyInfo: DataStoreKeyInfo, DataStoreKeyPages: DataStoreKeyPages, DataStoreListingPages: DataStoreListingPages, DataStoreObjectVersionInfo: DataStoreObjectVersionInfo, DataStoreOptions: DataStoreOptions, DataStorePages: DataStorePages,
	DataStoreService: DataStoreService, DataStoreSetOptions: DataStoreSetOptions, DataStoreVersionPages: DataStoreVersionPages, Debris: Debris, Decal: Decal, DepthOfFieldEffect: DepthOfFieldEffect, Dialog: Dialog, DialogChoice: DialogChoice, DigitsRigDescription: DigitsRigDescription, DistortionSoundEffect: DistortionSoundEffect,
	DoubleConstrainedValue: DoubleConstrainedValue, DragDetector: DragDetector, Dragger: Dragger, DynamicRotate: DynamicRotate, EchoSoundEffect: EchoSoundEffect, EditableImage: EditableImage, EditableMesh: EditableMesh, EncodingService: EncodingService, EqualizerSoundEffect: EqualizerSoundEffect, EulerRotationCurve: EulerRotationCurve,
	ExperienceInviteOptions: ExperienceInviteOptions, ExperienceNotificationService: ExperienceNotificationService, Explosion: Explosion, FaceControls: FaceControls, FaceInstance: FaceInstance, Feature: Feature, FeatureRestrictionManager: FeatureRestrictionManager, File: File, FileMesh: FileMesh, Fire: Fire,
	Flag: Flag, FlagStand: FlagStand, FlagStandService: FlagStandService, FlangeSoundEffect: FlangeSoundEffect, FloatCurve: FloatCurve, FloorWire: FloorWire, FluidForceSensor: FluidForceSensor, Folder: Folder, ForceField: ForceField, FormFactorPart: FormFactorPart,
	Frame: Frame, FriendPages: FriendPages, FriendService: FriendService, FunctionalTest: FunctionalTest, GamePassService: GamePassService, GamepadService: GamepadService, GeneratedFolder: GeneratedFolder, GenerationService: GenerationService, GenericChallengeService: GenericChallengeService, Geometry: Geometry,
	GeometryService: GeometryService, GetTextBoundsParams: GetTextBoundsParams, GlobalDataStore: GlobalDataStore, Glue: Glue, GroundController: GroundController, GroupService: GroupService, GuiBase: GuiBase, GuiBase2d: GuiBase2d, GuiBase3d: GuiBase3d, GuiButton: GuiButton,
	GuiLabel: GuiLabel, GuiMain: GuiMain, GuiObject: GuiObject, GuiService: GuiService, GuidRegistryService: GuidRegistryService, HSRDataContentProvider: HSRDataContentProvider, HandleAdornment: HandleAdornment, Handles: Handles, HandlesBase: HandlesBase, HapticEffect: HapticEffect,
	HapticService: HapticService, Hat: Hat, HeapProfilerService: HeapProfilerService, HeightmapImporterService: HeightmapImporterService, HiddenSurfaceRemovalAsset: HiddenSurfaceRemovalAsset, Highlight: Highlight, HingeConstraint: HingeConstraint, Hint: Hint, Hole: Hole, Hopper: Hopper,
	HopperBin: HopperBin, HttpRbxApiService: HttpRbxApiService, HttpService: HttpService, Humanoid: Humanoid, HumanoidController: HumanoidController, HumanoidDescription: HumanoidDescription, HumanoidRigDescription: HumanoidRigDescription, IKControl: IKControl, ILegacyStudioBridge: ILegacyStudioBridge, ImageButton: ImageButton,
	ImageHandleAdornment: ImageHandleAdornment, ImageLabel: ImageLabel, IncrementalPatchBuilder: IncrementalPatchBuilder, InputAction: InputAction, InputBinding: InputBinding, InputContext: InputContext, InputObject: InputObject, InsertService: InsertService, Instance: Instance, InstanceAdornment: InstanceAdornment,
	InstanceExtensionsService: InstanceExtensionsService, IntConstrainedValue: IntConstrainedValue, IntValue: IntValue, IntersectOperation: IntersectOperation, InventoryPages: InventoryPages, JointInstance: JointInstance, JointsService: JointsService, KeyboardService: KeyboardService, Keyframe: Keyframe, KeyframeMarker: KeyframeMarker,
	KeyframeSequence: KeyframeSequence, KeyframeSequenceProvider: KeyframeSequenceProvider, LayerCollector: LayerCollector, Light: Light, Lighting: Lighting, LineForce: LineForce, LineHandleAdornment: LineHandleAdornment, LinearVelocity: LinearVelocity, LocalScript: LocalScript, LocalizationService: LocalizationService,
	LocalizationTable: LocalizationTable, LogService: LogService, LoginService: LoginService, LuaSourceContainer: LuaSourceContainer, LuaWebService: LuaWebService, MLService: MLService, MLSession: MLSession, MakeupDescription: MakeupDescription, ManualGlue: ManualGlue, ManualSurfaceJointInstance: ManualSurfaceJointInstance,
	ManualWeld: ManualWeld, MarkerCurve: MarkerCurve, MarketplaceService: MarketplaceService, MatchmakingService: MatchmakingService, MaterialService: MaterialService, MaterialVariant: MaterialVariant, MemStorageConnection: MemStorageConnection, MemStorageService: MemStorageService, MemoryStoreHashMap: MemoryStoreHashMap, MemoryStoreHashMapPages: MemoryStoreHashMapPages,
	MemoryStoreQueue: MemoryStoreQueue, MemoryStoreService: MemoryStoreService, MemoryStoreSortedMap: MemoryStoreSortedMap, MeshContentProvider: MeshContentProvider, MeshPart: MeshPart, Message: Message, MessagingService: MessagingService, MicroProfilerService: MicroProfilerService, Model: Model, ModerationService: ModerationService,
	ModuleScript: ModuleScript, Motor: Motor, Motor6D: Motor6D, MotorFeature: MotorFeature, Mouse: Mouse, MouseService: MouseService, NegateOperation: NegateOperation, NetworkMarker: NetworkMarker, NetworkPeer: NetworkPeer, NetworkReplicator: NetworkReplicator,
	NoCollisionConstraint: NoCollisionConstraint, NotificationService: NotificationService, NumberPose: NumberPose, NumberValue: NumberValue, Object: Object, ObjectValue: ObjectValue, OpenCloudApiV1: OpenCloudApiV1, OpenCloudService: OpenCloudService, OperationGraph: OperationGraph, OrderedDataStore: OrderedDataStore,
	OutfitPages: OutfitPages, PVAdornment: PVAdornment, PVInstance: PVInstance, PackageLink: PackageLink, PackageService: PackageService, Packages: Packages, Pages: Pages, Pants: Pants, Part: Part, PartAdornment: PartAdornment,
	PartOperation: PartOperation, PartOperationAsset: PartOperationAsset, ParticleEmitter: ParticleEmitter, PatchBundlerFileWatch: PatchBundlerFileWatch, PatchMapping: PatchMapping, Path: Path, Path2D: Path2D, Path3D: Path3D, PathfindingLink: PathfindingLink, PathfindingModifier: PathfindingModifier,
	PathfindingService: PathfindingService, PermissionsService: PermissionsService, PhysicsService: PhysicsService, PitchShiftSoundEffect: PitchShiftSoundEffect, PlacesService: PlacesService, Plane: Plane, PlaneConstraint: PlaneConstraint, Platform: Platform, PlayerData: PlayerData, PlayerDataRecord: PlayerDataRecord,
	PlayerDataRecordConfig: PlayerDataRecordConfig, PlayerDataService: PlayerDataService, PlayerGui: PlayerGui, PlayerListConfiguration: PlayerListConfiguration, PlayerMouse: PlayerMouse, PlayerScripts: PlayerScripts, PlayerViewService: PlayerViewService, Players: Players, PluginManagementService: PluginManagementService, PointLight: PointLight,
	PointsService: PointsService, PolicyService: PolicyService, PopLatencyService: PopLatencyService, Pose: Pose, PoseBase: PoseBase, PostEffect: PostEffect, Preloaded: Preloaded, PrismaticConstraint: PrismaticConstraint, ProceduralModel: ProceduralModel, ProcessInstancePhysicsService: ProcessInstancePhysicsService,
	ProximityPrompt: ProximityPrompt, ProximityPromptService: ProximityPromptService, PublishService: PublishService, PyramidHandleAdornment: PyramidHandleAdornment, RayValue: RayValue, RecommendationPages: RecommendationPages, RecommendationService: RecommendationService, ReflectionMetadata: ReflectionMetadata, ReflectionMetadataCallbacks: ReflectionMetadataCallbacks, ReflectionMetadataClass: ReflectionMetadataClass,
	ReflectionMetadataClasses: ReflectionMetadataClasses, ReflectionMetadataEnum: ReflectionMetadataEnum, ReflectionMetadataEnumItem: ReflectionMetadataEnumItem, ReflectionMetadataEnums: ReflectionMetadataEnums, ReflectionMetadataEvents: ReflectionMetadataEvents, ReflectionMetadataFunctions: ReflectionMetadataFunctions, ReflectionMetadataItem: ReflectionMetadataItem, ReflectionMetadataMember: ReflectionMetadataMember, ReflectionMetadataProperties: ReflectionMetadataProperties, ReflectionMetadataYieldFunctions: ReflectionMetadataYieldFunctions,
	ReflectionService: ReflectionService, RemoteCommandService: RemoteCommandService, RemoteDebuggerServer: RemoteDebuggerServer, RemoteEvent: RemoteEvent, RemoteFunction: RemoteFunction, RenderingTest: RenderingTest, ReplicatedFirst: ReplicatedFirst, ReplicatedStorage: ReplicatedStorage, ReverbSoundEffect: ReverbSoundEffect, RigidConstraint: RigidConstraint,
	RocketPropulsion: RocketPropulsion, RodConstraint: RodConstraint, RopeConstraint: RopeConstraint, Rotate: Rotate, RotateP: RotateP, RotateV: RotateV, RotationCurve: RotationCurve, RunService: RunService, RunningAverageItemDouble: RunningAverageItemDouble, RunningAverageItemInt: RunningAverageItemInt,
	RunningAverageTimeIntervalItem: RunningAverageTimeIntervalItem, SceneAnalysisService: SceneAnalysisService, ScreenGui: ScreenGui, ScreenshotCapture: ScreenshotCapture, ScreenshotHud: ScreenshotHud, Script: Script, ScriptBuilder: ScriptBuilder, ScriptContext: ScriptContext, ScriptProfilerService: ScriptProfilerService, ScriptService: ScriptService,
	ScrollingFrame: ScrollingFrame, Seat: Seat, Selection: Selection, SelectionBox: SelectionBox, SelectionHighlightManager: SelectionHighlightManager, SelectionLasso: SelectionLasso, SelectionPartLasso: SelectionPartLasso, SelectionPointLasso: SelectionPointLasso, SelectionSphere: SelectionSphere, SelfViewConfiguration: SelfViewConfiguration,
	SensorBase: SensorBase, ServerReplicator: ServerReplicator, ServerScriptService: ServerScriptService, ServerStorage: ServerStorage, ServiceProvider: ServiceProvider, ServiceVisibilityService: ServiceVisibilityService, SessionCheckService: SessionCheckService, SharedTableRegistry: SharedTableRegistry, Shirt: Shirt, ShirtGraphic: ShirtGraphic,
	SkateboardController: SkateboardController, SkateboardPlatform: SkateboardPlatform, Skin: Skin, Sky: Sky, SlidingBallConstraint: SlidingBallConstraint, SlimContentProvider: SlimContentProvider, Smoke: Smoke, SmoothVoxelsUpgraderService: SmoothVoxelsUpgraderService, Snap: Snap, SocialService: SocialService,
	SolidModelContentProvider: SolidModelContentProvider, Sound: Sound, SoundEffect: SoundEffect, SoundGroup: SoundGroup, SoundService: SoundService, Sparkles: Sparkles, SpawnLocation: SpawnLocation, SpawnerService: SpawnerService, SpecialMesh: SpecialMesh, SphereHandleAdornment: SphereHandleAdornment,
	SpotLight: SpotLight, SpringConstraint: SpringConstraint, StandardPages: StandardPages, StarterCharacterScripts: StarterCharacterScripts, StarterGear: StarterGear, StarterGui: StarterGui, StarterPack: StarterPack, StarterPlayer: StarterPlayer, StarterPlayerScripts: StarterPlayerScripts, StartupMessageService: StartupMessageService,
	Stats: Stats, StatsItem: StatsItem, Status: Status, StopWatchReporter: StopWatchReporter, StringValue: StringValue, StudioTestService: StudioTestService, StudioTheme: StudioTheme, StyleBase: StyleBase, StyleDerive: StyleDerive, StyleLink: StyleLink,
	StyleQuery: StyleQuery, StyleRule: StyleRule, StyleSheet: StyleSheet, StylingService: StylingService, SunRaysEffect: SunRaysEffect, SurfaceAppearance: SurfaceAppearance, SurfaceGui: SurfaceGui, SurfaceGuiBase: SurfaceGuiBase, SurfaceLight: SurfaceLight, SurfaceSelection: SurfaceSelection,
	SwimController: SwimController, SyncScriptBuilder: SyncScriptBuilder, Team: Team, Teams: Teams, TeleportAsyncResult: TeleportAsyncResult, TeleportOptions: TeleportOptions, TeleportService: TeleportService, Terrain: Terrain, TerrainDetail: TerrainDetail, TerrainIterateOperation: TerrainIterateOperation,
	TerrainModifyOperation: TerrainModifyOperation, TerrainReadOperation: TerrainReadOperation, TerrainRegion: TerrainRegion, TerrainWriteOperation: TerrainWriteOperation, TestCase: TestCase, TestService: TestService, TextBox: TextBox, TextBoxService: TextBoxService, TextButton: TextButton, TextChannel: TextChannel,
	TextChannelWindow: TextChannelWindow, TextChatCommand: TextChatCommand, TextChatConfigurations: TextChatConfigurations, TextChatMessage: TextChatMessage, TextChatMessageProperties: TextChatMessageProperties, TextChatService: TextChatService, TextFilterResult: TextFilterResult, TextFilterTranslatedResult: TextFilterTranslatedResult, TextGenerator: TextGenerator, TextLabel: TextLabel,
	TextService: TextService, TextSource: TextSource, Texture: Texture, TimerService: TimerService, Tool: Tool, Torque: Torque, TorsionSpringConstraint: TorsionSpringConstraint, TotalCountTimeIntervalItem: TotalCountTimeIntervalItem, TouchInputService: TouchInputService, TouchTransmitter: TouchTransmitter,
	TraceRouteService: TraceRouteService, Trail: Trail, Translator: Translator, TremoloSoundEffect: TremoloSoundEffect, TriangleMeshPart: TriangleMeshPart, TrussPart: TrussPart, Tween: Tween, TweenBase: TweenBase, TweenService: TweenService, UGCValidationService: UGCValidationService,
	UIAspectRatioConstraint: UIAspectRatioConstraint, UIBase: UIBase, UIComponent: UIComponent, UIConstraint: UIConstraint, UICorner: UICorner, UIDragDetector: UIDragDetector, UIDragDetectorService: UIDragDetectorService, UIFlexItem: UIFlexItem, UIGradient: UIGradient, UIGridLayout: UIGridLayout,
	UIGridStyleLayout: UIGridStyleLayout, UILayout: UILayout, UIListLayout: UIListLayout, UIPadding: UIPadding, UIPageLayout: UIPageLayout, UIScale: UIScale, UIShadow: UIShadow, UISizeConstraint: UISizeConstraint, UIStroke: UIStroke, UITableLayout: UITableLayout,
	UITextSizeConstraint: UITextSizeConstraint, UnionOperation: UnionOperation, UniqueIdLookupService: UniqueIdLookupService, UniversalConstraint: UniversalConstraint, UnreliableRemoteEvent: UnreliableRemoteEvent, UserInputService: UserInputService, UserService: UserService, VRService: VRService, VRStatusService: VRStatusService, ValueBase: ValueBase,
	ValueCurve: ValueCurve, Vector3Curve: Vector3Curve, Vector3Value: Vector3Value, VectorForce: VectorForce, VehicleController: VehicleController, VehicleSeat: VehicleSeat, VelocityMotor: VelocityMotor, VideoCapture: VideoCapture, VideoCaptureService: VideoCaptureService, VideoDisplay: VideoDisplay,
	VideoFrame: VideoFrame, VideoPlayer: VideoPlayer, VideoSampler: VideoSampler, VideoScreenCaptureService: VideoScreenCaptureService, VideoService: VideoService, ViewportFrame: ViewportFrame, VirtualInput: VirtualInput, VirtualInputManager: VirtualInputManager, VirtualUser: VirtualUser, VisibilityCheckDispatcher: VisibilityCheckDispatcher,
	Visit: Visit, VisualizationMode: VisualizationMode, VisualizationModeCategory: VisualizationModeCategory, VisualizationModeService: VisualizationModeService, VoiceChatInternal: VoiceChatInternal, VoiceChatService: VoiceChatService, WebStreamClient: WebStreamClient, WedgePart: WedgePart, Weld: Weld, WeldConstraint: WeldConstraint,
	Wire: Wire, WireframeHandleAdornment: WireframeHandleAdornment, Workspace: Workspace, WorkspaceAnnotation: WorkspaceAnnotation, WorldModel: WorldModel, WorldRoot: WorldRoot, WrapDeformer: WrapDeformer, WrapLayer: WrapLayer, WrapTarget: WrapTarget, WrapTextureTransfer: WrapTextureTransfer,
	}
	
	type function toInstance(classname: type)
		if classname and not (classname.tag == "unknown" or classname.tag == "any" or classname.tag == "string") then
			local isvalid = classname:is("singleton") and typeof(classname:value()) == "string"
			local class = isvalid and RobloxClasses:readproperty(classname)

			if class then return class
			elseif isvalid then print("Invalid classname.") 	
			else print(`Expected to be provided an instance ClassName, but got {classname.tag}.`) end

			return types.never
		end

		return RobloxClasses:readproperty(types.singleton("Instance"))
	end

	local instanceCache = {
		["Instance"] = {
			type = "Instance",
			name = "Instance",
			ser = function(cursor: Cursor, v: Instance)
				if VALIDATION_ENABLED then 
					beginValidationScope(cursor, "Instance")
				end

				if not (typeof(v) == "Instance") then
					reportValidationError(cursor, `Expected provided value to be an instance, got {v} ({subtypeof(v)}).`)
				end

				pushref(cursor, v)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,
			des = function(cursor: Cursor): Instance?
				local v = popref(cursor)
				if typeof(v) ~= "Instance" then return nil end 
				return v
			end,
		}
	}

	-- Returns SerDes for 'Instance' datatype, with optional parameter for the class of the instance (checks inheritance).
	-- Defaults to all instances.
	function Squish.Instance<T>(classname: T | keyof<RobloxClasses> | nil): SerDes<toInstance<T>>
		if classname then assertSchemaType(classname, "string", 1) end 

		local classname = classname or "Instance"
		if instanceCache[classname] then
			return instanceCache[classname]
		end

		local t = `Instance:{classname}`

		local ins: SerDes<Instance?> = {
			type = "Instance",
			name = "Instance",
			structure = classname,
			ser = function(cursor: Cursor, v: Instance?)
				if VALIDATION_ENABLED then 
					beginValidationScope(cursor, t)
				end 

				if not (typeof(v) == "Instance" and v:IsA(classname)) then
					reportValidationError(cursor, `Expected provided value to be an instance of class "{classname}", got {v} ({subtypeof(v)}).`)
				end

				pushref(cursor, v)

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor: Cursor): Instance?
				local v = popref(cursor)
				if not (typeof(v) == "Instance" and v:IsA(classname)) then return nil end 
				return v
			end,
		}

		instanceCache[classname] = ins
		return ins
	end

end

-->>

do
	local literalid = 231
	local numberid = 232

	local f16id = 8 + numberid
	local f32id = 9 + numberid
	local f64id = 10 + numberid
	local hugeid = 11 + numberid
	local nhugeid = 12 + numberid
	local nanid = 13 + numberid

	function Squish.anyFrom<L>(toindex: {[string]: number}, toserdes: {[number]: SerDes<any>}, literalsMap: {[any]: number}?, literals: {[number]: any}?, hassubtypes: boolean?, usenumberfastpath: boolean?): SerDes<any>
		local anyFromSerdes: SerDes<any> = {
			type = nil,
			name = "variant",

			multypeinfo = {
				toindex = toindex,
				toserdes = toserdes,
				literals = literals,
				literalsMap = literalsMap,

				hassubtypes = hassubtypes,
				numberfastpath = usenumberfastpath,
			},

			ser = function(cursor: Cursor, x: any)
				if VALIDATION_ENABLED then beginValidationScope(cursor, "any") end 

				local litId = literalsMap and literalsMap[x]
				if litId then
					tryrealloc(cursor, 2)
					pushu1(cursor, litId)
					pushu1(cursor, literalid)
				else
					local t = typeof(x)
					if usenumberfastpath and t == "number" then
						-- special path

						local isfinite = math.isfinite(x)
						if (not isfinite) then
							if math.isnan(x) then
								tryrealloc(cursor, 1)
								pushu1(cursor, nanid)
							else
								tryrealloc(cursor, 1)
								pushu1(cursor, if x == math.huge then hugeid else nhugeid)
							end
						elseif (x % 1 ~= 0 or x >= 2^64 or x <= -2^64) then
							local m, e = math.frexp(x)
							
							if e >= -13 and e <= 16 and (m * 2^11) % 1 == 0 then
								tryrealloc(cursor, 3)
								pushf2(cursor, x)
								pushu1(cursor, f16id)
							elseif e >= -125 and e <= 128 and (m * 2^24) % 1 == 0 then
								tryrealloc(cursor, 5)
								pushf4(cursor, x)
								pushu1(cursor, f32id)
							else
								tryrealloc(cursor, 9)
								pushf8(cursor, x)
								pushu1(cursor, f64id)
							end

						else 
							pushu1(cursor, common_serInt(cursor, x) + numberid)
						end
					else 
						local tid
						if hassubtypes then
							local subtype = subtypeof(x, t)
							local potentialMatch = toindex[subtype]

							if potentialMatch and toserdes[potentialMatch] then 
								t = subtype
								tid = potentialMatch 
							else 
								tid = toindex[t]
							end
						else 
							tid = toindex[t] 
						end

						if toserdes[tid] then 
							toserdes[tid].ser(cursor, x)
							tryrealloc(cursor, 1)
							pushu1(cursor, tid)
						else
							local idx = toindex["nil"]

							if idx then
								toserdes[idx].ser(cursor, nil)
								tryrealloc(cursor, 1)
								pushu1(cursor, idx)
							else
								reportValidationError(cursor, `Type {t} is not supported.`)
							end
						end
					end
				end

				if VALIDATION_ENABLED then exitValidationScope(cursor) end
			end,

			des = function(cursor: Cursor): any
				local id = popu1(cursor)

				if usenumberfastpath and id >= numberid then
					if id == f16id then return popf2(cursor)
					elseif id == f32id then return popf4(cursor)
					elseif id == f64id then return popf8(cursor)
					elseif id == hugeid then return math.huge
					elseif id == nhugeid then return -math.huge 
					elseif id == nanid then return math.nan
					else return common_desInt(cursor, id - numberid, true)
					end
				elseif id == literalid then
					return literals[popu1(cursor)]
				else
					local serdes = toserdes[id]
					if serdes then return serdes.des(cursor) 
					else return end
				end
			end,
		}

		return anyFromSerdes
	end

	-- Returns SerDes for types provided to the function, with support for literals.
	-- <strong>Example</strong>: <em>Squish.variant({number = Squish.f32(), boolean = Squish.boolean()}, {"hello"})</em>
	function Squish.variant<T, L>(types: {T}, literals: {L}?): SerDes<index<T, "__T"> | L>
		local toindex: {[string]: number} = {}
		local toserdes: {[number]: SerDes<any>} = {}
		local literalsMap: {[L]: number} 
		local idtoLiteral: {L}

		local hassubtypes = false
		local count = 0

		assertSchemaType(types, "table", 1)

		for i, serdes in types do 
			assertIsSerdes(serdes, `field {i} in serdes array`)
			if serdes.multypeinfo then error(`field {i} cannot be a multi-type SerDes in serdes array`, 0) end
			assertSchemaType(serdes.type, "string", `serdestype of field {i} in serdes array`)

			if optMap[serdes] then
				if not toindex["nil"] then
					toindex["nil"] = count
					toserdes[count] = Squish.Nil()
					count += 1
				end
				serdes = optMap[serdes]
			end

			local name = serdes.type
			if toindex[name] then
				error(`field {i} ({name}) is repeated to Squish.variant() in serdes array.`, 0)
			end

			toindex[name] = count
			toserdes[count] = serdes
			count += 1

			hassubtypes = hassubtypes or not not string.find(name, ":", nil, true)
		end

		if literals ~= nil then
			assertSchemaType(literals, "table", 2)

			literalsMap, idtoLiteral = {}, {}

			for i, v in literals do
				local id = i - 1 
				
				if v ~= v then literalsMap[nanidkey] = id
				else literalsMap[v] = id end

				idtoLiteral[id] = v
			end

			if literalsMap[nanidkey] then
				setmetatable(literalsMap, literalsmap_mtbl)
			end
		end

		return Squish.anyFrom(toindex, toserdes, literalsMap, idtoLiteral, hassubtypes, false)
	end

	-- Adds the provided 'childSerdes' to 'serdes'. 'serdes' should be a variant or any serdes with a type.
	function Squish.addserdes(serdes: SerDes<any>, childSerdes: SerDes<any>)
		serdes = Squish.unopt(serdes)

		assertIsSerdes(serdes, 1)

		local info = serdes.multypeinfo
		assert(info and info.toserdes and info.toindex, `Parameter 1 does not support adding SerDes.`, 0)

		assertIsSerdes(childSerdes, 2)
		assert(not childSerdes.multypeinfo, `Parameter 2 cannot be a multi-type SerDes.`, 0)
		assertSchemaType(childSerdes.type, "string", "serdestype of parameter 2")

		local toindex = info.toindex
		local toserdes = info.toserdes

		local lastidx = #toserdes
		if lastidx == 0 and not toserdes[0] then lastidx = -1 end

		lastidx += 1

		local underlying = optMap[childSerdes]
		if underlying then
			if not toindex["nil"] then
				toindex["nil"] = lastidx
				toserdes[lastidx] = Squish.Nil()

				lastidx += 1
			end

			childSerdes = underlying
		end

		local name = childSerdes.type
		if toindex[name] then return end

		toindex[name] = lastidx
		toserdes[lastidx] = childSerdes

		-- can't enable hassubtypes since it relies on the upvalue rather than multypeinfo.
	end
end 

do 
	local anytypeToId: {[string]: number} = {}
	local idtoAnyType: {string} = {}
	local idtoSerdes: {SerDes<any>} = {}
	local lastAnyTypeId = 0

	local anyCache = Squish.anyFrom(anytypeToId, idtoSerdes, {}, {}, false, true)
	anyCache.name = "any"

	-- Returns a SerDes that can take in almost any value.
	function Squish.any(): SerDes<any>
		return anyCache
	end

	local function addanySerdes(serdesfunc: ((...any) -> SerDes<any>)?, ...: any?)
		local serdes = serdesfunc and serdesfunc(...)
		if not serdes then
			lastAnyTypeId += 1
			return
		end

		local t = serdes.type
		if type(t) ~= "string" then
			error(`Expected provided serdes to have a string type, but got {t} ({typeof(t)}).`, 0)
		end

		if anytypeToId[t] then
			error(`Type {t} was already added.`, 0)
		end

		local nextid = lastAnyTypeId
		lastAnyTypeId = nextid + 1

		anytypeToId[t] = nextid
		idtoSerdes[nextid] = serdes
		idtoAnyType[nextid] = t
	end

	-- !!! DO NOT CHANGE THE ORDER BELOW. ADD NEW DATATYPES AT THE END.
	-- Changing order will shift the type byte assigned to each datatype, thus breaking compatibility.

	addanySerdes(Squish.Nil)
	addanySerdes(Squish.boolean)
	addanySerdes(Squish.string)
	addanySerdes(Squish.buffer)
	addanySerdes(Squish.table, Squish.any())

	addanySerdes(Squish.vector)
	addanySerdes(Squish.Vector2)
	addanySerdes(Squish.CFrame)
	addanySerdes(Squish.Ray)
	addanySerdes(Squish.Region3)

	addanySerdes(Squish.Instance)
	addanySerdes(Squish.EnumItem)
	addanySerdes(Squish.PhysicalProperties)
	addanySerdes(Squish.PathWaypoint)
	addanySerdes(Squish.RaycastParams)
	addanySerdes(Squish.OverlapParams)
	addanySerdes(Squish.RaycastResult)
	addanySerdes(Squish.Faces)
	addanySerdes(Squish.Axes)

	addanySerdes(Squish.Vector3int16)
	addanySerdes(Squish.Vector2int16)
	addanySerdes(Squish.Region3int16)

	addanySerdes(Squish.NumberRange)
	addanySerdes(Squish.NumberSequenceKeypoint)
	addanySerdes(Squish.NumberSequence)

	addanySerdes(Squish.BrickColor)
	addanySerdes(Squish.Color3)
	addanySerdes(Squish.ColorSequenceKeypoint)
	addanySerdes(Squish.ColorSequence)

	addanySerdes(Squish.UDim)
	addanySerdes(Squish.UDim2)
	addanySerdes(Squish.Rect)
	addanySerdes(Squish.Font)

	addanySerdes(Squish.TweenInfo)
	addanySerdes(Squish.DateTime)
	addanySerdes(Squish.CatalogSearchParams)

	addanySerdes(Squish.FloatCurveKey)
	addanySerdes(Squish.RotationCurveKey)

	-- !!! DO NOT CHANGE THE ORDER ABOVE, ADD NEW DATATYPES AT THE END.
end

return Squish