var async, dialog, fs, initJSON, initWrite, initWriteConfirm, install, log, maxmertkit, modifyers, pack, path, project, request, themes, widgets, wrench, _;

pack = require('../package.json');

async = require('async');

request = require('superagent');

fs = require('fs');

dialog = require('commander');

wrench = require('wrench');

path = require('path');

_ = require('underscore');

modifyers = require('./modifyers');

themes = require('./themes');

widgets = require('./widgets');

project = require('./project');

maxmertkit = require('./maxmertkit');

log = require('./logger');

exports.init = function(options) {
  var _this = this;

  return async.series({
    "default": function(callback) {
      return initJSON(options, callback);
    }
  }, function(err, res) {
    if (err != null) {
      return log.error("An error while initialize maxmertkit.json");
    } else {
      if ((options.theme == null) && (options.modifyer == null) && (options.widget == null)) {
        widgets.init(options);
      }
      if (options.widget) {
        widgets.init(options);
      }
      if (options.theme) {
        themes.init(options);
      }
      if (options.modifyer) {
        return modifyers.init(options);
      }
    }
  });
};

exports.publish = function(options) {
  var mjson;

  mjson = maxmertkit.json();
  switch (mjson.type) {
    case 'widget':
      return widgets.publish(options);
    case 'modifyer':
      return modifyers.publish(options);
    case 'theme':
      return themes.publish(options);
  }
};

exports.unpublish = function(options) {
  var mjson;

  mjson = maxmertkit.json();
  switch (mjson.type) {
    case 'widget':
      return widgets.unpublish(options);
    case 'modifyer':
      return modifyers.unpublish(options);
    case 'theme':
      return themes.unpublish(options);
  }
};

exports.install = function(options) {
  var mjson;

  mjson = maxmertkit.json();
  fs.writeFileSync('_vars.sass', "");
  return install('.', mjson.dependences, mjson.themes);
};

install = function(pth, includes, themesGlobal) {
  if (includes == null) {
    includes = false;
  }
  return wrench.readdirRecursive(pth, function(error, files) {
    var file, index, mjson, thms, _results;

    _results = [];
    for (index in files) {
      file = files[index];
      file = path.join(pth, file);
      if (path.basename(file) === 'maxmertkit.json') {
        mjson = maxmertkit.json(file);
        fs.writeFileSync(path.join(path.dirname(file), '_imports.sass'), "");
        if (mjson.dependences != null) {
          pth = path.join(path.dirname(file), 'dependences/widgets');
          wrench.rmdirSyncRecursive(pth, function() {});
          wrench.mkdirSyncRecursive(pth, 0x1ff);
          if ((themesGlobal != null) && includes) {
            if (mjson.themes != null) {
              mjson.themes = _.extend(mjson.themes, themesGlobal);
            } else {
              mjson.themes = themesGlobal;
            }
          }
          if (mjson.type === 'widget') {
            widgets.install(pth, mjson, install, includes, themesGlobal);
          } else {
            project.install(pth, mjson, install, includes, themesGlobal);
          }
        }
        if (mjson.modifyers != null) {
          pth = path.join(path.dirname(file), 'dependences/modifyers');
          wrench.rmdirSyncRecursive(pth, function() {});
          wrench.mkdirSyncRecursive(pth, 0x1ff);
          modifyers.install(pth, mjson.modifyers);
        }
        if (mjson.themes != null) {
          thms = mjson.themes;
          if (themesGlobal != null) {
            thms = _.extend(mjson.themes, themesGlobal);
          }
          pth = path.join(path.dirname(file), 'dependences/themes');
          wrench.rmdirSyncRecursive(pth, function() {});
          wrench.mkdirSyncRecursive(pth, 0x1ff);
          _results.push(themes.install(pth, thms, true));
        } else {
          _results.push(void 0);
        }
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  });
};

initJSON = function(options, callback) {
  var _this = this;

  return async.series({
    type: function(callback) {
      if (!options.theme && !options.modifyer && !options.widget) {
        return callback(null, 'project');
      } else if (options.widget) {
        return callback(null, 'widget');
      } else if (options.theme) {
        return callback(null, 'theme');
      } else if (options.modifyer) {
        return callback(null, 'modifyer');
      }
    },
    name: function(callback) {
      var defaultPkgName;

      defaultPkgName = 'test';
      return dialog.prompt("name: (test) ", function(pkgName) {
        if (pkgName === '') {
          pkgName = defaultPkgName;
        }
        return callback(null, pkgName);
      });
    },
    version: function(callback) {
      var defaultVersion;

      defaultVersion = '0.0.0';
      return dialog.prompt("version: (0.0.0) ", function(version) {
        if (version === '') {
          version = defaultVersion;
        }
        return callback(null, version);
      });
    },
    description: function(callback) {
      return dialog.prompt("description: ", function(description) {
        return callback(null, description);
      });
    },
    repository: function(callback) {
      return dialog.prompt("repository: ", function(repository) {
        return callback(null, repository);
      });
    },
    author: function(callback) {
      return dialog.prompt("author: ", function(author) {
        return callback(null, author);
      });
    },
    license: function(callback) {
      var defaultLicense;

      defaultLicense = 'BSD';
      return dialog.prompt("license: (BSD) ", function(license) {
        if (license === '') {
          license = defaultLicense;
        }
        return callback(null, license);
      });
    }
  }, function(err, maxmertkitjson) {
    return initWriteConfirm(pack.maxmertkit, maxmertkitjson, callback);
  });
};

initWriteConfirm = function(file, json, callback) {
  var _this = this;

  console.log("\n\nWriting file " + file + "\n");
  return dialog.confirm("Is everything correct? \n\n " + (JSON.stringify(json, null, 4)) + "\n-> ", function(ok) {
    console.log("");
    if (!ok) {
      log.error("Initializing canceled");
      callback(true, null);
      return process.stdin.destroy();
    } else {
      return fs.exists(file, function(exists) {
        if (!exists) {
          initWrite(file, json, callback);
          return process.stdin.destroy();
        } else {
          log.error("File " + file + " already exists.");
          return dialog.confirm("Do you want to overwrite it and all other files in that folder? -> ", function(ok) {
            if (!ok) {
              log.error("initialization canceled.");
              callback(ok, null);
              return process.stdin.destroy();
            } else {
              initWrite(file, json, callback);
              return process.stdin.destroy();
            }
          });
        }
      });
    }
  });
};

initWrite = function(file, json, callback) {
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