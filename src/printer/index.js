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
      // Join the items in Body using commas.
      const body = join(concat([", ", softline]), path.map(print, "body"));
      // default to adding brackets
      let finalBody = group(concat(["(", body, ")"]));
      // name is the item which is being sent
      const name = n.name;
      // if the item is a ruby method, then avoid the brackets
      if (keywords.hasOwnProperty(n.name)) {
        finalBody = group(concat([line, body]));
      }
      // if the body is blank print nothing
      if (!body.parts.length) {
        finalBody = "";
      }
      const parts = [];
      // items are sent "to" something.
      if (n.to) {
        // if it is a chain of send (sent via the dot operator)
        let dotConnected = false;
        if (n.to.ast_type === "send" && !n.body.length) {
          dotConnected = true;
        }
        // if (n.to.ast_type === "send" && n.name === "[]") {
        //   dotConnected = true;
        // }
        // Usually the last item (Class name, Module name, etc)
        if (n.to.ast_type !== "send") {
          dotConnected = true;
        }
        parts.push(path.call(print, "to"));
        if (n.name !== "[]") {
          if (dotConnected) {
            parts.push(".");
          } else {
            parts.push(line);
          }
          parts.push(name);
        }
        // we don't add space if it is dot connected
        if (n.name !== "[]" && !dotConnected) {
          parts.push(line);
        }
        if (n.name === "[]") {
          parts.push("[");
        } else if (dotConnected && n.body.length) {
          parts.push("(");
        }
        parts.push(concat(path.map(print, "body")));
        if (n.name === "[]") {
          parts.push("]");
        } else if (dotConnected && n.body.length) {
          parts.push(")");
        }
      } else {
        parts.push(name, finalBody);
      }
      return group(concat(parts));
    }

    case "File": {
      return concat([printBody(path, print), hardline]);
    }

    case "def": {
      const def = [];

      def.push("def", line, path.call(print, "name"));

      const parts = [];

      parts.push(group(concat(def)));
      const args = [
        "(",
        indent(concat([softline, path.call(print, "args")])),
        softline,
        ")"
      ];
      if (n.args) {
        parts.push(group(concat(args)));
      }
      parts.push(
        indent(concat([hardline, concat(path.map(print, "body"))])),
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

    case "ivar": {
      return path.call(print, "body");
    }

    case "lvar": {
      return n.lvar;
    }

    case "ivasgn":
    case "lvasgn": {
      const left = group(concat([n.left, " = "]));
      const right = join(concat([line]), path.map(print, "right"));
      return concat([left, group(right)]);
    }

    case "return": {
      return group(concat(["return", line, path.call(print, "value")]));
    }

    case "nil": {
      return n.body;
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

    case "block": {
      let singleLineBlock = false;
      let isLambda = false;
      if (n.body.length === 1) {
        singleLineBlock = true;
        if (n.of.name === "lambda") {
          isLambda = true;
          n.of.name = "->";
        }
      }
      const _of = path.call(print, "of");
      let body = [];
      let argsContent = "";
      if (n.args.body.length > 0) {
        const args = group(path.call(print, "args"));
        argsContent = concat([
          singleLineBlock && isLambda ? "(" : "|",
          args,
          singleLineBlock && isLambda ? ")" : "|"
        ]);
      }
      body = path.map(print, "body");
      const blockHead = group(
        concat([
          _of,
          singleLineBlock && isLambda ? argsContent : "",
          line,
          singleLineBlock ? "{" : "do",
          line,
          singleLineBlock && isLambda ? "" : argsContent
        ])
      );

      const bodyIndented = indent(
        group(
          concat([
            singleLineBlock ? "" : hardline,
            isLambda ? "" : line,
            concat(body),
            line,
            singleLineBlock ? "}" : ""
          ])
        )
      );
      const end = dedent(concat([hardline, "end"]));
      return concat([blockHead, bodyIndented, singleLineBlock ? "" : end]);
    }

    case "array": {
      return group(
        concat([
          "[",
          join(concat([", ", softline]), path.map(print, "body")),
          "]"
        ])
      );
    }

    case "hash": {
      let body = path.map(print, "body");
      if (body.length > 0) {
        body = concat([
          indent(
            group(concat([line, group(join(concat([", ", softline]), body))]))
          ),
          line
        ]);
      } else {
        body = "";
      }

      return group(concat(["{", body, "}"]));
    }

    case "pair": {
      return group(
        concat([
          group(concat([n.symbol.body, ":"])),
          line,
          path.call(print, "value")
        ])
      );
    }

    case "sym": {
      return concat([":", path.call(print, "body")]);
    }

    case "const": {
      return concat([path.call(print, "body")]);
    }
    case "case": {
      const _case = [];
      _case.push("case", line, group(path.call(print, "condition")));
      const body = [];
      let hasElse = false;
      const lastBodyItem = n.body[n.body.length - 1];
      if (lastBodyItem && lastBodyItem.ast_type !== "when") {
        hasElse = true;
      }
      let astBody = path.map(print, "body");
      let elsePart;
      if (hasElse) {
        elsePart = astBody[astBody.length - 1];
        astBody = astBody.slice(0, astBody.length - 1);
      }
      const parts = [];
      body.push(hardline, concat(astBody));
      if (hasElse) {
        body.push("else", indent(concat([hardline, elsePart])));
      }
      parts.push(group(concat(_case)), concat(body), hardline);
      parts.push("end");
      return concat(parts);
    }

    case "when": {
      const _when = [];
      _when.push("when", line, group(path.call(print, "condition")));

      const body = [];
      body.push(
        group(concat(_when)),
        indent(concat([hardline, concat(path.map(print, "body"))])),
        hardline
      );
      return concat(body);
    }

    case "irange": {
      const range = [];
      range.push(path.call(print, "from"), "..", path.call(print, "to"));
      return concat(range);
    }

    default:
      // eslint-disable-next-line no-console
      console.error("Unknown Ruby Node:", n);
      return n.source;
  }
}

module.exports = genericPrint;
