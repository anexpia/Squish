--- @class Squish

--------------------------------------------------------------------------------
-- TYPES
--------------------------------------------------------------------------------

--- @interface Cursor
--- @within Squish
--- .name string? -- primarily used in error messages to better identify the cursor and source.
--- .pos number
--- .size: number
--- Object responsible for serializing and deserializing values. Every API interacts with this.

--[=[ 
	@interface SerDes
	@within Squish
	.ser (Cursor, ...T...) -> ()
	.des (Cursor) -> T...
	.type string? -- Type of the serdes, like string, number, etc.
	.name string? -- Name of the serdes in Squish.
	.structure any? -- Structure required to reproduce the exact same serdes.
	.multypeinfo {toindex: {[string]: number}?, toserdes: {[number]: SerDes<any>}?, literals: {any}?, literalsMap: {[any]: number}?, hassubtypes: boolean?, numberfastpath: boolean?}? -- Used by 'variant' and 'literal' serdes. 
]=]

--- @interface SquishRaycastResult
--- @within Squish
--- .Instance BasePart -- Hit instance, may be nil if it couldn't be found in references.
--- .Distance number -- Distance traversed by the raycast.
--- .Position Vector3 -- Hit position.
--- .Normal Vector3 -- Surface normal of the instance.
--- .Material Enum.Material -- Material of the instance at the hit position.
--- Resulting value from deserialization by [Squish:RaycastResult].

--------------------------------------------------------------------------------
-- VALIDATION NAMESPACE
--------------------------------------------------------------------------------

--[=[
	@class validation
	Namespace containing internal validation utilities and scope tracking.
]=]

--- @prop scopesEnabled boolean
--- @within validation
--- The `VALIDATIONENABLED` setting.

--- @function assertSchemaType
--- @within validation
--- @param v any -- Value to check.
--- @param t string -- Expected type.
--- @param parameter string | number -- Parameter index or a string override for it.
--- @param context string? -- Calling function. defaults to `Squish.{funcname}`.
--- Used for validating schema types when constructing SerDes.

--- @function assertIsSerdes
--- @within validation
--- @param v any -- Value to check if is serdes.
--- @param parameter string | number -- Parameter index or a string override for it.
--- @param context string? -- Calling function. defaults to `Squish.{funcname}`.
--- Asserts whether the provided value is a valid SerDes.

--- @function assertSerdesType
--- @within validation
--- @param serdes SerDes<any> -- Serdes to check.
--- @param t string -- Expected type of serdes.
--- @param parameter string | number -- Parameter index or a string override for it.
--- @param context string? -- Calling function. defaults to `Squish.{funcname}`.
--- Asserts whether the provided SerDes matches the expected type.

--- @function assertSerializeType
--- @within validation
--- @param cursor Cursor
--- @param value any
--- @param type string
--- Asserts that the value being serialized matches the expected type.

--- @function beginValidationScope
--- @within validation
--- @param cursor Cursor
--- @param name string
--- Appends `name` to the validation scopes.

--- @function exitValidationScope
--- @within validation
--- @param cursor Cursor
--- Pops the current validation scope.

--- @function overrideValidationScopeName
--- @within validation
--- @param cursor Cursor
--- @param name string
--- Changes the name of the last validation scope.

--------------------------------------------------------------------------------
-- UTILITY NAMESPACE
--------------------------------------------------------------------------------

--[=[
	@class util
	Namespace containing functions for pushing & popping values directly from the cursor.
]=]

--- @function tryrealloc
--- @within util
--- @param cursor Cursor
--- @param size number
--- Reallocates the buffer if the cursor position + size exceed the buffer size.

--- @function setpos
--- @within util
--- @param cursor Cursor
--- @param pos number
--- Sets the current position of the cursor.

--- @function getpos
--- @within util
--- @param cursor Cursor
--- @return number
--- Gets the current position of the cursor.

--- @function setbuf
--- @within util
--- @param cursor Cursor
--- @param buf buffer
--- Sets the current buffer of the cursor.

