local class = require "class"
local js = require "js"

local tileSize = 10
local svgNS = "http://www.w3.org/2000/svg"
local Canvas = class()

function Canvas:init(id, selector)

	self.svg = js.global.document:getElementById(id)
	self.svg.onmousemove = function(target, ev)
		self:onMouseMove(target, ev)
	end

	self.svg.onclick = function() self:onClick() end
	self:createHoverRect()

	self.selector = selector

	self.tiles = {}
end

function Canvas:createHoverRect()

	local rect = js.global.document:createElementNS(svgNS, "rect")
	rect:setAttribute("width", tileSize)
	rect:setAttribute("height", tileSize)
	rect.classList:add("hoverRect")

	self.svg:appendChild(rect)
	self.hoverRect = rect

end

function Canvas:onMouseMove(target, ev)

	assert(target == self.svg)
	local pt = target:createSVGPoint()

	pt.x = ev.clientX
	pt.y = ev.clientY

	local cursor = pt:matrixTransform(target:getScreenCTM():inverse());

	self.hoverX = cursor.x // tileSize
	self.hoverY = cursor.y // tileSize

	self.hoverRect:setAttribute("x", self.hoverX * tileSize)
	self.hoverRect:setAttribute("y", self.hoverY * tileSize)

	if ev.buttons ~= 0 then
		self:onClick()
	end
end

function Canvas:onClick()

	local tileType = self.selector:getSelectedType()
	self:setTile(self.hoverX, self.hoverY, tileType)

end

function Canvas:setTile(x,y,type)

	if not self.tiles[x] then
		self.tiles[x] = {}
	end

	local previous = self.tiles[x][y]

	if type == "none" then
		if previous then
			self.svg:removeChild(previous.elem)
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
		self.svg:appendChild(rect)

		previous = { elem = rect }
		self.tiles[x][y] = previous
	end

	previous.type = type
	local elem = previous.elem

	elem.classList:remove(elem.classList[1])
	elem.classList:add(type)
end

return Canvas
