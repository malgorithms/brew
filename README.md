# BREW

Brew is a NodeJS class that keeps source files compiled and bundled, available in memory. For examples:

* Keeping a bunch of `style`, `less`, and/or `css` files compiled into a single chunk of css.
* Compiling front-end `coffee` and `js` into a single `js` package.
* Compiling templates from `toffee`, `eco`, or whatever into js
* Heck, any other kind of compiling you want

What brew does:

* It monitors files and directories you specify, asynchronously
* If any file changes or disappears, or if a new one is introduced, the brew's version hash changes and a compile is triggered
* It uses an async `compile` function you provide on all matching files, which can do whatever you want
* It joins the compiles using an async `join` function you provide
* It can optionally compress results, with an async `compress` function you provide.

Basically: it decouples all this annoying file monitoring from your important compile, join, and compress steps.

### Installation

```
npm install -g brew
```

### Example

The following example in coffeescript just monitors 2 directories (and all their subdirs) full of `.js` files 
and combines them together into a single `.js` file. The ordering of the includes matters, and in this example a certain file is singled out
to be first, even though it's also requested in one of the later directories.

```coffee-script

brew = require('brew').brew

my_tasty_brew = new brew {
  includes: [
      "./js/bar/1.js"
      "./js/foo/"
      "./js/bar/"
    ]
  excludes: [
    "./js/bar/bad_code.js"
    "./js/foo/bad_dir/"
  ]
  match:      /^.*\.js$/ # don't compile anything unless it ends in .js 
  compile:    (path, txt, cb)              -> cb null, txt                            # the trivial compile
  join:       (strs, cb)                   -> cb null, (strs.join "\n")               # the trivial join
  compress:   (str,  cb)                   -> cb null, str.replace /[ \n\t\r]+/g, ' ' # strip extra whitespace
  onChange:   (vhash, txt, compressed_txt) -> console.log "the brew has changed; version hash = #{vhash}"
  onReady:    (vhash, txt, compressed_txt) -> console.log "the brew is ready;    version hash = #{vhash}"
}
````

Once a brew is ready (you've gotten an onReady call), you can access its compiled text and version numbers at any time:

```coffee-script
vh   = my_tasty_brew.getVersionHash()
txt  = my_tasty_brew.getCompiledText() 
ctxt = my_tasty_brew.getCompressedText() 
````

### The parameters, explained

* `includes`: this should be an array containing directories and/or files. Order matters. If a file qualifies twice, its priority will be determined by its first mention or ancestor directory mention.
* `exclude`:  (optional) files and directories to ignore.
* `match`:    (optional) a file will only be compiled/included if its name matches this regexp.
* `compile`:  (optional) your compile function is called on every matching file. You should call back with `err, txt`; the default compile function leaves text unmolested.
* `join`:     (optional) your join function gets an array of all the compiled texts and is responsible for turning them into one new text. Note that you may wish to do final compilation here, too. For example, with a `less` compilation, you might prefer to do nothing in `compile` but just join them all together and compile the results here.
* `compress`: (optional) your compress function takes the final joined string, and calls back with a new string, compressed. If you provide a compress function, this allows you to call getCompressedText()
* `onReady`:  brew calls this once it has made its first pass and compiled & joined everything
* `onChange`: (optional) this function is called if a version hash changes
* `logger`:   (optional) if you provide a logger function, brew will pass all kinds of verbose lines of text to it. Your logger function shuould take one parameter, a string.


### What is the "version_hash" exactly?

It's just an 8 character hex string, representing the results of all your files compiled and joined together. If you change a file, this
hash will change. You can use it for cache-busting, versioning, whatever.

### Any tips/suggestions?

Yes!

* In your compile function, depending on the output, consider auto-inserting a comment with the name of the source file.
* In your join function, consider performing a minimization in production but not in dev.
* In your onChange function, consider writing the result to the file system!
* Try using brew directly in your web process and use its `getCompiledText()` results to reply to users' requests for JS/CSS/whatever, cutting the filesystem out.

## Contributing/making changes

* You'll need iced-coffee-script: `npm install -g iced-coffee-script`
* You'll need coffee-script: `npm install -g coffee-script`
* Compile by running `cake build`
* Do not edit `.js` files directly, as they're generated by cake.


### My TODO

* pipeline building
