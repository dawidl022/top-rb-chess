require 'set'

class Piece
  attr_reader :symbol, :colour

  def initialize(colour, board, starting_square = nil)
    @colour = colour
    @board = board
    @starting_square = starting_square  # nil if not important to gameplay
    @first_move = !!starting_square
  end

  def valid_move?(file_index, rank_index, last_opponent_move = nil)
    # TODO: include last_opponent_move param
    valid_moves(last_opponent_move).include?([file_index, rank_index])
  end

  def position
    @board.each_with_index do |rank, rank_index|
      rank.each_with_index do |square, file_index|
        return [rank_index, file_index] if square.equal?(self)
      end
    end
    nil
  end

  # TODO
  # def to_s
  # end

  private

  def first_move?
    @first_move &&= position == @starting_square
  end
end

class Pawn < Piece
  attr_reader :first_move

  def initialize(colour, board, starting_square)
    super
    @symbol = colour == :white ? '♙' : '♟︎'
  end

  def valid_moves(last_opponent_move = nil)
    # TODO: check for check edge case, filter set by calling checking for check
    # after making each valid move
    @rank, @file = position

    # white pawns ascend ranks, black pawns descend ranks
    @op ||= @colour == :white ? :+ : :-

    moves = Set[]

    moves.add([@rank.send(@op, 1), @file]) if forward_move?
    moves.add([@rank.send(@op, 2), @file]) if two_forward_move?

    if capture_left? || en_passant_left?(last_opponent_move)
      moves.add([@rank.send(@op, 1), @file - 1])
    end
    if capture_right? || en_passant_right?(last_opponent_move)
      moves.add([@rank.send(@op, 1), @file + 1])
    end

    moves
  end

  private

  def forward_move?
    !@board[@rank.send(@op, 1)][@file]
  end

  def two_forward_move?
    first_move? && !@board[@rank.send(@op, 2)][@file] \
    && !@board[@rank.send(@op, 1)][@file]
  end

  def capture_left?
    piece_to_left = @board[@rank.send(@op, 1)][@file - 1]
    piece_to_left && piece_to_left.colour != @colour
  end

  def capture_right?
    piece_to_left = @board[@rank.send(@op, 1)][@file + 1]
    piece_to_left && piece_to_left.colour != @colour
  end

  def en_passant_left?(last_opponent_move)
    piece_to_left = @board[@rank][@file - 1]

    last_opponent_move && piece_to_left && piece_to_left.is_a?(Pawn) \
    && piece_to_left.first_move \
    && Chessboard.notation_to_indices(
      last_opponent_move) == [@rank, @file - 1]
  end

  def en_passant_right?(last_opponent_move)
    piece_to_right = @board[@rank][@file + 1]

    last_opponent_move && piece_to_right && piece_to_right.is_a?(Pawn) \
    && piece_to_right.first_move \
    && Chessboard.notation_to_indices(
      last_opponent_move) == [@rank, @file + 1]
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
  def initialize(colour, board, starting_square = nil)
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
  def initialize(colour, board, starting_square)
    super
    @symbol = @colour == :white ? '♔' : '♚'
  end

  def valid_moves
  end
end
