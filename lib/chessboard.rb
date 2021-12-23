class Chessboard
  FILES = [:a, :b, :c, :d, :e, :f, :g, :h]

  def self.notation_to_indices(notation)
    invalid_notation_error = ArgumentError.new(
      "Invalid notation for chessboard square: #{notation}"
    )

    if notation.length != 2
      raise invalid_notation_error
    end

    file = FILES.find_index { |letter| letter == notation[0].downcase.to_sym }
    raise invalid_notation_error if file.nil?

    rank = notation[1].to_i - 1
    raise invalid_notation_error unless rank.between?(0, 7)

    [rank, file]
  end

  def self.indices_to_notation(rank_index, file_index)
    unless rank_index.between?(0, 7) && file_index.between?(0, 7)
      raise ArgumentError,
        "Invalid indices for chessboard square: #{[rank_index, file_index]}"
    end

    rank = (rank_index + 1).to_s
    file = FILES[file_index].to_s

    file + rank
  end
end
