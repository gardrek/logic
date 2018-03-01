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
  v: Value in range [-1, +1]
  connections:
    1. -> input_node
    2. -> input_node
    etc.

input_node
  output: -> output_node
]]
--asldkfasdf
-- This library stops you from (accidentally) creating globals
require('noglobals')

rawset(_G, '_ALLOWGLOBALS', false)

local Logic = {}
Logic.__index = Logic
Logic.class = 'Component'

local Color = require('Color')

local Collider = require('Collider')

local Value = require('Value')

function Value:Coords()
  if not self.parent then error('Value has no parent.') end
  --return self.parent.x + self.parent.w, self.parent.y + self.index - 0.5
  return self.parent:outputCoords(self.index)
end

Logic.components = {
  Joypad = {
    displayName = 'Joypad',
    w = 2, h = 6,
    color = Color.BasicSensor,
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
    color = Color.BasicSensor,
    inputs = 0,
    outputs = 5,
    outputNames = {'x', 'y', 'left', 'right', 'middle'},
    --[[
    init = function(self)
      local c
      for i = 1, 5 do
        c = vector:new{0x55, 0x55, 0x55}
        c[love.math.random(1,3)] = love.math.random(0,3) * 0x11 + 0x88
        c[love.math.random(1,3)] = love.math.random(0,3) * 0x11 + 0x88
        self.output[i]:setColor(c)
      end
    end,--]]
    update = function(self)
      local x, y = love.mouse.getPosition()
      local w, h = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
      --if love.mouse.isDown(1) then
        self.output[1]:setvoltage(Value.clamp((x - w) / w))
        self.output[2]:setvoltage(Value.clamp((y - h) / h))
      --end
      self.output[3]:setvoltage(love.mouse.isDown(1) and 1 or 0)
      self.output[4]:setvoltage(love.mouse.isDown(2) and 1 or 0)
      self.output[5]:setvoltage(love.mouse.isDown(3) and 1 or 0)
    end,
  },

  Random = {
    displayName = 'Random',
    w = 2, h = 1,
    color = Color.BasicSensor,
    inputs = 0, outputs = 1,
    update = function(self)
      self.output[1]:setvoltage(love.math.random())
    end,
  },

  Truth = {
    displayName = 'True',
    w = 1, h = 1,
    color = Color.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = Value:new{color = self.color}
    end,
    update = function(self)
      local node = self.default
      if self.input[1].link then
        node = self.input[1].link.val
      end
      self.color = node.color
      self.output[1]:set(node)
      local voltage = self.output[1]:getvoltage()
      if voltage == 1.0 or voltage == -1.0 then
        self.output[1]:setvoltage(1.0)
      else
        self.output[1]:setvoltage(0.0)
      end
    end,
    draw = function(self, drawx, drawy, scale)
      local color = self.color or Color.Fallback
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

      Logic.drawTruthSymbol(node,
        drawx + self.w * scale / 2, drawy + self.h * scale / 2,
        scale, self.w * 0.5, self.color
      )
    end,
  },

  AND = {
    displayName = 'AND',
    w = 2, h = 2,
    color = Color.BasicGate,
    inputs = 2,
    outputs = 1,
    init = function(self)
      self.default = Value:new{color = self.color}
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
    color = Color.BasicGate,
    inputs = 2,
    outputs = 1,
    init = function(self)
      self.default = Value:new{color = self.color}
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
  -- TODO: XOR
  NOT = {
    displayName = 'NOT',
    w = 1, h = 1,
    color = Color.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = Value:new{color = self.color}
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
    draw = function(self, drawx, drawy, scale)
      local color = self.color or Color.Fallback
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
    color = Color.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = Value:new{color = self.color}
    end,
    update = function(self)
      local node = self.default
      if self.input[1].link then
        node = self.input[1].link.val
      end
      self.color = node.color
      self.output[1]:set(node)
      local voltage = self.output[1]:getvoltage()
      self.output[1]:setvoltage(math.abs(voltage))
    end,
  },
  Sign = {
    displayName = 'Sign',
    w = 1, h = 1,
    color = Color.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = Value:new{color = self.color}
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
    draw = function(self, drawx, drawy, scale)
      local color = self.color or Color.Fallback
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

      Logic.drawSignSymbol(node,
        drawx + self.w * scale / 2, drawy + self.h * scale / 2,
        scale, self.w * 0.5, self.color
      )
    end
  },

  PassThru = {
    displayName = 'PassThru',
    w = 1, h = 1,
    color = Color.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = Value:new{color = self.color}
      self.visual = Value:new()
    end,
    update = function(self)
      local node
      if self.input[1].link then
        node = self.input[1].link.val
      else
        node = self.default
      end
      self.color = node.color or Color.BasicGate
      self.output[1]:set(node)
    end,
    --drawOutputNodes = function() end,
    --drawInputNodes = function() end,
    draw = function(self, offx, offy, scale)
      self.visual:set(self.output[1])
      self.visual:setvoltage(1.0)
      self.visual:drawIONode('arrow',
        offx + (self.w / 2) * scale,
        offy + (self.h / 2) * scale,
        scale * self.w * 2.25
      )
    end,
  },

  Colorize = {
    displayName = 'col',
    w = 1, h = 1,
    color = Color.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.color = Color:random()
      self.default = Value:new{color = self.color}
    end,
    update = function(self)
      local node
      if self.input[1].link then
        node = self.input[1].link.val
      else
        node = self.default
      end
      --self.color = node.color or Color.BasicGate
      self.output[1]:set(node)
      self.output[1]:setColor(self.color)
    end,
    --drawOutputNodes = function() end,
    --drawInputNodes = function() end,
    --[[
    draw = function(self, offx, offy, scale)
      self.visual:set(self.output[1])
      self.visual:setvoltage(1.0)
      self.visual:drawIONode('arrow',
        offx + (self.x + self.w / 2) * scale,
        offy + (self.y + self.h / 2) * scale,
        scale * self.w * 2.25
      )
    end,--]]
  },

  AVG = {
    displayName = 'Average',
    w = 2, h = 2,
    color = Color.BasicGate,
    inputs = 2,
    outputs = 1,
    init = function(self)
      self.default = Value:new{color = self.color}
    end,
    update = function(self)
      local passthru = self.default
      local val = 0
      local count = 0
      local color
      self.output[1]:set(self.default)
      if #self.input == 0 then return end
      for _, input in ipairs(self.input) do
        if input.link then
          val = val + input.link.val:getvoltage()
          color = input.link.val.color
        end
        count = count + 1
      end
      if count == 0 then
        self.output[1]:set(self.default)
      else
        self.output[1]:set{
          voltage = val / count,
          color = color,
        }
      end
    end,
  },

  Add = {
    displayName = 'Add',
    w = 2, h = 2,
    color = Color.BasicGate,
    inputs = 2,
    outputs = 1,
    init = function(self)
      self.default = Value:new{color = self.color}
    end,
    update = function(self)
      local passthru = self.default
      local val = 0
      local color = self.default.color
      self.output[1]:set(self.default)
      if #self.input == 0 then return end
      for _, input in ipairs(self.input) do
        if input.link then
          val = val + input.link.val:getvoltage()
          color = input.link.val.color
        end
      end
      self.output[1]:set{
        voltage = Value.clamp(val),
        color = color,
      }
    end,
  },

  Negate = {
    displayName = 'Neg',
    w = 1, h = 1,
    color = Color.BasicGate,
    inputs = 1,
    outputs = 1,
    init = function(self)
      self.default = Value:new{color = self.color}
    end,
    update = function(self)
      local node = self.default
      if self.input[1].link then
        node = self.input[1].link.val
      end
      self.color = node.color
      self.output[1]:set(node)
      self.output[1]:setvoltage(-self.output[1]:getvoltage())
    end,
  },
  SignSplit = {
    displayName = 'SignSplit',
    w = 2, h = 2,
    color = Color.BasicGate,
    inputs = 1,
    outputs = 2,
    init = function(self)
      self.default = Value:new{color = self.color}
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
    color = Color.FullWhite,
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
    draw = function(self, drawx, drawy, scale)
      local radius = self.w * scale / 2
      local drawx, drawy = drawx + radius, drawy + radius
      local brightness = 0
      local node
      if self.input[1] and self.input[1].link then
        node = self.input[1].link.val
      else
        node = self.input[1].default
      end

      brightness = math.abs(node:getvoltage())
      love.graphics.setColor(node.color * brightness)
      love.graphics.circle('fill', drawx, drawy, radius)

      love.graphics.setColor(node.color)
      love.graphics.setLineWidth(scale / 32)
      love.graphics.circle('line', drawx, drawy, radius)

      if SHOW_DEBUG_TEXT then
        love.graphics.setColor(node.color)
        love.graphics.print(tostring(node), drawx, drawy + radius)
      end
    end,
  },

  ProgBar = {
    displayName = 'ProgBar',
    w = 2, h = 1,
    color = Color.FullWhite,
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
    draw = function(self, drawx, drawy, scale)
      local node
      if self.input[1] and self.input[1].link then
        node = self.input[1].link.comp.output[self.input[1].link.index]
      else
        node = self.input[1].default
      end
      local length = node:getvoltage()
      local padding = scale / 32
      love.graphics.setColor(Color.Black)
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

  Multimeter = {
    displayName = 'Multimeter',
    w = 2, h = 2,
    color = Color.FullWhite,
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
    draw = function(self, drawx, drawy, scale)
      local node
      if self.input[1] and self.input[1].link then
        node = self.input[1].link.comp.output[self.input[1].link.index]
      else
        node = self.input[1].default
      end
      local length = node:getvoltage()
      local padding = scale / 32
      love.graphics.setColor(Color.Black)
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

      Logic.drawSignSymbol(node,
        drawx + (self.w / 4) * scale, drawy + (self.h / 4) * scale,
        scale, self.h / 4, node.color
      )

      local brightness = math.abs(node:getvoltage())
      love.graphics.setColor(node.color * brightness)
      love.graphics.circle('fill',
        drawx + (self.w * 3 / 4) * scale, drawy + (self.h / 4) * scale,
        self.h / 8 * scale
      )

      love.graphics.setColor(node.color)
      love.graphics.setLineWidth(padding * 2)
      love.graphics.circle('line',
        drawx + (self.w * 3 / 4) * scale, drawy + (self.h / 4) * scale,
        self.h / 8 * scale
      )

      love.graphics.rectangle(
        'fill',
        drawx + 5 * padding,
        drawy + (self.h / 2) * scale + 5 * padding,
        (self.w * scale - 10 * padding) * math.abs(length),
        (self.h / 2) * scale - 10 * padding
      )

      love.graphics.setLineWidth(padding)
      local lineX, lineY
      for i = 0, 2 do
        lineX, lineY = 
          drawx + (self.w * scale - 10 * padding) / 2 * i + 5 * padding,
          drawy + (self.h / 2) * scale + 4 * padding
        love.graphics.line(
          lineX, lineY,
          lineX, lineY - 5 * padding
        )
        if i < 2 then
        lineX, lineY = 
          drawx + (self.w * scale - 10 * padding) / 2 * i + 2.5 * padding + (self.w * scale) / 4,
          drawy + (self.h / 2) * scale + 4 * padding
          love.graphics.line(
            lineX, lineY,
            lineX, lineY - 3 * padding
          )
        end
      end
    end,
  },
}

function Logic:instance(name, x, y)
  local base = Logic.components[name]
  if not base then error('Component ' .. tostring(name) .. ' does not exist.', 2) end
  local comp = {
    base = name,
    name = base.displayName or name,
    x = x, y = y,
    w = base.w or 21, h = base.h or 21,
    color = base.color or Color.Fallback,
    input = {},
    output = {},
    init = base.init,
    update = base.update or self.update,
    draw = base.draw or self.draw,
    drawInputNodes = base.drawInputNodes or self.drawInputNodes,
    drawOutputNodes = base.drawOutputNodes or self.drawOutputNodes,
    collider = Collider:rect{-1, -1, 1, 1},
  }

  local inputNames, outputNames = base.inputNames or {}, base.outputNames or {}

  if type(base.inputs) == 'number' then
    for i = 1, base.inputs do
      comp.input[i] = {
        name = inputNames[i] or '',
        default = Value:new{color = comp.color},
        collider = Collider:rect{-1, -1, 1, 1},
        index = i,
        parent = comp,
        --link = nil,
        pick = function(self, mouse)
          if self.link then
            local val = self.link.val
            self.parent:unlinkInput(self.index)
            return val
          end
        end,
        class = 'Input',
      }
    end
  --elseif base.inputs == 'var' then
    -- there must be a better way to do variable number of inputs
  end

  if type(base.outputs) == 'number' then
    for i = 1, base.outputs do
      comp.output[i] = Value:new{
        name = outputNames[i] or '',
        color = comp.color,
        parent = comp,
        index = i,
        links = {},
        collider = Collider:rect{-1, -1, 1, 1},
      }
    end
  end

  if comp.init then comp:init() end

  setmetatable(comp, self)
  return comp
end

function Logic:link(o, other, i)
  if other.input[i].link then
    other:unlinkInput(i)
  end
  -- Using the other component as a key into the table, with a Value of a set
  -- of all linked indexes
  -- this is just crazy enough to work
  self.output[o].links[other] = self.output[o].links[other] or {}
  self.output[o].links[other][i] = true

  other.input[i].link = {comp = self, index = o, val = self.output[o]}
end

function Logic:unlinkInput(i)
  local link = self.input[i].link
  if link then
    link.comp:unlinkOutput(link.index, self, i)
  end
  self.input[i].link = nil
end

function Logic:unlinkAllInputs()
  for i, inp in pairs(self.input) do
    self:unlinkInput(i)
  end
end

function Logic:unlinkOutput(o, comp, i)
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

function Logic:unlinkAllOutputs()
  for o, val in pairs(self.output) do
    for comp, links in pairs(val.links) do
      for comp_index, exists in pairs(links) do
        --print(o, comp, comp_index, exists, val)
        self:unlinkOutput(o, comp, comp_index)
      end
    end
  end
end

function Logic:unlinkAll()
  self:unlinkAllInputs()
  self:unlinkAllOutputs()
end

--FIXME: DELETEME: delete it or use it
function Logic:getCoords(x, y)
  if x and y then
    return x, y
  elseif self.board then
    return
      self.x * self.board.scale + self.board.x,
      self.y * self.board.scale + self.board.y
  else
    return 0, 0
  end
end

function Logic:draw(drawx, drawy, scale)
  local color = self.color or Color.Fallback
  local darkColor = color / 3
  local mediumColor = darkColor * 2
  local padding = scale / 32

  love.graphics.setColor(darkColor)
  love.graphics.setLineWidth(padding)
  love.graphics.setLineJoin('miter')

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
  if scale >= 32 or SHOW_DEBUG_TEXT then
    love.graphics.print(self.name, drawx + 3 * padding, drawy + 3 * padding)
  end
end

function Logic:drawInputNodes(offx, offy, scale, color)
  color = self.color or Color.Fallback
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

function Logic:drawOutputNodes(offx, offy, scale, color)
  color = self.color or Color.Fallback
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

function Logic:drawHangingWire(offx, offy, scale, val, x1, y1, x2, y2)
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
  Logic.drawWire(offx, offy, scale, val, points)
end

function Logic:drawWiresCamera(cam)
  local x1, y1, x2, y2, scale
  if self.board then
    scale = self.board.scale * camera.zoom
    for indexO, val in ipairs(self.output) do
      x1, y1 = self:outputCoords(indexO)
      x1, y1 = cam:project(
        (self.x + x1) * self.board.scale + self.board.x,
        (self.y + y1) * self.board.scale + self.board.y
      )
      for comp, link in pairs(val.links) do
        for indexI, haslink in pairs(link) do
          if self.board == comp.board then
            x2, y2 = comp:inputCoords(indexI)
            x2, y2 = cam:project(
              (comp.x + x2) * comp.board.scale + comp.board.x,
              (comp.y + y2) * comp.board.scale + comp.board.y
            )
            Logic:drawHangingWire(0, 0, scale, val, x1, y1, x2, y2)
            val:drawIONode('o', x1, y1, scale)
            val:drawIONode('i', x2, y2, scale)
          else
            x2, y2 = comp:inputCoords(indexI)
            x2, y2 = cam:project(
              (comp.x + x2 * scale),
              (comp.y + y2 * scale)
            )
            Logic:drawHangingWire(0, 0, scale, val, x1, y1, x2, y2)
            val:drawIONode('o', x1, y1, scale)
            val:drawIONode('i', x2, y2, scale)
          end
        end
      end
    end
  else
    error('Logic:drawWiresCamera() called on floating component (component not on a board)', 2)
  end
  --[[
  for indexO, val in ipairs(self.output) do
    local v = val:getvoltage()
    local mag = math.abs(v)
    local vColor = val.color * mag
    local halfColor = val.color / 2
    x1, y1 = self:outputCoords(indexO)
    x1, y1 = x1 * scale + offx, y1 * scale + offy
    if val.links then
      for comp, link in pairs(val.links) do
        for indexI, hasLink in pairs(link) do
          if self.board and self.board == comp.board then
            x2, y2 = comp:inputCoords(indexI)
            x2, y2 = x2 * scale + offx, y2 * scale + offy
            Logic:drawHangingWire(offx, offy, scale, val, x1, y1, x2, y2)
            val:drawIONode('o', x1, y1, scale)
            val:drawIONode('i', x2, y2, scale)
          end
        end
      end
    end
  end
  --]]
end

function Logic:drawWires(offx, offy, scale)
  local x1, y1, x2, y2
  for indexO, val in ipairs(self.output) do
    local v = val:getvoltage()
    local mag = math.abs(v)
    local vColor = val.color * mag
    local halfColor = val.color / 2
    x1, y1 = self:outputCoords(indexO)
    x1, y1 = x1 * scale + offx, y1 * scale + offy
    if val.links then
      for comp, link in pairs(val.links) do
        for indexI, hasLink in pairs(link) do
          if self.board and self.board == comp.board then
            x2, y2 = comp:inputCoords(indexI)
            x2, y2 = x2 * scale + offx, y2 * scale + offy
            Logic:drawHangingWire(offx, offy, scale, val, x1, y1, x2, y2)
            val:drawIONode('o', x1, y1, scale)
            val:drawIONode('i', x2, y2, scale)
          end
        end
      end
    end
  end
end

function Logic:drawDebug(offx, offy, scale)
  if SHOW_COLLIDERS then
    love.graphics.setLineWidth(scale / 32)
    love.graphics.setLineJoin('miter')
    self:drawColliders()
  end
end

local function drawColliderColor(col)
  if col.hit then
    love.graphics.setColor(Color.BrightCyan)
  else
    love.graphics.setColor(Color.FullWhite)
  end
  col:draw()
end

function Logic:drawColliders()
  if self.collider then
    drawColliderColor(self.collider)
  end
  for o, out in ipairs(self.output) do
    if out.collider then
      drawColliderColor(out.collider)
    end
  end
  for i, inp in ipairs(self.input) do
    if inp.collider then
      drawColliderColor(inp.collider)
    end
  end
end

function Logic:updateMouseColliders(drawx, drawy, scale)
  self.collider:set{drawx, drawy, self.w * scale, self.h * scale}

  local ioHalfWidth = 0.25
  local x, y

  for o, out in ipairs(self.output) do
    x, y = self:outputCoords(o)
    x, y = drawx + (x - ioHalfWidth) * scale, drawy + (y - ioHalfWidth) * scale
    out.collider:set{x, y, 2 * ioHalfWidth * scale, 2 * ioHalfWidth * scale}
  end

  for i, inp in ipairs(self.input) do
    x, y = self:inputCoords(i)
    x, y = drawx + (x - ioHalfWidth) * scale, drawy + (y - ioHalfWidth) * scale
    inp.collider:set{x, y, 2 * ioHalfWidth * scale, 2 * ioHalfWidth * scale}
  end
end

function Logic:pick(mouse)
  self.board:remove(self)
  return self
end

function Logic:place(mouse)
  if mouse.hoveredObject and mouse.hoveredObject.class == 'Board' then
    return
  end
  return self
end

function Logic:inputCoords(i)
  return 0, (i - 0.5) * self.h / #self.input
end

function Logic:outputCoords(o)
  return self.w, (o - 0.5) * self.h / #self.output
end

function Logic.drawWire(offx, offy, scale, val, points)
  local v = val:getvoltage()
  local mag = math.abs(v)
  local vColor = val.color * mag
  local halfColor = val.color / 2
  --local quarterColor = val.color / 4
  --local threeQuarterColor = quarterColor * 3
  love.graphics.setLineJoin('bevel')
  love.graphics.setColor(halfColor)
  --[[
  if mag >= 0.5 then
    love.graphics.setColor(quarterColor)
  else
    love.graphics.setColor(threeQuarterColor)
  end
  --]]
  love.graphics.setLineWidth(scale / 4)
  love.graphics.line(points)
  love.graphics.setColor(vColor)
  love.graphics.setLineWidth(scale / 8)
  love.graphics.line(points)
end

function Logic.drawTruthSymbol(node, x, y, scale, shapeWidth, color)
  local voltage = node:getvoltage()
  shapeWidth = scale * shapeWidth * 0.5
  love.graphics.setLineWidth(scale / 16)
  love.graphics.setColor(color)
  if math.abs(voltage) == 1.0 then
    love.graphics.rectangle('fill',
      x - shapeWidth / 5,
      y - shapeWidth,
      shapeWidth / 5 * 2,
      shapeWidth * 2
    )
    love.graphics.rectangle('fill',
      x - shapeWidth,
      y - shapeWidth,
      shapeWidth * 2,
      shapeWidth / 5 * 2
    )
  else
    love.graphics.rectangle('fill',
      x - shapeWidth,
      y - shapeWidth,
      shapeWidth / 5 * 2,
      shapeWidth * 2
    )
    love.graphics.rectangle('fill',
      x - shapeWidth,
      y - shapeWidth,
      shapeWidth * 2,
      shapeWidth / 5 * 2
    )
    love.graphics.rectangle('fill',
      x - shapeWidth,
      y - shapeWidth / 5,
      shapeWidth * 3 / 2,
      shapeWidth / 5 * 2
    )
  end
end

function Logic.drawSignSymbol(node, x, y, scale, shapeWidth, color)
  local voltage = node:getvoltage()
  shapeWidth = scale * shapeWidth * 0.5
  love.graphics.setLineWidth(scale / 16)
  love.graphics.setColor(color)
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

rawset(_G, '_ALLOWGLOBALS', true)

return Logic
