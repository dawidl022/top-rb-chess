class Player
  attr_reader :colour

  def initialize(colour)
    @colour = colour
  end

  def move
    print "#{@colour.to_s.capitalize}'s move: "
    gets.chomp.strip
  end
end
