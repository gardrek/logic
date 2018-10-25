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

-- This library stops you from (accidentally) creating globals
require('noglobals')

local Color = require('Color')

local Collider = require('Collider')

local Value = require('Value')

local Logic = {}
Logic.__index = Logic
Logic.class = 'Component'

function Value:Coords()
  if not self.parent then error('Cannot get coords of Value: Value has no parent.', 2) end
  return self.parent:outputCoords(self.index)
end

function Value:link(other)
  self.parent:link(self.index, other.parent, other.index)
end

function Value:pick(mouse) return self end

function Value:place(mouse)
  if mouse.hoveredObject then
    if mouse.hoveredObject.class == 'Input' then
      self:link(mouse.hoveredObject)
    elseif mouse.hoveredObject.class == 'Board' then
      local comp = Logic:instance('PassThru', mouse:reverseProject())
      comp:setColor(self.color)
      self:link(comp.input[1])
      local oldPlace = comp.place
      comp.place = function(self, mouse)
        local obj = oldPlace(self, mouse)
        if obj then
          return obj
        else
          self.place = nil
          self.mouseDelete = nil
          return self.output[1]
        end
      end
      comp.mouseDelete = function(self, mouse)
        if self.input[1].link then
          return self.input[1].link.val
        end
      end
      return comp
    end
  end
  return self
end

Logic.components = require('Components')(Logic)

local function pickInput(self, mouse)
  if self.link then
    local val = self.link.val
    self.parent:unlinkInput(self.index)
    return val
  end
end

function Logic:instance(name, x, y)
  local base = Logic.components[name]
  if not base then error('Component ' .. tostring(name) .. ' does not exist.', 2) end
  local comp = {
    base = name,
    name = base.displayName or name,
    x = x, y = y,
    w = base.w or 2, h = base.h or 2,
    color = base.color or Color.Fallback,
    input = {},
    output = {},
    init = base.init,
    update = base.update or self.update,
    draw = base.draw or self.draw, -- FIXME: maybe?
    scale = base.scale or 32,
    mouseCollider = Collider:rect{-1, -1, 1, 1},
  }

  setmetatable(comp, self)

  comp:updateWorldCollider()

  local inputNames, outputNames = base.inputNames or {}, base.outputNames or {}

  if type(base.inputs) == 'number' then
    for i = 1, base.inputs do
      comp:addInput(i, inputNames[i])
    end
  --elseif type(base.inputs) == 'table' and #base.inputs == 2 then
  end

  if type(base.outputs) == 'number' then
    for i = 1, base.outputs do
      comp:addOutput(i, inputNames[i])
    end
  end

  if comp.init then comp:init() end

  return comp
end

