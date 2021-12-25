require_relative '../boards'

class Chessboard
  include Boards

  attr_reader :board

  FILES = [:a, :b, :c, :d, :e, :f, :g, :h]

  def self.notation_to_indices(notation)
    invalid_notation_error = ArgumentError.new(
      "Invalid notation for chessboard square: #{notation}"
    )

    if notation.length != 2
      raise invalid_notation_error
    end

    file = FILES.find_index { |letter| letter == notation[0].downcase.to_sym }
    raise invalid_notation_error if file.nil?

    rank = notation[1].to_i - 1
    raise invalid_notation_error unless rank.between?(0, 7)

    [rank, file]
  end

  def self.indices_to_notation(rank_index, file_index)
    unless rank_index.between?(0, 7) && file_index.between?(0, 7)
      raise ArgumentError,
        "Invalid indices for chessboard square: #{[rank_index, file_index]}"
    end

    rank = (rank_index + 1).to_s
    file = FILES[file_index].to_s

    file + rank
  end

  def initialize
    @board = starting_board
    @moves = []
  end

  def move(notation, colour)
    return move_pawn(notation, colour) if notation.length == 2
  end

  def has_moves?(colour)
  end

  def legal_moves(piece)
    Set.new(piece.valid_moves.filter do |(move_rank, move_file)|
      cloned_chessboard = Chessboard.new
      cloned_board = clone_board

      cloned_chessboard.instance_variable_set(:@board, cloned_board)
      piece_rank, piece_file = piece.position

      # simulate move on cloned chessboard
      cloned_piece = cloned_board[piece_rank][piece_file]
      cloned_board[move_rank][move_file] = cloned_piece
      cloned_board[piece_rank][piece_file] = nil

      !cloned_chessboard.under_check?(piece.colour)
    end)
  end

  def under_check?(colour)
    king_position = find_piece(King, colour).position
    opponent_colour = colour == :white ? :black : :white
    opponents_pieces = find_all_pieces(opponent_colour)

    opponents_pieces.each do |piece|
      return true if piece.valid_moves.include?(king_position)
    end

    false
  end

  private

  def move_pawn(notation, colour)
    begin
      target = self.class.notation_to_indices(notation)
    rescue ArgumentError => error
      return error.message
    end

    rank = target[0]
    file = target[1]

    diff = colour == :white ? -1 : 1

    while rank >= 0 && rank <= 7
      piece = @board[rank][file]
      rank += diff
      next unless piece

      unless piece.is_a?(Pawn) && piece.colour == colour
        return 'Invalid move'
      end

      if legal_moves(piece).include?(target)
        @board[target[0]][file] = piece
        @board[rank - diff][file] = nil
        return true
      else
        return 'Illegal move'
      end
    end

    return 'Invalid move'
  end

  def find_piece(piece, colour)
    @board.each do |rank|
      rank.each do |square|
        return square if square.is_a?(piece) && square.colour == colour
      end
    end

    nil
  end

  def find_all_pieces(colour)
    pieces = []

    @board.each do |rank|
      rank.each do |square|
        pieces << square if square && square.colour == colour
      end
    end

    pieces
  end

  def clone_board
    clone = Array.new(8) { Array.new(8) }

    @board.each_with_index do |rank, rank_index|
      rank.each_with_index do |square, file_index|
        if square
          if square.instance_variable_get(:@starting_square)
            cloned_piece = square.class.new(square.colour, clone,
              square.instance_variable_get(:@starting_square))
          else
            cloned_piece = square.class.new(square.colour, clone)
          end

          cloned_piece.instance_variable_set(:@first_move,
            square.instance_variable_get(:@first_move)
          )

          clone[rank_index][file_index] = cloned_piece
        end
      end
    end
  end
end
