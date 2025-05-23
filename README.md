# Custom-Enums-Utility
A lightweight and flexible custom Enum module for Roblox, enabling the creation of type-safe, structured enumerations in Luau. Designed to mimic the behavior of native Enums while allowing extended control and customization for gameplay logic, configuration flags, and clean code organization.

# CustomEnum

This module provides a custom implementation of Enums in Roblox using Luau. Unlike native Enums, `CustomEnum` allows you to define your own keys and values, attach metadata, and enforce immutability for consistency and safety across your game architecture.

## Features
- Define custom enum-like objects
- Access enum values by name or index
- Supports metadata per enum entry
- Read-only and type-safe structure
- Useful for configuration, state handling, and clear code semantics

## Example Usage
```lua
local Enum = require(path.to.CustomEnum)

local WeaponType = Enum.new("WeaponType", {
    Sword = 1,
    Bow = 2,
    Staff = 3,
})

print(WeaponType.Sword) --> 1
