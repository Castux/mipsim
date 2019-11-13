package.path = package.path .. ";../?.lua"

local js = require "js"
local Geom = require "Geom"
local Simulator = require "Simulator"
local BFHost = require "BFHost"
local Canvas = require "Canvas"

local programState
local memoryState

local function setupDOM()

	programState = js.global.document:getElementById "programState"
	memoryState = js.global.document:getElementById "memoryState"

end

local function updateState(host)

	local prog = {}
	for i = 0,#host.program do
		table.insert(prog, string.char(host.program[i]))
	end

	programState.innerHTML = table.concat(prog)

end

local function onTilesLoaded(text, host)

	host.geom:loadTiles(text)

	print("Running")

	host.sim:setup()
	host:reset_proc()

	do return end
	while true do
		host:tick()
	end

end

local function main(args)

	setupDOM()

	print("Loading simulator")

	local geom = Geom()
	local sim = Simulator(geom)
	local host = BFHost(function() end, function() end, geom, sim)

	local canvas = Canvas("canvas", geom, sim)

	host:load_program("><><>++-+-+..")

	updateState(host)

	-- Load tiles

	local req = js.new(js.global.XMLHttpRequest)
	req:open('GET', "./full-bf-proc.txt")
	req.onload = function() onTilesLoaded(req.responseText, host) end
	req:send()

end

main({...})
