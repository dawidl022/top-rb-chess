require_relative '../lib/piece'
require_relative '../boards'
require 'set'

RSpec.describe Piece do
  include Boards

  describe '#position' do
    context 'white pawn in starting position' do
      let(:pawn) { starting_board[1][0] }

      it 'returns the coordinates (matrix indices) where the piece lies' do
        expect(pawn.position).to eq([1, 0])
      end
    end

    context 'black bishop in starting position' do
      let(:bishop) { starting_board[7][5] }

      it 'returns the coordinates (matrix indices) where the piece lies' do
        expect(bishop.position).to eq([7, 5])
      end
    end

    context 'white pawn after some moves' do
      it 'returns the coordinates (matrix indices) where the piece lies' do
        board = starting_board
        board[3][4] = board[1][4]
        pawn = board[1][4]
        board[1][4] = nil

        expect(pawn.position).to eq([3, 4])
      end
    end
  end

  describe '#symbol' do
    context 'white pawn in starting position' do
      let(:pawn) { starting_board[1][0] }

      it 'returns the "♙" symbol' do
        expect(pawn.symbol).to eq('♙')
      end
    end

    context 'black bishop in starting position' do
      let(:bishop) { starting_board[7][5] }

      it 'returns the "♝" symbol' do
        expect(bishop.symbol).to eq('♝')
      end
    end

    context 'white pawn after some moves' do
      it 'returns the "♙" symbol' do
        board = starting_board
        board[3][4] = board[1][4]
        pawn = board[1][4]
        board[1][4] = nil

        expect(pawn.symbol).to eq('♙')
      end
    end
  end

  describe "#to_s" do
    let(:board) { empty_board }
    describe "returns the unicode char along with chess notation position" do
      it 'for a white knight on c4' do
        knight = Knight.new(:white, board)
        board[3][2] = knight

        expect(knight.to_s).to eq('♘c4')
      end

      it 'for a black rook on a7' do
        rook = Rook.new(:black, board, [7, 7])
        board[6][0] = rook

        expect(rook.to_s).to eq('♜a7')
      end
    end

    it "#inspect is an alias" do
      rook = Rook.new(:black, board, [7, 7])
      board[6][0] = rook

      expect(rook.inspect).to eq(rook.to_s)
    end
  end
end

