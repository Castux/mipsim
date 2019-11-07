local class = require "class"

local Simulator = class()

function Simulator:init(geom, cb)

	self.geom = geom
	self.valueChangedCB = cb

	self:setup()
end

function Simulator:setup()

	self.values = {}
	self.needUpdate = {}

	for comp in pairs(self.geom.components) do
		table.insert(self.needUpdate, comp)
	end

	self:update()
end

function Simulator:update()

	local done = {}

	while #self.needUpdate > 0 do

		local comp = table.remove(self.needUpdate)

		if done[comp] then
			goto skip
		end

		local group = self:findGroup(comp)
		local value = self:computeGroupValue(group)

		-- Update values

		for c in pairs(group) do

			local prev = self.values[c]
			self.values[c] = value

			-- Detect circular dependencies

			if prev ~= self.values[c] and done[c] then
				self.values[c] = "unstable"
			end

			-- Notify

			if prev ~= self.values[c] and self.valueChangedCB then
				self.valueChangedCB(c, self.values[c])
			end

			-- Transistors that switch can modify other groups

			if c.type == "transistor" and prev ~= self.values[c] then
				table.insert(self.needUpdate, c.sd1)
				table.insert(self.needUpdate, c.sd2)
			end

			done[c] = true
		end

		::skip::
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
		if comp.type == "ground" then
			return "low"

		elseif comp.type == "power" then
			value = "high"
		end
	end

	return value
end

return Simulator
