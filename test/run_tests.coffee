{brew} = require '../src/brew'

printIt = (vh, txt) ->
  console.log """
---- OUTPUT: -----
#{txt}
------------------
VERSION: #{vh}
------------------
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
  join:       (strs)          -> strs.join "\n# this is a test separator"
  logger:     (line)          -> console.log "brew speaks: #{line}"
  onReady:    defer version_hash, txt
  onChange:   (version_hash, txt) -> printIt version_hash, txt
}

printIt version_hash, txt