---
sidebar_position: 2
---

# Differences from Squash?

This is largely similar to the Squash (it is a fork, after all). Only the important differences will be listed below.

## General Changes
- Most serdes that required a number serdes now optionally accept a serdes. and their default is `Squish.f32()`.
- Serialization now optionally checks the type of the provided parameter. This is toggled by the <b>`VALIDATIONENABLED`</b> present at the top of the script. This setting <b>should be kept false</b> if you aren't debugging as it heavily impacts performance.
- Type for many serdes such as `Squish.record()` is evaluated using a type function to make the use of `Squish.T()` obsolete. so you generally don't need to use that anymore.

:::caution

Squish is **heavily** reliant on the new type solver, thus types for many functions - particularly `Squish.table()`, `Squish.record()`, ... - will not work with the old solver.

:::

- Performance is faster for most if not all the serdes than with the base squash module.
- Exposes more functions that help with creating your own serdes.
    - **[Squish:pushref](../api/Squish#pushref)**
    - **[Squish:popref](../api/Squish#popref)**
    - **[validation.scopesEnabled](../api/validation#scopesEnabled)**
    - **[validation:assertSchemaType](../api/validation#assertSchemaType)**
    - **[validation:assertIsSerdes](../api/validation#assertIsSerdes)**
    - **[validation:assertSerdesType](../api/validation#assertSerdesType)**
    - **[validation:assertSerializeType](../api/validation#assertSerializeType)**
    - **[validation:beginValidationScope](../api/validation#beginValidationScope)**
    - **[validation:exitValidationScope](../api/validation#exitValidationScope)**
    - **[validation:overrideValidationScopeName](../api/validation#overrideValidationScopeName)**

## SerDes Changes.

- [ **NEW** ] **[number](../api/Squish#number)**: Serdes accepting any number of any size.
- [ **NEW** ] **[Nil](../api/Squish#Nil)**: Serdes for.. nil.
- [ **NEW** ] **[dedup](../api/Squish#dedup)**: Serdes that deduplicates serialized values.
- [ **NEW** ] **[Color3f16](../api/Squish#Color3f16)**: Serdes for color3, but not restricted to \[0-255] range.
- [ **NEW** ] **[Instance](../api/Squish#Instance)**: Serdes for Instances.
- [ **NEW** ] **[types](../api/Squish#types)**: Serdes for multiple types.
- [ **NEW** ] **[any](../api/Squish#any)**: Serdes for any type, except tables.

- [ **CHANGE** ] **[boolean](../api/Squish#boolean)**:\
    Only accepts one boolean parameter, original behavior has been moved to **[boolpack](../api/Squish#boolpack)**.

- [ **CHANGE** ] **[range](../api/Squish#range)**:\
    Added 2 new parameters:
    - `SerDes`: Defines which SerDes to use for serializing the numbers, overriding original.
    - `restricted`: Defines whether the numbers should be clamped to the range of min - max when serializing and deserializing.

- [ **CHANGE** ] **[table](../api/Squish#table)**:\
    Added second parameter `valueschema` (`length` is now third) for the schema of the values in the table.\
    If `valueschema` is not provided, will reuse `keyschema` for the values.

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