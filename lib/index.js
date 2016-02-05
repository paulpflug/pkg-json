(function() {
  var fs, path, processJson, util;

  path = require("path");

  fs = require("fs");

  util = require("core-util-is");

  processJson = function(options) {
    var getPath, index, lastChunk, result, setPath, type, value;
    setPath = function(value, lastChunk) {
      var newObj;
      if (lastChunk.path.length === 1) {
        return lastChunk.value[lastChunk.path[0]] = value;
      } else {
        newObj = {};
        lastChunk.value[lastChunk.path[0]] = newObj;
        return setPath(value, {
          value: newObj,
          path: lastChunk.path.slice(1)
        });
      }
    };
    getPath = function(obj, path) {
      if (obj[path[0]] == null) {
        if (options.type === "set") {
          return {
            value: obj,
            path: path
          };
        } else {
          throw new Error("path " + path[0] + " not found in " + (JSON.stringify(obj)));
        }
      }
      if (path.length > 1) {
        return getPath(obj[path[0]], path.slice(1));
      } else {
        return {
          value: obj,
          path: path
        };
      }
    };
    lastChunk = getPath(options.data, options.path.split("."));
    value = lastChunk.value[lastChunk.path[0]];
    result = function(val) {
      if (options.bare && options["return"]) {
        return val;
      } else {
        return JSON.stringify(val);
      }
    };
    if (options.type === "push" || options.type === "splice") {
      if (!util.isArray(value)) {
        throw new Error("there is no array at the given path");
      }
    }
    switch (options.type) {
      case "get":
        return result(value);
      case "set":
        if (!(options.force || lastChunk.path.length > 1)) {
          type = typeof options.value;
          if (util.isArray(value) && !util.isArray(options.value)) {
            throw new Error("you are trying to overwrite an array by a " + type + ". Use -f to force.");
          }
          if (util.isObject(value) && !util.isObject(options.value)) {
            throw new Error("you are trying to overwrite an object by a " + type + ". Use -f to force.");
          }
        }
        if (options.value != null) {
          setPath(options.value, lastChunk);
        } else {
          if (lastChunk.path.length === 1) {
            delete lastChunk.value[lastChunk.path];
          } else {
            throw new Error("path " + (path.splice(0, 1).join(".")) + " not found in " + (JSON.stringify(value)));
          }
        }
        return result(options.data);
      case "push":
        value.push(options.value);
        return result(options.data);
      case "splice":
        index = parseInt(options.value);
        if (isNaN(index)) {
          index = value.indexOf(options.value);
        }
        if (index < 0) {
          throw new Error(options.value + " not found in array");
        }
        if (index > value.length - 1) {
          throw new Error("index out of array boundary");
        }
        value.splice(index, 1);
        return result(options.data);
    }
  };

  module.exports = function(options) {
    var error, index;
    if (options == null) {
      options = {};
    }
    if ((options.set && (options.get || options.push || options.splice)) || (options.get && (options.push || options.splice)) || (options.push && options.splice)) {
      throw new Error("only one of set, get, push or splice is allowed");
    }
    if (options.type != null) {
      index = ["set", "get", "push", "splice"].indexOf(options.type);
      if (index < 0) {
        throw new Error("type: " + options.type + " is invalid");
      }
    } else {
      if (options.set != null) {
        options.type = "set";
      }
      if (options.get != null) {
        options.type = "get";
      }
      if (options.push != null) {
        options.type = "push";
      }
      if (options.splice != null) {
        options.type = "splice";
      }
    }
    if (options.type == null) {
      throw new Error("no command given, try set, get push or splice");
    }
    if (options.path == null) {
      options.path = options[options.type];
    }
    if (!util.isString(options.path)) {
      throw new Error("path needs to be a string");
    }
    if (options.type !== "get" && (options.value == null)) {
      if (options.type === "set" && (options.value == null) && !options.force) {
        throw new Error("no value provided for set, to remove a key use --force");
      } else if (options.type !== "set") {
        throw new Error("no value provided for " + options.type);
      }
    } else {
      try {
        options.value(JSON.parse(options.value));
      } catch (undefined) {}
    }
    if (options.data == null) {
      if (options["in"] == null) {
        options["in"] = "package.json";
      }
      options["in"] = path.resolve(process.cwd(), options["in"]);
      try {
        options.data = require(options["in"]);
      } catch (error) {
        throw new Error("failed to load " + (path.basename(options["in"])));
      }
    }
    if (!util.isObject(options.data)) {
      throw new Error("data needs to be an object");
    }
    if (options["return"] || options.type === "get" || (options["in"] == null)) {
      options["return"] = true;
      return processJson(options);
    } else {
      return fs.writeFile(options["in"], processJson(options), function(err) {
        if (err != null) {
          throw err;
        }
        return typeof options.cb === "function" ? options.cb() : void 0;
      });
    }
  };

}).call(this);
