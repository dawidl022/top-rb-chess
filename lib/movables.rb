
module MovableStraight
  private

  def straight_moves
    moves = Set[]

    moves.merge(file_moves_left)
    moves.merge(file_moves_right)
    moves.merge(rank_moves_up)
    moves.merge(rank_moves_down)
  end

  def file_moves_left
    file_moves(:-)
  end

  def file_moves_right
    file_moves(:+)
  end

  def rank_moves_up
    rank_moves(:+)
  end

  def rank_moves_down
    rank_moves(:-)
  end

  def file_moves(op)
    moves =  Set[]
    file = @file.send(op, 1)

    while file >= 0 && file <= 7 && !@board[@rank][file]
      moves.add([@rank, file])
      file = file.send(op, 1)
    end

    # include capture move
    if file >= 0 && file <= 7 && @board[@rank][file].colour != @colour
      moves.add([@rank, file])
    end

    moves
  end

  def rank_moves(op)
    moves =  Set[]
    rank = @rank.send(op, 1)

    while rank >= 0 && rank <= 7 && !@board[rank][@file]
      moves.add([rank, @file])
      rank = rank.send(op, 1)
    end

    # include capture move
    if rank >= 0 && rank <= 7 && @board[rank][@file].colour != @colour
      moves.add([rank, @file])
    end

    moves
  end
end

module MovableDiagonal
  private

  def diagonal_moves
    moves = Set[]

    [:+, :-].each do |rank_op|
      [:+, :-].each do |file_op|
        moves.merge(diagonal(rank_op, file_op))
      end
    end

    moves
  end

  def diagonal(rank_op, file_op)
    moves =  Set[]
    rank = @rank.send(rank_op, 1)
    file = @file.send(file_op, 1)

    while rank >= 0 && rank <= 7 && file >= 0 && file <= 7 \
    && !@board[rank][file]
      moves.add([rank, file])
      rank = rank.send(rank_op, 1)
      file = file.send(file_op, 1)
    end

    # include capture move
    if rank >= 0 && rank <= 7 && file >= 0 && file <= 7 \
    && @board[rank][file].colour != @colour
      moves.add([rank, file])
    end

    moves
  end
end
