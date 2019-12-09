local solver = require "solver"
local dot = require "dot"

local standard = {"not", "or", "and", "nor", "nand", "xor", "nxor"}
local limited = {"not", "or", "and"}
local nand = {"nand"}

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

		table.insert(output, string.format("<h2>Function %d</h2>", target))
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
