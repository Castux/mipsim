local solver = require "solver"
local dot = require "dot"

local standard = {"not", "or", "and", "nor", "nand", "xor", "nxor"}
local limited = {"not", "or", "and"}
local nand = {"nand"}
local nor = {"nor"}

local binaries =
{
	[0] = "false",
	[1] = "nor",
	[2] = "a-b",
	[3] = "not b",
	[4] = "b-a",
	[5] = "not a",
	[6] = "xor",
	[7] = "nand",
	[8] = "and",
	[9] = "nxor",
	[10] = "a",
	[11] = "b=>a",
	[12] = "b",
	[13] = "a=>b",
	[14] = "or",
	[15] = "true",
}

local html_header = [[
<html>
<head>
<title>%s</title>
</head>
]]

local function solution_text(s)
	local out = {}
	for i,v in ipairs(s) do
		table.insert(out, table.concat(v, ","))
	end

	return table.concat(out, "\n")
end

local function make_all(ops, arity, all, path)

	local fp = io.open(path, "w")

	local output = {}

	local title = string.format("%d-ary functions using %s", arity, table.concat(ops, "-"))

	fp:write(string.format(html_header, title), "\n")
	fp:write(string.format("<h1>%s</h1>", title), "\n")

	local from = 0
	local to = (1 << (1 << arity)) - 1

	local memo
	if not all then
		memo = {}
	end

	for target = from, to do
		print("Target", target)

		local res = solver.find(ops, arity, target, memo, all)

		local name = ""

		if arity == 2 then
			name = " (" .. binaries[target] .. ")"
		end

		fp:write(string.format("<h2>Function %d%s</h2>", target, name), "\n")

		if all then
			fp:write(string.format("<p>%d minimal solution%s</p>", #res, #res >= 2 and "s" or ""), "\n")
		end

		for _,solution in ipairs(res) do

			local dot_source = dot.make(solution)
			local svg = dot.run(dot_source)
			fp:write(svg)
		end
	end

	fp:write("</html>", "\n")
	fp:close()
end

--print(make_all(limited, 2, true, "limited-2.html"))
--print(make_all(standard, 3, false, "standard-3.html"))
--print(make_all(standard, 3, true, "standard-3-all.html"))
--print(make_all(nand, 2, true, "nand-2-all.html"))
print(make_all(nand, 3, false, "nand-3.html"))
