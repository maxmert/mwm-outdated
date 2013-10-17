var async, config, dialog, fs, immediately, log, maxmertkit, objectLength, pack, path, request, sass, wrench, write, _;

pack = require('../package.json');

config = require('./config');

async = require('async');

request = require('superagent');

fs = require('fs');

path = require('path');

dialog = require('commander');

_ = require('underscore');

wrench = require('wrench');

log = require('./logger');

maxmertkit = require('./maxmertkit');

if (global.setImmediate != null) {
  immediately = global.setImmediate;
}

exports.init = function(options) {
  var fileName,
    _this = this;
  fileName = path.join(config.directory(), 'theme.json');
  return async.series({
    modifier: function(callback) {
      return request.get("" + pack.homepage + "/api/0.1/defaults/theme").set('X-Requested-With', 'XMLHttpRequest').set('Accept', 'application/json').end(function(res) {
        if (res.ok) {
          return write(fileName, JSON.stringify(res.body, null, 4), callback);
        } else {
          log.requestError(res.body.msg, 'ERRR', res.status);
          return callback(res.error, null);
        }
      });
    }
  }, function(err, res) {
    if (err != null) {
      log.error("An error while initialized modifier.");
      return process.stdin.destroy();
    } else {
      return process.stdin.destroy();
    }
  });
};

exports.publish = function(options) {
  var fileName, mjson,
    _this = this;
  mjson = maxmertkit.json();
  fileName = 'theme.json';
  return async.series({
    theme: function(callback) {
      var json, rawjson;
      rawjson = fs.readFileSync(path.join(config.directory(), fileName));
      if (rawjson == null) {
        log.error("couldn\'t read " + fileName + " file.");
        return callback(true, null);
      } else {
        json = JSON.parse(rawjson);
        return callback(null, json);
      }
    },
    password: function(callback) {
      return dialog.password('\nEnter your password: ', function(password) {
        return callback(null, password);
      });
    }
  }, function(err, res) {
    if (err != null) {
      log.error("Publishing canceled.");
      return process.stdin.destroy();
    } else {
      return request.post("" + pack.homepage + "/api/0.1/themes/" + mjson.name + "/" + mjson.version).set('X-Requested-With', 'XMLHttpRequest').send({
        theme: res.theme,
        password: res.password,
        name: mjson.name,
        version: mjson.version,
        username: mjson.author
      }).end(function(res) {
        if (res.ok) {
          log.requestSuccess("theme " + mjson.name + "@" + mjson.version + " successfully published.");
          return process.stdin.destroy();
        } else {
          log.requestError(res.body.msg, 'ERRR', res.status);
          return process.stdin.destroy();
        }
      });
    }
  });
};

exports.unpublish = function(options) {
  var mjson,
    _this = this;
  mjson = maxmertkit.json();
  return async.series({
    password: function(callback) {
      return dialog.password('\nEnter your password: ', function(password) {
        return callback(null, password);
      });
    }
  }, function(err, res) {
    if (err != null) {
      log.error("Unpublishing canceled.");
      return process.stdin.destroy();
    } else {
      return request.del("" + pack.homepage + "/api/0.1/themes/" + mjson.name + "/" + mjson.version).set('X-Requested-With', 'XMLHttpRequest').send({
        password: res.password,
        name: mjson.name,
        version: mjson.version,
        username: mjson.author
      }).end(function(res) {
        if (res.ok) {
          log.requestSuccess("theme " + mjson.name + "@" + mjson.version + " successfully unpublished.");
          return process.stdin.destroy();
        } else {
          log.requestError(res.body.msg, 'ERRR', res.status);
          return process.stdin.destroy();
        }
      });
    }
  });
};

objectLength = function(obj) {
  var key, length;
  length = 0;
  for (key in obj) {
    if (obj.hasOwnProperty(key)) {
      length++;
    }
  }
  return length;
};

exports.install = function(pth, list, depent) {
  var arr, fileName, ok, result;
  if (depent == null) {
    depent = null;
  }
  wrench.mkdirSyncRecursive(pth, 0x1ff);
  fileName = path.join(pth, "_index.sass");
  fs.writeFileSync(fileName, '');
  result = null;
  ok = objectLength(list) - 1;
  arr = [];
  _.each(list, function(version, name) {
    return arr.push({
      name: name,
      version: version
    });
  });
  result = '';
  return async.reduce(arr, null, function(result, theme, callback) {
    return (function(result, theme, callback) {
      var _this = this;
      return request.get("" + pack.homepage + "/api/0.1/themes/" + theme.name + "/" + theme.version).set('X-Requested-With', 'XMLHttpRequest').end(function(res) {
        var nme, value, _ref;
        if (!res.ok) {
          return log.requestError(res.body.msg, 'ERRR', res.status);
        } else {
          if (result == null) {
            result = res.body;
          } else {
            _ref = res.body;
            for (nme in _ref) {
              value = _ref[nme];
              result[nme] += "\t" + value;
            }
          }
          log.requestSuccess("theme " + theme.name + "@" + theme.version + " successfully downloaded.");
          return callback(null, result);
        }
      });
    })(result, theme, callback);
  }, function(err, res) {
    var nme, str, value;
    if (err != null) {
      log.error("An error while installing themes.");
      return process.stdin.destroy();
    } else {
      if (res == null) {
        log.error("An error while installing themes.");
        return process.stdin.destroy();
      } else {
        str = '';
        for (nme in res) {
          value = res[nme];
          if (nme === 'theme') {
            str += "$" + nme + "s: " + value + "\n";
          } else {
            str += "$" + nme + ": " + value + "\n";
          }
        }
        return sass(fileName, str, function(err, res) {
          if (err != null) {
            return log.error("Couldn\'t write file " + fileName);
          } else {
            if (depent != null) {
              return fs.appendFile(path.join(pth, '../../_imports.sass'), "@import 'dependences/themes/_index.sass'\n", function(err) {
                if (err != null) {
                  return log.error("Couldn\'t append import of " + fileName + " to the file _imports.sass");
                } else {
                  return log.success("all themes successfully installed.");
                }
              });
            } else {
              return log.success("all themes successfully installed.");
            }
          }
        });
      }
    }
  });
};

write = function(file, data, callback) {
  return fs.writeFile(file, data, function(err) {
    if (err) {
      log.error("initializing – " + err + ".");
      return callback(err, null);
    } else {
      log.success("file " + file + " successfully created.");
      return callback(null, data);
    }
  });
};

sass = function(fileName, data, callback) {
  return fs.writeFile(fileName, data, function(err) {
    if (err != null) {
      return callback(err, null);
    } else {
      return callback(null, fileName);
    }
  });
};
