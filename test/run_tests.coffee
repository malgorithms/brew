{brew} = require '../src/brew'
fs     = require 'fs'

NUMBERS     = 20
USE_LOGGER  = false # set to true to watch what brew is doing

# -----------------------------------------------------------------------------

assertCompressedText = (test_name, b, target, max_wait, cb) ->
  t = Date.now()
  while (b.getCompressedText() isnt target) and (Date.now() - t < max_wait)
    await setTimeout defer(), 10
  ct = b.getCompressedText()
  if ct isnt target
    console.log "#{test_name} failed; target = #{target}; actual = #{ct}"
    console.log b._fs_watchers
    console.log "Try setting USE_LOGGER=true to see what brew is doing."
    process.exit 1
  else
    console.log "#{test_name} passed after #{Date.now() - t}ms"
  cb()

# -----------------------------------------------------------------------------

nPath = (num) -> 
  if num % 2
    "#{__dirname}/cases/math/odds/#{num}.txt"
  else
    "#{__dirname}/cases/math/evens/#{num}.txt"

# -----------------------------------------------------------------------------

fullDeletionTest = (b, cb) ->
  console.log "STARTING DELETION TEST\n\n"
  for i in [0...NUMBERS]
    await fs.exists nPath(i), defer exists
    if exists
      await fs.unlink nPath(i), defer err
      if err? then console.log err

  await assertCompressedText "full deletion test", b, 0, 1000, defer()
  cb()

# -----------------------------------------------------------------------------

fullInsertionTest = (b, cb) ->
  console.log "STARTING INSERTION TEST\n\n"
  for i in [0...NUMBERS]
    await fs.writeFile nPath(i), i, defer err

  target = (NUMBERS) * (NUMBERS - 1) / 2

  await assertCompressedText "full insertion test", b, target, 1000, defer()
  cb()

# -----------------------------------------------------------------------------

myCompress = (str, cb) ->
  ###
  adds up all the numbers in a comma-separated string
  ###
  nums = str.split ","
  sum  = 0
  if str.length then sum += parseInt n for n in nums
  cb null, sum

# -----------------------------------------------------------------------------

await b = new brew {
  includes: ["./cases/math/"]
  excludes: []
  match:      /^.*.txt$/
  join:       (strs, cb)      -> cb null, strs.join ","
  logger:     (line)          -> if USE_LOGGER then console.log "brew speaks: #{line}"
  compress:   (str, cb)       -> myCompress str, cb
  onReady:                       defer vh, txt, ctxt
  onChange: (vh, txt, ctxt)   -> console.log "change: [#{vh}] #{txt} -> #{ctxt}"
}

await fullDeletionTest  b, defer()
await fullInsertionTest b, defer()
await fullDeletionTest  b, defer()

console.log "SUCCESS"
process.exit 0

# 
# for i in [0...10]
#   await fs.writeFile nPath(i), i, defer err
# await setTimeout defer(), 2000
# console.log b2.getCompiledText()
