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

local function graph(arity)

	local funcs = {}

	local num_funcs = (1 << (1 << arity))

	for i = 0, num_funcs - 1 do
		funcs[i] = {}
	end

	for i = 0, num_funcs - 1 do
		for j = i, num_funcs - 1 do
			local res = apply("nand", i, j, arity)
			table.insert(funcs[res], {i,j})
		end
	end

	for i = 0, num_funcs - 1 do
		local v = funcs[i]
		io.write(i, ": ")
		for j,w in ipairs(v) do
			io.write(w[1] .. "+" .. w[2] .. ",")
		end
		io.write "\n"
	end

	local txt = {}

	table.insert(txt, "digraph G {")
	table.insert(txt, "overlap=false;")

	for i = 0, num_funcs - 1 do
		local v = funcs[i]

		for j,w in ipairs(v) do
			table.insert(txt, string.format("{%d,%d} -> nand_%d_%d -> %d;", w[1], w[2], i, j, i))
		end
	end

	table.insert(txt, "}")

	local fp = io.open("out_" .. arity .. ".dot", "w")
	fp:write(table.concat(txt, "\n"))
	fp:close()
end

graph(2)