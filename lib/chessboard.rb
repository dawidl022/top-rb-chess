require_relative '../boards'

class Chessboard
  include Boards

  attr_reader :board, :moves

  FILES = [:a, :b, :c, :d, :e, :f, :g, :h]
  PIECES = {Q: Queen, K: King, R: Rook, B: Bishop, N: Knight}
  PIECE_NAMES = {Q: 'queen', K: 'king', R: 'rook', B: 'bishop', N: 'knight'}

  def self.notation_to_indices(notation)
    invalid_notation_error = ArgumentError.new(
      "Invalid notation for chessboard square: #{notation}"
    )

    if notation.length != 2
      raise invalid_notation_error
    end

    file = FILES.find_index(notation[0].downcase.to_sym)
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

  def self.opponent_colour(colour)
    colour == :white ? :black : :white
  end

  def initialize
    @board = starting_board
    @moves = []
    @moves_since_capture_or_pawn_move = { white: 0, black: 0 }
    @capture_made_in_turn = { white: false, black: false }
    @board_captures = []
  end

  def moves_since_capture_or_pawn_move
    @moves_since_capture_or_pawn_move.min_by { |(k, v)| v }[1]
  end

  def nfold_repetition?(n)
    current_board = @board_captures[-1]

    @board_captures.filter { |board| board == current_board }.length >= n
  end

  # Only check for the obvious dead positions, i.e. king vs king, king & bishop
  # vs king, king & knight vs king
  def dead_position?
    left_pieces = {
      white: find_all_pieces(:white), black: find_all_pieces(:black)
    }

    return true if left_pieces.all? { |(colour, pieces)| pieces.length == 1 }

    left_pieces.each do |colour, pieces|
      return true if pieces.length == 2 && \
        left_pieces[self.class.opponent_colour(colour)].length == 1 && \
        pieces.any? { |piece| piece.is_a?(Bishop) || piece.is_a?(Knight) }
    end

    false
  end

  def move(notation, colour)
    result = evaluate_move(notation, colour)

    record_move(notation, colour) if result.equal?(true)

    if result == :ep
      record_move(notation + ' e.p.', colour)
      result = true
    end

    if result.equal?(true)
      update_move_count(colour)
      capture_board(colour)
    end

    result
  end

  def has_moves?(colour)
    find_all_pieces(colour).each do |piece|
      return true if legal_moves(piece).length >= 1
    end

    false
  end

  def legal_moves(piece)
    if piece.is_a?(Pawn)
      # en passant logic
      valid_moves = piece.valid_moves(@moves[-1] ? @moves[-1][-1] : nil)
    else
      valid_moves = piece.valid_moves
    end

    Set.new(valid_moves.filter do |(move_rank, move_file)|
      cloned_chessboard = Chessboard.new
      cloned_board = clone_board

      cloned_chessboard.instance_variable_set(:@board, cloned_board)
      cloned_chessboard.instance_variable_set(:@moves, cloned_moves)
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

  def checkmate?(colour)
    under_check?(colour) && !has_moves?(colour)
  end

  private

  def evaluate_move(notation, colour)
    return castle_kingside(colour) if notation == '0-0' || notation == 'O-O'
    return castle_queenside(colour) if notation == '0-0-0' || notation == 'O-O-O'
    return promote_pawn(notation, colour) if pawn_promotion_notation?(notation)
    return move_pawn(notation, colour) if pawn_notation?(notation)
    return move_piece(notation, colour) if PIECES.keys.include?(notation[0].to_sym)
    'Invalid move'
  end

  def record_move(notation, colour)
    opponent_colour = colour == :white ? :black : :white
    if under_check?(opponent_colour) && !has_moves?(opponent_colour)
      notation += '#'
    elsif under_check?(opponent_colour)
      notation += '+'
    end

    if colour == :white
      @moves << [notation]
    else
      @moves[-1] << notation
    end
  end

  def move_pawn(notation, colour)
    target = evaluate_target(notation)
    return target if target.is_a?(String)

    rank = target[0]

    if notation.length == 4
      file = FILES.find_index(notation[0].to_sym)
      # TODO extract error messages into constants
      return 'Invalid move' unless file
    else
      file = target[1]
    end

    diff = colour == :white ? -1 : 1

    while rank >= 0 && rank <= 7
      piece = @board[rank][file]
      rank += diff
      next unless piece

      unless piece.is_a?(Pawn) && piece.colour == colour
        return 'Invalid move'
      end

      if legal_moves(piece).include?(target)
        en_passant = notation[1] == 'x' && @board[target[0]][target[1]].nil?
        @board[target[0] + diff][target[1]] = nil if en_passant

        @board[target[0]][target[1]] = piece
        @board[rank - diff][file] = nil

        if notation[1] == 'x'
          piece.first_move_just_made = false
        elsif piece.first_move_just_made.nil?
          piece.first_move_just_made = true
        else
          piece.first_move_just_made = false
        end

        return en_passant ? :ep : true
      else
        return 'Illegal move'
      end
    end

    return 'Invalid move'
  end

  def promote_pawn(notation, colour)
    pawn_rank = colour == :white ? 6 : 1

    if notation.length >= 4
      target = self.class.notation_to_indices(notation[2, 2])
      target_rank, target_file = target
      pawn_file = FILES.find_index(notation[0].to_sym)
    else
      target = self.class.notation_to_indices(notation[0, 2])
      target_rank = target[0]
      pawn_file = target_file = target[1]
    end

    pawn = @board[pawn_rank][pawn_file]

    return 'Illegal move' unless legal_moves(pawn).include?(target)

    if notation.length == 2 || notation.length == 4
      return "Specify a piece to promote to: #{notation}Q, #{notation}R, " \
        "#{notation}B or #{notation}N"
    end

    piece_class = (PIECES.filter { |letter, piece| letter != :K })[notation[-1].to_sym]
    return 'Invalid promotion piece' unless piece_class

    @board[target_rank][target_file] = piece_class.new(colour, @board)
    @board[pawn_rank][pawn_file] = nil

    true
  end

  def move_piece(notation, colour)
    target = evaluate_target(notation)
    return target if target.is_a?(String)
    piece_class = PIECES[notation[0].to_sym]

    notation = notation.gsub('x', '')

    pieces = find_all_pieces(piece_class, colour)
      .filter do |piece|
        if notation.length == 4
          if FILES.include?(notation[1].to_sym)
            next false unless FILES.find_index(notation[1].to_sym) == piece.position[1]
          else
            next false unless notation[1].to_i - 1 == piece.position[0]
          end
        elsif notation.length == 5
          next false unless piece.position == self.class.notation_to_indices(notation[1, 2])
        end

        legal_moves(piece).include?(target)
      end

    if pieces.length > 1
      piece_name = PIECE_NAMES[notation[0].to_sym]
      return "Multiple #{piece_name}s can go to #{notation[-2, 2]}, please disambiguate"
    elsif pieces.length == 0
      return 'Illegal move'
    end

    starting_rank, starting_file = pieces[0].position

    @capture_made_in_turn[colour] = true if @board[target[0]][target[1]]

    @board[target[0]][target[1]] = pieces[0]
    @board[starting_rank][starting_file] = nil

    true
  end

  def castle(colour, rook_start, op)
    rank = colour == :white ? 0 : 7
    square_to_check = [rank, 4.send(op, 1)]
    finishing_square = [rank, 4.send(op, 2)]

    king = @board[rank][4]
    rook = @board[rank][rook_start]
    return 'Invalid move' unless king.is_a?(King) && rook.is_a?(Rook)

    opponent_colour = colour == :white ? :black : :white

    return 'Illegal move' if !legal_moves(king).include?(finishing_square) \
      || under_check?(colour) \
      || square_attacked?(square_to_check, opponent_colour)

    board[rank][finishing_square[1]] = king
    board[rank][square_to_check[1]] = rook
    board[rank][4] = nil
    board[rank][rook_start] = nil

    true
  end

  def castle_kingside(colour)
    castle(colour, 7, :+)
  end

  def castle_queenside(colour)
    castle(colour, 0, :-)
  end

  def evaluate_target(notation)
    begin
      self.class.notation_to_indices(notation[-2, 2])
    rescue ArgumentError => error
      error.message
    end
  end

  def square_attacked?(square, attacker_colour)
    find_all_pieces(attacker_colour).filter do |piece|
      piece.valid_moves.include?(square)
    end.length >= 1
  end

  def find_piece(piece, colour)
    @board.each do |rank|
      rank.each do |square|
        return square if square.is_a?(piece) && square.colour == colour
      end
    end

    nil
  end

  def find_all_pieces(piece = Piece, colour)
    pieces = []

    @board.each do |rank|
      rank.each do |square|
        pieces << square if square.is_a?(piece) && square.colour == colour
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

    clone
  end

  def capture_board(colour)
    castling_rights = { white: [], black: [] }
    en_passant_captures = { white: [], black: [] }

    [:white, :black].each do |colour|
      ['0-0', '0-0-0'].each do |castle_type|
        cloned_chessboard = Chessboard.new
        cloned_board = clone_board

        cloned_chessboard.instance_variable_set(:@board, cloned_board)
        cloned_chessboard.instance_variable_set(:@moves, cloned_moves)

        if move(castle_type, colour).equal?(true)
          castling_rights[colour] << castle_type
        end
      end

      pawns = find_all_pieces(Pawn, colour)
      pawns.each do |pawn|
        legal_moves(pawn).each do |move|
          if move[1] != pawn.position[1] && @board[move[0]][move[1]].nil?
            en_passant_captures[colour] << [pawn.position, move]
          end
        end
      end

    end

    @board_captures << BoardCapture.new(@board.inspect, colour, castling_rights,
                                        en_passant_captures)
  end

  def update_move_count(colour)
    move = @moves[-1][-1]
    if pawn_notation?(move) || pawn_promotion_notation?(move) \
    || @capture_made_in_turn[colour]
      @moves_since_capture_or_pawn_move[colour] = 0
    else
      @moves_since_capture_or_pawn_move[colour] += 1
    end

    @capture_made_in_turn[colour] = false
  end

  def cloned_moves
    Marshal.load(Marshal.dump(@moves))
  end

  def pawn_notation?(notation)
    notation.length == 2 \
    || (lowercase?(notation[0]) && notation[1] == 'x' && notation.length == 4)
  end

  def pawn_promotion_notation?(notation)
    notation =~ /^(?:[a-h]x)?[a-h][18][QRBNK]?$/
  end

  def lowercase?(string)
    string == string.downcase
  end
end

class BoardCapture
  attr_reader :board_inspection, :castling_rights, :colour, :en_passant_captures

  def initialize(board, colour, castling_rights, en_passant_captures)
    @board_inspection = board
    @colour = colour
    @castling_rights = castling_rights
    @en_passant_captures = en_passant_captures
  end

  def ==(other)
    @board_inspection == other.board_inspection && \
    @colour == other.colour && \
    @castling_rights == other.castling_rights && \
    @en_passant_captures == other.en_passant_captures
  end
end
