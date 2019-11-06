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
		for i = x-1,x+1 do
			for j = y-1,y+1 do
				if i ~= j then
					coroutine.yield(i,j)
				end
			end
		end
	end)

end

function Geom:computeComponent(tile)

	if not tile then
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

		for i,j in neighbours(current.x, current.y) do
			local neigh = self:getTile(i,j)
			if neigh and neigh.type == tile.type then
				table.insert(queue, neigh)
			end
		end

		::skip::
	end

	return comp
end

function Geom:updateComponents()

	self.components = {}
	local done = {}

	for x,y,tile in self:iterTiles() do
		if not done[tile] then
			local comp = self:computeComponent(tile)

			for tile in pairs(comp) do
				done[tile] = true
				tile.component = comp
			end
			table.insert(self.components, comp)
		end
	end

	if self.componentsUpdatedCB then
		self.componentsUpdatedCB(self.components)
	end
end

return Geom
