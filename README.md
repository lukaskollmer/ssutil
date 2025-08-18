<!-- 
This source file is part of the ssutil open-source project

SPDX-FileCopyrightText: 2025 Lukas Kollmer

SPDX-License-Identifier: MIT
-->

# ssutil

place iOS simulator screenshots in device bezels


## Installing

```bash
brew install lukaskollmer/formulae/ssutil
```

## Usage

> [!IMPORTANT]  
> `ssutil` isn't (yet) able to download the bezel templates from Apple on its own.
> Before you first use `ssutil`, you'll need to [download the bezel files from Apple][apple-bezels],
> and place them in a folder somewhere in your file system.
> You can then use the `--bezels` option to tell `ssutil` where the bezel templates are.

```
USAGE: ssutil --bezels <bezels> [--color <color>] [--in-place] [--output <output>] [<files> ...]

ARGUMENTS:
  <files>                 input files

OPTIONS:
  --bezels <bezels>       bezel templates downloaded from apple
  --color <color>         device color
  --in-place              override input files in-place
  --output <output>       output directory
  -h, --help              Show help information.
```


[apple-bezels]: https://developer.apple.com/design/resources/#product-bezels