--- @function getbuf
--- @within util
--- @param cursor Cursor
--- @return buffer
--- Gets the current buffer of the cursor.

--- @function pushu1
--- @within util
--- @param cursor Cursor
--- @param x number -- 8 bits unsigned number

--- @function popu1
--- @within util
--- @param cursor Cursor
--- @return number -- 8 bits unsigned number

--- @function pushu2
--- @within util
--- @param cursor Cursor
--- @param x number -- 16 bits unsigned number

--- @function popu2
--- @within util
--- @param cursor Cursor
--- @return number -- 16 bits unsigned number

--- @function pushu3
--- @within util
--- @param cursor Cursor
--- @param x number -- 24 bits unsigned number

--- @function popu3
--- @within util
--- @param cursor Cursor
--- @return number -- 24 bits unsigned number

--- @function pushu4
--- @within util
--- @param cursor Cursor
--- @param x number -- 32 bits unsigned number

--- @function popu4
--- @within util
--- @param cursor Cursor
--- @return number -- 32 bits unsigned number

--- @function pushu5
--- @within util
--- @param cursor Cursor
--- @param x number -- 40 bits unsigned number

--- @function popu5
--- @within util
--- @param cursor Cursor
--- @return number -- 40 bits unsigned number

--- @function pushu6
--- @within util
--- @param cursor Cursor
--- @param x number -- 48 bits unsigned number

--- @function popu6
--- @within util
--- @param cursor Cursor
--- @return number -- 48 bits unsigned number

--- @function pushu7
--- @within util
--- @param cursor Cursor
--- @param x number -- 56 bits unsigned number

--- @function popu7
--- @within util
--- @param cursor Cursor
--- @return number -- 56 bits unsigned number

--- @function pushu8
--- @within util
--- @param cursor Cursor
--- @param x number -- 64 bits unsigned number

--- @function popu8
--- @within util
--- @param cursor Cursor
--- @return number -- 64 bits unsigned number

--- @function pushi1
--- @within util
--- @param cursor Cursor
--- @param x number -- 8 bits signed number

--- @function popi1
--- @within util
--- @param cursor Cursor
--- @return number -- 8 bits signed number

--- @function pushi2
--- @within util
--- @param cursor Cursor
--- @param x number -- 16 bits signed number

--- @function popi2
--- @within util
--- @param cursor Cursor
--- @return number -- 16 bits signed number

--- @function pushi3
--- @within util
--- @param cursor Cursor
--- @param x number -- 24 bits signed number

--- @function popi3
--- @within util
--- @param cursor Cursor
--- @return number -- 24 bits signed number

--- @function pushi4
--- @within util
--- @param cursor Cursor
--- @param x number -- 32 bits signed number

--- @function popi4
--- @within util
--- @param cursor Cursor
--- @return number -- 32 bits signed number

--- @function pushi5
--- @within util
--- @param cursor Cursor
--- @param x number -- 40 bits signed number

--- @function popi5
--- @within util
--- @param cursor Cursor
--- @return number -- 40 bits signed number

--- @function pushi6
--- @within util
--- @param cursor Cursor
--- @param x number -- 48 bits signed number

--- @function popi6
--- @within util
--- @param cursor Cursor
--- @return number -- 48 bits signed number

--- @function pushi7
--- @within util
--- @param cursor Cursor
--- @param x number -- 56 bits signed number

--- @function popi7
--- @within util
--- @param cursor Cursor
--- @return number -- 56 bits signed number

--- @function pushi8
--- @within util
--- @param cursor Cursor
--- @param x number -- 64 bits signed number

--- @function popi8
--- @within util
--- @param cursor Cursor
--- @return number -- 64 bits signed number

--- @function pushf2
--- @within util
--- @param cursor Cursor
--- @param x number -- 16 bits float number

--- @function popf2
--- @within util
--- @param cursor Cursor
--- @return number -- 16 bits float number

--- @function pushf4
--- @within util
--- @param cursor Cursor
--- @param x number -- 32 bits float number

--- @function popf4
--- @within util
--- @param cursor Cursor
--- @return number -- 32 bits float number

