local BFHost = require "BFHost"

local function main(args)

	print("Loading simulator")
	local host = BFHost()

	local prog_path = args[1]

	print("Loading program " .. prog_path)
	host:load_program(io.open(prog_path, "r"):read("a"))

	print("Running")
	while true do
		host:tick()
	end
end

main({...})
