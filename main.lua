package.path = "./?.lua"

local js = require "js"
local Canvas = require "Canvas"
local Geom = require "Geom"
local Simulator = require "Simulator"

local function init()

	local geom = Geom()
	local sim = Simulator(geom)
	local canvas = Canvas("canvas", geom, sim)

end

init()