--- @function pushf8
--- @within util
--- @param cursor Cursor
--- @param x number -- 64 bits float number

--- @function popf8
--- @within util
--- @param cursor Cursor
--- @return number -- 64 bits float number

--- @function pushbool
--- @within util
--- @param cursor Cursor
--- @param bool boolean

--- @function popbool
--- @within util
--- @param cursor Cursor
--- @return boolean

--- @function pushboolpack
--- @within util
--- @param cursor Cursor
--- @param ... boolean?
--- Packs up to 8 booleans into a single byte and writes it into the buffer.

--- @function popboolpack
--- @within util
--- @param cursor Cursor
--- @return boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean
--- Reads 8 packed booleans from the buffer.

--- @function pushvlqrealloc
--- @within util
--- @param cursor Cursor
--- @param x number
--- Writes a variable length unsigned integer into the buffer and allocates the bytes needed for it.

--- @function popvlq
--- @within util
--- @param cursor Cursor
--- @return number
--- Reads a variable length unsigned integer from the buffer.

--- @function pushstr
--- @within util
--- @param cursor Cursor
--- @param x string
--- @param length number?
--- Writes a string to the cursor.

--- @function popstr
--- @within util
--- @param cursor Cursor
--- @param length number?
--- @return string
--- Reads a string from the cursor.

--- @function pushbuf
--- @within util
--- @param cursor Cursor
--- @param x buffer
--- @param length number?
--- Writes a buffer to the cursor.

--- @function popbuf
--- @within util
--- @param cursor Cursor
--- @param length number?
--- @return buffer
--- Reads a buffer from the cursor.

--- @function serbitarr
--- @within util
--- @param cursor Cursor
--- @param bits {boolean}
--- @param length number? -- Fixed length for the bit array
--- Serializes an array of booleans as a bit array into the buffer.

--- @function desbitarr
--- @within util
--- @param cursor Cursor
--- @param bitCount number -- Length of the bit array
--- @return {boolean}
--- Deserializes a bit array of `bitCount` length from the buffer.

--- @function pushref
--- @within util
--- @param cursor Cursor
--- @param v any
--- Adds a value to the 'references' table.

--- @function popref
--- @within util
--- @param cursor Cursor
--- @return any
--- Removes a value from the 'references' table using the current vlq.

--------------------------------------------------------------------------------
-- STRING NAMESPACE
--------------------------------------------------------------------------------

--[=[
	@class string
	This namespace may be called like a function to return a string serdes, or it may be accessed like a table to use the string content.
]=]

--[=[
	@function packintoalphanumeric
	@param str string
	@return buffer
	@within string
	Packs the string into 6 bits per character, reducing length by average of 25%.
	Only supports uppercase & lowercase letters and numbers. Unsupported characters are replaced by spaces.
]=]

--[=[
	@function unpackalphanumeric
	@param buf buffer
	@return string
	@within string
	Converts back the buffer into a string. Remainder bytes at the end of the text are replaced by spaces.
]=]

--[=[
	@function convert
	@param str string
	@param inAlphabet string
	@param outAlphabet string
	@return string
	@within string
	Converts a string, treated as a number in base `inAlphabet`, to a number in base `toAlphabet`.
]=]

--[=[
	@function alphabet
	@param source string
	@return string
	@within string
	Returns the smallest sorted alphabet from a source string.
]=]

--- @prop binary string
--- @within string
--- The alphabet `'01'`.

--- @prop octal string
--- @within string
--- The alphabet `'01234567'`.

--- @prop decimal string
--- @within string
--- The alphabet `'0123456789'`.

--- @prop duodecimal string
--- @within string
--- The alphabet `'0123456789AB'`.

--- @prop hexadecimal string
--- @within string
--- The alphabet `'0123456789ABCDEF'`.

--- @prop utf8 string
--- @within string
--- The alphabet of all 256 possible characters.

--- @prop lower string
--- @within string
--- The alphabet `'abcdefghijklmnopqrstuvwxyz'`.

