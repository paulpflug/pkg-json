# out: ../lib/index.js
path = require "path"
fs = require "fs"
util = require("core-util-is")

processJson = (options) ->
  setPath = (value, lastChunk) ->
    if lastChunk.path.length == 1
      lastChunk.value[lastChunk.path[0]] = value
    else
      newObj = {}
      lastChunk.value[lastChunk.path[0]] = newObj
      setPath(value,value:newObj,path:lastChunk.path.slice(1))

  getPath = (obj, path) ->
    unless obj[path[0]]?
      if options.type == "set"
        return value:obj, path: path
      else
        throw new Error "path #{path[0]} not found in #{JSON.stringify(obj)}"
    if path.length > 1
      return getPath obj[path[0]], path.slice(1)
    else
      return value:obj, path: path
  lastChunk = getPath options.data, options.path.split(".")
  value = lastChunk.value[lastChunk.path[0]]
  result = (val) ->
    if options.bare and options.return
      return val
    else
      return JSON.stringify(val, null, '\t')
  if options.type == "push" or options.type == "splice"

    unless util.isArray(value)
      throw new Error "there is no array at the given path"
  switch (options.type)
    when "get" then result value
    when "set"
      unless options.force or lastChunk.path.length > 1
        type = typeof options.value
        if util.isArray(value) and not util.isArray(options.value)
          throw new Error "you are trying to overwrite an array by a #{type}. Use -f to force."
        if util.isObject(value) and not util.isObject(options.value)
          throw new Error "you are trying to overwrite an object by a #{type}. Use -f to force."
      if options.value?
        setPath(options.value, lastChunk)
      else
        if lastChunk.path.length == 1
          delete lastChunk.value[lastChunk.path]
        else
          throw new Error "path #{path.splice(0,1).join(".")} not found in #{JSON.stringify(value)}"

      result options.data
    when "push"
      value.push options.value
      result options.data
    when "splice"
      index = parseInt(options.value)
      index = value.indexOf(options.value) if isNaN(index)
      throw new Error "#{options.value} not found in array" if index < 0
      throw new Error "index out of array boundary" if index > value.length-1
      value.splice(index,1)
      result options.data

module.exports = (options) ->
  options ?= {}
  if (options.set and (options.get or options.push or options.splice)) or
     (options.get and (options.push or options.splice)) or
     (options.push and options.splice)
    throw new Error "only one of set, get, push or splice is allowed"
  if options.type?
    index = ["set","get","push","splice"].indexOf(options.type)
    throw new Error "type: #{options.type} is invalid" if index < 0
  else
    options.type = "set" if options.set?
    options.type = "get" if options.get?
    options.type = "push" if options.push?
    options.type = "splice" if options.splice?
  throw new Error "no command given, try set, get push or splice" unless options.type?
  unless options.path?
    options.path = options[options.type]
  throw new Error "path needs to be a string" unless util.isString options.path
  if options.type != "get" and not options.value?
    if options.type == "set" and not options.value? and not options.force
      throw new Error "no value provided for set, to remove a key use --force"
    else if options.type != "set"
      throw new Error "no value provided for #{options.type}"
  else
    try
      options.value JSON.parse options.value
  unless options.data?
    options.in ?="package.json"
    options.in = path.resolve(process.cwd(), options.in)
    try
      options.data = require(options.in)
    catch
      throw new Error "failed to load #{path.basename(options.in)}"
  throw new Error "data needs to be an object" unless util.isObject options.data
  if options.return or options.type== "get" or not options.in?
    options.return = true
    return processJson(options)
  else
    fs.writeFile options.in, processJson(options), (err) ->
      throw err if err?
      options.cb?()
