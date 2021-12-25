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
        expect(board.board[3][4]).to be pawn
        expect(board.board[1][4]).to be_nil
      end

      it 'moves another white pawn forward by providing chess notation' do
        pawn = board.board[1][0]
        board.move('a3', :white)
        expect(pawn.position).to eq([2, 0])
      end

      it 'moves a black pawn forward by providing chess notation' do
        pawn = board.board[6][4]
        board.moves << []
        board.move('e5', :black)
        expect(pawn.position).to eq([4, 4])
      end

      it 'moves another black pawn forward by providing chess notation' do
        pawn = board.board[6][4]
        board.moves << []
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

      context 'capture' do
        it 'pawn captures another pawn' do
          white_pawn = board.board[1][4]
          board.move('e4', :white)
          board.move('d5', :black)
          board.move('exd5', :white)
          expect(white_pawn.position).to eq([4, 3])
          expect(board.board[4][3]).to be white_pawn
          expect(board.board[3][4]).to be_nil
        end
      end

      context 'promotion' do
        context 'when given promoting piece' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[5][2] = King.new(:black, board.board, [7, 4])
            board.board[5][5] = King.new(:white, board.board, [0, 4])
            board.board[6][4] = Pawn.new(:white, board.board, [1, 3])
          end

          it 'removes the pawn from the board' do
            pawn = board.board[6][4]
            board.move('e8Q', :white)
            expect(pawn.position).to be_nil
          end

          context 'when Q is noted' do
            it 'place a white queen on the board' do
              pawn = board.board[6][4]
              board.move('e8Q', :white)
              expect(board.board[7][4]).to be_a(Queen)
              expect(board.board[7][4].colour).to eq(:white)
            end
          end

          context 'when R is noted' do
            it 'place a rook on the board' do
              pawn = board.board[6][4]
              board.move('e8R', :white)
              expect(board.board[7][4]).to be_a(Rook)
            end
          end

          context 'when B is noted' do
            it 'place a bishop on the board' do
              pawn = board.board[6][4]
              board.move('e8B', :white)
              expect(board.board[7][4]).to be_a(Bishop)
            end
          end

          context 'when N is noted' do
            it 'place a knight on the board' do
              pawn = board.board[6][4]
              board.move('e8N', :white)
              expect(board.board[7][4]).to be_a(Knight)
            end
          end

          context 'when given an invalid piece to promote to' do
            it 'returns a message' do
              pawn = board.board[6][4]
              expect(board.move('e8K', :white)).to eq('Invalid promotion piece')
            end

            it 'does not move the pawn' do
              pawn = board.board[6][4]
              expect { board.move('e8K', :white) }.to_not change { board.board }
              expect { board.move('e8K', :white) }
                .to_not change { pawn.position }
            end
          end

        end
        context 'when not given promoting piece' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[5][2] = King.new(:black, board.board, [7, 4])
            board.board[5][5] = King.new(:white, board.board, [0, 4])
            board.board[6][4] = Pawn.new(:white, board.board, [1, 3])
          end

          it 'returns a message giving possible options' do
            pawn = board.board[6][4]
            expect(board.move('e8', :white)).to eq(
              'Specify a piece to promote to: e8Q, e8R, e8B or e8N'
            )
          end
        end
      end
    end

    describe 'saves moves to move history matrix' do
      describe 'sequence of pawn moves and captures' do
        it 'is recorded as entered' do
          expect do
            board.move('e4', :white)
            board.move('d5', :black)
            board.move('exd5', :white)
          end.to change { board.moves }.from([]).to([['e4', 'd5'], ['exd5']])
        end
      end

      context 'en passant' do
        it 'is recorded with e.p.' do
          expect do
            board.move('e4', :white)
            board.move('c5', :black)
            board.move('e5', :white)
            board.move('d5', :black)
            board.move('exd6', :white)
          end.to change { board.moves }.from([]).to([
            ['e4', 'c5'], ['e5', 'd5'], ['exd6 e.p.']
          ])
        end
      end
    end

    describe "Knight" do
      context 'when it is unambiguous' do
        context 'on a starting board as white' do
          it 'moves Knight to c3' do
            knight = board.board[0][1]
            board.move("Nc3", :white)
            expect(knight.position).to eq([2, 2])
            expect(board.board[2][2]).to be knight
            expect(board.board[0][1]).to be_nil
          end
        end


        context 'on a starting board as black' do
          it 'moves Knight to f6' do
            knight = board.board[7][6]
            board.move("Nc3", :white)
            board.move("Nf6", :black)
            expect(knight.position).to eq([5, 5])
            expect(board.board[5][5]).to be knight
            expect(board.board[7][6]).to be_nil
          end
        end
      end

      context 'when additional notation is supplied to disambiguate' do
        before do
          board.instance_variable_set(:@board, empty_board)
          board.board[2][2] = Knight.new(:white, board.board)
          board.board[2][4] = Knight.new(:white, board.board)
          board.board[6][2] = Knight.new(:white, board.board)
          board.board[0][5] = King.new(:white, board.board, [0, 4])
          board.board[7][6] = King.new(:black, board.board, [7, 4])
          board.board[6][6] = Pawn.new(:black, board.board, [6, 6])
        end

        it 'moves knight e3 to d5' do
          knight = board.board[2][4]
          board.move('Ned5', :white)
          expect(knight.position).to eq([4, 3])
          expect(board.board[4][3]).to be knight
          expect(board.board[2][4]).to be_nil
        end

        it 'moves knight c7 to d5' do
          knight = board.board[6][2]
          board.move('N7d5', :white)
          expect(knight.position).to eq([4, 3])
          expect(board.board[4][3]).to be knight
          expect(board.board[6][2]).to be_nil
        end

        it 'moves knight c3 to d5' do
          knight = board.board[2][2]
          board.move('Nc3d5', :white)
          expect(knight.position).to eq([4, 3])
          expect(board.board[4][3]).to be knight
          expect(board.board[2][2]).to be_nil
        end
      end

      context 'when redundant disambiguation is supplied' do
        context 'on a starting board as white' do
          it 'moves Knight to c3' do
            knight = board.board[0][1]
            board.move("Nb1c3", :white)
            expect(knight.position).to eq([2, 2])
            expect(board.board[2][2]).to be knight
            expect(board.board[0][1]).to be_nil
          end

          it 'records move without redundancy'
        end
      end

      context 'when it is ambiguous' do
        before do
          board.instance_variable_set(:@board, empty_board)
          board.board[2][2] = Knight.new(:white, board.board)
          board.board[2][4] = Knight.new(:white, board.board)
          board.board[6][2] = Knight.new(:white, board.board)
          board.board[0][5] = King.new(:white, board.board, [0, 4])
          board.board[7][6] = King.new(:black, board.board, [7, 4])
          board.board[6][6] = Pawn.new(:black, board.board, [6, 6])
        end

        it 'returns a message' do
          expect(board.move('Nd5', :white)). to eq(
            'Multiple knights can go to d5, please disambiguate'
          )
        end

        it 'does not move any piece' do
          expect { board.move('Nd5', :white) }.to_not change { board.board }
        end
      end

      context 'when move causes player to be under check' do
        before do
          board.instance_variable_set(:@board, empty_board)
          board.board[7][2] = King.new(:black, board.board, [7, 4])
          board.board[2][0] = Rook.new(:black, board.board)
          board.board[2][3] = Knight.new(:white, board.board)
          board.board[2][4] = King.new(:white, board.board, [0, 4])
        end

        it 'knight cannot move' do
          expect(board.move('Nc5', :white)).to eq('Illegal move')
        end

        it 'board is unchanged' do
          expect { board.move('Nc5', :white) }.to_not change { board.board }
        end
      end

      context 'invalid' do
        context 'no knight can access that square' do
          it 'returns message' do
            expect(board.move('Nd5', :white)).to eq('Illegal move')
          end
        end

        context 'there is no knight of that colour on the board' do
          before do
            board.instance_variable_set(:@board, empty_board)
          end

          it 'returns message' do
            expect(board.move('Nd5', :white)).to eq('Illegal move')
          end
        end
      end
    end

    describe "Bishop" do
      context 'when it is unambiguous' do
        before do
          board.instance_variable_set(:@board, empty_board)
          board.board[7][7] = King.new(:black, board.board, [7, 4])
          board.board[6][0] = Rook.new(:black, board.board)
          board.board[3][1] = Bishop.new(:white, board. board)
          board.board[2][4] = King.new(:white, board.board, [[0, 4]])
        end

        it 'moves bishop to c5' do
          bishop = board.board[3][1]
          board.move('Bc5', :white)
          expect(bishop.position).to eq([4, 2])
          expect(board.board[4][2]).to be bishop
          expect(board.board[3][1]).to be_nil
        end
      end

      context 'when additional notation is supplied to disambiguate' do
        before do
          board.instance_variable_set(:@board, empty_board)
          board.board[7][6] = King.new(:black, board.board, [7, 4])
          board.board[0][5] = King.new(:white, board.board, [0, 4])
          board.board[6][0] = Rook.new(:black, board.board)

          board.board[4][2] = Bishop.new(:white, board.board)
          board.board[4][4] = Bishop.new(:white, board.board)
          board.board[6][4] = Bishop.new(:white, board.board)
        end

        it 'moves bishop c5 to d6' do
          bishop = board.board[4][2]
          board.move('Bcd6', :white)
          expect(bishop.position).to eq([5, 3])
          expect(board.board[5][3]).to be bishop
          expect(board.board[4][2]).to be_nil
        end

        it 'moves bishop e7 to d6' do
          bishop = board.board[6][4]
          board.move('B7d6', :white)
          expect(bishop.position).to eq([5, 3])
          expect(board.board[5][3]).to be bishop
          expect(board.board[6][4]).to be_nil
        end

        it 'moves bishop e5 to d6' do
          bishop = board.board[4][4]
          board.move('Be5d6', :white)
          expect(bishop.position).to eq([5, 3])
          expect(board.board[5][3]).to be bishop
          expect(board.board[4][4]).to be_nil
        end
      end

      context 'when it is ambiguous' do
        before do
          board.instance_variable_set(:@board, empty_board)
          board.board[7][6] = King.new(:black, board.board, [7, 4])
          board.board[0][5] = King.new(:white, board.board, [0, 4])
          board.board[6][0] = Rook.new(:black, board.board)

          board.board[4][2] = Bishop.new(:white, board.board)
          board.board[4][4] = Bishop.new(:white, board.board)
          board.board[6][4] = Bishop.new(:white, board.board)
        end

        it 'returns a message' do
          expect(board.move('Bd6', :white)). to eq(
            'Multiple bishops can go to d6, please disambiguate'
          )
        end

        it 'does not move any piece' do
          expect { board.move('Bd6', :white) }.to_not change { board.board }
        end
      end

      context 'when move causes player to be under check' do
        before do
          board.instance_variable_set(:@board, empty_board)
          board.board[7][0] = Bishop.new(:black, board.board)
          board.board[4][3] = Bishop.new(:white, board.board)
          board.board[5][6] = King.new(:black, board.board, [7, 4])
          board.board[3][4] = King.new(:white, board.board, [0, 4])
        end

        it 'knight cannot move' do
          expect(board.move('Bc4', :white)).to eq('Illegal move')
        end

        it 'board is unchanged' do
          expect { board.move('Bc4', :white) }.to_not change { board.board }
        end
      end
    end

    context 'completely invalid notation' do
      it 'returns message' do
        expect(board.move('Ad4', :white)).to eq('Invalid move')
        expect(board.move('qwerty', :black)).to eq('Invalid move')
        expect(board.move('Hello world', :white)).to eq('Invalid move')
      end
    end

    context 'when checking opponent' do
      it 'places a + in the notation'
      it 'returns a message'
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
      expect{ board.legal_moves(king) }.to_not change { board.board }
    end
  end
end