--- @prop upper string
--- @within string
--- The alphabet `'ABCDEFGHIJKLMNOPQRSTUVWXYZ'`.

--- @prop letters string
--- @within string
--- The alphabet `lower .. upper`.

--- @prop punctuation string
--- @within string
--- The alphabet `' .,?!:;\'"-_'`.

--- @prop english string
--- @within string
--- The alphabet `letters .. punctuation`.

--- @prop filepath string
--- @within string
--- The alphabet `letters .. ':/'`.

--- @prop datastore string
--- @within string
--- The alphabet of every character that doesn't get expanded when JSON encoding.

--------------------------------------------------------------------------------
-- 1. CURSOR (@tag Cursor)
--------------------------------------------------------------------------------

--- @function print
--- @within Squish
--- @tag Cursor
--- @param cursor Cursor
--- Pretty prints a Cursor.

--- @function cursor
--- @within Squish
--- @tag Cursor
--- @param size number? -- Override size for the cursor, default is 8.
--- @param pos number? -- Override position for the cursor.
--- @return Cursor

--- @function frombuffer
--- @within Squish
--- @tag Cursor
--- @param buf buffer
--- @param pos number? -- Override position for the cursor, default is end of buffer.
--- @param references { any }? -- References that were previously used for serializing if present.
--- @return Cursor
--- Creates a new cursor using the provided buffer.\
--- 'references' should be provided if the buffer has attached references.

--- @function tobuffer
--- @within Squish
--- @tag Cursor
--- @param cursor Cursor
--- @return buffer, { any }?
--- Returns a copy of the buffer and the attached references if they exist.

--- @function addliterals
--- @within Squish
--- @param Serdes SerDes
--- @param ... any...
--- Adds the provided literals to the serdes.

--- @function addserdes
--- @within Squish
--- @param serdes SerDes
--- @param childSerdes SerDes
--- Adds the provided childSerdes to the variant or any serdes.

--------------------------------------------------------------------------------
-- 2. BASIC (@tag Basic)
--------------------------------------------------------------------------------

-- --- @class opt

--- @function opt
--- @within Squish
--- @tag Basic
--- @param serdes SerDes<T>
--- @return SerDes<T?>
--- Returns a copy of the provided SerDes which optionally accepts 'nil' value.

-- --- @class dedup

--[=[ 
	@function dedup
	@within Squish
	@tag Basic
	@param serdes SerDes<T>
	@return SerDes<T?>
	Returns a copy of the provided SerDes which can deduplicate the value if provided more than once.\
	Cannot be used with optional, boolean, nil, and Instance SerDes.

	```lua
	local arraySerDes = Squish.dedup(Squish.array(Squish.u8()))
	local arr = { 1, 2, 3, 4, 5 }
	
	for i = 1, 3 do 
		serdes.ser(cursor, arr)
	end
	
	local t1, t2, t3 = serdes.des(cursor), serdes.des(cursor), serdes.des(cursor)
	print(t1 == t2, t1 == t3) -- will print true, true
	```

]=]

-- --- @class ref

--- @function ref
--- @within Squish
--- @tag Basic
--- @return SerDes<any>
--- Returns SerDes that pushes / pops values from cursor.refs array.
--- Essentially a wrapper for `util.pushref` and `util.popref`.

-- --- @class tuple

--- @function tuple
--- @within Squish
--- @tag Basic
--- @param ... T... -- Tuple of serdes.
--- @return SerDes<T...>
--- Serdes for serializing provided values by the corresponding serdes used for construction.

-- --- @class literal

--- @function literal
--- @within Squish
--- @tag Basic
--- @param array { any } -- Array of literal values.
--- @return SerDes<any>
--- Serdes for exactly only values provided to the array.

-- --- @class any

--[=[
	@function any
	@within Squish
	@tag Basic
	@return SerDes<any>
	Serdes that accepts every datatype Squish supports.
	Do not use this unless you cannot guarantee the types of your values and neither can **[Squish:variant]** be used for your purposes.
]=]

-- --- @class variant

