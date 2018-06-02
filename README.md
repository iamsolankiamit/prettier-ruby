# Prettier Ruby Plugin
[![All Contributors](https://img.shields.io/badge/all_contributors-2-orange.svg?style=flat-square)](#contributors)

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
DEBUG=true yarn run test tests/defs --watch
```

## Usage

Until this package is officially released to npm you must clone it yourself, and run it directly:

* Clone this repository
* Run `yarn` to install dependencies
* Run `yarn prettier test.rb` to check the output of a single file
* Run on multiple files with `yarn prettier your_folder/**/*.rb`
* Save the result with `yarn prettier your_folder/**/*.rb --write`

## Contributors

Thanks goes to these wonderful people ([emoji key](https://github.com/kentcdodds/all-contributors#emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore -->
| [<img src="https://avatars2.githubusercontent.com/u/1271782?v=4" width="100px;"/><br /><sub><b>Alan Foster</b></sub>](http://www.alanfoster.me/)<br />[📖](https://github.com/iamsolankiamit/prettier-ruby/commits?author=AlanFoster "Documentation") [🐛](https://github.com/iamsolankiamit/prettier-ruby/issues?q=author%3AAlanFoster "Bug reports") [💻](https://github.com/iamsolankiamit/prettier-ruby/commits?author=AlanFoster "Code") [🤔](#ideas-AlanFoster "Ideas, Planning, & Feedback") | [<img src="https://avatars3.githubusercontent.com/u/3483526?v=4" width="100px;"/><br /><sub><b>Amit Solanki</b></sub>](http://solankiamit.com)<br />[📖](https://github.com/iamsolankiamit/prettier-ruby/commits?author=iamsolankiamit "Documentation") [🐛](https://github.com/iamsolankiamit/prettier-ruby/issues?q=author%3Aiamsolankiamit "Bug reports") [💻](https://github.com/iamsolankiamit/prettier-ruby/commits?author=iamsolankiamit "Code") [🤔](#ideas-iamsolankiamit "Ideas, Planning, & Feedback") [💡](#example-iamsolankiamit "Examples") [👀](#review-iamsolankiamit "Reviewed Pull Requests") [⚠️](https://github.com/iamsolankiamit/prettier-ruby/commits?author=iamsolankiamit "Tests") |
| :---: | :---: |
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/kentcdodds/all-contributors) specification. Contributions of any kind welcome!