RSpec.describe Pawn do
  include Boards

  describe '#valid_moves' do
    let(:board) { starting_board }

    context 'white pawn' do
      context 'first move in the game' do
        it 'shows two squares directly ahead of it' do
          pawn = starting_board[1][4]
          expect(pawn.valid_moves).to eq(Set[[2, 4], [3, 4]])
        end

        it 'shows two squares directly ahead of another pawn' do
          pawn = starting_board[1][0]
          expect(pawn.valid_moves).to eq(Set[[2, 0], [3, 0]])
        end
      end

      context 'not the first move in the game' do
        it 'shows just one square ahead' do
          board[3][4] = board[1][4]
          pawn = board[1][4]
          board[1][4] = nil

          expect(pawn.valid_moves).to eq(Set[[4, 4]])
        end
      end

      context 'when there is a piece in front of the pawn' do
        it 'returns an empty set' do
          board[3][4] = board[1][4]
          white_pawn = board[1][4]
          board[1][4] = nil

          board[4][4] = board[6][4]
          board[6][4] = nil

          expect(white_pawn.valid_moves).to eq(Set[])
        end
      end

      context 'when it is the first move but there is a piece 2 places ahead' do
        it 'only shows one square ahead' do
          board[3][4] = Bishop.new(:black, board)
          pawn = board[1][4]

          expect(pawn.valid_moves).to eq(Set[[2, 4]])
        end
      end

      context 'when it is the first move but there is a piece directly ahead' do
        it 'returns an empty set' do
          board[2][4] = Bishop.new(:black, board)
          pawn = board[1][4]

          expect(pawn.valid_moves).to eq(Set[])
        end
      end

      describe 'capturing' do
        context 'when opponents piece 1 square to the left diagonal' do
          it 'is possible to go forward or capture' do
            board[2][3] = Bishop.new(:black, board)
            pawn = board[1][4]

            expect(pawn.valid_moves).to eq(Set[[2, 4], [3, 4], [2, 3]])
          end
        end

        context 'when opponents piece 1 square to the right diagonal' do
          it 'is possible to go forward or capture' do
            board[2][5] = Bishop.new(:black, board)
            pawn = board[1][4]

            expect(pawn.valid_moves).to eq(Set[[2, 4], [3, 4], [2, 5]])
          end
        end

        context 'when opponents pieces are on both diagonals' do
          it 'is possible to go forward or capture' do
            board[2][5] = Bishop.new(:black, board)
            board[2][3] = Bishop.new(:black, board)
            pawn = board[1][4]

            expect(pawn.valid_moves).to eq(Set[[2, 4], [3, 4], [2, 3], [2, 5]])
          end
        end

        context 'when there is a piece ahead but capture is possible' do
          it 'is possible to capture' do
            board[2][5] = Bishop.new(:black, board)
            board[2][4] = Bishop.new(:black, board)
            board[2][3] = Bishop.new(:black, board)
            pawn = board[1][4]

            expect(pawn.valid_moves).to eq(Set[[2, 3], [2, 5]])
          end
        end

        context 'when player\'s piece 1 square to the left diagonal' do
          it 'is not possible to capture own piece' do
            board[2][3] = Bishop.new(:white, board)
            pawn = board[1][4]

            expect(pawn.valid_moves).to eq(Set[[2, 4], [3, 4]])
          end
        end

        context 'when player\'s piece 1 square to the right diagonal' do
          it 'is not possible to capture own piece' do
            board[2][5] = Bishop.new(:white, board)
            pawn = board[1][4]

            expect(pawn.valid_moves).to eq(Set[[2, 4], [3, 4]])
          end
        end

        context "when player's pieces are all around" do
          it 'returns empty set' do
            board[2][5] = Bishop.new(:white, board)
            board[2][4] = Bishop.new(:white, board)
            board[2][3] = Bishop.new(:white, board)
            pawn = board[1][4]

            expect(pawn.valid_moves).to eq(Set[])
          end
        end

        context 'when there is an en passant opportunity on the left' do
          subject(:white_pawn) { Pawn.new(:white, board, [1, 4]) }

          before do
            board[4][4] = white_pawn

            black_pawn = board[6][3]
            black_pawn.valid_moves

            board[4][3] = black_pawn
            board[6][3] = nil
          end

          it 'shows the capture opportunity on the move following' do
            expect(white_pawn.valid_moves('d5')).to eq(Set[[5, 3], [5, 4]])
          end

          it 'does not show capture opportunity 2 moves following' do
            expect(white_pawn.valid_moves('a5')).to eq(Set[[5, 4]])
          end
        end

        context 'when there is an en passant opportunity on the right' do
          let(:white_pawn) { Pawn.new(:white, board, [1, 4]) }

          before do
            board[4][4] = white_pawn

            black_pawn = board[6][5]
            black_pawn.valid_moves

            board[4][5] = black_pawn
            board[6][5] = nil
          end

          it 'shows the capture opportunity on the move following' do
            expect(white_pawn.valid_moves('f5')).to eq(Set[[5, 5], [5, 4]])
          end

          it 'does not show capture opportunity 2 moves following' do
            expect(white_pawn.valid_moves('a5')).to eq(Set[[5, 4]])
          end
        end

        context 'when en passant is not possible, but pawn is on the left' do
          subject(:white_pawn) { Pawn.new(:white, board, [1, 4]) }

          before do
            board[4][4] = white_pawn

            black_pawn = board[6][5]
            black_pawn.valid_moves

            board[5][3] = black_pawn
            board[6][3] = nil

            black_pawn.valid_moves
            board[4][3] = black_pawn
            board[5][3] = nil
          end

          it 'does not show capture opportunity on the move following' do
            expect(white_pawn.valid_moves('f5')).to eq(Set[[5, 4]])
          end
        end

        context 'when there is the opponents piece on the left' do
          subject(:white_pawn) { Pawn.new(:white, board, [1, 4]) }

          before do
            board[4][4] = white_pawn
            board[4][3] = Rook.new(:black, board)
          end

          it 'does not show capture opportunity' do
            expect(white_pawn.valid_moves('Rf5')).to eq(Set[[5, 4]])
          end
        end

        context 'when there is the players piece on the left' do
          subject(:white_pawn) { Pawn.new(:white, board, [1, 4]) }

          before do
            board[4][4] = white_pawn
            board[4][3] = Rook.new(:white, board)
          end

          it 'does not show capture opportunity' do
            expect(white_pawn.valid_moves('Bf2')).to eq(Set[[5, 4]])
          end
        end
      end
    end

    context 'black pawn' do
      context 'first move in the game' do
        it 'shows two squares directly ahead of it' do
          pawn = starting_board[6][4]
          expect(pawn.valid_moves).to eq(Set[[5, 4], [4, 4]])
        end

        it 'shows two squares directly ahead of another pawn' do
          pawn = starting_board[6][0]
          expect(pawn.valid_moves).to eq(Set[[5, 0], [4, 0]])
        end
      end

      context 'not the first move in the game' do
        it 'shows just one square ahead' do
          board[4][4] = board[6][4]
          pawn = board[6][4]
          board[6][4] = nil

          expect(pawn.valid_moves).to eq(Set[[3, 4]])
        end
      end

      context 'when there is a piece in front of the pawn' do
        it 'returns an empty set' do
          board[3][4] = board[1][4]
          white_pawn = board[1][4]
          board[1][4] = nil

          board[4][4] = board[6][4]
          board[6][4] = nil

          expect(white_pawn.valid_moves).to eq(Set[])
        end
      end

      context 'when it is the first move but there is a piece 2 places ahead' do
        it 'only shows one square ahead' do
          board[4][4] = Bishop.new(:white, board)
          pawn = board[6][4]

          expect(pawn.valid_moves).to eq(Set[[5, 4]])
        end
      end

      context 'when it is the first move but there is a piece directly ahead' do
        it 'returns an empty set' do
          board[5][4] = Bishop.new(:white, board)
          pawn = board[6][4]

          expect(pawn.valid_moves).to eq(Set[])
        end
      end

      describe 'capturing' do
        context 'when opponents piece 1 square to the left diagonal' do
          it 'is possible to go forward or capture' do
            board[5][3] = Bishop.new(:white, board)
            pawn = board[6][4]

            expect(pawn.valid_moves).to eq(Set[[5, 4], [4, 4], [5, 3]])
          end
        end

        context 'when opponents piece 1 square to the right diagonal' do
          it 'is possible to go forward or capture' do
            board[5][5] = Bishop.new(:white, board)
            pawn = board[6][4]

            expect(pawn.valid_moves).to eq(Set[[5, 4], [4, 4], [5, 5]])
          end
        end

        context 'when opponents pieces are on both diagonals' do
          it 'is possible to go forward or capture' do
            board[5][5] = Bishop.new(:white, board)
            board[5][3] = Bishop.new(:white, board)
            pawn = board[6][4]

            expect(pawn.valid_moves).to eq(Set[[5, 4], [4, 4], [5, 3], [5, 5]])
          end
        end

        context 'when there is a piece ahead but capture is possible' do
          it 'is possible to capture' do
            board[5][5] = Bishop.new(:white, board)
            board[5][4] = Bishop.new(:white, board)
            board[5][3] = Bishop.new(:white, board)
            pawn = board[6][4]

            expect(pawn.valid_moves).to eq(Set[[5, 3], [5, 5]])
          end
        end

        context 'when player\'s piece 1 square to the left diagonal' do
          it 'is not possible to capture own piece' do
            board[5][3] = Bishop.new(:black, board)
            pawn = board[6][4]

            expect(pawn.valid_moves).to eq(Set[[5, 4], [4, 4]])
          end
        end

        context 'when player\'s piece 1 square to the right diagonal' do
          it 'is not possible to capture own piece' do
            board[5][5] = Bishop.new(:black, board)
            pawn = board[6][4]

            expect(pawn.valid_moves).to eq(Set[[5, 4], [4, 4]])
          end
        end

        context "when player's pieces are all around" do
          it 'returns empty set' do
            board[5][5] = Bishop.new(:black, board)
            board[5][4] = Bishop.new(:black, board)
            board[5][3] = Bishop.new(:black, board)
            pawn = board[6][4]

            expect(pawn.valid_moves).to eq(Set[])
          end
        end

        context 'when there is an en passant opportunity on the left' do
          subject(:black_pawn) { Pawn.new(:black, board, [6, 4]) }

          before do
            board[3][4] = black_pawn

            white_pawn = board[1][3]
            white_pawn.valid_moves

            board[3][3] = white_pawn
            board[1][3] = nil
          end

          it 'shows the capture opportunity on the move following' do
            expect(black_pawn.valid_moves('d4')).to eq(Set[[2, 3], [2, 4]])
          end

          it 'does not show capture opportunity 2 moves following' do
            expect(black_pawn.valid_moves('a4')).to eq(Set[[2, 4]])
          end
        end

        context 'when there is an en passant opportunity on the right' do
          subject(:black_pawn) { Pawn.new(:black, board, [6, 4]) }

          before do
            board[3][4] = black_pawn

            white_pawn = board[1][5]
            white_pawn.valid_moves

            board[3][5] = white_pawn
            board[1][5] = nil
          end

          it 'shows the capture opportunity on the move following' do
            expect(black_pawn.valid_moves('f4')).to eq(Set[[2, 5], [2, 4]])
          end

          it 'does not show capture opportunity 2 moves following' do
            expect(black_pawn.valid_moves('a4')).to eq(Set[[2, 4]])
          end
        end

        context 'when en passant is not possible, but pawn is on the left' do
          subject(:black_pawn) { Pawn.new(:black, board, [1, 4]) }

          before do
            board[4][4] = black_pawn

            white_pawn = board[6][5]
            white_pawn.valid_moves

            board[5][3] = white_pawn
            board[6][3] = nil

            white_pawn.valid_moves
            board[4][3] = white_pawn
            board[5][3] = nil

          end

          it 'does not show capture opportunity on the move following' do
            expect(black_pawn.valid_moves('f4')).to eq(Set[[3, 4]])
          end
        end

        context 'when there is the opponents piece on the left' do
          subject(:black_pawn) { Pawn.new(:black, board, [1, 4]) }

          before do
            board[3][4] = black_pawn
            board[3][3] = Rook.new(:white, board)
          end

          it 'does not show capture opportunity' do
            expect(black_pawn.valid_moves('Rf5')).to eq(Set[[2, 4]])
          end
        end

        context 'when there is the player\'s piece on the left' do
          subject(:black_pawn) { Pawn.new(:black, board, [1, 4]) }

          before do
            board[3][4] = black_pawn
            board[3][3] = Rook.new(:black, board)
          end

          it 'does not show capture opportunity' do
            expect(black_pawn.valid_moves('Bf2')).to eq(Set[[2, 4]])
          end
        end
      end
    end
  end
