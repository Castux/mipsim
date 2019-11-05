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

	local array = bridges and self.bridges or self.tiles

	return coroutine.wrap(function()
		for i,row in pairs(array) do
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

	for i,j,type in self:iterTiles("bridges") do
		local str = string.format("{%d,%d,%q}", i, j, type)
		table.insert(res, str)
	end

	return "{" .. table.concat(res, ",") .. "}"
end

function Geom:findSegments()

	local tileLeft = {}


end

return Geom
