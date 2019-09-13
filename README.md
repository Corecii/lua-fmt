Not heavily tested yet. Feel free to try it out and submit an issue or pull request if you find a problem.

# fmt.lua

Converts easy-to-read formatting to formats strings

## Examples:

```lua
local fmt = require('fmt')

fmt('Index %s',5) --> Index 5
fmt('Index %04d',5) --> Index 0005
fmt('User input: %s',input) --> User input:
fmt('Multiple format patterns (%d',2,'), string "%s','safe string!','"') --> Multiple format patterns (2), string "safe string!"
fmt('Reusing options: option 1: "%s','hello!','"; option 2: %d',5,'; repeat: $1 $2') --> Reusing options: option 1: "hello!"; option 2: 5; repeat: hello! 5
fmt('Escape percent: %%s') --> Escape percent: %s
```

The following will error:
```lua
fmt('Format patterns %s must be at the end of format string')
fmt('Format patterns other than %%s must type-match %d','oops')
fmt(5, 'First argument must be a format string')
```

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

## Docs

```plain
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
```