local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Squish = require(ReplicatedStorage.Squish)

local function assert_result(actual, expected, success: boolean?, message)
	if not success then
		warn(message .. ": expected " .. tostring(expected) .. " --> " .. tostring(actual))
	end
end

local function assert_equal(actual, expected, message)
	return assert_result(actual, expected, actual == expected, message)
end

local function test_alloci_and_popi()
	local test_cases = {
		{push = Squish.i8().ser, pop = Squish.i8().des, value = -128},
		{push = Squish.i16().ser, pop = Squish.i16().des, value = -32768},
		{push = Squish.i24().ser, pop = Squish.i24().des, value = -8388608},
		{push = Squish.i32().ser, pop = Squish.i32().des, value = -2147483648},
		{push = Squish.i40().ser, pop = Squish.i40().des, value = -549755813888},
		{push = Squish.i48().ser, pop = Squish.i48().des, value = -140737488355328},
		{push = Squish.i56().ser, pop = Squish.i56().des, value = -36028797018963968},
		{push = Squish.i64().ser, pop = Squish.i64().des, value = -9223372036854775808},
	}

	for i, test_case in ipairs(test_cases) do
		local cursor = Squish.cursor()
		test_case.push(cursor, test_case.value)
		local result = test_case.pop(cursor)
		assert_equal(result, test_case.value, "Serialization and deserialization of int " .. i .. " failed")
	end
end

local function test_allocu_and_popu()
	local test_cases = {
		{push = Squish.u8().ser, pop = Squish.u8().des, value = 255},
		{push = Squish.u16().ser, pop = Squish.u16().des, value = 65535},
		{push = Squish.u24().ser, pop = Squish.u24().des, value = 16777215},
		{push = Squish.u32().ser, pop = Squish.u32().des, value = 4294967295},
		{push = Squish.u40().ser, pop = Squish.u40().des, value = 1099511627775},
		{push = Squish.u48().ser, pop = Squish.u48().des, value = 281474976710655},
		{push = Squish.u56().ser, pop = Squish.u56().des, value = 72057594037927935},
		{push = Squish.u64().ser, pop = Squish.u64().des, value = 18446744073709551615},
	}

	for i, test_case in ipairs(test_cases) do
		local cursor = Squish.cursor()
		test_case.push(cursor, test_case.value)
		local result = test_case.pop(cursor)
		assert_equal(result, test_case.value, "Serialization and deserialization of uint " .. i .. " failed")
	end
end

local function test_float()
	local test_cases = {
		{push = Squish.f32().ser, pop = Squish.f32().des, value = 3.14},
		{push = Squish.f64().ser, pop = Squish.f64().des, value = 2.718281828459045},
	}

	for i, test_case in ipairs(test_cases) do
		local cursor = Squish.cursor()
		test_case.push(cursor, test_case.value)
		local result = test_case.pop(cursor)
		assert_equal(result, test_case.value, "Serialization and deserialization of number " .. i .. " failed")
	end
end

local function test_allocvlq_and_popvlq()
	local test_cases = {
		{push = Squish.vlq().ser, pop = Squish.vlq().des, value = 255},
		{push = Squish.vlq().ser, pop = Squish.vlq().des, value = 65535},
		{push = Squish.vlq().ser, pop = Squish.vlq().des, value = 16777215},
		{push = Squish.vlq().ser, pop = Squish.vlq().des, value = 4294967295},
		{push = Squish.vlq().ser, pop = Squish.vlq().des, value = 1099511627775},
		{push = Squish.vlq().ser, pop = Squish.vlq().des, value = 281474976710655},
		{push = Squish.vlq().ser, pop = Squish.vlq().des, value = 72057594037927935},
		{push = Squish.vlq().ser, pop = Squish.vlq().des, value = 18446744073709551615},
	}

	for i, test_case in ipairs(test_cases) do
		local cursor = Squish.cursor()
		test_case.push(cursor, test_case.value)
		local result = test_case.pop(cursor)
		assert_equal(result, test_case.value, "Serialization and deserialization of vlq failed")
	end
end

local function test_string()
	local cursor = Squish.cursor()
	local value = "Hello, World!"
	Squish.string().ser(cursor, value)
	local result = Squish.string().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of string failed")
end

local function test_boolean()
	local cursor = Squish.cursor()
	local boolean = Squish.boolean()

	for _, v in {true, false} do 
		boolean.ser(cursor, v)
		local result = boolean.des(cursor)
		assert_equal(result, v, "Serialization and deserialization of boolean failed")
	end
