func { }
func {

}
func { puts "hello world" }
func { |x| puts x }
func { |x, y| puts x, y }
func { |x, y, z| puts x, y, z }
func { |x, y, z|
  puts x, y, z
}

func do; end
func do

end
func do
  puts "hello world"
end

func do |x|
  puts x
end

func do |x, y|
  puts x, y
end

func do |x, y, z|
  puts x, y, z
end

def index
  @people = Person.find(:all)

  respond_to do |format|
    format.html
    format.js
    format.xml do
      render :xml => @people.to_xml
    end
  end
end
