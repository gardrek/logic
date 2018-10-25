-- Generic Vector class, with any number of elements
local Vector = {}
--setmetatable(Vector, Vector)
Vector.class = 'Vector'

Vector.name = {
  x = 1, y = 2, z = 3,
}

Vector.__index = function(table, key)
  if Vector.name[key] then
    return rawget(table, Vector.name[key])
  elseif rawget(table, key) then
    return rawget(table, key)
  elseif rawget(Vector, key) then
    return rawget(Vector, key)
  end
end

function Vector:new(t)
  local obj
  if type(t) == 'number' then
    obj = {}
    for i = 1, t do
      obj[i] = 0
    end
    t = obj
  elseif type(t) ~= 'table' then
    error('Bad argument to Vector:new() of type ' .. type(t), 2)
  end
  obj = Vector.dup(t)
  --setmetatable(obj, getmetatable(self))
  setmetatable(obj, Vector)
  return obj
end

Vector.__call = function(...)
  return Vector:new(...)
end

function Vector:dup()
  local obj = {}
  for i = 1, #self do
    obj[i] = self[i]
  end
  for n, i in pairs(Vector.name) do
    if self[Vector.name[n]] then
      obj[i] = self[Vector.name[n]]
    end
  end
  setmetatable(obj, getmetatable(self) or Vector)
  return obj
end

function Vector:getElement(i)
  return self[i]
end

function Vector:setElement(i, v)
  self[i] = v
end

function Vector:mag()
  return math.sqrt(self:magsqr())
end

function Vector:magsqr()
  local m = 0
  for i = 1, #self do
    m = m + self[i] * self[i]
  end
  return m
end

function Vector:__add(other)
  local r = Vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] + other
    end
  else
    if #self ~= #other then error('Attempt to add unlike Vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] + other[i]
    end
  end
  return r
end

function Vector:__sub(other)
  local r = Vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] - other
    end
  else
    if #self ~= #other then error('Attempt to subtract unlike Vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] - other[i]
    end
  end
  return r
end

function Vector:__mul(other)
  local r = Vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] * other
    end
  else
    if #self ~= #other then error('Attempt to multiply unlike Vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] * other[i]
    end
  end
  return r
end

function Vector:__div(other)
  local r = Vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] / other
    end
  else
    if #self ~= #other then error('Attempt to divide unlike Vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] / other[i]
    end
  end
  return r
end

function Vector:__unm()
  local r = Vector:new(#self)
  for i = 1, #self do
    r[i] = -self[i]
  end
  return r
end

function Vector:norm()
  return self / self:mag()
end

function Vector:__tostring()
  local s = '('
  for i = 1, #self do
    s = s .. tostring(self[i])
    if i ~= #self then
      s = s .. ', '
    end
  end
  return s .. ')'
end

function Vector:__eq(other)
  if #self ~= #other then return false end
  for i = 1, #self do
    if self[i] ~= other[i] then
      return false
    end
  end
  return true
end

-- 2D-only functions

function Vector:rotate(angle)
  if #self ~= 2 then error('Rotation of non-2D Vectors not implemented', 2) end
  local cs, ns, nx, ny
  cs, sn = math.cos(angle), math.sin(angle)
  nx = self.x * cs - self.y * sn
  ny = self.x * sn + self.y * cs
  return Vector:new{nx, ny}
end

function Vector:draw(x, y, scale, arrow)
  if #self ~= 2 then error('Drawing of non-2D Vectors not implemented', 2) end
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

function Vector:unpack()
  local t = {}
  for i = 1, #self do
    t[i] = self[i]
  end
  return unpack(t)
end

return Vector
