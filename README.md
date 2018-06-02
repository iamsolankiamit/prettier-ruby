# Prettier Ruby Plugin

<p align="center">
    :construction: Work in Progress! :construction:
</p>

## WORK IN PROGRESS

Please note that this plugin is under active development, and might not be ready to run on production code yet.

## Contributing

If you're interested in contributing to the development of Prettier for Ruby:

* Clone this repository
* Run `yarn` to install dependencies
* Ensure all tests run with `yarn run test`

You will find it useful to read the [CONTRIBUTING guide from Prettier](https://github.com/prettier/prettier/blob/master/CONTRIBUTING.md),
as it all applies to this repository too.

### Development

Prettier-Ruby makes use of Ruby's official lexer and parser, [Ripper](https://docs.ruby-lang.org/en/2.5.0/Ripper.html).
You can see the output of Ripper's tokens, sexpressions, the intermediate representation that prettier-ruby uses,
as well as the final prettier-ruby result by appending `DEBUG=true` when running tests:

```bash
DEBUG=true yarn run test --watch
```

You can run the Ruby AST Exporter directly with a given string too:

```
$ ruby vendor/ruby/astexport.rb "puts 'hello world'"
```

To run an individual test folder:

```bash
DBEUG=true yarn run test tests/defs --watch
```

## Usage

Until this package is officially released to npm you must clone it yourself, and run it directly:

* Clone this repository
* Run `yarn` to install dependencies
* Run `yarn prettier test.rb` to check the output of a single file
* Run on multiple files with `yarn prettier your_folder/**/*.rb`
* Save the result with `yarn prettier your_folder/**/*.rb --write`
