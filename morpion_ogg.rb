module MorpionOgg
  class Board

    attr_accessor :boxes
    attr_accessor :alignments

    attr_accessor :imax, :jmax

    def initialize(isize, jsize)
      self.imax = isize - 1
      self.jmax = jsize - 1

      self.boxes = (0 .. imax).map { |i| (0 .. jmax).map { |j| Box.new(i: i, j: j) } }
                      
      self.alignments = []
      (0 .. imax).each do |i|
        (0 .. jmax - Alignment.al_size + 1).each do |j|
          al = Alignment.new
          (0 .. Alignment.al_size-1).each { |offset| box( i, j+offset ).belongs_to(al) }
          self.alignments << al
        end
      end

      (0 .. jmax).each do |j|
        (0 .. imax - Alignment.al_size + 1).each do |i|
          al = Alignment.new
          (0 .. Alignment.al_size-1).each { |offset| box( i+offset, j ).belongs_to(al) }
          self.alignments << al
        end
      end

      (0 .. imax - Alignment.al_size + 1).each do |i|
        (0 .. jmax - Alignment.al_size + 1).each do |j|
          al = Alignment.new
          (0 .. Alignment.al_size-1).each {|offset| box( i+offset, j+offset ).belongs_to(al) } 
          self.alignments << al
        end

      end

      (0 .. imax - Alignment.al_size + 1).each do |i|
        (0 .. jmax - Alignment.al_size + 1).each do |j|
          al = Alignment.new
          (0 .. Alignment.al_size - 1).each { |offset| box( imax-(i+offset), j+offset ).belongs_to(al) }
          self.alignments << al
        end
      end

    end

    def box(i,j)
      boxes[i][j]
    end

    def find_best_box
      box_values = []
      (0..imax).each do |i|
        (0..jmax).each do |j|
          box = box(i,j)
          if box.is_empty?
            box_values << {box: box, value: box.score}
          end
        end
      end
      selected_boxes = box_values.sort {|a,b| b[:value] <=> a[:value]} 
      max_value = selected_boxes.first[:value]
      selected = selected_boxes.select {|b| b[:value] == max_value }.sample
      return selected[:box]
    end

    def to_s
      col_sep = "|"
      row_sep = "\n+#{"---+" * (jmax+1)}\n"
      
      row_sep + (0..imax).map { |i| col_sep + (0..jmax).map { |j| "%2s " % box(i,j) }.join(col_sep) + col_sep }.join(row_sep) + row_sep

    end


    def debug_alignements
      self.alignments.each do |al|
        str = ""
        boxes = al.boxes.map {|box| "#{box.i}-#{box.j}"}
        (0..self.imax).each do |i|
          (0..self.jmax).each do |j|
            str += boxes.include?("#{i}-#{j}") ? "X" : "."
          end
          str+="\n"
        end
        print str
        print "\n"
      end
      nil
    end


    def debug_boxes
      (0..self.imax).each do |i|
        (0..self.jmax).each do |j|
          boxes = self.box(i,j).alignments.map(&:boxes).flatten.map {|box| "#{box.i}-#{box.j}"}.uniq
          str = ""
          (0..self.imax).each do |ib|
            (0..self.jmax).each do |jb|
              str += boxes.include?("#{ib}-#{jb}") ? "X" : "."
            end
            str+="\n"
          end
          print str
          print "\n"
         end
       end
       nil
    end


  end

  class Box
    attr_accessor :i, :j, :player, :alignments

    def initialize(i:,j:)
      self.i = i
      self.j = j
      self.player = :none
      self.alignments = []
    end

    def belongs_to(alignment)
      alignment.boxes << self
      alignments << alignment
    end
    
    def set_player(player)
      if self.is_empty?
        self.player = player
        { i: self.i, j: self.j, status: :ok}
      else
        { i: self.i, j: self.j, status: :not_empty}
      end
    end

    def is_empty?
      return player == :none
    end

    def score
      alignments.reduce(0) { |score,al| score += al.weight }
    end

    def to_s
      case player
      when :user
        "X"
      when :computer
        "O"
      when :none
        "."
      end     
    end   
  end

  class Alignment
    attr_accessor :boxes

    def self.al_size=(al_size)
      @@al_size = al_size
    end
    
    def self.al_size
      @@al_size
    end

    def weights_user
      @weight_user ||= [nil,1,2,50,500,99999]
    end

    def weights_computer
      @weight_computer ||= [nil,1,5,100,500,99999]
    end


    def initialize
      self.boxes = []
    end
    
    def calculate
      self.boxes.map(&:player).inject(Hash.new(0)) { |total, e| total[e] += 1 ;total}
    end

    def weight
      w = self.calculate 
      score = 0
      if w[:user] > 0 && w[:computer] > 0
        score = 0
      elsif w[:user] > 0
        score = self.weights_user[w[:user]+1]
      else
        score = self.weights_computer[w[:computer]+1]
      end
      return score
    end

    def is_won_by?(player)
      self.calculate[player] == Alignment.al_size
    end

    def is_tie?
      w = self.calculate
      w[:user] > 0 && w[:computer] > 0
    end

  end


  class Game
    attr_accessor :board
    attr_accessor :alignments

    def initialize(isize: 10, jsize:10, al_size:5)
      Alignment.al_size = al_size
      self.board = Board.new(isize, jsize)
    end

    def play(i,j)
      response = board.box(i,j).set_player(:user)
      if response[:status] == :not_empty
        raise "Box #{i},#{j} not empty"
      end

      if (check = check_end)[:result] == :end
        print board
      end
      {status: check[:status], i: response[:i], j: response[:j]}

    end

    def play_computer
      response = board.find_best_box.set_player(:computer)
      
      if (check = check_end)[:result] == :end
        print board
      end
      {status: check[:status], i: response[:i], j: response[:j]}
    end

    def check_end
      not_tie = board.alignments.select {|al| !al.is_tie?}
      return {result: :end, status: :tie} if not_tie.count == 0

      won_by_user = board.alignments.select { |al| al.is_won_by?(:user) }
      return {result: :end, status: :user_won} if won_by_user.count > 0

      won_by_computer = board.alignments.select {|al| al.is_won_by?(:computer) }
      return {result: :end, status: :computer_won} if won_by_computer.count > 0
        
      {result: :continue,status: :continue}
    end

  end

end