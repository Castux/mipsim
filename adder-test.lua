local Geom = require "Geom"
local Simulator = require "Simulator"

local function adder()

	print("Testing adder...")

	local geom = Geom()
	local adder = io.open("examples/8bits-adder.txt"):read("a")
	geom:loadTiles(adder)
	local sim = Simulator(geom)
	sim:setup()

	for i = 0,255 do
		print(i)
		for j = 0,255 do
			sim:setNumber("in_a", i)
			sim:setNumber("in_b", j)

			local result = sim:readNumber("out")
			local err = result % 256 ~= (i+j) % 256

			if err then
				print(i, "+", j, "=", result, err and "WRONG" or "")
			end
		end
	end

	print "Done."
end

local function incr()

	print "Testing incr/decr..."

	local geom = Geom()
	local adder = io.open("examples/incr-decr.txt"):read("a")
	geom:loadTiles(adder)
	local sim = Simulator(geom)
	sim:setup()

	sim:setNumber("in_incr", 1)

	for i = 0,255 do

		sim:setNumber("in_a", i)
		local result = sim:readNumber("out")
		local err = result % 256 ~= (i+1) % 256

		if err then
			print(i, "+1", "=", result, err and "WRONG" or "")
		end
	end

	sim:setNumber("in_incr", 0)

	for i = 0,255 do

		sim:setNumber("in_a", i)
		local result = sim:readNumber("out")
		local err = result % 256 ~= (i-1) % 256

		if err then
			print(i, "-1", "=", result, err and "WRONG" or "")
		end
	end

	print "Done"
end

adder()
incr()
