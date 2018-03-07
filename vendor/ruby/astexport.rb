require 'parser/current'
require 'unparser'
require 'json'

class Processor < AST::Processor
  def initialize(node, comments)
    @comment_processor = CommentProcessor.new(comments)
    processed_ast = process(node)
    @results = {
      ast_type: 'File',
      line: 0,
      body: [processed_ast],
      comments: @comment_processor.get_results, source: Unparser.unparse(node)
    }
  end

  def get_results
    @results
  end


  def on_begin(node)
    { ast_type: node.type,
      line: node.children[0].loc.line,
      body: node.children.map { |c|  process(c) },
      source: Unparser.unparse(node) }
  end

  def on_int(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_true(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_false(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_hash(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children.map { |c| process(c) },
      source: Unparser.unparse(node) }
  end

  def on_pair(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children.map { |c| process(c) },
      source: Unparser.unparse(node) }
  end

  def on_sym(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_arg(node)
    { line: node.loc.line,
      ast_type: node.type,
      arg: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_argument(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_back_ref(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_blockarg(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_casgn(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_const(node)
    { line: node.loc.line,
      ast_type: node.type, body: node.children[1],
      source: Unparser.unparse(node) }
  end

  def on_cvar(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_cvasgn(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

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

  def on_defs(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[1],
      source: Unparser.unparse(node) }
  end

  def on_gvar(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_gvasgn(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_ivar(node)
    { line: node,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_ivasgn(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_kwarg(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_kwoptarg(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_kwrestarg(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_lvar(node)
    { line: node.loc.line,
      ast_type: node.type,
      lvar: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_lvasgn(node)
    { line: node.loc.line,
      ast_type: node.type,
      left: node.children[0],
      right: node.children[1..-1].map{ |c| process(c) },
      source: Unparser.unparse(node) }
  end

  def on_case(node)
    { line: node.loc.line,
      ast_type: node.type,
      case: node.children[0],
      body: node.children[1..-1].map{ |c| process(c)},
      source: Unparser.unparse(node)
    }
  end

  def on_nth_ref(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_op_asgn(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_optarg(node)
    { line: node.loc.line,
      ast_type: node.type,
      arg: node.children[0],
      value: node.children[1..-1].map { |c| process(c) },
      source: Unparser.unparse(node) }
  end

  def on_procarg0(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_restarg(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_send(node)
    { line: node.loc.line,
      ast_type: node.type,
      to: process(node.children[0]),
      name: node.children[1],
      body: node.children[2..-1].map { |c| process(c) },
      source: Unparser.unparse(node) }
  end

  def on_self(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node)}
  end

  def on_shadowarg(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_var(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_vasgn(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_class(node)
    { line: node.loc.line,
      ast_type: node.type,
      name: process(node.children[0])[:body],
      body: node.children[1..-1].map { |c| process(c) },
      source: Unparser.unparse(node) }
  end

  def on_str(node)
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children[0],
      source: Unparser.unparse(node) }
  end

  def on_if(node)
    { line: node.loc.line,
      ast_type: node.type,
      condition: process(node.children[0]),
      body: process(node.children[1]),
      else_part: process(node.children[2]),
      source: Unparser.unparse(node) }
  end

  def on_until(node)
    { line: node.loc.line,
      ast_type: node.type,
      condition: process(node.children[0]),
      body: process(node.children[1]),
      else_part: process(node.children[2]),
      source: Unparser.unparse(node) }
  end

  def on_while(node)
    { line: node.loc.line,
      ast_type: node.type,
      condition: process(node.children[0]),
      body: node.children[1..-1].map { |c| process(c) },
      source: Unparser.unparse(node) }
  end

  def on_args(node) # FIXME: Blank args are not handled yet!
    { line: node.loc.line,
      ast_type: node.type,
      body: node.children.map { |c| process(c) },
      source: Unparser.unparse(node) }
  end
end

class CommentProcessor
  def initialize(comments)
    @results = comments.map { |comment| process(comment) }
  end

  def process(comment)
    { ast_type: 'comment', line: comment.loc.line, body: comment.text }
  end

  def get_results
    @results
  end
end

data = ARGV.first
atok, comments = Parser::CurrentRuby.parse_with_comments(data.to_s)
ast = Processor.new(atok, comments)
puts JSON.pretty_generate(ast.get_results)