end

local function test_boolpack()
	local value = { true, false, true, false, true, false, true, false }
	local cursor = Squish.cursor()
	Squish.boolpack().ser(cursor, table.unpack(value))
	local result = {Squish.boolpack().des(cursor)}
	for i = 1, 8 do
		assert_equal(result[i], value[i], "Serialization and deserialization of boolean failed")
	end
end

local function test_buffer()
	local cursor = Squish.cursor()
	local value = buffer.create(8)
	buffer.writeu32(value, 0, 12345678)
	Squish.buffer().ser(cursor, value)
	local result = Squish.buffer().des(cursor)
	assert_equal(buffer.readu32(result, 0), 12345678, "Serialization and deserialization of buffer failed")
end

local function test_axes()
	local cursor = Squish.cursor()
	local value = Axes.new(Enum.Axis.X, Enum.Axis.Y)
	Squish.Axes().ser(cursor, value)
	local result = Squish.Axes().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of axes failed")
end

local function test_brickcolor()
	local cursor = Squish.cursor()
	local value = BrickColor.new("Bright red")
	Squish.BrickColor().ser(cursor, value)
	local result = Squish.BrickColor().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of BrickColor failed")
end

local function test_rotation()
	local cursor = Squish.cursor()
	local value = CFrame.fromOrientation(1, 2, 3)
	Squish.rotation().ser(cursor, value)
	local result = Squish.rotation().des(cursor)
	assert_result(result, value, value:FuzzyEq(result, 0.01), "Serialization and deserialization of Rotation failed")
end

local function test_cframe()
	local cursor = Squish.cursor()
	local value = CFrame.new(1, 2, 3)
	Squish.CFrame(Squish.f32()).ser(cursor, value)
	local result = Squish.CFrame(Squish.f32()).des(cursor)
	assert_result(result, value, value:FuzzyEq(result), "Serialization and deserialization of CFrame failed")
end

local function test_color3()
	local cursor = Squish.cursor()
	local value = Color3.new(1, 0, 0)
	Squish.Color3().ser(cursor, value)
	local result = Squish.Color3().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of Color3 failed")
end

local function test_colorsequence()
	local cursor = Squish.cursor()
	local value = ColorSequence.new(Color3.new(1, 0, 0), Color3.new(0, 1, 0))
	Squish.ColorSequence().ser(cursor, value)
	local result = Squish.ColorSequence().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of ColorSequence failed")
end

local function test_datetime()
	local cursor = Squish.cursor()
	local value = DateTime.now()
	Squish.DateTime().ser(cursor, value)
	local result = Squish.DateTime().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of DateTime failed")
end

local function test_faces()
	local cursor = Squish.cursor()
	local value = Faces.new(Enum.NormalId.Front, Enum.NormalId.Top)
	Squish.Faces().ser(cursor, value)
	local result = Squish.Faces().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of Faces failed")
end

local function test_floatcurvekey()
	local cursor = Squish.cursor()
	local value = FloatCurveKey.new(1, 0.5, Enum.KeyInterpolationMode.Linear)
	Squish.FloatCurveKey().ser(cursor, value)
	local result = Squish.FloatCurveKey().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of FloatCurveKey failed")
end

local function test_font()
	local cursor = Squish.cursor()
	local value = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
	Squish.Font().ser(cursor, value)
	local result = Squish.Font().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of Font failed")
end

local function test_numberrange()
	local cursor = Squish.cursor()
	local value = NumberRange.new(1, 2)
	Squish.NumberRange(Squish.f32()).ser(cursor, value)
	local result = Squish.NumberRange(Squish.f32()).des(cursor)
	assert_equal(result, value, "Serialization and deserialization of NumberRange failed")
end

local function test_numbersequence()
	local cursor = Squish.cursor()
	local value = NumberSequence.new {NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }
	Squish.NumberSequence(Squish.f32()).ser(cursor, value)
	local result = Squish.NumberSequence(Squish.f32()).des(cursor)
	assert_equal(result, value, "Serialization and deserialization of NumberSequence failed")
end

local function test_ray()
	local cursor = Squish.cursor()
	local value = Ray.new(Vector3.new(0, 0, 0), Vector3.new(1, 0, 0))
	Squish.Ray(Squish.f32()).ser(cursor, value)
	local result = Squish.Ray(Squish.f32()).des(cursor)
	assert_equal(result, value, "Serialization and deserialization of Ray failed")
