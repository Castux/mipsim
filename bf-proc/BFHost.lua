package.path = package.path .. ";../?.lua"
local class = require "class"

local BFHost = class()

function BFHost:init(input_cb, output_cb, geom, sim)

	self.input_cb = input_cb
	self.output_cb = output_cb

	self.geom = geom

	self.program = {}
	self.memory = {}

	for i = 0,255 do
		self.program[i] = 0
		self.memory[i] = 0
	end

	self.sim = sim
end

function BFHost:load_program(str)

	str = str:sub(1,256)

	for i = 1,#str do
		self.program[i - 1] = str:byte(i)
	end
end

function BFHost:reset_proc()
	self.sim:setPin("clock", "low")

	self.sim:setPin("reset", "high")
	self.sim:setPin("reset", "low")
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

	if sel_prog == "high" or sel_mem == "high" then
		local array = sel_prog == "high" and self.program or self.memory

		if write == "high" then
			local value = self.sim:readNumber("port_data")
			array[addr] = value
		else
			local value = array[addr]
			self.sim:setNumber("port_data", value)
		end

	elseif sel_io == "high" then

		if write  == "high" then
			local value = self.sim:readNumber("port_data")
			self.output_cb(string.char(value))
		else
			local char = self.input_cb()
			self.sim:setNumber("port_data", char:byte(1))
		end
	end
end

return BFHost
