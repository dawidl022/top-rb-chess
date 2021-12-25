require_relative '../lib/chessboard'
require_relative '../boards'

RSpec.describe Chessboard do
  include Boards

  subject(:board) { described_class.new }

  describe ".notation_to_indices" do
    it 'translates a1 to [0, 0]' do
      expect(described_class.notation_to_indices('a1')).to eq([0, 0])
    end

    it 'translates d5 to [4, 3]' do
      expect(described_class.notation_to_indices('d5')).to eq([4, 3])
    end

    it 'translates h8 to [7, 7]' do
      expect(described_class.notation_to_indices('h8')).to eq([7, 7])
    end

    describe 'when wrong form format is specified' do
      shared_examples_for 'invalid notation' do |notation|
        it 'raises an error' do
          expect { described_class.notation_to_indices(notation) }
            .to raise_error(
              ArgumentError,
              "Invalid notation for chessboard square: #{notation}"
            )
        end
      end

      context 'incorrect number of characters' do
        it_behaves_like 'invalid notation', 'de5'
      end

      context 'invalid characters' do
        it_behaves_like 'invalid notation', 't1'
        it_behaves_like 'invalid notation', 'e9'
      end

      context 'wrong order of characters' do
        it_behaves_like 'invalid notation', '3d'
      end
    end
  end

  describe ".indices_to_notation" do
    it 'translates [0, 0] to a1' do
      expect(described_class.indices_to_notation(0, 0)).to eq('a1')
    end

    it 'translates [4, 3] do d5' do
      expect(described_class.indices_to_notation(4, 3)).to eq('d5')
    end

    it 'translates [7, 7] to h8' do
      expect(described_class.indices_to_notation(7, 7)).to eq('h8')
    end

    shared_examples_for 'invalid indices' do |indices|
      it 'raises an error' do
        expect { described_class.indices_to_notation(*indices) }
          .to raise_error(
            ArgumentError,
            "Invalid indices for chessboard square: #{indices}"
          )
      end
    end

    context "when invalid rank index is specified" do
      it_behaves_like 'invalid indices', [8, 4]
    end

    context "when invalid file index is specified" do
      it_behaves_like 'invalid indices', [0, -1]
    end
  end

  describe "#move" do
    describe 'pawn' do
      it 'moves a white pawn forward by providing chess notation' do
        pawn = board.board[1][4]
        board.move('e4', :white)
        expect(pawn.position).to eq([3, 4])
      end

      it 'moves another white pawn forward by providing chess notation' do
        pawn = board.board[1][0]
        board.move('a3', :white)
        expect(pawn.position).to eq([2, 0])
      end

      it 'moves a black pawn forward by providing chess notation' do
        pawn = board.board[6][4]
        board.move('e5', :black)
        expect(pawn.position).to eq([4, 4])
      end

      it 'moves another black pawn forward by providing chess notation' do
        pawn = board.board[6][4]
        board.move('e5', :black)
        expect(pawn.position).to eq([4, 4])
      end

      context 'invalid' do
        it 'chessboard square' do
          response = board.move('z9', :black)
          expect(board.board.inspect).to eq(starting_board.inspect)
          expect(response).to eq("Invalid notation for chessboard square: z9")
        end

        it 'cannot move a pawn there due to piece blocking' do
          board.board[3][4] = Knight.new(:black, board.board)
          response = board.move('e4', :white)
          expect(response).to eq('Invalid move')
        end

        it 'no pawn can reach that square' do
          board.board[1][4] = nil
          response = board.move('e4', :white)
          expect(response).to eq('Invalid move')
        end

        it 'pawn cannot reach that square' do
          response = board.move('e5', :white)
          expect(response).to eq('Illegal move')
        end

        it 'no piece on that rank' do
          board.board[1][4] = nil
          board.board[0][4] = nil
          response = board.move('e4', :white)
          expect(response).to eq('Invalid move')
        end
      end

      context 'when move causes player to be under check' do
        before do
          board.instance_variable_set(:@board, empty_board)
          board.board[6][0] = Bishop.new(:black, board.board)
          board.board[7][5] = King.new(:black, board.board, [7, 4])
          board.board[2][4] = Pawn.new(:white, board.board, [1, 4])
          board.board[1][5] = King.new(:white, board.board, [0, 4])
        end

        it 'is illegal' do
          response = board.move('e4', :white)
          expect(response).to eq('Illegal move')
        end
      end
    end
  end

  describe "#under_check?" do
    before do
      board.instance_variable_set(:@board, empty_board)
    end

    context 'when white is not under check' do
      shared_examples_for 'white not checked' do
        it 'returns false' do
          expect(board).to_not be_under_check(:white)
        end
      end

      before do
        board.board[6][0] = Bishop.new(:black, board.board)
        board.board[7][5] = King.new(:black, board.board, [7, 4])
        board.board[2][4] = Pawn.new(:white, board.board, [1, 4])
        board.board[1][5] = King.new(:white, board.board, [0, 4])
      end

      it_behaves_like 'white not checked'
    end

    context 'when white is under check' do
      shared_examples_for 'white checked' do
        it 'returns true' do
          expect(board).to be_under_check(:white)
        end
      end

      before do
        board.board[6][0] = Bishop.new(:black, board.board)
        board.board[7][5] = King.new(:black, board.board, [7, 4])
        board.board[1][5] = King.new(:white, board.board, [0, 4])
      end

      it_behaves_like 'white checked'
    end

    context 'when black is not under check' do
      shared_examples_for 'black not checked' do
        it 'returns false' do
          expect(board).to_not be_under_check(:black)
        end
      end

      before do
        board.board[6][1] = Knight.new(:black, board.board)
        board.board[6][4] = King.new(:black, board.board, [7, 4])
        board.board[5][4] = Rook.new(:black, board.board)
        board.board[3][4] = Queen.new(:white, board.board)
        board.board[2][2] = Knight.new(:white, board.board)
        board.board[2][5] = King.new(:white, board.board, [0, 4])
        board.board[1][0] = Pawn.new(:white, board.board, [1, 0])
      end

      it_behaves_like 'black not checked'
    end

    context 'when black is under check' do
      shared_examples_for 'black checked' do
        it 'returns false' do
          expect(board).to be_under_check(:black)
        end
      end

      before do
        board.board[6][1] = Knight.new(:black, board.board)
        board.board[6][4] = King.new(:black, board.board, [7, 4])
        board.board[5][4] = Rook.new(:black, board.board)
        board.board[3][4] = Queen.new(:white, board.board)
        board.board[4][3] = Knight.new(:white, board.board)
        board.board[2][5] = King.new(:white, board.board, [0, 4])
        board.board[1][0] = Pawn.new(:white, board.board, [1, 0])
      end

      it_behaves_like 'black checked'
    end
  end

  describe "#legal moves" do
    before do
      board.instance_variable_set(:@board, empty_board)
      board.board[6][1] = Knight.new(:black, board.board)
      board.board[6][4] = King.new(:black, board.board, [7, 4])
      board.board[5][4] = Rook.new(:black, board.board)
      board.board[3][5] = Queen.new(:white, board.board)
      board.board[3][2] = Knight.new(:white, board.board)
      board.board[2][5] = King.new(:white, board.board, [0, 4])
      board.board[1][0] = Pawn.new(:white, board.board, [1, 0])
    end

    context 'filters out moves which would cause player to be under check' do
      it 'king moves' do
        king = board.board[6][4]
        expect(board.legal_moves(king)).to eq(Set[
          [6, 3], [7, 3], [7, 4]
        ])
      end

      it 'pawn_moves' do
        board.instance_variable_set(:@board, empty_board)
        board.board[6][0] = Bishop.new(:black, board.board)
        board.board[7][5] = King.new(:black, board.board, [7, 4])
        board.board[2][4] = Pawn.new(:white, board.board, [1, 4])
        board.board[1][5] = King.new(:white, board.board, [0, 4])

        pawn = board.board[2][4]
        expect(board.legal_moves(pawn)).to eq(Set[])
      end
    end

    it 'does not mutate the chessboard' do
      king = board.board[6][4]
      expect{ board.legal_moves(king) }.to_not change { board }
    end
  end
end