end

RSpec.describe Rook do
  include Boards

  describe "#valid_moves" do
    context 'on a starting board' do
      let(:rooks_moves) do
        [
          starting_board[0][0], starting_board[0][7], starting_board[7][0],
          starting_board[7][7]
        ].map { |rook| rook.valid_moves }
      end

      it 'no rook has any moves' do
        expect(rooks_moves).to all(eq(Set[]))
      end
    end

    context 'on a board with just a rook on it' do
      let(:board) { empty_board }

      context 'when the rook is white' do
        subject(:rook) { Rook.new(:white, board) }

        context 'when the rook is in the corner' do
          before do
            board[0][0] = rook
          end

          it 'can move anywhere along the file it is on' do
            expect(rook.valid_moves).to include(
              [1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0], [7, 0]
            )
          end

          it 'can move anywhere along the rank it is on' do
            expect(rook.valid_moves).to include(
              [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7]
            )
          end
        end

        context 'when the rook is on an edge' do
          before do
            board[4][0] = rook
          end

          it 'can move anywhere along the file or rank it is on' do
            expect(rook.valid_moves).to eq(Set[
              [0, 0], [1, 0], [2, 0], [3, 0], [5, 0], [6, 0], [7, 0],
              [4, 1], [4, 2], [4, 3], [4, 4], [4, 5], [4, 6], [4, 7]
            ])
          end
        end

        context 'when the rook is in the middle' do
          before do
            board[4][5] = rook
          end

          it 'can move anywhere along the file or rank it is on' do
            expect(rook.valid_moves).to eq(Set[
              [0, 5], [1, 5], [2, 5], [3, 5], [5, 5], [6, 5], [7, 5],
              [4, 0], [4, 1], [4, 2], [4, 3], [4, 4], [4, 6], [4, 7]
            ])
          end
        end
      end

      context 'when the rook is black' do
        subject(:rook) { Rook.new(:black, board) }
        before do
          board[4][5] = rook
        end

        it 'can move anywhere along the file or rank it is on' do
          expect(rook.valid_moves).to eq(Set[
            [0, 5], [1, 5], [2, 5], [3, 5], [5, 5], [6, 5], [7, 5],
            [4, 0], [4, 1], [4, 2], [4, 3], [4, 4], [4, 6], [4, 7]
          ])
        end
      end
    end

    context 'when an opponent piece is in the rooks path' do
      subject(:rook) { Rook.new(:white, board) }
      let(:board) { empty_board }

      context 'on a rank' do
        before do
          board[4][5] = rook
          board[4][2] = Rook.new(:black, board)
        end

        it 'can move anywhere up to that piece and capture it' do
          expect(rook.valid_moves).to eq(Set[
            [0, 5], [1, 5], [2, 5], [3, 5], [5, 5], [6, 5], [7, 5],
            [4, 2], [4, 3], [4, 4], [4, 6], [4, 7]
          ])
        end
      end

      context 'on a file' do
        before do
          board[4][5] = rook
          board[6][5] = Rook.new(:black, board)
        end

        it 'can move anywhere up to that piece and capture it' do
          expect(rook.valid_moves).to eq(Set[
            [0, 5], [1, 5], [2, 5], [3, 5], [5, 5], [6, 5],
            [4, 0], [4, 1], [4, 2], [4, 3], [4, 4], [4, 6], [4, 7]
          ])
        end
      end
    end

    context 'when the player\'s piece is in the rooks path' do
      subject(:rook) { Rook.new(:white, board) }
      let(:board) { empty_board }

      context 'on a rank' do
        before do
          board[4][5] = rook
          board[4][2] = Rook.new(:white, board)
        end

        it 'can move anywhere up to that piece' do
          expect(rook.valid_moves).to eq(Set[
            [0, 5], [1, 5], [2, 5], [3, 5], [5, 5], [6, 5], [7, 5],
            [4, 3], [4, 4], [4, 6], [4, 7]
          ])
        end
      end

      context 'on a file' do
        before do
          board[4][5] = rook
          board[6][5] = Rook.new(:white, board)
        end

        it 'can move anywhere up to that piece' do
          expect(rook.valid_moves).to eq(Set[
            [0, 5], [1, 5], [2, 5], [3, 5], [5, 5],
            [4, 0], [4, 1], [4, 2], [4, 3], [4, 4], [4, 6], [4, 7]
          ])
        end
      end
    end
  end
