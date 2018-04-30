# Prettier Ruby Plugin

<p align="center">
    :construction: Work in Progress! :construction:
</p>

## WORK IN PROGRESS

Please note that this plugin is under active development, and might not be ready to run on production code yet.

## Contributing

If you're interested in contributing to the development of Prettier for Ruby, you can follow the [CONTRIBUTING guide from Prettier](https://github.com/prettier/prettier/blob/master/CONTRIBUTING.md), as it all applies to this repository too.

To test it out on a Ruby file:

* Clone this repository.
* Run `yarn`.
* Create a file called `test.rb`.
* Run `yarn prettier test.rb` to check the output.
  <!--

## Install

````bash
yarn add --dev --exact prettier @prettier/plugin-ruby
``` -->

## Configure

.prettierrc:

```json
{
  "plugins": ["@prettier/plugin-ruby"]
}
````

## Use

```bash
prettier --write "**/*.rb"
```
