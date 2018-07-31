'hello world'
"hello world"

'#{not interpolated}'
"start#{interpolated}end"

'hello\nworld1'
"hello\nworld2"

"hello " \
  "world"

'hello ' \
  'world ' \
  'multiline'

'\n'
"\\n"
"\n"

'"'
"'"

'\\'
"\\"

""
''

"1 + 2 + 3 = #{1 + 2 + 3}"
