local class = require "class"
local js = require "js"

local tileSize = 10
local svgNS = "http://www.w3.org/2000/svg"
local Canvas = class()

function Canvas:init(id)

	self.svg = js.global.document:getElementById(id)
	self.svg.onmousemove = function(target, ev)
		self:onMouseMove(target, ev)
	end

	self:createHoverRect()
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

	local x,y = cursor.x // tileSize * tileSize, cursor.y // tileSize * tileSize
	self.hoverRect:setAttribute("x", x)
	self.hoverRect:setAttribute("y", y)
end

return Canvas
