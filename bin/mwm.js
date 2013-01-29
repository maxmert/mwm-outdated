#!/usr/bin/env node;

var async, colorName, colorReset, colorTypeError, colorTypeHttp, colorWidgetName, pack, program, request;

pack = require('../package.json');

program = require('commander');

request = require('superagent');

async = require('async');

colorName = '\033[37m\033[40m';

colorTypeHttp = '\033[32m\033[40m';

colorTypeError = '\033[31m\033[40m';

colorWidgetName = '\033[34m';

colorReset = '\033[0m\033[0m';

program.version(pack.version);

program.command('install [names]').description('Install widgets with names').option('-s, --silent', 'Be quite while installing').action(function(name) {
  var isExist;
  program.args.unshift(name);
  console.log("" + colorName + "mwm" + colorReset + " Checking for availability: " + colorWidgetName + "%s" + colorReset, program.args);
  isExist = function(name) {
    return request.get("http://maxmertkit.com/widgets/" + name).set('Accept', 'application/json').end(function(res) {
      if (res.statusCode === 502 || 404) {
        return console.log("" + colorName + "mwm" + colorReset + " " + colorTypeError + "ERR" + colorReset + " " + colorWidgetName + "%s" + colorReset + " widget not found.", name);
      }
    });
  };
  return async.every(program.args, isExist, function(res) {
    return console.log(res);
  });
});

program.parse(process.argv);
