local class = require "class"

local Queue = class()

function Queue:init()
    self.b = 1
    self.e = 0
end

function Queue:empty()
    return self.e < self.b
end

function Queue:push(v)
    self.e = self.e + 1
    self[self.e] = v
end

function Queue:pop()

    if self.e < self.b then
        return nil
    end

    local elem = self[self.b]
    self.b = self.b + 1
    return elem
end

local test = function()

    local t = Queue()

    assert(t:empty())
	assert(t:pop() == nil)

	t:push(10)
	
	assert(not t:empty())
	assert(t:pop() == 10)

    assert(t:empty())

	t:push("a")
	t:push("b")
	t:push("c")

	assert(t:pop() == "a")
	assert(t:pop() == "b")
	assert(t:pop() == "c")
	assert(t:pop() == nil)

end

test()

return
{
    Queue = Queue
}
