"use strict";

// const util = require("../_util-from-prettier");
const tokens = require("./tokens");
const keywords = require("./keywords");

const docBuilders = require("prettier").doc.builders;
const concat = docBuilders.concat;
const join = docBuilders.join;
const hardline = docBuilders.hardline;
const line = docBuilders.line;
const softline = docBuilders.softline;
const group = docBuilders.group;
const indent = docBuilders.indent;

// function printRubyString(raw, options) {
//   // `rawContent` is the string exactly like it appeared in the input source
//   // code, without its enclosing quotes.

//   const modifierResult = /^\w+/.exec(raw);
//   const modifier = modifierResult ? modifierResult[0] : "";

//   let rawContent = raw.slice(modifier.length);

//   rawContent = rawContent.slice(1, -1);

//   const double = { quote: '"', regex: /"/g };
//   const single = { quote: "'", regex: /'/g };

//   const preferred = options.singleQuote ? single : double;
//   const alternate = preferred === single ? double : single;

//   let shouldUseAlternateQuote = false;

//   // If `rawContent` contains at least one of the quote preferred for enclosing
//   // the string, we might want to enclose with the alternate quote instead, to
//   // minimize the number of escaped quotes.
//   // Also check for the alternate quote, to determine if we're allowed to swap
//   // the quotes on a DirectiveLiteral.
//   if (
//     rawContent.includes(preferred.quote) ||
//     rawContent.includes(alternate.quote)
//   ) {
//     const numPreferredQuotes = (rawContent.match(preferred.regex) || []).length;
//     const numAlternateQuotes = (rawContent.match(alternate.regex) || []).length;

//     shouldUseAlternateQuote = numPreferredQuotes > numAlternateQuotes;
//   }

//   const enclosingQuote = shouldUseAlternateQuote
//     ? alternate.quote
//     : preferred.quote;

//   // It might sound unnecessary to use `makeString` even if the string already
//   // is enclosed with `enclosingQuote`, but it isn't. The string could contain
//   // unnecessary escapes (such as in `"\'"`). Always using `makeString` makes
//   // sure that we consistently output the minimum amount of escaped quotes.
//   return modifier + util.makeString(rawContent, enclosingQuote);
// }

function printBody(path, print) {
  return join(concat([hardline, hardline]), path.map(print, "body"));
}

function genericPrint(path, options, print) {
  const n = path.getValue();
  if (!n) {
    return "";
  }

  if (typeof n === "string") {
    return n;
  }

  if (typeof n === "number") {
    return n;
  }

  if (tokens.hasOwnProperty(n.ast_type)) {
    return tokens[n.ast_type];
  }

  switch (n.ast_type) {
    case "class": {
      return concat([printBody(path, print), hardline]);
    }

    case "begin": {
      return concat([printBody(path, print)]);
    }

    case "send": {
      const body = join(concat([", ", softline]), path.map(print, "body"));
      let finalBody = body;
      if (!keywords.hasOwnProperty(n.name)) {
        finalBody = group(concat(["(", body, ")"]));
      }
      const parts = group(concat([n.name, line, finalBody]));
      return parts;
    }

    case "File": {
      return concat([printBody(path, print), hardline]);
    }

    case "def": {
      const def = [];

      def.push("def", line, path.call(print, "name"));

      const parts = [];

      parts.push(
        group(concat(def)),
        group(
          concat([
            "(",
            indent(concat([softline, path.call(print, "args")])),
            softline,
            ")"
          ])
        ),
        indent(concat([hardline, printBody(path, print)])),
        hardline,
        group("end")
      );

      return concat(parts);
    }

    case "args": {
      return join(concat([", ", softline]), path.map(print, "body"));
    }

    case "optarg": {
      return concat([
        group(concat([path.call(print, "arg"), " = "])),
        group(concat(path.map(print, "value")))
      ]);
    }

    case "arg": {
      return n.arg;
    }

    case "lvar": {
      return n.lvar;
    }

    default:
      // eslint-disable-next-line no-console
      console.error("Unknown Ruby Node:", n);
      return n.source;
  }
}

module.exports = genericPrint;