--[=[
	@function variant
	@within Squish
	@tag Basic
	@param types { SerDes<any> } -- Array of allowed serdes.
	@param literals { any }? -- Array of allowed literal values
	@return SerDes<any>
	Takes an array of SerDes and serializes values using the SerDes that matches their type.\
	Optionally accepts an array of literals, which works like **[Squish:literal]**.
	
	If a value is not found in literals, and its serdes is not provided. It will error unless **[Squish.Nil]** was included.\
	Opt serdes automatically provide the nil serdes when provided.
]=]

-- --- @class anyFrom

--[=[
	@function anyFrom
	@within Squish
	@tag Basic
	@param toindex { [string]: number } -- Dictionary mapping types to their id.
	@param toserdes { [number]: SerDes<any> } -- Array containing SerDes'.
	@param literalsMap { [any]: number }? -- Dictionary mapping literals to their id.
	@param literals { [number]: any }? -- Array of literals.
	@param hassubtypes boolean? -- Enable if there's "subtypes" for serdes, such as an Instance serdes that accepts only parts.
	@param usenumberfastpath boolean? -- Uses an inlined form of the number serdes.
	@return SerDes<any>
	Low-level internal function to build a dynamic serdes for `variant()` and `any()`. 
	You probably shouldn't use this directly unless you know what you're doing.
]=]

--------------------------------------------------------------------------------
-- 3. NUMBER (@tag Number)
--------------------------------------------------------------------------------

-- --- @class uint

--- @function u8
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [0, 255].

--- @function u16
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [0, 65535].

--- @function u24
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [0, 16777215].

--- @function u32
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [0, 4294967295].

--- @function u40
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [0, 1099511627775].

--- @function u48
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [0, 281474976710655].

--- @function u56
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [0, 72057594037927935].\
--- Diminished accuracy, use wisely.

--- @function u64
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [0, 18446744073709551615].\
--- Greatly diminished accuracy, use wisely.

-- --- @class int

--- @function i8
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [-128, 127].

--- @function i16
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [-32768, 32767].

--- @function i24
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [-8388608, 8388607].

--- @function i32
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [-2147483648, 2147483647].

--- @function i40
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [-549755813888, 549755813887].

--- @function i48
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [-140737488355328, 140737488355327].

--- @function i56
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [-36028797018963968, 36028797018963967].\
--- Diminished accuracy, use wisely.

--- @function i64
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for integer numbers in range [-9223372036854775808, 9223372036854775807].\
--- Greatly diminished accuracy, use wisely.

-- --- @class float

--- @function f16
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for half-precision float numbers in range [-65504, 65504].

--- @function f32
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for single-precision float numbers in range [-3.4e38, 3.4e38].

--- @function f64
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for double-precision float numbers in range [-1.8e308, 1.8e308].

-- --- @class number

--- @function number
--- @within Squish
--- @tag Number
--- @param floatAllowed boolean? -- Whether to allow serializing as float, defaults to true.
--- @return SerDes<number>
--- Serdes for any number. Dynamically selects the smallest possible representation for the numbers.

--- @function range
--- @within Squish
--- @tag Number
--- @param min number
--- @param max number
--- @param serdes SerDes<number>? -- Which serdes to use for serializing instead of the smallest uint serdes.
--- @param restricted boolean? -- Whether to clamp the serialized number to [min - max] range.
--- @return SerDes<number>
--- The given min and max must be integers, and min < max. Uses the smallest uint representation for a given range.

-- --- @class vlq

--- @function vlq
--- @within Squish
--- @tag Number
--- @return SerDes<number>
--- Serdes for unsigned integer of any size, used for serializing and deserializing variable lengths.


--------------------------------------------------------------------------------
-- 4. TABLE (@tag Table)
--------------------------------------------------------------------------------

--- @function array
--- @within Squish
--- @tag Table
--- @param serdes SerDes<T>
--- @param length (number | SerDes<number>)? -- Optional fixed length or serdes for serializing length.
--- @return SerDes<{T}>
--- Serdes that serializes arrays with the given serdes.\
--- Deserializing can take a second parameter for a pre-allocated table to write to.

