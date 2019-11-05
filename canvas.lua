local class = require "class"
local js = require "js"
local Geom = require "Geom"

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

	self.geom = Geom()
	self.tileRects = {}
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

	self.geom:setTile(x,y,type)

	local typeHash = type == "bridge" and "b" or ""
	local elem = self.tileRects[x .. ":" .. y .. typeHash]

	if not elem then
		local rect = js.global.document:createElementNS(svgNS, "rect")
		rect:setAttribute("width", tileSize)
		rect:setAttribute("height", tileSize)
		rect:setAttribute("x", x * tileSize)
		rect:setAttribute("y", y * tileSize)
		rect.classList:add("tile")
		rect.classList:add("dummy")

		local layer = type == "bridge" and self.bridgeLayer or self.mainLayer
		layer:appendChild(rect)

		elem = rect
		self.tileRects[x .. ":" .. y .. typeHash] = elem
	end

	elem.classList:remove(elem.classList[1])
	elem.classList:add(type)
end

function Canvas:resetTile(x,y,type)

	self.geom:resetTile(x,y,type)

	local typeHash = type == "bridge" and "b" or ""
	local elem = self.tileRects[x .. ":" .. y .. typeHash]

	if elem then
		elem:remove()
		self.tileRects[x .. ":" .. y .. typeHash] = nil
	end
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
end

function Canvas:clearTiles()

	self.geom:clearTiles()

	for k,v in pairs(self.tileRects) do
		v:remove()
		self.tileRects[k] = nil
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
		self:setTile(t[1], t[2], t[3])
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

	elseif key == "w" then
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
	end

	self.tileDumpArea.value = self.geom:dumpTiles()
end

return Canvas
