require 'ripper'
require 'json'
require 'pp'

class Processor
  attr_reader :json, :sexp, :tokens, :alltokens

  def initialize(code)
    @json = []
    @code = code
    @tokens = Ripper.lex(code)
    @alltokens = Ripper.lex(code)
    @sexp = Ripper.sexp(code)
    @json = visit(@sexp)
    @json[:comments] = []
    (token_line, _),  token = last_token
    last_token_is_END = token == :on___end__
    if last_token_is_END
      @json[:body] << { ast_type: "__END__", content: code.lines[token_line..-1] }
    end
  end

  def last_token
    !@tokens.empty? ? @tokens[-1] : [[nil,nil],nil,nil]
  end

  def current_token
    @tokens.first
  end

  def current_token_type
    _, token_type = current_token
    token_type
  end

  def current_token_value
    _, _, value = current_token
    value
  end

  def next_token
    token = @tokens.shift.first
    token_pos, token_type = token
    # while(token_type === :on_nl || token_type === :on_sp || token_type === :on_ignored_nl || token_type === :on_comment)
    #   token = @tokens.shift.first
    #   token_pos, token_type = token
    # end
    token
  end

  def take_token(token)
    if(current_token_type === token)
      next_token
    else
      # throw "Got token #{token}, expected #{current_token_type}, tokens: #{@tokens}"
    end
  end

  def line?
    current_token_type === :on_nl || current_token_type === :on_ignored_nl
  end

  def next_is_newline?
    next_token = @tokens[1]
    _, next_token_type = next_token
    next_token_type === :on_nl || next_token_type === :on_ignored_nl
  end

  def hardline?
    hardline = line? && next_is_newline?
    while(line?)
      next_token
    end
    hardline
  end

  def remove_space_or_newline
    while(current_token_type === :on_sp || current_token_type === :on_nl || current_token_type === :on_ignored_nl)
      next_token
    end
  end

  def remove_space
    while current_token_type === :on_sp
      next_token
    end
  end

  def remove_token(operator)
    if(operator === current_token_value)
      next_token
    else
      # throw "expected operator #{current_token_value}, but got #{operator}"
    end
  end

  def visit_assign(node)
    type, target, value = node
    target = visit(target)
    remove_space
    remove_token("=")
    value = visit_assign_value(value)
    { ast_type: type, target: target, value: value }
  end

  def visit_opassign(node)
    type, target, op, value = node
    target = visit(target)
    remove_space
    op = visit(op)
    remove_space
    value = visit(value)
    { ast_type: type, target: target, op: op, value: value }
  end

  def visit_assign_value(node)
    remove_space_or_newline
    visit(node)
  end

  def visit_array(node)
    type, body = node
    array_type = "normal"
    remove_space_or_newline
    if current_token_type === :on_qwords_beg
      take_token(:on_qwords_beg)
      array_type = "words"
      body = visit_q_or_i_elements(body)
    elsif current_token_type === :on_qsymbols_beg
      take_token(:on_qsymbols_beg)
      array_type = "symbols"
      body = visit_q_or_i_elements(body)
    else
      body = visit_literal_elements(body)
    end
    { ast_type: type, body: body, newline: line?, hardline: hardline?, array_type: array_type }
  end

  def visit_literal_elements(nodes)
    remove_token("[")
    remove_space_or_newline
    exprs = []
    unless nodes.nil?
      nodes.each do |exp|
        type, _ = exp
        exprs << visit(exp) unless type == :void_stmt
        remove_space_or_newline
        remove_token(",") if current_token_type === :on_comma
        remove_space_or_newline
      end
    end
    remove_token("]")
    exprs
  end

  def visit_q_or_i_elements(nodes)
    remove_space_or_newline
    exprs = []
      nodes.each do |exp|
        type, _ = exp
        exprs << visit(exp) unless type == :void_stmt
        remove_space_or_newline
        take_token(:on_tstring_end) if current_token_type === :on_tstring_end
        remove_space_or_newline
      end
    exprs
  end

  def visit(node)
    case node.first
    when :program
      body = visit_exps(node[1])
      { ast_type: 'program', body: body }
    when :module
      # ["module", const_path_ref, bodystmt]
      type, name, body = node
      { ast_type: type, name: visit(name), body: visit(body) }
    when :sclass
      type, name, body = node
      { ast_type: type, name: visit(name), body: visit(body) }
    when :class
      visit_class(node)
    when :assign
      visit_assign(node)
    when :opassign
      visit_opassign(node)
    when :var_field
      body = visit(node[1])
      { ast_type: 'var_field', body: body }
    when :@gvar
      # [:@gvar, "$foo", [1, 0]]
      type, value = node
      take_token(:on_gvar)
      remove_space
      { ast_type: type, value: value, newline: line?, hardline: hardline? }
    when :@op
      # [:@op, "[]=", [1, 1]]
      type, value = node
      take_token(:on_op)
      remove_space
      { ast_type: type, value: value, newline: line?, hardline: hardline? }
    when :@int
      # [:@int, "123", [1, 0]]
      type, int = node
      remove_token(int)
      { ast_type: type, value: int }
    when :@float
      # [:@float, "123.45", [1, 0]]
      type, float = node
      { ast_type: type, value: float }
    when :@rational
      # [:@rational, "123r", [1, 0]]
      type, rational = node
      { ast_type: type, value: rational }
    when :@imaginary
      # [:@imaginary, "123i", [1, 0]]
      type, imaginary = node
      { ast_type: type, value: imaginary }
    when :@CHAR
      # [:@CHAR, "?a", [1, 0]]
      type, char = node
      { ast_type: type, value: char }
    when :@ident
      take_token(:on_ident)
      { ast_type: '@ident', value: node[1], newline: line?, hardline: hardline? }
    when :@kw
      take_token(:on_kw)
      # [:@kw, "nil", [1, 0]]
      type, value = node
      { ast_type: type, value: value, newline: line?, hardline: hardline? }
    when :@const
      # [:@const, "Constant", [1, 0]]
      type, value = node
      take_token(:on_const)
      { ast_type: type, value: value }
    when :@ivar
      # [:@ivar, "@foo", [1, 0]]
      type, value = node
      take_token(:on_ivar)
      { ast_type: type, value: value }
    when :@cvar
      # [:@cvar, "@@foo", [1, 0]]
      type, value = node
      take_token(:on_cvar)
      { ast_type: type, value: value }
    when :@const
      # [:@const, "FOO", [1, 0]]
      type, value = node
      { ast_type: type, value: value }
    when :const_ref
      # [:const_ref, [:@const, "Foo", [1, 8]]]
      type, value = node
      { ast_type: type, value: visit(value) }
    when :top_const_ref
      # [:top_const_ref, [:@const, ...]]
      remove_space_or_newline
      type, value = node
      { ast_type: type, value: visit(value) }
    when :void_stmt
      # Empty statement
      #
      # [:void_stmt]
      remove_space_or_newline
      { ast_type: "void_stmt" }
    when :dot2
      visit_range(node)
    when :dot3
      visit_range(node)
    when :massign
      visit_multiple_assign(node)
    when :bare_assoc_hash
      # [:bare_assoc_hash, exps]
      type, exps = node
      { ast_type: type, hashes: visit_exps(exps) }
    when :aref
      visit_array_access(node)
    when :call
      visit_call(node)
    when :field
      visit_field(node)
    when :aref_field
      visit_array_field(node)
    when :array
      visit_array(node)
    when :method_add_block
      { ast_type: 'method_add_block', call: visit(node[1]), block: visit(node[2]) }
    when :method_add_arg
      type, name, args = node
      { ast_type: type, name: visit(name), args: args.any? ? visit(args) : [] }
    when :fcall
      { ast_type: 'fcall', name: visit(node[1]) }
    when :do_block
      type, args, body = node
      {
        ast_type: type,
        args: args.nil? ? nil : visit(args),
        body: visit_exps(body)
      }
    when :brace_block
      visit_brace_block(node)
    when :block_var
      args, local_args = visit_block_args(node)
      { ast_type: 'block_var', args: args, local_args: local_args }
    when :var_ref
      { ast_type: 'var_ref', ref: visit(node[1]) }
    when :arg_paren
      type, args = node

      { ast_type: type, args: (args.nil? ? nil : visit(args)) }
    when :args_add_star
      visit_args_add_star(node)
    when :assoc_splat
      type, value = node
      { ast_type: type, value: visit(value) }
    when :args_add_block
      visit_args_add_block(node)
    when :vcall
      { ast_type: 'vcall', value: visit(node[1]) }
    when :defs
      visit_defs(node)
    when :def
      visit_def(node)
    when :params
      visit_params(node)
    when :rest_param
      { ast_type: 'rest_param', param: visit(node[1]) }
    when :blockarg
      type, name = node
    { ast_type: type, param: visit(name) }
    when :const_path_ref
      visit_path(node)
    when :hash
      type, elements = node
      remove_space
      take_token(:on_lbrace)
      remove_space_or_newline
      if elements
        elements = visit_exps(elements[1])
      else
        elements = []
      end
      take_token(:on_rbrace)
      remove_space
      { ast_type: type, elements: elements, newline: line?, hardline: hardline? }
    when :@label
      # [:@label, "foo:", [1, 3]]
      { ast_type: '@label', value: node[1] }
    when :regexp_literal
      type, content, regexp_end = node

      { ast_type: type, content: visit_exps(content), regexp_end: visit(regexp_end) }
    when :@regexp_end
      type, regexp_end = node
      { ast_type: type, regexp_end: regexp_end }
    when :string_literal, :xstring_literal
      visit_string_literal(node)
    when :string_concat
      visit_string_concat(node)
    when :string_content
      # [:string_content, exp]
      _, *exps = node
      visit_exps(exps)
    when :string_embexpr
      # [:string_content, exps]
      type, exps = node

      take_token(:on_embexpr_beg)
      exps = visit_exps(exps)
      take_token(:on_embexpr_end)
      { ast_type: type, interpolations: exps }
    when :symbol_literal
      visit_symbol_literal(node)
    when :symbol
      visit_symbol(node)
    when :dyna_symbol
      visit_quoted_symbol_literal(node)
    when :bodystmt
      visit_bodystmt(node)
    when :ifop
      visit_ternary_if(node)
    when :if_mod
      visit_if_mod(node)
    when :until_mod
      visit_until_mod(node)
    when :while
      visit_while(node)
    when :while_mod
      visit_while_mod(node)
    when :command
      visit_command(node)
    when :command_call
      # Note that the seperator can either be :"." or :"&."
      type, receiver, separator, name, args = node

      { ast_type: type, receiver: visit(receiver), separator: separator, name: visit(name), args: visit(args) }
    when :assoc_new
      visit_hash_key_value(node)
    when :until
      visit_until(node)
    when :unless_mod
      visit_unless_mod(node)
    when :unless
      visit_unless(node)
    when :if
      visit_if(node)
    when :elsif
      visit_if(node)
    when :return, :return0
      visit_return(node)
    when :retry
      { ast_type: :retry }
    when :begin
      visit_begin(node)
    when :rescue
      visit_rescue(node)
    when :rescue_mod
      type, body, cond  = node

      { ast_type: type, body: visit(body), cond: visit(cond) }
    when :ensure
      type, body = node
      { ast_type: type, bodystmt: visit_exps(body) }
    when :@tstring_content
      type, content = node
      take_token(:on_tstring_content)
      if current_token_type == :on_words_sep
        take_token(:on_words_sep)
        content = content.strip
      end

      { ast_type: type, content: content }
    when :else
      type, else_body = node
      { ast_type: type, else_body: visit_exps(else_body) }
    when :binary
      visit_binary(node)
    when :unary
      visit_unary(node)
    when :yield0
      { ast_type: :yield0 }
    when :yield
      visit_yield(node)
    when :paren
      visit_paren(node)
    when :mlhs_paren
      visit_paren(node)
    when :mlhs_add_star
      type, left, star, right = node

      {
        ast_type: type,
        left: visit_exps(left),
        star: visit(star),
        right: right.nil? ? nil : visit_exps(right)
      }
    when :lambda
      visit_lambda(node)
    when :case
      visit_case(node)
    when :when
      visit_when(node)
    when :BEGIN
      visit_BEGIN(node)
    when :END
      visit_END(node)
    when :alias, :var_alias
      visit_alias(node)
    when :zsuper
      # [:zsuper]
      type, _ = node
      { ast_type: type }
    when :super
      visit_super(node)
    when :defined
      visit_defined(node)
    when :mrhs_new_from_args
      visit_mrhs_new_from_args(node)
    when :mrhs_add_star
      type, left, right = node
      { ast_type: type, left: left.any? ? visit(left) : nil, right: visit(right) }
    when :next
      visit_next(node)
    when :undef
      visit_undef(node)
    when :break
      visit_break(node)
    else
      { ast_type: node.first, error: "Unhandled node within #{File.basename(__FILE__)}: #{node.first}" }
    end
  end

  def visit_break(node)
    # [:break, exp]
    type, exp = node
    exp = exp && !exp.empty? ? visit(exp) : nil
    { ast_type: type, exp: exp }
  end

  def visit_undef(node)
    # [:undef, exps]
    type, exps = node
    exps = exps && !exps.empty? ? visit_exps(exps) : nil
    { ast_type: type, exps: exps }
  end

  def visit_next(node)
    # [:next, args]
    type, args = node
    args = args && !args.empty? ? visit(args) : nil
    { ast_type: type, args: args }
  end

  def visit_defined(node)
    # [:defined, exp]
    type, exp = node
    { ast_type: type, exp: visit(exp) }
  end

  def visit_super(node)
    # [:super, args]
    type, args = node
    { ast_type: type, args: visit(args)}
  end

  def visit_alias(node)
    # [:alias, from, to]
    type, from, to = node
    take_token(:on_kw)
    remove_space
    from = visit(from)
    remove_space
    to = visit(to)
    { ast_type: type, from: from, to: to }
  end

  def visit_BEGIN(node)
    # begin
    #   body
    # end
    #
    # [:BEGIN, [:bodystmt, body, rescue_body, else_body, ensure_body]]
    type, bodystmt = node
    { ast_type: type, bodystmt: visit_exps(bodystmt)}
  end

  def visit_END(node)
    # end
    #   body
    # end
    #
    # [:END, [:bodystmt, body, rescue_body, else_body, ensure_body]]
    type, bodystmt = node
    { ast_type: type, bodystmt: visit_exps(bodystmt)}
  end

  def visit_begin(node)
    # begin
    #   body
    # end
    #
    # [:begin, [:bodystmt, body, rescue_body, else_body, ensure_body]]
    type, bodystmt = node
    { ast_type: type, bodystmt: visit_bodystmt(bodystmt)}
  end

  def visit_rescue(node)
    type, types, name, body, additional_rescues = node

    {
      ast_type: type,
      types: types.nil? ? nil : visit_exps(to_ary(types)),
      name: name.nil? ? nil : visit(name),
      bodystmt: body.nil? ? nil : visit_exps(body),
      additional_rescues: additional_rescues.nil? ? nil : visit(additional_rescues)
    }
  end

  def to_ary(node = [])
    node[0].is_a?(Symbol) ? [node] : node
  end

  def visit_mrhs_new_from_args(node)
    # Multiple exception types
    # [:mrhs_new_from_args, exps, final_exp]
    type, exps, final_exp = node

    if final_exp
      exps = visit_exps(exps)
      final_exp = visit(final_exp)
    else
      exps = visit_exps(to_ary(exps))
    end
    { ast_type: type, exps: exps, final_exp: final_exp }
  end

  def visit_lambda(node)
    # [:lambda, [:params, nil, nil, nil, nil, nil, nil, nil], [[:void_stmt]]]
    type, params, body = node
    { ast_type: type, params: visit(params), body: visit_exps(body) }
  end

  def visit_paren(node)
    # ( exps )
    # [:paren, exps]
    type, exps = node
    if exps
      exps = visit_exps(to_ary(exps))
    end
    { ast_type: type, exps: exps }
  end

  def visit_yield(node)
    # [:yield, exp]
    type, exp = node
    { ast_type: type, exp: visit(exp) }
  end

  def visit_multiple_assign(node)
    # [:massign, lefts, right]
    type, lefts, right = node
    { ast_type: type, lefts: visit_exps(to_ary(lefts)), right: visit(right) }
  end

  def visit_brace_block(node)
    # [:brace_block, args, body]
    type, args, body = node
    {
      ast_type: type,
      args: args.nil? ? nil : visit(args),
      body: visit_exps(body)
    }
  end

  def visit_range(node)
    # [:dot2, left, right]
    # [:dot3, left, right]
    type, left, right = node
    { ast_type: type, left: visit(left), right: visit(right) }
  end

  def visit_array_access(node)
    # exp[arg1, ..., argN]
    #
    # [:aref, name, args]
    type, name, args = node
    { ast_type: type, name: visit(name), args: visit(args) }
  end

  def visit_path(node)
    # Foo::Bar
    #
    # [:const_path_ref,
    #   [:var_ref, [:@const, "Foo", [1, 0]]],
    #   [:@const, "Bar", [1, 5]]]
    parts = node[1..-1]
    { ast_type: "const_path_ref", parts: visit_exps(parts) }
  end

  def visit_call(node)
    # Unparser.unparse(node)
    # [:call, obj, :".", name]
    # or
    # Unparser&.unparse(code)
    # [:call, obj, :"&.", name]
    type, obj, separator, name = node
    { ast_type: type, obj: visit(obj), separator: separator, name: visit(name) }
  end

  def visit_array_field(node)
    # foo[arg1, arg2, ..]
    # [:aref_field, name, args]
    type, name, args = node
    { ast_type: type, name: visit(name), args: visit(args) }
  end

  def visit_field(node)
    # foo.bar
    # [:field, receiver, :".", name]
    # foo&.bar
    # [:field, receiver, :"&.", name]
    type, receiver, separator, name = node
    { ast_type: type, receiver: visit(receiver), separator: separator, name: visit(name) }
  end

  def visit_defs(node)
    # [:defs,
    # [:vcall, [:@ident, "foo", [1, 5]]],
    # [:@period, ".", [1, 8]],
    # [:@ident, "bar", [1, 9]],
    # [:params, nil, nil, nil, nil, nil, nil, nil],
    # [:bodystmt, [[:void_stmt]], nil, nil, nil]]
    type, receiver, period, name, params, body = node
    if params[0] == :paren
      params = visit(params[1])
    else
      params = visit(params)
    end
    { ast_type: type, receiver: visit(receiver), name: visit(name), params: params, bodystmt: visit(body) }
  end

  def visit_def(node)
    type, name, params, body = node
    take_token(:on_kw)
    if params[0] == :paren
      params = visit(params[1])
    else
      remove_space
      params = visit(params)
    end
    remove_space_or_newline
    { ast_type: type, name: visit(name), params: params, bodystmt: visit(body) }
  end

  def visit_return(node)
    # [:return, exp]
    type, exp = node
    { ast_type: type, value: exp ? visit(exp) : nil }
  end

  def visit_hash_key_value(node)
    # key => value
    # [:assoc_new, key, value]
    type, key, value = node

    symbol = key[0] == :symbol_literal  || key[0] == :dyna_symbol
    arrow = symbol || !(key[0] == :@label)
    key = visit(key)
    remove_space
    if arrow
      remove_token("=>")
      remove_space
    end
    value = visit(value)
    take_token(:on_comma) if current_token_type == :on_comma
    remove_space_or_newline
    { ast_type: type, key: key, value: value, has_arrow: arrow }
  end

  def visit_command(node)
    # puts arg1, ..., argN
    #
    # [:command, name, args]
    type, name, args = node
    name = visit(name)
    remove_space
    args = args[0] === :args_add_block ? visit(args) : visit_exps(args)
    { ast_type: type, name: name, args: args }
  end

  def visit_bodystmt(node)
    # [:bodystmt, body, rescue_body, else_body, ensure_body]
    type, body, rescue_body, else_body, ensure_body = node

    body = visit_exps(body) if body
    rescue_body = visit(rescue_body) if rescue_body
    else_body = visit(else_body) if else_body
    ensure_body = visit(ensure_body) if ensure_body
    take_token(:on_kw)
    remove_space_or_newline
    { ast_type: type, body: body, rescue_body: rescue_body, else_body: else_body, ensure_body: ensure_body }
  end

  def visit_exps(node)
    exprs = []
      node.each do |exp|
        type, _ = exp
        exprs << visit(exp) unless type == :void_stmt
      end
    exprs
  end

  def isEmpty?(args)
    a, b, c, d, e, f, g, h = args
    !a && !b && !c && !d && !e && !f && !g && !h
  end


  def visit_args_add_block(node)
    type, args, opt_block_arg = node
    is_args_add_star = args.any? && args[0] == :args_add_star

    {
      ast_type: type,
      args_body: is_args_add_star ? visit(args) : visit_exps(args),
      opt_block_arg: opt_block_arg ? visit(opt_block_arg) : false
    }
  end

  def visit_args_add_star(node)
    type, args, value, post_args = node
    is_args_add_star = args.any? && args[0] == :args_add_star

    {
      ast_type: type,
      args_body: is_args_add_star ? visit(args) : visit_exps(args),
      value: visit(value),
      post_args: post_args ? visit(post_args) : false
    }
  end

  def visit_block_args(node)
    _, node_params, node_local_params = node
    params = []
    unless isEmpty?(node_params)
      params = visit_exps(node_params[1])
    end
    local_params = visit(node_local_params[1]) unless isEmpty?(node_local_params)
    [params, local_params]
  end

  def visit_params(node)
    # (def params)
    #
    # [:params, pre_rest_params, args_with_default, rest_param, post_rest_params, label_params, double_star_param, blockarg]
    type,
    pre_rest_params,
    args_with_default,
    rest_param,
    post_rest_params,
    label_params,
    double_star_param,
    blockarg = node
    remove_space
    pre_rest_params = visit_exps(pre_rest_params) if pre_rest_params
    args_with_default = visit_args_with_default(args_with_default) if args_with_default
    rest_param = visit(rest_param[1]) if rest_param
    post_rest_params = visit_exps(post_rest_params) if post_rest_params
    label_params = visit_label_params(label_params) if label_params
    double_star_param = visit(double_star_param) if double_star_param
    blockarg = visit(blockarg) if blockarg
    {
      ast_type: type,
      pre_rest_params: pre_rest_params,
      args_with_default: args_with_default,
      rest_param: rest_param,
      post_rest_params: post_rest_params,
      label_params: label_params,
      double_star_param: double_star_param,
      blockarg: blockarg
    }
  end

  def visit_label_params(nodes)
    # [[[ :@label, name ], [key, value]]]
    params = []
    nodes.each do |node|
      label, default = node
      label = visit(label)
      default = visit(default) if default
      params << { ast_type: "label_param", label: label, default: default }
    end
    params
  end

  def visit_args_with_default(nodes)
    args = []
    nodes.each do |node|
      arg, default = node
      arg = visit(arg)
      default = visit(default)
      args << { ast_type: "args_with_default", arg: arg, default: default }
    end
    args
  end


  def visit_symbol_literal(node)
    # :foo
    #
    # [:symbol_literal, [:symbol, [:@ident, "foo", [1, 1]]]]
    #
    # A symbol literal not necessarily begins with `:`.
    # For example, an `alias foo bar` will treat `foo`
    # a as symbol_literal but without a `:symbol` child.
    type, symb = node
    symb = visit(symb)
    { ast_type: type, body: symb }
  end

  def visit_symbol(node)
    # :foo
    #
    # [:symbol, [:@ident, "foo", [1, 1]]]
    take_token(:on_symbeg)
    { ast_type: node[0], symbol: visit(node[1]) }
  end

  def visit_quoted_symbol_literal(node)
    # :"foo"
    #
    # [:dyna_symbol, exps]
    type, exps = node

    if current_token_type == :on_tstring_beg
      take_token(:on_tstring_beg)
      exps = visit(exps)
      take_token(:on_label_end)
    else
      take_token(:on_symbeg)
      exps = visit_exps(exps)
      take_token(:on_tstring_end)
    end
    {ast_type: type, value: exps}
  end

  def visit_if_mod(node)
    # then if cond
    #
    # [:if_mod, cond, body]
    type, cond, body = node

    { ast_type: type, then_body: visit(body), cond: visit(cond) }
  end

  def visit_while_mod(node)
    # then while cond
    #
    # [:while_mod, cond, body]
    type, cond, body = node

    { ast_type: type, then_body: visit(body), cond: visit(cond) }
  end

  def visit_until_mod(node)
    # then until cond
    #
    # [:until_mod, cond, body]
    type, cond, body = node

    { ast_type: type, then_body: visit(body), cond: visit(cond) }
  end

  def visit_unless_mod(node)
    # then unless cond
    #
    # [:unless_mod, cond, body]
    type, cond, body = node

    { ast_type: type, then_body: visit(body), cond: visit(cond) }
  end

  def visit_ternary_if(node)
    # cond ? then : else
    #
    # [:ifop, cond, then_body, else_body]
    type, cond, then_body, else_body = node

    { ast_type: type, cond: visit(cond), then_body: visit(then_body), else_body: visit(else_body)}
  end

  def visit_if(node)
    # if cond
    #   then_body
    # else
    #   else_body
    # end
    #
    # [:if, cond, then, else]
    type, cond, then_body, else_body = node

    {
      ast_type: type,
      cond: visit(cond),
      then_body: then_body ? visit_exps(then_body) : nil,
      else_body: else_body ? visit(else_body) : nil
    }
  end

  def visit_until(node)
    # until cond
    #   then_body
    # else
    #   else_body
    # end
    #
    # [:until, cond, then, else]
    type, cond, then_body, else_body = node

    {
      ast_type: type,
      cond: visit(cond),
      then_body: then_body ? visit_exps(then_body) : nil,
      else_body: else_body ? visit(else_body) : nil
    }
  end

  def visit_unless(node)
    # unless cond
    #   then_body
    # else
    #   else_body
    # end
    #
    # [:unless, cond, then, else]
    type, cond, then_body, else_body = node

    {
      ast_type: type,
      cond: visit(cond),
      then_body: then_body ? visit_exps(then_body) : nil,
      else_body: else_body ? visit(else_body) : nil
    }
  end

  def visit_while(node)
    # while cond
    #   then_body
    # end
    #
    # [:while, cond, then]
    type, cond, then_body = node

    {
      ast_type: type,
      cond: visit(cond),
      then_body: then_body ? visit_exps(then_body) : nil,
    }
  end

  def visit_string_literal(node)
    # [:string_literal, [:string_content, exps]]
    type, string_content = node
    remove_space_or_newline
    is_single_quote = current_token_value === "'"
    isHereDoc = current_token_type == :on_heredoc_beg
    hereDocType = current_token_value if isHereDoc
    take_token(:on_heredoc_beg) if isHereDoc
    here_doc_newline = line? if isHereDoc
    remove_space_or_newline
    take_token(:on_tstring_beg) if type == :string_literal
    take_token(:on_backtick) if type == :xstring_literal
    string_content = type == :xstring_literal ? visit_exps(string_content) : visit(string_content)
    hereDocEnd = current_token_value if isHereDoc
    take_token(:on_tstring_end)
    remove_space
    json = { ast_type: type, string_content: string_content, is_single_quote: is_single_quote, newline: line?, hardline: hardline? }
    if(isHereDoc)
      json[:is_here_doc] = true
      json[:here_doc_newline] = here_doc_newline
      json[:here_doc_type] = hereDocType
      json[:here_doc_end] = hereDocEnd
    end
    json
  end

  def visit_string_concat(node)
    type, left, right = node
    { ast_type: type, left: visit(left), right: visit(right) }
  end

  def visit_unary(node)
    # [:unary, op, exp]
    type, op, exp = node
    { ast_type: type, operator: op, exp: visit(exp) }
  end

  def visit_binary(node)
    # [:binary, left, op, right]
    type, left, op, right = node
    { ast_type: type, left: visit(left), operator: op, right: visit(right) }
  end

  def visit_class(node)
    # [:class, name, superclass, [:bodystmt, body, nil, nil, nil] ]
    type, name, superclass, body = node

    {
      ast_type: type,
      name: visit(name),
      superclass: superclass ? visit(superclass) : nil,
      body: body ? visit(body) : nil
    }
  end

  def visit_case(node)
    # [:case, cond, case_when]
    type, cond, case_when = node

    cond = cond ? visit(cond) : nil;

    case_when = visit case_when
    { ast_type: type, cond: cond, case_when: case_when }
  end

  def visit_when(node)
    # [:when, conds, body, next_exp]
    type, conds, body, next_exp = node
    { ast_type: type, conds: visit_exps(conds), body: visit_exps(body), next_exp: visit(next_exp) }
  end
end

data = ARGV.first
code = data.to_s
processor = Processor.new(code)

result = {}
result[:alltokens] = processor.alltokens.pretty_inspect if ENV['DEBUG']
result[:tokens] = processor.tokens.pretty_inspect if ENV['DEBUG']
result[:sexp] = processor.sexp.pretty_inspect if ENV['DEBUG']
result[:json] = processor.json

puts JSON.pretty_generate(result, max_nesting: false)
