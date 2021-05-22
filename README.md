# menro

![GitHub](https://img.shields.io/github/license/pocka/menro)
[![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg?style=flat-square)](https://github.com/prettier/prettier)

Toy project. Do not expect anything else.

## Guides

### Development

You need at least:

- Node.js (Active LTS or Current is recommended)
- Yarn

This project uses Yarn 2's Zero-Installs feature.
You don't need to `yarn install` after cloning the repository or switching branches.

To run development server:

```sh
$ yarn dev

# Add --help for refering options
```

To build app:

```sh
$ yarn build
```

`elm` (npm package) does not compatible with Yarn v2.
In order to invoke Elm locally, use `yarn bin elm` to get the path then execute the binary.

```sh
# e.g. Install elm/json package
$ $(yarn bin elm) install elm/json
```

### Host your own

The source code uses [`homepage` key in`package.json`](./package.json) for things requiring URLs.
You need to change a value of the `homepage` key to where you host the app.

Also, I recommend you to replace the value of `repository.url` key and `name` key too.

Then build the app by running `yarn build` and every references will be updated.
