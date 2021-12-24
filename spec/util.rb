require_relative '../lib/piece'

module Util
  def mute_io(object = subject, methods = %i[puts print])
    methods.each { |method| allow(object).to receive(method) }
  end

  def starting_board
    board = []
    board << [
      Rook.new(:white, board, [0, 0]), Knight.new(:white, board),
      Bishop.new(:white, board), Queen.new(:white, board),
      King.new(:white, board, [0, 4]), Bishop.new(:white, board),
      Knight.new(:white, board), Rook.new(:white, board, [0,7])
    ]
    board << 8.times.map { |index| Pawn.new(:white, board, [1, index]) }
    board << Array.new(8)
    board << Array.new(8)
    board << Array.new(8)
    board << Array.new(8)
    board << 8.times.map { |index| Pawn.new(:black, board, [6, index]) }
    board << [
      Rook.new(:black, board, [7, 0]), Knight.new(:black, board),
      Bishop.new(:black, board), Queen.new(:black, board),
      King.new(:black, board, [7, 4]), Bishop.new(:black, board),
      Knight.new(:black, board), Rook.new(:black, board, [7, 7])
    ]
  end

  def empty_board
    Array.new(8) { Array.new(8) }
  end
end
