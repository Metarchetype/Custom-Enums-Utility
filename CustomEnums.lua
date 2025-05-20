--[[
	EnumBuilder.lua
	```````````````
    Author: @XiK_Z
    Created: May 19, 2025
    
    Description:
        A utility module for creating custom enum-like tables in Luau.
        Useful for defining and organizing fixed sets of named constants with validation support.

    Usage:
        local Colors = EnumBuilder.Create("Red", "Green", "Blue")
        print(Colors.Red) --> "Red"
        print(Colors:IsValid("Green")) --> true
]]

--[=[
	@class EnumBuilder
	Utility for creating type-safe, name-locked custom enumerations.
]=]

--[=[
	@class EnumError
	Handles internal EnumBuilder error construction and reporting.

	Provides structured, user-friendly error messages for common enum misuse patterns.
]=]
local EnumError
do
	EnumError = {
		--[=[
			@prop Kind {string}
			@within EnumError
			Represents all error kinds that can be triggered by the EnumBuilder module.
		]=]
		Kind = {
			"InvalidEnum",
			"MissingItem",
			"InvalidArguments",
			"DuplicateEnum",
			"newIndex",
			"UnsupportedError"
		}
	}
	EnumError.__index = EnumError
	--[=[
		Creates a new EnumError object.
		@within EnumError
		@param Kind string -- The type of error (must match a value from EnumError.Kind).
		@param Level number -- Stack trace level to report the error from.
		@param Trace string -- Stack trace string.
		@param Mode "warn" | "error" -- Whether to warn or error the message.
		@return EnumError -- A structured error object ready to be logged.
	]=]
	function EnumError.new(Kind, Level, Trace, Mode : "warn" | "error")
		assert(typeof(Kind) == 'string', string.format(`Error.Kind must be of type string. got %s`, typeof(Kind)))
		assert(typeof(Level) == 'number', string.format(`Error.Level must be of type number. got %s`, typeof(Level)))
		assert(typeof(Trace) == 'string', string.format(`Error.Trace must be of type string. got %s`, typeof(Trace)))
		assert(typeof(Mode) == 'string', string.format(`Error.Mode must be of type string. got %s`, typeof(Mode)))
		local Error = setmetatable({}, EnumError)
		Error.Kind = Kind
		Error.Level = Level
		Error.Trace = Trace
		Error.Mode = Mode
		return Error
	end
	--[=[
		Logs the error using either `warn` or `error`, depending on the error's mode.
		@within EnumError
		@return nil
	]=]
	function EnumError:LogError()
		if self.Kind and self.Level and self.Mode then
			local _error = string.format("[EnumBuilder] (%s), %s at line %s", self.Mode:upper(), self.Kind, self.Trace)
			if self.Mode == "warn" then warn(error) elseif self.Mode == "error" then error(_error, self.Level) end
		end
	end
end

local EnumBuilder = {}
EnumBuilder.Enums = {} :: {[string] : {[any] : any}}


--[=[
	Creates a new immutable enum table from a list of unique string values.

	@within EnumBuilder
	@param EnumName string -- Name of the enum type (used only for internal error messages).
	@param Values {string} -- Array of unique string values to include in the enum.
	@return {[string]: string} -- A frozen table where each key and value are the same string.

	@example
	local Element = EnumBuilder.Create("Element", {"Fire", "Ice", "Poison"})
	print(Element.Fire) --> "Fire"
]=]
function EnumBuilder.newEnum(enumName : string, members : {[any] : any})
	if EnumBuilder.Enums[enumName] then
		EnumError.new("DuplicateEnum", 3, debug.traceback(), "error"):LogError()
	end
	local enumProxy = newproxy(true)
	local enumMetatable = getmetatable(enumProxy)
	local enum = {}
	for index, member in pairs(members) do
		enum[index] = member
	end
	EnumBuilder.Enums[enumName] = enum
	table.freeze(enum)
	do
		enumMetatable.__index = function(_,k)
			assert(enum[k], EnumError.new("MissingItem", 3, debug.traceback(), "warn"):LogError())
			return enum[k]
		end
		enumMetatable.__newindex = function(_,k,v)
			EnumError.new("newIndex", 3, debug.traceback(), "error"):LogError()
		end
		enumMetatable.__meta = enum
		enumMetatable.__metatable = `Attempted to get the metatable of a custom enum.`
	end
	
	return enumProxy :: enum
end
--[=[
	Retrieves an enum value by key from the specified enum.

	@within EnumBuilder
	@param enumName string -- The name of the enum to search in.
	@param key string -- The key within the enum to retrieve.
	@return any -- The value stored under the given key.
	
	@throws EnumError "InvalidEnum" if the enum does not exist.
	@throws EnumError "MissingItem" if the key is not found in the enum.

	@example
	local Colors = EnumBuilder.new("Colors", {
		Red = 1,
		Blue = 2,
	})

	local redValue = EnumBuilder:Get("Colors", "Red") -- returns 1
]=]
function EnumBuilder.Get(enumName : string, value)
	assert(typeof(enumName) == 'string', string.format(`Argument enumName of EnumBuilder:Get must be of type string. Got %s`, typeof(enumName)))
	if not EnumBuilder.Enums[enumName] then
		EnumError.new("InvalidEnum", 3, debug.traceback(), `error`):LogError()
	end
	local enum = EnumBuilder.Enums[enumName]
	if enum and enum[value] then
		return enum[value]
	else
		EnumError.new("MissingItem", 3, debug.traceback(), `error`):LogError()
	end
end
--[=[
	Returns a list of values in the enum.

	@within EnumBuilder
	@param EnumTable {[string]: string} -- The enum to get values from.
	@return {string} -- List of all enum values.
]=]
function EnumBuilder.GetValues(enumName : string)
	assert(typeof(enumName) == 'string', string.format(`Argument enumName of EnumBuilder.GetValues must be of type string. Got %s`, typeof(enumName)))
	assert(EnumBuilder.Enums[enumName], string.format(`Couldn't find enum %s`, enumName))
	local values = {}
	for key, value in EnumBuilder.Enums[enumName] do
		table.insert(values, value)
	end
	return values
end
--[=[
	Returns a list of keys in the enum.

	@within EnumBuilder
	@param EnumTable {[string]: string} -- The enum to get keys from.
	@return {string} -- List of all enum keys.
]=]
function EnumBuilder.GetKeys(enumName : string)
	assert(typeof(enumName) == 'string', string.format(`Argument enumName of EnumBuilder.GetValues must be of type string. Got %s`, typeof(enumName)))
	assert(EnumBuilder.Enums[enumName], string.format(`Couldn't find enum %s`, enumName))
	local keys = {}
	for key, value in EnumBuilder.Enums[enumName] do
		table.insert(keys, key)
	end
	return keys
end
--[=[
	Checks if a value exists in the enum.

	@within EnumBuilder
	@param EnumTable {[string]: string} -- The enum table.
	@param Value any -- The value to check.
	@return boolean -- True if valid, false if not.
]=]
function EnumBuilder.isEnumMember(Value : any, enumName : enum)
	assert(EnumBuilder.Enums[enumName], string.format(`Argument enumName of EnumBuilder.GetValues must be of type string. Got %s`, typeof(enumName)))
	if EnumBuilder.Enums[enumName][Value] then return true else return false end
end
--[[
	Determines whether a given key exists within the specified enum.
	This is useful for validating if a particular identifier is part of the enum.
	
	@param enumName string -- The name of the enum to search within.
	@param Key string -- The key to look up in the enum table.
	@return boolean -- Returns true if the key exists in the enum, otherwise false.
	
	@example
		local exists = EnumBuilder.HasKey("Colors", "Red")
		print(exists) -- true or false
]]
function EnumBuilder.HasKey(enumName, Key)
	assert(EnumBuilder.Enums[enumName], string.format(`Argument enumName of EnumBuilder.GetValues must be of type string. Got %s`, typeof(enumName)))
	local enum = EnumBuilder.Enums[enumName]
	if enum and enum[Key] then
		return true
	end
	return false
end
--[[
	Checks if the enum contains the specified value anywhere in its set.
	This function scans through the enum's values to determine if the target value is present.
	
	@param enumName string -- The name of the enum to search.
	@param Value any -- The value to check for membership within the enum.
	@return boolean -- True if the value is found, false if it is absent.
	
	@example
		local contains = EnumBuilder.HasValue("Status", "Active")
		print(contains) -- true or false
]]
function EnumBuilder.HasValue(enumName, Value)
	local enum = EnumBuilder.Enums[enumName]
	if enum and table.find(enum, Value) then
		return true
	end
	return false
end
--[[
	Finds all keys in the enum that map to the given value.
	This is useful when you need to reverse lookup an enum to get the key(s) associated with a value.
	
	@param enumName string -- The name of the enum table to search.
	@param Value any -- The value for which the corresponding key(s) should be found.
	@return string | table | nil -- Returns a single key if only one matches, a table of keys if multiple matches exist, or nil if no matches are found.
	
	@example
		local key = EnumBuilder.GetKeyFromValue("Directions", "North")
		print(key) -- "North"
]]
function EnumBuilder.GetKeyFromValue(enumName, Value)
	if not Value then return end
	assert(EnumBuilder.Enums[enumName], string.format(`Argument enumName of EnumBuilder.GetValues must be of type string. Got %s`, typeof(enumName)))
	local Keys = {}
	local enum = EnumBuilder.Enums[enumName]
	if enum then
		for key, value in pairs(enum) do
			if value == Value then
				table.insert(Keys, key)
			end
		end
	end
	if #Keys == 1 then
		return Keys[1]
	elseif #Keys > 1 then
		return Keys
	else
		return nil
	end
end
--[[
	Creates and returns a shallow copy of the entire enum table.
	This can be useful if you want to modify or manipulate an enum without affecting the original.
	
	@param enumName string -- The name of the enum to clone.
	@return table -- A new table that contains all key-value pairs from the original enum.
	
	@example
		local clonedEnum = EnumBuilder.DeepClone("Status")
		-- clonedEnum can be modified independently of the original
]]
function EnumBuilder.DeepClone(enumName)
	assert(EnumBuilder.Enums[enumName], string.format(`Argument enumName of EnumBuilder.GetValues must be of type string. Got %s`, typeof(enumName)))
	local cloned = {}
	local enum = EnumBuilder.Enums[enumName]
	if enum then
		for k, v in pairs(enum) do
			cloned[k] = v
		end
	end
	return cloned
end
--[[
	Checks whether an enum with the given name has been created and exists.
	This is useful for verifying the existence of an enum before performing operations on it.
	
	@param enumName string -- The name of the enum to verify.
	@return boolean -- True if the enum exists, false if it does not.
	
	@example
		local exists = EnumBuilder.Exists("Colors")
		print(exists) -- true or false
]]
function EnumBuilder.Exists(enumName)
	assert(EnumBuilder.Enums[enumName], string.format(`Argument enumName of EnumBuilder.GetValues must be of type string. Got %s`, typeof(enumName)))
	local enum = EnumBuilder.Enums[enumName]
	if enum then
		return true
	end
	return false
end
--[[
	Validates whether a specific key in an enum corresponds to the provided value.
	This function helps ensure that the enum entry matches expected data.
	
	@param enumName string -- The name of the enum to check.
	@param Key string -- The key in the enum table.
	@param Value any -- The value to compare against the enum's stored value.
	@return boolean -- True if the key exists and the stored value equals the provided value, otherwise false.
	
	@example
		local valid = EnumBuilder.KeyHasValue("Status", "Active", 1)
		print(valid) -- true or false
]]
function EnumBuilder.KeyHasValue(enumName, Key, Value)
	assert(EnumBuilder.Enums[enumName], string.format(`Argument enumName of EnumBuilder.GetValues must be of type string. Got %s`, typeof(enumName)))
	local enum = EnumBuilder.Enums[enumName]
	if enum then
		if enum[Key] then
			if enum[Key] == Value then
				return true
			end
		end
	end
	return false
end
--[[
	Checks whether a specific value in an enum corresponds to the provided key.
	This function is useful for confirming that the given value is stored under the given key in the enum.
	
	@param enumName string -- The name of the enum to check.
	@param Key string -- The key to verify in the enum.
	@param Value any -- The value to compare against the enum's stored value.
	@return boolean -- True if the value exists under the specified key, otherwise false.
	
	@example
		local isMatch = EnumBuilder.ValueHasKey("Status", "Active", 1)
		print(isMatch) -- true or false
]]
function EnumBuilder.ValueHasKey(enumName, Key, Value)
	assert(EnumBuilder.Enums[enumName], string.format(`Argument enumName of EnumBuilder.GetValues must be of type string. Got %s`, typeof(enumName)))
	local enum = EnumBuilder.Enums[enumName]
	if enum then
		for k, v in pairs(enum) do
			if k == Key then
				if v == Value then
					return true
				end
			end
		end
	end
	return false
end
--[[
	Attempts to retrieve an enum by its name, safely handling errors.
	If the enum does not exist or retrieval fails, it logs a warning instead of throwing an error.
	
	@param enumName string -- The name of the enum to retrieve.
	@return any -- The enum table if successful, or nil if retrieval failed.
	
	@example
		local enum = EnumBuilder.TryGet("Colors")
		if enum then
			print(enum.Red)
		else
			print("Enum not found or unsupported.")
		end
]]
function EnumBuilder.TryGet(enumName)
	local success, results = pcall(function()
		return EnumBuilder.Get(enumName)
	end)	
	
	if not success then
		EnumError.new("UnsupportedError", 0, debug.traceback(), 'warn'):LogError()
		warn(success)
	end
end

return EnumBuilder