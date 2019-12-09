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

local function solution_sorter(a,b)
	return a[1] < b[1]
end

local function equal_solutions(s1,s2)

	if #s1 ~= #s2 then
		return false
	end

	table.sort(s1, solution_sorter)
	table.sort(s2, solution_sorter)

	for i,v in ipairs(s1) do
		local w = s2[i]

		if v[3] and v[4] and v[3] > v[4] then
			v[3],v[4] = v[4],v[3]
		end

		if w[3] and w[4] and w[3] > w[4] then
			w[3],w[4] = w[4],w[3]
		end

		for j = 1,4 do
			if v[j] ~= w[j] then
				return false
			end
		end
	end

	return true
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
			funcs[i].out = true
		end
	end

	if found then
		table.insert(solutions, copy(funcs))
	end

	local apply = make_apply(arity)

	local function add_solution(s)
		for i,v in ipairs(solutions) do
			if equal_solutions(v, s) then
				return
			end
		end

		table.insert(solutions, s)
	end

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
							local c = copy(funcs)
							c[#c].out = true
							memo[res] = c
						end

						if res == target then
							found = true
							local c = copy(funcs)
							c[#c].out = true
							add_solution(c)

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
		return { memo[target] }
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