package.path = package.path .. ";../?.lua"

local Geom = require "Geom"
local Simulator = require "Simulator"

local function clock()

	print("Testing clock...")

	local geom = Geom()
	local adder = io.open("part-clock.txt"):read("a")
	geom:loadTiles(adder)
	local sim = Simulator(geom)
	sim:setup()

	for i = 1,100 do

		local before = sim:readNumber("phase")

		local clock = sim:readValue("clock_in")
		clock = clock == "high" and "low" or "high"
		sim:setPin("clock_in", clock)

		local after = sim:readNumber("phase")

		local correct = after == 1 or after == before * 2
		if not correct then
			print("Before", before, "after", after)
		end
	end

	print("Done.")
end

clock()
