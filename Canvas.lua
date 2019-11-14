local class = require "class"
local js = require "js"
local Geom = require "Geom"
local Simulator = require "Simulator"

local scrollSpeed = 1.03
local tileSize = 10
local svgNS = "http://www.w3.org/2000/svg"
local Canvas = class()

function Canvas:init(id, geom, sim)

	self.svg = js.global.document:getElementById(id)
	self.svg.onmousemove = function(target, ev)
		self:onMouseMove(target, ev)
	end
	self.svg.onmousedown = function(target, ev)
		self:onMouseDown(target, ev)
	end
	self.svg.onmouseup = function() self:onMouseUp() end

	self.componentsLayer = self.svg:getElementById "componentsLayer"
	self.transistorsLayer = self.svg:getElementById "transistorsLayer"
	self.bridgesLayer = self.svg:getElementById "bridgesLayer"

	self:createSelectRect()

	self.svg.onwheel = function(target, e)
		e:preventDefault()
		self:zoom(e.deltaY > 0 and scrollSpeed or 1/scrollSpeed)
	end

	self.geom = geom
	self.simulator = sim
	self.svgComponents = {}

	self.geom.componentUpdatedCB = function(comp)
		self:onComponentUpdated(comp)
	end

	self.geom.componentDestroyedCB = function(comp)
		self:onComponentDestroyed(comp)
	end

	local savePath = js.global.document:getElementById "savePath"
	local saveButton = js.global.document:getElementById "saveButton"
	saveButton.onclick = function()
		local path = savePath.value
		js.global:saveFile(self.geom:dumpComponents(), path)
	end

	self.saveBox = js.global.document:getElementById "saveBox"
	self.simulationBox = js.global.document:getElementById "simulationBox"
	self.simulationBoxValues = js.global.document:getElementById "simulationValues"
	self.simulationInputs = js.global.document:getElementById "simulationInputs"

	js.global.document.onkeydown = function(target, e)
		if e.target == js.global.document.body then
			self:handleKeyPress(e.key)
		end
	end

	local loadButton = js.global.document:getElementById "loadButton"
	loadButton.onchange = function(target, e)
		self:loadFile(e.target.files[0])
	end

	local loadToClipboardButton = js.global.document:getElementById "loadToClipboardButton"
	loadToClipboardButton.onchange = function(target, e)
		self:loadFile(e.target.files[0], true)
	end

	self:toggleEdit()

	self.svg.oncontextmenu = function(t,e)
		e:preventDefault()
	end

	self.labelP = js.global.document:getElementById "labelP"
	self.labelP.style.display = "none"

	self.labelInput = js.global.document:getElementById "labelInput"
	self.labelInput.onchange = function(t,e)
		self:editLabel(self.labelInput.value)
	end
end

function Canvas:loadFile(file, toClipboard)

	if file == js.null then
		return
	end

	local reader = js.new(js.global.FileReader)
	reader.onloadend = function()

		if toClipboard then
			self:loadToClipboard(reader.result)
		else
			self.geom:loadComponents(reader.result)
			self:zoomToAll()
		end
	end

	reader:readAsText(file)
end

function Canvas:createSelectRect()

	local rect = js.global.document:createElementNS(svgNS, "rect")
	rect:setAttribute("width", tileSize)
	rect:setAttribute("height", tileSize)
	rect.classList:add("selectRect")

	self.svg:appendChild(rect)
	self.selectRect = rect
end

function Canvas:updateMousePosition(target,ev)

	assert(target == self.svg)
	local pt = target:createSVGPoint()

	pt.x = ev.clientX
	pt.y = ev.clientY

	local cursor = pt:matrixTransform(target:getScreenCTM():inverse());

	self.hoverX = cursor.x // tileSize
	self.hoverY = cursor.y // tileSize
end

function Canvas:onMouseMove(target, ev)

	self:updateMousePosition(target, ev)

	if not self.editMode then return end

	if self.dragStartX and self.dragStartY then

		local top = math.min(self.dragStartY, self.hoverY)
		local left = math.min(self.dragStartX, self.hoverX)

		local w = math.abs(self.dragStartX - self.hoverX) + 1
		local h = math.abs(self.dragStartY - self.hoverY) + 1

		self.selection = {left, top, w, h}
		self:updateSelectRect()

		self:updateLabelInput()
	end
end

