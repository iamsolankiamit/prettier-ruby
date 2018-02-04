"use strict";

const spawnSync = require("child_process").spawnSync;
const path = require("path");

function parseText(text) {
  const executionResult = spawnSync("ruby", [
    path.join(__dirname, "../vendor/ruby/astexport.rb"),
    text
  ]);

  const error = executionResult.stderr.toString();
  if (error) {
    throw new Error(error);
  }

  return executionResult;
}

function parse(text) {
  const executionResult = parseText(text);

  const res = executionResult.stdout.toString();
  const ast = JSON.parse(res);
  return ast;
}

module.exports = parse;
