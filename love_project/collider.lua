vector = require('vector')

local collider = {}
collider.__index = collider

collider.kinds = {
  'point',
  'rect',
  'circ',
}

collider.overlapFunctions = {}

collider.drawFunctions = {}

for _, kind in ipairs(collider.kinds) do
  collider[kind] = function(self, data)
    return self:new(kind, data)
  end
  collider.overlapFunctions[kind] = {}
end

collider.overlapFunctions.point.point = function(self, other)
  return other.center.x == self.center.x and other.center.y == self.center.y
end

collider.overlapFunctions.point.rect = function(self, other)
  return
    self.center.x >= other.corner.x and
    self.center.y >= other.corner.y and
    self.center.x < other.corner.x + other.dim.x and
    self.center.y < other.corner.y + other.dim.y
end

collider.overlapFunctions.point.circ = function(self, other)
  local distX, distY = other.center.x - self.center.x, other.center.y - self.center.y
  return distX * distX + distY * distY < other.radius * other.radius
end

collider.overlapFunctions.rect.rect = function(self, other)
  return
    self.corner.x + self.dim.x >= other.corner.x and
    self.center.y + self.dim.y >= other.corner.y and
    self.center.x < other.corner.x + other.dim.x and
    self.center.y < other.corner.y + other.dim.y
end

collider.overlapFunctions.rect.circ = function(self, other)
  --error('circ-rect collision not yet implemented', 2)
  --local distX, distY = other.point.x - self.point.x, other.point.y - self.point.y
  --return math.sqrt(distX * distX + distY * distY) < other.radius
end

collider.overlapFunctions.circ.circ = function(self, other)
  local distX, distY = other.center.x - self.center.x, other.center.y - self.center.y
  return distX * distX + distY * distY < other.radius * other.radius + self.radius * self.radius
end

collider.overlapFunctions.rect.point = function(self, other)
  return collider.overlapFunctions.point.rect(other, self)
end

collider.overlapFunctions.circ.point = function(self, other)
  return collider.overlapFunctions.point.circ(other, self)
end

collider.overlapFunctions.circ.rect = function(self, other)
  return collider.overlapFunctions.rect.circ(other, self)
end

function collider:new(kind, data)
  return setmetatable({kind = tostring(kind)}, collider):set(data)
end

function collider:set(data)
  if self.kind == 'point' then
    assert(
      type(data[1]) == 'number' and
      type(data[2]) == 'number'
    )
    self.center = vector:new{data[1], data[2]}
  elseif self.kind == 'rect' then
    assert(
      type(data[1]) == 'number' and
      type(data[2]) == 'number' and
      type(data[3]) == 'number' and
      type(data[4]) == 'number'
    )
    self.corner = vector:new{data[1], data[2]}
    self.dim = vector:new{data[3], data[4]}
  elseif self.kind == 'circ' then
    assert(
      type(data[1]) == 'number' and
      type(data[2]) == 'number' and
      type(data[3]) == 'number'
    )
    self.center = vector:new{data[1], data[2]}
    self.radius = data[3]
  else
    error('collider:new() unrecognized collider type "' .. self.kind .. '"', 2)
  end
  return self
end

function collider:overlaps(other, callback)
  local hit = collider.overlapFunctions[self.kind][other.kind](self, other)
  local selfHit, otherHit = callback(hit)
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

collider.collide = collider.overlaps

function collider:draw(offsetX, offsetY, scale)
  offsetX = offsetX or 0
  offsetY = offsetY or 0
  scale = scale or 1
  return collider.drawFunctions[self.kind](self, offsetX, offsetY, scale)
end

collider.drawFunctions.point = function(self, offsetX, offsetY, scale)
  local len = 5 * scale
  love.graphics.line(self.center.x - len, self.center.y, self.center.x + len, self.center.y)
  love.graphics.line(self.center.x, self.center.y - len, self.center.x, self.center.y + len)
end

collider.drawFunctions.rect = function(self, offsetX, offsetY, scale)
  love.graphics.rectangle('line',
    self.corner.x * scale + offsetX,
    self.corner.y * scale + offsetY,
    self.dim.x * scale,
    self.dim.y * scale
  )
end

collider.drawFunctions.circ = function(self, offsetX, offsetY, scale)
  love.graphics.circle('line',
    self.center.x * scale + offsetX,
    self.center.y * scale + offsetY,
    self.radius * scale
  )
end

return collider
