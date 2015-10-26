module MorpionAlex	
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
	    def initialize
	      self.boxes = []
	    end

	    def is_won?
	    	v = boxes.map(&:player).uniq
	    	v.count == 1 && v.first != :none
	    end

	    def is_tie?
	    	t = boxes.map(&:player).uniq
	    	t.count < 2
	    end
  	end


	class Board 
			attr_accessor :boxes
	    	attr_accessor :alignments
		def initialize
			self.boxes = []
			(0 .. 9).each do |i|
				self.boxes << (0 .. 9).map { |j| Box.new(i: i, j: j) }
			end

			self.alignments = []
      
		    (0 .. 9).each do |i|
		        (0 .. 5).each do |j|
			        row = Alignment.new
			        (0 .. 4).each { |offset| box( i, j+offset ).belongs_to(row) }
			        self.alignments << row
		        end
		    end

		    (0..9).each do |i|
		      	(0..5).each do |j|
		      		col = Alignment.new
		      		(0..4).each { |offset| box(j+offset, i).belongs_to(col)}
		      		self.alignments << col 
		    	end
		    end

	    	(0..5).each do |i|
	    		(0..5).each do |j|
	    			diag_sup_right = Alignment.new
	    			(0..4).each do |offset|
	    				box(offset+i, j+offset).belongs_to(diag_sup_right)
	    			end
	    			self.alignments << diag_sup_right 
	    		end
	    	end

	    	(0..5).each do |i|
	    		(0..5).each do |j|
	    			diag_inf_left = Alignment.new
	    			(0..4).each do |offset|
	    				box(j+offset, 9-(i+offset)).belongs_to(diag_inf_left)
	    			end
	    			self.alignments << diag_inf_left
	    		end
	    	end
		end 

    	def find_best_box
	    	weight_user = [10,100,1000,10000,100000]
	    	weight_computer = [5,50,500,5000,50000]
	    	weight_boxes = []
	    	(0..9).each do |i|
	    		(0..9).each do |j|
	    			if self.box(i,j).player == :none
		    			price =0
		    			box(i,j).alignments.each do |al|
							user = al.boxes.select{|p| p.player == :user }
							computer = al.boxes.select{|p| p.player == :computer}
							if computer.count !=0 && user.count ==0
			    				price += weight_computer[computer.count]
			    			elsif computer.count ==0 && user.count !=0
			    				price += weight_user[user.count]
			    			end
			    		end
			    		hash = {weight: price, i: i, j: j}
			    		weight_boxes << hash
			 		end
	    		end
	    	end
	    	all_value = weight_boxes.sort_by{ |w| w[:weight] }
	    	one_of_best_boxes = weight_boxes.sort_by{ |w| w[:weight] }.last
	    	one_of_best_boxes[:weight]
	    	a = weight_boxes.select{|w| w[:weight] == one_of_best_boxes[:weight]}
	    	box=a.shuffle.first
	    	i = box[:i]
	    	j = box[:j]
	    	str = " -----------------------------------------\n"
	    	weight_boxes.each_with_index do |w, i|
				unless w[:j] == 9
					str += " | #{w[:weight]}"
				end
				str += "\n" if i.modulo(10) == 0	
			end
			str
	    	return i, j
	  	end

		def box(i,j)
      		boxes[i][j]
    	end

		def to_s
			str = " -----------------------------------------\n"
			(0..9).each do |i|
				(0..9).each do |j|
					str += " | #{self.boxes[i][j]}"
				end
				str += " | \n ----------------------------------------- \n"
			end
			str
		end

		def is_game_over
			result = alignments.select{|a| a.is_won?}
			result.count > 0
		end

		def is_tie
			result = alignments.select{|t| t.is_tie?}
			result.count > 0
		end
	end


	class Game
			attr_accessor :board
		def initialize
			self.board = Board.new
		end

		def play(i, j)
			if i>10 || j>10
				puts "Tu n'est pas dans le tableau, rentre un nombre inférieur à 10"
			elsif self.board.box(i,j).player != :none
				puts "Cette case est déja prise, essaie encore"
			elsif self.board.box(i,j).player == :none
				board.box(i,j).player = :user
				if self.board.is_game_over
					puts "Vous avez fini cette partie, vous devez recommencer une partie"
					show_board
					return {status: :user_won , i: i, j: j}
				elsif !self.board.is_tie
					puts "Égalité, vous devez recommencer une partie"
					return {status: :tie, i: i, j: j}
				end
				return {status: :continue , i: i, j:j }
			else 
				puts "Que passa ???"
			end
		end

		def play_computer
			a = board.find_best_box
			board.box(a[0], a[1]).player = :computer
			if self.board.is_game_over
				puts "Vous avez fini cette partie, vous devez recommencer une partie"
				show_board
				return {status: :user_won , i: a[0], j: a[1]}
			elsif !self.board.is_tie
				puts "Égalité, vous devez recommencer une partie"
				return {status: :tie, i: a[0], j: a[1]}
			else
				return {status: :continue , i: a[0], j: a[1]}
			end
		end

		def show_board
			puts self.board
		end
		def tmp_show_bord_values
			puts self.board_values
		end
	end
end