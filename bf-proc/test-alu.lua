package.path = package.path .. ";../?.lua"

local Geom = require "Geom"
local Simulator = require "Simulator"

local function alu()

	print "Testing ALU..."

	local geom = Geom()
	local adder = io.open("part-alu.txt"):read("a")
	geom:load(adder)
	local sim = Simulator(geom)
	sim:setup()

	sim:setPin("alu_zero", "low")
	sim:setPin("alu_incr", "high")

	for i = 0,255 do

		sim:setNumber("alu_in", i)

		sim:setPin("alu_write", "high")
		sim:setPin("alu_write", "low")

		sim:setPin("alu_read", "high")
		local result = sim:readNumber("alu_out")
		sim:setPin("alu_read", "low")

		local err = result % 256 ~= (i + 1) % 256

		if err then
			print(i, "+ 1", "=", result, err and "wrong" or "")
		end
	end

	sim:setPin("alu_zero", "low")
	sim:setPin("alu_incr", "low")

	for i = 0,255 do

		sim:setNumber("alu_in", i)

		sim:setPin("alu_write", "high")
		sim:setPin("alu_write", "low")

		sim:setPin("alu_read", "high")
		local result = sim:readNumber("alu_out")
		sim:setPin("alu_read", "low")

		local err = result % 256 ~= (i - 1) % 256

		if err then
			print(i, "- 1", "=", result, err and "wrong" or "")
		end
	end

	sim:setPin("alu_zero", "high")

	for i = 0,255 do

		sim:setNumber("alu_in", i)

		sim:setPin("alu_write", "high")
		sim:setPin("alu_write", "low")

		sim:setPin("alu_read", "high")
		local result = sim:readNumber("alu_out")
		sim:setPin("alu_read", "low")

		local err = result ~= i

		if err then
			print(i, "+ 0", "=", result, err and "wrong" or "")
		end
	end

	print "Done."
end

alu()
