local js = require "js"
local Canvas = require "Canvas"
local Simulator = require "Simulator"


local function onTilesLoaded(txt, canvas)

	canvas:loadTiles(txt)
	canvas:toggleEdit()

	local sim = canvas.simulator

	local iter = coroutine.wrap(function()
	    local data = {}
		math.randomseed(os.time())

		while true do
		    for reg = 0,7 do
		        local d = math.random(0,255)
		        sim:setNumber("in_addr", reg)

				coroutine.yield("pause")

		        sim:setNumber("in_data", d)
				coroutine.yield("pause")
		        sim:setPin("in_write", "high")

				coroutine.yield("pause")
		        sim:setPin("in_write", "low")

		        data[reg] = d
		        print("Reg", reg, "wrote", d)

				coroutine.yield("pause")
		    end

		    for reg = 0,7 do
		        sim:setNumber("in_addr", reg)

								coroutine.yield("pause")
		        sim:setPin("in_read", "high")
		        local d = sim:readNumber("out_data")

				coroutine.yield("pause")

		        sim:setPin("in_read", "low")

		        print("Reg", reg, "read", d, d ~= data[reg] and "wrong" or "")

				coroutine.yield("pause")
		    end
		end

		print "Done."
	end)

	local function progress()
		local foo = iter()
		if foo then
			js.global:setTimeout(progress, 1)
		end
	end

	progress()
end

local function init()

	local canvas = Canvas("canvas")

	local req = js.new(js.global.XMLHttpRequest)
	req:open('GET', "./examples/8-registers-decoders.txt")
	req.onload = function() onTilesLoaded(req.responseText, canvas) end
	req:send()
end

init()
