local Board = {}
Board.__index = Board
Board.class = 'Board'

local Logic = require('Logic')
local Color = require('Color')
local Collider = require('Collider')

Board.prototype = {
  x = 20, y = 20,
  w = 32, h = 32,
  scale = 32,
  components = {},
}

function Board:new(data)
  return setmetatable({}, Board):set(data)
end

function Board:set(data)
  for _, name in ipairs{'x', 'y', 'w', 'h', 'scale'} do
    self[name] = data and data[name] or Board.prototype[name]
  end
  --if Board.prototype.components and not data.components then
    self.components = {}
  --end
  self.mouseCollider = Collider:rect{-1, -1, 1, 1}
  return self
end

function Board:update()
  for _, obj in ipairs(self.components) do
    if obj.board ~= self then print(obj.board) error'' end
  end
end

function Board:updateColliders(camera)
  local x0, y0, w0, h0 = camera:projectRect(self.x, self.y, self.w, self.h, self.scale)
  self.mouseCollider:set{x0, y0, w0, h0}
end

function Board:draw(camera)
  local x0, y0, w0, h0, scale0 = camera:projectRect(self.x, self.y, self.w, self.h, self.scale)
  local x1, y1, scale1
  love.graphics.setColor(Color.boardBG)
  love.graphics.rectangle('fill', x0, y0, w0, h0)
  --[[
  for _, obj in ipairs(self.components) do
    obj:updateMouseColliders(camera)
    obj:drawAll(camera)
  end
  --]]
  for _, func in ipairs{
    'updateMouseColliders',
    'draw',
    'drawOutputNodes',
    'drawInputNodes',
    'drawWires',
    'drawDebug',
  } do
    for _, obj in ipairs(self.components) do
      obj[func](obj, camera)
    end
  end
  if SHOW_COLLIDERS then
    love.graphics.setLineWidth(scale0 / 32)
    love.graphics.setLineJoin('bevel')
    local col = self.mouseCollider
    if col.hit then
      love.graphics.setColor(Color.BrightCyan)
    else
      love.graphics.setColor(Color.FullWhite)
    end
    col:draw()
  end
end

function Board:each()
  return function(list, i)
    i = i + 1
    if not list then return end
    local v = list[i]
    if v then
      return i, v
    end
  end, self.components, 0
end

function Board:canBeInserted(comp, coll)
  if type(coll) == 'table' and coll.class ~= 'Collider' then
    coll = Collider:rect(coll)
  elseif not coll then
    coll = Collider:rect{comp.x, comp.y, comp.w * self.scale, comp.w * self.scale}
  end
  for _, obj in pairs(self.components) do
    if coll:collide(obj.worldCollider) then
      return false
    end
  end
  return true
end

function Board:insert(comp)
  self.components[#self.components + 1] = comp
  comp.board = self
  comp.scale = self.scale
  comp:updateWorldCollider()
  return comp
end

function Board:insertNew(...)
  local comp = Logic:instance(...)
  return self:insert(comp)
end

function Board:removeAtIndex(i)
  ---[[
  local t = self.components
  local obj = t[i]
  t[i] = t[#t]
  t[#t] = nil
  return obj
  --]] return table.remove(self.components, i)
end

function Board:remove(which)
  local comp
  if type(which) == 'number' then
    comp = self:removeAtIndex(which)--table.remove(self.components, which)
  else
    -- search backwards; faster, assuming that older components are
    -- less likely to be deleted.
    for i = #self.components, 1, -1 do
      if self.components[i] == which then
        comp = self:removeAtIndex(i)--table.remove(self.components, i)
        break -- it's faster because it stops iterating early
      end
    end
  end
  comp.board = nil
  return comp
end

return Board
