var EventEmitter, archives, async, dialog, fs, immediately, log, maxmertkit, modifyers, mustache, pack, path, request, sys, templates, themes, write, _;

pack = require('../package.json');

templates = require('../templates.json');

async = require('async');

request = require('superagent');

fs = require('fs');

path = require('path');

dialog = require('commander');

_ = require('underscore');

mustache = require('mustache');

log = require('./logger');

archives = require('./archives');

maxmertkit = require('./maxmertkit');

themes = require('./themes');

modifyers = require('./modifyers');

EventEmitter = require("events").EventEmitter;

sys = require("sys");

if (global.setImmediate != null) {
  immediately = global.setImmediate;
}

exports.install = function(pth, mjson, calll, depent, themesss) {
  var arr;
  arr = [];
  _.each(mjson.dependences, function(ver, name) {
    return arr.push({
      name: name,
      version: ver.version != null ? ver.version : ver,
      themes: ver.themes != null ? ver.themes : mjson.themes
    });
  });
  return async.eachSeries(arr, function(widget, callback) {
    var _this = this;
    this.calll = calll;
    this.depent = depent;
    return immediately(function(calll, depent, themesss) {
      var fileName, req;
      fileName = "" + widget.name + "@" + widget.version + ".tar";
      return req = request.get("" + pack.homepage + "/api/0.1/widgets/" + widget.name + "/" + widget.version).set('X-Requested-With', 'XMLHttpRequest').end(function(res) {
        var stream;
        if (res.ok) {
          req = request.get("" + pack.homepage + "/api/0.1/widgets/" + widget.name + "/" + widget.version).set('X-Requested-With', 'XMLHttpRequest');
          stream = fs.createWriteStream(path.join(pth, fileName));
          req.pipe(stream);
          return stream.on('close', function() {
            return archives.unpack(path.join(pth, fileName), function(err) {
              if (err != null) {
                log.error("Couldn\'t unpack " + widget.name + "@" + widget.version + ".tar");
                return callback(true, null);
              } else {
                fs.unlink(path.join(pth, fileName));
                if (path.dirname(path.join(pth, '../../_myvars.sass')) !== '.') {
                  fs.readFile(path.join(pth, '../../_myvars.sass'), function(err, data) {
                    if (!(err != null)) {
                      return fs.appendFile('_vars.sass', "\n" + data + "\n", function(err) {});
                    }
                  });
                }
                return fs.readFile(path.join(pth, '../../_imports.sass'), function(err, data) {
                  if (err != null) {
                    log.error("Coluld not read " + (path.join(pth, '../../_imports.sass')) + ".");
                    return process.stdin.destroy();
                  } else {
                    data = data + ("@import 'dependences/widgets/" + widget.name + "/_index.sass'\n");
                    return fs.writeFile(path.join(pth, '../../_imports.sass'), data, function(err) {
                      if (err != null) {
                        log.error("Coluld not write " + (path.join(pth, '../../_imports.sass')) + ".");
                        return callback(true, null);
                      } else {
                        fs.writeFileSync(path.join(pth, widget.name, '_params.sass'), "$dependent: " + (depent ? true : null) + "\n");
                        if (widget.themes != null) {
                          if (themesss != null) {
                            themesss = _.extend(widget.themes, themesss);
                          } else {
                            themesss = widget.themes;
                          }
                        }
                        _this.calll(path.join(pth, widget.name), _this.depent, themesss);
                        return callback();
                      }
                    });
                  }
                });
              }
            });
          });
        } else {
          log.requestError(res.body.msg, 'ERRR', res.status);
          if (!(callback != null) || typeof callback === 'object') {
            return process.stdin.destroy();
          } else {
            return callback(true, widget.name);
          }
        }
      });
    });
  }, function(err) {
    if (err != null) {
      log.error("An error while installing widgets: " + err);
      return process.stdin.destroy();
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
