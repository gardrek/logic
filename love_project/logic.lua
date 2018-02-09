--[[
component
  input_nodes:
    1. -> output_node
    2. -> output_node
    etc.
  output_nodes:
    1. output node
    2. output node
    etc.

output_node
  v: value in range [-1, +1]
  connections:
    1. -> input_node
    2. -> input_node
    etc.

input_node
  output: -> output_node
]]

-- This library stops you from (accidentally) creating globals
require('noglobals')

rawset(_G, '_ALLOWGLOBALS', false)

local logic = {}
logic.__index = logic
logic.class = 'component'

local colors = require('colors')

local value = require('value')

function value:Coords()
  if not self.parent then error('Value has no parent.') end
  --return self.parent.x + self.parent.w, self.parent.y + self.index - 0.5
  return self.parent:outputCoords(self.index)
end

logic.components = {
  Joypad = {
    displayName = 'Joypad',
    w = 2, h = 6,
    color = colors.BasicSensor,
    inputs = 0, outputs = 6,
    outputNames = {'x', 'y', 'a', 'b', 'c', 'start'},
    update = function(self)
      local keyNames = {false, false, 'z', 'x', 'c', 'return'}
      for index, name in ipairs(keyNames) do
        if name then
          if love.keyboard.isDown(name) then
            self.output[index]:setvoltage(1.0)
          else
            self.output[index]:setvoltage(0.0)
          end
        end
      end
      local v = 0
      if love.keyboard.isDown('left') then v = v - 1.0 end
      if love.keyboard.isDown('right') then v = v + 1.0 end
      self.output[1]:setvoltage(v)
      v = 0
      if love.keyboard.isDown('up') then v = v - 1.0 end
      if love.keyboard.isDown('down') then v = v + 1.0 end
      self.output[2]:setvoltage(v)
    end,
  },
  Mouse = {
    displayName = 'Mouse',
    w =2, h = 5,
    color = colors.BasicSensor,
    inputs = 0,
    outputs = 5,
    outputNames = {'x', 'y', 'left', 'right', 'middle'},
    init = function(self)
      local c
      for i = 1, 5 do
        c = {0x55, 0x55, 0x55}
        c[love.math.random(1,3)] = love.math.random(0,3) * 0x11 + 0x88
        c[love.math.random(1,3)] = love.math.random(0,3) * 0x11 + 0x88
        self.output[i]:setColor(c)
      end
    end,
    update = function(self)
      local x, y = love.mouse.getPosition()
      local w, h = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
      --if love.mouse.isDown(1) then
        self.output[1]:setvoltage(value.clamp((x - w) / w))
        self.output[2]:setvoltage(value.clamp((y - h) / h))
      --end
      self.output[3]:setvoltage(love.mouse.isDown(1) and 1 or 0)
      self.output[4]:setvoltage(love.mouse.isDown(2) and 1 or 0)
      self.output[5]:setvoltage(love.mouse.isDown(3) and 1 or 0)
    end,
  },


  Truth = {
    displayName = 'True',
    w = 1, h = 1,
    color = colors.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = value:new{color = self.color}
    end,
    update = function(self)
      local passthru = self.default
      if self.input[1].link then
        passthru = self.input[1].link.val
      end
      self.output[1]:set(passthru)
      local voltage = self.output[1]:getvoltage()
      if voltage == 1.0 or voltage == -1.0 then
        self.output[1]:setvoltage(1.0)
      else
        self.output[1]:setvoltage(0.0)
      end
    end,
  },

  AND = {
    displayName = 'AND',
    w = 2, h = 2,
    color = colors.BasicGate,
    inputs = 2,
    outputs = 1,
    init = function(self)
      self.default = value:new{color = self.color}
    end,
    update = function(self)
      local passthru = self.default
      local val
      local node
      local maxval = 1.0
      for _, input in ipairs(self.input) do
        if input.link then
          val = math.abs(input.link.val:getvoltage())
          node = input.link.val
        else
          val = math.abs(self.default:getvoltage())
          node = self.default
        end
        if val <= maxval then
          passthru = node
          maxval = val
        end
      end
      self.output[1]:set(passthru)
    end,
  },
  OR = {
    displayName = 'OR',
    w = 2, h = 2,
    color = colors.BasicGate,
    inputs = 2,
    outputs = 1,
    init = function(self)
      self.default = value:new{color = self.color}
    end,
    update = function(self)
      local passthru = self.default
      local val
      local node
      local maxval = 0.0
      for _, input in ipairs(self.input) do
        if input.link then
          val = math.abs(input.link.val:getvoltage())
          node = input.link.val
        else
          val = math.abs(self.default:getvoltage())
          node = self.default
        end
        if val >= maxval then
          passthru = node
          maxval = val
        end
      end
      self.output[1]:set(passthru)
    end,
  },
  NOT = {
    displayName = 'NOT',
    w = 1, h = 1,
    color = colors.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = value:new{color = self.color}
    end,
    update = function(self)
      local passthru = self.default
      if self.input[1].link then
        passthru = self.input[1].link.val
      end
      self.color = passthru.color
      self.output[1]:set(passthru)
      local voltage = self.output[1]:getvoltage()
      self.output[1]:setvoltage((voltage < 0.0 and -1.0 or 1.0) - voltage)
    end,
    draw = function(self, offx, offy, scale)
      local drawx, drawy = self.x * scale + offx, self.y * scale + offy
      local color = self.color or colors.Fallback
      local darkColor = {color[1] / 3, color[2] / 3, color[3] / 3}
      local padding = scale / 32
      local shape = {
        drawx + 2 * padding, drawy + 2 * padding,
        drawx + self.w * scale - 6 * padding, drawy + self.h * scale / 2,
        drawx + 2 * padding, drawy + self.h * scale - 2 * padding,
      }

      love.graphics.setColor(darkColor)
      love.graphics.setLineWidth(padding * 2)
      love.graphics.setLineJoin('miter')
      love.graphics.polygon('fill', shape)

      love.graphics.setColor(color)
      love.graphics.polygon('line', shape)

      love.graphics.setColor(darkColor)
      love.graphics.circle('fill', drawx + self.w * scale - 6 * padding, drawy + self.h * scale / 2, padding * 5)

      love.graphics.setColor(self.color)
      love.graphics.circle('line', drawx + self.w * scale - 6 * padding, drawy + self.h * scale / 2, padding * 5)
    end
  },

  ABS = {
    displayName = 'Abs',
    w = 1, h = 1,
    color = colors.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = value:new{color = self.color}
    end,
    update = function(self)
      local passthru = self.default
      if self.input[1].link then
        passthru = self.input[1].link.val
      end
      self.output[1]:set(passthru)
      local voltage = self.output[1]:getvoltage()
      self.output[1]:setvoltage(math.abs(voltage))
    end,
  },
  Sign = {
    displayName = 'Sign',
    w = 1, h = 1,
    color = colors.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = value:new{color = self.color}
    end,
    update = function(self)
      local node = self.default
      if self.input[1].link then
        node = self.input[1].link.val
      end
      self.color = node.color
      self.output[1]:set(node)
      local voltage = self.output[1]:getvoltage()
      if voltage > 0.0 then
        self.output[1]:setvoltage(1.0)
      elseif voltage < 0.0 then
        self.output[1]:setvoltage(-1.0)
      else
        self.output[1]:setvoltage(0.0)
      end
    end,
    draw = function(self, offx, offy, scale)
      local drawx, drawy = self.x * scale + offx, self.y * scale + offy
      local color = self.color or colors.Fallback
      local darkColor = {color[1] / 3, color[2] / 3, color[3] / 3}
      local mediumColor = {color[1] / 3 * 2, color[2] / 3 * 2, color[3] / 3 * 2}
      local padding = scale / 32

      love.graphics.setColor(darkColor)
      love.graphics.setLineWidth(padding)
      love.graphics.rectangle(
        'fill', drawx + 2 * padding, drawy + 2 * padding,
        self.w * scale - 4 * padding, self.h * scale - 4 * padding
      )

      love.graphics.setColor(mediumColor)
      love.graphics.rectangle(
        'line', drawx + 2 * padding, drawy + 2 * padding,
        self.w * scale - 4 * padding, self.h * scale - 4 * padding
      )

      local node
      if self.input[1].link then
        node = self.input[1].link.val
      else
        node = self.default
      end
      local voltage = node:getvoltage()
      local x, y = drawx + self.w * scale / 2, drawy + self.h * scale / 2
      local shapeWidth = scale / 2 * self.w / 2
      love.graphics.setLineWidth(scale / 16)
      love.graphics.setColor(self.color)
      if voltage == 0.0 then
        love.graphics.circle('line', x, y, shapeWidth)
      else
        if voltage > 0.0 then
          love.graphics.rectangle('fill',
            x - shapeWidth / 5,
            y - shapeWidth,
            shapeWidth / 5 * 2,
            shapeWidth * 2
          )
        end
        love.graphics.rectangle('fill',
          x - shapeWidth,
          y - shapeWidth / 5,
          shapeWidth * 2,
          shapeWidth / 5 * 2
        )
      end
    end
  },

  PassThru = {
    displayName = 'PassThru',
    w = 1, h = 1,
    color = colors.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = value:new{color = self.color}
      self.visual = value:new()
    end,
    update = function(self)
      local node
      if self.input[1].link then
        node = self.input[1].link.val
      else
        node = self.default
      end
      self.color = node.color or colors.BasicGate
      self.output[1]:set(node)
    end,
    --drawOutputNodes = function() end,
    --drawInputNodes = function() end,
    draw = function(self, offx, offy, scale)
      self.visual:set(self.output[1])
      self.visual:setvoltage(1.0)
      self.visual:drawIONode('arrow',
        offx + (self.x + self.w / 2) * scale,
        offy + (self.y + self.h / 2) * scale,
        scale * self.w * 2.25
      )
    end,
  },

  AVG = {
    displayName = 'Average',
    w = 2, h = 2,
    color = colors.BasicGate,
    inputs = 2,
    outputs = 1,
    init = function(self)
      self.default = value:new{color = self.color}
    end,
    update = function(self)
      local passthru = self.default
      local val = 0
      local count = 0
      for _, input in ipairs(self.input) do
        if input.link then
          val = val + input.link.val:getvoltage()
        end
        count = count + 1
      end
      if count == 0 then
        self.output[1]:set(self.default)
      else
        self.output[1]:setvoltage(val / count)
      end
    end,
  },
  Negate = {
    displayName = 'Neg',
    w = 1, h = 1,
    color = colors.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = value:new{color = self.color}
    end,
    update = function(self)
      local passthru = self.default
      if self.input[1].link then
        passthru = self.input[1].link.val
      end
      self.output[1]:set(passthru)
      self.output[1]:setvoltage(-self.output[1]:getvoltage())
    end,
  },
  SignSplit = {
    displayName = 'SignSplit',
    w = 2, h = 2,
    color = colors.BasicGate,
    inputs = 1,
    outputs = 2,
    init = function(self)
      self.default = value:new{color = self.color}
    end,
    update = function(self)
      local passthru = self.default
      if self.input[1].link then
        passthru = self.input[1].link.val
      end
      self.output[1]:set(passthru)
      self.output[2]:set(passthru)
      local voltage = passthru:getvoltage()
      if voltage >= 0 then
        self.output[1]:setvoltage(voltage)
        self.output[2]:setvoltage(0)
      else
        self.output[1]:setvoltage(0)
        self.output[2]:setvoltage(voltage)
      end
    end,
  },

  LED = {
    displayName = 'LED',
    w = 1, h = 1,
    color = colors.FullWhite,
    inputs = 1,
    update = function(self)
      local node
      -- might not need to check number of inputs?
      -- might want to instead enforce number elsewhere
      if self.input[1] and self.input[1].link then
        node = self.input[1].link.comp.output[self.input[1].link.index]
      else
        node = self.input[1].default
      end
      self.color = --[[self.colorOverride or ]]node.color
    end,
    draw = function(self, offx, offy, scale)
      local radius = self.w * scale / 2
      local drawx, drawy = self.x * scale + offx + radius, self.y * scale + offy + radius
      local brightness = 0
      local node
      if self.input[1] and self.input[1].link then
        node = self.input[1].link.val
      else
        node = self.input[1].default
      end

      brightness = math.abs(node:getvoltage())
      love.graphics.setColor({
        node.color[1] * brightness,
        node.color[2] * brightness,
        node.color[3] * brightness,
      })
      love.graphics.circle(
        'fill', drawx, drawy, radius
      )

      love.graphics.setColor(node.color)
      love.graphics.setLineWidth(scale / 32)
      love.graphics.circle(
        'line', drawx, drawy, radius
      )

      if SHOW_DEBUG_TEXT then
        love.graphics.setColor(node.color)
        love.graphics.print(tostring(node), drawx, drawy + radius)
      end
    end,
  },

  ProgBar = {
    displayName = 'ProgBar',
    w = 2, h = 1,
    color = colors.FullWhite,
    inputs = 1,
    update = function(self)
      local node
      if self.input[1] and self.input[1].link then
        node = self.input[1].link.val
      else
        node = self.input[1].default
      end
      self.color = node.color
    end,
    draw = function(self, offx, offy, scale)
      local drawx, drawy = self.x * scale + offx, self.y * scale + offy
      local node
      if self.input[1] and self.input[1].link then
        node = self.input[1].link.comp.output[self.input[1].link.index]
      else
        node = self.input[1].default
      end
      local length = node:getvoltage()
      local padding = scale / 32
      love.graphics.setColor(colors.Black)
      love.graphics.rectangle(
        'fill', drawx + 2 * padding, drawy + 2 * padding,
        self.w * scale - 4 * padding, self.h * scale - 4 * padding
      )
      love.graphics.setColor(node.color)
      love.graphics.setLineWidth(padding)
      love.graphics.rectangle(
        'line', drawx + 2 * padding, drawy + 2 * padding,
        self.w * scale - 4 * padding, self.h * scale - 4 * padding
      )
      love.graphics.rectangle(
        'fill',
        drawx + 5 * padding,
        drawy + 5 * padding,
        (self.w * scale - 10 * padding) * math.abs(length),
        self.h * scale - 10 * padding
      )
    end,
  },
}

