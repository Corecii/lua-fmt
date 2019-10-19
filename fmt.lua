--[[
	# fmt.lua

	Converts easy-to-read formatting to formats strings

	For example:
	```lua
		local fmt = require('fmt')
		local formatted = fmt('Index %d',index,' for name %s',name,'(index again: %1)')
	```

	string fmt(string starter, ...)
		Formats (starter, ...) and returns the formatted string

	Formatter fmt.new(string starter, ...)
		Returns a formatter for (starter, ...)

	string, any[], any[], string[] fmt.raw(string starter, ...)
		Returns (formatString, formatOptions, rawOptionsByIndex, rawFormattersByIndex)

	Formatter
		string Formatter()
			Returns the formatted string
		string tostring(Formatter)
			Returns the formatted string
		string .FormatString
			The format string that will be passed to string.format
		any[] .Options
			The options that will be passed to string.format

	## Full Formatting Specification

	* The formatter takes in a list of format strings and options.
	* The first value (starter) is always treated as a format string.
	* If a format string ends with a string.format pattern, then the following value is treated as an option.
	* If a string is not preceded by a string.format pattern, then it is treated as a format string.
	* If a non-string is not preceded by a string.format pattern, then it is tostringed and treated as an option to `%s`.
	* If an option is used for `%s`, it is tostringed. It is safe to use all values for `%s`.
	* Format strings are only allowed to have string.format patterns at the end.
	* You can reuse previous values by including `%X` to re-use option X where X is an integer.
	  For example, `fmt('Index %d',5,' (also index is %1)')` will result in `Index 5 (also index is 5)`
	  Only named (non-automatic) options can be reused by index.

	When formatting with a user-input string or an unknown type, always explicitly use the `%s` formatting option.
	This should be done so that user-input strings such as 'hello %d' do not get treated as format string.
	This is practically escaping or parameterizing your user-input strings.

	The Formatter object can be used, for example, if you want an interactive logger that lets you inspect
	the formattervalues in a debug console.

	## Examples:

	```lua
	fmt('Index %s',5) --> Index 5
	fmt('Index %04d',5) --> Index 0005
	fmt('User input: %s',input) --> User input:
	fmt('Multiple format patterns (%d',2,'), string %s','safe string!')
	fmt('Reusing options: option 1: %s','hello!',' option 2: %d',5,' repeat: $1 $2')
	fmt('Escape percent: %%s')
	```

	The following will error:
	```lua
	fmt('Format patterns %s must be at the end of format string')
	fmt('Format patterns other than %%s must type-match %d','oops')
	fmt(5, 'First argument must be a format string')
	```

--]]

---@param str string @Formatter string
---@vararg any @Formatter strings or option values
---@return string @Format string
---@return any[] @Format options
---@return any[] @Format options by index
---@return string[] @Formatter strings by index
local function format(str, ...)
	assert(type(str) == 'string', 'Expected string for argument 1, got '..type(str)..' ('..tostring(str)..')')
	local args = {str, ...}
	local formatters = {}
	local rawOptions = {}
	local options = {}
	local nextFormatter
	local convertToString = false
	for i, arg in ipairs(args) do
		if nextFormatter then
			formatters[#formatters + 1] = nextFormatter
			args[i] = nextFormatter
			nextFormatter = nil
			local option
			if convertToString then
				option = tostring(arg)
			else
				option = arg
			end
			rawOptions[#rawOptions + 1] = option
			options[#options + 1] = option
		elseif type(arg) == 'string' then
			local base
			do
				local escapes, formatter, specifier
				base, escapes, formatter, specifier = arg:match('^(.*)(%%*)(%%[%-%+ #0]?%d*%.?[%d%*]*[hljztL]?[hl]?)([diuoxXfFeEgGaAcspn])$')
				if base and #escapes%2 == 0 then
					nextFormatter = formatter..specifier
					convertToString = specifier == 's'
				else
					base = arg
				end
			end
			if not base then
				base = arg
			end
			for escapes, formatter, specifier in base:gmatch('(%%+)([%-%+ #0]?%d*%.?[%d%*]*[hljztL]?[hl]?)([diuoxXfFeEgGaAcspn])') do
				assert(#escapes%2 == 0, 'Unexpected formatter "%'..formatter..specifier..'": formatters should only be at the end of non-option strings')
			end
			base = base:gsub('(%%+)(%d+)', function(escapes, digits)
				if #escapes%2 == 0 then
					return
				end
				local optionIndex = tonumber(digits)
				local formatter = assert(formatters[optionIndex], 'Option '..digits..' must be defined before it can be reused')
				local option = rawOptions[optionIndex]
				options[#options + 1] = option
				return formatter
			end)
			args[i] = base
		else
			args[i] = '%s'
			options[#options + 1] = tostring(arg)
		end
	end
	return table.concat(args), options, rawOptions, formatters
end

---@class Formatter
local Formatter = {}
Formatter.__index = Formatter

---@return string @Formatted string
function Formatter:__call()
	return string.format(self.FormatString, unpack(self.Options))
end

---@return string @Formatted string
function Formatter:__tostring()
	return string.format(self.FormatString, unpack(self.Options))
end

local fmt = {}
setmetatable(fmt, fmt)

---@param str string @Formatter string
---@vararg any @Formatter strings or option values
---@return Formatter @String formatter
function fmt.new(str, ...)
	local formatStr, options, rawOptions_, formatters_ = format(str, ...)
	local self = {
		FormatString = formatStr,
		Options = options,
	}
	return setmetatable(self, Formatter)
end

---@param str string @Formatter string
---@vararg any @Formatter strings or option values
---@return string @Formatted string
function fmt:__call(str, ...)
	local formatStr, options = format(str, ...)
	return string.format(formatStr, unpack(options))
end

fmt.raw = format

return fmt