end


RSpec.describe Bishop do
  include Boards

  describe "#valid_moves" do
    context 'on a starting board' do
      let(:bishops_moves) do
        [
          starting_board[0][2], starting_board[0][5], starting_board[7][2],
          starting_board[7][5]
        ].map { |bishop| bishop.valid_moves }
      end

      it 'no bishop has any moves' do
        expect(bishops_moves).to all(eq(Set[]))
      end
    end

    context 'on a board with just a bishop on it' do
      let(:board) { empty_board }
      context 'when the bishop is white' do
        subject(:bishop) { Bishop.new(:white, board) }

        context 'when the bishop is in the corner' do
          before do
            board[0][0] = bishop
          end

          it 'can move anywhere along the diagonal it is on' do
            expect(bishop.valid_moves).to eq(Set[
              [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7]
            ])
          end
        end

        context 'when the bishop is on an edge' do
          before do
            board[4][0] = bishop
          end

          it 'can move anywhere along the two diagonals it is on' do
            expect(bishop.valid_moves).to eq(Set[
              [3, 1], [2, 2], [1, 3], [0, 4], [5, 1], [6, 2], [7, 3]
            ])
          end
        end

        context 'when the bishop is in the middle' do
          before do
            board[4][5] = bishop
          end

          it 'can move anywhere along the two diagonals it is on' do
            expect(bishop.valid_moves).to eq(Set[
              [7, 2], [6, 3], [5, 4], [3, 6], [2, 7],
              [0, 1], [1, 2], [2, 3], [3, 4], [5, 6], [6, 7]
            ])
          end
        end
      end

      context 'when the bishop is black' do
        subject(:bishop) { Bishop.new(:black, board) }
        before do
          board[4][5] = bishop
        end

        it 'can move anywhere along the two diagonals it is on' do
          expect(bishop.valid_moves).to eq(Set[
            [7, 2], [6, 3], [5, 4], [3, 6], [2, 7],
            [0, 1], [1, 2], [2, 3], [3, 4], [5, 6], [6, 7]
          ])
        end
      end
    end

    context 'when an opponent piece is in the bishops path' do
      subject(:bishop) { Bishop.new(:white, board) }
      let(:board) { empty_board }

      before do
        board[4][5] = bishop
        board[2][3] = Bishop.new(:black, board)
      end

      it 'can move anywhere up to that piece and capture it' do
        expect(bishop.valid_moves).to eq(Set[
          [7, 2], [6, 3], [5, 4], [3, 6], [2, 7],
          [2, 3], [3, 4], [5, 6], [6, 7]
        ])
      end
    end

    context 'when the player\'s piece is in the rooks path' do
      subject(:bishop) { Bishop.new(:white, board) }
      let(:board) { empty_board }

      before do
        board[4][5] = bishop
        board[2][3] = Bishop.new(:white, board)
      end

      it 'can move anywhere up to that piece' do
        expect(bishop.valid_moves).to eq(Set[
          [7, 2], [6, 3], [5, 4], [3, 6], [2, 7],
          [3, 4], [5, 6], [6, 7]
        ])
      end
    end
  end
