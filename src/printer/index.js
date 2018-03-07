"use strict";

const util = require("../_util-from-prettier");
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
const dedent = docBuilders.dedent;

function printRubyString(raw, options) {
  // `rawContent` is the string exactly like it appeared in the input source
  // code, without its enclosing quotes.

  const modifierResult = /^\w+/.exec(raw);
  const modifier = modifierResult ? modifierResult[0] : "";

  let rawContent = raw.slice(modifier.length);

  rawContent = rawContent.slice(1, -1);

  const double = { quote: '"', regex: /"/g };
  const single = { quote: "'", regex: /'/g };

  const preferred = options.singleQuote ? single : double;
  const alternate = preferred === single ? double : single;

  let shouldUseAlternateQuote = false;

  // If `rawContent` contains at least one of the quote preferred for enclosing
  // the string, we might want to enclose with the alternate quote instead, to
  // minimize the number of escaped quotes.
  // Also check for the alternate quote, to determine if we're allowed to swap
  // the quotes on a DirectiveLiteral.
  if (
    rawContent.includes(preferred.quote) ||
    rawContent.includes(alternate.quote)
  ) {
    const numPreferredQuotes = (rawContent.match(preferred.regex) || []).length;
    const numAlternateQuotes = (rawContent.match(alternate.regex) || []).length;

    shouldUseAlternateQuote = numPreferredQuotes > numAlternateQuotes;
  }

  const enclosingQuote = shouldUseAlternateQuote
    ? alternate.quote
    : preferred.quote;

  // It might sound unnecessary to use `makeString` even if the string already
  // is enclosed with `enclosingQuote`, but it isn't. The string could contain
  // unnecessary escapes (such as in `"\'"`). Always using `makeString` makes
  // sure that we consistently output the minimum amount of escaped quotes.
  return modifier + util.makeString(rawContent, enclosingQuote);
}

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
      return concat([
        group(concat(["class", line, path.call(print, "name")])),
        indent(join(concat([hardline]), path.map(print, "body"))),
        group(concat([hardline, "end"]))
      ]);
    }

    case "begin": {
      return join(concat([hardline]), path.map(print, "body"));
    }

    case "str": {
      return printRubyString(n.source, options);
    }

    case "int": {
      return n.body.toString();
    }

    case "true": {
      return "true";
    }

    case "false": {
      return "false";
    }

    case "restarg": {
      return "*" + n.body;
    }

    case "send": {
      const body = join(concat([", ", softline]), path.map(print, "body"));
      let finalBody = group(concat(["(", body, ")"]));
      const name = n.name;
      if (keywords.hasOwnProperty(n.name)) {
        finalBody = group(concat([line, body]));
      }
      if (!body.parts.length) {
        finalBody = "";
      }
      let parts = group(concat([name, finalBody]));
      if (n.to) {
        parts = group(
          concat([
            path.call(print, "to"),
            line,
            name,
            line,
            concat(path.map(print, "body"))
          ])
        );
      }
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

    case "lvasgn": {
      const left = group(concat([n.left, " = "]));
      const right = join(concat([line]), path.map(print, "right"));
      return concat([left, right]);
    }

    case "while": {
      const _while = [];
      _while.push("while", line, group(path.call(print, "condition")));

      const body = [];
      body.push(
        group(concat(_while)),
        indent(
          concat([
            hardline,
            join(concat([hardline, hardline]), path.map(print, "body"))
          ])
        ),
        hardline,
        group("end")
      );
      return concat(body);
    }

    case "until": {
      const _until = [];
      _until.push("until", line, group(path.call(print, "condition")));

      const body = [];
      const isElse = n.else_part;
      body.push(
        group(concat(_until)),
        indent(concat([hardline, path.call(print, "body")])),
        hardline
      );
      if (isElse) {
        const elsePart = path.call(print, "else_part");
        body.push("else", indent(concat([hardline, elsePart])));
        body.push(hardline, "end");
      } else {
        body.push("end");
      }
      return concat(body);
    }

    case "if": {
      const _if = [];
      _if.push("if", line, group(path.call(print, "condition")));

      const body = [];
      const isElse = n.else_part;
      const isElseIf = isElse && n.else_part.ast_type === "if";
      body.push(
        group(concat(_if)),
        indent(concat([hardline, path.call(print, "body")])),
        hardline
      );
      if (isElse) {
        const elsePart = path.call(print, "else_part");
        if (isElseIf) {
          body.push("els", dedent(concat([elsePart])));
        } else {
          body.push("else", indent(concat([hardline, elsePart])));
          body.push(hardline, "end");
        }
      } else {
        body.push("end");
      }
      return concat(body);
    }

    default:
      // eslint-disable-next-line no-console
      console.error("Unknown Ruby Node:", n);
      return n.source;
  }
}

module.exports = genericPrint;
