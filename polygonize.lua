
local function modIndex(t,n)

	local i = (n - 1) % #t + 1
	return t[i]
end

local function aligned(p1,p2,p3)

	return (p1[1] == p2[1] and p1[1] == p3[1]) or
		(p1[2] == p2[2] and p1[2] == p3[2])
end

local function reduceCycle(c)

	local i = 1
	while i <= #c and #c >= 4 do

		local p1,p2,p3 = modIndex(c, i-1), modIndex(c, i), modIndex(c, i+1)

		if aligned(p1,p2,p3) then
			table.remove(c, i)
		else
			i = i + 1
		end
	end
end

local function polygonize(tiles)

	local allPairs = {}
	local allPoints = {}

	-- First gather segments on the periphery of the shape

	local function addPair(p1, p2)

		local hash1 = table.concat(p1, ":")
		local hash2 = table.concat(p2, ":")

		allPoints[hash1] = p1
		allPoints[hash2] = p2

		allPairs[hash1] = allPairs[hash1] or {}
		allPairs[hash2] = allPairs[hash2] or {}

		-- Toggle presence: a segment inside the shape will come up twice
		-- while border segments come up only once

		allPairs[hash1][hash2] = not allPairs[hash1][hash2]
		allPairs[hash2][hash1] = not allPairs[hash2][hash1]
	end

	for _,tile in ipairs(tiles) do
		addPair( {tile.x, tile.y}, {tile.x + 1, tile.y})
		addPair( {tile.x, tile.y}, {tile.x, tile.y + 1})
		addPair( {tile.x + 1, tile.y}, {tile.x + 1, tile.y + 1})
		addPair( {tile.x, tile.y + 1}, {tile.x + 1, tile.y + 1})
	end

	-- Go around

	local function findCycle()
		local current = next(allPoints)
		if not current then
			return nil
		end

		local result = {}

		while true do

			table.insert(result, allPoints[current])
			allPoints[current] = nil

			local next
			for n,border in pairs(allPairs[current]) do
				if border and allPoints[n] then
					next = n
					break
				end
			end

			if not next then break end
			current = next
		end

		if #result > 1 then		-- internal points are still in allPoints
			return result
		else
			return nil
		end
	end

	local cycles = {}
	for c in findCycle do
		reduceCycle(c)
		table.insert(cycles, c)
	end

	return cycles
end

return polygonize
