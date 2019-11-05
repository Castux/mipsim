local class = require "class"
local js = require "js"

local Selector = class()

function Selector:init(id)

	self.elem = js.global.document:getElementById(id)

	self.buttons = {}

	for i = 0,self.elem.children.length - 1 do
		local child = self.elem.children[i]
		table.insert(self.buttons, child)

		child.onclick = function(target, ev)
			self:select(target)
		end
	end

	self:select(self.buttons[1])
end

function Selector:select(target)

	for _, button in ipairs(self.buttons) do
		if button == target then
			button.classList:add "selected"
		else
			button.classList:remove "selected"
		end
	end
end

return Selector
