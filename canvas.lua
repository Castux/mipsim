local class = require "class"
local js = require "js"

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

	self.mainLayer = self.svg:getElementById "mainLayer"
	self.bridgeLayer = self.svg:getElementById "bridgeLayer"

	self:createSelectRect()

	self.tiles = {}
	self.bridges = {}

	self.tileDumpArea = js.global.document:getElementById "tileDump"
	self.tileDumpArea.onchange = function()
		self:loadTiles(self.tileDumpArea.value)
	end

	self.svg.onwheel = function(target, e)
		e:preventDefault()
		self:zoom(e.deltaY > 0 and scrollSpeed or 1/scrollSpeed)
	end

	js.global.document.onkeydown = function(target, e)
		self:handleKeyPress(e.key)
	end

	self.background = self.svg:getElementById "background"
end

function Canvas:createSelectRect()

	local rect = js.global.document:createElementNS(svgNS, "rect")
	rect:setAttribute("width", tileSize)
	rect:setAttribute("height", tileSize)
	rect.classList:add("selectRect")
	rect.classList:add("hidden")

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

	if self.dragStartX and self.dragStartY then

		local top = math.min(self.dragStartY, self.hoverY)
		local left = math.min(self.dragStartX, self.hoverX)

		local w = math.abs(self.dragStartX - self.hoverX) + 1
		local h = math.abs(self.dragStartY - self.hoverY) + 1

		self.selectRect:setAttribute("x", left * tileSize)
		self.selectRect:setAttribute("y", top * tileSize)
		self.selectRect:setAttribute("width", w * tileSize)
		self.selectRect:setAttribute("height", h * tileSize)
		self.selectRect.classList:remove("hidden")

		self.selection = {left, top, w, h}
	end
end

function Canvas:onMouseDown(target, ev)

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

	if not self.tiles[x] then
		self.tiles[x] = {}
	end

	local previous = self.tiles[x][y]

	if type == "none" then
		if previous then
			self.mainLayer:removeChild(previous.elem)
			self.tiles[x][y] = nil
		end

		return
	end

	if not previous then
		local rect = js.global.document:createElementNS(svgNS, "rect")
		rect:setAttribute("width", tileSize)
		rect:setAttribute("height", tileSize)
		rect:setAttribute("x", x * tileSize)
		rect:setAttribute("y", y * tileSize)
		rect.classList:add("tile")
		rect.classList:add("dummy")
		self.mainLayer:appendChild(rect)

		previous = { elem = rect }
		self.tiles[x][y] = previous
	end

	previous.type = type
	local elem = previous.elem

	elem.classList:remove(elem.classList[1])
	elem.classList:add(type)
end

function Canvas:toggleBridge(x,y)

	if not self.bridges[x] then
		self.bridges[x] = {}
	end

	local previous = self.bridges[x][y]

	if previous then
		self.bridgeLayer:removeChild(previous)
		self.bridges[x][y] = nil
		return
	end

	local rect = js.global.document:createElementNS(svgNS, "rect")
	rect:setAttribute("width", tileSize)
	rect:setAttribute("height", tileSize)
	rect:setAttribute("x", x * tileSize)
	rect:setAttribute("y", y * tileSize)
	rect.classList:add("tile")
	rect.classList:add("bridge")
	self.bridgeLayer:appendChild(rect)

	self.bridges[x][y] = rect
end

function Canvas:dumpTiles()
	local res = {}
	for i,row in pairs(self.tiles) do
		for j,w in pairs(row) do
			local str = string.format("{%d,%d,%q}", i, j, w.type)
			table.insert(res, str)
		end
	end

	for i,row in pairs(self.bridges) do
		for j,w in pairs(row) do
			local str = string.format("{%d,%d,%q}", i, j, "bridge")
			table.insert(res, str)
		end
	end

	return "{" .. table.concat(res, ",") .. "}"
end

function Canvas:clearTiles()

	for i,row in pairs(self.tiles) do
		for j,w in pairs(row) do
			self.mainLayer:removeChild(w.elem)
			self.tiles[i][j] = nil
		end
	end

	for i,row in pairs(self.bridges) do
		for j,w in pairs(row) do
			self.bridgeLayer:removeChild(w)
			self.bridges[i][j] = nil
		end
	end

end

function Canvas:loadTiles(str)

	self:clearTiles()
	local newTilesLoader = load("return " .. str)
	if not newTilesLoader then
		print "Invalid tile dump"
		return
	end

	local tiles = newTilesLoader()
	for _,t in ipairs(tiles) do
		if t[3] == "bridge" then
			self:toggleBridge(t[1], t[2])
		else
			self:setTile(t[1], t[2], t[3])
		end
	end
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

	self.background:setAttribute("width", neww)
	self.background:setAttribute("height", newh)
	self.background:setAttribute("x", newminx)
	self.background:setAttribute("y", newminy)
end

function Canvas:handleKeyPress(key)

	if key == "Escape" then
		self:deselect()

	elseif key == "w" and self.selection then

	end

end

return Canvas
