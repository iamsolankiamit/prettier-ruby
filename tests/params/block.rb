def method_receiving_block(&block)
  block.call
end

def method_passing_block(&block)
  other(&block)
end

def method_passing_block_with_arguments(&block)
  other(1, 2, 3, &block)
end
