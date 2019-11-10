local Geom = require "Geom"
local Simulator = require "Simulator"

local function registers()

	print("Testing registers...")

	local geom = Geom()
	local adder = io.open("examples/8-registers-decoders.txt"):read("a")
	geom:loadTiles(adder)
	local sim = Simulator(geom)
	sim:setup()

    local data = {}
	math.randomseed(os.time())

    for reg = 0,7 do
        local d = math.random(0,255)
        sim:setNumber("in_addr", reg)
        sim:setNumber("in_data", d)
        sim:setPin("in_write", "high")
        sim:setPin("in_write", "low")

        data[reg] = d
        print("Reg", reg, "wrote", d)
    end

    for reg = 0,7 do
        sim:setNumber("in_addr", reg)
        sim:setPin("in_read", "high")
        local d = sim:readNumber("out_data")
        sim:setPin("in_read", "low")

        print("Reg", reg, "read", d, d ~= data[reg] and "wrong" or "")

    end

	print "Done."
end

registers()