end

local function test_region3()
	local cursor = Squish.cursor()
	local value = Region3.new(Vector3.new(0, 0, 0), Vector3.new(1, 1, 1))
	Squish.Region3(Squish.f32()).ser(cursor, value)
	local result = Squish.Region3(Squish.f32()).des(cursor)
	assert_equal(result, value, "Serialization and deserialization of Region3 failed")
end

local function test_region3int16()
	local cursor = Squish.cursor()
	local value = Region3int16.new(Vector3int16.new(0, 0, 0), Vector3int16.new(1, 1, 1))
	Squish.Region3int16().ser(cursor, value)
	local result = Squish.Region3int16().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of Region3int16 failed")
end

local function test_rotationcurvekey()
	local cursor = Squish.cursor()
	local value = RotationCurveKey.new(1, CFrame.new(0, 0, 0), Enum.KeyInterpolationMode.Linear)
	Squish.RotationCurveKey(Squish.f32()).ser(cursor, value)
	local result = Squish.RotationCurveKey(Squish.f32()).des(cursor)
	assert_equal(result, value, "Serialization and deserialization of RotationCurveKey failed")
end

local function test_tweeninfo()
	local cursor = Squish.cursor()
	local value = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0)
	Squish.TweenInfo().ser(cursor, value)
	local result = Squish.TweenInfo().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of TweenInfo failed")
end

local function test_udim()
	local cursor = Squish.cursor()
	local value = UDim.new(1, 2)
	Squish.UDim(Squish.f32()).ser(cursor, value)
	local result = Squish.UDim(Squish.f32()).des(cursor)
	assert_equal(result, value, "Serialization and deserialization of UDim failed")
end

local function test_udim2()
	local cursor = Squish.cursor()
	local value = UDim2.new(1, 2, 3, 4)
	Squish.UDim2(Squish.f32()).ser(cursor, value)
	local result = Squish.UDim2(Squish.f32()).des(cursor)
	assert_equal(result, value, "Serialization and deserialization of UDim2 failed")
end

local function test_vector2()
	local cursor = Squish.cursor()
	local value = Vector2.new(1, 2)
	Squish.Vector2(Squish.f32()).ser(cursor, value)
	local result = Squish.Vector2(Squish.f32()).des(cursor)
	assert_equal(result, value, "Serialization and deserialization of Vector2 failed")
end

local function test_vector2int16()
	local cursor = Squish.cursor()
	local value = Vector2int16.new(1, 2)
	Squish.Vector2int16().ser(cursor, value)
	local result = Squish.Vector2int16().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of Vector2int16 failed")
end

local function test_vector3()
	local cursor = Squish.cursor()
	local value = Vector3.new(1, 2, 3)
	Squish.Vector3(Squish.f32()).ser(cursor, value)
	local result = Squish.Vector3(Squish.f32()).des(cursor)
	assert_equal(result, value, "Serialization and deserialization of Vector3 failed")
end

local function test_vector3int16()
	local cursor = Squish.cursor()
	local value = Vector3int16.new(1, 2, 3)
	Squish.Vector3int16().ser(cursor, value)
	local result = Squish.Vector3int16().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of Vector3int16 failed")
end

local function test_pathwaypoint()
	local cursor = Squish.cursor()
	local value = PathWaypoint.new(Vector3.new(1, 2, 3), Enum.PathWaypointAction.Jump, "Label")
	Squish.PathWaypoint(Squish.f32()).ser(cursor, value)
	local result = Squish.PathWaypoint(Squish.f32()).des(cursor)
	assert_equal(result, value, "Serialization and deserialization of PathWaypoint failed")
end

local function test_physicalproperties()
	local cursor = Squish.cursor()
	local value = PhysicalProperties.new(1, 2, 0.5, 4, 5)
	Squish.PhysicalProperties().ser(cursor, value)
	local result = Squish.PhysicalProperties().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of PhysicalProperties failed")
end

local function test_raycastparams()
	local cursor = Squish.cursor()
	local value = RaycastParams.new()
	value.CollisionGroup = "Default"
	value.FilterType = Enum.RaycastFilterType.Include
	value.BruteForceAllSlow = true
	value.RespectCanCollide = true
	Squish.RaycastParams().ser(cursor, value)
	local result = Squish.RaycastParams().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of RaycastParams failed")
