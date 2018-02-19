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
  for _, name in ipairs{'x', 'y', 'w', 'h', 'scale', 'components'} do
    self[name] = data and data[name] or Board.prototype[name]
  end
  self.collider = Collider:rect{-1, -1, 1, 1}
  return self
end

function Board:update()
end

function Board:updateColliders(camera)
  local x0, y0, w0, h0 = camera:project(self.x, self.y, self.w, self.h, self.scale)
  self.collider:set{x0, y0, w0, h0}
end

function Board:draw(camera)
  local x0, y0, w0, h0, scale0 = camera:project(self.x, self.y, self.w, self.h, self.scale)
  local x1, y1, scale1
  love.graphics.setColor(Color.boardBG)
  love.graphics.rectangle('fill', x0, y0, w0, h0)
  for _, func in ipairs{
    'draw',
    'drawOutputNodes',
    'drawInputNodes',
    'drawWires',
    'drawDebug',
    'updateMouseColliders',
  } do
    for _, obj in ipairs(self.components) do
      if func == 'drawWires' then
        obj:drawWiresCamera(camera)
      else
        x1, y1, _, _, scale1 = camera:project(obj.x * self.scale + self.x, obj.y * self.scale + self.y, nil, nil, self.scale)
        --obj[func](obj, x0, y0, scale0)
        obj[func](obj, x1, y1, scale1)
      end
    end
  end
  if SHOW_COLLIDERS then
    love.graphics.setLineWidth(scale0 / 32)
    love.graphics.setLineJoin('bevel')
    local col = self.collider
    if col.hit then
      love.graphics.setColor(Color.BrightCyan)
    else
      love.graphics.setColor(Color.FullWhite)
    end
    col:draw()
  end
end

function Board:each()
  return function(self, i)
    i = i + 1
    local v = self[i]
    if v then
      return i, v
    end
  end, self, 0
end

function Board:insert(comp)
  self.components[#self.components + 1] = comp
  comp.board = self
  return comp
end

function Board:insertNew(...)
  local comp = Logic:instance(...)
  return self:insert(comp)
end

function Board:remove(which)
  local comp
  if type(which) == 'number' then
    comp = table.remove(self.components, which)
  else
    -- search backwards; faster, assuming that older components are
    -- less likely to be deleted.
    for i = #self.components, 1, -1 do
      if self.components[i] == which then
        comp = table.remove(self.components, i)
        break -- it's faster because it stops iterating early
      end
    end
  end
  comp.board = nil
  return comp
end

return Board
