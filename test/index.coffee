chai = require "chai"
fs = require "fs"
should = chai.should()
util = require "core-util-is"
script = require "../src/index.coffee"
testjson = "test/test.json"
testobj = {
  name: "test"
  othername: "test2"
  number: 3
  nested:
    nested2: "test3"
    nested3: test4: "test5"
    nested4: [4,5,6]
  array: [1,2,3]
  array2: ["a","b","c"]
}
wraperr = (err, arg) ->
  (->script(arg)).should.throw err

describe "pkg-json", ->
  before (done) ->
    fs.writeFile testjson, JSON.stringify(testobj), -> done()
  describe "script", ->

    it "should be a function", ->
      script.should.be.a.function

    it "should throw when more than one option is given", ->
      err = "only one of set, get, push or splice is allowed"
      wraperr err, set:true, get:true
      wraperr err, set:true, push:true
      wraperr err, set:true, splice:true
      wraperr err, push:true, get:true
      wraperr err, splice:true, get:true
      wraperr err, splice:true, push:true

    it "should throw when type is unvalid", ->
      err = "type: something is invalid"
      wraperr err, type:"something"

    it "should throw when no command is given", ->
      err = "no command given, try set, get push or splice"
      wraperr err

    it "should throw when path is no string", ->
      err = "path needs to be a string"
      wraperr err, type:"set", path: 0

    it "should throw when no value is provided with push or splice", ->
      wraperr "no value provided for splice", splice:""
      wraperr "no value provided for push", push:""

    it "should throw when no value is provided with set and isn't forced", ->
      wraperr "no value provided for set, to remove a key use --force", set:""

    it "should throw when invalid json file is provided", ->
      wraperr "failed to load invalid.json", get:"", in:"invalid.json"

    it "should throw when data is no object", ->
      wraperr "data needs to be an object", get: "", data: ""

    it "should throw when path is not found", ->
      wraperr 'path test not found in {"test2":"test2"}', get: "test", data: test2: "test2"

    it "should throw when push or splice is called on something other then array", ->
      wraperr "there is no array at the given path", splice: "test", value:"1", data: test: "test"
      wraperr "there is no array at the given path", push: "test", value:"1", data: test: "test"

    it "should throw when splice is not found", ->
      wraperr "d not found in array", splice: "test", value:"d", data: test: ["a","b","c"]

    it "should throw when splice is out of boundary", ->
      wraperr "index out of array boundary", splice: "test", value:"4", data: test: ["a","b","c"]

    it "should throw when trying to overwrite a object/array with something other", ->
      wraperr "you are trying to overwrite an array by a number. Use -f to force.",
        set:"test",value:1,data: test: []
      wraperr "you are trying to overwrite an object by a number. Use -f to force.",
        set:"test",value:1,data: test: {}

    it "should work with get and package.json", ->
      script(get:"name").should.equal '"pkg-json"'
      script(type:"get", path:"name").should.equal '"pkg-json"'
      script(get:"bin.pkg-json").should.equal '"./index.js"'

    it "should work with get and testjson", ->
      script(get:"name",in:testjson).should.equal "\"#{testobj.name}\""

    it "should work with bare", ->
      script(get:"name",in:testjson,bare:true).should.equal testobj.name

    it "should work nested", ->
      script(get:"nested.nested3.test4",in:testjson,bare:true).should.equal testobj.nested.nested3.test4

    it "should work with set", (done) ->
      script set:"name",value:"newName",in:testjson,cb: ->
        script(get:"name",in:testjson,bare:true).should.equal "newName"
        done()

    it "should work with deep set", (done) ->
      script set:"nested.added.again",value:"something",in:testjson,cb: ->
        testobj.nested ?= {}
        testobj.nested.added ?= {}
        testobj.nested.added.again = "something"
        script(get:"nested.added.again",in:testjson,bare:true).should.equal "something"
        done()

    it "should work with return", ->
      clone = JSON.parse(JSON.stringify(testobj))
      clone.name = "newName2"
      script(set:"name",value:"newName2",in:testjson,return: true).should.equal JSON.stringify clone

    it "should work with push", (done) ->
      script push:"array",value:4,in:testjson,cb: ->
        script(get:"array",in:testjson).should.equal JSON.stringify [1,2,3,4]
        done()

    it "should work with splice", (done) ->
      script splice:"array",value:0,in:testjson,cb: ->
        script(get:"array",in:testjson).should.equal JSON.stringify [2,3,4]
        script splice:"array2",value:"b",in:testjson,cb: ->
          script(get:"array2",in:testjson).should.equal JSON.stringify ["a","c"]
          done()
  describe "cli", ->
    it "should be tested"

  after (done) ->
    fs.unlink testjson, -> done()
