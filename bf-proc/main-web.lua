package.path = package.path .. ";../?.lua"

local js = require "js"
local Geom = require "Geom"
local Simulator = require "Simulator"
local BFHost = require "BFHost"
local Canvas = require "Canvas"

local programState
local memoryState
local autorunCheckbox

local function tick(host)
	host:tick()

	if autorunCheckbox.checked then
		js.global:requestAnimationFrame(function() tick(host) end)
	end
end

local function setupDOM(host)

	programState = js.global.document:getElementById "programState"
	memoryState = js.global.document:getElementById "memoryState"

	local tickButton = js.global.document:getElementById "tickButton"
	tickButton.onclick = function() tick(host) end

	autorunCheckbox = js.global.document:getElementById "autorunCheckbox"
end

local function updateState(host)

	local prog = {}
	for i = 0,#host.program do
		table.insert(prog, string.char(host.program[i]))
	end

	programState.innerHTML = table.concat(prog)

	local mem = {}
	for i = 0,#host.memory do
		table.insert(mem, string.format("%03d ", host.memory[i]))
		if i % 16 == 15 then
			table.insert(mem, "</br>")
		end
	end

	memoryState.innerHTML = table.concat(mem)
end

local function onTilesLoaded(text, host, canvas)

	host.geom:loadTiles(text)
	canvas:toggleEdit()

	print("Running")

	host.sim:setup()
	host:reset_proc()

end

local function main(args)

	print("Loading simulator")

	local geom = Geom()
	local sim = Simulator(geom)
	local host = BFHost(function() end, function() end, geom, sim)

	local canvas = Canvas("canvas", geom, sim)

	host:load_program("><><>++-+-+..")
	setupDOM(host)
	updateState(host)

	-- Load tiles

	local req = js.new(js.global.XMLHttpRequest)
	req:open('GET', "./full-bf-proc.txt")
	req.onload = function() onTilesLoaded(req.responseText, host, canvas) end
	req:send()

end

main({...})
