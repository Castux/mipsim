local class = require "class"

local Geom = class()

function Geom:init()

	-- flat [x][y] arrays of tile types

	self.tiles = {}

	-- segments are adjacent tiles of the same type
	-- nodes are connected groups of wires and bridges

	self.components = {}
	self.componentUpdatedCB = nil
	self.componentDestroyedCB = nil


	-- Live update

	self.dirtyTiles = {}		-- need new component
	self.dirtyComponents = {}	-- need to recheck connections

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

	if tile.label and tile.type ~= "wire" then
		tile.label = nil
	end

	self:setDirtyTile(tile, true)
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

	if not tile.type and not tile.bridge then
		self.tiles[x][y] = nil
	end

	self:setDirtyTile(tile, true)
end

function Geom:clearTiles()

	self.tiles = {}

	for comp in pairs(self.components) do
		if self.componentDestroyedCB then
			self.componentDestroyedCB(comp)
		end
	end

	self.components = {}
end

function Geom:setDirtyTile(tile, addNeighbours)

	self.dirtyTiles[tile] = true

	if tile.component then
		self:deleteComponent(tile.component)
		assert(not tile.component)
	end
	if tile.bridgeComponent then
		self:deleteComponent(tile.bridgeComponent)
		assert(not tile.bridgeComponent)
	end

	if addNeighbours then
		for neigh in self:neighbours(tile) do
			self:setDirtyTile(neigh, false)
		end
	end

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

		if tile.label then
			table.insert(parts, string.format("label=%q", tile.label))
		end

		table.insert(res, "{" .. table.concat(parts, ",") .. "}")
	end

	return "{" .. table.concat(res, ",\n") .. "}"
end

function Geom:loadTiles(tiles)

	self:clearTiles()

	if type(tiles) == "string" then
		local loader = load("return " .. tiles)
		if not loader then
			print "Invalid tile dump"
		end
		tiles = loader()
	end

	for _,t in ipairs(tiles) do
		if t.type then
			self:setTile(t.x, t.y, t.type)
		end
		if t.bridge then
			self:setTile(t.x, t.y, "bridge")
		end
		if t.label then
			local created = self:getTile(t.x, t.y)
			self:setLabel(created, t.label)
		end
	end

	self:updateComponents()
end

