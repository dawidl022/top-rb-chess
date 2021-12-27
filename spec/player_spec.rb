require_relative '../lib/player'
require_relative 'util'

RSpec.describe Player do
  include Util

  subject(:player) { described_class.new(:white) }

  describe "#colour" do
    context 'when initialised with :white' do
      it 'returns :white' do
        expect(player.colour).to eq(:white)
      end
    end

    context 'when initialised with :black' do
      subject(:player) { described_class.new(:black) }

      it 'returns :black' do
        expect(player.colour).to eq(:black)
      end
    end
  end

  describe "#move" do
    describe "prints a prompt" do
      before do
        allow(player).to receive(:gets).and_return("Bf3")
      end

      context "when the player is controlling white" do
        it 'prints "White\'s move: "' do
          expect { player.move }.to output(/White's move: /).to_stdout
        end
      end

      context "when the player is controlling black" do
        subject(:player) { described_class.new(:black) }

        it 'prints "Black\'s move: "' do
          expect { player.move }.to output(/Black's move: /).to_stdout
        end
      end
    end

    it "returns the string input by the user" do
      mute_io
      allow(player).to receive(:gets).and_return("Bf3")

      expect(player.move).to eq("Bf3")
    end

    it "returns a different string input by the user" do
      mute_io
      allow(player).to receive(:gets).and_return("Qxb5")

      expect(player.move).to eq("Qxb5")
    end

    it 'removes leading and trailing whitespace' do
      mute_io
      allow(player).to receive(:gets).and_return(" Qxb5  ")

      expect(player.move).to eq("Qxb5")
    end
  end
end
