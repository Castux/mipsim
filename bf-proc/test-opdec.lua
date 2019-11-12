package.path = package.path .. ";../?.lua"

local Geom = require "Geom"
local Simulator = require "Simulator"

local function op()

	print("Testing opcode decoder...")

	local geom = Geom()
	local adder = io.open("part-opdec.txt"):read("a")
	geom:loadTiles(adder)
	local sim = Simulator(geom)
	sim:setup()

	local ops = {">", "<", "+", "-", ",", ".", "[", "]", "nop"}

	-- (string.byte("nop") will be "n", which is a valid test)

	for i,op in ipairs(ops) do

		local b = string.byte(op)
		sim:setNumber("op_in", b)
		sim:setPin("op_write", "high")
		sim:setPin("op_write", "low")

		for _,op2 in ipairs(ops) do
			local out = sim:readValue("op_" .. op2)

			if op == op2 and out ~= "high" then
				print("In:", op, "but", op2, "not high")
			end

			if op ~= op2 and out == "high" then
				print("In:", op, "but", op2, "high")
			end
		end
	end

	print "Done."
end

op()
