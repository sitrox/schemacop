# Schemacop schema V3

## Nodes

### String (`string`, `hsh`)

The string type is used for strings of text and must be a ruby `String` object
or a subclass.

#### Options

* `min_length` 
  Defines the minimum required string length
* `max_length` 
  Defines the maximum required string length
* `pattern` 
  Defines a (ruby) regex pattern the value will be matched against. Must be a
  string and should generally start with `^` and end with `$` so as to evaluate
  the entire string. It should not be enclosed in `/` characters.
* `format_options`

### Hash (`hash`, `hsh`)