function logic:instance(name, x, y)
  local base = logic.components[name]
  if not base then error('Component ' .. tostring(name) .. ' does not exist.', 2) end
  local comp = {
    base = name,
    name = base.displayName or name,
    x = x, y = y,
    w = base.w or 21, h = base.h or 21,
    color = base.color or colors.Fallback,
    input = {},
    output = {},
    init = base.init,
    update = base.update or self.update,
    draw = base.draw or self.draw,
    drawInputNodes = base.drawInputNodes or self.drawInputNodes,
    drawOutputNodes = base.drawOutputNodes or self.drawOutputNodes,
  }

  local inputNames, outputNames = base.inputNames or {}, base.outputNames or {}

  if type(base.inputs) == 'number' then
    for i = 1, base.inputs do
      comp.input[i] = {
        name = inputNames[i] or '',
        default = value:new{color = comp.color},
        --index = i,
        --parent = comp,
        --link = nil,
      }
    end
  --elseif base.inputs == 'var' then
    -- there must be a better way to do variable number of inputs
  end

  if type(base.outputs) == 'number' then
    for i = 1, base.outputs do
      comp.output[i] = value:new{
        name = outputNames[i] or '',
        color = comp.color,
        parent = comp,
        index = i,
        links = {},
      }
    end
  end

  if comp.init then comp:init() end

  setmetatable(comp, self)
  return comp
