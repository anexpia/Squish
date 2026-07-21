---
sidebar_position: 2
---

# Differences from Squash?

This is largely similar to the Squash (it is a fork, after all). Only the important differences will be listed below.

## General Changes
- Most serdes that required a number serdes now optionally accept a serdes. and their default is `Squish.f32()`.
- Serialization now optionally checks the type of the provided parameter. This is toggled by the <b>`VALIDATIONENABLED`</b> present at the top of the script. This setting <b>should be kept false</b> if you aren't debugging as it heavily impacts performance.
- Type for many serdes such as `Squish.record()` is evaluated using a type function to make the use of `Squish.T()` obsolete. so you generally don't need to use that anymore.
- Serdes expose internal info such as their type, name, and structure data to make it easier to create custom serdes and recreate them.

:::caution

Squish is **heavily** reliant on the new type solver, thus types for many functions - particularly `Squish.table()`, `Squish.record()`, ... - will not work with the old solver.

:::

- Performance is faster for most if not all the serdes than with the base squash module.
- Exposes more namespaces that help with creating your own serdes.
    - **[Utility namespace](../api/util)**: Contains internal functions for manipulating cursor data, pushing and popping values, and allocating.\
    setpos, getpos, setbuf, getbuf, and tryrealloc were moved to this namespace.

    - **[Validation namespace](../api/validation)**: Contains functions for validating types of schemas and values.

## SerDes Changes.
Many of the SerDes were rewritten to be more performant. Below are the public-facing changes:

- [ **NEW** ] **[number](../api/Squish#number)**: Serdes accepting any number of any size.
- [ **NEW** ] **[Nil](../api/Squish#Nil)**: Serdes for.. nil.
- [ **NEW** ] **[dedup](../api/Squish#dedup)**: Serdes that deduplicates serialized values.
- [ **NEW** ] **[Color3f16](../api/Squish#Color3f16)**: Serdes for color3, but not restricted to \[0-255] range.
- [ **NEW** ] **[Instance](../api/Squish#Instance)**: Serdes for Instances.
- [ **NEW** ] **[variant](../api/Squish#variant)**: Serdes for multiple types and literals combined.
- [ **NEW** ] **[any](../api/Squish#any)**: Serdes for any type.
- [ **NEW** ] **[anyFrom](../api/Squish#anyFrom)**: Internal serdes used by **any** and **variant**, exposed so you can use it if needed.
- [ **NEW** ] **[addserdes](../api/Squish#addserdes) function**: Adds provided serdes' to a **variant** or **any** serdes's registry.
- [ **NEW** ] **[addliterals](../api/Squish#addliterals) function**: Adds new literals to a **variant**, **any**, or **literal** serdes's registry.

- [ **CHANGE** ] **[boolean](../api/Squish#boolean)**:\
    Only accepts one boolean parameter, original behavior has been moved to **[boolpack](../api/Squish#boolpack)**.

- [ **CHANGE** ] **[range](../api/Squish#range)**:\
    Added 2 new parameters:
    - `SerDes`: Defines which SerDes to use for serializing the numbers, overriding original.
    - `restricted`: Defines whether the numbers should be clamped to the range of min - max when serializing and deserializing.

- [ **CHANGE** ] **[table](../api/Squish#table)**:\
    Replaces the old table implementation. Now accepts a single `serdes` parameter which applies to both keys and values of the table, and supports table deduplication and circular references.

- [ **CHANGE** ] **All table SerDes (array, record, ...)**\
    They now accept a second parameter when deserializing for an optional user-supplied table to write to instead of creating a new one.

- [ **CHANGE** ] **[vector](../api/Squish#vector)**:\
    All vector functions have been combined into a single one as the old api was confusing (eg. `Squash.vector2` and `Squash.Vector2` were not the same.)\
    By default, `Squish.vector()` will return a SerDes for the vector size currently used (4-wide) or (3-wide), You can change this by providing the `size` parameter.

    `Squish.Vector2()` still remains, however, as it is a datatype in roblox.

- [ **CHANGE** ] **[EnumItem](../api/Squish#EnumItem)**:\
    Can be provided no enum, in which case it will accept any enumitem.

- [ **CHANGE** ] **[CFrame](../api/Squish#CFrame)**:\
    Can be provided `false` in which case it will only serialize the rotational component of cframes.

    `Squish.rotation()` now acts as a wrapper for `Squish.CFrame(false)`.

- [ **CHANGE** ] **[RaycastResult](../api/Squish#RaycastResult)**:\
    Can serialize the basepart.

## Benchmarks.
The following benchmarks show performance differences between Squash 5.0.0 and Squish.