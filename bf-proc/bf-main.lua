package.path = package.path .. ";../?.lua"

local Geom = require "Geom"
local Simulator = require "Simulator"

local program = {}
local memory = {}
local sim

local function load_program(str)

	str = str:sub(1,256)

	for i = 1,#str do
		program[i - 1] = str:byte(i)
	end

	print(str)
end

local function init()

	local geom = Geom()
	local tiles = io.open("full-bf-proc.txt", "r"):read("a")

	for i = 0,255 do
		program[i] = 0
		memory[i] = 0
	end

	geom:loadTiles(tiles)

	sim = Simulator(geom)
	sim:setup()

	sim:setPin("clock", "low")

	sim:setPin("reset", "high")
	sim:setPin("reset", "low")
end

local function tick()

	-- Toggle clock

	local clock = sim:readValue("clock")
	clock = clock == "high" and "low" or "high"
	sim:setPin("clock", clock)

	-- Handle IO port

	local sel_prog = sim:readValue("port_sel_prog")
	local sel_mem = sim:readValue("port_sel_mem")
	local sel_io = sim:readValue("port_sel_io")

	local addr = sim:readNumber("port_addr")
	local write = sim:readValue("port_write")

	sim:setNumber("port_data", nil)

	if sel_prog or sel_mem then
		local array = sel_prog and program or memory

		if write then
			local value = sim:readNumber("port_data")
			array[addr] = value
		else
			local value = array[addr]
			sim:setNumber("port_data", value)
		end

	elseif sel_io then

		if write then
			local value = sim:readNumber("port_data")
			io.write(string.char(value))
		else
			local char = io.read(1)
			sim:setNumber("port_data", char:byte(1))
		end
	end
end

local function main(args)

	local prog_path = args[1]

	print("Loading program " .. prog_path)
	load_program(io.open(prog_path, "r"):read("a"))

	print("Loading simulator")
	init()

	print("Running")
	while true do
		tick()
	end
end

main({...})
