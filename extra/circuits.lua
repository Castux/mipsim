local function copy(t)
	local res = {}
	for k,v in pairs(t) do
		res[k] = v
	end
	return res
end

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

local function find_at_depth(ops, arity, depth, ignore)

	local results = {}
	local funcs = {}

	for i,v in ipairs(selectors(arity)) do
		local name = string.char(string.byte("a") + i-1)
		table.insert(funcs, {v, name})
	end

	local function rec(d)

		if d == 0 then
			local func = funcs[#funcs][1]

			if not ignore[func] and not results[func] then
				results[func] = copy(funcs)
			end
			return
		end

		for _,op in ipairs(ops) do

			for i = 1,#funcs do
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
						rec(d-1)
						table.remove(funcs)
					end

					if op == "not" then
						break		-- the second argument is actually not used, no need to go through all of them
					end
				end
			end
		end
	end

	rec(depth)
	return results
end

local function build_all(ops, arity)

	local found = {}
	local count = 0

	for depth = 1, math.maxinteger do

		local res = find_at_depth(ops, arity, depth, found)
		local empty = true

		for func,solution in pairs(res) do
			empty = false
			found[func] = solution
			count = count + 1
		end

		print(count)

		if empty then
			break
		end
	end

	return found
end

local function dirty_dump(results)

	for func, res in pairs(results) do
		print("======")
		print("FUNC", func)
		for i,v in ipairs(res) do
			print(table.unpack(v))
		end
	end
end

dirty_dump(build_all({"nand"}, 3))