
class TestMoi < Scripts

	def initialize(rpt)
		@rpt = rpt
	end


	def run()

		result = true

		if @rpt.get('login')
			puts "OK"
		else
			result = false
			puts "KO"
		end

		if @rpt.post('login')
			puts "OK"
		else
			result = false
			puts "KO"
		end

		@rpt.clearExecStack

		return @rpt.run
	end

end
