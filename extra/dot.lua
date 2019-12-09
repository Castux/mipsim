local function make(solution)

	local txt = {}

	table.insert(txt, "digraph G {")
	table.insert(txt, "splines = ortho;")
	table.insert(txt, "rankdir = LR;")

	-- inputs

	table.insert(txt, "subgraph inputs {")
	table.insert(txt, "rank = same;")

	for i,v in ipairs(solution) do
		if not v[3] then
			table.insert(txt, string.format("f%d [shape=circle, label=%s];", v[1], v[2]))
		end
	end
	table.insert(txt, "}")

	-- gates
	local out

	for _,v in ipairs(solution) do
		if v[3] then
			table.insert(txt, string.format("f%d [shape=rectangle, label=%s];", v[1], v[2]))
			for i = 3,#v do
				table.insert(txt, string.format("f%d -> f%d;", v[i], v[1]))
			end
		end

		if v.out then
			out = v[1]
		end
	end

	-- output

	table.insert(txt, ('out [shape=none, label=""];'))
	table.insert(txt, string.format("f%d -> out;", out))

	table.insert(txt, "}")

	return table.concat(txt, "\n")
end

local function run(src)

	local path = os.tmpname()
	local fp = io.open(path, "w")
	fp:write(src)
	fp:flush()
	fp:close()

	local fp = io.popen("dot -Tsvg " .. path)
	local res = fp:read "a"
	fp:close()

	return res
end

return
{
	make = make,
	run = run
}