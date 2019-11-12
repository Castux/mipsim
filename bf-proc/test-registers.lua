package.path = package.path .. ";../?.lua"

local Geom = require "Geom"
local Simulator = require "Simulator"

local function registers()

	print("Testing registers...")

	local geom = Geom()
	local adder = io.open("registers.txt"):read("a")
	geom:loadTiles(adder)
	local sim = Simulator(geom)
	sim:setup()

	local data = {}
	math.randomseed(os.time())

	local registers = {"reg_pc", "reg_addr", "reg_tmp", "reg_braces"}

	for _ = 1,100 do

		for i,reg in ipairs(registers) do
			local d = math.random(0,255)

			sim:setPin(reg, "high")
			sim:setNumber("reg_in", d)
			sim:setPin("reg_write", "high")
			sim:setPin("reg_write", "low")
			sim:setPin(reg, "low")

			data[reg] = d
			print("Reg", reg, "wrote", d)
		end

		for i,reg in ipairs(registers) do

			sim:setPin(reg, "high")
			sim:setPin("reg_read", "high")
			local d = sim:readNumber("reg_out")
			sim:setPin("reg_read", "low")
			sim:setPin(reg, "low")

			print("Reg", reg, "read", d, d ~= data[reg] and "wrong" or "")
		end

	end

	print "Done."
end

registers()