function Logic:dup()
  local base = self
  if not base then error('Component ' .. tostring(name) .. ' does not exist.', 2) end
  local comp = {
    base = base.base,
    name = base.name,
    x = base.x, y = base.y,
    w = base.w or 21, h = base.h or 21,
    color = base.color,
    input = {},
    output = {},
    init = base.init,
    update = base.update,
    draw = base.draw or self.draw, -- FIXME: maybe?
    scale = base.scale or 32,
    mouseCollider = Collider:rect{-1, -1, 1, 1},
  }

  setmetatable(comp, Logic)

  comp:updateWorldCollider()

  for i = 1, #base.input do
    comp.input[i] = {
      name = base.input[i].name,
      default = Value:new{color = comp.color},
      mouseCollider = Collider:rect{-1, -1, 1, 1},
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

  for i = 1, #base.output do
    comp.output[i] = Value:new{
      name = base.output[i].name,
      color = comp.color, --FIXME: inherit the individual i/o node's color?
      parent = comp,
      index = i,
      links = {},
      mouseCollider = Collider:rect{-1, -1, 1, 1},
    }
  end

  if comp.init then comp:init() end

  return comp
end

-------- IO Connections --------

function Logic:addInput(i, name)
  i = i or #self.input
  name = name or ''
  table.insert(self.input, i, {
    name = names,
    default = Value:new{color = self.color},
    mouseCollider = Collider:rect{-1, -1, 1, 1},
    index = i,
    parent = self,
    --link = nil,
    pick = pickInput,
    class = 'Input',
  })
end

function Logic:addOutput(i, name)
  i = i or #self.output
  name = name or ''
  table.insert(self.output, i, Value:new{
    name = name,
    color = self.color,
    parent = self,
    index = i,
    links = {},
    mouseCollider = Collider:rect{-1, -1, 1, 1},
  })
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

-------- Update --------

function Logic:update_internal()
  self.shadow_output = self.shadow_output or {}
  for i, v in ipairs(self.output) do
    self.shadow_output[i] = v:dup()
  end
  self:update()
  self.output, self.shadow_output = self.shadow_output, self.output
end

function Logic:update_external()
  self.output, self.shadow_output = self.shadow_output, self.output
end

-------- Drawing --------

function Logic:drawAll(cam)
  for _, func in ipairs{
    'draw',
    'drawOutputNodes',
    'drawInputNodes',
    'drawWires',
    'drawDebug',
  } do
    self[func](self, cam)
  end
end

function Logic:draw(cam)
  local drawx, drawy = cam:project(self.x, self.y)
  local scale = self.scale * cam.zoom
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

function Logic:drawInputNodes(cam)
  local drawx, drawy = cam:project(self.x, self.y)
  local scale = self.scale * cam.zoom
  local color = self.color or Color.Fallback
  local x, y, node
  for index, val in ipairs(self.input) do
    x, y = self:inputCoords(index)
    x, y = x * scale + drawx, y * scale + drawy
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

function Logic:drawOutputNodes(cam)
  local drawx, drawy = cam:project(self.x, self.y)
  local scale = self.scale * cam.zoom
  local color = self.color or Color.Fallback
  local x, y, node
  for index, val in ipairs(self.output) do
    love.graphics.setColor(val.color or color)
    x, y = self:outputCoords(index)
    x, y = x * scale + drawx, y * scale + drawy
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
    local sign = 1
    if y2 < y1 then sign = -1 end
    points = {
      x1, y1,
      x1 + curvesize, y1,
      x1 + curvesize, y1 + sign * curvesize,
      x2 - curvesize, y2 - sign * curvesize,
      x2 - curvesize, y2,
      x2, y2,
    }
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

function Logic:drawWires(cam)
  local selfDrawX, selfDrawY = cam:project(self.x, self.y)
  local otherDrawX, otherDrawY
  local x1, y1, x2, y2
  local scale = self.scale * cam.zoom
  for indexO, val in ipairs(self.output) do
    local v = val:getvoltage()
    local mag = math.abs(v)
    local vColor = val.color * mag
    local halfColor = val.color / 2
    x1, y1 = self:outputCoords(indexO)
    x1, y1 = x1 * scale + selfDrawX, y1 * scale + selfDrawY
    if val.links then
      for comp, link in pairs(val.links) do
        for indexI, hasLink in pairs(link) do
          --if self.board and self.board == comp.board then
            otherDrawX, otherDrawY = cam:project(comp.x, comp.y)
            x2, y2 = comp:inputCoords(indexI)
            x2, y2 = x2 * scale + otherDrawX, y2 * scale + otherDrawY
            Logic:drawHangingWire(0, 0, scale, val, x1, y1, x2, y2)
            val:drawIONode('o', x1, y1, scale)
            val:drawIONode('i', x2, y2, scale)
          --end
        end
      end
    end
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

function Logic:drawDebug(cam)
  --local drawx, drawy = cam:project(self.x, self.y)
  local scale = self.scale * cam.zoom
  love.graphics.setLineWidth(scale / 32)
  love.graphics.setLineJoin('miter')
  if SHOW_COLLIDERS then
    self:drawColliders()
--[[
  else
    love.graphics.setColor(Color.FullWhite)
    local x, y = cam:project(0,0)
    self.worldCollider:draw(x, y, cam.zoom)
--]]
  end
end

function Logic:drawColliders()
  if self.mouseCollider then
    drawColliderColor(self.mouseCollider)
  end
  for o, out in ipairs(self.output) do
    if out.mouseCollider then
      drawColliderColor(out.mouseCollider)
    end
  end
  for i, inp in ipairs(self.input) do
    if inp.mouseCollider then
      drawColliderColor(inp.mouseCollider)
    end
  end
end

function Logic:updateMouseColliders(cam)
  local drawx, drawy = cam:project(self.x, self.y)
  local scale = self.scale * cam.zoom
  self.mouseCollider:set{drawx, drawy, self.w * scale, self.h * scale}

  local ioHalfWidth = 0.25
  local x, y

  for o, out in ipairs(self.output) do
    x, y = self:outputCoords(o)
    x, y = drawx + (x - ioHalfWidth) * scale, drawy + (y - ioHalfWidth) * scale
    out.mouseCollider:set{x, y, 2 * ioHalfWidth * scale, 2 * ioHalfWidth * scale}
  end

  for i, inp in ipairs(self.input) do
    x, y = self:inputCoords(i)
    x, y = drawx + (x - ioHalfWidth) * scale, drawy + (y - ioHalfWidth) * scale
    inp.mouseCollider:set{x, y, 2 * ioHalfWidth * scale, 2 * ioHalfWidth * scale}
  end
end

function Logic:updateWorldCollider()
  local data = {
    self.x, self.y,
    self.w * self.scale, self.h * self.scale
  }
  if not self.worldCollider then
    self.worldCollider = Collider:rect(data)
  else
    self.worldCollider:set(data)
  end
end

function Logic:pick(mouse)
  self.board:remove(self)
  return self
end

function Logic:place(mouse)
  if
    mouse.hoveredObject and
    mouse.hoveredObject.class == 'Board' and
    mouse.hoveredObject:canBeInserted(
      self,
      Collider:rect{self.x, self.y,
      self.w * mouse.hoveredObject.scale,
      self.h * mouse.hoveredObject.scale}
    ) then
      --self.x, self.y = mouse.insertX, mouse.insertY
      --mouse.insertX, mouse.insertY = nil, nil
      mouse.hoveredObject:insert(self)
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

function Logic:setColor(c)
  self.color = c
  for _, v in ipairs{'default', 'visual',} do
    if type(self[v]) == 'table' and self[v].class == 'Value' then
      self[v]:setColor(c)
    end
  end
  for i, v in ipairs(self.input) do
    self.input[i].default:setColor(c)
  end
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

return Logic
