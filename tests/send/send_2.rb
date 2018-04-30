def on_def(node)
  childrens = node.children[1..-1].map { |c| process(c) }
  args = childrens.select { |c| c[:ast_type] == :args }
  body = childrens.reject { |c| c[:ast_type] == :args }
  { line: node.loc.line,
    ast_type: node.type,
    name: node.children[0],
    args: args[0],
    body: body,
    source: Unparser.unparse(node) }
end
