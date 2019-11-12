local class = require "class"
local Queue = require("collections").Queue

local Simulator = class()

function Simulator:init(geom)

	self.geom = geom
	self.valueChangedCB = nil
	self.stepped = false
end

function Simulator:setup()

	self.values = {}
	self.pins = {}

	self:setupNamedComponents()

	for comp in pairs(self.geom.components) do
		self.values[comp] = "floating"
	end

	for comp in pairs(self.geom.components) do

		if comp.type == "power" or comp.type == "ground" then
			self:update(comp)
		end
	end
end

local function oppositeValues(a,b)
	return (a == "high" and b ~= "high") or
		(a ~= "high" and b == "high")
end

function Simulator:update(startComp)

	local queue = Queue()
	queue:push(startComp)

	local flipCounts = {}

	while not queue:empty() do

		local comp = queue:pop()
		local group = self:findGroup(comp)
		local newVal = self:computeGroupValue(group)

		-- Cycle detection

		for c in pairs(group) do
			if (flipCounts[c] or 0) > 20 then
				newVal = "unstable"
				break
			end
		end

		-- Update values

		for c in pairs(group) do

			local prev = self.values[c]
			if prev == "unstable" then
				goto skip
			end

			-- Change it

			self.values[c] = newVal

			if prev ~= newVal and self.valueChangedCB then
				self.valueChangedCB(c, newVal)
			end

			if self.stepped then
				coroutine.yield("paused")
			end

			-- Transistors that switch can modify other groups

			if newVal ~= "unstable" and c.type == "transistor" and oppositeValues(prev, newVal) then

				flipCounts[c] = (flipCounts[c] or 0) + 1

				queue:push(c.sd1)
				if newVal ~= "high" then
					queue:push(c.sd2)
				end
			end

			::skip::
		end
	end
end

function Simulator:connectedComponents(comp)

	-- Transistor is only connected to its gate

	if comp.type == "transistor" then
		return { comp.gate }
	end

	-- Any other component is simply connected to
	-- any non-transistor neighbour
	-- For transistors the rules are:
	-- If we are the transistor's gate, we're connected to the
	-- transistor
	-- If we are a source/drain, AND the transistor is powered,
	-- we are connected to the other source/drain

	local result = {}

	for adj in pairs(comp.connected) do

		if adj.type ~= "transistor" then
			table.insert(result, adj)

		else
			if comp == adj.gate then
				table.insert(result, adj)
			elseif self.values[adj] == "high" and comp == adj.sd1 then
				table.insert(result, adj.sd2)

			elseif self.values[adj] == "high" and comp == adj.sd2 then
				table.insert(result, adj.sd1)

			end
		end
	end

	return result
end

function Simulator:findGroup(comp)

	local group = {}
	local queue = { comp }

	while #queue > 0 do

		local current = table.remove(queue)
		group[current] = true

		for _,other in ipairs(self:connectedComponents(current)) do
			if not group[other] then
				table.insert(queue, other)
			end
		end
	end

	return group
end

function Simulator:computeGroupValue(group)

	-- A group's value is:
	-- Low if there's a ground in it
	-- High if there's no ground but a power in it
	-- Floating if there's neither ground or power

	local value = "floating"

	for comp in pairs(group) do
		if comp.type == "ground" or self.pins[comp] == "low" then
			return "low"

		elseif comp.type == "power" or self.pins[comp] == "high" then
			value = "high"
		end
	end

	return value
end

function Simulator:setPin(comp, value)

	if type(comp) == "string" then
		comp = self.named[comp]
	end

	assert(comp.type == "wire")

	self.pins[comp] = value
	self:update(comp)
end

function Simulator:setupNamedComponents()

	local named = {}

	for comp in pairs(self.geom.components) do
		local labelTile = self.geom:getComponentLabel(comp)
		if labelTile then
			named[labelTile.label] = comp
		end
	end

	self.named = named

	local numbers = {}

	for k,v in pairs(named) do
		local base,bit = k:match("^(.*)_(%d+)")
		if base and bit then
			numbers[base] = numbers[base] or {}
			numbers[base][tonumber(bit)] = v

			named[k] = nil
		end
	end

	self.numbers = numbers
end

function Simulator:readValue(name)

	assert(self.named[name], "No component called " .. name)
	return self.values[self.named[name]]
end

function Simulator:readNumber(name)

	assert(self.numbers[name], "No component number called " .. name)

	local value = 0
	for i,v in pairs(self.numbers[name]) do
		local bit = self.values[v] == "high" and 1 or 0
		value = value + bit * (1 << i)
	end

	return value
end

function Simulator:setNumber(name, number)

	local wires = self.numbers[name]
	if not wires then
		return
	end

	if not number then
		for i = 0,#wires do
			if wires[i] then
				self:setPin(wires[i], nil)
			end
		end
		return
	end

	local bitIndex = 0
	for i = 0,#wires do

		local bit = number & 1
		local value = bit == 1 and "high" or "low"
		local wire = wires[i]

		if wire then
			self:setPin(wire, value)
		end

		number = number >> 1
	end

end

return Simulator
