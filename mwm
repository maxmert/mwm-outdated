#!/usr/bin/env node;

var archives, common, fs, log, pack, path, program;

pack = require('./package.json');

path = require('path');

common = require('./lib/common');

archives = require('./lib/archives');

program = require('nomnom').colors();

log = require('./lib/logger');

fs = require('fs');

program.command('init').option('widget', {
  abbr: 'w',
  help: 'Initialize a new widget in the current directory.',
  flag: true
}).option('theme', {
  abbr: 't',
  help: 'Initialize a new theme in the current directory.',
  flag: true
}).option('modifyer', {
  abbr: 'm',
  help: 'Initialize a new modifyer in the current directory.',
  flag: true
}).callback(function(options) {
  return common.init(options);
}).help('Initializing new project/widget/modifyer/theme in the current directory.');

program.command('publish').callback(function(options) {
  return common.publish(options);
}).help('Publishing current version of widget/modifyer/theme.');

program.command('unpublish').callback(function(options) {
  return common.unpublish(options);
}).help('Unpublishing current version of widget/modifyer/theme.');

program.command('install').callback(function(options) {
  return common.install(options);
}).help('Installing all dependences, themes and modifyers.');

program.command('pack').callback(function(options) {
  return archives.pack('.', null);
}).help('Pack current version of widget/modifyer/theme to a tar file.');

program.parse();
