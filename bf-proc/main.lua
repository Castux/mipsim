local BFHost = require "BFHost"

local function main(args)

	print("Loading simulator")
	local tiles = io.open("full-bf-proc.txt", "r"):read("a")
	local host = BFHost(tiles, function() return io.read(1) end, io.write)

	local prog_path = args[1]

	print("Loading program " .. prog_path)
	host:load_program(io.open(prog_path, "r"):read("a"))

	print("Running")
	while true do
		host:tick()
	end
end

main({...})
