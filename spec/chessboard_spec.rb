require_relative '../lib/chessboard'
require_relative '../boards'

RSpec.describe Chessboard do
  include Boards

  subject(:board) { described_class.new }
  # TODO stub capture board in all methods that don't need it

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

  describe ".opponent_colour" do
    context 'when supplied :white' do
      it 'returns :black' do
        expect(described_class.opponent_colour(:white)).to eq(:black)
      end
    end

    context 'when supplied :black' do
      it 'returns white' do
        expect(described_class.opponent_colour(:black)).to eq(:white)
      end
    end
  end

  describe "#move" do
    before do
      # stub time consuming method
      allow(board).to receive(:capture_board)
    end

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
          expect(response).to eq('Illegal move')
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
        it 'white pawn captures another pawn' do
          white_pawn = board.board[1][4]
          board.move('e4', :white)
          board.move('d5', :black)
          board.move('exd5', :white)
          expect(white_pawn.position).to eq([4, 3])
          expect(board.board[4][3]).to be white_pawn
          expect(board.board[3][4]).to be_nil
        end

        it 'black pawn captures another pawn' do
          black_pawn = board.board[6][4]
          board.move('e4', :white)
          board.move('e5', :black)
          board.move('d4', :white)
          board.move('exd4', :black)
          expect(black_pawn.position).to eq([3, 3])
          expect(board.board[3][3]).to be black_pawn
          expect(board.board[4][4]).to be_nil
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

          context 'when =Q is noted' do
            it 'is also accepted' do
              pawn = board.board[6][4]
              board.move('e8=Q', :white)
              expect(board.board[7][4]).to be_a(Queen)
              expect(board.board[7][4].colour).to eq(:white)
            end

            it 'is recorded without the =' do
              board.move('e8=Q+', :white)
              expect(board.moves[-1][-1]).to eq('e8Q+')
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

          context 'when piece is captured during promotion' do
            before do
              board.instance_variable_set(:@board, empty_board)
              board.board[7][2] = Knight.new(:black, board.board)
              board.board[7][5] = King.new(:black, board.board, [7, 4])
              board.board[6][3] = Pawn.new(:white, board.board, [1, 3])
              board.board[6][5] = Pawn.new(:white, board.board, [1, 5])
              board.board[5][2] = King.new(:white, board.board, [0, 4])
            end

            context 'when not given promoting piece' do
              it 'returns a message giving possible options' do
                expect(board.move('dxc8', :white)).to eq(
                  'Specify a piece to promote to: dxc8Q, dxc8R, dxc8B or dxc8N'
                )
              end
            end

            context 'when given promoting piece' do
              it 'captures and promotes' do
                pawn = board.board[6][3]
                board.move('dxc8Q', :white)
                expect(pawn.position).to be_nil
                expect(board.board[7][2]).to be_a(Queen)
                expect(board.board[7][2].colour).to eq(:white)
                expect(board.board[6][3]).to be_nil
              end
            end

            context 'when given invalid starting file' do
              it 'returns a message' do
                expect(board.move('fxc8Q', :white)).to eq('Illegal move')
              end
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
            expect(board.move('e8', :white)).to eq(
              'Specify a piece to promote to: e8Q, e8R, e8B or e8N'
            )
          end
        end

        context 'when black pawn is promoted' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[7][5] = King.new(:black, board.board, [7, 4])
            board.board[3][5] = Knight.new(:white, board.board)
            board.board[3][6] = King.new(:white, board.board, [0, 4])
            board.board[1][2] = Pawn.new(:black, board.board, [6, 2])
            board.move('Ne2', :white)
          end

          it 'promotes to given piece' do
            pawn = board.board[1][2]
            board.move('c1Q', :black)
            expect(pawn.position).to be_nil
            expect(board.board[0][2]).to be_a(Queen)
            expect(board.board[0][2].colour).to eq(:black)
            expect(board.board[1][2]).to be_nil
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
        context 'when opponents pawn first move was a capture' do
          before do
            board.board[6][4] = nil
            board.board[4][4] = Pawn.new(:white, board.board, [1, 4])
            board.board[5][5] = Pawn.new(:white, board.board, [1, 5])
            board.board[1][4] = nil
            board.board[1][5] = nil
            board.move('e6', :white)
            board.move('dxe6', :black)
          end

          it 'en passant is not possible' do
            expect(board.move('fxe7', :white)).to eq('Illegal move')
          end
        end

        context 'when opponents first move was a step forward' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[7][7] = King.new(:black, board.board, [7, 4])
            board.board[0][7] = King.new(:white, board.board, [0, 4])
            board.board[6][3] = Pawn.new(:black, board.board, [6, 3])
            board.board[5][4] = Pawn.new(:black, board.board, [1, 4])
            board.move('Kg1', :white)
            board.move('d6', :black)
          end

          it 'en passant is not possible' do
            expect(board.move('exd7', :white)).to eq('Invalid move')
          end
        end

        context 'when it is legal as white' do
          before do
            board.move('e4', :white)
            board.move('c5', :black)
            board.move('e5', :white)
            board.move('d5', :black)
            board.move('exd6', :white)
          end

          it 'is recorded with e.p.' do
            expect(board.moves).to eq([
              ['e4', 'c5'], ['e5', 'd5'], ['exd6 e.p.']
            ])
          end

          it 'removes the captured piece from the board' do
            expect(board.board[4][3]).to be_nil
          end
        end

        context 'when it is legal by black' do
          before do
            board.move('e4', :white)
            board.move('c5', :black)
            board.move('f4', :white)
            board.move('c4', :black)
            board.move('d4', :white)
            board.move('cxd3', :black)
          end

          it 'is recorded with e.p.' do
            expect(board.moves).to eq([
              ['e4', 'c5'], ['f4', 'c4'], ['d4', 'cxd3 e.p.']
            ])
          end

          it 'removes the captured piece from the board' do
            expect(board.board[3][3]).to be_nil
          end
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

      context 'capture' do
        before do
          board.move('e4', :white)
          board.move('e5', :black)
          board.move('Bb5', :white)
          board.move('a6', :black)
        end

        it 'captures the piece, but is not required to include the x' do
          bishop = board.board[4][1]
          board.move('Bd7', :white)
          expect(bishop.position).to eq([6, 3])
          expect(board.board[4][1]).to be_nil
          expect(board.board[6][3]).to be bishop
        end

        it 'captures the piece with the x' do
          bishop = board.board[4][1]
          board.move('Bxd7', :white)
          expect(bishop.position).to eq([6, 3])
          expect(board.board[4][1]).to be_nil
          expect(board.board[6][3]).to be bishop
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

    context 'castling' do
      shared_examples_for 'white castles kingside' do
        it 'is done' do
          king = board.board[0][4]
          rook = board.board[0][7]
          board.move('0-0', :white)

          expect(king.position).to eq([0, 6])
          expect(rook.position).to eq([0, 5])

          expect(board.board[0][6]).to be king
          expect(board.board[0][5]).to be rook
          expect(board.board[0][4]).to be_nil
          expect(board.board[0][7]).to be_nil
        end
      end

      context 'castling kingside' do
        context 'when it is valid' do
          before do
            board.board[0][5] = nil
            board.board[0][6] = nil

            board.board[7][5] = nil
            board.board[7][6] = nil
          end

          it_behaves_like 'white castles kingside'

          it 'black castles' do
            king = board.board[7][4]
            rook = board.board[7][7]
            board.moves << []
            board.move('0-0', :black)

            expect(king.position).to eq([7, 6])
            expect(rook.position).to eq([7, 5])

            expect(board.board[7][6]).to be king
            expect(board.board[7][5]).to be rook
            expect(board.board[7][4]).to be_nil
            expect(board.board[7][7]).to be_nil
          end
        end

        context 'when given PGN notation' do
          before do
            board.board[0][5] = nil
            board.board[0][6] = nil

            board.board[7][5] = nil
            board.board[7][6] = nil
          end

          it 'is standardized when PGN notation is provided' do
            board.move('O-O', :white)
            expect(board.moves[-1][-1]).to eq('0-0')
          end
        end

        context 'when the king is not in its starting position' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[7][0] = Bishop.new(:black, board.board)
            board.board[5][5] = King.new(:black, board.board, [7, 4])
            board.board[4][3] = Bishop.new(:white, board.board)
            board.board[1][4] = King.new(:white, board.board, [0, 4])
            board.board[1][7] = Rook.new(:white, board.board, [0, 7])
          end

          it 'return message' do
            expect(board.move('0-0', :white)).to eq('Invalid move')
          end
        end

        context 'when the king has already moved' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[7][0] = Bishop.new(:black, board.board)
            board.board[5][5] = King.new(:black, board.board, [7, 4])
            board.board[4][3] = Bishop.new(:white, board.board)
            board.board[1][4] = King.new(:white, board.board, [0, 4])
            board.board[0][7] = Rook.new(:white, board.board, [0, 7])
            board.move('Ke1', :white)
          end

          it 'returns message' do
            expect(board.move('0-0', :white)).to eq('Illegal move')
          end
        end

        context 'when the rook is not there' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[7][0] = Bishop.new(:black, board.board)
            board.board[5][5] = King.new(:black, board.board, [7, 4])
            board.board[4][3] = Bishop.new(:white, board.board)
            board.board[0][4] = King.new(:white, board.board, [0, 4])
          end

          it 'returns message' do
            expect(board.move('0-0', :white)).to eq('Invalid move')
          end
        end

        context 'when the rook has already moved' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[7][0] = Bishop.new(:black, board.board)
            board.board[5][5] = King.new(:black, board.board, [7, 4])
            board.board[4][3] = Bishop.new(:white, board.board)
            board.board[0][4] = King.new(:white, board.board, [0, 4])
            board.board[1][7] = Rook.new(:white, board.board, [0, 7])
            board.move('Rh1', :white)
          end

          it 'returns message' do
            expect(board.move('0-0', :white)).to eq('Illegal move')
          end
        end

        context 'when rook is being attacked' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[7][0] = Bishop.new(:black, board.board)
            board.board[5][5] = King.new(:black, board.board, [7, 4])
            board.board[0][4] = King.new(:white, board.board, [0, 4])
            board.board[0][7] = Rook.new(:white, board.board, [0, 7])
          end

          it_behaves_like 'white castles kingside'
        end

        context 'when king is under check' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[3][1] = Bishop.new(:black, board.board)
            board.board[5][5] = King.new(:black, board.board, [7, 4])
            board.board[0][4] = King.new(:white, board.board, [0, 4])
            board.board[0][7] = Rook.new(:white, board.board, [0, 7])
          end

          it 'returns message' do
            expect(board.move('0-0', :white)).to eq('Illegal move')
          end
        end

        context 'when king would have to move through check' do
        before do
          board.instance_variable_set(:@board, empty_board)
          board.board[3][2] = Bishop.new(:black, board.board)
          board.board[5][5] = King.new(:black, board.board, [7, 4])
          board.board[0][4] = King.new(:white, board.board, [0, 4])
          board.board[0][7] = Rook.new(:white, board.board, [0, 7])
        end

          it 'returns message' do
            expect(board.move('0-0', :white)).to eq('Illegal move')
          end
        end

        context 'attacking piece cannot move but attacks castling square' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[5][1] = King.new(:black, board.board, [7, 4])
            board.board[4][1] = Bishop.new(:black, board.board)

            board.board[0][1] = Rook.new(:white, board.board)
            board.board[0][4] = King.new(:white, board.board, [0, 4])
            board.board[0][7] = Rook.new(:white, board.board, [0, 7])
          end

          it 'returns message' do
            expect(board.move('0-0', :white)).to eq('Illegal move')
          end
        end

        context 'when ending square is under check' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[5][1] = King.new(:black, board.board, [7, 4])
            board.board[4][2] = Bishop.new(:black, board.board)

            board.board[0][4] = King.new(:white, board.board, [0, 4])
            board.board[0][7] = Rook.new(:white, board.board, [0, 7])
          end

          it 'returns message' do
            expect(board.move('0-0', :white)).to eq('Illegal move')
          end
        end
      end

      context 'castling queenside' do
        context 'when it is valid' do
          before do
            board.board[0][1] = nil
            board.board[0][2] = nil
            board.board[0][3] = nil

            board.board[7][1] = nil
            board.board[7][2] = nil
            board.board[7][3] = nil
          end

          it 'white castles queenside' do
            king = board.board[0][4]
            rook = board.board[0][0]
            board.move('0-0-0', :white)

            expect(king.position).to eq([0, 2])
            expect(rook.position).to eq([0, 3])

            expect(board.board[0][2]).to be king
            expect(board.board[0][3]).to be rook
            expect(board.board[0][4]).to be_nil
            expect(board.board[0][0]).to be_nil
          end

          it 'black castles queenside' do
            king = board.board[7][4]
            rook = board.board[7][0]
            board.moves << []
            board.move('0-0-0', :black)

            expect(king.position).to eq([7, 2])
            expect(rook.position).to eq([7, 3])

            expect(board.board[7][2]).to be king
            expect(board.board[7][3]).to be rook
            expect(board.board[7][4]).to be_nil
            expect(board.board[7][0]).to be_nil
          end
        end

        context 'when king is under check' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[3][6] = King.new(:black, board.board, [7, 4])
            board.board[2][6] = Bishop.new(:black, board.board)
            board.board[0][4] = King.new(:white, board.board, [0, 4])
            board.board[0][0] = Rook.new(:white, board.board, [0, 0])
          end

          it 'returns message' do
            expect(board.move('0-0-0', :white)).to eq('Illegal move')
          end
        end

        context 'when king would have to move through check' do
          before do
            board.instance_variable_set(:@board, empty_board)
            board.board[3][6] = King.new(:black, board.board, [7, 4])
            board.board[2][5] = Bishop.new(:black, board.board)
            board.board[0][4] = King.new(:white, board.board, [0, 4])
            board.board[0][0] = Rook.new(:white, board.board, [0, 0])
          end

          it 'returns message' do
            expect(board.move('0-0-0', :white)).to eq('Illegal move')
          end
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
      before do
        board.instance_variable_set(:@board, empty_board)
        board.board[3][6] = King.new(:black, board.board, [7, 4])
        board.board[1][6] = Bishop.new(:black, board.board)
        board.board[0][4] = King.new(:white, board.board, [0, 4])
        board.board[0][0] = Rook.new(:white, board.board, [0, 0])
      end

      it 'places a + in the notation' do
        expect do
          board.move('Kd1', :white)
          board.move('Bf3', :black)
        end.to change { board.moves }.from([]).to([
          ['Kd1', 'Bf3+']
        ])
      end

      it 'works when + is supplied in notation' do
        expect do
          board.move('Kd1', :white)
          board.move('Bf3+', :black)
        end.to change { board.moves }.from([]).to([
          ['Kd1', 'Bf3+']
        ])
      end
    end

    context 'when checkmating the opponent' do
      before do
        board.instance_variable_set(:@board, empty_board)
        board.board[7][7] = King.new(:black, board.board, [7, 4])
        board.board[0][5] = King.new(:white, board.board, [0, 4])
        board.board[5][6] = Queen.new(:white, board.board)
        board.board[3][5] = Rook.new(:white, board.board)
        board.board[2][0] = Pawn.new(:black, board.board, [6, 0])
      end

      it 'places a # in the notation' do
        expect { board.move('Rh4', :white) }.to change { board.moves }.to([
          ['Rh4#']
        ])
      end

      it 'works when # is supplied in the notation' do
        expect { board.move('Rh4#', :white) }.to change { board.moves }.to([
          ['Rh4#']
        ])
      end
    end
  end

  describe "#under_check?" do
    before do
      # stub time consuming method
      allow(board).to receive(:capture_board)
    end

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

    context 'when attacking piece is pinned' do
      before do
        board.board[6][3] = Bishop.new(:black, board.board)
        board.board[5][1] = King.new(:black, board.board, [7, 4])
        board.board[0][2] = Rook.new(:white, board.board)
        board.board[0][5] = King.new(:white, board.board, [0, 4])
        board.move('Rb1', :white)
        board.move('Bb5', :black)
      end

      it 'white should be under check' do
        expect(board).to be_under_check(:white)
      end

      it 'both checks should be recorded' do
        expect(board.moves).to eq([['Rb1+', 'Bb5+']])
      end
    end
  end

  describe "#legal moves" do
    before do
      # stub time consuming method
      allow(board).to receive(:capture_board)
    end

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

  describe "#has_moves" do
    before do
      # stub time consuming method
      allow(board).to receive(:capture_board)
    end

    context 'start of game' do
      it 'returns true for both colour' do
        expect(board.has_moves?(:white)).to be true
        expect(board.has_moves?(:black)).to be true
      end
    end

    context 'checkmate' do
      before do
        board.instance_variable_set(:@board, empty_board)
        board.board[7][7] = King.new(:black, board.board, [7, 4])
        board.board[0][5] = King.new(:white, board.board, [0, 4])
        board.board[5][6] = Queen.new(:white, board.board)
        board.board[3][7] = Rook.new(:white, board.board)
        board.board[2][0] = Pawn.new(:black, board.board, [6, 0])
      end

      it 'returns false for black' do
        expect(board.has_moves?(:black)).to be false
      end

      it 'returns true for white' do
        expect(board.has_moves?(:white)).to be true
      end
    end

    context 'stalemate' do
      before do
        board.instance_variable_set(:@board, empty_board)
        board.board[7][7] = King.new(:black, board.board, [7, 4])
        board.board[0][5] = King.new(:white, board.board, [0, 4])
        board.board[5][6] = Queen.new(:white, board.board)
        board.board[3][5] = Rook.new(:white, board.board)
      end

      it 'returns false for black' do
        expect(board.has_moves?(:black)).to be false
      end

      it 'but black is not under check' do
        expect(board).to_not be_under_check(:black)
      end
    end
  end

  describe "#checkmate?" do
    before do
      # stub time consuming method
      allow(board).to receive(:capture_board)
    end

    context 'black is checkmated' do
      before do
        board.instance_variable_set(:@board, empty_board)
        board.board[7][7] = King.new(:black, board.board, [7, 4])
        board.board[0][5] = King.new(:white, board.board, [0, 4])
        board.board[5][6] = Queen.new(:white, board.board)
        board.board[3][7] = Rook.new(:white, board.board)
        board.board[2][0] = Pawn.new(:black, board.board, [6, 0])
      end

      it 'returns true' do
        expect(board).to be_checkmate(:black)
      end
    end

    context 'black is not checkmated' do
      before do
        board.instance_variable_set(:@board, empty_board)
        board.board[7][7] = King.new(:black, board.board, [7, 4])
        board.board[0][5] = King.new(:white, board.board, [0, 4])
        board.board[5][6] = Queen.new(:white, board.board)
        board.board[2][0] = Pawn.new(:black, board.board, [6, 0])
      end

      it 'returns false' do
        expect(board).to_not be_checkmate(:black)
      end
    end
  end

  describe "#moves_since_capture_or_pawn_move" do
    before do
      # stub time consuming method
      allow(board).to receive(:capture_board)
    end

    it 'is incremented after a non-pawn move' do
      expect do
        board.move('Nc3', :white)
        board.move('Nc6', :black)
      end.to change{ board.moves_since_capture_or_pawn_move }.from(0).to(1)

      expect do
        board.move('Nf3', :white)
        board.move('Nf6', :black)
      end.to change{ board.moves_since_capture_or_pawn_move }.from(1).to(2)
    end

    it 'is reset to zero after a pawn move' do
      board.move('Nc3', :white)
      board.move('Nc6', :black)

      expect do
        board.move('e4', :white)
        board.move('e5', :black)
      end.to change{ board.moves_since_capture_or_pawn_move }.from(1).to(0)
    end

    it 'is reset to zero afer a capture' do
      board.move('Nc3', :white)
      board.move('Nf6', :black)

      expect do
        board.move('Nd5', :white)
        board.move('Nxd5', :black)
      end.to change{ board.moves_since_capture_or_pawn_move }.from(1).to(0)
    end
  end

  describe "#nfold_repetition?" do
    before do
      board.instance_variable_set(:@board, empty_board)
      board.board[1][0] = Pawn.new(:white, board.board, [1, 0])
      board.board[6][0] = Pawn.new(:black, board.board, [6, 0])
      board.board[2][4] = King.new(:white, board.board, [0, 4])
      board.board[4][4] = King.new(:black, board.board, [7, 4])
    end

    context 'when n is 3' do
      it 'true when current situation appeared 2 or more times in the past' do
        board.send(:capture_board, :black)
        2.times do
          board.move('Kf3', :white)
          board.move('Kf5', :black)
          board.move('Ke3', :white)
          board.move('Ke5', :black)
        end

        expect(board).to be_nfold_repetition(3)
      end

      it 'false when current situation appeared less than 2 times in past' do
        board.send(:capture_board, :black)
        board.move('Kf3', :white)
        board.move('Kf5', :black)
        board.move('Ke3', :white)
        board.move('Ke5', :black)

        expect(board).to_not be_nfold_repetition(3)
      end
    end
  end

  describe "#dead_position" do
    before do
      board.instance_variable_set(:@board, empty_board)
      board.board[6][3] = King.new(:black, board.board, [7, 4])
      board.board[4][3] = King.new(:white, board.board, [0, 4])
    end

    context 'when only two kings are left' do
      before do
        board.move('Ke4', :white)
        board.move('Kxd6', :black)
      end

      it { should be_dead_position }
    end

    context 'as white' do
      context 'when a king and a pawn vs a king is left' do
        before do
          board.board[5][3] = Pawn.new(:white, board.board, [1, 3])
        end

        it { should_not be_dead_position }
      end

      context 'when a king and bishop vs king are left' do
        before do
          board.board[5][3] = Bishop.new(:white, board.board)
        end

        it { should be_dead_position }
      end

      context 'when a king and knight vs king are left' do
        before do
          board.board[5][3] = Knight.new(:white, board.board)
        end

        it { should be_dead_position }
      end

      context 'when a king and rook vs king are left' do
        before do
          board.board[5][3] = Rook.new(:white, board.board)
        end

        it { should_not be_dead_position }
      end

      context 'when a king and queen vs king are left' do
        before do
          board.board[5][3] = Queen.new(:white, board.board)
        end
      end
    end

    context 'as black' do
      context 'when a king and a pawn vs a king is left' do
        before do
          board.board[5][3] = Pawn.new(:black, board.board, [6, 3])
        end

        it { should_not be_dead_position }
      end

      context 'when a king and bishop vs king are left' do
        before do
          board.board[5][3] = Bishop.new(:black, board.board)
        end

        it { should be_dead_position }
      end

      context 'when a king and knight vs king are left' do
        before do
          board.board[5][3] = Knight.new(:black, board.board)
        end

        it { should be_dead_position }
      end

      context 'when a king and rook vs king are left' do
        before do
          board.board[5][3] = Rook.new(:black, board.board)
        end

        it { should_not be_dead_position }
      end

      context 'when a king and queen vs king are left' do
        before do
          board.board[5][3] = Queen.new(:black, board.board)
        end
      end
    end
  end

  describe ".parse_pgn" do
    it 'given a valid pgn with no inline comments returns a matrix of moves' do
      pgn = <<~GAME
        [Event "USA-chJ"]
        [Site "?"]
        [Date "1955.??.??"]
        [Round "?"]
        [White "Thomason, J."]
        [Black "Fischer, Robert James"]
        [Result "0-1"]
        [WhiteElo ""]
        [BlackElo ""]
        [ECO "E91"]

        1.d4 Nf6 2.c4 g6 3.Nc3 Bg7 4.e4 d6 5.Nf3 O-O 6.Bd3 Bg4 7.O-O Nc6 8.Be3 Nd7
        9.Be2 Bxf3 10.Bxf3 e5 11.d5 Ne7 12.Be2 f5 13.f4 h6 14.Bd3 Kh7 15.Qe2 fxe4
        16.Nxe4 Nf5 17.Bd2 exf4 18.Bxf4 Ne5 19.Bc2 Nd4 20.Qd2 Nxc4 21.Qf2 Rxf4 22.Qxf4 Ne2+
        23.Kh1 Nxf4  0-1
      GAME

      expect(described_class.parse_pgn(pgn)).to eq([
        ['d4', 'Nf6'], ['c4', 'g6'], ['Nc3', 'Bg7'], ['e4', 'd6'],
        ['Nf3', '0-0'], ['Bd3', 'Bg4'], ['0-0', 'Nc6'], ['Be3', 'Nd7'],
        ['Be2', 'Bxf3'], ['Bxf3', 'e5'], ['d5', 'Ne7'], ['Be2', 'f5'],
        ['f4', 'h6'], ['Bd3', 'Kh7'], ['Qe2', 'fxe4'], ['Nxe4', 'Nf5'],
        ['Bd2', 'exf4'], ['Bxf4', 'Ne5'], ['Bc2', 'Nd4'], ['Qd2', 'Nxc4'],
        ['Qf2', 'Rxf4'], ['Qxf4', 'Ne2+'], ['Kh1', 'Nxf4']
      ])
    end

    it 'when pawn promotion is present' do
      pgn = <<~GAME
        [Event "USA-chJ"]
        [Site "?"]
        [Date "1957.??.??"]
        [Round "?"]
        [White "Thacker, R."]
        [Black "Fischer, Robert James"]
        [Result "0-1"]
        [WhiteElo ""]
        [BlackElo ""]
        [ECO "B50"]

        1.e4 c5 2.Nf3 d6 3.c3 Nf6 4.Bd3 g6 5.Bc2 Bg7 6.d4 O-O 7.h3 cxd4 8.cxd4 Nc6
        9.cxd4 Nc6 10.d5 Nd4 11.Nxd4 exd4 12.Ne2 Re8 13.f3 Qb6 14.Bd3 Nd7 15.Qa4 Rf8
        16.O-O Nc5 17.Qd1 Bd7 18.Kh1 f5 19.Ng3 Nxd3 20.Qxd3 Bb5 21.Qd1 Bxf1 22.Qxf1 f4
        23.Ne2 g5 24.Qd1 Rac8 25.Rb1 Qa6 26.Qb3 Qxe2 27.Bxf4 gxf4 28.Qxb7 d3 29.Qxa7 d2
        30.Qxg7+ Kxg7 31.Re1 dxe1=Q+ 32.Kh2  0-1
      GAME

      expect(described_class.parse_pgn(pgn)).to eq([
        ['e4', 'c5'], ['Nf3', 'd6'], ['c3', 'Nf6'], ['Bd3', 'g6'],
        ['Bc2', 'Bg7'], ['d4', '0-0'], ['h3', 'cxd4'], ['cxd4', 'Nc6'],
        ['cxd4', 'Nc6'], ['d5', 'Nd4'], ['Nxd4', 'exd4'], ['Ne2', 'Re8'],
        ['f3', 'Qb6'], ['Bd3', 'Nd7'], ['Qa4', 'Rf8'], ['0-0', 'Nc5'],
        ['Qd1', 'Bd7'], ['Kh1', 'f5'], ['Ng3', 'Nxd3'], ['Qxd3', 'Bb5'],
        ['Qd1', 'Bxf1'], ['Qxf1', 'f4'], ['Ne2', 'g5'], ['Qd1', 'Rac8'],
        ['Rb1', 'Qa6'], ['Qb3', 'Qxe2'], ['Bxf4', 'gxf4'], ['Qxb7', 'd3'],
        ['Qxa7', 'd2'], ['Qxg7+','Kxg7'], ['Re1', 'dxe1Q+'], ['Kh2']
      ])
    end

    it 'when comments are present' do
        pgn = <<~GAME
        [Event "USA-chJ"]
        [Site "?"]
        [Date "1957.??.??"]
        [Round "?"]
        [White "Thacker, R."]
        [Black "Fischer, Robert James"]
        [Result "0-1"]
        [WhiteElo ""]
        [BlackElo ""]
        [ECO "B50"]

        1.e4 c5 2.Nf3 d6 3.c3 {some comment I don't care about} Nf6 4.Bd3 g6
      GAME

      expect(described_class.parse_pgn(pgn)).to eq([
        ['e4', 'c5'], ['Nf3', 'd6'], ['c3', 'Nf6'], ['Bd3', 'g6'],
      ])
    end

    it 'when comments are at end of line and spaces after move numbers' do
      pgn = <<~GAME
        1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 {This opening is called the Ruy Lopez.}
        4. Ba4 Nf6
      GAME

      expect(described_class.parse_pgn(pgn)).to eq([
        ['e4', 'e5'], ['Nf3', 'Nc6'], ['Bb5', 'a6'], ['Ba4', 'Nf6'],
      ])
    end
  end

  describe '#to_pgn' do
    it 'returns a pgn of the current moves made on the board' do
      board.instance_variable_set(:@moves, [
        ['d4', 'Nf6'], ['c4', 'g6'], ['Nc3', 'Bg7'], ['e4', 'd6'],
        ['Nf3', '0-0'], ['Bd3', 'Bg4'], ['0-0', 'Nc6'], ['Be3', 'Nd7'],
        ['Be2', 'Bxf3'], ['Bxf3', 'e5'], ['d5', 'Ne7'], ['Be2', 'f5'],
        ['f4', 'h6'], ['Bd3', 'Kh7'], ['Qe2', 'fxe4'], ['Nxe4', 'Nf5'],
        ['Bd2', 'exf4'], ['Bxf4', 'Ne5'], ['Bc2', 'Nd4'], ['Qd2', 'Nxc4'],
        ['Qf2', 'Rxf4'], ['Qxf4', 'Ne2+'], ['Kh1', 'Nxf4']
      ])

      expect(board.to_pgn).to eq(%w[
        1.d4 Nf6 2.c4 g6 3.Nc3 Bg7 4.e4 d6 5.Nf3 O-O 6.Bd3 Bg4 7.O-O Nc6 8.Be3 Nd7
        9.Be2 Bxf3 10.Bxf3 e5 11.d5 Ne7 12.Be2 f5 13.f4 h6 14.Bd3 Kh7 15.Qe2 fxe4
        16.Nxe4 Nf5 17.Bd2 exf4 18.Bxf4 Ne5 19.Bc2 Nd4 20.Qd2 Nxc4 21.Qf2 Rxf4 22.Qxf4 Ne2+
        23.Kh1 Nxf4
      ].join(" "))
    end

    it 'returns pgn with pawn promotion notation using =' do
      board.instance_variable_set(:@moves, [
        ['e4', 'c5'], ['Nf3', 'd6'], ['c3', 'Nf6'], ['Bd3', 'g6'],
        ['Bc2', 'Bg7'], ['d4', '0-0'], ['h3', 'cxd4'], ['cxd4', 'Nc6'],
        ['cxd4', 'Nc6'], ['d5', 'Nd4'], ['Nxd4', 'exd4'], ['Ne2', 'Re8'],
        ['f3', 'Qb6'], ['Bd3', 'Nd7'], ['Qa4', 'Rf8'], ['0-0', 'Nc5'],
        ['Qd1', 'Bd7'], ['Kh1', 'f5'], ['Ng3', 'Nxd3'], ['Qxd3', 'Bb5'],
        ['Qd1', 'Bxf1'], ['Qxf1', 'f4'], ['Ne2', 'g5'], ['Qd1', 'Rac8'],
        ['Rb1', 'Qa6'], ['Qb3', 'Qxe2'], ['Bxf4', 'gxf4'], ['Qxb7', 'd3'],
        ['Qxa7', 'd2'], ['Qxg7+','Kxg7'], ['Re1', 'dxe1Q+'], ['Kh2']
      ])

      expect(board.to_pgn).to eq(%w[
        1.e4 c5 2.Nf3 d6 3.c3 Nf6 4.Bd3 g6 5.Bc2 Bg7 6.d4 O-O 7.h3 cxd4 8.cxd4 Nc6
        9.cxd4 Nc6 10.d5 Nd4 11.Nxd4 exd4 12.Ne2 Re8 13.f3 Qb6 14.Bd3 Nd7 15.Qa4 Rf8
        16.O-O Nc5 17.Qd1 Bd7 18.Kh1 f5 19.Ng3 Nxd3 20.Qxd3 Bb5 21.Qd1 Bxf1 22.Qxf1 f4
        23.Ne2 g5 24.Qd1 Rac8 25.Rb1 Qa6 26.Qb3 Qxe2 27.Bxf4 gxf4 28.Qxb7 d3 29.Qxa7 d2
        30.Qxg7+ Kxg7 31.Re1 dxe1=Q+ 32.Kh2
      ].join(" "))
    end
  end

  describe '.from_pgn' do
    let(:pgn) do
      <<~GAME
        [Event "USA-chJ"]
        [Site "?"]
        [Date "1955.??.??"]
        [Round "?"]
        [White "Thomason, J."]
        [Black "Fischer, Robert James"]
        [Result "0-1"]
        [WhiteElo ""]
        [BlackElo ""]
        [ECO "E91"]

        1.d4 Nf6 2.c4 g6 3.Nc3 Bg7 4.e4 d6 5.Nf3 O-O 6.Bd3 Bg4 7.O-O Nc6 8.Be3 Nd7
        9.Be2 Bxf3 10.Bxf3 e5 11.d5 Ne7 12.Be2 f5 13.f4 h6 14.Bd3 Kh7 15.Qe2 fxe4
        16.Nxe4 Nf5 17.Bd2 exf4 18.Bxf4 Ne5 19.Bc2 Nd4 20.Qd2 Nxc4 21.Qf2 Rxf4 22.Qxf4 Ne2+
        23.Kh1 Nxf4  0-1
      GAME
    end

    subject(:board) { described_class.from_pgn(pgn) }

    it 'sets the board to the final position in pgn and sets move history' do
      # two tests kept under one to increase performance
      expect(board.board[0][0]).to be_a(Rook)
        .and(have_attributes(colour: :white))
      expect(board.board[0][5]).to be_a(Rook)
        .and(have_attributes(colour: :white))
      expect(board.board[0][7]).to be_a(King)
        .and(have_attributes(colour: :white))
      expect(board.board[1][0]).to be_a(Pawn)
        .and(have_attributes(colour: :white))
      expect(board.board[1][1]).to be_a(Pawn)
        .and(have_attributes(colour: :white))
      expect(board.board[1][2]).to be_a(Bishop)
        .and(have_attributes(colour: :white))
      expect(board.board[1][6]).to be_a(Pawn)
        .and(have_attributes(colour: :white))
      expect(board.board[1][7]).to be_a(Pawn)
        .and(have_attributes(colour: :white))
      expect(board.board[3][2]).to be_a(Knight)
        .and(have_attributes(colour: :black))
      expect(board.board[3][4]).to be_a(Knight)
        .and(have_attributes(colour: :white))
      expect(board.board[3][5]).to be_a(Knight)
        .and(have_attributes(colour: :black))
      expect(board.board[4][3]).to be_a(Pawn)
        .and(have_attributes(colour: :white))
      expect(board.board[5][3]).to be_a(Pawn)
        .and(have_attributes(colour: :black))
      expect(board.board[5][6]).to be_a(Pawn)
        .and(have_attributes(colour: :black))
      expect(board.board[5][7]).to be_a(Pawn)
        .and(have_attributes(colour: :black))
      expect(board.board[6][0]).to be_a(Pawn)
        .and(have_attributes(colour: :black))
      expect(board.board[6][1]).to be_a(Pawn)
        .and(have_attributes(colour: :black))
      expect(board.board[6][2]).to be_a(Pawn)
        .and(have_attributes(colour: :black))
      expect(board.board[6][6]).to be_a(Bishop)
        .and(have_attributes(colour: :black))
      expect(board.board[6][7]).to be_a(King)
        .and(have_attributes(colour: :black))
      expect(board.board[7][0]).to be_a(Rook)
        .and(have_attributes(colour: :black))
      expect(board.board[7][3]).to be_a(Queen )
        .and(have_attributes(colour: :black))

      expect(board.moves).to eq([
        ['d4', 'Nf6'], ['c4', 'g6'], ['Nc3', 'Bg7'], ['e4', 'd6'],
        ['Nf3', '0-0'], ['Bd3', 'Bg4'], ['0-0', 'Nc6'], ['Be3', 'Nd7'],
        ['Be2', 'Bxf3'], ['Bxf3', 'e5'], ['d5', 'Ne7'], ['Be2', 'f5'],
        ['f4', 'h6'], ['Bd3', 'Kh7'], ['Qe2', 'fxe4'], ['Nxe4', 'Nf5'],
        ['Bd2', 'exf4'], ['Bxf4', 'Ne5'], ['Bc2', 'Nd4'], ['Qd2', 'Nxc4'],
        ['Qf2', 'Rxf4'], ['Qxf4', 'Ne2+'], ['Kh1', 'Nxf4']
      ])
    end

    context 'illegal move in pgn' do
      it 'raises error with message' do
        expect { described_class.from_pgn('1. e8 ') }.to raise_error(
          ArgumentError, 'Incompatible PGN notation supplied'
        )
      end
    end
  end
end