end

function logic:link(o, other, i)
  if other.input[i].link then
    other:unlinkInput(i)
  end
  -- Using the other component as a key into the table, with a value of a set
  -- of all linked indexes
  -- this is just crazy enough to work
  self.output[o].links[other] = self.output[o].links[other] or {}
  self.output[o].links[other][i] = true

  other.input[i].link = {comp = self, index = o, val = self.output[o]}
end

function logic:unlinkInput(i)
  local link = self.input[i].link
  if link then
    link.comp:unlinkOutput(link.index, self, i)
  end
  self.input[i].link = nil
end

function logic:unlinkAllInputs()
  for i, inp in pairs(self.input) do
    self:unlinkInput(i)
  end
end

function logic:unlinkOutput(o, comp, i)
  local links = self.output[o].links
  if links[comp] then
    comp.input[i].link = nil
    links[comp][i] = nil
    local count = 0
    for _ in pairs(links[comp]) do
      count = count + 1
    end
    if count == 0 then links[comp] = nil end
  end
end

function logic:unlinkAllOutputs()
  for o, val in pairs(self.output) do
    for comp, links in pairs(val.links) do
      for comp_index, exists in pairs(links) do
        print(o, comp, comp_index, exists, val)
        self:unlinkOutput(o, comp, comp_index)
      end
    end
  end
