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

local function make_apply(arity)

	local mask = (1 << (1 << arity)) - 1
	return function(op, f, g)
		return ops[op](f,g) & mask
	end
end

local function copy(t)

	if type(t) ~= "table" then
		return t
	end

	local c = {}
	for k,v in pairs(t) do
		c[k] = copy(v)
	end
	return c
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

local function find_at_depth(ops, arity, depth, target, memo, all_solutions)

	local solutions = {}
	local funcs = {}
	local found = false

	for i,v in ipairs(selectors(arity)) do
		local name = string.char(string.byte("a") + i-1)
		table.insert(funcs, {v, name})

		if v == target then
			found = true
			table.insert(solutions, copy(funcs))
		end
	end

	local apply = make_apply(arity)

	local function rec(d)

		if d == 0 then
			return
		end

		for _,op in ipairs(ops) do

			for i = 1,#funcs do
				for j = i,#funcs do		-- assume all operators are symetrical
					local left,right = funcs[i][1], funcs[j][1]
					local res = apply(op, left, right)

					local new = true
					for i,v in ipairs(funcs) do
						if res == v[1] then
							new = false
							break
						end
					end

					if new then
						table.insert(funcs, {res, op, left, (op ~= "not" and right or nil)})

						if memo and not memo[res] then
							memo[res] = copy(funcs)
						end

						if res == target then
							found = true
							table.insert(solutions, copy(funcs))

							if not all_solutions then
								return
							end
						end

						rec(d-1)

						if found and (not all_solutions) then return end

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
		rec(depth)
	end

	return solutions
end

local function find(ops, arity, target, memo, all_solutions)

	if memo and memo[target] then
		return memo[target]
	end

	for depth = 1,math.maxinteger do
		local res = find_at_depth(ops, arity, depth, target, memo, all_solutions)
		if #res > 0 then
			return res
		end
	end
end

return
{
	find = find
}