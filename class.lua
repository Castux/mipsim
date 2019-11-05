local function class()

	local t = {}
	setmetatable(t,
	{
		__call = function(_, ...)

			local instance = {}
			setmetatable(instance, t)
			instance:init(...)

			return instance
		end
	})

	t.__index = t

	return t
end


return class
