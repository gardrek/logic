local Vector = require('Vector')

local Collider = {}
Collider.__index = Collider
Collider.class = 'Collider'

Collider.kinds = {
  'point',
  'rect',
  'circ',
}

Collider.overlapFunctions = {}

Collider.drawFunctions = {}

for _, kind in ipairs(Collider.kinds) do
  Collider[kind] = function(self, data)
    return self:new(kind, data)
  end
  Collider.overlapFunctions[kind] = {}
end

Collider.overlapFunctions.point.point = function(self, other)
  return other.center.x == self.center.x and other.center.y == self.center.y
end

Collider.overlapFunctions.point.rect = function(self, other)
  return
    self.center.x >= other.corner.x and
    self.center.y >= other.corner.y and
    self.center.x < other.corner.x + other.dim.x and
    self.center.y < other.corner.y + other.dim.y
end

Collider.overlapFunctions.point.circ = function(self, other)
  local distX, distY = other.center.x - self.center.x, other.center.y - self.center.y
  return distX * distX + distY * distY < other.radius * other.radius
end

Collider.overlapFunctions.rect.rect = function(self, other)
  return
    self.corner.x + self.dim.x > other.corner.x and
    self.corner.y + self.dim.y > other.corner.y and
    self.corner.x < other.corner.x + other.dim.x and
    self.corner.y < other.corner.y + other.dim.y
end

Collider.overlapFunctions.rect.circ = function(self, other)
  --error('circ-rect collision not yet implemented', 2)
  --local distX, distY = other.point.x - self.point.x, other.point.y - self.point.y
  --return math.sqrt(distX * distX + distY * distY) < other.radius
end

Collider.overlapFunctions.circ.circ = function(self, other)
  local distX, distY = other.center.x - self.center.x, other.center.y - self.center.y
  return distX * distX + distY * distY < other.radius * other.radius + self.radius * self.radius
end

Collider.overlapFunctions.rect.point = function(self, other)
  return Collider.overlapFunctions.point.rect(other, self)
end

Collider.overlapFunctions.circ.point = function(self, other)
  return Collider.overlapFunctions.point.circ(other, self)
end

Collider.overlapFunctions.circ.rect = function(self, other)
  return Collider.overlapFunctions.rect.circ(other, self)
end

function Collider:new(kind, data)
  return setmetatable({kind = tostring(kind)}, Collider):set(data)
end

function Collider:set(data)
  if self.kind == 'point' then
    assert(
      type(data[1]) == 'number' and
      type(data[2]) == 'number'
    )
    self.center = Vector:new{data[1], data[2]}
  elseif self.kind == 'rect' then
    assert(
      type(data[1]) == 'number' and
      type(data[2]) == 'number' and
      type(data[3]) == 'number' and
      type(data[4]) == 'number'
    )
    self.corner = Vector:new{data[1], data[2]}
    self.dim = Vector:new{data[3], data[4]}
  elseif self.kind == 'circ' then
    assert(
      type(data[1]) == 'number' and
      type(data[2]) == 'number' and
      type(data[3]) == 'number'
    )
    self.center = Vector:new{data[1], data[2]}
    self.radius = data[3]
  else
    error('Collider:new() unrecognized Collider type "' .. self.kind .. '"', 2)
  end
  return self
end

function Collider:overlaps(other, callback)
  local hit = Collider.overlapFunctions[self.kind][other.kind](self, other)
  local selfHit, otherHit
  if callback then
    selfHit, otherHit = callback(hit)
  end
  -- this way you can set and clear using bool, and nil causes no change
  -- of course, you can actually use any value here
  if selfHit ~= nil then
    self.hit = selfHit
  end
  if otherHit ~= nil then
    other.hit = otherHit
  end
  return hit
end

Collider.collide = Collider.overlaps

function Collider:draw(offsetX, offsetY, scale)
  offsetX = offsetX or 0
  offsetY = offsetY or 0
  scale = scale or 1
  return Collider.drawFunctions[self.kind](self, offsetX, offsetY, scale)
end

Collider.drawFunctions.point = function(self, offsetX, offsetY, scale)
  local len = 5 * scale
  love.graphics.line(self.center.x - len, self.center.y, self.center.x + len, self.center.y)
  love.graphics.line(self.center.x, self.center.y - len, self.center.x, self.center.y + len)
end

Collider.drawFunctions.rect = function(self, offsetX, offsetY, scale)
  love.graphics.rectangle('line',
    self.corner.x * scale + offsetX,
    self.corner.y * scale + offsetY,
    self.dim.x * scale,
    self.dim.y * scale
  )
end

Collider.drawFunctions.circ = function(self, offsetX, offsetY, scale)
  love.graphics.circle('line',
    self.center.x * scale + offsetX,
    self.center.y * scale + offsetY,
    self.radius * scale
  )
end

return Collider