end

function logic:unlinkAll()
  self:unlinkAllInputs()
  self:unlinkAllOutputs()
end

function logic:draw(offx, offy, scale)
  local drawx, drawy = self.x * scale + offx, self.y * scale + offy
  local color = self.color or colors.Fallback
  local darkColor = {color[1] / 3, color[2] / 3, color[3] / 3}
  local mediumColor = {color[1] / 3 * 2, color[2] / 3 * 2, color[3] / 3 * 2}
  local padding = scale / 32

  love.graphics.setColor(darkColor)
  love.graphics.setLineWidth(padding)
  love.graphics.rectangle(
    'fill', drawx + 2 * padding, drawy + 2 * padding,
    self.w * scale - 4 * padding, self.h * scale - 4 * padding
  )

  love.graphics.setColor(mediumColor)
  love.graphics.rectangle(
    'line', drawx + 2 * padding, drawy + 2 * padding,
    self.w * scale - 4 * padding, self.h * scale - 4 * padding
  )

  love.graphics.setColor(color)
  love.graphics.print(self.name, drawx + 3 * padding, drawy + 3 * padding)
end

function logic:drawInputNodes(offx, offy, scale, color)
  color = self.color or colors.Fallback
  local x, y, node
  for index, val in ipairs(self.input) do
    x, y = self:inputCoords(index)
    x, y = x * scale + offx, y * scale + offy
    if val.link then
      node = val.link.comp.output[val.link.index]
    else
      node = val.default
    end
    love.graphics.setColor(node.color or color)
    if SHOW_DEBUG_TEXT then
      love.graphics.print(tostring(node), x + 6, y + 6)
    end
    --node:drawIONode('i', x, y, scale)
    if not val.link then
      node:drawIONode('i', x, y, scale)
    end
  end
