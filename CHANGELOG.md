# Change log

## 3.0.19 (2022-09-19)

* Make `cast_str` of `BooleanNode` in  `v3` case-insensitive

## 3.0.18 (2022-07-27)

* Add option `ignore_obsolete_properties` to `HashNode` for Schemacop v3

## 3.0.17 (2022-06-08)

* Add options `filter` and `reject` to array nodes which allow to filter arrays
  before they are validated.

* `#64545`: Fix an issue where `cast_str` in conjunction with `number` notes
  lead to parsing errors when the given number had a leading zero, e.g. parsing
  the string `08` lead to an error, as the number was interpreted as an octal
  string. Numbers are now always being treated as decimal with base 10.

## 3.0.16 (2021-11-23)

* Add setting `Schemacop.v3_default_options` which allows to set default node
  options vor V3 schemas. This is particularly useful for the option `cast_str`
  to allow string casting globally.

## 3.0.15 (2021-10-11)

* Add support for custom string formatters

## 3.0.14 (2021-10-11)

* Add string format `integer_list`

* Improve handling for booleans

## 3.0.13 (2021-10-04)

* When using `boolean` with `cast_str: true`, `"0"` is now casted to `false` and
  `"1"` to `true`. This in addition to already casting `"true", "false"`.

## 3.0.12 (2021-09-14)

* Fix compatibility issue with `ruby <= 2.5`

## 3.0.11 (2021-03-26)

* Treat blank string as nil when using `cast_str` option

## 3.0.10 (2021-03-19)

* If wrong type is given, report class of wrong type in error message

## 3.0.9 (2021-02-26)

* Fix casting of blank strings

* Add `allow_blank` option to `String` nodes

## 3.0.8 (2021-02-23)

* Fix `object` nodes in hashes with no classes

* Document `cast_str` option

## 3.0.7 (2021-02-22)

* Adapt schema definitions handling when using Swagger-standard JSON

## 3.0.6 (2021-02-14)

* Remove option `json_format` from {Schemacop::Schema3.as_json as_json} again.
  If you need to use the swagger format, use
  {Schemacop::V3::Context.with_json_format} instead.

* Rename `Schemacop::V3::Context.spawn_with` to
  {Schemacop::V3::Context.with_json_format} and make keyword argument
  `json_format` a positional argument.

## 3.0.5 (2021-02-14)

* Allow option `pattern` to be a `Regexp` for `string` (`str`) nodes

* Remove `examples_keyword` from context again

* Add option `json_format` to {Schemacop::Schema3.as_json as_json}. This allows
  generating a JSON schema that is [specific to
  swagger](https://swagger.io/docs/specification/data-models/keywords/) by
  passing `:swagger` to it.

## 3.0.4 (2021-02-15)

* Add `examples_keyword` to context which allows to customize the name of the
  `examples` attribute in JSON output

## 3.0.3 (2021-02-15)

* Fix boolean node casting

## 3.0.2 (2021-02-14)

* Fix #15 Code to ignore Zeitwerk fails when Zeitwerk is disabled

## 3.0.1 (2021-02-11)

* Add format `symbol` to strings

## 3.0.0 (2021-02-08)

* Setup Zeitwerk ignores for Rails applications

* Read previous `3.0.0.rcX` entries for all changes included
  in this stable release

## 3.0.0.rc5 (2021-02-05)

* Use `ruby2_keywords` for compatibility with ruby `2.6.2`

## 3.0.0.rc4 (2021-02-02)

* Fix some minor bugs

* Improve documentation

* `used_external_schemas` for the `ReferenceNode` is now applied
  recursively

## 3.0.0.rc3 (2021-01-28)

* Add minor improvements to the documentation

* Internal restructuring, no changes in API

## 3.0.0.rc2 (2021-01-28)

* Represent node names as strings internally

* Update documentation

## 3.0.0.rc1 (2021-01-22)

* Add support for ruby `3.0.0`

* Add `ruby-3.0.0` to travis testing

* Document all `v3` nodes

## 3.0.0.rc0 (2021-01-14)

* Add `Schemacop::Schema3`

* Adapt Readme for Version 2 and 3 of `Schemacop`

* Add `ruby-2.7.1` to travis testing

## 2.4.7 (2020-07-02)

* Return nil when casting an empty string to an Integer or a Float,
  such that these cases can then be handled by the `opt` or `req`.

## 2.4.6 (2020-06-29)

* Use basis 10 (decimal system) when casting a `String` to an `Integer`

## 2.4.5 (2020-05-13)

* Allow procs for `default` that will be evaluated at runtime

## 2.4.4 (2020-03-9)

* Add option `allow_obsolete_keys` to `:hash` validator in order to allow
  validating arbitrary hashes with dynamic keys not specifiable in schema.

## 2.4.3 (2020-03-05)

* Only dup hashes and arrays but not the values when creating the modified
  datastructure that is returned by `validate!`.

## 2.4.2 (2019-11-05)

### Bug fixes

* The object validator, if given no classes, now supports any object of classes
  that derive from `BasicObject`. This allows you to specify types that reside
  out of the ruby standard library, such as `Tempfile`.

## 2.4.1 (2019-10-28)

### Bug fixes

* Re-format code to comply with rubocop. There are no functional implications.

## 2.4.0 (2019-10-28)

### New features

* Add support for default values

* Add support for type casting

### Bug fixes

* Change order of built-in validators so that `Integer` and `String` come
  *before* `Number` which matches both.

### Changes

## 2.3.2 (2019-09-26)

### New features

* Add ability to return custom error messages from `:check` blocks

## 2.3.1 (2019-08-19)

### Changes

* Make compatible with Rails 6

## 2.3.0 (2017-05-18)

### New features

* Option `strict` for the Type `:object`

  This option, which defaults to true, ensures that instance classes are checked
  strictly. If set to false, instances of derived classes are also allowed.

### Bug fixes

* Removed '/root' from the paths in the error messages

### Changes

* Added tests for the Collector paths to ensure correct behavior
* Added symbol Type to the short forms test

## 2.2.0 (2017-05-17)

### Changes

* Handle `ActiveSupport::HashWithIndifferentAccess` objects gracefully when
  performing the validation. This allows the user to specify the schema using
  a mixture of symbols and strings, but during the validation of a
  `HashWithIndifferentAccess` it transparently converts the keys, both in the
  schema and in the hash, to symbols.

  In the event that a key is defined both in the string and symbol version,
  Schemacop expects a Ruby hash and will throw a ValidationError otherwise.

## 2.1.0 (2017-05-16)

### New features

* Validator for type Symbol, accessible with the symbol `:symbol`

## 2.0.0 (2017-05-15)

### Changes

* Completely rewritten the schema specification, breaking backwards
  compatibility with version 1.x
* Added tons of unit tests

## 1.0.1 (2016-06-07)

### Bug fixes

* Fixed bug which didn't allow unspecified hash contents
* Fixed bug which didn't allow mixed array type specifications

## 1.0.0 (2016-06-06)

* Initial stable release