end

RSpec.describe Queen do
  include Boards

  describe "#valid_moves" do
    context 'on a starting board' do
      let(:queens_moves) do
        [
          starting_board[0][3], starting_board[7][3]
        ].map { |queen| queen.valid_moves }
      end

      it 'no queen has any moves' do
        expect(queens_moves).to all(eq(Set[]))
      end
    end

    context 'on a board with just a queen on it' do
      let(:board) { empty_board }
      context 'when the queen is white' do
        subject(:queen) { Queen.new(:white, board) }

        context 'when the queen is in the corner' do
          before do
            board[0][0] = queen
          end

          it 'can move along the diagonal, rank and file it is on' do
            expect(queen.valid_moves).to eq(Set[
              [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7],
              [1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0], [7, 0],
              [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7]
            ])
          end
        end

        context 'when the queen is on an edge' do
          before do
            board[4][0] = queen
          end

          it 'can move along the two diagonals, rank and file it is on' do
            expect(queen.valid_moves).to eq(Set[
              [3, 1], [2, 2], [1, 3], [0, 4], [5, 1], [6, 2], [7, 3],
              [0, 0], [1, 0], [2, 0], [3, 0], [5, 0], [6, 0], [7, 0],
              [4, 1], [4, 2], [4, 3], [4, 4], [4, 5], [4, 6], [4, 7]
            ])
          end
        end

        context 'when the queen is in the middle' do
          before do
            board[4][5] = queen
          end

          it 'can move along the two diagonals,rank and file it is on' do
            expect(queen.valid_moves).to eq(Set[
              [7, 2], [6, 3], [5, 4], [3, 6], [2, 7],
              [0, 1], [1, 2], [2, 3], [3, 4], [5, 6], [6, 7],
              [0, 5], [1, 5], [2, 5], [3, 5], [5, 5], [6, 5], [7, 5],
              [4, 0], [4, 1], [4, 2], [4, 3], [4, 4], [4, 6], [4, 7]
            ])
          end
        end
      end

      context 'when the queen is black' do
        subject(:queen) { Queen.new(:black, board) }
        before do
          board[4][5] = queen
        end

        it 'can move anywhere along the two diagonals it is on' do
          expect(queen.valid_moves).to eq(Set[
            [7, 2], [6, 3], [5, 4], [3, 6], [2, 7],
            [0, 1], [1, 2], [2, 3], [3, 4], [5, 6], [6, 7],
            [0, 5], [1, 5], [2, 5], [3, 5], [5, 5], [6, 5], [7, 5],
            [4, 0], [4, 1], [4, 2], [4, 3], [4, 4], [4, 6], [4, 7]
          ])
        end
      end
    end
  end
