#!/usr/bin/env node
var archives, common, fs, log, pack, path, program;

pack = require('../package.json');

path = require('path');

common = require('../lib/common');

archives = require('../lib/archives');

program = require('nomnom').colors();

log = require('../lib/logger');

fs = require('fs');

program.command('init').option('widget', {
  abbr: 'w',
  help: 'Initialize a new widget in the current directory.',
  flag: true
}).option('theme', {
  abbr: 't',
  help: 'Initialize a new theme in the current directory.',
  flag: true
}).option('modifier', {
  abbr: 'm',
  help: 'Initialize a new modifier in the current directory.',
  flag: true
}).option('animation', {
  abbr: 'a',
  help: 'Initialize a new animation in the current directory.',
  flag: true
}).callback(function(options) {
  return common.init(options);
}).help('Initializing new project/widget/modifier/theme/animation in the current directory.');

program.command('publish').callback(function(options) {
  return common.publish(options);
}).help('Publishing current version of widget/modifier/theme/animation.');

program.command('unpublish').callback(function(options) {
  return common.unpublish(options);
}).help('Unpublishing current version of widget/modifier/theme/animation.');

program.command('install').callback(function(options) {
  return common.install(options);
}).help('Installing all dependences, themes, modifiers and animations.');

program.command('pack').callback(function(options) {
  return archives.pack('.', null);
}).help('Pack current version of widget/modifier/theme/animation to a tar file.');

program.parse();
