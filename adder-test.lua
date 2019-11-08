local Geom = require "Geom"
local Simulator = require "Simulator"

local geom = Geom()

local adder = io.open("examples/4bits-adder.txt"):read("a")

geom:loadTiles(adder)

local sim = Simulator(geom)
sim:setup()

for i = 0,15 do
	for j = 0,15 do
		sim:setNumber("in_a", i)
		sim:setNumber("in_b", j)

		print(i, "+", j, "=", sim:readNumber("out"))
	end
end