end

local rcresult
local function test_raycastresult()
	local cursor = Squish.cursor()
	rcresult = workspace:Raycast(Vector3.new(1, 2, 3), Vector3.new(-4, -5, -6))
	assert(rcresult, `No RaycastResult`)
	Squish.RaycastResult(Squish.f32()).ser(cursor, rcresult)
	local result = Squish.RaycastResult(Squish.f32()).des(cursor)
	assert_equal(result.Distance, rcresult.Distance, "Serialization and deserialization of RaycastResult.Distance failed")
	assert_equal(result.Instance, rcresult.Instance, "Serialization and deserialization of RaycastResult.Instance failed")
	assert_equal(result.Material, rcresult.Material, "Serialization and deserialization of RaycastResult.Material failed")
	assert_equal(result.Normal, rcresult.Normal, "Serialization and deserialization of RaycastResult.Normal failed")
	assert_equal(result.Position, rcresult.Position, "Serialization and deserialization of RaycastResult.Position failed")
end

local function test_instance()
	local cursor = Squish.cursor()
	local value = workspace
	Squish.Instance().ser(cursor, value)
	local result = Squish.Instance().des(cursor)
	assert_equal(result, value, "Serialization and deserialization of Instance failed")
end

local function test_dedup()
		local cursor = Squish.cursor()
	local serdes = Squish.dedup(Squish.array(Squish.u8()))
	local t = {
		1,
		2,
		3,
		4,
		5,
	}

	for i = 1, 4 do
		serdes.ser(cursor, t)
	end

	local t1, t2, t3, t4 = serdes.des(cursor), serdes.des(cursor), serdes.des(cursor), serdes.des(cursor)
	assert_equal(t2, t1, "Serialization and deserialization of dedup [1] failed")
	assert_equal(t3, t1, "Serialization and deserialization of dedup [2] failed")
	assert_equal(t4, t1, "Serialization and deserialization of dedup [3] failed")
end

local function test_types()
	-- Types

	local cursor = Squish.cursor()
	local serdes = Squish.types(Squish.UDim2(), Squish.Vector3(), Squish.opt(Squish.boolean()), Squish.string(), Squish.u16())

	local values = {
		UDim2.new(),
		false,
		nil,
		"hello",
		535,
		Vector3.zero
	}

	for i, v in values do 
		serdes.ser(cursor, v)
		local popped = serdes.des(cursor)
		
		assert_equal(popped, v, "Serialization and deserialization of 'types' failed")
		if v ~= popped then break end
	end
end 

local function test_varnum()
	-- number

	local cursor = Squish.cursor()
	local number = Squish.number()
	for i, num in {0, 0xF, 0xFF, -0xFFF, 0xFFFF, 0xFFFFF, -0xFFFFFF, 0xFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFFFFFF, 0.5, math.huge, math.nan, -math.huge} do 
		number.ser(cursor, num)
		local v = number.des(cursor)
		
		if v ~= v and num ~= num then
			print("nan success")
			continue
		end

		assert_equal(v, num, "Serialization and deserialization of varnum (int) failed")
		if v ~= num then break end
	end

	local r = Random.new()
	local range = 0xFFFFFFFF
	for i = 1, 10000 do 
		local num = if i % 2 == 0 then r:NextNumber(-range, range) else r:NextInteger(-range, range)
		
		number.ser(cursor, num)
		local v = number.des(cursor)

		assert_equal(v, num, "Serialization and deserialization of varnum (float) failed")
		if v ~= num then break end
	end

end 

