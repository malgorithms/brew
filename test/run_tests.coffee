{brew} = require '../src/brew'

printIt = (vh, txt, ctxt) ->
  console.log """
---- OUTPUT: ---------
#{txt}
---- COMPRESSED: -----
#{ctxt}
---- VERSION: --------
#{vh}
-----CHECK: ----------
#{vh is b.getVersionHash()} 
#{txt is b.getCompiledText()} 
#{ctxt is b.getCompressedText()}
"""

# -----------------------------------------------------------------------------

await b = new brew {
  includes: [
      "./cases/coffee/bar/1.coffee"
      "./cases/coffee/foo"
      "./cases/coffee/bar"
      "./cases/coffee"
    ]
  excludes: [
    "./cases/coffee/bar/bad_code.coffee"
    "./cases/coffee/bad_dir"
  ]
  match:      /^.*.coffee$/
  compile:    (path, txt, cb) -> cb null, "\n# #{path} compiled with love by brew\n#{txt}"
  join:       (strs, cb)      -> cb null, strs.join "\n# this is a test separator"
  compress:   (str, cb)       -> cb null, str.replace /\n[ ]*\#[^\n]*/g, ''
  logger:     (line)          -> console.log "brew speaks: #{line}"
  onReady:    defer version_hash, txt, ctxt
  onChange:   (version_hash, txt, ctxt) -> printIt version_hash, txt, ctxt
}

# -----------------------------------------------------------------------------

printIt version_hash, txt, ctxt