# load "tournament.rb";load("morpion_ogg.rb");t=Tournament.new(MorpionOgg::Game, MorpionOgg::Game);t.run


# load "tournament.rb";load("morpion_ogg.rb");load("morpion_alex.rb");t=Tournament.new(MorpionLeo::Game,MorpionOgg::Game);t.run

class Tournament
	attr_accessor :klass1, :klass2

	# Usage : t=Tournament.new(Morpion::Game, Morpion::Game);t.run
	def initialize(klass1,klass2)
		self.klass1 = klass1
		self.klass2 = klass2
	end


	def run_one

		p1, p2 = [self.klass1.new, self.klass2.new].shuffle

		ref = p1
		1000.times {
			r = p1.play_computer
			# puts r
			if r[:status] != :continue
				return r.merge(g: p1)
			end

			
			r = p2.play(r[:i],r[:j])
			# puts r
			if r[:status] != :continue
				return r.merge(g: p1)
			end
			#puts ref.board
			p = p1; p1 = p2; p2 = p

		}
	end

	def run

		score={}
		score[:tie] = 0
		score[self.klass1.new.class.name] = 0
		score[self.klass2.new.class.name] = 0

		100.times {
			result = self.run_one
			g = result.delete(:g)
			if result[:status] == :tie
				score[:tie] += 1
			else
				score[g.class.name] += 1
			end
			puts score
		}

	end


end