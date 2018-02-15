-- Generic vector class
local vector = {}
setmetatable(vector, vector)

vector.name = {
  x = 1, y = 2, z = 3,
}

vector.__index = function(table, key)
  if vector.name[key] then
    return rawget(table, vector.name[key])
  elseif rawget(table, key) then
    return rawget(table, key)
  elseif rawget(vector, key) then
    return rawget(vector, key)
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
    error('Bad argument to vector:new() of type ' .. type(t), 2)
  end
  obj = vector.dup(t)
  setmetatable(obj, getmetatable(self))
  return obj
end

vector.__call = function(...)
  return vector:new(...)
end

function vector:dup()
  local obj = {}
  for i = 1, #self do
    obj[i] = self[i]
  end
  for n, i in pairs(vector.name) do
    if self[vector.name[n]] then
      obj[i] = self[vector.name[n]]
    end
  end
  setmetatable(obj, getmetatable(self))
  return obj
end

function vector:getElement(i)
  return self[i]
end

function vector:setElement(i, v)
  self[i] = v
end

function vector:mag()
  return math.sqrt(self:magsqr())
end

function vector:magsqr()
  local m = 0
  for i = 1, #self do
    m = m + self[i] * self[i]
  end
  return m
end

function vector:__add(other)
  local r = vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] + other
    end
  else
    if #self ~= #other then error('Attempt to add unlike vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] + other[i]
    end
  end
  return r
end

function vector:__sub(other)
  local r = vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] - other
    end
  else
    if #self ~= #other then error('Attempt to subtract unlike vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] - other[i]
    end
  end
  return r
end

function vector:__mul(other)
  local r = vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] * other
    end
  else
    if #self ~= #other then error('Attempt to multiply unlike vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] * other[i]
    end
  end
  return r
end

function vector:__div(other)
  local r = vector:new(#self)
  if type(other) == 'number' then
    for i = 1, #self do
      r[i] = self[i] / other
    end
  else
    if #self ~= #other then error('Attempt to divide unlike vectors.', 2) end
    for i = 1, #self do
      r[i] = self[i] / other[i]
    end
  end
  return r
end

function vector:__unm()
  local r = vector:new(#self)
  for i = 1, #self do
    r[i] = -self[i]
  end
  return r
end

function vector:norm()
  return self / self:mag()
end

function vector:__tostring()
  local s = '('
  for i = 1, #self do
    s = s .. tostring(self[i])
    if i ~= #self then
      s = s .. ', '
    end
  end
  return s .. ')'
end

function vector:__eq(other)
  if #self ~= #other then return false end
  for i= 1, #self do
    if self[i] ~= other[i] then
      return false
    end
  end
  return true
end

-- 2D-only functions

function vector:rotate(angle)
  if #self ~= 2 then error('Rotation of non-2D vectors not implemented', 2) end
  local cs, ns, nx, ny
  cs, sn = math.cos(angle), math.sin(angle)
  nx = self.x * cs - self.y * sn
  ny = self.x * sn + self.y * cs
  return vector:new{nx, ny}
end

function vector:draw(x, y, scale, arrow)
  if #self ~= 2 then error('Drawing of non-2D vectors not implemented', 2) end
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

function vector:unpack()
  local t = {}
  for i = 1, #self do
    t[i] = self[i]
  end
  return unpack(t)
end

return vector

