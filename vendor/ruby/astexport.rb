require 'parser/current'
require 'unparser'
require 'json'

class Processor < AST::Processor
  def initialize
    @results
  end

  def get_results
    @results
  end

  def on_class(node)
    { line: node.loc.line, 
      type: node.type, body: node.children.map { |c| process(c) }, 
      raw: Unparser.unparse(node) }
  end

  def on_const(node)
    { line: node.loc.line, 
      type: node.type, body: node.children[1], 
      raw: Unparser.unparse(node) }
  end

  def on_lvasgn(node)
    { line: node.loc.line, 
      type: node.type, body: node.children[0], 
      raw: Unparser.unparse(node) }
  end

  def on_def(node)
    { line: node.loc.line, 
      type: node.type, 
      name: node.children[0], 
      body: node.children[1..-1].map { |c| process(c) }, 
      raw: Unparser.unparse(node) }
  end

  def on_defs(node)
    { line: node.loc.line, 
      type: node.type, 
      body: node.children[1], 
      raw: Unparser.unparse(node) }
  end

  def on_str(node)
    { line: node.loc.line, 
      type: node.type, 
      body: node.children[0], 
      raw: Unparser.unparse(node) }
  end

  def on_args(node)
    { line: node, 
      type: node.type, 
      body: node.children[0], 
      raw: Unparser.unparse(node) }
  end

  def on_ivar(node)
    { line: node, 
      type: node.type, 
      body: node.children[0], 
      raw: Unparser.unparse(node) }
  end

  def on_lvar(node)
    { line: node.loc.line, 
      type: node.type, 
      body: node.children[0], 
      raw: Unparser.unparse(node) }
  end

  def on_send(node)
    { line: node.loc.line, 
      type: node.type, 
      name: node.children[1], 
      body: node.children[2..-1].map { |c| process(c) }, 
      raw: Unparser.unparse(node)  }
  end

  def on_begin(node)
    d = { type: node.type, 
          line: node.children[0].loc.line, 
          body: node.children.map { |c|  process(c) }, 
          raw: Unparser.unparse(node) }
    @results = d
  end

end

data = ARGV.first
atok = Parser::CurrentRuby.parse(File.read(data))
ast = Processor.new
after_ast_process = ast.process(atok)
puts JSON.pretty_generate(ast.get_results)



