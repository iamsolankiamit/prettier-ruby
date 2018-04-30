a = {
  line: node.loc.line,
  ast_type: node.type,
  body: node.children.map { |c| process(c) },
  source: Unparser.unparse(node)
}
a
