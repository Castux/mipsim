-- Functions are represented as integers:
-- bit i is the result of applying the function
-- to input i, the bits of which represent the values
-- of its inputs

-- Returns f(g,h)
-- Assumes f is 2-ary, while g and h are arity-ary

local function compose(f, g, h, arity)

	local res = 0

	for i = 0, 2 ^ arity - 1 do

		local left = (g >> i) & 1
		local right = (h >> i) & 1

		local f_input = left << 1 | right
		local composed = (f >> f_input) & 1

		res = res | (composed << i)
	end

	return res
end


local function iterate(ops, funcs, arity)

	local generated_new = false

	local new = {}

	for f,f_name in pairs(ops) do
		for g,g_name in pairs(funcs) do
			for h,h_name in pairs(funcs) do
				local composed = compose(f,g,h,arity)
				if not funcs[composed] then
					new[composed] = new[composed] or {}
					table.insert(new[composed], {f,g,h})
					new[composed].example = string.format("%s(%s,%s)", f_name, g_name, h_name)
					generated_new = true
				end
			end
		end
	end

	for k,v in pairs(new) do
		funcs[k] = v
	end

	return generated_new
end

local function close(ops, funcs, arity)

	local init = {}

	for k,v in pairs(funcs) do
		init[k] = v
	end

	while true do
		local new = iterate(ops, init, arity)
		if not new then break end
	end

	for k,v in pairs(init) do
		print(k,#v, v.example)
	end
end

local ab =
{
	[10] = "b",		-- 1010
	[12] = "a",		-- 1100
}

local nand =
{
	[7] = "nand",	-- 0111
}

local nor =
{
	[1] = "nor",	-- 0001
}

local classic =
{
	[3] = "nota",	-- 0011
	[5] = "notb",	-- 0101
	[8] = "and",	-- 1000
	[14] = "or",	-- 1110
}

local fullbin =
{
	[0] = "false",
	[1] = "nor",
--	[2] = "b-a",
	[3] = "nota",
--	[4] = "a-b",
	[5] = "notb",
	[6] = "xor",
	[7] = "nand",
	[8] = "and",
--	[9] = "nxor",
	[10] = "b",
--	[11] = "a=>b",
	[12] = "a",
--	[13] = "b=>a",
	[14] = "or",
	[15] = "true",
}

local abc =
{
	[0xF0] = "a", 		-- 11110000
	[0xCC] = "b", 		-- 11001100
	[0xAA] = "c", 		-- 10101010
}

local function main()

	print("## nand ##")
	close(nand, ab, 2)

	print("## nor ##")
	close(nor, ab, 2)

	print("## classic ##")
	close(classic, ab, 2)

	print("## tern ##")
	close(fullbin, abc, 3)

	print("## nand3 ##")
	close(nand, abc, 3)

end

main()