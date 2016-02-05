#!/usr/bin/env node
var program = require('commander')
  , fs = require('fs')
  , path = require('path')

program
  .version(JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'), 'utf8')).version)
  .usage('[options] <value>')
  .option('-f, --force', 'allows to overwrite a obj or array by string')
  .option('--stdout', 'will write to stdout instead changing the file')
  .option('--stdin','will read from stdin instead of a file')
  .option('-b, --bare','toString instead of "JSON.stringify", only works with stdout')
  .option('-i, --in <file>', 'json file')
  .option('set <path>', 'sets a path to value')
  .option('get <path>', 'gets a path')
  .option('remove <path>', 'same as -f set <path> null')
  .option('push <path>', 'pushes value to array')
  .option('splice <path>', 'splices value from array, also takes an index')
  .parse(process.argv)
var start = function(program) {
  program.cb = function() {process.exit(0)}
  result = require("./lib/index.js")(program)
  if (program.stdout || program.get){
    console.log(result)
  }
}
if (program.stdout ){
  program.return = true
}
program.value = program.args[0]
if (program.value == undefined) {program.value = null}
if (program.remove) {
  program.set = program.remove
  program.value = null
  program.force = true
}
try {
  if (program.stdin) {
    raw = ""
    process.stdin.on('end', function(){
      program.data = raw
      start(program)
    })
    process.stdin.setEncoding("utf8")
    process.stdin.on("data", function(chunk){
      if (chunk != null) {
        raw += chunk
      }
    })
  } else {
    start(program)
  }
} catch(e) {
  console.error(e.stack)
  process.exit(1)
}
