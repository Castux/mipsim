
local js = require "js"

package.path = "../?.lua"

local Geom = require "Geom"
local Simulator = require "Simulator"
local Canvas = require "Canvas"

package.path = "./?.lua"

local BFHost = require "BFHost"

local programState
local memoryState
local autorunCheckbox

local defaultProgram = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."

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

local function tick(host)
	host:tick()
	updateState(host)

	if autorunCheckbox.checked then
		js.global:requestAnimationFrame(function() tick(host) end)
	end
end

local function setupDOM(host)

	programState = js.global.document:getElementById "programState"
	memoryState = js.global.document:getElementById "memoryState"

	programState.onchange = function()
		host:load_program(programState.value)
		updateState(host)
	end

	local tickButton = js.global.document:getElementById "tickButton"
	tickButton.onclick = function() tick(host) end

	autorunCheckbox = js.global.document:getElementById "autorunCheckbox"
end

local function onTilesLoaded(text, host, canvas)

	host.geom:load(text)
	canvas:toggleEdit()
	canvas:zoomToAll()

	host.sim:setup()
	host:reset_proc()
end

local function main(args)

	local geom = Geom()
	local sim = Simulator(geom)
	local host = BFHost(function() end, function() end, geom, sim)

	host:load_program(defaultProgram)

	local canvas = Canvas("canvas", geom, sim)

	setupDOM(host)
	updateState(host)

	-- Load tiles

	local req = js.new(js.global.XMLHttpRequest)
	req:open('GET', "./full-bf-proc.txt")
	req.onload = function() onTilesLoaded(req.responseText, host, canvas) end
	req:send()

end

main({...})
