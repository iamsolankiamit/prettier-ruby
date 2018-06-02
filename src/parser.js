/* eslint-disable no-console */
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
  const { tokens, sexp, json } = JSON.parse(res);

  if (process.env.DEBUG) {
    console.log("tokens:\n", tokens);
    console.log("sexp:\n", sexp);
    console.log("json AST:\n", JSON.stringify(json, null, 4));
  }

  return json;
}

module.exports = parse;
