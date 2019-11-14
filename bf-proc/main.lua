package.path = package.path .. ";../?.lua"

local Geom = require "Geom"
local Simulator = require "Simulator"
local BFHost = require "BFHost"

local function main(args)

	print("Loading simulator")

	local geom = Geom()
	local sim = Simulator(geom)
	local host = BFHost(function() return io.read(1) end, io.write, geom, sim)

	local tiles = io.open("full-bf-proc.txt", "r"):read("a")
	geom:load(tiles)

	local prog_path = args[1]
	print("Loading program " .. prog_path)

	host:load_program(io.open(prog_path, "r"):read("a"))

	print("Running")

	sim:setup()
	host:reset_proc()

	while true do

		print("Tick")
		host:tick()

		print("pc", sim:readNumber("pc"))
		print("addr", sim:readNumber("addr"))
	end
end

main({...})
