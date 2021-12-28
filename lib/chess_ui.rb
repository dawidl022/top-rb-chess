require_relative 'player'
require_relative 'chessboard'
require_relative 'util'

class ChessUI
  def initialize(scroll: false, labels: false, pgn: nil, replay: false)
    @white = Player.new(:white)
    @black = Player.new(:black)
    @labels = labels
    @scroll = scroll
    if pgn && replay
      @chessboard = replay_game(pgn, replay)
    else
      @chessboard = pgn ? Chessboard.from_pgn(pgn) : Chessboard.new
    end
  end

  def play_game
    whites_move = !@chessboard.moves[-1] || @chessboard.moves[-1].length == 2
    loop do
      clear_screen(scroll: @scroll)
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
        when /save/ then save_game(input); next
        when 'quit' then return
        end

        break if (result = @chessboard.move(input, player.colour)).equal?(true)
        clear_screen(scroll: @scroll)
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
        clear_screen(scroll: @scroll)
        print_board
        put_blank_line
        puts result
      end

      clear_screen(scroll: @scroll)
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

  def print_board(chessboard = @chessboard)
    board_string = @labels ? "8 " : ""
    white_square = true

    notation_rows = format_notation(@labels ? 20 : 18, chessboard)

    chessboard.board.reverse.each_with_index do |rank, index|
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
        board_string += "#{7 - index} " if @labels
      end
    end

    puts board_string
    print "\e[0m  "

    row_index = 8

    if @labels
      Chessboard::FILES.each { |letter| print letter.to_s  + " " }
      print notation_rows[row_index].to_s
      row_index += 1
      put_blank_line
    end

    if notation_rows[row_index...notation_rows.length]
      notation_rows[row_index...notation_rows.length].each do |row|
        print " " * (@labels ? 18 : 16) + row + "\n"
      end
    end
  end

  def format_notation(padding, chessboard = @chessboard)
    columns = (`tput cols`.to_i - padding) / 21
    number_of_rows = [8, (chessboard.moves.length / columns.to_f).ceil].max
    rows = Array.new(number_of_rows) { String.new }

    chessboard.moves.each_with_index do |move, index|
      rows[index % number_of_rows] +=
        "#{(index + 1).to_s.rjust(3)}. #{move[0].to_s.ljust(7)} "\
        "#{move[1].to_s.ljust(7)} "
    end

    # clear redundant trailing whitespace
    rows.each(&:rstrip!)
  end

  def save_game(input)
    input = input.split(' ')
    if input.length  < 2
      return puts 'Please specify a file path to save the game to'
    end

    filename = input[1]

    begin
      File.write(filename, @chessboard.to_pgn + " \n")
    rescue IOError
      puts "Unable to save game to '#{filename}', please try again."
    else
      puts "Game saved successfully to '#{filename}'"
    end
  end

  def replay_game(pgn, delay)
    board = Chessboard.new
    moves = Chessboard.parse_pgn(pgn)


    moves.each do |move|
      move.each_with_index do |sub_move, index|
        unless board.move(sub_move, index == 0 ? :white : :black).equal?(true)
          raise ArgumentError, 'Incompatible PGN notation supplied'
        end
        clear_screen(scroll: @scroll)
        print_board(board)
        put_blank_line
        sleep delay
      end
    end

    board
  end
end