end

function logic:drawOutputNodes(offx, offy, scale, color)
  color = self.color or colors.Fallback
  local x, y, node
  for index, val in ipairs(self.output) do
    love.graphics.setColor(val.color or color)
    --x, y = (self.x + self.w) * scale + offx, (self.y + index - 0.5) * scale + offy
    x, y = self:outputCoords(index)
    x, y = x * scale + offx, y * scale + offy
    if SHOW_DEBUG_TEXT then
      love.graphics.print(tostring(val.name), x - (self.w / 2) * scale, y - 12)
      love.graphics.print(tostring(val), x - (self.w / 2) * scale, y + 6)
    end
    val:drawIONode('o', x, y, scale)
    if SHOW_DEBUG_TEXT then
      if val.links then
        love.graphics.setColor(val.color or color)
        if #val.links == 0 then
          --love.graphics.print('nolink', x + 6, y - 12)
        end
        local offset = 0
        for comp, link in pairs(val.links) do
          love.graphics.print(comp.name, x + 8, y + 10 * (offset - 1))
          for index, hasLink in pairs(link) do
            love.graphics.print(index, x + 48, y + 10 * (offset - 1))
            offset = offset + 1
          end
        end
      end
    end
  end
end

function logic:drawHangingWire(offx, offy, scale, val, x1, y1, x2, y2)
  local points
  local curvesize = 0.25 * scale
  if x2 - curvesize < x1 then
    if y2 < y1 then
      points = {
        x1, y1,
        x1 + curvesize, y1,
        x1 + curvesize, y1 - curvesize,
        x2 - curvesize, y2 + curvesize,
        x2 - curvesize, y2,
        x2, y2,
      }
    else
      points = {
        x1, y1,
        x1 + curvesize, y1,
        x1 + curvesize, y1 + curvesize,
        x2 - curvesize, y2 - curvesize,
        x2 - curvesize, y2,
        x2, y2,
      }
    end
  elseif x2 - curvesize > x1 + curvesize or (y2 < y1 - curvesize or y2 > y1 + curvesize) then
    points = {
      x1, y1,
      x1 + curvesize, y1,
      x2 - curvesize, y2,
      x2, y2,
    }
  else
    points = {
      x1, y1,
      x2, y2,
    }
  end
  logic.drawWire(offx, offy, scale, val, points)
