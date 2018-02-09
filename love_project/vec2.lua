-- Vector class
local vec2 = {}
vec2.__index = vec2

function vec2:new(x, y)
	local obj = {}
	if type(x) == 'number' and type(y) == 'number' then
		obj.x, obj.y = x, y
	else
		error('attempt to create vector with non-number values', 2)
	end
	setmetatable(obj, self)
	return obj
end

function vec2:mag()
	return math.sqrt(self.x * self.x + self.y * self.y)
end
vec2.__len = vec2.mag

function vec2:magsqr()
	return self.x * self.x + self.y * self.y
end

function vec2:rotate(angle)
	local cs, sn, nx, ny
	cs, sn = math.cos(angle), math.sin(angle)
	nx = self.x * cs - self.y * sn
	ny = self.x * sn + self.y * cs
	return vec2:new(nx, ny)
end

function vec2:__add(other)
	if type(other) == 'number' then
		return vec2:new(self.x + other, self.y + other)
	end
	if type(self) == 'number' then
		return vec2:new(self + other.x, self + other.y)
	end
	return vec2:new(self.x + other.x, self.y + other.y)
end

function vec2:__sub(other)
	if type(other) == 'number' then
		return vec2:new(self.x - other, self.y - other)
	end
	if type(self) == 'number' then
		return vec2:new(self - other.x, self - other.y)
	end
	return vec2:new(self.x - other.x, self.y - other.y)
end

function vec2:__mul(other)
	if type(other) == 'number' then
		return vec2:new(self.x * other, self.y * other)
	end
	if type(self) == 'number' then
		return vec2:new(self * other.x, self * other.y)
	end
	return vec2:new(self.x * other.x, self.y * other.y)
end

function vec2:__div(other)
	if type(other) == 'number' then
		return vec2:new(self.x / other, self.y / other)
	end
	if type(self) == 'number' then
		return vec2:new(self / other.x, self / other.y)
	end
	return vec2:new(self.x / other.x, self.y / other.y)
end

function vec2:__unm()
	return vec2:new(-self.x, -self.y)
end

function vec2:norm()
	return self / self:mag()
end

function vec2:__tostring()
	return '(' .. tostring(self.x) .. ', ' .. tostring(self.y) .. ')'
end

function vec2:draw(x, y, scale, arrow)
	if self:mag() ~= 0 then
		local t = self * scale
		if arrow > 0 then
			local a, b
			local m = t:mag() / arrow
			a = t:rotate(math.pi / 6):norm() * -m
			b = t:rotate(math.pi / -6):norm() * -m
			love.graphics.line(t.x + x, t.y + y, t.x + x + a.x, t.y + y + a.y)
			love.graphics.line(t.x + x, t.y + y, t.x + x + b.x, t.y + y + b.y)
		end
		love.graphics.line(x, y, t.x + x, t.y + y)
	end
end

return vec2
