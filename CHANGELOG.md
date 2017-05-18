# Change log

<!--
## master (unreleased)

### New features

### Bug fixes

### Changes
-->

## master (unreleased)

### Bug fixes

* Remove '/root' from the paths in the error messages

### Changes

* Add tests for the Collector paths to ensure correct behavior.
* Add symbol Type to the short forms test

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
