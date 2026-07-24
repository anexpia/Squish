---
sidebar_position: 3
---

# How To Serialize?

Every byte can represent 256 possible values. We can represent 256^2 = 65536 possible values with 2 bytes, 256^3 = 16777216 possible values with 3 bytes, and so on. There are many ways to interpret these bytes depending on context which is the key to serialization. All serialization does is turn information into data, in this case datatype instances to buffers. If used smartly, less data can be used to represent the same information which is what Squish exploits as much as possible.

## Cursors

Buffers themselves are **statically sized**, which means that when a buffer is created it cannot be resized to fit more data. Squish uses something called a **Cursor** which wraps around buffers to treat them like **dynamically sized stacks**. This means users push and pop data off of the stack, and if it grows too big the buffer gets reallocated behind the scenes. Every serializer expects a cursor to push and pop from when serializing and deserializing. For more information, the internally used cursors - in the original project - have been extracted into a dedicated library called [Cursor](https://data-oriented-house.github.io/Cursor/).

A fun consequence of using a stack is that multiple independent serializations are allowed on the same cursor in succession. This makes fine-tuned serdes a breeze, since a user can serialize a number, then a string, then an array of vectors, and it just works!

## opt & dedup

**[opt](../api/Squish#opt)** allows you to *optionally* serialize a value as either `nil` or using the serdes provided to opt().

**[dedup](../api/Squish#dedup)** allows you to deduplicate multiple values that are identical. so serializing the same value (eg. a table present in multiple tables) will have the relatively the same size as only serializing one copy of the table. The table is also not cloned when deserializing so you won't have multiple copies of them.

## Booleans

In Luau, the `boolean` type is 1 byte large, but only 1 bit is actually necessary to store the contents of a boolean. This means we can actually serialize not just 1, but 8 booleans in a single byte. This is a common strategy called *bit-packing* to implement [*bit-fields*](https://en.wikipedia.org/wiki/Bit_field).

| Happy | Confused | Irritated | Concerned | Angry | Humber | Dazed | Nage |
| - | - | - | - | - | - | - | - |
| 1 | 1 | 0 | 1 | 0 | 1 | 1 | 0 |

All of this information fits inside a single byte! We can use this to serialize 8 booleans in a single byte.\
Doing so is a little slower than storing only one boolean, so a different SerDes than **[boolean](../api/Squish#boolean)**,**[boolpack](../api/Squish#boolpack)**, exists for this purpose.

```lua
-- Using Squish.boolean().

local cursor = Squish.cursor()
Squish.boolean().ser(cursor, true)
Squish.print(cursor)
-- Pos: 1 / 8
-- Buf: { 1 0 0 0 0 0 0 0 }
--          ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.boolean().des(cursor))
-- true
```
```lua
-- Using Squish.boolpack().

local cursor = Squish.cursor(3)
Squish.boolpack().ser(cursor, true, false, true, false, true, true, false, true)
Squish.print(cursor)
--- Pos: 1 / 3
--- Buf: { 181 0 0 }
---            ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.boolpack().des(cursor))
-- true false true false true true false true
```

## Numbers

In Luau, the `number` type is 8 bytes large, but only 52 of the bits are dedicated to storing the contents of an integer. After this threshold, the spacing between numbers is larger than 1, and integers begin skipping. At 7 and 8 bytes, integers may or may not be represented properly anymore.

### Unsigned Integers

Unsigned integers are whole numbers that can be serialized using 1 to 8 bytes.

***N = &#123; 0, 1, 2, 3, 4, 5, . . . &#125;***

They may only be positive and can represent all possible permutations of their bits. These are the easiest to wrap our heads around and manipulate. They are often used to implement [Fixed Point](https://en.wikipedia.org/wiki/Fixed-point_arithmetic) numbers by multiplying by some scale factor and shifting by some offset, then doing the reverse when deserializing.

| Bytes | Range | Min | Max |
| - | - | - | - |
| ***1*** | **&#123; 0, 1, 2, 3, . . . , 253, 254, 255 &#125;** | ***0*** | ***255*** |
| ***2*** | **&#123; 0, 1, 2, 3, . . . , 65,534, 65,535 &#125;** | ***0*** | ***65,535*** |
| ***3*** | **&#123; 0, 1, 2, 3, . . . , 16,777,214, 16,777,215 &#125;** | ***0*** | ***16,777,215*** |
| . . . | . . . | . . . | . . . |
| ***n*** | **&#123; 0, 1, 2, 3, . . . , 2^(8n) - 2, 2^(8n) - 1 &#125;** | ***0*** | ***2^(8n) - 1*** |

**WARNING:** Using 7 or 8 bytes puts uints outside the 52 bit range of representation, leading to inaccurate results.

```lua
local cursor = Squish.cursor()
Squish.u8().ser(cursor, 243)
Squish.print(cursor)
-- Pos: 1 / 8
-- Buf: { 243 0 0 0 0 0 0 0 }
--            ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.u8().des(cursor))
-- 243
```
```lua
local cursor = Squish.cursor(1)
Squish.u8().ser(cursor, -13)
Squish.print(cursor)
-- Pos: 1 / 1
-- Buf: { 243   }
--            ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.u8().des(cursor))
-- 243
```
```lua
local cursor = Squish.cursor(4, 1)
Squish.u16().ser(cursor, 7365)
Squish.print(cursor)
-- Pos: 3 / 4
-- Buf: { 0 197 28 0 }
--                 ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.u16().des(cursor))
-- 7365
```

### Signed Integers

Signed Integers are Integers that can be serialized with 1 through 8 bytes:

***Z = &#123; ..., -2, -1, 0, 1, 2, 3, ... &#125;***

They use [2's Compliment](https://en.wikipedia.org/wiki/Two%27s_complement) to represent negative numbers. The first bit is called the *sign bit* and the rest of the bits are called the *magnitude bits*. The sign bit is 0 for positive numbers and 1 for negative numbers. This implies the range of signed integers is one power of two smaller than the range of unsigned integers with the same number of bits, because the sign bit is not included in the magnitude bits.

| Bytes | Range | Min | Max |
| - | - | - | - |
| ***1*** | **&#123; -128, -127, . . . , 126, 127 &#125;** | ***-128*** | ***127*** |
| ***2*** | **&#123; -32,768, -32,767, . . . , 32,766, 32,767 &#125;** | ***-32,768*** | ***32,767*** |
| ***3*** | **&#123; -8,388,608, -8,388,607, . . . , 8,388,606, 8,388,607 &#125;** | ***-8,388,608*** | ***8,388,607*** |
| . . . | . . . | . . . | . . . |
| ***n*** | **&#123; -2^(8n - 1), -2^(8n - 1) + 1, . . . , 2^(8n - 1) - 2, 2^(8n - 1) - 1 &#125;** | ***-2^(8n - 1)*** | ***2^(8n - 1) - 1*** |

**WARNING:** Using 7 or 8 bytes puts ints outside the 52 bit range of representation, leading to inaccurate results.

```lua
local cursor = Squish.cursor()
Squish.i8().ser(cursor, 127)
Squish.print(cursor)
-- Pos: 1 / 8
-- Buf: { 127 0 0 0 0 0 0 0 }
--            ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.i8().des(cursor))
-- 127
```
```lua
local cursor = Squish.cursor()
Squish.i8().ser(cursor, -127)
Squish.print(cursor)
-- Pos: 1 / 8
-- Buf: { 129 0 0 0 0 0 0 0 }
--            ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.i8().des(cursor))
-- -127
```
```lua
local cursor = Squish.cursor()
Squish.i8().ser(cursor, 128)
Squish.print(cursor)
-- Pos: 1 / 8
-- Buf: { 128 0 0 0 0 0 0 0 }
--            ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.i8().des(cursor))
-- -128
```
```lua
local cursor = Squish.cursor()
Squish.i8().ser(cursor, -128)
Squish.print(cursor)
-- Pos: 1 / 8
-- Buf: { 128 0 0 0 0 0 0 0 }
--            ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.i8().des(cursor))
-- -128
```

### Floating Point

Floating Point Numbers are Rational Numbers that can be represented with either 4 or 8 bytes:

***Q = &#123; ..., -2.0, ..., -1.0, ..., 0.0, ..., 1.0, ..., 2.0, ... &#125;***

With 4 bytes (called a `float`), the possible values that can be represented are a bit more complicated. The first bit is used to represent the sign of the number, the next 8 bits are used to represent the exponent, and the last 23 bits are used to represent the mantissa.

![Floating Point](/floatingpoint.png)

The formula for calculating the value of a `float` from its sign, exponent, and mantissa can be found at [this wikipedia article](https://en.wikipedia.org/wiki/Single-precision_floating-point_format).

With 8 bytes (called a `double`). The first bit is used to represent the sign of the number, the next 11 bits are used to represent the exponent, and the last 52 bits are used to represent the mantissa.

![Double Precision Floating Point](/floatingpointdouble.png)

The formula for calculating the value of a `double` from its sign, exponent, and mantissa can be found at [this wikipedia article](https://en.wikipedia.org/wiki/Double-precision_floating-point_format).

```lua
local cursor = Squish.cursor()
Squish.f32().ser(cursor, 174302.923957475339573)
Squish.print(cursor)
-- Pos: 4 / 8
-- Buf: { 187 55 42 72 0 0 0 0 }
--                     ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.f32().des(cursor))
-- 174302.921875
```
```lua
local cursor = Squish.cursor()
Squish.f64().ser(cursor, -17534840302.923957475339573)
Squish.print(cursor)
-- Pos: 8 / 8
-- Buf: { 34 178 187 183 161 84 16 194   }
--                                     ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.f64().des(cursor))
-- -17534840302.923958
```

### [Variable Length Quantities](https://en.wikipedia.org/wiki/Variable-length_quantity)

Sometimes we don't know how many bytes we need to represent a number, or we need to represent a number so large that 8 bytes isn't enough. This is where **[VLQS](../api/Squish#vlq)**  come in. They are a binary format to represent arbitrarily large numbers as a sequence of bytes. 7 bits encode the number, 1 bit encodes the end of the number. This means 127 serializes to 1 byte. 128 serializes to 2 bytes. It increments by powers of 128 instead of 256 like bytes do because of the missing bit.

```lua
local cursor = Squish.cursor()
Squish.vlq().ser(cursor, 10)
Squish.print(cursor)
-- Pos: 1 / 8
-- Buf: { 138 0 0 0 0 0 0 0 }
--            ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.vlq().des(cursor))
-- 10
```
```lua
local cursor = Squish.cursor()
Squish.vlq().ser(cursor, 130)
Squish.print(cursor)
-- Pos: 2 / 8
-- Buf: { 129 2 0 0 0 0 0 0 }
--              ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.vlq().des(cursor))
-- 130
```
```lua
local cursor = Squish.cursor()
Squish.vlq().ser(cursor, 547359474)
Squish.print(cursor)
-- Pos: 5 / 8
-- Buf: { 130 5 0 21 114 0 0 0 }
--                       ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.vlq().des(cursor))
-- 547359474
```

### Variable Numbers
Sometimes, even VLQ is incapable of representing the numbers you are providing (eg. negative, float numbers).\
For these cases, a different Serdes (**[number](../api/Squish#number)**) is provided to fulfill this use-case with support for the aforementioned type of numbers.

```lua
local num = Squish.number(0)
local cursor = Squish.cursor()

for _, x in {10, -4.35, math.nan, math.huge, 0, 2^32, 1e+300, -10000} do 
   num.ser(cursor, xx)
   print(num.des(cursor))
end

--[[ Will print the following
    10
    -4.35
    NaN
    inf
    0
    2^32
    1e+300
    -10000
]]
```

### Ranges

A **[range](../api/Squish#range)** is a custom datatype that encodes an integer inverval `[a, b]` using uints with as few bytes as possible. This is great if you know your lower and upper bounds for array sizes or other lists. It is not strict and will technically encode outside of bounds.

```lua
local cursor = Squish.cursor()
Squish.range(100, 150).ser(cursor, 130)
Squish.print(cursor)
-- Pos: 1 / 8
-- Buf: { 30 0 0 0 0 0 0 0 }
--           ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.range(100, 150).des(cursor))
-- 130
```
```lua
local cursor = Squish.cursor()
Squish.range(1, 15).ser(cursor, 16)
Squish.print(cursor)
-- Pos: 1 / 8
-- Buf: { 16 0 0 0 0 0 0 0 }
--           ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.range(1, 15).des(cursor))
-- 16
```

## Strings

Strings are a bit trickier conceptually since they have a variable size. However to serialize with Squish is actually easier than numbers! Every character is a byte, so it is useful to think of strings are arrays of bytes. After writing each character in sequence, we need a mechanism to count how many characters we've serialized else we'll never know when to stop reading when deserializing. Right after the string, the length is serialized as a [Variable Length Quantity](https://en.wikipedia.org/wiki/Variable-length_quantity) to use only necessary bytes.

```lua
local cursor = Squish.cursor()
Squish.string().ser(cursor, "Hello, World!")
Squish.print(cursor)
-- Pos: 14 / 18
-- Buf: { 72 101 108 108 111 44 32 87 111 114 108 100 33 141 0 0 0 0 }
--                                                           ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.string().des(cursor))
-- Hello, World!
```

```lua
local cursor = Squish.cursor()
Squish.string(13).ser(cursor, "Hello, World!")
Squish.print(cursor)
-- Pos: 13 / 18
-- Buf: { 72 101 108 108 111 44 32 87 111 114 108 100 33 0 0 0 0 0 }
--                                                       ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(Squish.string(13).des(cursor))
-- Hello, World!
```

### Using Base Conversion

There are many ways to compress serialized strings, a lossless approach is to treat the string itself as a number and convert the number into a higher base, or radix. This is called [base conversion](https://en.wikipedia.org/wiki/Radix). Strings come in many different *flavors* though, so we need to know how to serialize each *flavor*. Each string is composed of a sequence of certain characters. The set of those certain characters is called that string's smallest **Alphabet**. For example the string ***"Hello, World!"*** has the alphabet ***" !,HWdelorw"***. We can assign a number to each character in the alphabet like its position in the string. With our example:
```lua
{
	[' '] = 1, ['!'] = 2, [','] = 3, ['H'] = 4, ['W'] = 5,
	['d'] = 6, ['e'] = 7, ['l'] = 8, ['o'] = 9, ['r'] = 10,
	['w'] = 11,
}
```
This allows us to now calculate a numerical value for each string using [Positional Notation](https://en.wikipedia.org/wiki/Positional_notation). The alphabet above has a radix of 11, so we can convert the string into a number with base 11. We can then use the base conversion formula, modified to work with strings, to convert the number with a radix 11 alphabet into a number with a radix 256 alphabet such as extended ASCII or UTF-8. To prevent our numbers from being shortened due to leading 0's, we have to use an extra character in our alphabet in the 0's place that we never use, such as the \0 character, making our radix 12. Long story short, you can fit ***log12(256) = 2.23*** characters from the original string into a single character in the new string. This proccess is invertible and lossless, so we can convert the serialized string back into the original string when we are ready. To play with this concept for arbitrary alphabets, you can visit [Zamicol's Base Converter](https://convert.zamicol.com/) which supports these exact operations and comes with many pre-defined alphabets.
```lua
local x = 'Hello, world!'
local alphabet = Squish.string.alphabet(x)
print(alphabet)
--  !,Hdelorw
local y = Squish.string.convert(x, alphabet, Squish.string.utf8)
print(y)
-- >q#�
print(Squish.string.convert(y, Squish.string.utf8, alphabet))
-- 'Hello, world!'
```
```lua
local y = Squish.string.convert('great sword', Squish.string.lower .. ' ', Squish.string.utf8)
print(y)
-- �zvFV�
print(Squish.string.convert(y, Squish.string.utf8, Squish.string.lower .. ' '))
-- 'great sword'
```
```lua
local y = Squish.string.convert('lowercase', Squish.string.lower, Squish.string.upper)
print(y)
-- LOWERCASE
print(Squish.string.convert(y, Squish.string.upper, Squish.string.lower))
-- lowercase
```
```lua
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
```

## Literals

**[Literal](../api/Squish#literal)**s are individual values that can be enumerated and distinguished using just `u1`s. This is useful for encoding enums of names, orientations, and other unique identifiers with minimal data.

```lua
local literal = Squish.literal({ "a", 2, "c", true, "e" })

local cursor = Squish.cursor()
literal.ser(cursor, "c")
Squish.print(cursor)
-- Pos: 1 / 8
-- Buf: { 2 0 0 0 0 0 0 0 }
--          ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(literal.des(cursor))
-- "c"
```

## Tuples

**[Tuple](../api/Squish#tuple)** types `(T...)` are like arrays but not wrapped in a table, and each element can be a different type. Tuples cannot be used in table types, and cannot be nested in other tuples.

```lua
local S = Squish
local T = S.T

local mytuple = S.tuple(
    S.Vector3(S.f64()),
    S.CFrame(S.i8()),
    S.BrickColor(),
    S.EnumItem(Enum.HumanoidStateType)
)

local cursor = S.cursor()
mytuple.ser(cursor, Vector3.new(123456789, 1, 0), CFrame.new(1, 2, 3), BrickColor.new(93), Enum.HumanoidStateType.Freefall)
S.print(cursor)
-- Pos: 40 / 40
-- Buf: { 0 0 0 0 0 0 0 0 0 0 0 0 0 0 240 63 0 0 0 96 52 111 157 65 1 0 0 64 64 0 0 0 64 0 0 128 63 194 0 134   }
--                                                                                                            ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(mytuple.des(cursor))
-- 123456792, 1, 0 1, 2, 3, 1, 0, 0, 0, 1, 0, 0, 0, 1 Medium stone grey Enum.HumanoidStateType.Freefall
```

## Multiple Types

Multiple SerDes can be combined into one that supports all provided Serdes using **[variant](../api/Squish#variant)**.\
This is useful if your value can be of multiple types. It also supports literals if needed.

If a type is provided when serializing which wasn't added to the constructor, it will error unless **[opt](../api/Squish#opt) or [Nil](../api/Squish#Nil)** were provided.

 ```lua
local cursor = Squish.cursor()
local variantSerdes = Squish.variant({ Squish.number(), Squish.string() }, {true})

variantSerdes.ser(cursor, 5)
print(variantSerdes.des(cursor)) -- prints 5

variantSerdes.ser(cursor, "Hello!")
print(variantSerdes.des(cursor)) -- prints "Hello!"

variantSerdes.ser(cursor, true) -- prints true, because it is added as a literal.
variantSerdes.ser(cursor, false) -- will error unless Squish.Nil() is provided to the constructor.

```

## any

**[any](../api/Squish#any)** is a serdes that accepts every datatype with the exception of `table`.\
You should only ever use this if you cannot guarantee the type of your values and **[Squish:variant](../api/Squish#variant)** wouldn't be fit for your purposes.

```lua
local values = {
	nil,
	true,
	false,
	"meow",

	Vector3.zero,
	CFrame.identity,
	workspace,

	Color3.new(),
	DateTime.now(),
}

local cursor = Squish.cursor()
local anyArray = Squish.array(Squish.any())

anyArray.ser(cursor, values)
print(anyArray.des(cursor)) -- will print an identical array to the 'values' one.

```

## Arrays

**[Array](../api/Squish#array)**s are a classic table type `{T}`. Like strings, which are also arrays (of bytes), after serializing every element in sequence we append a VLQ representing the count. An array can store an array or any other table type.

```lua
local arr = Squish.array
local float = Squish.f32()
local myarr = arr(float)

local cursor = Squish.cursor()
myarr.ser(cursor, {1, 2, 3, 4, 5.5, 6.6, -7.7, -8.9, 10.01})
Squish.print(cursor)
-- Pos: 37 / 40
-- Buf: { 0 0 128 63 0 0 0 64 0 0 64 64 0 0 128 64 0 0 176 64 51 51 211 64 102 102 246 192 102 102 14 193 246 40 32 65 137 0 0 0 }
--                                                                                                                         ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(myarr.des(cursor))
-- 1 2 3 4 5.5 6.599999904632568 -7.699999809265137 -8.899999618530273 10.01000022888184
```

```lua
local arr = Squish.array
local float = Squish.f32()
local myarr = arr(float, 8)

local cursor = Squish.cursor()
myarr.ser(cursor, {1, 2, 3, 4, 5.5, 6.6, -7.7, -8.9, 10.01})
Squish.print(cursor)
-- Pos: 32 / 40
-- Buf: { 0 0 128 63 0 0 0 64 0 0 64 64 0 0 128 64 0 0 176 64 51 51 211 64 102 102 246 192 102 102 14 193 0 0 0 0 0 0 0 0 }
--                                                                                                        ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(myarr.des(cursor))
-- 1 2 3 4 5.5 6.599999904632568 -7.699999809265137 -8.899999618530273
```

## Maps

**[Map](../api/Squish#map)**s are a classic table type `{ [T]: U }` that map T's to U's. A map can store a map or any other table type.

```lua
local u = Squish.uint
local vec3 = Squish.Vector3
local vec2 = Squish.Vector2
local mymap = Squish.map(vec2(u(2)), vec3(u(3)))

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
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
print(mymap.des(cursor))
-- {
--    [Vector2(24346692898)] = 72, 483, 555,
--    [Vector2(243466928B0)] = 4, 29, 33,
--    [Vector2(243466928C8)] = 1, 2, 3
-- }
```

## Records

**[Record](../api/Squish#record)**s (Structs) `{ prop1: any, prop2: any, ... }` map enumerated string identifiers to different values, like a named tuple. Because all keys are string literals known ahead of time, none of them have to be serialized! A record can store a record or any other table type.

When defining compound types the code can become verbose and difficult to read. If this is an issue, it is encouraged to store each SerDes in a variable with a shorter name.

```lua
local T = Squish.T
local u = Squish.uint
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
    position = T(vec2(float)),
    health = T(u(1)),
    name = T(str),
    poisoned = T(bool),
    items = T(arr(record {
        count = T(vlq),
        name = T(str),
    })),
    inns = T(map(str, bool)),
    equipped = T(opt(str)),
}

local cursor = Squish.cursor()
playerserdes.ser(cursor, {
    position = Vector2.new(287.3855, -13486.3),
    health = 9,
    name = "Cedrick",
    poisoned = true,
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
-- Buf: { 0 9 1 72 105 115 32 82 101 99 101 115 115 138 1 84 104 101 32 67 111 112 112 101 114 32 67 97 117 108 100 114 111 110 147 1 73 110 102 105 114 109 97 114 121 137 131 130 76 97 110 116 101 114 110 135 129 87 97 116 101 114 115 107 105 110 137 132 77 97 112 131 131 67 101 100 114 105 99 107 135 1 51 185 82 198 88 177 143 67   }
--                                                                                                                                                                                                                                                                                                                                            ^
local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
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
```

## Tables

Luau tables are extremely versatile data structures that can and do implement every other kind of data structure one can think of. They are *too* versatile to optimally serialize in the general case, which is why Squish has the previously listed Array, Map, and Record serializers.

Only use this serializer if you cannot guarantee the shape of your table beforehand, as it offers less control and worse size reduction. This is the algorithm that Roblox uses when serializing tables because they can't guarantee the shape of the tables users pass. If you do not know the type of your table but you still need to serialize it, then the **[Squish.table](../api/Squish#table)** serializer is a last resort.

It has to store data for every value, the type of every value, every key, and the type of every key, which makes it significantly larger than the specialized functions. It does not offer property-specific granularity though it allows for any table structure, such as tables with circular references, mixed tables, gaps, ...

The serializer takes a single `serdes` parameter which it uses to serialize both keys and values.

```lua
local serdes = Squish.table(Squish.variant({
    Squish.f64(),
    Squish.string(),
    Squish.boolean(),
    Squish.Nil(),
    Squish.table(Squish.variant({
        Squish.CFrame(Squish.f32()),
        Squish.Vector3(Squish.i16()),
        Squish.vlq(),
    })),
}))

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

local buf = Squish.tobuffer(cursor)

local cursor = Squish.frombuffer(buf)
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
```

## UnwrapSerdes
This is a type function that's helpful for extracting the type that each SerDes uses.

```lua
local f32 = Squish.f32()
type x = typeof(f32)
-- SerDes<number>

type x2 = Squish.UnwrapSerdes<x>
-- number
```

An older deprecated function **[T](../api/Squish#T)** exists which fulfills the same purpose without relying on the new type solver.