--- @function map
--- @within Squish
--- @tag Table
--- @param keySerDes SerDes<K>
--- @param valueSerDes SerDes<V>
--- @param length (number | SerDes<number>)? -- Optional fixed length or serdes for serializing length.
--- @return SerDes<{[K]: V}>
--- Serdes that serializes tables keys using keySerDes and values using valueSerDes.\
--- Deserializing can take a second parameter for a pre-allocated table to write to.

--- @function record
--- @within Squish
--- @tag Table
--- @param schema T
--- @return SerDes<T>
--- Serdes that serializes tables given a schema mapping each string key to a serdes.\
--- Deserializing can take a second parameter for a pre-allocated table to write to.

--[=[
	@function table
	@within Squish
	@tag Table
	@param serdes SerDes<T>
	@return SerDes<{[T]: T}>
	Returns SerDes for arbitrary tables of any shape, supporting mixed tables, gaps, and circular references.\
	Uses the provided single `serdes` parameter for serializing both keys and values.\
	Deserializing can take a second parameter for a pre-allocated table to write to.
	
	**It is highly recommended that you do not use this for tables you know the type of already.**
]=]


--------------------------------------------------------------------------------
-- 5. LUAUTYPE (@tag LuauType)
--------------------------------------------------------------------------------

-- --- @class boolean

--- @function boolean
--- @within Squish
--- @tag LuauType
--- @return SerDes<boolean>

--- @function boolpack
--- @within Squish
--- @tag LuauType
--- @return SerDes<boolean?, boolean?, boolean?, boolean?, boolean?, boolean?, boolean?, boolean?>

--- @function string
--- @within Squish
--- @tag LuauType
--- @param length number? -- Optional length for the string.
--- @return SerDes<string>
--- Serdes for string values.

-- --- @class buffer

--- @function buffer
--- @within Squish
--- @tag LuauType
--- @param length number? -- Optional length for the buffer.
--- @return SerDes<buffer>
--- Serdes for buffer values.

-- --- @class nil

--- @function Nil
--- @within Squish
--- @tag LuauType
--- @return SerDes<Nil>
--- Serdes for.. nil, yeah. 

-- --- @class vector

--- @function vector
--- @within Squish
--- @tag LuauType
--- @param size number? -- Size of vector [2, 3, or 4 if enabled]. defaults to highest.
--- @param serdes SerDes<number>? -- Optional serdes for serializing, defaults to f32.
--- @return SerDes<vector>
--- Serdes for [vector] values.

--- @function Vector3
--- @within Squish
--- @tag LuauType
--- @param serdes SerDes<number>?
--- @return SerDes<vector>
--- Wrapper for Squish.vector(3).

--------------------------------------------------------------------------------
-- 6. ROBLOXTYPE (@tag RobloxType)
--------------------------------------------------------------------------------

-- --- @class Axes

--- @function Axes
--- @within Squish
--- @tag RobloxType
--- @return SerDes<Axes>
--- Serdes for [Axes] Datatype.

-- --- @class BrickColor

--- @function BrickColor
--- @within Squish
--- @tag RobloxType
--- @return SerDes<BrickColor>
--- Serdes for [BrickColor] Datatype.

-- --- @class EnumItem

--- @function EnumItem
--- @within Squish
--- @tag RobloxType
--- @param enum Enum? -- optional type of enum. eg. `Enum.Material`.
--- @return SerDes<EnumItem>
--- Serdes for [EnumItem] Datatype.\
--- If the type of enum is not provided, will serialize any enumitem provided regardless of type.

-- --- @class Instance

--- @function Instance
--- @within Squish
--- @tag RobloxType
--- @param classname string? -- optional classname. eg. `BasePart`.
--- @return SerDes<Instance>
--- Serdes for [Instance] Datatype.\
--- If the classname is not provided, will serialize any instance.

-- --- @class CatalogSearchParams

--- @function CatalogSearchParams
--- @within Squish
--- @tag RobloxType
--- @return SerDes<CatalogSearchParams>
--- Serdes for [CatalogSearchParams] Datatype.\

