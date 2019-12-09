local solver = require "solver"
local dot = require "dot"

local standard = {"not", "or", "and", "nor", "nand", "xor", "nxor"}
local limited = {"not", "or", "and"}
local nand = {"nand"}

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

local function make_all(ops, arity)

	local output = {}

	local title = string.format("%d-ary functions using %s", arity, table.concat(ops, "-"))

	table.insert(output, string.format(html_header, title))
	table.insert(output, string.format("<h1>%s</h1>", title))

	for target = 0, (1 << (1 << arity)) - 1 do

		local res = solver.find(ops, arity, target, nil, "all_solutions")

		local name = ""

		if arity == 2 then
			name = " (" .. binaries[target] .. ")"
		end

		table.insert(output, string.format("<h2>Function %d%s</h2>", target, name))
		table.insert(output, string.format("<p>%d minimal solution%s</p>", #res, #res >= 2 and "s" or ""))

		for _,solution in ipairs(res) do

			local dot_source = dot.make(solution)
			local svg = dot.run(dot_source)

			table.insert(output, svg)
		end
	end

	table.insert(output, "</html>")

	return table.concat(output, "\n")
end

print(make_all(limited, 2))
