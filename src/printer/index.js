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
const ifBreak = docBuilders.ifBreak;

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
    case "module": {
      const parts = [];
      parts.push(group(concat(["module", line, path.call(print, "name")])));
      parts.push(indent(concat([hardline, concat(path.map(print, "body"))])));
      parts.push(group(concat([hardline, "end"])));
      return concat(parts);
    }
    case "sclass":
    case "class": {
      const name = path.call(print, "name");
      const _extends = path.call(print, "extends");
      const selfClass = n.ast_type === "sclass";
      let parts = [];
      parts.push("class ");
      if (selfClass) {
        parts.push("<< ");
      }
      parts.push(name);
      if (_extends) {
        if (!selfClass) {
          parts.push(" < ", _extends);
        } else {
          parts.push(indent(concat([hardline, _extends])));
        }
      }
      parts = [group(concat(parts))];
      const body = path.map(print, "body");
      parts.push(
        indent(concat([hardline, concat(body)])),
        group(concat([hardline, "end"]))
      );
      return concat(parts);
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

    case "break": {
      return "break";
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
      let name = n.name;
      // if the item is a ruby method, then avoid the brackets
      if (keywords.hasOwnProperty(n.name)) {
        finalBody = group(concat([line, body]));
      }
      // if the body is blank print nothing
      if (!body.parts.length) {
        finalBody = "";
      }
      let parts = [];
      // items are sent "to" something.
      if (n.to) {
        // if it is a chain of send (sent via the dot operator)
        let dotConnected = false;
        let hasEqual = false;
        if (n.to.ast_type === "send" && !n.body.length) {
          dotConnected = true;
        }
        // if (n.to.ast_type === "send" && n.name === "[]") {
        //   dotConnected = true;
        // }
        // Usually the last item (Class name, Module name, etc)
        if (n.to.ast_type !== "send" && !tokens.includes(name)) {
          dotConnected = true;
        }
        let withoutName = false;
        let arrayEqual = false;
        if (name === "-@") {
          withoutName = true;
          parts.push("-");
        }
        parts.push(path.call(print, "to"));
        let arraySend = false;
        if (n.name === "[]" || n.name === "[]=") {
          if (n.name === "[]=") {
            arrayEqual = true;
          }
          arraySend = true;
        }
        if (!arraySend && !withoutName) {
          if (
            !tokens.includes(name) &&
            name.lastIndexOf("=") === name.length - 1
          ) {
            hasEqual = true;
            dotConnected = true;
            name = name.substring(0, name.length - 1) + " = ";
          }
          if (dotConnected) {
            parts.push(".");
          } else {
            parts.push(line);
          }

          parts.push(name);
        }
        // we don't add space if it is dot connected
        if (!arraySend && !dotConnected && !hasEqual) {
          parts.push(line);
        }
        if (arraySend) {
          parts.push("[");
        } else if (dotConnected && n.body.length && !hasEqual) {
          parts.push("(");
        }
        parts = [concat(parts)];
        for (let i = 0; i < n.body.length; i++) {
          const element = n.body[i];
          if (element.ast_type === "hash") {
            n.body[i].noBraces = true;
          }
          if (arraySend && element.ast_type === "send") {
            if (n.subParts) {
              n.subParts.push(n.body[i]);
            } else {
              n.subParts = [n.body[i]];
            }
            n.body.splice(i, 1);
            i -= 1;
          }
        }
        parts.push(
          group(
            indent(
              concat([
                softline,
                join(concat([",", line]), path.map(print, "body"))
              ])
            )
          )
        );
        if (arraySend) {
          parts.push("]");
        } else if (dotConnected && n.body.length && !hasEqual) {
          parts.push(concat([softline, ")"]));
        }
        if (arrayEqual) {
          parts.push(" = ", concat(path.map(print, "subParts")));
        }
      } else {
        parts.push(name, finalBody);
      }
      return group(concat(parts));
    }

    case "and": {
      return concat([
        path.call(print, "left"),
        line,
        "&&",
        line,
        path.call(print, "right")
      ]);
    }

    case "or": {
      return concat([
        path.call(print, "left"),
        line,
        "||",
        line,
        path.call(print, "right")
      ]);
    }

    case "File": {
      return concat([printBody(path, print), hardline]);
    }
    case "defs":
    case "def": {
      const def = [];
      const isSelf = n.ast_type === "defs";
      let name = path.call(print, "name");
      if (isSelf) {
        name = concat(["self.", name]);
      }
      def.push("def", line, name);

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
    case "casgn":
    case "or_asgn":
    case "ivasgn":
    case "lvasgn": {
      const hasRight = !!n.right.length;
      const leftParts = [];
      leftParts.push(path.call(print, "left"));
      const orAssign = n.ast_type === "or_asgn";
      if (hasRight) {
        leftParts.push(line);
        if (orAssign) {
          leftParts.push("||");
        }
        leftParts.push("=", line);
      }
      const left = group(concat(leftParts));
      const right = join(line, path.map(print, "right"));
      return concat([left, group(right)]);
    }

    case "return": {
      const value = path.call(print, "value");
      return group(concat(["return", value ? " " : "", value]));
    }

    case "nil": {
      return n.body;
    }

    case "masgn": {
      const multipleLeftAssign = path.call(print, "mlhs");
      const body = group(concat(path.map(print, "body")));
      const parts = [];
      const left = group(concat([multipleLeftAssign, line, "=", line]));
      parts.push(left, body);
      return concat(parts);
    }

    case "mlhs": {
      return group(join(concat([",", line]), path.map(print, "body")));
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

      const bodyParts = [];

      let isElse = n.else_part;
      const isElseIf = isElse && n.else_part.ast_type === "if";
      let singleLineBlock = false;
      if (n.body && n.body.ast_type !== "begin" && !isElse) {
        singleLineBlock = true;
      }
      const body = path.call(print, "body");
      // if the body is blank and it has else part, then print "unless" elsePart
      if (body === "" && isElse) {
        isElse = false;
        singleLineBlock = true;
        _if.push("unless", line, group(path.call(print, "condition")));
        bodyParts.push(
          group(concat([path.call(print, "else_part"), " ", concat(_if)]))
        );
      } else {
        _if.push("if", line, group(path.call(print, "condition")));
        if (singleLineBlock) {
          bodyParts.push(group(concat([body, " ", concat(_if)])));
        } else {
          bodyParts.push(group(concat(_if)));
          bodyParts.push(indent(concat([hardline, body])));
          bodyParts.push(hardline);
        }
      }
      if (isElse) {
        const elsePart = path.call(print, "else_part");
        if (isElseIf) {
          bodyParts.push("els", dedent(concat([elsePart])));
        } else {
          bodyParts.push("else", indent(concat([hardline, elsePart])));
          bodyParts.push(hardline, "end");
        }
      } else {
        if (!singleLineBlock) {
          bodyParts.push("end");
        }
      }
      return concat(bodyParts);
    }

    case "block": {
      let singleLineBlock = false;
      let isLambda = false;
      if (n.body.length > 0 && n.body[0].ast_type !== "begin") {
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
          singleLineBlock && isLambda ? ")" : "| "
        ]);
      }
      body = path.map(print, "body");
      let blockHead = [];
      blockHead.push(_of);
      const args = [];
      if (singleLineBlock) {
        if (isLambda) {
          args.push(argsContent);
        }
        args.push(ifBreak(" do ", " { "));
        if (!isLambda) {
          args.push(argsContent);
        }
      } else {
        args.push(" do ");
        if (!isLambda) {
          args.push(argsContent);
        }
      }
      blockHead.push(concat(args));
      blockHead = [ifBreak(concat(blockHead), group(concat(blockHead)))];
      blockHead.push(
        indent(
          group(
            concat([
              softline,
              concat(body),
              dedent(
                singleLineBlock
                  ? ifBreak(concat([line, "end"]), " }")
                  : concat([hardline, "end"])
              )
            ])
          )
        )
      );

      return group(concat(blockHead));
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
      const body = path.map(print, "body");
      const noBraces = n.noBraces;
      let bodyParts = [];
      if (body.length > 0) {
        if (!noBraces) {
          bodyParts.push(line);
        }
        bodyParts.push(group(join(concat([", ", softline]), body)));
        bodyParts = [indent(group(concat(bodyParts)))];
        if (!noBraces) {
          bodyParts.push(line);
        }
      }
      bodyParts = concat(bodyParts);
      const parts = [];
      if (!noBraces) {
        parts.push("{");
      }
      parts.push(bodyParts);
      if (!noBraces) {
        parts.push("}");
      }
      return group(concat(parts));
    }

    case "pair": {
      return group(
        concat([
          group(concat([n.symbol.body, ":", line])),
          group(concat([path.call(print, "value")]))
        ])
      );
    }

    case "sym": {
      return concat([":", path.call(print, "body")]);
    }

    case "const": {
      const ofModule = n.of !== null;
      const parts = [];
      if (ofModule) {
        parts.push(path.call(print, "of"), "::");
      }
      parts.push(n.constant);
      return group(concat(parts));
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

    case "yield": {
      const parts = [];
      parts.push("yield");
      parts.push("(");
      parts.push(concat(path.map(print, "body")));
      parts.push(")");
      return concat(parts);
    }

    case "kwoptarg": {
      const parts = [];
      parts.push(n.name);
      parts.push(":");
      parts.push(line);
      parts.push(concat(path.map(print, "arg")));
      return concat(parts);
    }
    default:
      // eslint-disable-next-line no-console
      console.error("Unknown Ruby Node:", n);
      return n.source;
  }
}

module.exports = genericPrint;
