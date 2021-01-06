# Schemacop schema V3


# Table of Contents
1. [Introcution](#Introcution)
2. [Generic Keywords](#generic-keywords)
3. [Nodes](#nodes)
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
4. [Context](#context)
5. [External schemas](#external-schemas)

## Introcution

TODO: Write short section about using schemacop V3

## Generic Keywords

* enum
* title
* description
* examples

* cast_str?

## Nodes

### String

Type: `:string`\
DSL: `str`

The string type is used for strings of text and must be a ruby `String` object
or a subclass. Using the option `format`, strings can be validated against and
transformed into various types.

#### Options

* `min_length`
  Defines the minimum required string length
* `max_length`
  Defines the maximum required string length
* `pattern`
  Defines a (ruby) regex pattern the value will be matched against. Must be a
  string and should generally start with `^` and end with `$` so as to evaluate
  the entire string. It should not be enclosed in `/` characters.
* `format`
  The `format` option allows for basic semantic validation on certain kinds of
  string values that are commonly used. See section *formats* for more
  information on the available formats. Note that strings with a format are also
  **casted** into that format.

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

* `boolean`
  The string must be either `true` or `false`. This value will be casted to
  ruby's `TrueClass` or `FalseClass`.

* `binary`
  The string is expected to contain binary contents. No casting or additional
  validation is performed.

* `integer`
  The string must be an integer and will be casted to a ruby `Integer` object.

* `number`
  The string must be a number and will be casted to a ruby `Float` object.

#### Examples

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

#### Examples

```ruby
# Validates that the input is an even number between 0 and 100 (inclusive)
schema = Schemacop::Schema3.new(:integer, minimum: 0, maximum: 100, multiple_of: 2)
schema.validate!(42)            # => 42
schema.validate!(43)            # => Schemacop::Exceptions::ValidationError: /: Value must be a multiple of 2.
schema.validate!(-2)            # => Schemacop::Exceptions::ValidationError: /: Value must have a minimum of 0.
schema.validate!(102)           # => Schemacop::Exceptions::ValidationError: /: Value must have a maximum of 100.
schema.validate!(42.1)          # => Schemacop::Exceptions::ValidationError: /: Invalid type, expected "integer".
schema.validate!(4r)            # => Schemacop::Exceptions::ValidationError: /: Invalid type, expected "integer".
schema.validate!((4 + 0i))      # => Schemacop::Exceptions::ValidationError: /: Invalid type, expected "integer".
schema.validate!(BigDecimal(5)) # => Schemacop::Exceptions::ValidationError: /: Invalid type, expected "integer".
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

As some subclasses of `Numeric`, such as `Complex` don't support all required oeprations,
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

#### Examples

```ruby
# Validates that the input is an even number between 0 and 100 (inclusive)
schema = Schemacop::Schema3.new(:number, minimum: 0.0, maximum: (50r), multiple_of: BigDecimal('0.5'))
schema.validate!(42)            # => 42
schema.validate!(42.2)          # => Schemacop::Exceptions::ValidationError: /: Value must be a multiple of 0.5.
schema.validate!(-2)            # => Schemacop::Exceptions::ValidationError: /: Value must have a minimum of 0.0.
schema.validate!(51)            # => Schemacop::Exceptions::ValidationError: /: Value must have a maximum of 50/1.
schema.validate!(42.5)          # => 42.5
schema.validate!(1.5r)          # => (3/2)
schema.validate!(BigDecimal(5)) # => 0.5e1
schema.validate!((4 + 0i))      # => Schemacop::Exceptions::ValidationError: /: Invalid type, expected "big_decimal" or "float" or "integer" or "rational".
```

### Symbol

Type: `:symbol`\
DSL: `sym`

### Boolean

Type: `:boolean`\
DSL: `boo`

### Array

Type: `:array`\
DSL: `arr`

### Hash

Type: `:hash`\
DSL: `hsh`

The hash type represents a ruby `Hash` or an `object` in JSON schema language.
It consists of key-value-pairs that can be validated using arbitrary nodes.

#### Options

* `additional_properties`

  This option specifies whether additional, unspecified properties are allowed
  (`true`) or not (`false`). By default, this is `true` if no properties are
  specified and `false` if you have specified at least one property.

* `property_names`

  This option allows to specify a regexp pattern (as string) which validates the
  keys of any properties that are not specified in the hash. This option only
  makes sense if `additional_properties` is enabled.

* `min_properties`

  Specifies the (inclusive) minimum number of properties a hash must contain.

* `max_properties`

  Specifies the (inclusive) maximum number of properties a hash must contain.

#### Specifying properties

Hash nodes support a block in which you can specify the required hash contents.

##### Standard properties

It supports all type nodes, but requires the suffix `?` or `!` for each
property, which specifies whether a property is required (`!`) or optional
(`?`).

```ruby
str! :my_required_property
int! :my_optional_property
```

##### Pattern properties

In addition to symbols, property keys can also be a regular expression:

```ruby
Schemacop::Schema3.new do
  str! :name

  # The following statement allows any number of integer properties of which the
  # name starts with `id_`.
  int! /^id_.*$/
end
```

For example, the above example would successfully validate the following hash:

```ruby
{ name: 'John Doe', id_a: 42, id_b: 42 }
```

##### Additional properties & property names

In addition to standard properties, you can allow the hash to contain
additional, unspecified properties. By default, this is turned off if you have
defined at least one standard property.

When it comes to additional properties, you have the choice to either just
enable all of them by enabling the option `additional_properties`. Using the DSL
method `add` in the hash-node's body however, you can specify an additional
schema to which additional properties must adhere:

```ruby
Schemacop::Schema3.new do
  int! :id

  # Allow any additional properties besides `id`, but their value must be a
  # string. Note that using the `add` node, the option `additional_properties`
  # is automatically enabled.
  add :str
end
```

Using the option `property_names`, you can additionaly specify a pattern that
any additional property **keys** must adhere to:

```ruby
# The following schema allows any number of properties, but all keys must
# consist of downcase letters from a-z.
Schemacop::Schema3.new additional_properties: :true, property_names: '^[a-z]+$'

# The following schema allows any number of properties, but all keys must
# consist of downcase letters from a-z AND the properties must be arrays.
Schemacop::Schema3.new additional_properties: :true, property_names: '^[a-z]+$' do
  add :array
end
```

##### Dependencies

Using the DSL method `dep`, you can specifiy (non-nested) property dependencies:

```ruby
# In this example, `billing_address` and `phone_number` are required if
# `credit_card` is given, and `credit_card` is required if `billing_address` is
# given.
Schemacop::Schema3.new do
  str! :name
  str? :credit_card
  str? :billing_address
  str? :phone_number

  dep :credit_card, :billing_address, :phone_number
  dep :billing_address, :credit_card
end
```

#### Examples
```ruby
schema = Schemacop::Schema3.new do
  # Define built-in schema 'address' for re-use
  scm :address do
    str! :street
    int! :number
    str! :zip
  end

  int? :id
  str! :name

  # Reference above defined schema 'address' and use it for key 'address'
  ref! :address, :address

  # Reference above defined schema 'address' and use it as contents for array
  # in key `additional_addresses`
  ary! :additional_addresses, default: [] do
    ref :address
  end
  ary? :comments, :array, default: [] { str }

  # Define a hash with key `jobs` that needs at least one property, and all
  # properties must be valid integers and their values must be strings.
  hsh! :jobs, min_properties: 1 do
    str? /^[0-9]+$/
  end
end

schema.valid?(
  id:      42,
  name:    'John Doe',
  address: {
    street: 'Silver Street',
    number: 4,
    zip:    '38234C'
  },
  additional_addresses: [
    { street: 'Example street', number: 42, zip: '8048' }
  ],
  comments: [
    'This is a comment'
  ],
  jobs: {
    2020 => 'Software Engineer'
  }
) # => true
```

```ruby
# The following schema supports exactly the properties defined below, `options`
# being a nested hash.
Schemacop::Schema3.new do
  int? :id         # Optional integer with key 'id'
  str! :name       # Required string with name 'name'
  hsh! :options do # Required hash with name `options`
    boo! :enabled  # Required boolean with name `enabled`
  end
end

# Allow any hash with any contents.
Schemacop::Schema3.new(additional_properties: true)

# Allow a hash where `id` is given, but any additional properties of any name
# and any type are supported as well.
Schemacop::Schema3.new(additional_properties: true) do
  int! :id
end

# Allow a hash where `id` is given, but any additional properties of which the
# key starts with `k_` and of any value type are allowed.
Schemacop::Schema3.new(additional_properties: true, property_names: '^k_.*$') do
  int! :id
end

# Allow a hash where `id` is given, but any additional properties of which the
# key starts with `k_` and the additional value is a string are allowed.
Schemacop::Schema3.new(additional_properties: true, property_names: '^k_.*$') do
  int! :id
  add :string
end

# Allow a hash where `id` is given, and any additional string properties that start
# with `k_` are allowed. At least one string with key `k_*` must be given though
# as this property is required.
Schemacop::Schema3.new(property_names: '^k_.*$') do
  int! :id
  str! /^k_.*$/
end
```

### Object

Type: `:object`\
DSL: `obj`

### AllOf

Type: `:all_of`\
DSL: `all_of`

### AnyOf

Type: `:any_of`\
DSL: `any_of`

### OneOf

Type: `:one_of`\
DSL: `one_of`

### IsNot

Type: `:is_not`\
DSL: `is_not`

### Reference

DSL: `ref`

