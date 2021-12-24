require_relative 'chessboard'
require_relative 'movables'
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

  def to_s
    "#{symbol}#{Chessboard.indices_to_notation(*position)}"
  end

  protected

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

  def on_chessboard
    proc { |(x, y)| x >= 0 && x <= 7 && y >= 0 && y <= 7 }
  end

  def valid_moves
    current_position = position

    Set.new(
    [[1, 2], [2, 1], [-1, -2], [-2, -1], [1, -2], [2, -1], [-1, 2], [-2, 1]]
    .map do |difference|
      [current_position[0] + difference[0], current_position[1] + difference[1]]
    end.filter(&on_chessboard)  # don't allow knight to leave chessboard
    .filter do |(rank, file)|
      !@board[rank][file] || @board[rank][file].colour != @colour
    end)
  end
end

class Bishop < Piece
  include MovableDiagonal

  def initialize(colour, board)
    super
    @symbol = @colour == :white ? '♗' : '♝'
  end

  def valid_moves
    # TODO include check each move to see if check exists, if so filter it out
    @rank, @file = position

    diagonal_moves
  end
end

class Rook < Piece
  include MovableStraight

  def initialize(colour, board, starting_square = nil)
    super
    @symbol = @colour == :white ? '♖' : '♜'
  end

  def valid_moves
    # TODO include check each move to see if check exists, if so filter it out
    @rank, @file = position

    # castling logic
    first_move? # update when making a move that can possibly return to start

    straight_moves
  end
end

class Queen < Piece
  include MovableStraight
  include MovableDiagonal

  def initialize(colour, board)
    super
    @symbol = @colour == :white ? '♕' : '♛'
  end

  def valid_moves
    # TODO include check each move to see if check exists, if so filter it out
    @rank, @file = position
    moves = Set[]

    moves.merge(straight_moves)
    moves.merge(diagonal_moves)
  end
end

class King < Piece
  def initialize(colour, board, starting_square)
    super
    @symbol = @colour == :white ? '♔' : '♚'
  end

  def valid_moves
    @rank, @file = position
    moves = Set[]

    [-1, 0, 1].each do |rank_diff|
      rank = @rank + rank_diff
      next if rank < 0 || rank > 7

      [-1, 0, 1].each do |file_diff|
        next if rank_diff == 0 && file_diff == 0

        file = @file + file_diff
        next if file < 0 || rank > 7

        if !@board[rank][file] || @board[rank][file].colour != @colour
          moves.add([rank, file])
        end
      end
    end

    moves.merge(castling_moves) if first_move?

    moves
  end

  private

  def castling_moves
    moves = Set[]

    # TODO the board should check if a castling square is under check
    moves.add([@rank, 6]) if castle_kingside?
    moves.add([@rank, 2]) if castle_queenside?

    moves
  end

  def castle_kingside?
    !@board[@rank][5] && !@board[@rank][6] && @board[@rank][7].is_a?(Rook) \
    && @board[@rank][7].first_move?
  end

  def castle_queenside?
    !@board[@rank][3] && !@board[@rank][2] && !@board[@rank][1] \
    && @board[@rank][0].is_a?(Rook) && @board[@rank][0].first_move?
  end
end
