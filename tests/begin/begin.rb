def foo
  begin
    something_dangerous!
  rescue => e
    puts "Oops."
  end
end
