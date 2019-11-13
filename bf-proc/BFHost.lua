package.path = package.path .. ";../?.lua"

local class = require "class"
local Geom = require "Geom"
local Simulator = require "Simulator"

local BFHost = class()

function BFHost:init()

	self.geom = Geom()
	local tiles = io.open("full-bf-proc.txt", "r"):read("a")

	self.program = {}
	self.memory = {}

	for i = 0,255 do
		self.program[i] = 0
		self.memory[i] = 0
	end

	self.geom:loadTiles(tiles)

	self.sim = Simulator(self.geom)
	self.sim:setup()

	self.sim:setPin("clock", "low")

	self.sim:setPin("reset", "high")
	self.sim:setPin("reset", "low")
end

function BFHost:load_program(str)

	str = str:sub(1,256)

	for i = 1,#str do
		self.program[i - 1] = str:byte(i)
	end

	print(str)
end

function BFHost:tick()

	-- Toggle clock

	local clock = self.sim:readValue("clock")
	clock = clock == "high" and "low" or "high"
	self.sim:setPin("clock", clock)

	-- Handle IO port

	local sel_prog = self.sim:readValue("port_sel_prog")
	local sel_mem = self.sim:readValue("port_sel_mem")
	local sel_io = self.sim:readValue("port_sel_io")

	local addr = self.sim:readNumber("port_addr")
	local write = self.sim:readValue("port_write")

	self.sim:setNumber("port_data", nil)

	if sel_prog or sel_mem then
		local array = sel_prog and self.program or self.memory

		if write then
			local value = self.sim:readNumber("port_data")
			array[addr] = value
		else
			local value = array[addr]
			self.sim:setNumber("port_data", value)
		end

	elseif sel_io then

		if write then
			local value = self.sim:readNumber("port_data")
			io.write(string.char(value))
		else
			local char = io.read(1)
			self.sim:setNumber("port_data", char:byte(1))
		end
	end
end

return BFHost