local function test_any()
	-- any 

	local values = {
		nil,
		true,
		false,
		"hello",
	--	buffer.create(16),
	--	{a = {b = true}},

		Vector3.zero,
		Vector2.zero,
		CFrame.identity,
		Ray.new(),
		Region3.new(),

		workspace,
		workspace.Terrain,
		Enum.Material.SmoothPlastic,
		Enum.PreferredInput.Touch,
		Enum.Font.Code,

		PhysicalProperties.new(1, 1, 1, 1, 1),
		PathWaypoint.new(),
		RaycastParams.new(),
		OverlapParams.new(),
		Faces.new(),
		Axes.new(),
	--	rcresult,

		Vector3int16.new(),
		Vector2int16.new(),
		Region3int16.new(),

		NumberRange.new(5),
		NumberSequenceKeypoint.new(1, 1, 1),
		NumberSequence.new(5),

		BrickColor.Red(),
		Color3.new(),
		ColorSequenceKeypoint.new(1, Color3.new()),
		ColorSequence.new(Color3.new()),

		UDim.new(),
		UDim2.new(),
		Rect.new(),
		Font.fromEnum(Enum.Font.Arimo),

		TweenInfo.new(5),
		DateTime.now(),
		CatalogSearchParams.new(),

		FloatCurveKey.new(1, 1, Enum.KeyInterpolationMode.Linear),
		RotationCurveKey.new(1, CFrame.identity, Enum.KeyInterpolationMode.Linear),
	}

	local cursor = Squish.cursor()
	local any = Squish.any()
	for _, v in values do 
		any.ser(cursor, v)
		local result = any.des(cursor)
		
		assert_equal(result, v, "Serialization and deserialization of 'any' failed")
		if v ~= result then break end
	end
end

local function run_tests()
	test_alloci_and_popi()
	test_allocu_and_popu()
	test_allocvlq_and_popvlq()
	test_float()
	test_string()
	test_boolpack()
	test_buffer()
	test_axes()
	test_brickcolor()
	test_rotation()
	test_cframe()
	test_color3()
	test_colorsequence()
	test_datetime()
	test_faces()
	test_floatcurvekey()
	test_font()
	test_numberrange()
	test_numbersequence()
	test_ray()
	test_region3()
	test_region3int16()
	test_rotationcurvekey()
	test_tweeninfo()
	test_udim()
	test_udim2()
	test_vector2()
	test_vector2int16()
	test_vector3()
	test_vector3int16()
	test_pathwaypoint()
	test_physicalproperties()
	test_raycastparams()
	test_raycastresult()
	test_instance()
	test_boolean()
	test_dedup()
	test_varnum()
	test_types()
	test_any()
	print("All tests passed!")
end

run_tests()

local cursor = Squish.cursor()
local vlqarray = Squish.array(Squish.vlq())
local arr = {}

for i = 1, 1000 do 
	arr[i] = 2^(7 * (i % 8)) + i
end

vlqarray.ser(cursor, arr)
local result = vlqarray.des(cursor)
for i, v in arr do 
	assert(v == result[i], `{v} ~= {result[i]}`)
end
-- 547359474

----* Base Conversion

local x = 'Hello, world!'
local alphabet = Squish.string.alphabet(x)
print(alphabet)
--  !,Hdelorw
local y = Squish.string.convert(x, alphabet, Squish.string.utf8)
print(y)
-- >q#�
print(Squish.string.convert(y, Squish.string.utf8, alphabet))
-- 'Hello, world!'

local y = Squish.string.convert('great sword', Squish.string.lower .. ' ', Squish.string.utf8)
print(y)
-- �zvFV�
print(Squish.string.convert(y, Squish.string.utf8, Squish.string.lower .. ' '))
-- 'great sword'

local y = Squish.string.convert('lowercase', Squish.string.lower, Squish.string.upper)
print(y)
-- LOWERCASE
print(Squish.string.convert(y, Squish.string.upper, Squish.string.lower))
-- lowercase

