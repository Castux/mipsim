local fp = io.popen("ls test-*.lua")

for file in fp:read("a"):gmatch("%S+") do
	if file ~= "test-all.lua" then
		dofile(file)
	end
end
