[![Ruby](https://github.com/sitrox/schemacop/actions/workflows/ruby.yml/badge.svg?branch=master)](https://github.com/sitrox/schemacop/actions/workflows/ruby.yml)
[![Gem Version](https://badge.fury.io/rb/schemacop.svg)](https://badge.fury.io/rb/schemacop)

# Schemacop

Schemacop validates ruby structures consisting of nested hashes and arrays
against schema definitions described by a simple DSL. It is also able to
generate [JSON Schema](https://json-schema.org) compliant JSON output, i.e. for
use in conjunction with [OpenAPI](https://swagger.io/specification/).

## Compatibility

Schemacop is tested with the following ruby versions:

* 2.6.2
* 2.7.1
* 3.0.1
* 3.1.0

Other ruby versions might work but are not covered by our automated tests.

## Basic example

```ruby
schema = Schemacop::Schema3.new :hash do
  scm :group do
    str! :name
  end
  str! :name
  int? :age, minimum: 21
  ary! :groups do
    list :reference, path: :group
  end
end

schema.validate!(
  name: 'John Doe',
  age: 42,
  groups: [
    { name: 'Group 1' },
    { name: 'Group 2' }
  ]
)
```

## Installation

To install the **Schemacop** gem:

```sh
$ gem install schemacop
```

To install it using `bundler` (recommended for any application), add it to your
`Gemfile`:

```ruby
gem 'schemacop', '>= 3.0.0'
```

## Schema specification

The actual schema definition depends on the schema version you're using.
Schemacop 3 supports version 3 and also the legacy version 2 for backwards
compatibility. For version 1, you need to use the `1.x` versions of schemacop.

* [Schema version 3](README_V3.md)
* [Schema version 2](README_V2.md) (legacy)

## JSON generation

Using the method `as_json` on any V3 schema will produce a JSON schema compliant
to the JSON Schema standard.

```ruby
Schemacop::Schema3.new :hash do
  str! :name
end.as_json

# Will result in
{
  type: :object,
  properties: {
    name: { type: :string }
  },
  additionalProperties: false,
  required: [:name]
}
```

On the resulting data structure, you can use `to_json` to convert it into an
actual JSON string.

## Exceptions

Schemacop will throw one of the following checked exceptions:

* `Schemacop::Exceptions::InvalidSchemaError`

  This exception is thrown when the given schema definition format is invalid.

* `Schemacop::Exceptions::ValidationError`

  This exception is thrown when the given data does not comply with the given
  schema definition.

## Development

To run tests:

* Check out the source

* Run `bundle install`

* Run `bundle exec rake test` to run all tests

* Run `bundle exec rake test TEST=test/unit/some/file.rb` to run a single test
  file

## Copyright

Copyright © 2016 - 2023 Sitrox. See `LICENSE` for further details.
