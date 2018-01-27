--[[
component
  :input_nodes
    1. -> output_node
    2. -> output_node
    etc.
  :output_nodes
    1. output node
    2. output node

output_node
  v: value in range [-1, +1]
  connections:
    1. -> input_node
    2. -> input_node

input_node
  output: -> output_node
]]

local logic = {}
logic.__index = logic

local colors = require('colors')

local value = require('value')

logic.components = {
  Mouse = {
    displayName = 'Raw Mouse',
    w = 1, h = 2,
    inputs = 0,
    outputs = {'x', 'y'},
    update = function(self)
      local x, y = love.mouse.getPosition()
      local w, h = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
      self.output[1]:setvoltage((x - w) / w)
      self.output[2]:setvoltage((y - h) / h)
    end,
  },
  AND = {
    displayName = 'AND',
    w = 2, h = 2,
    inputs = 'var',
    outputs = {''},
    update = function(self)
      local x, y = love.mouse.getPosition()
      local w, h = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
      self.output[1]:setvoltage((x - w) / w)
      self.output[2]:setvoltage((y - h) / h)
    end,
  },
}

function logic:instance(name, x, y)
  local base = logic.components[name]
  if not base then error('Component ' .. tostring(name) .. ' does not exist.', 2) end
  local comp = {
    name = base.displayName or name,
    x = x, y = y,
    w = base.w or 21, h = base.h or 21,
    input = {},
    output = {},
    update = base.update,
  }

  if type(base.inputs) == 'number' then
    for i = 1, base.inputs do
      comp.input[i] = {
        name = '',
      }
    end
  elseif type(base.inputs) == 'table' then
    for i, name in ipairs(base.inputs) do
      comp.input[i] = {
        name = name,
      }
    end
  elseif base.inputs == 'var' then
    --
  end

  if type(base.outputs) == 'number' then
    for i = 1, base.outputs do
      comp.output[i] = {
        name = '',
      }
    end
  elseif type(base.outputs) == 'table' then
    for i, name in ipairs(base.outputs) do
      comp.output[i] = value:new{
        name = name,
      }
    end
  end

  setmetatable(comp, self)
  return comp
end

function logic:draw(offx, offy, scale)
  local drawx, drawy = self.x * scale + offx, self.y * scale + offy
  local color = self.color or colors.Fallback
  love.graphics.setColor(color)
  love.graphics.rectangle(
    'line', drawx + 2, drawy + 2,
    self.w * scale - 4, self.h * scale - 4
  )
  love.graphics.print(self.name, drawx + 2, drawy + 2)
  local x, y
  for index, val in ipairs(self.output) do
    love.graphics.setColor(val.color or color)
    x, y = (self.x + self.w) * scale + offx, (self.y + index - 0.5) * scale + offy
    love.graphics.print(tostring(val), x - 40, y + 6)
    val:drawNode(x, y)
  end
end

return logic

