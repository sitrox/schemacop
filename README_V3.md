# Schemacop schema V3

Please note that Schemacop v3 is still a work in progress, especially the documentation.

Use at your own discretion.

# Table of Contents
1. [Introcution](#Introcution)
2. [Validation](#validation)
3. [Exceptions](#exceptions)
4. [Generic Keywords](#generic-keywords)
5. [Nodes](#nodes)
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
6. [Context](#context)
7. [External schemas](#external-schemas)

## Introcution

TODO: Write short section about using schemacop V3

## Validation

Using schemacop, you can either choose to validate the data either using the
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

TODO: Describe the exceptions raised by schemacop

`Schemacop::Exceptions::ValidationError`
`Schemacop::Exceptions::InvalidSchemaError`

## Generic Keywords

TODO: Complete this

* enum
* title
* description
* examples

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
# Validates that the input is a number between 0 and 50 (inclusive) and a multiple of 0.5
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

The symbol type is used to validate elements for the Ruby `Symbol` class.

#### Examples

```ruby
# Validates that the input is a symbol
schema = Schemacop::Schema3.new(:symbol)
schema.validate!(:foo)  # => :foo
schema.validate!('foo') # => Schemacop::Exceptions::ValidationError: /: Invalid type, expected "Symbol".
schema.validate!(123)   # => Schemacop::Exceptions::ValidationError: /: Invalid type, expected "Symbol".
schema.validate!(false) # => Schemacop::Exceptions::ValidationError: /: Invalid type, expected "Symbol".
```

### Boolean

Type: `:boolean`\
DSL: `boo`

The boolean type is used to validate Ruby booleans, i.e. the `TrueClass` and `FalseClass`

#### Examples

```ruby
# Validates that the input is a boolean
schema = Schemacop::Schema3.new(:boolean)
schema.validate!(true)    # => true
schema.validate!(false)   # => false
schema.validate!(:false)  # => Schemacop::Exceptions::ValidationError: /: Invalid type, expected "boolean".
schema.validate!('false') # => Schemacop::Exceptions::ValidationError: /: Invalid type, expected "boolean".
schema.validate!(1234)    # => Schemacop::Exceptions::ValidationError: /: Invalid type, expected "boolean".
```

### Array

Type: `:array`\
DSL: `arr`

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
  This option specifies wether the items in the array must all be distinct from
  each other, or if there may be duplicate values. By default, this is false,
  i.e. duplicate values are allowed

#### Contains

The `array` node features the contains node, which you can use with the DSL
method `cont`. With that DSL method, you can specify a schema which at least
one item in the array needs to validate against.

One usecase for example could be that you want an array of integers, from which
at least one must be 5 or larger:

```ruby
schema = Schemacop::Schema3.new :array do
  list :integer
  cont :integer, minimum: 5
end

schema.validate!([])      # => Schemacop::Exceptions::ValidationError: /: At least one entry must match schema {"type"=>"integer", "minimum"=>5}.
schema.validate!([1, 5])  # => [1, 5]
schema.validate!(['foo']) # => Schemacop::Exceptions::ValidationError: /[0]: Invalid type, expected "integer". /: At least one entry must match schema {"type"=>"integer", "minimum"=>5}
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

#### Specifying properties

Array nodes support a block in which you can specify the required array contents.
The array nodes support either list validation, or tuple validation, depending on
how you specify your array contents.

##### List validation

List validation validates a sequence of arbitrary length where each item matches
the same schema. Unless you specify a `min_items` count on the array node, an
empty array will also validate. To specify a list validation, use the `list`
DSL method, and specify the type you want to validate against. Here, you need
to specify the type of the element using the long `type` name (e.g. `integer` and not `int`).

For example, you can specify that you want an array with only integers between 1 and 5:

```ruby
schema = Schemacop::Schema3.new :array do
  list :integer, minimum: 1, maximum: 5
end

schema.validate!([])     # => []
schema.validate!([1, 3]) # => [1, 3]
schema.validate!([0, 6]) # => Schemacop::Exceptions::ValidationError: /[0]: Value must have a minimum of 1. /[1]: Value must have a maximum of 5.
schema.validate! ['foo'] # => Schemacop::Exceptions::ValidationError: /[0]: Invalid type, expected "integer".
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
schema.validate!([['foo'], [2, 3]]) # => Schemacop::Exceptions::ValidationError: /[0]/[0]: Invalid type, expected "integer".
```

Please note that you can only specify *one* `list` item:

```ruby
schema = Schemacop::Schema3.new :array do
  list :integer
  list :string
end

# => Schemacop::Exceptions::InvalidSchemaError: You can only use "list" once.
```

##### Tuple validation

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
schema.validate!([1, 'foo', 'bar']) # => Schemacop::Exceptions::ValidationError: /[2]: Invalid type, expected "integer".
schema.validate!([1, 'foo', 2, 3])  # => [1, "foo", 2, 3]
```

Please note, that you cannot use multiple `add` in the same array schema, this will result in
an exception:

```ruby
schema = Schemacop::Schema3.new :array do
  int
  add :integer
  add :string
end

# => Schemacop::Exceptions::InvalidSchemaError: You can only use "add" once to specify additional items.
```

If you want to specify that your schema accept multiple additional types, use the `one_of`
type (see below for more infos). The correct way to specify that you want to allow additional
items, which may be an integer or a string is as follows:

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
  makes sense if `additional_properties` is enabled. See below for more informations.

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
schema = Schemacop::Schema3.new :hash do
  str! :foo # Is a required property
  int? :bar # Is an optional property
end

schema.validate!({})                    # => Schemacop::Exceptions::ValidationError: /foo: Value must be given.
schema.validate!({foo: 'str'})          # => {:foo=>"str"}
schema.validate!({foo: 'str', bar: 42}) # => {:foo=>"str", :bar=>42}
schema.validate!({bar: 42})             # => Schemacop::Exceptions::ValidationError: /foo: Value must be given.
```

##### Pattern properties

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
schema.validate!({id_foo: 1})             # => {:id_foo=>1}
schema.validate!({id_foo: 1, id_bar: 2})  # => {:id_foo=>1, :id_bar=>2}
schema.validate!({foo: 3})                # => Schemacop::Exceptions::ValidationError: /: Obsolete property "foo".
```

##### Additional properties & property names

In addition to standard properties, you can allow the hash to contain
additional, unspecified properties. By default, this is turned off if you have
defined at least one standard property.

When it comes to additional properties, you have the choice to either just
enable all of them by enabling the option `additional_properties`:

```ruby
# This schema will accept any additional properties
schema = Schemacop::Schema3.new :hash, additional_properties: true

schema.validate!({}) # => {}
schema.validate!({foo: :bar, baz: 42}) # => {:foo=>:bar, :baz=>42}
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

schema.validate!({id: 1})             # => {:id=>1}
schema.validate!({id: 1, foo: 'bar'}) # => {:foo=>"bar", :id=>1}
schema.validate!({id: 1, foo: 42})    # => Schemacop::Exceptions::ValidationError: /foo: Invalid type, expected "string".
```

Using the option `property_names`, you can additionaly specify a pattern that
any additional property **keys** must adhere to:

```ruby
# The following schema allows any number of properties, but all keys must
# consist of downcase letters from a-z.
schema = Schemacop::Schema3.new :hash, additional_properties: :true, property_names: '^[a-z]+$'


schema.validate!({})            # => {}
schema.validate!({foo: 123})    # => {:foo=>123}
schema.validate!({Foo: 'bar'})  # => Schemacop::Exceptions::ValidationError: /: Property name :Foo does not match "^[a-z]+$".

# The following schema allows any number of properties, but all keys must
# consist of downcase letters from a-z AND the properties must be arrays.
schema = Schemacop::Schema3.new :hash, additional_properties: true, property_names: '^[a-z]+$' do
  add :array
end

schema.validate!({})                # => {}
schema.validate!({foo: [1, 2, 3]})  # => {:foo=>[1, 2, 3]}
schema.validate!({foo: :bar})       # => Schemacop::Exceptions::ValidationError: /foo: Invalid type, expected "array".
schema.validate!({Foo: :bar})       # => Schemacop::Exceptions::ValidationError: /: Property name :Foo does not match "^[a-z]+$". /Foo: Invalid type, expected "array".
```

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
schema.validate!({name: 'Joe Doe'}) # => {:name=>"Joe Doe"}
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
# => {:name=>"Joe Doe", :credit_card=>"XXXX XXXX XXXX XXXX X", :billing_address=>"Street 42", :phone_number=>"000-000-00-00"}
```

--------------------------------------

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