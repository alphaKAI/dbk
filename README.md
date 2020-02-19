# DBK
Directory Bookmark Tool

## Requirements

- DUB(1.19.0) - Package Manager and Build Tool for D lang
- DMD(2.090.1) - The D Compiler

## Installation

At first, please clone and build it: `git clone https://github.com/alphaKAI/dbk ; cd dbk; dub build`  

Append these configurations into your `.zshrc` or `.bashrc`  

```sh
DBK_IMPL_PATH=/path/to/generated/dbk/binary
alias dbk="source /path/to/directory/of/dbk/dbk_wrap"
```

More useful:
`alias dbkcd='cd $(echo $(dbk peco|peco) | ruby -e "puts STDIN.gets.chomp.split(\" - \")[1]")'`

## LICENSE
DBK is released under the MIT License.  
Please see `LICENSE` for details.  
Copyright © 2020, Akihiro Shoji  