function Canvas:updateSelectRect()

	if not self.selection then
		self.selectRect.style.display = "none"
		return
	end

	self.selectRect.style.display = "initial"

	local left,top,w,h = table.unpack(self.selection)

	self.selectRect:setAttribute("x", left * tileSize)
	self.selectRect:setAttribute("y", top * tileSize)
	self.selectRect:setAttribute("width", w * tileSize)
	self.selectRect:setAttribute("height", h * tileSize)
end

function Canvas:onMouseDown(target, ev)

	if not self.editMode then return end

	self:onMouseMove(target, ev)

	self.dragStartX = self.hoverX
	self.dragStartY = self.hoverY

	self:onMouseMove(target, ev)
end

function Canvas:onMouseUp()
	self.dragStartX = nil
	self.dragStartY = nil
end

function Canvas:deselect()
	self.selection = nil
	self.selectRect.style.display = "none"

	self:updateLabelInput()
end

function Canvas:setTile(x,y,type)
	self.geom:setTile(x,y,type)
end

function Canvas:resetTile(x,y,type)
	self.geom:resetTile(x,y,type)
end

function Canvas:fill(type)

	if not self.selection then
		return
	end

	local minx,miny,w,h = table.unpack(self.selection)

	for x = minx, minx + w - 1 do
		for y = miny, miny + h - 1 do

			if type == "reset" then
				self:resetTile(x,y)
			elseif type == "resetBridge" then
				self:resetTile(x,y,"bridge")
			else
				self:setTile(x,y,type)
			end
		end
	end

	self.geom:updateComponents()
	self:updateLabelInput()
end

function Canvas:zoom(factor)

	local viewBox = self.svg:getAttribute "viewBox"
	local minx, miny, w, h = viewBox:match("(%S+) (%S+) (%S+) (%S+)")

	minx = tonumber(minx)
	miny = tonumber(miny)
	w = tonumber(w)
	h = tonumber(h)

	local cx, cy = self.hoverX * tileSize, self.hoverY * tileSize

	local newminx = (minx - cx) * factor + cx
	local newminy = (miny - cy) * factor + cy
	local neww = w * factor
	local newh = h * factor

	local newBox = string.format("%f %f %f %f",
		newminx, newminy, neww, newh)

	self.svg:setAttribute("viewBox", newBox)
end

function Canvas:handleKeyPress(key)

	if key == "Escape" then
		self:deselect()

	elseif key == "e" then
		self:toggleEdit()
	elseif key == "E" then
		self:toggleEdit("steps")
	end

	if self.editMode then
		if key == "w" then
			self:fill("wire")
		elseif key == "p" then
			self:fill("power")
		elseif key == "g" then
			self:fill("ground")
		elseif key == "t" then
			self:fill("transistor")
		elseif key == "b" then
			self:fill("bridge")
		elseif key == "Backspace" then
			self:fill("reset")
		elseif key == "B" then
			self:fill("resetBridge")
		elseif key == "x" then
			self:editCut()
		elseif key == "c" then
			self:editCut("copy")
		elseif key == "v" then
			self:editPaste()
		elseif key == "m" then
			self:editMirror(true)
		elseif key == "M" then
			self:editMirror(false)
		elseif key == "r" then
			self:editRotate()
		elseif key == "." then
			for comp in pairs(self.geom.components) do
				self.geom:updateConnections(comp)
			end
		end
	end
end

function Canvas:onComponentDestroyed(comp)

	self.svgComponents[comp]:remove()
	self.svgComponents[comp] = nil

end

