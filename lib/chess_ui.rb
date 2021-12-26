require_relative 'player'
require_relative 'chessboard'
require_relative 'util'

class ChessUI
  HINTS = false
  SCROLL = false

  def initialize
    @white = Player.new(:white)
    @black = Player.new(:black)
    @chessboard = Chessboard.new
  end

  def play_game
    whites_move = true
    loop do
      clear_screen(scroll: SCROLL)
      print_board
      put_blank_line

      player = whites_move ? @white : @black
      whites_move = !whites_move

      if @chessboard.checkmate?(player.colour)
        puts "Checkmate!"
        break
      end

      if @chessboard.under_check?(player.colour)
        puts "Check!"
      end

      until (result = @chessboard.move(player.move, player.colour)).equal?(true)
        clear_screen(scroll: SCROLL)
        print_board
        put_blank_line
        puts result
      end
    end
  end

  private

  def print_board
    board_string = HINTS ? "8 " : ""
    white_square = true

    notation_rows = format_notation(HINTS ? 20 : 18)

    @chessboard.board.reverse.each_with_index do |rank, index|
      board_string += "\e[30m"
      board_string += rank.map do |piece|
        colour = white_square ? "\e[47m" : "\e[48;5;35m"
        white_square = !white_square

        colour + (piece ? piece.to_s[0] : " ")
      end.join(" ")
      white_square = !white_square
      board_string += " \e[0m"
      board_string += notation_rows[index].to_s

      unless index == 7
        board_string += "\n"
        board_string += "#{7 - index} " if HINTS
      end
    end

    puts board_string
    print "\e[0m  "

    if HINTS
      Chessboard::FILES.each { |letter| print letter.to_s  + " " }
      put_blank_line
    end
  end

  def format_notation(padding)
    Array.new(8)
  end
end
