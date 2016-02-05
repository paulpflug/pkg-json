# pkg-json

a simple cli to alter a package.json (or any other json file)

## Install

```sh
npm install pkg-json

```

## Usage - cli

```
Usage: pkg-json [options] <value>

  Options:

    -h, --help       output usage information
    -V, --version    output the version number
    -f, --force      allows to overwrite a obj or array by string
    --stdout         will write to stdout instead changing the file
    --stdin          will read from stdin instead of a file
    -b, --bare       toString instead of "JSON.stringify", only works with stdout
    -i, --in <file>  json file
    set <path>       sets a path to value
    get <path>       gets a path
    remove <path>    same as -f set <path> null
    push <path>      pushes value to array
    splice <path>    splices value from array, also takes an index
```

## Example

```sh
pkg-json set version 1.0.0
pkg-json set dependencies.pkg-json 0.0.1
pkg-json get version
pkg-json push keywords "awesome"
pkg-json remove keywords "awesome"
```

## Usage - node
```coffee
pkgJson = require "pkg-json"
```
pkgJson will be Function taking a single 'options' object

| Parameter | Type    | Usage                                   |
| --------: | ------- | :--------------------------------------|
| type      | string  |  set, get, push or splice  |
| path      | string  |  path in data |
| set      | string | value will be `path` and `type` will be `"set"` |
| get      | string | value will be `path` and `type` will be `"get"` |
| push      | string | value will be `path` and `type` will be `"push"` |
| splice      | string | value will be `path` and `type` will be `"splice"` |
| value      | * | used for `"set"`, `"push"`and `"splice"` |
| bare      | boolean | if set will return object instead of jsonified string |
| return      | boolean | if set will return the result instead to write file |
| in      | filepath | json file which will be used instead of package.json |

## Example

```coffee
pkgJson = require "pkg-json"

pkgJson set:"version", value: "1.0.0"
version = pkgJson get: "version" # "1.0.0"

# to get the changed json add a return:true (nothing will be written)
result = pkgJson set: "dependencies.pkg-json", value: "0.0.1", return: true

# to get the changed data (no json format) add a bare: true
result = pkgJson set: "dependencies.pkg-json", value: "0.0.1", return: true, bare: true

pkgJson push: "keywords", value: "awesome"
pkgJson splice: "keywords", value: "awesome"
```

## Release History

 - *v0.0.1*: First release

## License
Copyright (c) 2015 Paul Pflugradt
Licensed under the MIT license.
