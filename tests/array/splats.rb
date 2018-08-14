def foo(a = {})
  some_args = a[:foo] || []
  [*some_args].map do |i|
    some_stuff_with i
  end
end

first, *, last = [1, 2, 3, 4, 5]
first, *middle, last = [1, 2, 3, 4]
first, *rest = [1, 2, 3]

a = [1,2]
b = [3,4]
flattened = [*a, *b]