local y = Squish.string.convert('123', Squish.string.decimal, Squish.string.binary)
print(y)
-- 1111011
print(Squish.string.convert(y, Squish.string.binary, Squish.string.octal))
-- 173
print(Squish.string.convert(y, Squish.string.binary, Squish.string.decimal))
-- 123
print(Squish.string.convert(y, Squish.string.binary, Squish.string.duodecimal))
-- A3
print(Squish.string.convert(y, Squish.string.binary, Squish.string.hexadecimal))
-- 7B
print(Squish.string.convert(y, Squish.string.binary, Squish.string.utf8))
-- {

--* Arrays

local cursor = Squish.cursor()
Squish.array(Squish.f32()).ser(cursor, {1, 2, 3, 4, 5.5, 6.6, -7.7, -8.9, 10.01})
Squish.print(cursor)
-- Pos: 37 / 40
-- Buf: { 0 0 128 63 0 0 0 64 0 0 64 64 0 0 128 64 0 0 176 64 51 51 211 64 102 102 246 192 102 102 14 193 246 40 32 65 137 0 0 0 }
--                                                                                                                         ^
print(Squish.array(Squish.f32()).des(cursor))
-- {
--    [1] = 1,
--    [2] = 2,
--    [3] = 3,
--    [4] = 4,
--    [5] = 5.5,
--    [6] = 6.599999904632568,
--    [7] = -7.699999809265137,
--    [8] = -8.899999618530273,
--    [9] = 10.01000022888184
-- }

local cursor = Squish.cursor()
Squish.array(Squish.boolean()).ser(cursor, {true, true, true, false, false, true, false, false, false, true, true, true, true, false, false, false, true})
Squish.print(cursor)
-- Pos: 4 / 8
-- Buf: { 39 30 1 17 0 0 0 0 }
--                   ^
print(Squish.array(Squish.boolean()).des(cursor))

local arr = Squish.array
local float = Squish.f32()
local myarr = arr(float, 8)

local cursor = Squish.cursor()
myarr.ser(cursor, {1, 2, 3, 4, 5.5, 6.6, -7.7, -8.9, 10.01})
Squish.print(cursor)
-- Pos: 32 / 40
-- Buf: { 0 0 128 63 0 0 0 64 0 0 64 64 0 0 128 64 0 0 176 64 51 51 211 64 102 102 246 192 102 102 14 193 0 0 0 0 0 0 0 0 }
--                                                                                                        ^
print(myarr.des(cursor))
-- {
--    [1] = 1,
--    [2] = 2,
--    [3] = 3,
--    [4] = 4,
--    [5] = 5.5,
--    [6] = 6.599999904632568,
--    [7] = -7.699999809265137,
--    [8] = -8.899999618530273,
-- }

--* Maps

local vec3 = Squish.Vector3
local vec2 = Squish.Vector2
local mymap = Squish.map(vec2(Squish.u16()), vec3(Squish.u24()))

local cursor = Squish.cursor()
mymap.ser(cursor, {
	[Vector2.new(1, 2)] = Vector3.new(1, 2, 3),
	[Vector2.new(4, 29)] = Vector3.new(4, 29, 33),
	[Vector2.new(72, 483)] = Vector3.new(72, 483, 555),
})
Squish.print(cursor)
-- Pos: 40 / 40
-- Buf: { 43 2 0 227 1 0 72 0 0 227 1 72 0 33 0 0 29 0 0 4 0 0 29 0 4 0 3 0 0 2 0 0 1 0 0 2 0 1 0 131   }
--                                                                                                    ^
print(mymap.des(cursor))
-- {
--    [Vector2(24346692898)] = 72, 483, 555,
--    [Vector2(243466928B0)] = 4, 29, 33,
--    [Vector2(243466928C8)] = 1, 2, 3
-- }

--* Records

local vlq = Squish.vlq()
local bool = Squish.boolean()
local str = Squish.string()
local float = Squish.f32()
local vec2 = Squish.Vector2
local arr = Squish.array
local map = Squish.map
local opt = Squish.opt
local record = Squish.record

local playerserdes = record {
	position = vec2(float),
	health = Squish.u8(),
	name = str,
	poisoned = bool,
	grappled = bool,
	conscious = bool,
	items = arr(record {
		count = vlq,
		name = str,
	}),
	inns = map(str, bool),
	equipped = opt(str),
}

local cursor = Squish.cursor()
playerserdes.ser(cursor, {
	position = Vector2.new(287.3855, -13486.3),
	health = 9,
	name = "Cedrick",
	poisoned = true,
	grappled = true,
	conscious = false,
	items = {
		{ name = 'Lantern', count = 2 },
		{ name = 'Waterskin', count = 1 },
		{ name = 'Map', count = 4 },
	},
	inns = {
		['The Copper Cauldron'] = true,
		Infirmary = true,
		['His Recess'] = true,
	},
	equipped = nil,
})
Squish.print(cursor)
-- Pos: 90 / 90
-- Buf: { 6 0 9 1 72 105 115 32 82 101 99 101 115 115 138 1 84 104 101 32 67 111 112 112 101 114 32 67 97 117 108 100 114 111 110 147 1 73 110 102 105 114 109 97 114 121 137 131 130 76 97 110 116 101 114 110 135 129 87 97 116 101 114 115 107 105 110 137 132 77 97 112 131 131 67 101 100 114 105 99 107 135 51 185 82 198 88 177 143 67   }
--                                                                                                                                                                                                                                                                                                                                            ^                                                                                                                                                                                                                                                                                                                                     ^
print(playerserdes.des(cursor))
-- {
--     ["health"] = 9,
--     ["inns"] =  ▼  {
--        ["His Recess"] = true,
--        ["Infirmary"] = true,
--        ["The Copper Cauldron"] = true
--     },
--     ["items"] =  ▼  {
--        [1] =  ▼  {
--           ["count"] = 2,
--           ["name"] = "Lantern"
--        },
--        [2] =  ▼  {
--           ["count"] = 1,
--           ["name"] = "Waterskin"
--        },
--        [3] =  ▼  {
--           ["count"] = 4,
--           ["name"] = "Map"
--        }
--     },
--     ["name"] = "Cedrick",
--     ["poisoned"] = true,
--     ["position"] = 287.385498, -13486.2998
--  }

--* Literals

local literal = Squish.literal("a", 2, "c", true, "e")

local cursor = Squish.cursor()
literal.ser(cursor, "c")
Squish.print(cursor)
-- Pos: 1 / 8
-- Buf: { 2 0 0 0 0 0 0 0 }
--          ^
print(literal.des(cursor))
-- "c"

--* Tuples

local S = Squish

local mytuple = S.tuple(
	S.Vector3(S.f64()),
	S.CFrame(S.i8()),
	S.BrickColor(),
	S.EnumItem(Enum.HumanoidStateType)
)

local cursor = S.cursor()
mytuple.ser(cursor, Vector3.new(123456789, 1, 0), CFrame.new(1, 2, 3), BrickColor.new(93), Enum.HumanoidStateType.Freefall)
Squish.print(cursor)
-- Pos: 40 / 40
-- Buf: { 0 0 0 0 0 0 0 0 0 0 0 0 0 0 240 63 0 0 0 96 52 111 157 65 1 0 0 64 64 0 0 0 64 0 0 128 63 194 0 134   }
--                                                                                                            ^
print(mytuple.des(cursor))
-- 123456792, 1, 0 1, 2, 3, 1, 0, 0, 0, 1, 0, 0, 0, 1 Medium stone grey Enum.HumanoidStateType.Freefall

--* Tables

local serdes = Squish.table {
	number = Squish.f64(),
	string = Squish.string(),
	boolean = Squish.boolean(),
	table = Squish.table {
		CFrame = Squish.CFrame(Squish.f32()),
		Vector3 = Squish.Vector3(Squish.i16()),
		number = Squish.vlq(),
	},
}

local cursor = Squish.cursor()
serdes.ser(cursor, {
	wow = -5.352345,
	[23846.4522] = true,
	[false] = 'Gaming!',
	ThisWontSerialize = DateTime.now(),
	[{
		CFrame.new(-24.2435, 2, 3), CFrame.new(), Vector3.new(354, -245, -23),
		[100] = Vector3.zAxis,
		[Vector3.zero] = 255,
	}] = {
		[1] = CFrame.identity,
		[2] = Vector3.zero,
		[3] = 256,
	},
})
Squish.print(cursor)
-- Pos: 131 / 135
-- Buf: { 71 97 109 105 110 103 33 135 1 0 2 240 162 175 32 205 104 21 192 0 119 111 119 131 1 1 2 208 68 216 240 156 73 215 64 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 129 0 0 0 0 0 0 0 2 130 0 130 0 0 131 0 131 3 1 0 0 64 64 0 0 0 64 176 242 193 193 1 129 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 130 0 233 255 11 255 98 1 2 131 0 129 127 0 0 0 0 0 0 0 2 1 0 0 0 0 0 2 228 0 133 3 132 0 0 0 0 }
--                                                                                                                                                                                                                                                                                                                                                                           ^
print(serdes.des(cursor))
-- {
--     ["wow"] = -5.352345,
--     [23846.4522] = true,
--     [Table(24BE4A11A98)] =  ▼  {
--         [1] = 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1,
--         [2] = 0, 0, 0,
--         [3] = 256
--     },
--     [false] = "Gaming!"
-- }

do
	local serdes, data, n = Squish.array(Squish.u8()), { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 } :: { number }, 17
	local c = Squish.cursor()
	serdes.ser(c, data)
	Squish.print(c)
	local b = Squish.frombuffer(Squish.tobuffer(c))
	local result = serdes.des(b)
	for i = 1, n do
		assert(data[i] == result[i])
		print(i, result[i])
	end
end

do
	local serdes, data, n = Squish.array(Squish.opt(Squish.u8())), { 1, 2, nil, nil, 5, 6, 7, 8, nil, 10, 11, 12, 13, nil, 15, 16, 17 } :: { number? }, 17
	local c = Squish.cursor()
	serdes.ser(c, data)
	Squish.print(c)
	local b = Squish.frombuffer(Squish.tobuffer(c))
	local result = serdes.des(b)
	for i = 1, n do
		print(data[i], result[i], data[i] == result[i])
		assert(data[i] == result[i])
	end
end

do
	local serdes, data, n = Squish.array(Squish.boolean(), 17), { true, true, false, true, false, false, false, true, false, true, false, true, false, true, false, true, false } :: { boolean }, 17
	local c = Squish.cursor()
	serdes.ser(c, data)
	Squish.print(c)
	local b = Squish.frombuffer(Squish.tobuffer(c))
	local result = serdes.des(b)
	for i = 1, n do
		assert(data[i] == result[i])
		print(i, result[i])
	end
end

do
	local serdes, data, n = Squish.array(Squish.opt(Squish.boolean())), { true, nil, false, nil, false, nil, false, nil, false, nil, false, nil, false, nil, false, true, false } :: { boolean? }, 17
	local c = Squish.cursor()
	serdes.ser(c, data)
	Squish.print(c)
	local b = Squish.frombuffer(Squish.tobuffer(c))
	local result = serdes.des(b)
	for i = 1, n do
		assert(data[i] == result[i])
		print(i, result[i])
	end
end

do
	local T = Squish.T
	local B = Squish.boolean()
	local O = Squish.opt
	local U = Squish.u8()

	local s = {
		a = B,
		b = B,
		c = B,
		d = B,
		e = B,
		f = B,
		g = B,
		h = B,
		i = B,

		j = O(U),
		k = O(U),
		l = O(U),
		m = O(U),
		n = O(U),
		o = O(U),
		p = O(U),
		q = O(U),
		r = O(U),

		s = O(B),
		t = O(B),
		u = O(B),
		v = O(B),
		w = O(B),
		x = O(B),
		y = O(B),
		z = O(B),
		aa = O(B),
	}

	local n, serdes, data = 1e4, Squish.record(s), {
		a = true,
		b = false,
		c = true,
		d = false,
		e = true,
		f = false,
		g = true,
		h = false,
		i = true,

		j = 1,
		k = 2,
		l = 3,
		m = 4,
		n = nil,
		o = 6,
		p = 7,
		q = 8,
		r = 9,

		s = true,
		t = false,
		u = nil,
		v = true,
		w = false,
		x = nil,
		y = true,
		z = false,
		aa = true,
	}

	do
		local c = Squish.cursor()
		serdes.ser(c, data)
		Squish.print(c)
		local b = Squish.tobuffer(c)
		local c = Squish.frombuffer(b)
		local t = serdes.des(c)

		local ks = {}
		for k in t do
			table.insert(ks, k :: string)
		end
		table.sort(ks, function(a, b) return if a:len() < b:len() then true elseif a:len() > b:len() then false else a < b end)
		for _, k in ks do
			assert(data[k] == t[k])
			print(k, t[k])
		end
	end

	do

		print("\n")
		print("Record")
		print("\n")
		
		local sqTest = S.record {
			x = S.u16(),
			y = S.u16(),
			z = S.u16(),
			w = S.record {
				x = S.u16(),
				y = S.u16(),
				z = S.u16(),
				s1 = S.string(),
				s2 = S.string(),
				s3 = S.string(),
			},
			u = S.boolean(),
			v = S.boolean(),
		}

		local tbl = {
			x = 1,
			y = 2,
			z = 3,
			w = {
				x = 4,
				y = 6,
				z = 8,
				s1 = 'hello',
				s2 = 'world',
				s3 = 'help',
			},
			u = false,
			v = true,
		}

		local c = S.cursor()
		sqTest.ser(c, tbl)
		local b = S.tobuffer(c)
		local c = S.frombuffer(b)
		
		local res = sqTest.des(c)
		
		print(tbl, res)

		for k, v in res do
			if type(v) == "table" then
				print("-> table", k)
				local otherv = tbl[k]
				
				for l, u in v do
					assert(otherv[l] == u)
					print(`\t`, otherv[l], u)
				end
			else
				assert(tbl[k] == v)
				print(k, v)
			end
		end
	end
end
