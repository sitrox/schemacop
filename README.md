[![Build Status](https://travis-ci.org/sitrox/schemacop.svg?branch=master)](https://travis-ci.org/sitrox/schemacop)
[![Gem Version](https://badge.fury.io/rb/schemacop.svg)](https://badge.fury.io/rb/schemacop)

# Schemacop

This is the README for Schemacop version 2, which **breaks backwards
compatibility** with version 1.

Schemacop validates ruby structures consisting of nested hashes and arrays
against schema definitions described by a simple DSL.

Examples:

```ruby
schema = Schema.new do
  req :naming, :hash do
    opt :first_name, :string
    req :last_name, :string
  end
  opt! :age, :integer, min: 18
  req? :password do
    type :string, check: proc { |pw| pw.include?('*') }
    type :integer
  end
end

schema.validate!(
  naming: { first_name: 'John',
            last_name: 'Doe' },
  age: 34,
  password: 'my*pass'
)
```

```ruby
schema2 = Schema.new do
  req :description,
      :string,
      if: proc { |str| str.start_with?('Abstract: ') },
      max: 35,
      check: proc { |str| !str.end_with?('.') }
  req :description, :string, min: 35
end

schema2.validate!(description: 'Abstract: a short description')
schema2.validate!(description: 'Since this is no abstract, we expect it to be longer.')
```

## Installation

To install the **Schemacop** gem:

```sh
$ gem install schemacop
```

To install it using `bundler` (recommended for any application), add it to your
`Gemfile`:

```ruby
gem 'schemacop'
```

## Basics

Since there is no explicit typing in Ruby, it can be hard to make sure that a
method is recieving exactly the right kind of data it needs. The idea of this
gem is to define a schema at boot time that will validate the data being passed
around at runtime. Those two steps look as follows:

At boot time:

```ruby
my_schema = Schema.new do
  # Your specification goes here
end
```

At runtime:

```ruby
my_schema.validate!(
  # Your data goes here
)
```

`validate!` will fail if the data given to it does not match what was specified
in the schema.

### Type lines vs. Field lines

Schemacop uses a DSL (domain-specific language) to let you describe your
schemas. We distinguish between two kinds of identifiers:

- Field Lines: We call a key-value pair (like the contents of a hash) a *field*.
  A field line typically starts with the keyword `req` (for a required field) or
  `opt` (for an optional field).

- Type Lines: Those start with the keyword `type` and specify the data type to
  be accepted with a corresponding symbol (e.g. `:integer` or `:boolean`). You
  can have multiple Type Lines for a Field Line in order to indicate that the
  field's value can be of one of the specified types.

If you don't use any short forms, a schema definition would be something like
this:

```ruby
s = Schema.new do
  type :integer
  type :hash do
    req 'present' do
      type :boolean
    end
  end
end
```

The above schema would accept either an integer or a hash with exactly one field
with key 'present' of type String and value of type Boolean (either TrueClass or
FalseClass).

We will see Type and Field lines in more detail below.

### `validate` vs `validate!` vs `valid?`

The method `validate` will return a `Collector` object that contains all
validation errors (if any) as well as a deep copy of your data with applied
defaults and castings, whereas `validate!` will accumulate all violations
and finally throw an exception describing them or, if the validation was
successful, a deep-copy of your supplied data with defaults and castings
applied.

For simply querying the validity of some data, use the methods `valid?` or
`invalid?`.

Examples:

```ruby
# validate! returns your modified data or throws a validation error
s = Schema.new do
  req :foo, default: 42
end
s.validate!({}) # => { foo: 42 }

# validate returns a collector
s = Schema.new do
  req :foo, default: 42
end

collector = s.validate({}) 
collector.valid? # true
collector.data   # => { foo: 42 }

collector = s.validate({ foo: 'invalid' }) 
collector.valid?     # false
collector.data       # => nil
collector.exceptions # => Validation error
```


## Schemacop's DSL

In this section, we will ignore [short forms](#short-forms) and explicitly
write out everything.

Inside the block given at the schema instantiation (`Schema.new do ... end`),
the following kinds of method calls are allowed (where the outermost must be a
Type Line):

### Type Line

A Type Line always starts with the identifier `type` and specifies a possible
data type for a given field (if inside a Field Line) or the given data structure
(if directly below the schema instantiation).

Type Lines are generally of the form

```ruby
type :my_type, option_1: value_1, ..., option_n: value_n
```

where `:my_type` is a supported symbol (see section [Types](#types) below for
supported types).

#### General options

Some types support specific options that allow additional checks on the nature
of the data (such as the `min` option for type `:number`). The following options
are supported by all types:

##### Option `if`

This option takes a proc (or a lambda) as value. The proc will be called when
checking whether or not the data being analyzed fits a certain type. The data is
given to the proc, which has to return either true or false. If it returns true,
the type of the given data is considered correct and the data will be validated
if further options are given.

Note that the proc in `if` will only get called if the type (`:my_type` from
above) fits the data already. You can use the option `if` in order to say: "Even
if the data is of type `:my_type`, I consider it having the wrong type if my
proc returns false."

Consider a scenario in which you want to have the following rule set:

- Only integers may be given
- Odd integers must be no larger than 15
- No limitations for even integers

The corresponding schema would look as follows:

```ruby
Schema.new do
  type :integer, if: proc { |data| data.odd? }, max: 15
  type :integer
end
```

Here, the first type line will only accept odd numbers and the option `max: 15`
provided by the `:integer` validator will discard numbers higher than 15.

Since the first line only accepts odd numbers, it doesn't apply for even numbers
(due to the proc given to `if` they are considered to be of the wrong type) and
control falls through to the second type line accepting any integer.

##### Option `check`

This option allows you to perform arbitrary custom checks for a given data type.
Just like `if`, `check` takes a proc or lambda as a value, but it runs *after*
the type checking, meaning that it only gets executed if the data has the right
type and the proc in `if` (if any) has returned true.

The proc passed to the `check` option is given the data being analyzed. It is to
return true if the data passes the custom check. If it returns false or an error
message as a string, Schemacop considers the data to be invalid.

The following example illustrates the use of the option `check`: Consider a
scenario in which you want the following rule set:

- Data must be of type String
- The string must be longer than 5 characters
- The second character must be an 'r'

The corresponding schema would look as follows:

```ruby
Schema.new do
  type :string, min: 5, check: proc { |data| data[1] == 'r'}
end
```

The above Type Line has type `:string` and two options (`min` and `check`). The
option `min` is supported by the `:string` validator (covered later).

You can also specify a custom error message by returning a string:


```ruby
Schema.new do
  type :integer, check: proc { |i| i.even? ? true : 'Custom error' }
end
```

This will include `Custom error` in the validation error message.

### Field Line

Inside a Type Line of type `:hash`, you may specify an arbitrary number of field
lines (one for each key-value pair you want to be in the hash).

Field Lines start with one of the following six identifiers: `req`, `req?`,
`req!`, `opt`, `opt?` or `opt!`:

- The suffix `-!` means that the field must not be nil.

- The suffix `-?` means that the field may be nil.

- The prefix `req-` denotes a required field (validation fails if the given data
  hash doesn't define it). `req` is a shorthand notation for `req!` (meaning
  that by default, a required field cannot be nil).

- The prefix `opt-` denotes an optional field. `opt` is a shorthand notation for
  `opt?` (meaning that by default, an optional field may be nil).

To summarize:

- `req` or `req!`: required and non-nil
- `req?`: required but may be nil
- `opt` or `opt?`: optional and may be nil
- `opt!`: optional but non-nil

You then pass a block with a single or multiple Type Lines to the field.

Example: The following schema defines a hash that has a required non-nil field
of type String under the key `:name` (of type Symbol) and an optional but
non-nil field of type Integer or Date under the key `:age`.

```ruby
Schema.new do
  type :hash do
    req :name do
      type :string
    end
    opt! :age do
      type :integer
      type :object, classes: Date
    end
  end
end
```

You might find the notation cumbersome, and you'd be right to say so. Luckily
there are plenty of short forms available which we will see below.

#### Handling hashes with indifferent access

Schemacop has special handling for objects of the class
`ActiveSupport::HashWithIndifferentAccess`: You may specify the keys as symbols
or strings, and Schemacop will handle the conversion necessary for proper
validation internally. Note that if you define the same key as string and
symbol, it will throw a `ValidationError` [exception](#exceptions) when asked to
validate a hash with indifferent access.

Thus, the following two schema definitions are equivalent when validating a hash
with indifferent access:

```ruby
Schema.new do
  type :hash do
    req :name do
      type :string
    end
  end
end

Schema.new do
  type :hash do
    req 'name' do
      type :string
    end
  end
end
```

## Types

Types are defined via their validators, which is a class under `validator/`.
Each validator is sourced by `schemacop.rb`.

The following types are supported by Schemacop by default:

* `:boolean` accepts a Ruby TrueClass or FalseClass instance.

* `:integer` accepts a Ruby Integer.

  - supported options: `min`, `max` (lower / upper bound)

* `:float` accepts a Ruby Float.

  - supported options: `min`, `max` (lower / upper bound)

* `:number` accepts a Ruby Integer or Float.

  - supported options: `min`, `max` (lower / upper bound)

* `:string` accepts a Ruby String.

  - supported options: `min`, `max` (bounds for string length)

* `:symbol` accepts a Ruby Symbol.

* `:object` accepts an arbitrary Ruby object (any object if no option is given).

  Supported options:

  - `classes`: Ruby class (or an array of them) that will be the only recognized
    filters. Unlike other options, this one affects not the validation but the
    type recognition, meaning that you can have multiple Type Lines with
    different `classes` option for the same field, each having its own
    validation (e.g. through the option `check`).

  - `strict`: Boolean option, defaults to true. If set to false, the validator
    also allows derived classes of those specified with `classes`.

* `:array` accepts a Ruby Array.

  - supported options: `min`, `max` (bounds for array size) and `nil`: TODO

  - accepts a block with an arbitrary number of Type Lines.

  - TODO no lookahead for different arrays, see
    validator_array_test#test_multiple_arrays

* `:hash` accepts a Ruby Hash or an `ActiveSupport::HashWithIndifferentAccess`.

  - accepts a block with an arbitrary number of Field Lines.

  - `allow_obsolete_keys`: If enabled (default `false`), this allows arbitrary
    keys within your hash. Keys not specified in your schema will not be
    validated further, but keys specified explicitly are still validated.

* `:nil`: accepts a Ruby NilClass instance. If you want to allow `nil` as a
  value in a field, see above for the usage of the suffixes `-!` and `-?` for
  Field Lines.

All types support the options `if` and `check` (see the section about Type Lines
above).

## Short forms

For convenience, the following short forms may be used (and combined if
possible).

### Passing a type to a Field Line or schema

Instead of adding a Type Line in the block of a Field Line, you can omit `do
type ... end` and directly write the type after the key of the field.

Note that when using this short form, you may not give a block to the Field
Line.

```ruby
# Long form
req :name do
  type :string, min: 2, max: 5
end

# Short form
req :name, :string, min: 2, max: 5
```

This means that the value under the key `:name` of type Symbol must be a String
containing 2 to 5 characters.

The short form also works in the schema instantiation:

```ruby
# Long form
Schema.new do
  type :string, min: 2, max: 5
end

# Short form
Schema.new(:string, min: 2, max: 5)
```

This means that the data given to the schema must be a String that is between 2
and 5 characters long.

### Passing multiple types at once

You can specify several types at once by putting them in an array.

Note that when using this short form, you may not give any options.

```ruby
# Long form
opt! :age do
  type :string
  type :integer
  type :boolean
end

# Short form
opt! :age do
  type [:string, :integer, :boolean]
end
```

Combined with previous short form:

```ruby
opt! :age, [:string, :integer, :boolean]
```

This also works in the schema instantiation:

```ruby
Schema.new([:string, :integer, :boolean])
```

This means that the schema will validate any data of type String, Integer,
TrueClass or FalseClass.

### Omitting the Type Line in a Field Line

If you don't specify the type of a field, it will default to `:object` with no
options, meaning that the field will accept any kind of data:

```ruby
# Long form
req? :child do
  type :object
end

# Short form
req? :child
```

### Omitting the Type Line in schema instantiation

If you don't give a Type Line to a schema, it will accept data of type Hash.
Therefore, if you validate Hashes only, you can omit the Type Line and directly
write Field Lines in the schema instantiation:

```ruby
# Long form
Schema.new do
  type :hash do
    req :name do
      # ...
    end
  end
end

# Short form
Schema.new do
  req :name do
    # ...
  end
end
```

Note that this does not allow you to specify any options for the hash itself.
You still need to specify `:hash` as a type if you want to pass any options to
the hash (i.e. a `default`).

### Shortform for subtypes

In case of nested arrays, you can group all Type Lines to a single one.

Note that any options or block passed to the grouped Type Line will be given to
the innermost (last) type.

```ruby
# Long form
type :array do
  type :integer, min: 3
end

# Short form
type :array, :integer, min: 3
```

A more complex example:

Long form:

```ruby
Schema.new do
  type :hash do
    req 'nutrition' do
      type :array do
        type :array do
          type :hash, check: proc { |h| h.member?(:food) || h.member?(:drink) } do
            opt! :food do
              type :object
            end
            opt! :drink do
              type :object
            end
          end
        end
      end
    end
  end
end
```

Short form (with this short form others from above):

```ruby
Schema.new do
  req 'nutrition', :array, :array, :hash, check: proc { |h| h.member?(:food) || h.member?(:drink) } do
    opt! :food
    opt! :drink
  end
end
```

This example accepts a hash with exactly one String key 'nutrition' with value
of type Array with children of type Array with children of type Hash in which at
least one of the Symbol keys `:food` and `:drink` (with any non-nil value type)
is present.

## Defaults

Starting from version 2.4.0, Schemacop allows you to define default values at
any point in your schema. If the validated data contains a nil value, it will be
substituted by the given default value.

Note that Schemacop never modifies the data you pass to it. If you want to
benefit from Schemacop-applied defaults, you need to access the cloned, modified
data returned by `validate` or `validate!`.

Applying defaults is done before validating the substructure and before any type
casting. The provided default will be validated same as user-supplied data, so
if your given default does not validate properly, a validation error is thrown.
Make sure your default values always match the underlying schema.

Defaults can be specified at any point:


```ruby
# Basic usage
Schema.new do
  type :string, default: 'Hello World'
end

# The default given for the first type will match
Schema.new do
  type :string, default: 'Hello World' # This will always be applied of no value is supplied
  type :integer, default: 42
end

# You can also pass entire hashes or arrays to your defaults
Schema.new do
  req :foo, :hash, default: { foo: :bar } do
    req :foo, :symbol
  end
  req :bar, :array, :integer, default: [1, 2, 3]
end

# Defaults must match the given schema. The following will fail.
Schema.new do
  req :foo, default: { bar: :baz } do
    req :foo
  end
end
```

### Required data points

Note that any *required* validation is done before applying the defaults. If you
specify a `req` field, it must always be given, no matter if you have specified
a default or not. Therefore, specifying `req` fields do not make sense in
conjunction with defaults, as the default is always ignored.

## Type casting

Starting from version 2.4.0, Schemacop allows you to specify type castings that
can alter the validated data. Consider the following:

```ruby
s = Schema.new do
  req :id, :integer, cast: [String]
end

data = s.validate!(id: '42')
data # => { id: 42 }
```

Note that Schemacop never modifies the data you pass to it. If you want to
benefit from Schemacop-applied castings, you need to access the cloned, modified
data returned by `validate` or `validate!`.

### Specifying type castings

Type castings can be specified using two forms: Either as a hash or as an array.
While using an array only allows you to specify the supported source types to be
casted, using a hash allows you to specify custom casting logic as blocks.

For hashes, the key must be a class and the value must be either `:default` for
using a built-in caster or a callable object (proc or lambda) that receives the
value and is supposed to cast it. If the value can't be casted, the proc must
fail with an exception. The exception message will then be contained in the
collected validation errors.

Example:

```ruby
Schema.new do
  # Pass array to `cast`. This enables casting from String or Float to Integer
  # using the built-in casters.
  req :id_1, :integer, cast: [String, Float]

  # Pass hash to `cast`. This enables casting from Float to Integer using the
  # built-in caster and from String to Integer using a custom callback.
  req :id_2, :integer, cast: { Float => :default, String => proc { |s| Integer(s) }
end
```

### Built-in casters

Schemacop comes with the following casters:

- `String` to `Integer` and `Float`
- `Float` to `Integer`
- `Integer` to `Float`

Note that all built-in casters are precise, so the string `foo` will fail with
an error if casted to an Integer. When casting float values and strings
containing float values to integers, the decimal places will be discarded
however.

### Execution order

The casting is done *before* the options `if` and `check` are evaluated.
Example:

```ruby
s = Schema.new do
  type :integer, if: proc { |i| i == 42 }    # 1
  type :integer, check: proc { |i| i < 3 }   # 2
  type :string
end

s.validate!('42')  # 1 will match
s.validate!('2')   # 2 will match
s.validate!('234') # 3 will match
s.validate!(5)     # Will fail, as nothing matches
```

### Caveats

Casting only works with type definitions that only include one type. For
instance, the `Numeric` validator includes both `Integer` and `Float`, which
would made it unclear what to cast a string into:

```ruby
# This does not work, as it is unclear whether to cast the String into an
# Integer or a Float.
type :number, cast: [String]
```

The same also applies to booleans, as they compound both `TrueClass` and
`FalseClass`. This may be tackled in future releases.

## Exceptions

Schemacop will throw one of the following checked exceptions:

* {Schemacop::Exceptions::InvalidSchemaError}

  This exception is thrown when the given schema definition format is invalid.

* {Schemacop::Exceptions::ValidationError}

  This exception is thrown when the given data does not comply with the given
  schema definition.

## Known limitations

* Schemacop does not yet allow cyclic structures with infinite depth.

* Schemacop is not made for validating complex causalities (i.e. field `a`
  needs to be given only if field `b` is present).

* Schemacop does not yet support string regex matching.

## Development

To run tests:

* Check out the source

* Run `bundle install`

* Run `bundle exec rake test` to run all tests

* Run `bundle exec rake test TEST=test/unit/some/file.rb` to run a single test
  file

## Copyright

Copyright (c) 2020 Sitrox. See `LICENSE` for further details.
