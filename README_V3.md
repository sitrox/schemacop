# Schemacop Schema V3

## Table of Contents

1. [Validation](#validation)
2. [Exceptions](#exceptions)
3. [Generic Keywords](#generic-keywords)
4. [Nodes](#nodes)
    1. [String](#string)
    2. [Integer](#integer)
    3. [Number](#number)
    4. [Symbol](#symbol)
    5. [Boolean](#boolean)
    6. [Array](#array)
    7. [Hash](#hash)
    8. [Object](#object)
    9. [AllOf](#allOf)
    10. [AnyOf](#anyOf)
    11. [OneOf](#oneOf)
    12. [IsNot](#isNot)
    13. [Reference](#reference)
5. [Context](#context)
6. [External schemas](#external-schemas)
7. [Default options](#default-options)

## Validation

Using Schemacop, you can either choose to validate your data either using the
graceful `validate` method, or the bang variant, `validate!`.

The `validate` method on a schema with some supplied data will return a
`Schemacop::Result` object, which has some useful methods to work with the
data you validated.

```ruby
schema = Schemacop::Schema3.new :string, format: :date
result = schema.validate('2020-01-01')
result.class # => Schemacop::Result
```

With the `data` method, you can access the casted version of your data:

```ruby
schema = Schemacop::Schema3.new :string, format: :date
result = schema.validate('2020-01-01')
result.data # => Wed, 01 Jan 2020
```

And with the `valid?` method, you can check if the supplied data validates
against the schema:

```ruby
schema = Schemacop::Schema3.new :string, format: :date
result = schema.validate('2020-01-01')
result.valid? # => true
```

On the other hand, the `validate!` method either returns the casted data if the
validation was successful, or if the validation failed, raises a
`Schemacop::Exceptions::ValidationError` exception:

```ruby
schema = Schemacop::Schema3.new :string, format: :date
schema.validate!('2020-01-01')  # => Wed, 01 Jan 2020
schema.validate!('Foo')         # => Schemacop::Exceptions::ValidationError: /: String does not match format "date".
```

## Exceptions

Schemacop can raise the following exceptions:

* `Schemacop::Exceptions::ValidationError`: This exception is raised when the
  `validate!` method is used, and the data that was passed in is invalid. The
  exception message contains additional information why the validation failed.

  Example:

  ```ruby
  schema = Schemacop::Schema3.new :hash do
    int! :foo
  end

  schema.validate!(foo: 'bar')
  # => Schemacop::Exceptions::ValidationError: /foo: Invalid type, got type "String", expected "integer".
  ```

* `Schemacop::Exceptions::InvalidSchemaError`: This exception is raised when the
  schema itself is not valid. The exception message contains additional
  information why the validation failed.

  Example:

  ```ruby
  Schemacop::Schema3.new :hash do
    int!
  end

  # => Schemacop::Exceptions::InvalidSchemaError: Child nodes must have a name.
  ```

## Generic Keywords

The nodes in Schemacop v3 also support generic keywords, similar to JSON schema:

* `title`: Short string, should be self-explanatory
* `description`: Description of the schema
* `examples`: Here, you can provide examples which will be valid for the schema
* `enum`: Here, you may enumerate values which will be valid, if the provided
  value is not in the array, the validation will fail
* `default`: You may provide a default value for items that will be set if the
  value is not given
* `require_key`: If set to true, validate that the key of this node is present,
  regardless of the value (including `nil`). This is only validated if the
  schema type is set to `:hash`.
  Example:
  ```ruby
  Schemacop::Schema3.new(:hash) do
    str? :foo, require_key: true
    int? :bar, require_key: true
  end
  ```

The three keywords `title`, `description` and `examples` aren't used for validation,
but can be used to document the schema. They will be included in the JSON output
when you use the `as_json` method:

```ruby
schema = Schemacop::Schema3.new :hash do
  str! :name, title: 'Name', description: 'Holds the name of the user', examples: ['Joe', 'Anna']
end

schema.as_json

# => {"properties"=>{"name"=>{"type"=>"string", "title"=>"Name", "examples"=>["Joe", "Anna"], "description"=>"Holds the name of the user"}}, "additionalProperties"=>false, "required"=>["name"], "type"=>"object"}
```

The `enum` keyword can be used to only allow a subset of values:

```ruby
schema = Schemacop::Schema3.new :string, enum: ['foo', 'bar']

schema.validate!('foo') # => "foo"
schema.validate!('bar') # => "bar"
schema.validate!('baz') # => Schemacop::Exceptions::ValidationError: /: Value not included in enum ["foo", "bar"].
```

Please note that you can also specify values in the enum that are not valid for
the schema. This means that the validation will still fail:

```ruby
schema = Schemacop::Schema3.new :string, enum: ['foo', 'bar', 42]

schema.validate!('foo') # => "foo"
schema.validate!('bar') # => "bar"
schema.validate!(42)    # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "Integer", expected "string".
```

The enum will also be provided in the json output:

```ruby
schema = Schemacop::Schema3.new :string, enum: ['foo', 'bar']

schema.as_json
# => {"type"=>"string", "enum"=>["foo", "bar", 42]}
```

And finally, the `default` keyword lets you set a default value to use when no
value is provided:

```ruby
schema = Schemacop::Schema3.new :string, default: 'Schemacop'

schema.validate!('foo') # => "foo"
schema.validate!(nil)   # => "Schemacop"
```

The default value will also be provided in the json output:

```ruby
schema = Schemacop::Schema3.new :string, default: 'Schemacop'

schema.as_json
# => {"type"=>"string", "default"=>"Schemacop"}
```

Note that the default value you use is also validated against the schema:

```ruby
schema = Schemacop::Schema3.new :string, default: 42

schema.validate!('foo') # => "foo"
schema.validate!(nil)   # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "Integer", expected "string".
```

## Nodes

### String

Type: `:string`\
DSL: `str`

The string type is used for strings of text and must be a ruby `String` object
or a subclass. Using the option `format`, strings can be validated against and
transformed into various types.

#### Options

* `min_length`
  Defines the (inclusive) minimum required string length
* `max_length`
  Defines the (inclusive) maximum required string length
* `pattern`
  Defines a (ruby) regex pattern the value will be matched against. Must be either
  a string which should not be enclosed in `/` characters, or a Ruby Regexp.
  The pattern should generally start with `^` and end with `$` so as to evaluate
  the entire string.
* `format`
  The `format` option allows for basic semantic validation on certain kinds of
  string values that are commonly used. See section *formats* for more
  information on the available formats. Note that strings with a format are also
  **casted** into that format.
* `allow_blank`
  By default, blank strings are allowed and left as they are when casted (e.g.
  the string `''` is valid). If you want to disallow blank strings, set this
  option to `false`.

#### Formats

* `date`
  A date according to [ RFC 3339, section
  5.6.](https://json-schema.org/latest/json-schema-validation.html#RFC3339) date
  format, i.e. `2018-11-13`. Strings with this format will be
  casted to a ruby `Date` object.

* `date_time`
  A date time according to [RFC 3339, section
  5.6.](https://json-schema.org/latest/json-schema-validation.html#RFC3339) date
  format, i.e. `2018-11-13T20:20:39+00:00`. Strings with this format will be
  casted to a ruby `DateTime` object. The time zones will be inferred by the
  string.

* `email`
  Validates for a valid email address. There is no casting involved since email
  addresses do not have their own ruby type.

* `mailbox`
  Validates for a valid mailbox, which is defined as a valid email enclosed in
  brackets (`< >`), with an optional name before the email address. There is no
  casting involved.

* `boolean`
  The string must be either `true`, `false`, `0` or `1`. This value will be
  casted to Ruby's `TrueClass` or `FalseClass`. Please note that the strings
  `true` and `false` are case-insensitive, i.e. `True`, `TRUE` etc. will also
  work.

* `binary`
  The string is expected to contain binary contents. No casting or additional
  validation is performed.

* `integer`
  The string must be an integer and will be casted to a ruby `Integer` object.

* `number`
  The string must be a number and will be casted to a ruby `Float` object.

* `integer_list`
  The string must consist of comma-separated integers casted to a ruby `Array<Integer>` object

* `symbol`
  The string can be anything and will be casted to a ruby `Symbol` object.

* `ipv4`
  A valid IPv4 address without netmask. No casting is performed.

* `ipv4-cidr`
  A valid IPv4 CIDR address with netmask. No casting is performed.

* `ipv6`
  A valid IPv6 address without netmask. No casting is performed.

#### Custom Formats

You can also implement your custom formats or override the behavior of the
standard formats. For Rails applications, this can be done in
`config/schemacop.rb`:

```ruby
# config/schemacop.rb
Schemacop.register_string_formatter(
  :character_array,                        # Formatter name
  pattern: /^[a-zA-Z](,[a-zA-Z])*/,        # Regex pattern for validation
  handler: ->(value) { value.split(',') }  # Casting callback
)

# In your schema
str! :my_list, format: :character_array
```

#### Examples

```ruby
# Basic example
schema = Schemacop::Schema3.new :string
schema.validate!(nil)   # => nil
schema.validate!('')    # => ""
schema.validate!('foo') # => "foo"
schema.validate!("\n")  # => "\n"
```

With the `required` option:

```ruby
# Basic example
schema = Schemacop::Schema3.new :string, required: true
schema.validate!(nil)   # => Schemacop::Exceptions::ValidationError: /: Value must be given.
schema.validate!('')    # => ""
schema.validate!('foo') # => "foo"
schema.validate!("\n")  # => "\n"
```

With the `allow_blank` option:

```ruby
# Basic example
schema = Schemacop::Schema3.new :string, allow_blank: false
schema.validate!(nil)   # => Schemacop::Exceptions::ValidationError: /: String is blank but must not be blank!
schema.validate!('')    # => Schemacop::Exceptions::ValidationError: /: String is blank but must not be blank!
schema.validate!('foo') # => "foo"
schema.validate!("\n")  # => Schemacop::Exceptions::ValidationError: /: String is blank but must not be blank!
```
Example of using a `format` option:

```ruby
# By using a format, string values are casted to that respective format
schema = Schemacop::Schema3.new(:string, format: :date)
result = schema.validate('1980-01-13')
result.data # => Date<"Sun, 13 Jan 1980">
```

### Integer

Type: `:integer`\
DSL: `int`

The integer type is used for whole numbers and must be a ruby `Integer` or a
subclass. With the various available options, validations on the value of the
integer can be done.

#### Options

* `minimum`
  Defines an (inclusive) minimum, i.e. the number has to be equal or larger than the
  given number
* `exclusive_minimum`
  Defines an exclusive minimum, i.e. the number has to larger than the given number
* `maximum`
  Defines an (inclusive) maximum, i.e. the number has to be equal or smaller than the
  given number
* `exclusive_maximum`
  Defines an exclusive maximum, i.e. the number has to smaller than the given number
* `multiple_of`
  The received number has to be a multiple of the given number for the validation to
  pass.
* `cast_str`
  When set to `true`, this node also accepts strings that can be casted to an integer, e.g.
  the values `'-5'` or `'42'`. Please note that you can only validate numbers which
  are in the `Integer` format. Blank strings will be treated equally as `nil`.
  Strings will be parsed with base 10, so only decimal numbers are allowed.
  Leading zeroes will be ignored.

#### Examples

```ruby
# Validates that the input is an even number between 0 and 100 (inclusive)
schema = Schemacop::Schema3.new(:integer, minimum: 0, maximum: 100, multiple_of: 2)
schema.validate!(42)            # => 42
schema.validate!(43)            # => Schemacop::Exceptions::ValidationError: /: Value must be a multiple of 2.
schema.validate!(-2)            # => Schemacop::Exceptions::ValidationError: /: Value must have a minimum of 0.
schema.validate!(102)           # => Schemacop::Exceptions::ValidationError: /: Value must have a maximum of 100.
schema.validate!(42.1)          # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "Float", expected "integer".
schema.validate!(4r)            # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "Rational", expected "integer".
schema.validate!((4 + 0i))      # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "Complex", expected "integer".
schema.validate!(BigDecimal(5)) # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "BigDecimal", expected "integer".
```

With `cast_str` enabled:

```ruby
# Validates that the input is an even number between 0 and 100 (inclusive)
schema = Schemacop::Schema3.new(:integer, minimum: 0, maximum: 100, multiple_of: 2, cast_str: true)
schema.validate!('42')            # => 42
schema.validate!('43')            # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!('-2')            # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!('102')           # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!('42.1')          # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!('4r')            # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!('(4 + 0i)')      # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!(nil)             # => nil
schema.validate!('')              # => nil
```

Please note, that `nil` and blank strings are treated equally when using the `cast_str` option,
and validating a blank string will return `nil`.
If you need a value, use the `required` option:

```ruby
schema = Schemacop::Schema3.new(:integer, minimum: 0, maximum: 100, multiple_of: 2, cast_str: true, required: true)
schema.validate!('42')  # => 42
schema.validate!(nil)   # => Schemacop::Exceptions::ValidationError: /: Value must be given.
schema.validate!('')    # => Schemacop::Exceptions::ValidationError: /: Value must be given.
```

### Number

Type: `:number`\
DSL: `num`

The number type is used to validate various number classes. The following ruby classes
and subclasses are valid:

* `Integer`
* `Float`
* `Rational`
* `BigDecimal`

As some subclasses of `Numeric`, such as `Complex` don't support all required operations,
only the above list is supported. If you need support for additional number classes, please
contact the Gem maintainers.

With the various available options, validations on the value of the number can be done.

#### Options

* `minimum`
  Defines an (inclusive) minimum, i.e. the number has to be equal or larger than the
  given number
* `exclusive_minimum`
  Defines an exclusive minimum, i.e. the number has to larger than the given number
* `maximum`
  Defines an (inclusive) maximum, i.e. the number has to be equal or smaller than the
  given number
* `exclusive_maximum`
  Defines an exclusive maximum, i.e. the number has to smaller than the given number
* `multiple_of`
  The received number has to be a multiple of the given number for the validation to
  pass.
* `max_precision`
  Defines the maximum number of digits after the decimal point for `Float` and 
  `BigDecimal` values. Must be a non-negative integer. When `nil` (default), no
  precision validation is performed. Trailing zeros are ignored in the validation.
* `cast_str`
  When set to `true`, this node also accepts strings that can be casted to a number, e.g.
  the values `'0.1'` or `'3.1415'`. Please note that you can only validate numbers which
  are in the `Integer` or `Float` format, i.e. values like `'1.5r'` or `'(4 + 0i)'` will
  not work. Blank strings will be treated equally as `nil`.  Strings will be
  parsed with base 10, so only decimal numbers are allowed.  Leading zeroes will
  be ignored.

#### Examples

```ruby
# Validates that the input is a number between 0 and 50 (inclusive) and a multiple of 0.5
schema = Schemacop::Schema3.new(:number, minimum: 0.0, maximum: (50r), multiple_of: BigDecimal('0.5'))
schema.validate!(42)            # => 42
schema.validate!(42.2)          # => Schemacop::Exceptions::ValidationError: /: Value must be a multiple of 0.5.
schema.validate!(-2)            # => Schemacop::Exceptions::ValidationError: /: Value must have a minimum of 0.0.
schema.validate!(51)            # => Schemacop::Exceptions::ValidationError: /: Value must have a maximum of 50/1.
schema.validate!(42.5)          # => 42.5
schema.validate!(1.5r)          # => (3/2)
schema.validate!(BigDecimal(5)) # => 0.5e1
schema.validate!((4 + 0i))      # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "Complex", expected "big_decimal" or "float" or "integer" or "rational"
```

With `cast_str` enabled:

```ruby
schema = Schemacop::Schema3.new(:number, cast_str: true, minimum: 0.0, maximum: (50r), multiple_of: BigDecimal('0.5'))
schema.validate!('42')        # => 42
schema.validate!('42.2')      # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!('-2')        # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!('51')        # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!('42.5')      # => 42.5
schema.validate!('1.5r')      # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!('(4 + 0i)')  # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!(nil)         # => nil
schema.validate!('')          # => nil
```

With `max_precision`:

```ruby
# Validates that the input is a number with maximum 2 decimal places
schema = Schemacop::Schema3.new(:number, max_precision: 2)
schema.validate!(42)                   # => 42
schema.validate!(42.5)                 # => 42.5
schema.validate!(42.52)                # => 42.52
schema.validate!(42.523)               # => Schemacop::Exceptions::ValidationError: /: Value must have a maximum precision of 2 digits after the decimal point.
schema.validate!(BigDecimal('3.14'))   # => 0.314e1
schema.validate!(BigDecimal('3.141'))  # => Schemacop::Exceptions::ValidationError: /: Value must have a maximum precision of 2 digits after the decimal point.
schema.validate!(BigDecimal('3.140'))  # => 0.314e1 (trailing zeros are ignored)
schema.validate!(1r)                   # => (1/1) (rational numbers are not affected)
```

Please note, that `nil` and blank strings are treated equally when using the `cast_str` option,
and validating a blank string will return `nil`.
If you need a value, use the `required` option:

```ruby
schema = Schemacop::Schema3.new(:number, cast_str: true, minimum: 0.0, maximum: (50r), multiple_of: BigDecimal('0.5'), required: true)
schema.validate!('42.5')  # => 42.5
schema.validate!(nil)     # => Schemacop::Exceptions::ValidationError: /: Value must be given.
schema.validate!('')      # => Schemacop::Exceptions::ValidationError: /: Value must be given.
```

### Symbol

Type: `:symbol`\
DSL: `sym`

The symbol type is used to validate elements for the Ruby `Symbol` class.

#### Options

* `cast_str`
  When set to `true`, this node also accepts strings that can be casted to a symbol. Blank strings will be treated equally as `nil`.

#### Examples

```ruby
# Validates that the input is a symbol
schema = Schemacop::Schema3.new(:symbol)
schema.validate!(:foo)   # => :foo
schema.validate!('foo')  # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "String", expected "Symbol".
schema.validate!(123)    # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "Integer", expected "Symbol".
schema.validate!(false)  # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "FalseClass", expected "Symbol".
schema.validate!(:false) # => :false
```

With `cast_str` enabled:

```ruby
# Validates that the input is a symbol
schema = Schemacop::Schema3.new(:symbol, cast_str: true)
schema.validate!(':foo')   # => :":foo"
schema.validate!('foo')    # => :foo
schema.validate!('123')    # => :"123"
schema.validate!('false')  # => :false
schema.validate!(':false') # => :":false"
schema.validate!(nil)      # => nil
schema.validate!('')       # => nil
```

Please note, that `nil` and blank strings are treated equally when using the `cast_str` option,
and validating a blank string will return `nil`.
If you need a value, use the `required` option:

```ruby
schema = Schemacop::Schema3.new(:symbol, cast_str: true, required: true)
schema.validate!('foo')   # => :foo
schema.validate!(nil)     # => Schemacop::Exceptions::ValidationError: /: Value must be given.
schema.validate!('')      # => Schemacop::Exceptions::ValidationError: /: Value must be given.
```

### Boolean

Type: `:boolean`\
DSL: `boo`

The boolean type is used to validate Ruby booleans, i.e. the `TrueClass` and `FalseClass`

#### Options

* `cast_str`
  When set to `true`, this node also accepts strings that can be casted to a
  boolean, namely the values `'true'`, `'false'`, `'1'` and `'0'`. Blank strings
  will be treated equally as `nil`. This casting is case-insensitive.

#### Examples

```ruby
# Validates that the input is a boolean
schema = Schemacop::Schema3.new(:boolean)
schema.validate!(true)    # => true
schema.validate!(false)   # => false
schema.validate!(:false)  # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "Symbol", expected "boolean".
schema.validate!('false') # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "String", expected "boolean".
schema.validate!(1234)    # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "Integer", expected "boolean".

schema.validate!('0', cast_str: true)     # => false
schema.validate!('1', cast_str: true)     # => true
schema.validate!('false', cast_str: true) # => false
schema.validate!('true', cast_str: true)  # => true
```

With `cast_str` enabled:

```ruby
schema = Schemacop::Schema3.new(:boolean, cast_str: true)
schema.validate!(true)    # => true
schema.validate!(false)   # => false
schema.validate!(:false)  # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!('false') # => false
schema.validate!(1234)    # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!(nil)     # => nil
schema.validate!('')      # => nil
```

Please note, that `nil` and blank strings are treated equally when using the `cast_str` option,
and validating a blank string will return `nil`.
If you need a value, use the `required` option:

```ruby
schema = Schemacop::Schema3.new(:boolean, cast_str: true, required: true)
schema.validate!('false') # => false
schema.validate!(nil)     # => Schemacop::Exceptions::ValidationError: /: Value must be given.
schema.validate!('')      # => Schemacop::Exceptions::ValidationError: /: Value must be given.
```

### Array

Type: `:array`\
DSL: `ary`

The array type represents a ruby `Array`.
It consists of one or multiple values, which can be validated using arbitrary nodes.

#### Options

* `min_items`
  This option specifies the (inclusive) minimum number of elements the array
  must contain to pass the validation.

* `max_items`
  This option specifies the (inclusive) maximum number of elements the array
  must contain to pass the validation.

* `unique_items`
  This option specifies whether the items in the array must all be distinct from
  each other, or if there may be duplicate values. By default, this is false,
  i.e. duplicate values are allowed

* `filter`
  This option allows you to filter an array *before it is validated*. When using
  casting, this also filters the data returned by the validator. If the given value
  is a `Symbol`, the method with the given name will be executed on each array
  item in order to determine whether it is kept. If the given value is a `Proc`,
  it will be called for each array item to determine whether it is kept. Both
  functions or Procs are expected to return either `true` or `false`.

  This is the inverse of option `reject`.

* `reject`
  This option allows you to filter an array *before it is validated*. When using
  casting, this also filters the data returned by the validator. If the given value
  is a `Symbol`, the method with the given name will be executed on each array
  item in order to determine whether it is removed. If the given value is a `Proc`,
  it will be called for each array item to determine whether it is removed. Both
  functions or Procs are expected to return either `true` or `false`.

  This is the inverse of option `filter`.

* `parse_json`
  Specifies whether JSON is accepted instead of an array. If this is set to
  `true` and the given value is a string, Schemacop will attempt to parse the
  string as JSON. If the JSON yields a valid array, it will cast the JSON to a
  array and validate it using the given schema.

  Defaults to `false`.

#### Contains

The `array` node features the *contains* node, which you can use with the DSL
method `cont`. With that DSL method, you can specify a schema which at least one
item in the array needs to validate against.

One use case for example could be that you want an array of integers, from which
at least one must be 5 or larger:

```ruby
schema = Schemacop::Schema3.new :array do
  list :integer
  cont :integer, minimum: 5
end

schema.validate!([])      # => Schemacop::Exceptions::ValidationError: /: At least one entry must match schema {"type"=>"integer", "minimum"=>5}.
schema.validate!([1, 5])  # => [1, 5]
schema.validate!(['foo']) # => Schemacop::Exceptions::ValidationError: /[0]: Invalid type, got type "String", expected "integer". /: At least one entry must match schema {"type"=>"integer", "minimum"=>5}
```

You can also use it with the tuple validation (see below), e.g. if you want
an array of 3 integers, from which at least one needs to be 5 or larger:

```ruby
schema = Schemacop::Schema3.new :array do
  int
  int
  int
  cont :integer, minimum: 5
end

schema.validate!([])        # => /: Array has 0 items but must have exactly 3. /: At least one entry must match schema {"type"=>"integer", "minimum"=>5}.
schema.validate!([1, 2, 3]) # => Schemacop::Exceptions::ValidationError: /: At least one entry must match schema {"type"=>"integer", "minimum"=>5}.
schema.validate!([1, 3, 5]) # => [1, 3, 5]
```

#### Specifying Properties

Array nodes support a block in which you can specify the required array contents.
The array nodes support either list validation, or tuple validation, depending on
how you specify your array contents.

##### List Validation

List validation validates a sequence of arbitrary length where each item matches
the same schema. Unless you specify a `min_items` count on the array node, an
empty array will also suffice. If the option `required: true` is not specified,
a list containing only `nil` values is also valid. To specify a list validation,
use the `list` DSL method, and specify the type you want to validate against.
Here, you need to specify the type of the element using the long `type` name
(e.g. `integer` and not `int`).

For example, you can specify that you want an array with only integers between 1 and 5:

```ruby
schema = Schemacop::Schema3.new :array do
  list :integer, minimum: 1, maximum: 5
end

schema.validate!([])      # => []
schema.validate!([1, 3])  # => [1, 3]
schema.validate!([0, 6])  # => Schemacop::Exceptions::ValidationError: /[0]: Value must have a minimum of 1. /[1]: Value must have a maximum of 5.
schema.validate!(['foo']) # => Schemacop::Exceptions::ValidationError: /[0]: Invalid type, got type "String", expected "integer".
```

You can also build more complex structures, e.g. an array containing an arbitrary
number of integer arrays:

```ruby
schema = Schemacop::Schema3.new :array do
  list :array do
    list :integer
  end
end

schema.validate!([])                # => []
schema.validate!([[1], [2, 3]])     # => [[1], [2, 3]]
schema.validate!([['foo'], [2, 3]]) # => Schemacop::Exceptions::ValidationError: /[0]/[0]: Invalid type, got type "String", expected "integer".
```

Please note that you can only specify *one* `list` item:

```ruby
schema = Schemacop::Schema3.new :array do
  list :integer
  list :string
end

# => Schemacop::Exceptions::InvalidSchemaError: You can only use "list" once.
```

##### Tuple Validation

On the other hand, tuple validation validates a sequence of fixed length, where
each item has its own schema that it has to match. Here, the order of the items
is relevant for the validation.

For example, we want a tuple with an int, followed by a string:

```ruby
schema = Schemacop::Schema3.new :array do
  int
  str
end

schema.validate!([])                # => Schemacop::Exceptions::ValidationError: /: Array has 0 items but must have exactly 2.
schema.validate!([1, 'foo'])        # => [1, "foo"]
schema.validate!([1, 'foo', 'bar']) # => Schemacop::Exceptions::ValidationError: /: Array has 3 items but must have exactly 2.
```

When using tuple validation, you can also allow additional items in the array
*after* the specified items, either with the option `additional_items` or the
DSL method `add`. With the option `additional_items` set to `true`, you can
allow any additional items:

```ruby
schema = Schemacop::Schema3.new :array, additional_items: true do
  int
  str
end

schema.validate!([])                # => Schemacop::Exceptions::ValidationError: /: Array has 0 items but must have exactly 2.
schema.validate!([1, 'foo'])        # => [1, "foo"]
schema.validate!([1, 'foo', 'bar']) # => [1, "foo", "bar"]
```

You can also use the dsl method `add` to specify more exactly what type the
of the additional items may be. As with any other dsl method, you may specify
and valid schema which the additional items will be validated against:

```ruby
schema = Schemacop::Schema3.new :array do
  int
  str
  add :integer
end

schema.validate!([])                # => Schemacop::Exceptions::ValidationError: /: Array has 0 items but must have exactly 2.
schema.validate!([1, 'foo'])        # => [1, "foo"]
schema.validate!([1, 'foo', 'bar']) # => Schemacop::Exceptions::ValidationError: /[2]: Invalid type, got type "String", expected "integer".
schema.validate!([1, 'foo', 2, 3])  # => [1, "foo", 2, 3]
```

Please note that you cannot use multiple `add` in the same array schema, this
will result in an exception:

```ruby
schema = Schemacop::Schema3.new :array do
  int
  add :integer
  add :string
end

# => Schemacop::Exceptions::InvalidSchemaError: You can only use "add" once to specify additional items.
```

If you want to specify that your schema accept multiple additional types, use
the `one_of` type (see below for more infos). The correct way to specify that
you want to allow additional items, which may be an integer or a string is as
follows:

```ruby
schema = Schemacop::Schema3.new :array do
  int
  add :one_of do
    int
    str
  end
end

schema.validate!([])          # => Schemacop::Exceptions::ValidationError: /: Array has 0 items but must have exactly 1.
schema.validate!([1, 2])      # => [1, 2]
schema.validate!([1, 'foo'])  # => [1, "foo"]
schema.validate!([1, :bar])   # => Schemacop::Exceptions::ValidationError: /[1]: Matches 0 definitions but should match exactly 1.
```

#### Filtering

Using the options `filter` and `reject`, arrays can be filtered. Filtering
happens before validation. Both options behave in the same way, with the only
difference being that `filter` uses a inclusive approach and `reject` an
exclusive (see [filter](https://apidock.com/ruby/Array/filter) and
[reject](https://apidock.com/ruby/Array/reject) in the Ruby API, as they behave
in a similar manner).

You can either pass a Symbol which specifies the name of the method that is
called on each array item:

```ruby
# FYI: This example requires active_support for the blank? method
schema = Schemacop::Schema3.new :array, reject: :blank? do
  list :string
end

schema.validate!(['', 'foo'])  # => ["foo"]
```

You can also pass a proc to `filter` or `reject`:

```ruby
schema = Schemacop::Schema3.new :array, filter: ->(value) { value.is_a?(String) } do
  list :string
end

schema.validate!(['foo', 42])  # => ["foo"]
```

Note that the given method name or proc should work with all element types that
could possibly be in the (unvalidated) array. If a `NoMethodError` is
encountered during a single filtering iteration, the element will be left in the
array and, in most cases, trigger a validation error later:

```ruby
schema = Schemacop::Schema3.new :array, reject: :zero? do
  list :integer
end

# In this example, the value 'foo' does not respond to the method `zero?` which
# lead to a `NoMethodError` that is caught by Schemacop which in turn leaves the
# value in the array.
schema.validate!(['foo', 42, 0]) # => Schemacop::Exceptions::ValidationError: /[0]: Invalid type, got type "String", expected "integer".
```

##### Parsing JSON

By enabling `parse_json`, the given value will be parsed as JSON if it is a
string instead of an array:

```ruby
# This schema will accept any additional properties, but remove them from the result
schema = Schemacop::Schema3.new :array, parse_json: true do
  list :integer
end

schema.validate!([1, 2, 3])   # => [1, 2, 3]
schema.validate!('[1, 2, 3]') # => [1, 2, 3]
```

### Hash

Type: `:hash`\
DSL: `hsh`

The hash type represents a ruby `Hash` or an `object` in JSON schema language.
It consists of key-value-pairs that can be validated using arbitrary nodes.

#### Options

* `additional_properties`
  This option specifies whether additional, unspecified properties are allowed
  (`true`) or not (`false`). By default, this is `false`, i.e. you need to
  explicitly set it to `true` if you want to allow arbitrary additional properties,
  or use the `add` DSL method (see below) to specify additional properties.

* `property_names`
  This option allows to specify a regexp pattern (as string) which validates the
  keys of any properties that are not specified in the hash. This option only
  makes sense if `additional_properties` is enabled. See below for more information.

* `min_properties`
  Specifies the (inclusive) minimum number of properties a hash must contain.

* `max_properties`
  Specifies the (inclusive) maximum number of properties a hash must contain.

* `ignore_obsolete_properties`
  Similar to `additional_properties`. If this is set to `true`, all additional
  properties are allowed (i.e. they pass the validation), but they are removed
  from the result hash. This is useful e.g. to validate params coming from the
  controller, as this only allows white-listed params and removes any params
  which are not whitelisted (i.e. similar to strong params from Rails).

  If it is set to an enumerable (e.g. `Set` or `Array`), it functions as a
  white-list and only the given additional properties are allowed.

* `parse_json`
  Specifies whether JSON is accepted instead of a hash. If this is set to
  `true` and the given value is a string, Schemacop will attempt to parse the
  string as JSON. If the JSON yields a valid hash, it will cast the JSON to a
  hash and validate it using the given schema.

  Defaults to `false`.

#### Specifying Properties

Hash nodes support a block in which you can specify the required hash contents.

##### Standard Properties

It supports all type nodes, but requires the suffix `?` or `!` for each
property, which specifies whether a property is required (`!`) or optional
(`?`).

```ruby
schema = Schemacop::Schema3.new :hash do
  str! :foo # Is a required property
  int? :bar # Is an optional property
end

schema.validate!({})                    # => Schemacop::Exceptions::ValidationError: /foo: Value must be given.
schema.validate!({foo: 'str'})          # => {"foo"=>"str"}
schema.validate!({foo: 'str', bar: 42}) # => {"foo"=>"str", "bar"=>42}
schema.validate!({bar: 42})             # => Schemacop::Exceptions::ValidationError: /foo: Value must be given.
```

The name of the properties may either be a string or a symbol, and you can pass
in the property either identified by a symbol or a string:

The following two schemas are equal:

```ruby
schema = Schemacop::Schema3.new :hash do
  int! :foo
end

schema.validate!(foo: 42)     # => {"foo"=>42}
schema.validate!('foo' => 42) # => {"foo"=>42}

schema = Schemacop::Schema3.new :hash do
  int! 'foo'
end

schema.validate!(foo: 42)     # => {"foo"=>42}
schema.validate!('foo' => 42) # => {"foo"=>42}
```

The result in both cases will be a
[HashWithIndifferentAccess](https://api.rubyonrails.org/classes/ActiveSupport/HashWithIndifferentAccess.html),
which means that you can access the data in the hash with the symbol as well as
the string representation:

```ruby
schema = Schemacop::Schema3.new :hash do
  int! :foo
end

result = schema.validate!(foo: 42)

result.class  # => ActiveSupport::HashWithIndifferentAccess
result[:foo]  # => 42
result['foo'] # 42
```

Please note that if you specify the value twice in the data you want to
validate, once with the key being a symbol and once being a string, Schemacop
will raise an error:

```ruby
schema = Schemacop::Schema3.new :hash do
  int! :foo
end

schema.validate!(foo: 42, 'foo' => 43) # => Schemacop::Exceptions::ValidationError: /: Has 1 ambiguous properties: [:foo].
```

In addition to the normal node options (which vary from type to type, check
the respective nodes for details), properties also support the `as` option.

With this, you can "rename" properties in the output:

```ruby
schema = Schemacop::Schema3.new :hash do
  int! :foo, as: :bar
end

schema.validate!({foo: 42}) # => {"bar"=>42}
```

Please note that if you specify a node with the same property name multiple
times, or use the `as` option to rename a node to the same name of another
node, the last specified node will be used:

```ruby
schema = Schemacop::Schema3.new :hash do
  int? :foo
  str? :foo
end

schema.validate!({foo: 1})      # => Schemacop::Exceptions::ValidationError: /foo: Invalid type, got type "Integer", expected "string".
schema.validate!({foo: 'bar'})  # => {"foo"=>"bar"}
```

As well as:

```ruby
schema = Schemacop::Schema3.new :hash do
  int? :foo
  int? :bar, as: :foo
end

schema.validate!({foo: 1})          # => {"foo"=>1}
schema.validate!({foo: 1, bar: 2})  # => {"foo"=>2}
schema.validate!({bar: 2})          # => {"foo"=>2}
```

If you want to specify a node which may be one of multiple types, use the `one_of`
node (see further down for more details):

```ruby
schema = Schemacop::Schema3.new :hash do
  one_of! :foo do
    int
    str
  end
end

schema.validate!({foo: 1})      # => {"foo"=>1}
schema.validate!({foo: 'bar'})  # => {"foo"=>"bar"}
```

##### Pattern Properties

In addition to symbols, property keys can also be a regular expression. Here,
you may only use the optional `?` suffix for the property. This allows any
property, which matches the type and the name of the property matches the
regular expression.

```ruby
schema = Schemacop::Schema3.new :hash do
  # The following statement allows any number of integer properties of which the
  # name starts with `id_`.
  int? /^id_.*$/
end

schema.validate!({})                      # => {}
schema.validate!({id_foo: 1})             # => {"id_foo"=>1}
schema.validate!({id_foo: 1, id_bar: 2})  # => {"id_foo"=>1, "id_bar"=>2}
schema.validate!({foo: 3})                # => Schemacop::Exceptions::ValidationError: /: Obsolete property "foo".
```

##### Additional Properties & Property Names

In addition to standard properties, you can allow the hash to contain
additional, unspecified properties. By default, this is turned off if you have
defined at least one standard property.

When it comes to additional properties, you have the choice to either just
enable all of them by enabling the option `additional_properties`:

```ruby
# This schema will accept any additional properties
schema = Schemacop::Schema3.new :hash, additional_properties: true

schema.validate!({}) # => {}
schema.validate!({foo: :bar, baz: 42}) # => {"foo"=>:bar, "baz"=>42}
```

Using the DSL method `add` in the hash-node's body however, you can specify
an additional schema to which additional properties must adhere:


```ruby
Schemacop::Schema3.new :hash do
  int! :id

  # Allow any additional properties besides `id`, but their value must be a
  # string.
  add :string
end

schema.validate!({id: 1})             # => {"id"=>1}
schema.validate!({id: 1, foo: 'bar'}) # => {"id"=>1, "foo"=>"bar"}
schema.validate!({id: 1, foo: 42})    # => Schemacop::Exceptions::ValidationError: /foo: Invalid type, got type "Integer", expected "string".
```

Using the option `property_names`, you can additionaly specify a pattern that
any additional property **keys** must adhere to:

```ruby
# The following schema allows any number of properties, but all keys must
# consist of downcase letters from a-z.
schema = Schemacop::Schema3.new :hash, additional_properties: true, property_names: '^[a-z]+$'


schema.validate!({})            # => {}
schema.validate!({foo: 123})    # => {"foo"=>123}
schema.validate!({Foo: 'bar'})  # => Schemacop::Exceptions::ValidationError: /: Property name "Foo" does not match "^[a-z]+$".

# The following schema allows any number of properties, but all keys must
# consist of downcase letters from a-z AND the properties must be arrays.
schema = Schemacop::Schema3.new :hash, additional_properties: true, property_names: '^[a-z]+$' do
  add :array
end

schema.validate!({})                # => {}
schema.validate!({foo: [1, 2, 3]})  # => {"foo"=>[1, 2, 3]}
schema.validate!({foo: :bar})       # => Schemacop::Exceptions::ValidationError: /foo: Invalid type, got type "Symbol", expected "array".
schema.validate!({Foo: :bar})       # => Schemacop::Exceptions::ValidationError: /: Property name :Foo does not match "^[a-z]+$". /Foo: Invalid type, got type "Symbol", expected "array".
```

##### Ignoring Obsolete Properties

By enabling `ignore_obsolete_properties`, you can filter out any unspecified params,
while still passing validation:

```ruby
# This schema will accept any additional properties, but remove them from the result
schema = Schemacop::Schema3.new :hash, ignore_obsolete_properties: true do
  int? :foo
end

schema.validate!({}) # => {}
schema.validate!({foo: :bar}) # => {"foo"=>:bar}
schema.validate!({foo: :bar, baz: 42}) # => {"foo"=>:bar}
```

##### Parsing JSON

By enabling `parse_json`, the given value will be parsed as JSON if it is a
string instead of a hash:

```ruby
# This schema will accept any additional properties, but remove them from the result
schema = Schemacop::Schema3.new :hash, parse_json: true do
  int! :id
  str! :name
end

schema.validate!({
  id: 42,
  name: 'Jane Doe'
}) # => { id: 42, name: 'Jane Doe' }
schema.validate!('{ "id": 42, name: "Jane Doe" }') # => { "id" => 42, "name" => 'Jane Doe' }
```

Note that the parsed JSON will always result in string hash keys, not symbols.

##### Dependencies

Using the DSL method `dep`, you can specifiy (non-nested) property dependencies:

```ruby
# In this example, `billing_address` and `phone_number` are required if
# `credit_card` is given, and `credit_card` is required if `billing_address` is
# given.
schema = Schemacop::Schema3.new :hash do
  str! :name
  str? :credit_card
  str? :billing_address
  str? :phone_number

  dep :credit_card, :billing_address, :phone_number
  dep :billing_address, :credit_card
end

schema.validate!({}) # => Schemacop::Exceptions::ValidationError: /name: Value must be given.
schema.validate!({name: 'Joe Doe'}) # => {"name"=>"Joe Doe"}
schema.validate!({
  name: 'Joe Doe',
  billing_address: 'Street 42'
})
# => Schemacop::Exceptions::ValidationError: /: Missing property "credit_card" because "billing_address" is given.

schema.validate!({
  name: 'Joe Doe',
  credit_card: 'XXXX XXXX XXXX XXXX X'
})
# => Schemacop::Exceptions::ValidationError: /: Missing property "billing_address" because "credit_card" is given. /: Missing property "phone_number" because "credit_card" is given.

schema.validate!({
  name: 'Joe Doe',
  billing_address: 'Street 42',
  phone_number: '000-000-00-00',
  credit_card: 'XXXX XXXX XXXX XXXX X'
})
# => {"name"=>"Joe Doe", "credit_card"=>"XXXX XXXX XXXX XXXX X", "billing_address"=>"Street 42", "phone_number"=>"000-000-00-00"}
```

### Object

Type: `:object`\
DSL: `obj`

The object type represents a Ruby `Object`. Please note that the `as_json`
method on nodes of this type will just return `{}` (an empty JSON object), as
there isn't a useful way to represent a Ruby object without conflicting with the
`Hash` type. If you want to represent a JSON object, you should use the `Hash`
node.

In the most basic form, this node will accept anything:

```ruby
schema = Schemacop::Schema3.new :object

schema.validate!(nil)         # => nil
schema.validate!(true)        # => true
schema.validate!(false)       # => false
schema.validate!(Object.new)  # => #<Object:0x0000556ab4f58dd0>
schema.validate!('foo')       # => "foo"
```

If you want to limit the allowed classes, you can so so by specifying an array
of allowed classes:

```ruby
schema = Schemacop::Schema3.new :object, classes: [String]

schema.validate!(nil)             # => nil
schema.validate!(true)            # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "TrueClass", expected "String".
schema.validate!(Object.new)      # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "Object", expected "String".
schema.validate!('foo')           # => "foo"
schema.validate!('foo'.html_safe) # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "ActiveSupport::SafeBuffer", expected "String".
```

Here, the node checks if the given value is an instance of any of the given
classes with `instance_of?`, i.e. the exact class and not a subclass.

If you want to allow subclasses, you can specify this by using the `strict` option:

```ruby
schema = Schemacop::Schema3.new :object, classes: [String], strict: false

schema.validate!(nil)             # => nil
schema.validate!(true)            # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "TrueClass", expected "String".
schema.validate!(Object.new)      # => Schemacop::Exceptions::ValidationError: /: Invalid type, got type "Object", expected "String".
schema.validate!('foo')           # => "foo"
schema.validate!('foo'.html_safe) # => "foo"
```

If you set the `strict` option to `false`, the check is done using `is_a?` instead of
`instance_of?`, which also allows subclasses

### AllOf

Type: `:all_of`\
DSL: `all_of`

With the AllOf node you can specify multiple schemas, for which the given value
needs to validate against every one:

```ruby
schema = Schemacop::Schema3.new :all_of do
  str min_length: 2
  str max_length: 4
end

schema.validate!('foo')   # => "foo"
schema.validate!('foooo') # => Schemacop::Exceptions::ValidationError: /: Does not match all allOf conditions.
```

Please note that it's possible to create nonsensical schemas with this node, as
you can combine multiple schemas which contradict each other:

```ruby
schema = Schemacop::Schema3.new :all_of do
  str min_length: 4
  str max_length: 1
end

schema.validate!('foo')   # => Schemacop::Exceptions::ValidationError: /: Does not match all allOf conditions.
schema.validate!('foooo') # => Schemacop::Exceptions::ValidationError: /: Does not match all allOf conditions.
```

### AnyOf

Type: `:any_of`\
DSL: `any_of`

Similar to the `all_of` node, you can specify multiple schemas, for which the
given value needs to validate against at least one of the schemas.

For example, your value needs to be either a string which is at least 2
characters long, or an integer:

```ruby
schema = Schemacop::Schema3.new :any_of do
  str min_length: 2
  int
end

schema.validate!('f')   # => Schemacop::Exceptions::ValidationError: /: Does not match any anyOf condition.
schema.validate!('foo') # => "foo"
schema.validate!(42)    # => 42
```

Please note that you need to specify at least one item in the `any_of` node:

```ruby
Schemacop::Schema3.new :any_of # => Schemacop::Exceptions::InvalidSchemaError: Node "any_of" makes only sense with at least 1 item.
```

### OneOf

Type: `:one_of`\
DSL: `one_of`

Similar to the `all_of` node, you can specify multiple schemas, for which the
given value needs to validate against exaclty one of the schemas. If the given
value validates against multiple schemas, the value is invalid.

For example, if you want an integer which is either a multiple of 2 or 3,
but not both (i.e. no multiple of 6), you could do it as follows:

```ruby
schema = Schemacop::Schema3.new :one_of do
  int multiple_of: 2
  int multiple_of: 3
end

schema.validate!(2) # => 2
schema.validate!(3) # => 3
schema.validate!(4) # => 4
schema.validate!(5) # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!(6) # => Schemacop::Exceptions::ValidationError: /: Matches 2 definitions but should match exactly 1.
```

Again, as previously with the AllOf node, you're allowed to create schemas
which will not work for any input, e.g. by specifying the same schema twice:

```ruby
schema = Schemacop::Schema3.new :one_of do
  int multiple_of: 2
  int multiple_of: 2
end

schema.validate!(2) # => Schemacop::Exceptions::ValidationError: /: Matches 2 definitions but should match exactly 1.
schema.validate!(3) # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!(4) # => Schemacop::Exceptions::ValidationError: /: Matches 2 definitions but should match exactly 1.
schema.validate!(5) # => Schemacop::Exceptions::ValidationError: /: Matches 0 definitions but should match exactly 1.
schema.validate!(6) # => Schemacop::Exceptions::ValidationError: /: Matches 2 definitions but should match exactly 1.
```

### IsNot

Type: `:is_not`\
DSL: `is_not`

With the `is_not` node, you can specify a schema which the given value must not
validate against, i.e. every value which matches the schema will make this node
invalid.

For example, you want anything but the numbers between 3 and 5:

```ruby
schema = Schemacop::Schema3.new :is_not do
  int minimum: 3, maximum: 5
end

schema.validate!(nil)   # => nil
schema.validate!(1)     # => 1
schema.validate!(2)     # => 2
schema.validate!(3)     # => Schemacop::Exceptions::ValidationError: /: Must not match schema: {"type"=>"integer", "minimum"=>3, "maximum"=>5}.
schema.validate!('foo') # => "foo"
```

Note that a `is_not` node needs exactly one item:

```ruby
schema = Schemacop::Schema3.new :is_not # => Schemacop::Exceptions::InvalidSchemaError: Node "is_not" only allows exactly one item.
```

### Reference

**Referencing**
DSL: `ref`\
Type: `reference`

**Definition**
DSL: `scm`

Finally, with the *Reference* node, you can define schemas and then later reference
them for usage, e.g. when you have a rather long schema which you need at multiple
places.

#### Examples

For example, let's define an object with an schema called `Address`, which we'll
reference multiple times:

```ruby
schema = Schemacop::Schema3.new :hash do
  scm :Address do
    str! :street
    str! :zip_code
    str! :location
    str! :country
  end

  ref! :shipping_address, :Address
  ref! :billing_address, :Address
end

schema.validate!({}) # => Schemacop::Exceptions::ValidationError: /shipping_address: Value must be given. /billing_address: Value must be given.
schema.validate!({
  shipping_address: 'foo',
  billing_address: 42
})
# => Schemacop::Exceptions::ValidationError: /shipping_address: Invalid type, got type "String", expected "object". /billing_address: Invalid type, got type "Integer", expected "object".

schema.validate!({
  shipping_address: {
    street:   'Example Street 42',
    zip_code: '12345',
    location: 'London',
    country:  'United Kingdom'
  },
  billing_address: {
    street:   'Main St.',
    zip_code: '54321',
    location: 'Washington DC',
    country:  'USA'
  }
})

# => {"shipping_address"=>{"street"=>"Example Street 42", "zip_code"=>"12345", "location"=>"London", "country"=>"United Kingdom"}, "billing_address"=>{"street"=>"Main St.", "zip_code"=>"54321", "location"=>"Washington DC", "country"=>"USA"}}
```

Note that if you use the reference node with the long type name `reference`,
e.g. in an array, you need to specify the "name" of the schema in the
`path` option:

```ruby
schema = Schemacop::Schema3.new :array do
  scm :User do
    str! :first_name
    str! :last_name
  end

  list :reference, path: :User
end

schema.validate!([])                                      # => []
schema.validate!([{first_name: 'Joe', last_name: 'Doe'}]) # => [{"first_name"=>"Joe", "last_name"=>"Doe"}]
schema.validate!([id: 42, first_name: 'Joe'])             # => Schemacop::Exceptions::ValidationError: /[0]/last_name: Value must be given. /[0]: Obsolete property "id".
```

#### Inline References

By passing `nil` as the name, you can "inline" a referenced schema into the
parent hash. Instead of nesting the referenced properties under a key, they are
unpacked directly into the parent:

```ruby
schema = Schemacop::Schema3.new :hash do
  scm :BasicInfo do
    int! :id
    str! :name
  end

  ref! nil, :BasicInfo
  str! :extra
end

# Properties from the referenced schema are validated at the top level
schema.validate!({id: 1, name: 'John', extra: 'info'})
# => {"id"=>1, "name"=>"John", "extra"=>"info"}

# Required properties from the ref are enforced
schema.validate!({extra: 'info'})
# => Schemacop::Exceptions::ValidationError: /id: Value must be given. /name: Value must be given.

# Unknown properties are still rejected
schema.validate!({id: 1, name: 'John', extra: 'info', unknown: 'value'})
# => Schemacop::Exceptions::ValidationError: /: Obsolete property "unknown".
```

Casting works as expected — values from the inline ref are cast according to the
referenced schema's types:

```ruby
schema = Schemacop::Schema3.new :hash do
  scm :BasicInfo do
    str! :born_at, format: :date
    str! :name
  end

  ref! nil, :BasicInfo
  str! :extra
end

result = schema.validate!({born_at: '1990-01-13', name: 'John', extra: 'info'})
result[:born_at] # => Date<"Sat, 13 Jan 1990">
```

You can also use multiple inline refs in the same hash:

```ruby
schema = Schemacop::Schema3.new :hash do
  scm :BasicInfo do
    int! :id
    str! :name
  end

  scm :Timestamps do
    str! :created_at, format: :date
  end

  ref! nil, :BasicInfo
  ref! nil, :Timestamps
  str! :extra
end

schema.validate!({id: 1, name: 'John', created_at: '2024-01-01', extra: 'info'})
# => {"id"=>1, "name"=>"John", "created_at"=>Mon, 01 Jan 2024, "extra"=>"info"}
```

If a direct property has the same name as one from the inline ref, the direct
property takes precedence:

```ruby
schema = Schemacop::Schema3.new :hash do
  scm :BasicInfo do
    str! :name
  end

  ref! nil, :BasicInfo
  int! :name  # Direct property takes precedence
end

schema.validate!({name: 42})      # => {"name"=>42}
schema.validate!({name: 'John'})
# => Schemacop::Exceptions::ValidationError: /name: Invalid type, got type "String", expected "integer".
```

In the JSON / Swagger output, inline refs produce an `allOf` array containing
the `$ref` entries alongside the hash's own properties:

```ruby
schema = Schemacop::Schema3.new :hash do
  scm :BasicInfo do
    int! :id
    str! :name
  end

  ref! nil, :BasicInfo
  str! :extra
end

schema.as_json
# => {
#   "allOf" => [
#     { "$ref" => "#/definitions/BasicInfo" },
#     {
#       "type" => "object",
#       "properties" => { "extra" => { "type" => "string" } },
#       "additionalProperties" => false,
#       "required" => ["extra"]
#     }
#   ],
#   "definitions" => {
#     "BasicInfo" => {
#       "properties" => { "id" => { "type" => "integer" }, "name" => { "type" => "string" } },
#       "additionalProperties" => false,
#       "required" => ["id", "name"],
#       "type" => "object"
#     }
#   },
#   "type" => "object"
# }
```

## Context

Schemacop also features the concept of a `Context`. You can define schemas in a
context, and then reference them in other schemas in that context. This is e.g.
useful if you need a part of the schema to be different depending on the
business action.

Examples:

```ruby
# Define a new context
context = Schemacop::V3::Context.new

# Define the :Person schema in that context
context.schema :Person do
  str! :first_name
  str! :last_name
  ref? :info, :PersonInfo
end

# And also define the :PersonInfo schema in that context
context.schema :PersonInfo do
  str! :born_at, format: :date
end

# Now we can define our general schema, where we reference the :Person schema.
# Note that at this point, we don't know what's in the :Person schema.
schema = Schemacop::Schema3.new :reference, path: :Person

# Validate the data in the context we defined before, where we need the first_name
# and last_name of a person, as well as an optional info hash with the born_at date
# of the person.
Schemacop.with_context context do
  schema.validate!({first_name: 'Joe', last_name: 'Doe', info: { born_at: '1980-01-01'} })
  # => {"first_name"=>"Joe", "last_name"=>"Doe", "info"=>{"born_at"=>Tue, 01 Jan 1980}}
end

# Now we might want another context, where the person is more anonymous, and as
# such, we need another schema
other_context = Schemacop::V3::Context.new

# Here, we only want the nickname of the person
other_context.schema :Person do
  str! :nickname
end

# Finally, validate the data in the new context. We do not want the real name or
# birth date of the person, instead only the nickname is allowed.
Schemacop.with_context other_context do
  schema.validate!({first_name: 'Joe', last_name: 'Doe', info: { born_at: '1980-01-01'} })
  # => Schemacop::Exceptions::ValidationError: /nickname: Value must be given.
  #    /: Obsolete property "first_name".
  #    /: Obsolete property "last_name".
  #    /: Obsolete property "info".

  schema.validate!({nickname: 'J.'}) # => {"nickname"=>"J."}
end
```

As one can see, we validated the data against the same schema, but because we
defined the referenced schemas differently in the two contexts, we were able
to use other data in the second context than in the first.

## External schemas

Finally, Schemacop features the possibility to specify schemas in separate
files.  This is especially useful is you have schemas in your application which
are used multiple times throughout the application.

For each schema, you define the schema in a separate file, and after loading the
schemas, you can reference them in other schemas. The schema can be retrieved
by using the file name, e.g. `user` in the example `app/schemas/user.rb` below.

The default load path is `'app/schemas'`, but this can be configured by setting
the value of the `load_paths` attribute of the `Schemacop` module.

Please note that the following predescence order is used for the schemas:

```
local schemas > context schemas > global schemas
```

Where:

* local schemas: Defined by using the DSL method `scm`
* context schemas: Defined in the current context using `context.schema`
* global schemas: Defined in a ruby file in the load path

### External Schemas in Rails Applications

In Rails applications, your schemas are automatically eager-loaded from the load
path `'app/schemas'` when your application is started, unless your application
is running in the `DEVELOPMENT` environment. In the `DEVELOPMENT` environment,
schemas are loaded each time when they are used, and as such you can make changes
to your external schemas without having to restart the server each time.

After starting your application, you can reference them like normally defined
reference schemas, with the name being relative to the load path.

Example:

You defined the following two schemas in the `'app/schemas'` directory:

```ruby
# app/schemas/user.rb
schema :hash do
  str! :first_name
  str! :last_name
  ary? :groups do
    list :reference, path: 'nested/group'
  end
end
```

```ruby
# app/schemas/nested/group.rb
schema :hash do
  str! :name
end
```

To use the schema, you then can simply reference the schema as with normal
reference schemas:

```ruby
schema = Schemacop::Schema3.new :hash do
  ref! :usr, :user
end

schema.validate!({usr: {first_name: 'Joe', last_name: 'Doe'}})
  # => {"usr"=>{"first_name"=>"Joe", "last_name"=>"Doe"}}

schema.validate!({usr: {first_name: 'Joe', last_name: 'Doe', groups: []}})
  # => {"usr"=>{"first_name"=>"Joe", "last_name"=>"Doe", "groups"=>[]}}

schema.validate!({usr: {first_name: 'Joe', last_name: 'Doe', groups: [{name: 'foo'}, {name: 'bar'}]}})
  # => {"usr"=>{"first_name"=>"Joe", "last_name"=>"Doe", "groups"=>[{"name"=>"foo"}, {"name"=>"bar"}]}}
```

### External Schemas in Non-Rails Applications

Usage in non-Rails applications is the same as with usage in Rails applications,
however you might need to eager load the schemas yourself:

```ruby
Schemacop::V3::GlobalContext.eager_load!
```

As mentioned before, you can also use the external schemas without having to
eager-load them, but if you use the schemas multiple times, it might be better
to eager-load them on start of your application / script.

## Default options

Using the setting `Schemacop.v3_default_options`, you can specify a hash
containing default options that will be used for every schemacop node (options
not supported by a particular node are automatically ignored). Options passed
directly to a node still take precedence.

### Rails applications

For Rails applications, configure default options in `config/schemacop.rb`
(note: not in the `initializers/` subdirectory). This ensures that options are
applied before schemas are eager loaded in production mode:

```ruby
# config/schemacop.rb
Schemacop.v3_default_options = { cast_str: true }.freeze
```

### Non-Rails applications

For non-Rails applications, set the options before loading any schemas:

```ruby
Schemacop.v3_default_options = { cast_str: true }.freeze

# Example schema: As cast_str is enabled in the default options, strings will
# automatically be casted where supported.
schema = Schemacop::Schema3.new(:integer)
schema.validate!('42')  # => 42
```
