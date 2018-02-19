-- This library stops you from (accidentally) creating globals
require('noglobals')

rawset(_G, '_ALLOWGLOBALS', false)

local Value = {}
Value.__index = Value
Value.class = 'Value'
--setmetatable(Value, Value)

local Color = require('Color')
local Vector = require('Vector')

function Value:new(val)
  if type(val) == 'number' then
    val = {voltage = val}
  elseif not val then
    val = {}
  end
  val.voltage = Value.clamp(val) or 0.0
  val.color = Vector:new(val.color or Color.FullWhite)
  setmetatable(val, self)
  return val
end

function Value:setvoltage(v)
  -- DEBUG
  if v > 1.0 or v < -1.0 then
    error('E: attempt to set Value outside range')
    --print('W: attempt to set Value outside range ' .. tostring(v))
    --v = self.clamp(v)
  end
  self.voltage = v
end

function Value:getvoltage()
  return self.voltage
end

function Value:setColor(c)
  self.color = Vector:new(c)
end

--[[
function Value:dup(val)
  val = val or {}
  if not getmetatable(val) then
    setmetatable(val, getmetatable(self))
  end
  self.set(val, self)
  return val
end--]]

function Value:set(other)
  if not other then error('Required argument "other" to Value:set', 2) end
  if other.getvoltage then
    self.voltage = other:getvoltage()
  elseif other.voltage then
    self.voltage = other.voltage
  end
  if other.color then
    self:setColor(other.color)
  end
end

function Value:clamp()
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

function Value:__tostring()
  return ("%.f%%"):format(self.voltage * 100)
end

function Value:drawIONode(nodeType, x, y, radius)
  local scale = radius / 32
  local v = self:getvoltage()
  local mag = math.abs(v)
  local vColor = self.color * mag
  local halfColor = self.color / 2
  if nodeType == 'i' then
    love.graphics.setColor(self.color)
    love.graphics.polygon('fill',
      x + 1.5 * scale, y - 5 * scale,
      x + 1.5 * scale, y + 5 * scale,
      x - 3.5 * scale, y + 5 * scale,
      x - 0.5 * scale, y + 1.5 * scale,
      -- FIXME: ??? profit? literally no idea why ^^this y co-ordinate^^ works. I must be doing something awfully wrong somehow
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
    if nodeType ~= 'arrow' then print('Value:drawIONode() falling back to node type "arrow"') end
    love.graphics.setColor(self.color)
    love.graphics.circle('fill', x, y, 7 * scale)
    love.graphics.setColor(Color.Black)
    love.graphics.circle('fill', x, y, 5 * scale)
    love.graphics.setColor(self.color)--(vColor)--
    love.graphics.polygon('fill', x - 2 * scale, y - 3 * scale, x + 4 * scale, y, x - 2 * scale, y + 3 * scale)
  end
end

function Value:link(other)
  self.parent:link(self.index, other.parent, other.index)
end

function Value:pick(mouse) return self end

function Value:place(mouse)
  if mouse.hoveredObject and mouse.hoveredObject.class == 'Input' then
    self:link(mouse.hoveredObject)
  end
  return self
end

rawset(_G, '_ALLOWGLOBALS', true)

return Value
