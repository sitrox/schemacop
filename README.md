[![Build Status](https://travis-ci.org/sitrox/schemacop.svg?branch=master)](https://travis-ci.org/sitrox/schemacop)
[![Gem Version](https://badge.fury.io/rb/schemacop.svg)](https://badge.fury.io/rb/schemacop)


# Schemacop

Schemacop validates ruby structures consisting of nested hashes and arrays
against simple schema definitions.

Example:

```ruby
schema = {
  type: :hash,
  hash: {
    first_name: :string,
    last_name: :string
  }
}

data = {
  first_name: 'John',
  last_name: 'Doe'
}

Schemacop.validate!(schema, data)
```

## Installation

To install the **Schemacop** gem:

```sh
$ gem install schemacop
```

To install it using `bundler` (recommended for any application), add it
to your `Gemfile`:

```ruby
gem 'schemacop'
```

## Basic usage

Schemacop's interface is very simple:

```ruby
Schemacop.validate!(schema, data)
```

It will throw an exception if either the schema is wrong or the given data does
not comply with the schema. See section *Exceptions* for more information.

## Defining schemas

Schemacop can validate recursive structures of arrays nested into hashes and
vice-versa. 'Leaf-nodes' can be of any data type, but their internal structure
is not validated.

Schema definitions are always a hash, even if they specify an array. Each level
of a definition hash has to define a type.

You can specify any type, but only the types `:hash` and `:array` allow you to
specify a sub structure.

### Defining hashes

Once a level is defined as a hash (`type: :hash`), you can provide the key
`hash` which in turn specifies the keys contained in that hash:

```ruby
{
  type: :hash,
  hash: {
    first_name: { type: :string },
    last_name: { type: :string }
  }
}
```

If you don't provide the `:hash` key, the hash won't be validated (other than
the verification that it really is a hash):

```ruby
{ type: :hash }
```

Hash definitions can be nested deeply:

```ruby
{
  type: :hash,
  hash: {
    name: {
      type: :hash,
      hash: {
        first_name: { type: :string },
        last_name: { type: :string }
      }
    }
  }
}
```

### Defining arrays

When you define a level as an array (`type: :array`), you can provide further
specification of the array's contents uby supplying the key `:array`:

```ruby
{
  type: :array,
  array: {
    type: :string
  }
}
```

This example would define an array of strings.

Arrays can nest hashes and vice-versa:

```ruby
{
  type: :array,
  array: {
    type: :string
  }
}
```

If you don't provide the `:array` key, the array contents won't be validated:

```ruby
{ type: :array }
```

## Types

For each level in your schema, you can specify the type in one of the following
manors:

- A ruby class:

  ```ruby
  { type: String }
  ```

- A type alias (see {Schemacop::Validator::TYPE_ALIASES} for a full list of
  available type aliasses):

  ```ruby
  { type: :boolean }
  ```

- A list of ruby classes or type aliases:

  ```ruby
  { type: [String, :integer] }
  ```

  When specifying more than one type, it is validated that the given data
  structure matches *one* of the given types.

  If you specify both `:array` and `:hash` in such a type array, you can provide
  a specification for both `array` and `hash` types:

  ```ruby
  {
    type: [:array, :hash],
    array: {
      type: :string
    },
    hash: {
      first_name: :string
    }
  }
  ```

  It will then determine which specification to use based on the actual data.

## Null and required

Using the optional parameters `required` and `null`, you can control whether a
specific substructure must be provided (`required`) and if it can be `nil`
(`null`).

These two parameters can be combined in any way.

### Required validation

When validating with `required = false`, it means that the whole key can be
omitted. As an example:

```ruby
# Successfully validates data hash: {}
{
  type: :hash,
  hash: {
    first_name: { type: :string, required: false }
  }
}
```

### Null validation

When validating with `null = true`, the key must still be present, but it can
also be `nil`.

```ruby
# Successfully validates data hash: { first_name: nil }
{
  type: :hash,
  hash: {
    first_name: { type: :string, null: false }
  }
}
```

## Allowed values

For any level, you can optionally specify an array of values that are allowed.

For example:

```ruby
{
  type: :hash,
  hash: {
    category: { type: :integer, allowed_values: [1, 2, 3] }
  }
}
```

## Shortcuts

### Type shortcut

If you'd just like to define a type for a level but don't need to supply any
additional information, you can just skip passing an extra hash and just pass
the type instead.

For example, the following

```ruby
{
  type: :array,
  array: {
    type: :string
  }
}
```

can also be written as:

```ruby
{
  type: :array,
  array: :string
}
```

### Quick hash and array

When specifying a level as hash or array and you're further specifying the
hashe's fields or the array's content types, you can omit the `type` key.

For example, the following

```ruby
{
  type: :array,
  array: {
    type: :string
  }
}
```

can also be written as:

```ruby
{
  array: :string
}
```

## Example schema

```ruby
{
  hash: {
    id: [Integer, String],
    name: :string,
    meta: {
      hash: {
        groups: { array: :integer },
        birthday: Date,
        comment: {
          type: :string,
          required: false,
          null: true
        },
        ar_object: User
      }
    }
  },
}
```

## Exceptions

Schemacop will throw one of the following checked exceptions:

* {Schemacop::Exceptions::InvalidSchema}

  This exception is thrown when the given schema definition format is invalid.

* {Schemacop::Exceptions::Validation}

  This exception is thrown when the given data does not comply with the given
  schema definition.

## Known limitations

* Schemacop does not yet allow cyclic structures with infinite depth.

* Schemacop aborts when it encounters an error. It is not able to collect a full
  list of multiple errors.

* Schemacop is not made for validating complex causalities (i.e. field `a`
  needs to be given only if field `b` is present).

* Schemacop does not yet support string regex matching.

## Contributors

Thanks to [Rubocop](https://github.com/bbatsov/rubocop) for great inspiration
concerning their name and the structure of their README file.

## Copyright

Copyright (c) 2016 Sitrox. See `LICENSE` for further details.