function Canvas:onComponentUpdated(comp)

	-- Callback is for updated/created
	-- We just delete-remake

	if self.svgComponents[comp] then
		self:onComponentDestroyed(comp)
	end

	-- Polygon!

	local poly = comp.polygon
	local str = {}

	for _, path in ipairs(poly) do
		for i,point in ipairs(path) do
			str[#str + 1] = string.format("%s%d %d",
				i == 1 and "M" or "L",
				point[1] * tileSize,
				point[2] * tileSize)
		end
		str[#str + 1] = "Z"
	end

	str = table.concat(str, " ")

	local group = js.global.document:createElementNS(svgNS, "g")

	local svg = js.global.document:createElementNS(svgNS, "path")
	svg:setAttribute("d", str)
	svg.classList:add("component")
	svg.classList:add(comp.type)

	group:appendChild(svg)

	-- Transistor specials

	if comp.type == "transistor" then

		if comp.invalid then
			svg.classList:add "invalid"
		else

			local ds = js.global.document:createElementNS(svgNS, "line")
			ds:setAttribute("x1", (comp.sd1Tile.x + 0.5) * tileSize)
			ds:setAttribute("y1", (comp.sd1Tile.y + 0.5) * tileSize)
			ds:setAttribute("x2", (comp.sd2Tile.x + 0.5) * tileSize)
			ds:setAttribute("y2", (comp.sd2Tile.y + 0.5) * tileSize)
			ds.classList:add "drain-source"

			group:appendChild(ds)
		end
	end

	-- Bridge endpoints

	if comp.type == "bridge" then

		for _,tile in ipairs(comp.endpoints) do
			local ep = js.global.document:createElementNS(svgNS, "circle")
			ep:setAttribute("r", tileSize / 4)
			ep:setAttribute("cx", (tile.x + 0.5) * tileSize)
			ep:setAttribute("cy", (tile.y + 0.5) * tileSize)
			ep.classList:add("endpoint")

			group:appendChild(ep)
		end
	end

	-- Pinnable wires

	if comp.type == "wire" then
		svg.onmousedown = function(t, e)
			if not self.editMode then
				self:setPin(comp, e.button == 0 and "high" or "low")
			end
		end

		local labelTile = self.geom:getComponentLabel(comp)
		if labelTile then
			local txt = js.global.document:createElementNS(svgNS, "text")
			txt:setAttribute("class", "label")
			txt:setAttribute("x", (labelTile.x + 0.5) * tileSize)
			txt:setAttribute("y", (labelTile.y + 0.5) * tileSize)
			txt.innerHTML = labelTile.label

			group:appendChild(txt)
		end
	end

	-- Add to canvas!

	local layer

	if comp.type == "transistor" then
		layer = self.transistorsLayer
	elseif comp.type == "bridge" then
		layer = self.bridgesLayer
	else
		layer = self.componentsLayer
	end

	layer:appendChild(group)
	self.svgComponents[comp] = group

	-- Fun stuff

	svg.onmouseenter = function(target)
		if self.editMode then
			for adj in pairs(comp.connected) do
				self.svgComponents[adj].classList:add "connected"
			end
		end
	end

	svg.onmouseout = function(target)
		if self.editMode then
			for adj in pairs(comp.connected) do
				self.svgComponents[adj].classList:remove "connected"
			end
		end
	end
end

function Canvas:toggleEdit(steps)

	self.editMode = not self.editMode

	self.saveBox.style.display = self.editMode and "initial" or "none"
	self.simulationBox.style.display = (not self.editMode) and "initial" or "none"

	if not self.editMode then
		self.selection = nil
		self:updateSelectRect()

		self.clipboard = nil

		self:startSimulation(steps)
	else
		self:stopSimulation()
	end
end

function Canvas:zoomToAll()
	local minx, miny = math.maxinteger, math.maxinteger
	local maxx, maxy = math.mininteger, math.mininteger
	for x,y,t in self.geom:iterTiles() do
		minx = math.min(minx, x - 1)
		miny = math.min(miny, y - 1)
		maxx = math.max(maxx, x + 1)
		maxy = math.max(maxy, y + 1)
	end

	local box = string.format("%f %f %f %f",
		minx * tileSize,
		miny * tileSize,
		(maxx - minx + 1) * tileSize,
		(maxy - miny + 1) * tileSize)

	self.svg:setAttribute("viewBox", box)
end

function Canvas:editCut(copy)

	if not self.selection then
		return
	end

	local clipboard = {}
	local left,top,w,h = table.unpack(self.selection)

	for i = left, left + w - 1 do
		for j = top, top + h - 1 do

			local tile = self.geom:getTile(i,j)

			if tile and tile.type then
				table.insert(clipboard, {tile.x - left, tile.y - top, tile.type, tile.label})
				if not copy then
					self:resetTile(i,j)
				end
			end

			if tile and tile.bridge then
				table.insert(clipboard, {tile.x - left, tile.y - top, "bridge"})
				if not copy then
					self:resetTile(i,j,"bridge")
				end
			end
		end
	end

	self.clipboard = clipboard
	self.geom:updateComponents()
end

function Canvas:loadToClipboard(str)
	local loader = load("return " .. str)
	if not loader then
		print "Invalid tile dump"
		return
	end

	local clipboard = {}

	local tiles = loader()
	for i,tile in ipairs(tiles) do

		if tile.type then
			table.insert(clipboard, {tile.x, tile.y, tile.type, tile.label})
		end
		if tile.bridge then
			table.insert(clipboard, {tile.x, tile.y, "bridge"})
		end
	end
	self.clipboard = clipboard
end

function Canvas:editPaste()
	if not self.selection or not self.clipboard then
		return
	end

	local left,top,w,h = table.unpack(self.selection)

	for i = left, left + w - 1 do
		for j = top, top + h - 1 do
			self:resetTile(i, j)
			self:resetTile(i, j, "bridge")
		end
	end

	for _,tile in ipairs(self.clipboard) do
		local x,y = tile[1] + left, tile[2] + top
		self:setTile(x, y, tile[3])
		if tile[4] then
			self.geom:setLabel(self.geom:getTile(x,y), tile[4])
		end
	end

	self.geom:updateComponents()
end

function Canvas:editMirror(vertical)

	self:editCut()

	local left,top,w,h = table.unpack(self.selection)

	for _,t in ipairs(self.clipboard) do
		if vertical then
			t[1] = w - t[1] - 1
		else
			t[2] = h - t[2] - 1
		end
	end

	self:editPaste()
end

function Canvas:editRotate()

	self:editCut()

	local left,top,w,h = table.unpack(self.selection)
	local cx = w // 2
	local cy = h // 2

	for _,t in ipairs(self.clipboard) do
		t[1], t[2] = -(t[2] - cy) + cx, (t[1] - cx) + cy
	end

	self:editPaste()

	self.selection = {left - h + 1 + cx + cy, top - cx + cy, h, w}
	self:updateSelectRect()
end

function Canvas:resetValue(comp)
	local svg = self.svgComponents[comp]
	if not svg then return end

	svg.classList:remove "low"
	svg.classList:remove "high"
	svg.classList:remove "unstable"
	svg.classList:remove "floating"
	svg.classList:remove "pinned"
end

function Canvas:onValueChanged(comp, value)
	self:resetValue(comp)

	local svg = self.svgComponents[comp]
	svg.classList:add(value)

	if self.simulator.pins[comp] then
		svg.classList:add "pinned"
	end

	self:updateSimulationBox()
end

local function stepSimulation(wrap)

	local res = wrap()

	if res == "paused" then
		js.global:setTimeout(function() stepSimulation(wrap) end, 100)
	end
end

function Canvas:setPin(comp, val)
	local old = self.simulator.pins[comp]

	if val == old then
		val = nil
	end

	if val then
		self.svgComponents[comp].classList:add "pinned"
	else
		self.svgComponents[comp].classList:remove "pinned"
	end

	local wrap = coroutine.wrap(function()
		self.simulator:setPin(comp, val)
	end)

	stepSimulation(wrap)
end

function Canvas:startSimulation(stepped)

	self.simulator.stepped = stepped

	self.simulator.valueChangedCB = function(comp, value)
		self:onValueChanged(comp, value)
	end

	local wrap = coroutine.wrap(function()
		self.simulator:setup("stepped")
	end)

	stepSimulation(wrap)

	self:updateSimulationBox()
end

function Canvas:stopSimulation()
	for comp,svg in pairs(self.svgComponents) do
		self:resetValue(comp)
	end
end


function Canvas:updateLabelInput()

	local show = false
	local text = ""

	if self.selection then
		local left,top,w,h = table.unpack(self.selection)
		local tile = self.geom:getTile(left,top)

		if tile and tile.type =="wire" and w == 1 and h == 1 then
			show = true
			text = tile.label or ""
		end
	end

	self.labelP.style.display = show and "initial" or "none"
	if show then
		self.labelInput.value = text
	end
end

function Canvas:editLabel(value)
	assert(self.selection)

	local left,top,w,h = table.unpack(self.selection)
	local tile = self.geom:getTile(left,top)

	assert(tile and tile.type == "wire")

	if value == "" then value = nil end

	self.geom:setLabel(tile, value)
	self:onComponentUpdated(tile.component)
end

function Canvas:updateSimulationBox()

	-- Values

	local res = {}
	for k,v in pairs(self.simulator.named) do
		local val = self.simulator.values[v]
		table.insert(res, k .. ": " .. val)
	end

	for k in pairs(self.simulator.numbers) do
		local val = self.simulator:readNumber(k)
		table.insert(res, k .. ": " .. val)
	end

	res = table.concat(res, "</br>")

	self.simulationBoxValues.innerHTML = res

	-- Inputs

	self.simulationInputs.innerHTML = ""

	for k in pairs(self.simulator.numbers) do
		local input = js.global.document:createElement "input"
		input:setAttribute("type", "text")
		input:setAttribute("placeholder", k)

		input.onchange = function()
			local wrap = coroutine.wrap(function()
				self.simulator:setNumber(k, tonumber(input.value))
			end)
			stepSimulation(wrap)
		end

		self.simulationInputs:appendChild(input)

	end
end

return Canvas
