local js = require "js"
local Canvas = require "Canvas"
local Selector = require "Selector"

local function init()

	local selector = Selector("selector")
	local canvas = Canvas("canvas", selector)
end

init()
