local class = require "class"

local Simulator = class()

function Simulator:init(geom, cb)

	self.geom = geom
	self.valueChangedCB = nil
end

function Simulator:setup()

	self.values = {}
	self.pins = {}

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

function Simulator:update(comp, parentTransistors)

	parentTransistors = parentTransistors or {}

	local group = self:findGroup(comp)
	local newVal = self:computeGroupValue(group)

	-- Cycle detection

	for c in pairs(group) do
		if parentTransistors[c] and oppositeValues(self.values[c], newVal) then
			newVal = "unstable"
			break
		end
	end

	-- Update values

	for c in pairs(group) do

		local prev = self.values[c]

		-- Change it

		self.values[c] = newVal

		if prev ~= newVal and self.valueChangedCB then
			self.valueChangedCB(c, newVal)
		end

		-- Transistors that switch can modify other groups

		if newVal ~= "unstable" and c.type == "transistor" and oppositeValues(prev, newVal) then

			parentTransistors[c] = true

			self:update(c.sd1, parentTransistors)

			if newVal ~= "high" then
				self:update(c.sd2, parentTransistors)
			end

			parentTransistors[c] = false
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

	assert(comp.type == "wire")

	self.pins[comp] = value
	self:update(comp)
end

return Simulator
