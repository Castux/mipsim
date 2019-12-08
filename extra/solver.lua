local ops =
{
	["not"] = function(a) return ~a end,
	["and"] = function(a,b) return a & b end,
	["or"] = function(a,b) return a | b end,
	["xor"] = function(a,b) return a ~ b end,
	["nand"] = function(a,b) return ~(a & b) end,
	["nor"] = function(a,b) return ~(a | b) end,
	["nxor"] = function(a,b) return ~(a ~ b) end,
}

local function apply(op, f, g, arity)

	local mask = (1 << (1 << arity)) - 1
	return ops[op](f,g) & mask
end

local function selectors(arity)

	local selectors = {}
	for i = 1,arity do
		selectors[i] = 0
	end

	for input = 0, 2 ^ arity - 1 do
		for i = 1,arity do
			selectors[i] = selectors[i] | (((input >> (i-1)) & 1) << input)
		end
	end

	return selectors
end

local function find_at_depth(ops, arity, depth, target)

	local funcs = {}
	local found = false

	for i,v in ipairs(selectors(arity)) do
		local name = string.char(string.byte("a") + i-1)
		table.insert(funcs, {v, name})

		if v == target then
			found = true
		end
	end

	local function rec(d, min_i)

		if d == 0 then
			return
		end

		for _,op in ipairs(ops) do

			for i = min_i,#funcs do
				for j = i,#funcs do		-- assume all operators are symetrical
					local left,right = funcs[i][1], funcs[j][1]
					local res = apply(op, left, right, arity)

					local new = true
					for i,v in ipairs(funcs) do
						if res == v[1] then
							new = false
							break
						end
					end

					if new then
						table.insert(funcs, {res, op, left, (op ~= "not" and right or nil)})

						if res == target then
							found = true
							return
						end

						rec(d-1, i)

						if found then return end

						table.remove(funcs)
					end

					if op == "not" then
						break		-- the second argument is actually not used, no need to go through all of them
					end
				end
			end
		end
	end

	if not found then
		rec(depth, 1)
	end

	if found then
		return funcs
	end
end

local function find(ops, arity, target)

	for depth = 1,math.maxinteger do
		local res = find_at_depth(ops, arity, depth, target)
		if res then
			return res
		end
	end

	return nil
end

local standard = {"not", "or", "and", "nor", "nand", "xor", "nxor"}
local nand = {"nand"}

for target = 0, (1 << (1 << 3)) - 1 do
	print("======")
	print("FUNC", target)
	local res = find(nand, 3, target)

	for i,v in ipairs(res) do
		print(table.unpack(v))
	end
end