yield(file.to_s)

def method_with_yields
  yield
  yield 123
  yield(123)
end
