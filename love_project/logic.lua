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

local colors = require('colors')

local value = require('value')

logic.components = {
  TestJoypad = {
    displayName = 'Joypad',
    w = 2, h = 8,
    color = colors.BasicSensor,
    inputs = 0, outputs = 8,
    outputNames = {'left', 'right', 'up', 'down', 'a', 'b', 'c', 'start'},
    update = function(self)
      local keyNames = {'left', 'right', 'up', 'down', 'z', 'x', 'c', 'return'}
      for index, name in ipairs(keyNames) do
        if love.keyboard.isDown(name) then
          self.output[index]:setvoltage(1.0)
        else
          self.output[index]:setvoltage(0.0)
        end
      end
    end,
  },
  Mouse = {
    displayName = 'Raw Mouse',
    w =2, h = 5,
    color = colors.BasicSensor,
    inputs = 0,
    outputs = 5,
    outputNames = {'x', 'y', 'left', 'right', 'middle'},
    init = function(self)
      local c
      for i = 1, 5 do
        c = {0x55, 0x55, 0x55}
        c[math.random(1,3)] = math.random(0,3) * 0x11 + 0x88
        c[math.random(1,3)] = math.random(0,3) * 0x11 + 0x88
        --self.output[i]:setColor(c)
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
      local maxval = 1.0
      for _, input in ipairs(self.input) do
        if input.link then
          val = math.abs(input.link.val:getvoltage())
          if val <= maxval then
            passthru = input.link.val
            maxval = val
          end
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
      local minval = 0.0
      for _, input in ipairs(self.input) do
        if input.link then
          val = math.abs(input.link.val:getvoltage())
          if val >= minval then
            passthru = input.link.val
            minval = val
          end
        end
      end
      self.output[1]:set(passthru)
    end,
  },
  NOT = {
    displayName = 'NOT',
    w = 2, h = 1,
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
      self.output[1]:setvoltage(1 - math.abs(self.output[1]:getvoltage()))
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
        node = self.input[1].link.comp.output[self.input[1].link.index]
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
      --DEBUG
      love.graphics.setColor(node.color)
      --[[
      love.graphics.rectangle(
        'line', drawx - radius, drawy - radius, radius * 2, radius * 2
      )
      --]]
      if SHOW_DEBUG_TEXT then love.graphics.print(tostring(node), drawx, drawy + radius) end
      --self:drawInputNodes(offx, offy, scale)
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
  }

  local inputNames, outputNames = base.inputNames or {}, base.outputNames or {}

  if type(base.inputs) == 'number' then
    for i = 1, base.inputs do
      comp.input[i] = {
        name = inputNames[i] or '',
        default = value:new{color = comp.color},
        parent = comp,
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
  local halfColor = {color[1] / 3, color[2] / 3, color[3] / 3}
  local thirdColor = {color[1] / 3 * 2, color[2] / 3 * 2, color[3] / 3 * 2}

  love.graphics.setColor(halfColor)
  love.graphics.rectangle(
    'fill', drawx + 2, drawy + 2,
    self.w * scale - 4, self.h * scale - 4
  )

  love.graphics.setLineWidth(2)
  love.graphics.setColor(thirdColor)
  love.graphics.rectangle(
    'line', drawx + 2, drawy + 2,
    self.w * scale - 4, self.h * scale - 4
  )

  love.graphics.setColor(color)
  love.graphics.print(self.name, drawx + 2, drawy + 2)
  --self:drawInputNodes(offx, offy, scale, color)
  --self:drawOutputNodes(offx, offy, scale, color)
end

function logic:drawInputNodes(offx, offy, scale, color)
  color = self.color or colors.Fallback
  local x, y, node
  for index, val in ipairs(self.input) do
    x, y = self.x * scale + offx, (self.y + index - 0.5) * scale + offy
    if val.link then
      node = val.link.comp.output[val.link.index]
    else
      node = val.default
    end
    love.graphics.setColor(node.color or color)
    if SHOW_DEBUG_TEXT then
      love.graphics.print(tostring(node), x + 6, y + 6)
    end
    node:drawNode(x, y, scale)
  end
end

function logic:drawOutputNodes(offx, offy, scale, color)
  color = self.color or colors.Fallback
  local x, y, node
  for index, val in ipairs(self.output) do
    love.graphics.setColor(val.color or color)
    x, y = (self.x + self.w) * scale + offx, (self.y + index - 0.5) * scale + offy
    if SHOW_DEBUG_TEXT then
      love.graphics.print(tostring(val.name), x - (self.w / 2) * scale, y - 12)
      love.graphics.print(tostring(val), x - (self.w / 2) * scale, y + 6)
    end
    val:drawNode(x, y, scale)
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
          --print(comp.input[index], link, index)
          x2, y2 = comp:inputCoords(indexI)
          x2, y2 = x2 * scale + offx, y2 * scale + offy
          love.graphics.setColor(halfColor)
          love.graphics.setLineWidth(w * 1.5)
          love.graphics.line(x1, y1, x2, y2)
          --love.graphics.polygon('fill', x1, y1 + w, x1, y1 - w, x2, y2 - w, x2, y2 + w)
          love.graphics.setColor(vColor)
          love.graphics.setLineWidth(w)
          love.graphics.line(x1, y1, x2, y2)
          --love.graphics.polygon('fill', x1, y1 + w2, x1, y1 - w2, x2, y2 - w2, x2, y2 + w2)
        end
      end
    end
  end
end

function logic:inputCoords(i)
  return self.x, self.y + i - 0.5
end

function logic:outputCoords(o)
  return self.x + self.w, self.y + o - 0.5
end

rawset(_G, '_ALLOWGLOBALS', true)

return logic