end

RSpec.describe Knight do
  include Boards

  describe "#valid_moves" do
    context 'on a starting board' do
      let(:knights_moves) do
        [
          starting_board[0][1], starting_board[7][1],
          starting_board[0][6], starting_board[7][6]
        ].map { |knight| knight.valid_moves }
      end

      it 'each knight has two possible moves' do
        expect(knights_moves).to all(have_attributes(length: 2))
      end
    end

    context 'on a board with just a knight on it' do
      let(:board) { empty_board }
      context 'when the knight is white' do
        subject(:knight) { Knight.new(:white, board) }

        context 'when the knight is in the corner' do
          before do
            board[7][7] = knight
          end

          it 'has two moves' do
            expect(knight.valid_moves).to eq(Set[[6, 5], [5, 6]])
          end
        end

        context 'when the knight is on the edge' do
          before do
            board[4][7] = knight
          end

          it 'has four moves' do
            expect(knight.valid_moves).to eq(Set[
              [6, 6], [5, 5], [3, 5], [2, 6]
            ])
          end
        end

        context 'when the knight is in the middle' do
          before do
            board[4][4] = knight
          end

          it 'has eight moves' do
            expect(knight.valid_moves).to eq(Set[
              [5, 2], [6, 3], [6, 5], [5, 6], [3, 6], [2, 5], [2, 3], [3, 2]
            ])
          end
        end
      end

      context 'when the knight is black and in the middle' do
        subject(:knight) { Knight.new(:black, board) }

        before do
          board[4][4] = knight
        end

        it 'has eight moves' do
          expect(knight.valid_moves).to eq(Set[
            [5, 2], [6, 3], [6, 5], [5, 6], [3, 6], [2, 5], [2, 3], [3, 2]
          ])
        end
      end

      context 'when there is a piece the knight can capture' do
        subject(:knight) { Knight.new(:white, board) }

        before do
          board[4][4] = knight
          board[5][2] = Knight.new(:black, board)
        end

        it 'can capture it' do
          expect(knight.valid_moves).to eq(Set[
            [5, 2], [6, 3], [6, 5], [5, 6], [3, 6], [2, 5], [2, 3], [3, 2]
          ])
        end
      end

      context 'when there is a player\'s piece within the knights range' do
        subject(:knight) { Knight.new(:white, board) }

        before do
          board[4][4] = knight
          board[5][2] = Knight.new(:white, board)
        end

        it 'can capture it' do
          expect(knight.valid_moves).to eq(Set[
            [6, 3], [6, 5], [5, 6], [3, 6], [2, 5], [2, 3], [3, 2]
          ])
        end
      end
    end
  end
end

