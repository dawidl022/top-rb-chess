require_relative '../lib/piece'
require_relative 'util'
require 'set'

RSpec.describe Piece do
  include Util

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

  describe '#valid_move' do
    let(:board) { starting_board }

    context 'when given a valid move' do
      let(:white_pawn) { board[1][4] }

      it 'returns true' do
        expect(white_pawn.valid_move?(3, 4)).to be true
      end
    end

    context 'when given an invalid move' do
      let(:white_pawn) { board[1][4] }

      it 'returns true' do
        expect(white_pawn.valid_move?(5, 4)).to be false
        expect(white_pawn.valid_move?(1, 4)).to be false
      end
    end

    context 'when opponents last move play a role' do
      context 'en passant possible and try going there' do
        let(:black_pawn) { Pawn.new(:black, board, [6, 4]) }

        before do
          board[3][4] = black_pawn

          white_pawn = board[1][3]
          white_pawn.valid_moves

          board[3][3] = white_pawn
          board[1][3] = nil
        end

        it 'returns true' do
          expect(black_pawn.valid_move?(2, 3, 'd4')).to be true
        end
      end
    end

    context 'when opponents last move does not play a role' do
      pending 'other pieces not yet implemented'
    end
  end

  describe "#to_s" do
    describe "returns the unicode char along with chess notation position" do
      pending 'indices to chess notation conversion not yet implemented'
    end
  end
end

RSpec.describe Pawn do
  include Util

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
          let(:white_pawn) { Pawn.new(:white, board, [1, 4]) }

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
          let(:white_pawn) { Pawn.new(:white, board, [1, 4]) }

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
          let(:white_pawn) { Pawn.new(:white, board, [1, 4]) }

          before do
            board[4][4] = white_pawn
            board[4][3] = Rook.new(:black, board)
          end

          it 'does not show capture opportunity' do
            expect(white_pawn.valid_moves('Rf5')).to eq(Set[[5, 4]])
          end
        end

        context 'when there is the players piece on the left' do
          let(:white_pawn) { Pawn.new(:white, board, [1, 4]) }

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
          let(:black_pawn) { Pawn.new(:black, board, [6, 4]) }

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
          let(:black_pawn) { Pawn.new(:black, board, [6, 4]) }

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
          let(:black_pawn) { Pawn.new(:black, board, [1, 4]) }

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
          let(:black_pawn) { Pawn.new(:black, board, [1, 4]) }

          before do
            board[3][4] = black_pawn
            board[3][3] = Rook.new(:white, board)
          end

          it 'does not show capture opportunity' do
            expect(black_pawn.valid_moves('Rf5')).to eq(Set[[2, 4]])
          end
        end

        context 'when there is the player\'s piece on the left' do
          let(:black_pawn) { Pawn.new(:black, board, [1, 4]) }

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
