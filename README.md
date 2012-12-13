
# brew

Brew is an npm module to help you keep source files compiled and available with real-time updates. For examples:

* Keeping a bunch of `less` and `css` files compiled into a single `css` file
* Compiling front-end `coffee` and `js` into a single `js` package.
* Any other kind of compiling you want

What brew does:

* It monitors files and directories you specify
* If any file changes, the brew's version hash changes and recompiles are triggered
* It uses a `compile` function you provide on all matching files
* It joins the compiles using a `join` function you provide

### Example

The following example in coffeescript monitors 2 directories (and all their subdirs) full of `.js` files 
and combines them together into a single `.js` file. The ordering of the includes matters, so a certain file is singled out
to be first, even though it's also requested in one of the later directories.

```coffee-script

brew = require('brew').brew

tasty_brew = new brew {
  includes: [
      "./js/bar/1.js"
      "./js/foo/"
      "./js/bar/"
    ]
  excludes: [
    "./js/bar/bad_code.js"
    "./js/foo/bad_dir/"
  ]
  match:      /^.*.coffee$/
  compile:    (path, txt, cb) -> cb null, txt
  join:       (strs, cb)      -> cb null, strs.join "\n"
  onChange:   (vh, txt) -> console.log "the brew has changed; version hash = #{vh}"
  onReady:    (vh, txt) -> console.log "the brew is ready; versions hash = #{vh}"
}
````

Once a brew is ready, you can access its compiled text and version numbers at any time:

```coffee-script
vh  = tasty_brew.getVersionHash()
txt = tasty_brew.getCompiledText() 
````

If you provide the optional `onChange` function, as shown above, you can be notified whenever the version
hash changes of all your files, and what the new compiled and joined text is.


my todo
====
* TODO: make iced-coffee-script a dev req, and explain it
* TODO: pipeline first pass building!
* TODO: all kinds of error handling/checking:
	- file gets added to a monitored dir
	- file gets deleted
	- file gets moved
	- permission denied
* TODO: special case handling
	- 2 different files with same names in different mon'd dirs
	- entire dir deleted
