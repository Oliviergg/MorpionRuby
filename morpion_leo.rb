module MorpionLeo
  class Box
    attr_accessor :i, :j, :player, :alignments
    def initialize(i:, j:)
      self.i = i
      self.j = j
      self.player = :none
      self.alignments = []
    end
    def belongs_to(alignment)
      alignment.boxes << self
      alignments << alignment
    end
    def to_s
      case player
      when :none
        ' '
      when :player_one
        'O'
      when :player_two
        'X'
      end
    end
  end

  class Board
    attr_accessor :boxes, :alignments
    def initialize
      self.boxes = []
      (0 .. 9).each do |i|
        self.boxes << (0 .. 9).map { |j| Box.new(i: i, j: j) }
      end
      self.alignments = []
      (0 .. 9).each do |i|
        (0 .. 5).each do |j|
          alignment = Alignment.new
          (0 .. 4).each { |k| self.boxes[i][j + k].belongs_to(alignment) }
          self.alignments << alignment
        end
      end
      (0 .. 5).each do |i|
        (0 .. 9).each do |j|
          alignment = Alignment.new
          (0 .. 4).each { |k| self.boxes[i + k][j].belongs_to(alignment) }
          self.alignments << alignment
        end
      end
      (0 .. 5).each do |i|
        (0 .. 5).each do |j|
          alignment = Alignment.new
          (0 .. 4).each { |k| self.boxes[i + k][j + k].belongs_to(alignment) }
          self.alignments << alignment
        end
      end
      (0 .. 5).each do |i|
        (0 .. 5).each do |j|
          alignment = Alignment.new
          (0 .. 4).each { |k| self.boxes[i + k][4 + j - k].belongs_to(alignment) }
          self.alignments << alignment
        end
      end
    end
    def is_free?(pos_x, pos_y)
      self.boxes[pos_y][pos_x].player == :none
    end
    def set_box(pos_x, pos_y, player)
      self.boxes[pos_y][pos_x].player = player
    end
    def computer_priority
      tab_ref_player_one_value, tab_ref_player_two_value, tab_score, tab_best_score = [1, 2, 50, 500, 100000], [2, 4, 100, 1000, 200000], [], []
      (0 .. 9).each do |i|
        (0 .. 9).each do |j|
          if boxes[j][i].player == :none
            current_score = 0
            boxes[j][i].alignments.each do |alignment|
              unless alignment.is_tie?
                player_one_s_alignment = alignment.boxes.select { |box| box.player == :player_one }
                player_two_s_alignment = alignment.boxes.select { |box| box.player == :player_two }
                if player_one_s_alignment.count > 0
                  current_score += tab_ref_player_one_value[player_one_s_alignment.count]
                elsif player_two_s_alignment.count > 0
                  current_score += tab_ref_player_two_value[player_two_s_alignment.count]
                else
                  current_score += tab_ref_player_one_value[0]
                end
              end
            end
            tab_score << { score: current_score, pos_x: i, pos_y: j }
          end
        end
      end
      tab_score = tab_score.sort_by { |hash| hash[:score] }.reverse
      tab_best_score << tab_score[0]
      (0 .. tab_score.length - 2).each do |i|
        if tab_score[i][:score] == tab_score[i + 1][:score]
          tab_best_score << tab_score[i + 1]
        else
          break
        end
      end
      tab_best_score[Random.rand(tab_best_score.length)]
    end
    def winning_shot
      result = alignments.select { |alignment| alignment.is_won? }
      result.count > 0
    end
    def tying_shot
      result = alignments.select { |alignment| !alignment.is_tie? }
      result.count == 0
    end
    def game_over(winner_s_nickname)
      puts "Game over! Winner is #{winner_s_nickname}!"
    end
    def to_s
      s_col_sep = ' | '
      s_row_sep = "\n"
      (0 .. 9).map { |i| (0 .. 9).map { |j| self.boxes[i][j] }.join(s_col_sep) }.join(s_row_sep) # Affiche la board
    end
  end

  class Alignment
    attr_accessor :boxes
    def initialize
      self.boxes = []
    end
    def is_won?
      combination = boxes.map(& :player).uniq
      combination.count == 1 && combination.first != :none
    end
    def is_tie?
      combination = boxes.map(& :player).uniq
      combination.include?(:player_one) && combination.include?(:player_two)
    end
  end

  class Game
    attr_accessor :board, :alignments
    def initialize
      self.board = Board.new
      @game_over = false
    end
    def play(i, j)
      pos_x, pos_y = j, i
      if !@game_over
        if self.board.is_free?(pos_x, pos_y)
          self.board.set_box(pos_x, pos_y, :player_one)
          if self.board.winning_shot
            self.board.game_over(:player_one)
            @game_over = true
            show_board
            return { status: :user_won, i: pos_y, j: pos_x }
          elsif self.board.tying_shot
            puts 'Sorry, no winner this time'
            @game_over = true
            show_board
            return { status: :tie, i: pos_y, j: pos_x }
          end
        else
          puts 'Box not free, try again...'
        end
        { status: :continue, i: pos_y, j: pos_x }
      else
        puts 'Game is over, launch a new one if you want to play'
      end
    end
    def play_computer
      if !@game_over
        best_box_to_play = self.board.computer_priority
        self.board.set_box(best_box_to_play[:pos_x], best_box_to_play[:pos_y], :player_two)
        if self.board.winning_shot
          self.board.game_over(:player_two)
          @game_over = true
          show_board
          return { status: :computer_won, i: best_box_to_play[:pos_y], j: best_box_to_play[:pos_x] }
        elsif self.board.tying_shot
          puts 'Sorry, no winner this time'
          @game_over = true
          show_board
          return { status: :tie, i: best_box_to_play[:pos_y], j: best_box_to_play[:pos_x] }
        end
      end
      { status: :continue, i: best_box_to_play[:pos_y], j: best_box_to_play[:pos_x] }
    end
    def show_board
      puts self.board
    end
  end
end