end

function logic:drawWires(offx, offy, scale)
  local x1, y1, x2, y2, node
  local w = scale / 8
  local w2 = w / 2
  for indexO, val in ipairs(self.output) do
    local v = val:getvoltage()
    local mag = math.abs(v)
    local vColor = {val.color[1] * mag, val.color[2] * mag, val.color[3] * mag}
    local halfColor = {val.color[1] / 2, val.color[2] / 2, val.color[3] / 2}
    x1, y1 = self:outputCoords(indexO)
    x1, y1 = x1 * scale + offx, y1 * scale + offy
    if val.links then
      for comp, link in pairs(val.links) do
        for indexI, hasLink in pairs(link) do
          x2, y2 = comp:inputCoords(indexI)
          x2, y2 = x2 * scale + offx, y2 * scale + offy
          logic:drawHangingWire(offx, offy, scale, val, x1, y1, x2, y2)
          val:drawIONode('o', x1, y1, scale)
          val:drawIONode('i', x2, y2, scale)
        end
      end
    end
  end
end

function logic:inputCoords(i)
  return self.x, self.y + (i - 0.5) * self.h / #self.input
end

function logic:outputCoords(o)
  return self.x + self.w, self.y + (o - 0.5) * self.h / #self.output
end

function logic.drawWire(offx, offy, scale, val, points)
  local v = val:getvoltage()
  local mag = math.abs(v)
  local vColor = {val.color[1] * mag, val.color[2] * mag, val.color[3] * mag}
  local halfColor = {val.color[1] / 2, val.color[2] / 2, val.color[3] / 2}
  --local halfColor = {val.color[1], val.color[2], val.color[3], 0.75 * 255}
  love.graphics.setLineJoin('bevel')
  love.graphics.setColor(halfColor)
  love.graphics.setLineWidth(scale / 4)
  love.graphics.line(points)
  love.graphics.setColor(vColor)
  love.graphics.setLineWidth(scale / 8)
  love.graphics.line(points)
end

rawset(_G, '_ALLOWGLOBALS', true)

return logic
