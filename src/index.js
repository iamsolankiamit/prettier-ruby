"use strict";

const utilShared = require("prettier").util;
const util = require("./_util-from-prettier");
const parse = require("./parser");
const print = require("./printer");

const languages = [
  {
    name: "Ruby",
    since: "1.9.2", // FIXME: Fix this before releasing.
    parsers: ["ruby"],
    extensions: [".rb"],
    tmScope: "source.rb",
    aceMode: "text",
    linguistLanguageId: 303,
    vscodeLanguageIds: ["ruby"]
  }
];

const parsers = {
  ruby: {
    parse,
    astFormat: "ruby",
    locStart: locStart,
    locEnd: locEnd
  }
};

function locStart(node) {
  // This function is copied from the code that used to live in the main prettier repo.

  // Handle nodes with decorators. They should start at the first decorator
  if (
    node.declaration &&
    node.declaration.decorators &&
    node.declaration.decorators.length > 0
  ) {
    return locStart(node.declaration.decorators[0]);
  }
  if (node.decorators && node.decorators.length > 0) {
    return locStart(node.decorators[0]);
  }

  if (node.__location) {
    return node.__location.startOffset;
  }
  if (node.range) {
    return node.range[0];
  }
  if (typeof node.start === "number") {
    return node.start;
  }
  if (node.source) {
    return (
      utilShared.lineColumnToIndex(node.source.start, node.source.input.css) - 1
    );
  }
  if (node.loc) {
    return node.loc.start;
  }

  return 0;
}

function locEnd(node) {
  // This function is copied from the code that used to live in the main prettier repo.

  const endNode = node.nodes && utilShared.getLast(node.nodes);
  if (endNode && node.source && !node.source.end) {
    node = endNode;
  }

  let loc;
  if (node.range) {
    loc = node.range[1];
  } else if (typeof node.end === "number") {
    loc = node.end;
  } else if (node.source) {
    loc = utilShared.lineColumnToIndex(node.source.end, node.source.input.css);
  }

  if (node.__location) {
    return node.__location.endOffset;
  }
  if (node.typeAnnotation) {
    return Math.max(loc, locEnd(node.typeAnnotation));
  }

  if (node.loc && !loc) {
    return node.loc.end;
  }

  return loc || 0;
}

function canAttachComment(node) {
  return node.ast_type && node.ast_type !== "comment";
}

function printComment(commentPath) {
  const comment = commentPath.getValue();

  switch (comment.ast_type) {
    case "comment": {
      const hasNewLine = comment.value.lastIndexOf("\n");
      let value = comment.value;
      const hasSpaceAfterHash = value.charAt(1) === " ";
      if (hasNewLine) {
        value = value.slice(0, hasNewLine);
      }

      if (!hasSpaceAfterHash) {
        value = "# " + value.slice(1, value.length);
      }

      return value;
    }
    default:
      throw new Error("Not a comment: " + JSON.stringify(comment));
  }
}

function clean(ast, newObj) {
  delete newObj.lineno;
  delete newObj.col_offset;
}

const printers = {
  ruby: {
    print,
    hasPrettierIgnore: util.hasIgnoreComment,
    printComment,
    canAttachComment,
    massageAstNode: clean
  }
};

module.exports = {
  languages,
  printers,
  parsers,
  defaultOptions: {
    printWidth: 79,
    tabWidth: 2,
    singleQuote: true
  }
};