-- --- @class CFrame

--- @function CFrame
--- @within Squish
--- @tag RobloxType
--- @param positionSerDes SerDes<number> | false? -- Optional serdes for serializing the positional component, defaults to f32. `false` omits position.
--- @return SerDes<CFrame>
--- Serdes for [CFrame] Datatype.

-- --- @class rotation

--- @function rotation
--- @within Squish
--- @tag RobloxType
--- @return SerDes<CFrame>
--- Wrapper for Squish.CFrame(false).

-- --- @class Color3

--- @function Color3
--- @within Squish
--- @tag RobloxType
--- @return SerDes<Color3>
--- Serdes for [Color3] Datatype. Saves color components as u8 integers [0-255].

--- @function Color3f16
--- @within Squish
--- @tag RobloxType
--- @return SerDes<Color3>
--- Similar to Squish.Color3(), but serializes components as float16, allowing numbers outside [0-255] range.

-- --- @class ColorSequenceKeypoint

--- @function ColorSequenceKeypoint
--- @within Squish
--- @tag RobloxType
--- @return SerDes<ColorSequenceKeypoint>
--- Serdes for [ColorSequenceKeypoint] Datatype.

-- --- @class ColorSequence

--- @function ColorSequence
--- @within Squish
--- @tag RobloxType
--- @return SerDes<ColorSequence>
--- Serdes for [ColorSequence] Datatype.

-- --- @class DateTime

--- @function DateTime
--- @within Squish
--- @tag RobloxType
--- @return SerDes<DateTime>
--- Serdes for [DateTime] Datatype.

-- --- @class Faces

--- @function Faces
--- @within Squish
--- @tag RobloxType
--- @return SerDes<Faces>
--- Serdes for [Faces] Datatype.

-- --- @class FloatCurveKey

--- @function FloatCurveKey
--- @within Squish
--- @tag RobloxType
--- @return SerDes<FloatCurveKey>
--- Serdes for [FloatCurveKey] Datatype.

-- --- @class Font

--- @function Font
--- @within Squish
--- @tag RobloxType
--- @return SerDes<Font>
--- Serdes for [Font] Datatype.

-- --- @class NumberRange

--- @function NumberRange
--- @within Squish
--- @tag RobloxType
--- @param serdes SerDes<number>? -- Optional serdes for serializing, defaults to f32.
--- Serdes for [NumberRange] Datatype.

-- --- @class NumberSequenceKeypoint

--- @function NumberSequenceKeypoint
--- @within Squish
--- @tag RobloxType
--- @param serdes SerDes<number>? -- Optional serdes for serializing, defaults to f32.
--- @return SerDes<NumberSequenceKeypoint>
--- Serdes for [NumberSequenceKeypoint] Datatype.

-- --- @class NumberSequence

--- @function NumberSequence
--- @within Squish
--- @tag RobloxType
--- @param serdes SerDes<number>? -- Optional serdes for serializing, defaults to f32.
--- @return SerDes<NumberSequence>
--- Serdes for [NumberSequence] Datatype.

-- --- @class OverlapParams

--- @function OverlapParams
--- @within Squish
--- @tag RobloxType
--- @return SerDes<OverlapParams>
--- Serdes for [OverlapParams] Datatype.\
--- **Does not serialize the FilterDescendantsInstances.**

-- --- @class RaycastParams

--- @function RaycastParams
--- @within Squish
--- @tag RobloxType
--- @return SerDes<RaycastParams>
--- Serdes for [RaycastParams] Datatype.\
--- **Does not serialize the FilterDescendantsInstances.**

-- --- @class Vector2

--- @function Vector2
--- @within Squish
--- @tag RobloxType
--- @param serdes SerDes<number> -- Optional serdes for serializing, defaults to f32.
--- @return SerDes<Vector2>
--- Serdes for [Vector2] Datatype.\
--- **Not the same as Squish.vector(2)**, this is a different datatype unfortunately.

-- --- @class PathWaypoint

