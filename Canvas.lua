local class = require "class"
local js = require "js"
local Geom = require "Geom"
local Simulator = require "Simulator"
local polygonize = require "polygonize"

local scrollSpeed = 1.03
local tileSize = 10
local svgNS = "http://www.w3.org/2000/svg"
local Canvas = class()

function Canvas:init(id)

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

	self.geom = Geom()
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
		self:downloadFile(path, self.geom:dumpTiles())
	end

	self.saveBox = js.global.document:getElementById "saveBox"

	js.global.document.onkeydown = function(target, e)
		if e.target ~= savePath then
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
end

function Canvas:downloadFile(path, content)

	local element = js.global.document:createElement "a"
	element:setAttribute('href', 'data:text/plain;charset=utf-8,' .. js.global:encodeURIComponent(content))
	element:setAttribute('download', path);

	element.style.display = 'none'
	js.global.document.body:appendChild(element)

	element:click()

	js.global.document.body:removeChild(element)
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
			self.geom:loadTiles(reader.result)
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

		self.selectRect:setAttribute("x", left * tileSize)
		self.selectRect:setAttribute("y", top * tileSize)
		self.selectRect:setAttribute("width", w * tileSize)
		self.selectRect:setAttribute("height", h * tileSize)

		self.selection = {left, top, w, h}
		self.selectRect.style.display = "initial"
	end
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
	self.selectRect.classList:add("hidden")
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

	local poly = polygonize(comp)
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

	local svg = js.global.document:createElementNS(svgNS, "path")
	svg:setAttribute("d", str)
	svg.classList:add("component")
	svg.classList:add(comp.type)

	-- Transistor specials

	if comp.type == "transistor" then

		if comp.invalid then
			svg.classList:add "invalid"
		else

			local group = js.global.document:createElementNS(svgNS, "g")
			group:appendChild(svg)

			local ds = js.global.document:createElementNS(svgNS, "line")
			ds:setAttribute("x1", (comp.sd1Tile.x + 0.5) * tileSize)
			ds:setAttribute("y1", (comp.sd1Tile.y + 0.5) * tileSize)
			ds:setAttribute("x2", (comp.sd2Tile.x + 0.5) * tileSize)
			ds:setAttribute("y2", (comp.sd2Tile.y + 0.5) * tileSize)
			ds.classList:add "drain-source"

			group:appendChild(ds)
			svg = group
		end
	end

	-- Bridge endpoints

	if comp.type == "bridge" then

		local group = js.global.document:createElementNS(svgNS, "g")
		group:appendChild(svg)

		for _,tile in ipairs(comp.endpoints) do
			local ep = js.global.document:createElementNS(svgNS, "circle")
			ep:setAttribute("r", tileSize / 4)
			ep:setAttribute("cx", (tile.x + 0.5) * tileSize)
			ep:setAttribute("cy", (tile.y + 0.5) * tileSize)
			ep.classList:add("endpoint")

			group:appendChild(ep)
		end

		svg = group
	end

	-- Pinnable wires

	if comp.type == "wire" then
		svg.onmousedown = function(t, e)
			if not self.editMode then
				self:setPin(comp, e.button == 0 and "high" or "low")
			end
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

	layer:appendChild(svg)
	self.svgComponents[comp] = svg

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

	if not self.editMode then
		self.selection = nil
		self.clipboard = nil
		self.selectRect.style.display = "none"

		self:startSimulation(steps)
	else
		self:stopSimulation()
	end
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
				table.insert(clipboard, {tile.x - left, tile.y - top, tile.type})
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
			table.insert(clipboard, {tile.x, tile.y, tile.type})
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

	for _,tile in ipairs(self.clipboard) do
		self:setTile(tile[1] + left, tile[2] + top, tile[3])
	end

	self.geom:updateComponents()
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
end

local function stepSimulation(wrap)

	local res = wrap()

	if res == "paused" then
		js.global:setTimeout(function() stepSimulation(wrap) end, 300)
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

	self.simulator = Simulator(self.geom)
	self.simulator.stepped = stepped

	self.simulator.valueChangedCB = function(comp, value)
		self:onValueChanged(comp, value)
	end

	local wrap = coroutine.wrap(function()
		self.simulator:setup("stepped")
	end)

	stepSimulation(wrap)
end



function Canvas:stopSimulation()
	for comp,svg in pairs(self.svgComponents) do
		self:resetValue(comp)
	end

	self.simulator = nil
end

return Canvas
