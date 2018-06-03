a = true ? 1 : 2
a = true ? true ? 1 : 2 : 3
a = (very_long_expression? || other_very_long_expression?) ? 1 : 2
a = (very_long_expression? || other_very_long_expression?) ? very_long_method_call! : other_very_long_method_call!
a = (very_long_expression? || other_very_long_expression?) ? (very_long_expression? || other_very_long_expression?) ? very_long_method_call! : other_very_long_method_call! : other_very_long_method_call!
