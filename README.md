Vim-colddeck
-------------

> Vim meets Instacalc meets Hewlett-Packard calculators

Colddeck ("Column dc") is a single-column spreadsheet using `dc` for
computations. You jot down values and formulas, one per line, and the result
is shown on the right.

Extra features:

  - References to other rows (absolute and relative)
  - Ranges
  - Aggregates (sum, min/max, average...)
  - Vim expressions (experimental) 
  - Value references (experimental)

Example
--------

[![asciicast](https://asciinema.org/a/0NgfyWgetZBIoXi6O3ikawkIE.svg)](https://asciinema.org/a/0NgfyWgetZBIoXi6O3ikawkIE)

Syntax in a nutshell
---------------------

- `R3`: reference to row #3
- `R-1`: relative reference to the row above
- `R+2`: relative reference to the second row below
- `R1:R3`: range of rows from #1 to #3 (insert values and number of elements)
- `R1:R3 @sum`: sum of row #1 to #3 (other aggregates: `@min`, `@max`, `@avg`,
  `@prod`)
- `42 # text`: add "text" as a comment, while passing the value '42' to `dc`
- `42 ## Label`: add "Label" as a right-aligned comment and hide the value or
  formula on its left, that is still passed to `dc`
- <code>&#96;log(2)&#96;</code>: vim expression (evaluated before passing the
  line to `dc`)
- `$2`: *result* of the evalutation of row #2 (must have been previously
  computed; evaluated before passing the line to `dc`)

See [the documentation](doc/colddeck.txt) for full manual.

FAQ
----

*What is it?*  
A single-column spreadsheet, in Vim, with postfix operators.
Look ma, no Excel.

*"dc", WTF?*  
Who doesn't love rabid panda notation?

Installation
-------------
Use your favorite method:
*  [Pathogen][1] - git clone https://github.com/fcpg/vim-colddeck ~/.vim/bundle/vim-colddeck
*  [NeoBundle][2] - NeoBundle 'fcpg/vim-colddeck'
*  [Vundle][3] - Plugin 'fcpg/vim-colddeck'
*  [Plug][4] - Plug 'fcpg/vim-colddeck'
*  manual - copy all files into your ~/.vim directory

License
--------
[Attribution-ShareAlike 4.0 Int.](https://creativecommons.org/licenses/by-sa/4.0/)

[1]: https://github.com/tpope/vim-pathogen
[2]: https://github.com/Shougo/neobundle.vim
[3]: https://github.com/gmarik/vundle
[4]: https://github.com/junegunn/vim-plug

