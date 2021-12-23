require_relative '../lib/chessboard'

RSpec.describe Chessboard do
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
end
