local class = require "class"

local Geom = class()

function Geom:init()

	-- flat [x][y] arrays of tile types

	self.tiles = {}
	self.tileUpdatedCB = nil

	-- segments are adjacent tiles of the same type
	-- nodes are connected groups of wires and bridges

	self.components = {}
	self.componentsUpdatedCB = nil

end

function Geom:setTile(x,y,type)

	local tile = self:getTile(x,y)
	if not tile then
		tile = {
			x = x,
			y = y
		}

		if not self.tiles[x] then
			self.tiles[x] = {}
		end

		self.tiles[x][y] = tile
	end

	if type == "bridge" then
		tile.bridge = true
	else
		tile.type = type
	end

	if self.tileUpdatedCB then
		self.tileUpdatedCB(tile)
	end
end

function Geom:getTile(x,y)
	return self.tiles[x] and self.tiles[x][y]
end

function Geom:resetTile(x,y,type)

	local tile = self:getTile(x,y)
	if not tile then return end

	if type == "bridge" then
		tile.bridge = nil
	else
		tile.type = nil
	end

	local deleted = false

	if not tile.type and not tile.bridge then
		self.tiles[x][y] = nil
		deleted = true
	end

	if self.tileUpdatedCB then
		self.tileUpdatedCB(tile, deleted)
	end
end

function Geom:clearTiles()
	self.tiles = {}
end

function Geom:iterTiles(bridges)

	return coroutine.wrap(function()
		for i,row in pairs(self.tiles) do
			for j,tile in pairs(row) do
				coroutine.yield(i,j,tile)
			end
		end
	end)
end

function Geom:dumpTiles()
	local res = {}

	for x,y,tile in self:iterTiles() do
		local parts = {}
		table.insert(parts, string.format("x=%d,y=%d", x, y))

		if tile.type then
			table.insert(parts, string.format("type=%q", tile.type))
		end

		if tile.bridge then
			table.insert(parts, "bridge=true")
		end

		table.insert(res, "{" .. table.concat(parts, ",") .. "}")
	end

	return "{" .. table.concat(res, ",") .. "}"
end

function Geom:loadTiles(str)

	local loader = load("return " .. str)
	if not loader then
		print "Invalid tile dump"
	end

	self:clearTiles()
	local newTiles = loader()

	for _,t in ipairs(newTiles) do
		if t.type then
			self:setTile(t.x, t.y, t.type)
		end
		if t.bridge then
			self:setTile(t.x, t.y, "bridge")
		end
	end

	self:updateComponents()
end

local function neighbours(x,y)

	return coroutine.wrap(function()
		coroutine.yield(x, y-1)
		coroutine.yield(x, y+1)
		coroutine.yield(x-1, y)
		coroutine.yield(x+1, y)
	end)

end

function Geom:computeComponent(tile, bridge)

	if not tile then
		return
	end

	if bridge and not tile.bridge then
		return
	end

	if not bridge and not tile.type then
		return
	end

	local comp = {}
	local endpoints = {}
	local adjacentTiles = {}
	local queue = { tile }

	while #queue > 0 do

		local current = table.remove(queue)
		if comp[current] then
			goto skip
		end

		comp[current] = true
		local neighbourCount = 0

		for i,j in neighbours(current.x, current.y) do
			local neigh = self:getTile(i,j)
			if neigh then
				local valid
			 	if bridge then
					valid = neigh.bridge
				else
					valid = neigh.type == tile.type
				end

				if valid then
					neighbourCount = neighbourCount + 1
					table.insert(queue, neigh)
				elseif neigh.type then
					adjacentTiles[neigh] = true
				end
			end
		end

		if neighbourCount == 1 then
			table.insert(endpoints, current)
		end

		::skip::
	end

	-- Return as list

	local tmp = {}
	for k in pairs(comp) do
		table.insert(tmp, k)
	end
	comp = tmp

	comp.type = bridge and "bridge" or tile.type
	if bridge then
		comp.endpoints = endpoints
	else
		comp.adjacentTiles = adjacentTiles
	end

	return comp
end

function Geom:updateConnections(comp)

	local connected = {}

	-- Regular components

	if comp.type ~= "bridge" then

		for tile,_ in pairs(comp.adjacentTiles) do
			connected[tile.component] = true
		end

		comp.adjacentTiles = nil

	-- Bridge components

	else

		local i = 1
		while i <= #comp.endpoints do
			local tile = comp.endpoints[i]

			if tile.type == "wire" then
				connected[tile.component] = true
				table.insert(tile.component.connected, comp)	-- connect back the wire
				i = i + 1
			else
				table.remove(comp.endpoints, i)
			end
		end

	end

	-- Flatten list

	local tmp = {}
	for other,_ in pairs(connected) do
		table.insert(tmp, other)
	end

	comp.connected = tmp

	-- Extra checks for transistors

	if comp.type == "transistor" then
		self:checkTransistor(comp)
	end
end

function Geom:checkTransistor(comp)

	if #comp.connected ~= 3 then
		comp.invalid = true
		return
	end

end

function Geom:updateComponents()

	self.components = {}
	local done = {}

	-- Normal components first

	for x,y,tile in self:iterTiles() do
		if not done[tile] and tile.type then
			local comp = self:computeComponent(tile)
			for _,tile in ipairs(comp) do
				done[tile] = true
				tile.component = comp
			end
			table.insert(self.components, comp)
		end
	end

	-- Bridge components next

	done = {}

	for x,y,tile in self:iterTiles() do
		if not done[tile] and tile.bridge then
			local comp = self:computeComponent(tile, true)
			for _,tile in ipairs(comp) do
				done[tile] = true
				tile.bridgeComponent = comp
			end
			table.insert(self.components, comp)
		end
	end

	-- Update connections

	for _,comp in ipairs(self.components) do
		self:updateConnections(comp)
	end

	if self.componentsUpdatedCB then
		self.componentsUpdatedCB(self.components)
	end
end

return Geom
