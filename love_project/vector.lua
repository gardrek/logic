-- Generic vector class
local vector = {}
setmetatable(vector, vector)

vector.names = {'x', 'y', 'z', 'w'}

vector.__index = function(table, key)
  for i = 1, #vector.names do
    if key == vector.names[i] then
      return table:getElement(i)
    end
  end
  if table[key] then
    return table[key]
  elseif vector[key] then
    return vector[key]
  end
end

function vector:new(t)
  local obj
  if type(t) == 'number' then
    obj = {}
    for i = 1, t do
      obj[i] = 0
    end
    t = obj
  elseif type(t) ~= 'table' then
    error('Bad argument to vector:new()', 2)
  end
  obj = vector.dup(t)
  setmetatable(obj, getmetable(self))
  return obj
end

function vector:dup()
  local obj = {}
  for i = 1, #vector.names do
    if self[vector.names[i]] then
      obj[i] = self[vector.names[i]]
    else
      obj[i] = self[i]
    end
  end
  setmetatable(obj, getmetable(self))
  return obj
end

function vector:getElement(i)
  return self[i]
end

function vector:setElement(i, v)
  self[i] = v
end



local vec2 = {}



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

