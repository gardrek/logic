local value = {}
value.__index = value
--setmetatable(value, value)

local colors = require('colors')

function value:new(val)
  if type(val) == 'number' then
    val = {voltage = val}
  elseif not val then
    val = {}
  end
  val.voltage = value.clamp(val) or 0.0
  val.color = val.color or colors.FullWhite
  setmetatable(val, self)
  return val
end

function value:setvoltage(v)
  -- DEBUG
  if v > 1.0 or v < -1.0 then error('E: attempt to set value outside range') end
  self.voltage = v
end

function value:getvoltage()
  return self.voltage
end

function value:dup(val)
  if not val then
    val = {}
    setmetatable(val, getmetatable(self))
  end
  self.set(val, self)
  return val
end

function value:set(other)
  if other.getvoltage then
    self.voltage = other:getvoltage()
  elseif other.voltage then
    self.voltage = other.voltage
  end
  if other.color then
    self.color = {other.color[1], other.color[2], other.color[3]}
  end
end

function value:clamp()
  if type(self) == 'table' and self.voltage then
    if self.voltage < -1.0 then
      self.voltage = -1.0
    elseif self.voltage > 1.0 then
      self.voltage = 1.0
    end
    return self.v
  elseif type(self) == 'number' then
    if self < -1.0 then
      self = -1.0
    elseif self > 1.0 then
      self = 1.0
    end
    return self
  end
end

function value:__tostring()
  return ("%.f%%"):format(self.voltage * 100)
end

function value:drawNode(x, y, scale)
  scale = scale or 1
  local v = self:getvoltage()
  local mag = math.abs(v)
  local vColor = {self.color[1] * mag, self.color[2] * mag, self.color[3] * mag}
  love.graphics.setColor(self.color)
  if v < 0 then
    love.graphics.rectangle('fill', x - 6 * scale, y - 6 * scale, 6 * scale, 6 * scale)
    love.graphics.rectangle('fill', x, y, 6 * scale, 6 * scale)
    --[[
    love.graphics.rectangle('fill', x - 6 * scale, y - 6 * scale, 12 * scale, 6 * scale)
  elseif v > 0 then
    love.graphics.rectangle('fill', x - 6 * scale, y, 12 * scale, 6 * scale)
    --]]
  end
  love.graphics.circle('fill', x, y, 6 * scale)
  love.graphics.setColor(vColor)
  love.graphics.circle('fill', x, y, 4 * scale)
end

local qqq = {
  value:new(),
  value:new(0.23),
  value:new(20),
}

return value
