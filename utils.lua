local utils = {}

function utils.table_contains(tab, elem)

	for k,v in pairs(tab) do
		if v == elem then
			return true
		end
	end

	return false
end


return utils