RSpec.describe King do
  include Boards

  describe "#valid_moves" do
    context 'on a starting board' do
      let(:kings_moves) do
        [
          starting_board[0][4], starting_board[7][4]
        ].map { |king| king.valid_moves }
      end

      it 'no king has any moves' do
        expect(kings_moves).to all(eq(Set[]))
      end
    end

    context 'on a board with just a king on it' do
      let(:board) { empty_board }
      context 'when the king is white' do
        subject(:king) { King.new(:white, board, [0, 4]) }

        context 'when the king is in the corner' do
          before do
            board[0][0] = king
          end

          it 'has three moves' do
            expect(king.valid_moves).to eq(Set[[1, 0], [1, 1], [0, 1]])
          end
        end

        context 'when the king is on the edge' do
          before do
            board[4][0] = king
          end

          it 'has five moves' do
            expect(king.valid_moves).to eq(Set[
              [5, 0], [5, 1], [4, 1], [3, 0], [3, 1]
            ])
          end
        end

        context 'when the king is in the middle' do
          before do
            board[4][4] = king
          end

          it 'has eight moves' do
            expect(king.valid_moves).to eq(Set[
              [5, 3], [5, 4], [5, 5], [4, 3], [3, 3], [3, 4], [3, 5], [4, 5]
            ])
          end
        end
      end

      context 'when the king is black and in the middle' do
        subject(:king) { King.new(:black, board, [0, 4]) }

        before do
          board[4][4] = king
        end

        it 'has eight moves' do
          expect(king.valid_moves).to eq(Set[
            [5, 3], [5, 4], [5, 5], [4, 3], [3, 3], [3, 4], [3, 5], [4, 5]
          ])
        end
      end

      context 'when there is a piece the king can capture' do
        subject(:king) { King.new(:white, board, [0, 4]) }

        before do
          board[4][4] = king
          board[5][3] = Knight.new(:black, board)
        end

        it 'can capture it' do
          expect(king.valid_moves).to eq(Set[
            [5, 3], [5, 4], [5, 5], [4, 3], [3, 3], [3, 4], [3, 5], [4, 5]
          ])
        end
      end

      context 'when there is a player\'s piece within the king\'s range' do
        subject(:king) { King.new(:white, board, [0, 4]) }

        before do
          board[4][4] = king
          board[5][3] = Knight.new(:white, board)
        end

        it 'can capture it' do
          expect(king.valid_moves).to eq(Set[
            [5, 4], [5, 5], [4, 3], [3, 3], [3, 4], [3, 5], [4, 5]
          ])
        end
      end
    end

    describe 'castling' do
      let(:board) { empty_board }

      context 'when a king is white' do
        subject(:king) { King.new(:white, board, [0, 4]) }

        before do
          board[0][4] = king
        end

        context 'on its first move' do
          describe 'kingside' do
            context 'when the kingside rook has not moved' do
              before do
                board[0][7] = Rook.new(:white, board, [0, 7])
              end

              it 'castling kingside is possible' do
                expect(king.valid_moves).to eq(Set[
                  [0, 3], [1, 3], [1, 4], [1, 5], [0, 5], [0, 6]
                ])
              end
            end

            context 'when there is a different piece in place of rook' do
              before do
                board[0][7] = Bishop.new(:white, board)
              end

              it 'castling kingside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
                ])
              end
            end

            context 'when there is no piece in place of the rook' do
              it 'castling kingside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
                ])
              end
            end

            context 'when the kingside rook has moved' do
              before do
                board[5][7] = Rook.new(:white, board, [0, 7])
                board[5][7].valid_moves

                board[0][7] = board[5][7]
                board[5][7] = nil
              end

              it 'castling kingside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
                ])
              end
            end

            context 'when an opponents piece occupies a castling square' do
              before do
                board[0][7] = Rook.new(:white, board, [0, 7])
              end

              context 'f1' do
                before do
                  board[0][5] = Knight.new(:black, board)
                end

                it 'castling kingside is not possible' do
                  expect(king.valid_moves).to eq(Set[
                    [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
                  ])
                end
              end
              context 'g1' do
                before do
                  board[0][6] = Knight.new(:black, board)
                end

                it 'castling kingside is not possible' do
                  expect(king.valid_moves).to eq(Set[
                    [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
                  ])
                end
              end
            end
          end

          describe 'queenside' do
            context 'when the queenside rook has not moved' do
              before do
                board[0][0] = Rook.new(:white, board, [0, 0])
              end

              it 'castling queenside is possible' do
                expect(king.valid_moves).to eq(Set[
                  [0, 3], [1, 3], [1, 4], [1, 5], [0, 5], [0, 2]
                ])
              end
            end

            context 'when there is a different piece in place of rook' do
              before do
                board[0][0] = Bishop.new(:white, board)
              end

              it 'castling queenside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
                ])
              end
            end

            context 'when there is no piece in place of the rook' do
              it 'castling queenside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
                ])
              end
            end

            context 'when the queenside rook has moved' do
              before do
                board[5][0] = Rook.new(:white, board, [0, 0])
                board[5][0].valid_moves

                board[0][0] = board[5][0]
                board[5][0] = nil
              end

              it 'castling queenside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
                ])
              end
            end

            context 'when an opponents piece occupies a castling square' do
              before do
                board[0][0] = Rook.new(:white, board, [0, 0])
              end

              context 'b1' do
                before do
                  board[0][1] = Knight.new(:black, board)
                end

                it 'castling queenside is not possible' do
                  expect(king.valid_moves).to eq(Set[
                    [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
                  ])
                end
              end
              context 'c1' do
                before do
                  board[0][2] = Knight.new(:black, board)
                end

                it 'castling queenside is not possible' do
                  expect(king.valid_moves).to eq(Set[
                    [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
                  ])
                end
              end

              context 'd1' do
                before do
                  board[0][3] = Knight.new(:black, board)
                end

                it 'castling queenside is not possible' do
                  expect(king.valid_moves).to eq(Set[
                    [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
                  ])
                end
              end
            end
          end

          context 'when neither rook has moved' do
            before do
              board[0][0] = Rook.new(:white, board, [0, 0])
              board[0][7] = Rook.new(:white, board, [0, 7])
            end

            it 'is possible to castle either kingside or queenside' do
              expect(king.valid_moves).to eq(Set[
                [0, 2], [0, 3], [1, 3], [1, 4], [1, 5], [0, 5], [0, 6]
              ])
            end
          end
        end

        context 'when the king has already moved' do
          before do
            king.valid_moves
            board[1][4] = king
            board[0][4] = nil

            king.valid_moves
            board[0][4] = king
            board[1][4] = nil

            board[0][0] = Rook.new(:white, board, [0, 0])
            board[0][7] = Rook.new(:white, board, [0, 7])
          end

          it 'is not possible to castle' do
            expect(king.valid_moves).to eq(Set[
              [0, 3], [1, 3], [1, 4], [1, 5], [0, 5]
            ])
          end
        end
      end

      context 'when a king is black' do
        subject(:king) { King.new(:black, board, [7, 4]) }

        before do
          board[7][4] = king
        end

        context 'on its first move' do
          describe 'kingside' do
            context 'when the kingside rook has not moved' do
              before do
                board[7][7] = Rook.new(:black, board, [7, 7])
              end

              it 'castling kingside is possible' do
                expect(king.valid_moves).to eq(Set[
                  [7, 3], [6, 3], [6, 4], [6, 5], [7, 5], [7, 6]
                ])
              end
            end

            context 'when there is a different piece in place of rook' do
              before do
                board[7][7] = Bishop.new(:black, board)
              end

              it 'castling kingside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [7, 3], [6, 3], [6, 4], [6, 5], [7, 5]
                ])
              end
            end

            context 'when there is no piece in place of the rook' do
              it 'castling kingside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [7, 3], [6, 3], [6, 4], [6, 5], [7, 5]
                ])
              end
            end

            context 'when the kingside rook has moved' do
              before do
                board[5][7] = Rook.new(:black, board, [7, 7])
                board[5][7].valid_moves

                board[7][7] = board[5][7]
                board[5][7] = nil
              end

              it 'castling kingside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [7, 3], [6, 3], [6, 4], [6, 5], [7, 5]
                ])
              end
            end

            context 'when the player\'s piece occupies a castling square' do
              before do
                board[7][7] = Rook.new(:black, board, [7, 7])
              end

              context 'f7' do
                before do
                  board[7][5] = Knight.new(:black, board)
                end

                it 'castling kingside is not possible' do
                  expect(king.valid_moves).to eq(Set[
                    [7, 3], [6, 3], [6, 4], [6, 5],
                  ])
                end
              end
              context 'g7' do
                before do
                  board[7][6] = Knight.new(:black, board)
                end

                it 'castling kingside is not possible' do
                  expect(king.valid_moves).to eq(Set[
                    [7, 3], [6, 3], [6, 4], [6, 5], [7, 5]
                  ])
                end
              end
            end
          end

          describe 'queenside' do
            context 'when the queenside rook has not moved' do
              before do
                board[7][0] = Rook.new(:black, board, [7, 0])
              end

              it 'castling queenside is possible' do
                expect(king.valid_moves).to eq(Set[
                  [7, 3], [6, 3], [6, 4], [6, 5], [7, 5], [7, 2]
                ])
              end
            end

            context 'when there is a different piece in place of rook' do
              before do
                board[7][0] = Bishop.new(:black, board)
              end

              it 'castling queenside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [7, 3], [6, 3], [6, 4], [6, 5], [7, 5]
                ])
              end
            end

            context 'when there is no piece in place of the rook' do
              it 'castling queenside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [7, 3], [6, 3], [6, 4], [6, 5], [7, 5]
                ])
              end
            end

            context 'when the queenside rook has moved' do
              before do
                board[5][0] = Rook.new(:black, board, [7, 0])
                board[5][0].valid_moves

                board[7][0] = board[5][0]
                board[5][0] = nil
              end

              it 'castling queenside is not possible' do
                expect(king.valid_moves).to eq(Set[
                  [7, 3], [6, 3], [6, 4], [6, 5], [7, 5]
                ])
              end
            end

            context 'when an opponents piece occupies a castling square' do
              before do
                board[7][0] = Rook.new(:black, board, [7, 0])
              end

              context 'b7' do
                before do
                  board[7][1] = Knight.new(:white, board)
                end

                it 'castling queenside is not possible' do
                  expect(king.valid_moves).to eq(Set[
                    [7, 3], [6, 3], [6, 4], [6, 5], [7, 5]
                  ])
                end
              end

              context 'c7' do
                before do
                  board[7][2] = Knight.new(:white, board)
                end

                it 'castling queenside is not possible' do
                  expect(king.valid_moves).to eq(Set[
                    [7, 3], [6, 3], [6, 4], [6, 5], [7, 5]
                  ])
                end
              end

              context 'd7' do
                before do
                  board[7][3] = Knight.new(:white, board)
                end

                it 'castling queenside is not possible' do
                  expect(king.valid_moves).to eq(Set[
                    [7, 3], [6, 3], [6, 4], [6, 5], [7, 5]
                  ])
                end
              end
            end
          end

          context 'when neither rook has moved' do
            before do
              board[7][0] = Rook.new(:black, board, [7, 0])
              board[7][7] = Rook.new(:black, board, [7, 7])
            end

            it 'is possible to castle either kingside or queenside' do
              expect(king.valid_moves).to eq(Set[
                [7, 2], [7, 3], [6, 3], [6, 4], [6, 5], [7, 5], [7, 6]
              ])
            end
          end
        end

        context 'when the king has already moved' do
          before do
            king.valid_moves
            board[6][4] = king
            board[7][4] = nil

            king.valid_moves
            board[7][4] = king
            board[6][4] = nil

            board[7][0] = Rook.new(:black, board, [7, 0])
            board[7][7] = Rook.new(:black, board, [7, 7])
          end

          it 'is not possible to castle' do
            expect(king.valid_moves).to eq(Set[
              [7, 3], [6, 3], [6, 4], [6, 5], [7, 5]
            ])
          end
        end
      end
    end
  end
end