function Geom:neighbours(tile)
	local x,y = tile.x, tile.y

	return coroutine.wrap(function()

		local neigh = self:getTile(x, y-1)
		if neigh then coroutine.yield(neigh) end
		local neigh = self:getTile(x, y+1)
		if neigh then coroutine.yield(neigh) end
		local neigh = self:getTile(x-1, y)
		if neigh then coroutine.yield(neigh) end
		local neigh = self:getTile(x+1, y)
		if neigh then coroutine.yield(neigh) end

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
	local queue = { tile }

	while #queue > 0 do

		local current = table.remove(queue)
		if comp[current] then
			goto skip
		end

		comp[current] = true
		local neighbourCount = 0

		for neigh in self:neighbours(current) do
			local valid
		 	if bridge then
				valid = neigh.bridge
			else
				valid = neigh.type == tile.type
			end

			if valid then
				table.insert(queue, neigh)
			end
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

	return comp
end

function Geom:adjacentTiles(comp)

	assert(comp.type ~= "bridge")

	return coroutine.wrap(function()
		for _,tile in ipairs(comp) do
			for neigh in self:neighbours(tile) do
				if neigh.component and neigh.component ~= comp then
					coroutine.yield(neigh)
				end
			end
		end
	end)
end

function Geom:endpoints(comp)

	assert(comp.type == "bridge")
	local result = {}

	for _,tile in ipairs(comp) do
		if self:isEndpoint(tile) then
			table.insert(result, tile)
		end
	end

	return result
end

function Geom:isEndpoint(tile)

	if tile.type ~= "wire" then
		return false
	end

	if not tile.bridge then
		return false
	end

	local count = 0
	for neigh in self:neighbours(tile) do
		if neigh.bridge then
			count = count + 1
		end

		if count > 1 then break end
	end

	return count == 1
end

function Geom:updateConnections(comp)

	comp.connected = {}

	-- Regular components

	if comp.type ~= "bridge" then

		for n in self:adjacentTiles(comp) do
			comp.connected[n.component] = true
		end

		if comp.type == "wire" then
			for _,tile in ipairs(comp) do
				if self:isEndpoint(tile) then
					comp.connected[tile.bridgeComponent] = true
				end
			end
		end

	-- Bridge components

	else
		comp.endpoints = self:endpoints(comp)

		for _,tile in ipairs(comp.endpoints) do
			comp.connected[tile.component] = true
		end
	end

	-- Extra pass for transistors

	if comp.type == "transistor" then
		self:checkTransistor(comp)
	end
end

function Geom:findStraightLine(t)

	for adj in self:adjacentTiles(t) do
		for adj2 in self:adjacentTiles(t) do

			if adj.component ~= adj2.component and
				(adj.x == adj2.x or adj.y == adj2.y) then

				return adj, adj2
			end
		end
	end

	return nil
end

function Geom:checkTransistor(comp)

	comp.invalid = nil
	comp.sd1 = nil
	comp.sd2 = nil
	comp.gate = nil
	comp.sd1Tile = nil
	comp.sd2Tile = nil

	local count = 0
	for c in pairs(comp.connected) do
		count = count + 1
	end
	if count ~= 3 then
		comp.invalid = true
		return
	end

	local adj, adj2 = self:findStraightLine(comp)
	if not adj then
		comp.invalid = true
		return
	end

	-- Source/drains

	comp.sd1 = adj.component
	comp.sd2 = adj2.component

	-- Gate

	for c in pairs(comp.connected) do
		if c ~= comp.sd1 and c ~= comp.sd2 then
			comp.gate = c
			break
		end
	end

	assert(comp.gate)

	-- Remember adjacent tiles for drawing

	comp.sd1Tile = adj
	comp.sd2Tile = adj2
end

function Geom:deleteComponent(comp)


	for _,tile in ipairs(comp) do
		self.dirtyTiles[tile] = true

		tile.bridgeComponent = nil
		tile.component = nil
	end

	for conn in pairs(comp.connected) do
		self.dirtyComponents[conn] = true
	end

	if self.componentDestroyedCB then
		self.componentDestroyedCB(comp)
	end

	self.components[comp] = nil
end

function Geom:updateComponents()

	local newComponents = {}

	-- Normal components first

	for tile in pairs(self.dirtyTiles) do

		if tile.component then
			assert(newComponents[tile.component], "Dirty tile with old component")
		end

		if tile.type and not tile.component then

			local comp = self:computeComponent(tile)
			for _,tile in ipairs(comp) do
				tile.component = comp
			end
			self.components[comp] = true
			self.dirtyComponents[comp] = true
			newComponents[comp] = true
		end

		if tile.bridgeComponent then
			assert(newComponents[tile.bridgeComponent], "Dirty tile with old component")
		end

		if tile.bridge and not tile.bridgeComponent then
			local comp = self:computeComponent(tile, true)
			for _,tile in ipairs(comp) do
				tile.bridgeComponent = comp
			end
			self.components[comp] = true
			self.dirtyComponents[comp] = true
			newComponents[comp] = true
		end
	end

	self.dirtyTiles = {}

	-- All tiles should have components!

	for x,y,tile in self:iterTiles() do
		assert(tile.component or tile.bridgeComponent, "Tile without component")
	end

	-- Destroyed components shouldn't be treated as dirty

	for comp in pairs(self.dirtyComponents) do
		if not self.components[comp] then
			self.dirtyComponents[comp] = nil
		end
	end

	-- Update connections

	for comp in pairs(self.dirtyComponents) do
		self:updateConnections(comp)
	end

	-- Cleanup

	for comp in pairs(self.dirtyComponents) do
		if self.componentUpdatedCB then
			self.componentUpdatedCB(comp)
		end
	end

	self.dirtyComponents = {}
end

function Geom:setLabel(tile, value)

	assert(tile.type == "wire")
	tile.label = value

end

function Geom:getComponentLabel(comp)

	for _,tile in ipairs(comp) do
		if tile.label then
			return tile
		end
	end

	return nil
end

return Geom
