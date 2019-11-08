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

		local result = sim:readNumber("out")
		local err = result % 16 ~= (i+j) % 16

		print(i, "+", j, "=", result, err and "WRONG" or "")
	end
end