--- @function PathWaypoint
--- @within Squish
--- @tag RobloxType
--- @param serdes SerDes<number>? -- Optional serdes for serializing the positional component, defaults to f32.
--- @return SerDes<PathWaypoint>
--- Serdes for [PathWaypoint] Datatype.

-- --- @class PhysicalProperties

--- @function PhysicalProperties
--- @within Squish
--- @tag RobloxType
--- @return SerDes<PhysicalProperties>
-- Serdes for [PhysicalProperties] Datatype.

-- --- @class Ray

--- @function Ray
--- @within Squish
--- @tag RobloxType
--- @param serdes SerDes<number>? -- Optional serdes for serializing, defaults to f32.
--- @return SerDes<Ray>
--- Serdes for [Ray] Datatype.

-- --- @class RaycastResult

--- @function RaycastResult
--- @within Squish
--- @tag RobloxType
--- @param serdes SerDes<number>? -- Optional serdes for serializing the positional component, defaults to f32.
--- @return SerDes<SquishRaycastResult>
--- Serdes for [RaycastResult] datatype.\
--- Returns a `SquishRaycastResult` because Roblox does not allow instantiating RaycastResults.

-- --- @class Rect

--- @function Rect
--- @within Squish
--- @tag RobloxType
--- @param serdes SerDes<number>? -- Optional serdes for serializing, defaults to f32.
--- @return SerDes<Rect>
--- Serdes for [Rect] Datatype.

-- --- @class Region3

--- @function Region3
--- @within Squish
--- @tag RobloxType
--- @param serdes SerDes<number>? -- Optional serdes for serializing, defaults to f32.
--- @return SerDes<Region3>
--- Serdes for [Region3] Datatype.

-- --- @class Region3int16

--- @function Region3int16
--- @within Squish
--- @tag RobloxType
--- @return SerDes<Region3int16>
--- Serdes for [Region3int16] Datatype.

-- --- @class RotationCurveKey

--- @function RotationCurveKey
--- @within Squish
--- @tag RobloxType
--- @param positionSerDes SerDes<number>? -- Optional serdes for serializing the positional component of the CFrame., defaults to f32.
--- @return SerDes<RotationCurveKey>
--- Serdes for [RotationCurveKey] Datatype.

-- --- @class TweenInfo

--- @function TweenInfo
--- @within Squish
--- @tag RobloxType
--- @return SerDes<TweenInfo>
--- Serdes for [TweenInfo] Datatype.

-- --- @class UDim

--- @function UDim
--- @within Squish
--- @tag RobloxType
--- @param serdes SerDes<number>? -- Optional serdes for serializing, defaults to f32.
--- @return SerDes<UDim>
--- Serdes for [UDim] Datatype.

-- --- @class UDim2

--- @function UDim2
--- @within Squish
--- @tag RobloxType
--- @param serdes SerDes<number>? -- Optional serdes for serializing, defaults to f32.
--- @return SerDes<UDim2>
--- Serdes for [UDim2] Datatype.

-- --- @class Vector2int16

--- @function Vector2int16
--- @within Squish
--- @tag RobloxType
--- @return SerDes<Vector2int16>
--- Serdes for [Vector2int16] Datatype.

-- --- @class Vector3int16

--- @function Vector3int16
--- @within Squish
--- @tag RobloxType
--- @return SerDes<Vector3int16>
--- Serdes for [Vector3int16] Datatype.

--------------------------------------------------------------------------------
-- 7. TYPEFUNCTIONS (@tag TypeFunction)
--------------------------------------------------------------------------------

--- @function UnwrapSerdes
--- @within Squish
--- @tag TypeFunction
--- @param t type -- The SerDes to extract type from.
--- @return type.
--- A type function that extracts the type serialized by the serdes.\
--- Should be used instead of [Squish:T].

--- @function T
--- @within Squish
--- @tag TypeFunction
--- @param x SerDes<T>
--- @return T
--- @deprecated Squish -- This function has been superseded by Squish.unwrapSerdes type function, which should be used instead.
--- Used for extracting the type serialized by the serdes. This is not a type function but rather a normal one.