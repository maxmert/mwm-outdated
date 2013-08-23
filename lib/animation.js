var async, dialog, fs, log, maxmertkit, mustache, pack, path, request, sass, templates, wrench, write;

pack = require('../package.json');

templates = require('../templates.json');

async = require('async');

request = require('superagent');

fs = require('fs');

path = require('path');

dialog = require('commander');

wrench = require('wrench');

mustache = require('mustache');

log = require('./logger');

maxmertkit = require('./maxmertkit');

exports.init = function(options) {
  var fileName, indexFileName, mjson,
    _this = this;
  fileName = '_animation.sass';
  indexFileName = '_index.sass';
  mjson = maxmertkit.json();
  return async.series({
    index: function(callback) {
      return sass(indexFileName, mustache.render(templates.animation, mjson), callback);
    },
    animation: function(callback) {
      var _this = this;
      return request.get("" + pack.homepage + "/api/0.1/defaults/animation").set('X-Requested-With', 'XMLHttpRequest').end(function(res) {
        if (res.ok) {
          return sass(fileName, mustache.render(templates.animationFinal, mjson), callback);
        } else {
          log.requestError(res.body.msg, 'ERRR', res.status);
          return callback(res.error, null);
        }
      });
    }
  }, function(err, res) {
    if (err != null) {
      log.error("An error while initialized animation.");
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
  fileName = '_animation.sass';
  return async.series({
    css: function(callback) {
      var raw;
      raw = fs.readFileSync(path.join('.', fileName), 'utf8');
      if (!(raw != null)) {
        log.error("couldn\'t read " + fileName + " file.");
        return callback(true, null);
      } else {
        return callback(null, raw);
      }
    },
    password: function(callback) {
      return callback(null, 'linolium');
    }
  }, function(err, res) {
    if (err != null) {
      log.error("Publishing canceled.");
      return process.stdin.destroy();
    } else {
      return request.post("" + pack.homepage + "/api/0.1/animation/" + mjson.name + "/" + mjson.version).set('X-Requested-With', 'XMLHttpRequest').send({
        animation: res.css,
        password: res.password,
        name: mjson.name,
        version: mjson.version,
        username: mjson.author,
        image: mjson.image
      }).end(function(res) {
        if (res.ok) {
          log.requestSuccess("animation " + mjson.name + "@" + mjson.version + " successfully published.");
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
      return callback(null, 'linolium');
    }
  }, function(err, res) {
    if (err != null) {
      log.error("Unpublishing canceled.");
      return process.stdin.destroy();
    } else {
      return request.del("" + pack.homepage + "/api/0.1/animation/" + mjson.name + "/" + mjson.version).set('X-Requested-With', 'XMLHttpRequest').send({
        password: res.password,
        name: mjson.name,
        version: mjson.version,
        username: mjson.author
      }).end(function(res) {
        if (res.ok) {
          log.requestSuccess("animation " + mjson.name + "@" + mjson.version + " successfully unpublished.");
          return process.stdin.destroy();
        } else {
          log.requestError(res.body.msg, 'ERRR', res.status);
          return process.stdin.destroy();
        }
      });
    }
  });
};

exports.install = function(pth, list) {
  var name, version, _results;
  wrench.mkdirSyncRecursive(pth, 0x1ff);
  _results = [];
  for (name in list) {
    version = list[name];
    _results.push((function(name, version, pth) {
      var _this = this;
      return request.get("" + pack.homepage + "/api/0.1/animation/" + name + "/" + version).set('X-Requested-With', 'XMLHttpRequest').end(function(res) {
        var fileName, renderJSON, str;
        if (res.ok) {
          renderJSON = {
            name: "" + name
          };
          str = "" + res.body.animation + "\n\n" + (mustache.render(templates.animationInstall, renderJSON));
          fileName = path.join(pth, "_" + name + ".sass");
          return sass(fileName, str, function(err, res) {
            if (err != null) {
              return log.error("Couldn\'t write file " + fileName);
            } else {
              return fs.appendFile(path.join(pth, '../../_imports.sass'), "@import 'dependences/animation/_" + name + ".sass'\n", function(err) {
                if (err != null) {
                  return log.error("Couldn\'t append import of " + fileName + " to the file _imports.sass");
                } else {
                  return log.requestSuccess("animation " + name + "@" + version + " successfully installed.");
                }
              });
            }
          });
        } else {
          log.requestError(res.body.msg, 'ERRR', res.status);
          return process.stdin.destroy();
        }
      });
    })(name, version, pth));
  }
  return _results;
};

write = function(file, json, callback) {
  return fs.writeFile(file, JSON.stringify(json, null, 4), function(err) {
    if (err) {
      log.error("initializing – " + err + ".");
      return callback(err, null);
    } else {
      log.success("file " + file + " successfully created.");
      return callback(null, json);
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
