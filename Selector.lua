local class = require "class"
local js = require "js"
local sim = require "simulation"
local utils = require "utils"

local Selector = class()

function Selector:init(id)

	self.elem = js.global.document:getElementById(id)

	self.buttons = {}

	for i = 0,self.elem.children.length - 1 do
		local child = self.elem.children[i]
		local type = child.classList[1]

		assert(utils.table_contains(sim.wireTypes, type))

		self.buttons[child] = type

		child.onclick = function(target, ev)
			self:select(target)
		end
	end

	self.selected = nil
	self:select(self.elem.children[0])
end

function Selector:select(target)

	for button,type in pairs(self.buttons) do
		if button == target then
			button.classList:add "selected"
			self.selected = button
		else
			button.classList:remove "selected"
		end
	end
end

function Selector:getSelectedType()
	return self.buttons[self.selected]
end

return Selector
