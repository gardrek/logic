local Board = {}
Board.__index = Board

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
  return self
end

function Board:draw(camera)
  local x0, y0, w0, h0, scale0 = camera:project(self.x, self.y, self.w, self.h, self.scale)
  love.graphics.setColor(colors.boardBG)
  love.graphics.rectangle('fill', x0, y0, w0, h0)
  for _, func in ipairs{
    'draw',
    'drawOutputNodes',
    'drawInputNodes',
    'drawWires',
    'drawDebug',
  } do
    for _, obj in ipairs(self.components) do
      obj[func](obj, x0, y0, scale0)
    end
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
  return comp
end

function Board:insertNew(...)
  local comp = logic:instance(...)
  self.components[#self.components + 1] = comp
  return comp
end

function Board:remove(which)
  if type(which) == 'number' then
    table.remove(self.components, which):unlinkAll()
  else
    -- search backwards; faster, assuming that older components are
    -- less likely to be deleted.
    for i = #self.components, 1, -1 do
      if self.components[i] == which then
        table.remove(self.components, which):unlinkAll()
        break -- it's faster because it stops iterating early
      end
    end
  end
end

return Board
