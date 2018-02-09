-- This library stops you from (accidentally) creating globals
require('noglobals')

rawset(_G, '_ALLOWGLOBALS', false)

local value = {}
value.__index = value
value.class = 'value'
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
  if v > 1.0 or v < -1.0 then
    error('E: attempt to set value outside range')
    --print('W: attempt to set value outside range ' .. tostring(v))
    --v = self.clamp(v)
  end
  self.voltage = v
end

function value:getvoltage()
  return self.voltage
end

function value:setColor(c)
  self.color = {c[1], c[2], c[3]}
end

--[[
function value:dup(val)
  val = val or {}
  if not getmetatable(val) then
    setmetatable(val, getmetatable(self))
  end
  self.set(val, self)
  return val
end--]]

function value:set(other)
  if not other then error('Required argument "other" to value:set', 2) end
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

function value:drawIONode(nodeType, x, y, radius)
  local scale = radius / 32
  local v = self:getvoltage()
  local mag = math.abs(v)
  local vColor = {self.color[1] * mag, self.color[2] * mag, self.color[3] * mag}
  local halfColor = {self.color[1] / 2, self.color[2] / 2, self.color[3] / 2}
  if nodeType == 'i' then
    love.graphics.setColor(self.color)
    love.graphics.polygon('fill',
      x + 1.5 * scale, y - 5 * scale,
      x + 1.5 * scale, y + 5 * scale,
      x - 3.5 * scale, y + 5 * scale,
      x - 0.5 * scale, y + 1.5 * scale,
      -- FIXME: ??? profit? literally no idea why ^^this y co-ordinate^^ works. tempted to say it's a float rounding artifact
      x - 3.5 * scale, y - 5 * scale
    )
  elseif nodeType == 'o' then
    love.graphics.setColor(self.color)
    love.graphics.polygon('fill',
      x + 4 * scale, y - 5.5 * scale,
      x + 4 * scale, y + 5.5 * scale,
      x - 1.5 * scale, y + 3.5 * scale,
      x - 1.5 * scale, y - 3.5 * scale
    )
    --[[
    love.graphics.setColor(vColor)
    love.graphics.polygon('fill',
      x + 4 * scale, y - 2 * scale,
      x + 4 * scale, y + 2 * scale,
      x + 0.5 * scale, y + 2 * scale,
      x + 0.5 * scale, y - 2 * scale
    )
    --]]
  else
    if nodeType ~= 'arrow' then print('value:drawIONode() falling back to node type "arrow"') end
    love.graphics.setColor(self.color)
    love.graphics.circle('fill', x, y, 7 * scale)
    love.graphics.setColor(colors.Black)
    love.graphics.circle('fill', x, y, 5 * scale)
    love.graphics.setColor(self.color)--(vColor)
    love.graphics.polygon('fill', x - 2 * scale, y - 3 * scale, x + 4 * scale, y, x - 2 * scale, y + 3 * scale)
  end
end

rawset(_G, '_ALLOWGLOBALS', true)

return value
