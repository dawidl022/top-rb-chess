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
        puts "Checkmate! " \
          "#{Chessboard.opponent_colour(player.colour).to_s.capitalize} wins."
        break
      end

      if @chessboard.under_check?(player.colour)
        puts 'Check!'
      end

      unless @chessboard.has_moves?(player.colour)
        puts 'Stalemate.'
        break
      end

      if @chessboard.dead_position?
        puts 'Draw. Dead position.'
        break
      end

      if @chessboard.moves_since_capture_or_pawn_move >= 75
        puts 'Draw. 75 moves passed since last capture or pawn move.'
        break
      end

      if @chessboard.nfold_repetition?(5)
        puts 'Draw. Fivefold repetition.'
        break
      end

      loop do
        input = player.move
        case input
        when 'resign' then return resign(player.colour)
        when 'draw' then break offer_draw(player, player.colour)
        when 'save' then raise NotImplementedError
        when 'quit' then return
        end

        break if (result = @chessboard.move(input, player.colour)).equal?(true)
        clear_screen(scroll: SCROLL)
        print_board
        put_blank_line
        puts result
      end
    end
  end

  private

  def resign(colour)
    puts "#{colour.to_s.capitalize} resigns."
  end

  def offer_draw(player, colour)
    if @chessboard.moves_since_capture_or_pawn_move >= 50
      puts 'Draw. 50 or more moves passed since last capture or pawn move.'
      exit
    elsif @chessboard.nfold_repetition?(3)
      puts 'Draw. Threefold repetition.'
      exit
    else
      puts 'Make your move to claim/offer a draw'
      until (result = @chessboard.move(player.move, player.colour)).equal?(true)
        clear_screen(scroll: SCROLL)
        print_board
        put_blank_line
        puts result
      end

      clear_screen(scroll: SCROLL)
      print_board
      put_blank_line

      if @chessboard.moves_since_capture_or_pawn_move >= 50
        puts 'Draw. 50 or more moves passed since last capture or pawn move.'
        exit
      elsif @chessboard.nfold_repetition?(3)
        puts 'Draw. Threefold repetition.'
        exit
      end

      print "(#{Chessboard.opponent_colour(colour).to_s.capitalize}) " \
        "Type in 'draw' to agree to the offered draw: "
      if gets.chomp.downcase == 'draw'
        puts 'Draw by agreement'
        exit
      end
    end
  end

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
