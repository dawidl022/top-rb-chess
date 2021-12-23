class Piece
  attr_reader :symbol

  def initialize(colour, board)
    @colour = colour
    @board = board
  end

  def valid_move?(file_index, rank_index)
    valid_moves.include?([file_index, file_rank])
  end
end

class Pawn < Piece
  def initialize(colour, board)
    super
    @symbol = @colour == :white ? '♙' : '♟'
  end

  def valid_moves
  end
end

class Knight < Piece
  def initialize(colour, board)
    super
    @symbol = @colour == :white ? '♘' : '♞'
  end

  def valid_moves
  end
end

class Bishop < Piece
  def initialize(colour, board)
    super
    @symbol = @colour == :white ? '♗' : '♝'
  end

  def valid_moves
  end
end

class Rook < Piece
  def initialize(colour, board)
    super
    @symbol = @colour == :white ? '♖' : '♜'
  end

  def valid_moves
  end
end

class Queen < Piece
  def initialize(colour, board)
    super
    @symbol = @colour == :white ? '♕' : '♛'
  end

  def valid_moves
  end
end

class King < Piece
  def initialize(colour, board)
    super
    @symbol = @colour == :white ? '♔' : '♚'
  end

  def valid_moves
  end
end