--[=====[
logic.comp = {}
logic.comp.__index = logic.comp

function logic.comp:new(c)
  c = c or {}
  c.instance = self.instance or c.instance
  setmetatable(c, self)
  return c
end

function logic.comp:initOutput(index, v, color)
  self.output[index] = logic.value:new{
    component = self,
    index = index,
    v = v,
    color = color or self.color,
    connections = {},
  }
end

function logic.comp:instance(t)
  local c = {}
  c.w, c.h = self.w or 2, self.h or 2
  c.input = {} -- array of references to the outputs of other components
  c.output = {} -- array of values
  --c.base = self
  local v
  for _, copy in ipairs({
      'init', 'connect', 'update', 'draw', 'drawWires', 'initOutput', 'disconnectAll',
      'name',
    }) do
      v = self[copy]
      if v then
        c[copy] = v
      end
  end
  if self.color then
    c.color = {self.color[1], self.color[2], self.color[3]}
  end
  if t then
    for key, value in pairs(t) do
      c[key] = value
    end
  end
  if c.init then
    c:init()
  end
  return c
end

function logic.comp:connect(input, other, output)
  if self.input[input] then
    print('found you')
  end
  self.input[input] = other.output[output]
  table.insert(other.output[output].connections, {self, input})
end

function logic.comp:disconnectAll()
  for index in pairs(self.input) do
    self.input[index] = nil
  end
  for index, val in ipairs(self.output) do
    for _, vvvvv in ipairs(val.connections) do
      print(vvvvv[1].name, vvvvv[2])
      vvvvv[1].input[vvvvv[2]] = nil
    end
  end
end

function logic.comp:draw(offx, offy, scale)
  local drawx, drawy = self.x * scale + offx, self.y * scale + offy
  love.graphics.setColor(self.color or colors.Fallback)
  love.graphics.rectangle(
    'line', drawx + 2, drawy + 2,
    self.w * scale - 4, self.h * scale - 4
  )
  love.graphics.print(self.name, drawx + 2, drawy + 2)
end

function logic.comp:drawWires(offx, offy, scale)
  local comp, x1, y1, x2, y2
  local mag
  for index, val in ipairs(self.input) do
    comp = val.component
    love.graphics.setColor(val.color)
    x1, y1 = (comp.x + comp.w) * scale + offx, (comp.y + val.index - 0.5) * scale + offy
    x2, y2 = self.x * scale + offx, (self.y + index - 0.5) * scale + offy
    love.graphics.line(x1, y1, x2, y2)
    if val.v < 0 then
      love.graphics.rectangle('fill', x2 - 6, y2 - 6, 12, 12)
    else
      love.graphics.circle('fill', x2, y2, 6)
    end
    mag = math.abs(val.v)
    love.graphics.setColor{val.color[1] * mag, val.color[2] * mag, val.color[3] * mag}
    love.graphics.circle('fill', x2, y2, 4)
  end
  for index, val in ipairs(self.output) do
    love.graphics.setColor(val.color)
    x1, y1 = (self.x + self.w) * scale + offx, (self.y + val.index - 0.5) * scale + offy
    love.graphics.print(tostring(val), x1 - 42, y1 - 6)
    if val.v < 0 then
      love.graphics.rectangle('fill', x1 - 6, y1 - 6, 12, 12)
    else
      love.graphics.circle('fill', x1, y1, 6)
    end
    mag = math.abs(val.v)
    love.graphics.setColor{val.color[1] * mag, val.color[2] * mag, val.color[3] * mag}
    love.graphics.circle('fill', x1, y1, 4)
  end
end

--[[
function logic.comp:mouseInput(mouse)
  
end
--]]

logic.comp.base = {}

-- Logic Gates -- -- -- -- -- -- -- --

-- N-ary
logic.comp.base.AND = logic.comp:new{
  name = 'AND',
  color = colors.BasicGate,
  init = function(self)
    self:initOutput(1, ERR)
    self.default = logic.value:new{
      v = ERR,
      color = self.color,
    }
  end,
  update = function(self)
    local passthru
    local v = 1.0
    for _, n in ipairs(self.input) do
      if math.abs(n.v) <= v then
        passthru = n
        v = math.abs(n.v)
      end
    end
    if passthru then
      passthru:dup(self.output[1])
    else
      self.default:dup(self.output[1])
    end
  end,
}

logic.comp.base.OR = logic.comp:new{
  name = 'OR',
  color = colors.BasicGate,
  init = function(self)
    self:initOutput(1, ERR)
    self.default = logic.value:new{
      v = ERR,
      color = self.color,
    }
  end,
  update = function(self)
    local passthru
    local v = 0.0
    for _, n in ipairs(self.input) do
      if math.abs(n.v) >= v then
        passthru = n
        v = math.abs(n.v)
      end
    end
    if passthru then
      passthru:dup(self.output[1])
    else
      self.default:dup(self.output[1])
    end
  end,
}

logic.comp.base.XOR = logic.comp:new{
  name = 'XOR',
  color = colors.BasicGate,
  init = function(self)
    self:initOutput(1, ERR)
  end,
  update = function(self)
    local v = 0.0
    local truth
    for _, n in ipairs(self.input) do
      n = math.abs(n.v)
      if n == 1.0 then
        truth = not truth
      elseif n > v then
        v = n
      end
    end
    if truth then
      self.output[1]:setv(1.0)
    else
      self.output[1]:setv(v)
    end
  end
}

logic.comp.base.AVG = logic.comp:new{
  name = 'Average',
  color = colors.BasicGate,
  init = function(self)
    self:initOutput(1, ERR)
  end,
  update = function(self)
    self.h = #self.input
    if self.h < 2 then self.h = 2 end
    local v = 0.0
    for _, n in ipairs(self.input) do
      v = v + n.v
    end
    if #self.input == 0 then
      self.output[1]:setv(ERR)
    else
      self.output[1]:setv(v / #self.input)
    end
  end,
}

-- Unary
logic.comp.base.NOT = logic.comp:new{
  name = 'Logical NOT',
  color = colors.BasicGate,
  w = 1, h = 1,
  init = function(self)
    self:initOutput(1, ERR)
    self.default = logic.value:new{
      v = ERR,
      color = self.color,
    }
  end,
  update = function(self)
    if self.input[1] then
      self.input[1]:dup(self.output[1])
      self.output[1]:setv(1 - math.abs(self.input[1].v))
    else
      self.default:dup(self.output[1])
    end
  end,
}

logic.comp.base.Negative = logic.comp:new{
  name = 'Negative',
  color = colors.BasicGate,
  w = 1, h = 1,
  init = function(self)
    self:initOutput(1, ERR)
    self.default = logic.value:new{
      v = ERR,
      color = self.color,
    }
  end,
  update = function(self)
    if self.input[1] then
      self.input[1]:dup(self.output[1])
      self.output[1]:setv(-self.input[1].v)
    else
      self.default:dup(self.output[1])
    end
  end,
}

logic.comp.base.SGN = logic.comp:new{
  name = 'Sign',
  color = colors.BasicGate,
  w = 1, h = 1,
  init = function(self)
    self:initOutput(1, ERR)
    self.default = logic.value:new{
      v = ERR,
      color = self.color,
    }
  end,
  update = function(self)
    if self.input[1] then
      self.input[1]:dup(self.output[1])
      local value = self.input[1].v
      if value < 0.0 then
        self.output[1]:setv(-1.0)
      elseif value > 0.0 then
        self.output[1]:setv(1.0)
      else
        self.output[1]:setv(value) -- propogate -0.0 I guess?
      end
    else
      self.default:dup(self.output[1])
    end
  end,
}

logic.comp.base.ABS = logic.comp:new{
  name = 'Absolute Value',
  color = colors.BasicGate,
  w = 1, h = 1,
  init = function(self)
    self:initOutput(1, ERR)
    self.default = logic.value:new{
      v = ERR,
      color = self.color,
    }
  end,
  update = function(self)
    if self.input[1] then
      self.input[1]:dup(self.output[1])
      self.output[1]:setv(math.abs(self.input[1].v))
    else
      self.default:dup(self.output[1])
    end
  end,
}

logic.comp.base.Truth = logic.comp:new{
  name = 'Boolean Truth',
  color = colors.BasicGate,
  w = 1, h = 1,
  init = function(self)
    self:initOutput(1, ERR)
    self.default = logic.value:new{
      v = ERR,
      color = self.color,
    }
  end,
  update = function(self)
    if self.input[1] then
      self.input[1]:dup(self.output[1])
      if math.abs(self.input[1].v) == 1.0 then
        self.output[1]:setv(1.0)
      else
        self.output[1]:setv(0.0)
      end
    else
      self.default:dup(self.output[1])
    end
  end,
}

-- Turn a range of -1.0, +1.0 into a range of 0, +1.0
logic.comp.base.RangeToPositive = logic.comp:new{
  name = 'r2pos',
  color = colors.BasicGate,
  w = 1, h = 1,
  init = function(self)
    self:initOutput(1, ERR)
    self.default = logic.value:new{
      v = ERR,
      color = self.color,
    }
  end,
  update = function(self)
    if self.input[1] then
      self.input[1]:dup(self.output[1])
      self.output[1]:setv(self.input[1].v / 2 + 0.5)
    else
      self.default:dup(self.output[1])
    end
  end,
}

-- Binary

-- Subtract is superfluous because average(A, -B) is the same as (A - B) / 2
-- Here is a magnitude subtract, which acts a lot like LBP2's direction combiner
logic.comp.base.SUB = logic.comp:new{
  name = 'Subtract',
  color = colors.BasicGate,
  w = 2, h = 2,
  init = function(self)
    self:initOutput(1, ERR)
  end,
  update = function(self)
    if self.input[1] and self.input[2] then
      --self.output[1]:setv((self.input[1].v - self.input[2].v) / 2)
      self.output[1]:setv(math.abs(self.input[1].v) - math.abs(self.input[2].v))
      --self.output[1]:clamp()
    else
      self.output[1]:setv(ERR)
    end
  end,
}

-- Sensors and Other Signal Generators -- -- -- -- -- -- -- --

logic.comp.base.SWITCH = logic.comp:new{
  name = '2-way Switch',
  init = function(self)
    self:initOutput(1, 0.0)
  end,
  --TODO: figure out input
  clicked = function(self)
    self.output[1]:setv(1.0 - self.output[1].v)
  end,
}

logic.comp.base.Mouse = logic.comp:new{
  name = 'Raw Mouse',
  color = colors.BasicSensor,
  w = 2, h = 4,
  init = function(self)
    self:initOutput(1, 0.0)
    self:initOutput(2, 0.0)
    self.output[1].color = colors.Red
    self.output[2].color = colors.Blue
    self:update()
  end,
  update = function(self)
    local x, y = love.mouse.getPosition()
    local w, h = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    self.output[1]:setv((x - w) / w)
    self.output[2]:setv((y - h) / h)
  end,
}

-- Output Devices -- -- -- -- -- -- -- --

logic.comp.base.LED = logic.comp:new{
  name = 'LED',
  color = colors.FullWhite,
  w = 1, h = 1,
  draw = function(self, offx, offy, scale)
    local radius = (self.w or 2) * scale / 2
    local drawx, drawy = self.x * scale + offx + radius, self.y * scale + offy + radius
    local brightness = 0
    if self.input[1] then
      brightness = math.abs(self.input[1].v)
    end
    love.graphics.setColor({
      self.color[1] * brightness,
      self.color[2] * brightness,
      self.color[3] * brightness,
    })
    love.graphics.circle(
      'fill', drawx, drawy, radius
    )
    --DEBUG
    love.graphics.setColor(self.color)
    love.graphics.rectangle(
      'line', drawx - radius, drawy - radius, radius * 2, radius * 2
    )
    if self.input[1] then love.graphics.print(tostring(self.input[1]), drawx, drawy + radius) end
  end,
}

logic.comp.base.RGB = logic.comp:new{
  name = 'RGB LED',
  w = 1, h = 1,
  update = function(self)
    if self.input[1] then
      self.color = self.input[1].color
    end
  end
}

logic.comp.base.RGB.draw = logic.comp.base.LED.draw
]=====]
