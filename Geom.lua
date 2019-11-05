local class = require "class"

local Geom = class()

function Geom:init()

	-- flat [x][y] arrays of tile types

	self.tiles = {}
	self.bridges = {}

	-- segments are adjacent tiles of the same type
	-- nodes are connected groups of wires and bridges

	self.segments = {}
	self.nodes = {}

	-- transistors have exactly three nodes connected

	self.transistors = {}

	-- node adjancency somehow

end

function Geom:setTile(x,y,type)

	local array = type == "bridge" and self.bridges or self.tiles

	if not array[x] then
		array[x] = {}
	end

	array[x][y] = type
end

function Geom:getTile(x,y)

	return self.tiles[x] and self.tiles[x][y],
		self.briges[x] and self.bridges[x][y]

end

function Geom:resetTile(x,y,type)

	local array = type == "bridge" and self.bridges or self.tiles

	if not array[x] then
		return
	end

	array[x][y] = nil
end

function Geom:clearTiles()

	self.tiles = {}
	self.bridges = {}

end

function Geom:iterTiles(bridges)

	return coroutine.wrap(function()
		for i,row in pairs(self.tiles) do
			for j,w in pairs(row) do
				coroutine.yield(i,j,w)
			end
		end

		for i,row in pairs(self.bridges) do
			for j,w in pairs(row) do
				coroutine.yield(i,j,w)
			end
		end
	end)
end

function Geom:dumpTiles()
	local res = {}

	for i,j,type in self:iterTiles() do
		local str = string.format("{%d,%d,%q}", i, j, type)
		table.insert(res, str)
	end

	return "{" .. table.concat(res, ",") .. "}"
end

local function hash(x,y,type)
	return string.format("%d:%d%s",
		x,
		y,
		type == "bridge" and "b" or ""
	)
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

function Geom:findSegment(x,y,type)

	local array = type == "bridge" and self.bridges or self.tiles
	local found = {}

	local queue = { {x,y,type} }
	local inQueue = {}

	inQueue[hash(x,y,type)] = true

	while #queue > 0 do
		local current = table.remove(queue)
		table.insert(found, current)

		for i,j in neighbours(current[1], current[2]) do

			local tile = array[i] and array[i][j]
			if tile == type and not inQueue[hash(i,j,type)] then
				table.insert(queue, {i,j,type})
				inQueue[hash(i,j,type)] = true
			end
		end
	end

	return found
end

function Geom:findSegments()

	local tilesLeft = {}

	for i,j,type in self:iterTiles() do
		tilesLeft[hash(i,j,type)] = {i,j,type}
	end

	local segments = {}

	while true do

		local k,tile = next(tilesLeft)
		if not tile then break end

		local segment = self:findSegment(tile[1], tile[2], tile[3])
		for _,v in ipairs(segment) do
			tilesLeft[hash(v[1],v[2],v[3])] = nil
		end

		table.insert(segments, segment)
	end

	return segments
end

return Geom
