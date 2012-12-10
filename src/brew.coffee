fs      = require 'fs'
path    = require 'path'
crypto  = require 'crypto'

class brew
  constructor: (o) ->
    ###
    o (dict argument): 
      includes: a sorted list of files and/or dirs to include
      excludes: (optional) any exceptions (files and/or dirs) to the includes
      match:    (optional) a regular expression any file must match; say if you want to limit to extensions
      compile:  (optional) fn to call on each file; takes (filename, str, cb) as arguments; if missing, just returns text
      join:     (optional) fn takes all the (sorted) compiled strings and joins them together for final output 
      onChange: (optional) a callback when anything changes in the brew. takes (passes version_hash, txt) as argument
      onReady:  (optional) a callback for when the first compilation pass is done and the brew is ready
      logger:   (optional) a function that handles lines of logs
    ###
    @_includes          = (path.resolve(p) for p in (o.includes  or []))
    @_excludes          = (path.resolve(p) for p in (o.excludes  or []))
    @_match             = o.match     or /.*/
    @_compile           = o.compile   or        (p, str, cb) -> cb null, str
    @_join              = o.join      or              (strs) -> strs.join "\n"
    @_onChange          = o.onChange  or (version_hash, txt) -> 
    @_onReady           = o.onReady   or (version_hash, txt) ->
    @_logger            = o.logger    or null
    @_isCompiling       = false
    @_versionHash       = null
    @_txt               = null
    @_includeMembers    = {} # keyed by strings in _includes; points at an array of matches in _files
    @_files             = {} # keyed by full paths to files; points to file class objects
    @_fs_watchers       = {} # keyed by full paths to files or dirs; makes sure we have finite watchers

    await @_fullPass defer()

    if o.onReady?
      o.onReady @getVersionHash(), @getCompiledText()

  getVersionHash:  -> @_versionHash
  getCompiledText: -> @_txt


  # --------------- PRIVATE PARTY BELOW ---------------------------------------

  _log: (str) -> if @_logger? then @_logger str

  _fullPass: (cb) ->
    d = Date.now()
    @_isCompiling = true
    for p, i in @_includes
      await @_recurse p, i, defer()
    @_flipToNewContent true
    @_isCompiling = false
    @_log "[#{Date.now() - d}ms] performed full pass"
    cb()

  _partialPass: (path, priority) ->
    ###
    happens when we get an fs.watch trigger on a dir or file
    ###
    while @_isCompiling
      @_log "deferring on compile of #{path} while waiting for another compile"
      await setTimeout defer(), 50    
    @_isCompiling = true
    d = Date.now()
    await @_recurse path, priority, defer()
    @_flipToNewContent false
    @_isCompiling = false
    @_log "[#{Date.now() - d}ms] performed partial pass of #{path};pri=#{priority}"

  _flipToNewContent: (is_first_pass) ->
    ###
    puts together all the compilations
    and generates a new version number
    ###
    d = Date.now()
    paths = (fp for fp, f of @_files when f.isOk())
    paths.sort (b,a) => @_files[a].getPriority() - @_files[b].getPriority()
    txts = []
    for fp in paths
      txts.push @_files[fp].getCompiledText()
    res = @_join txts
    if res isnt @_txt
      @_txt         = res
      @_versionHash = crypto.createHash('md5').update(@_txt).digest('hex')[0...8]
      if not is_first_pass
        @_onChange @_versionHash, @_txt
      @_log "[#{Date.now() - d}ms] flipped to new content"
    else
      @_log "[#{Date.now() - d}ms] content unchanged"

  _recurse: (p, priority, cb) ->
    ###
    p:  a file or directory
    ###
    if p in @_excludes
      @_log "skipping #{p} on recurse due to excludes"
    else
      await fs.stat p, defer err, stat
      if not err
        if stat.isDirectory()
          await fs.readdir p, defer err, files
          if not err
            for f in files
              fp = path.join p, f          
              await @_recurse fp, priority, defer()
        else if stat.isFile()
          if path.basename(p).match @_match
            await @_recurseHandleFile p, priority, defer()
          else
            @_log "skipping #{p} on recurse due to filename regexp match"
      else
        # perhaps this path does not exist;
        if @_files[p]? then delete @_files[p]
        @_log "removing #{p} from files; it went missing"
      @_monitorForChanges p, priority
    cb()

  _monitorForChanges: (p, priority) ->
    if @_fs_watchers[p]
      return
    try
      @_log "fs.watch() called for #{p}"
      @_fs_watchers[p] = fs.watch p, {persistent: true}, (evt, fn) =>
        @_log "fs.watch() triggered for #{p}"
        @_fs_watchers[p].close() # will be fired back up in the partial pass
        delete @_fs_watchers[p]
        @_partialPass p, priority
    catch e 
      @_log "fs.watch() failed for #{p}; it probably disappeared"

  _recurseHandleFile: (p, priority, cb) ->
    d = Date.now()
    if not @_files[p]? then @_files[p] = new file p
    @_files[p].setPriority Math.min priority, @_files[p].getPriority()

    await @_files[p].possiblyReload @_compile, defer(err, did_reload)
    if did_reload
      @_log "[#{Date.now() - d}ms] read & compiled #{p}"
    else
      @_log "[#{Date.now() - d}ms] ignored #{p}; unchanged"
    cb()

# -----------------------------------------------------------------------------

class file
  constructor: (p, priority) ->
    ###
    p = path
    pri = 0, 1, etc. (0 is lowest)
    ###
    @_path            = p
    @_priority        = priority
    @_src_txt         = null
    @_compiled_txt    = null
    @_err             = null

  possiblyReload: (compile_fn, cb) ->
    await fs.readFile @_path, "utf8", defer(err, data)
    @_err = null
    if err
      @_err = err
      cb err, null
    else if data isnt @_src_txt      
      @_src_txt = data
      await compile_fn @_path, @_src_txt, defer err, @_compiled_txt
      cb null, true
    else
      cb null, false

  isOk:               -> not @_err 
  getCompiledText:    -> @_compiled_txt
  getSrc:             -> @_src
  getPriority:        -> @_priority
  setPriority: (pri)  -> @_priority = pri

# -----------------------------------------------------------------------------

exports.brew = brew