-- Globals

-- This library stops you from (accidentally) creating globals
require('noglobals')

do -- This way the printed text won't look janky due to non-integer coords
  local old_print = love.graphics.print
  love.graphics.print = function(text, x, y, ...)
    old_print(text, math.floor(x + 0.5), math.floor(y + 0.5), ...)
  end
end

rawset(_G, '_ALLOWGLOBALS', true)

SHOW_DEBUG_TEXT = false
NO_COLOR_MODE = false

-- TODO: switch over to using vectors for more than just colors and colliders
vector = require('vector')

collider = require('collider')

-- list of colors for theming, etc
colors = require('colors')

-- This library is used to create and control the logic gates, sensors,  that make up logic circuitry
logic = require('logic')

Board = require('Board')

-- This library is required by 'logic' and represents the signals passed thru
-- the logic circuitry
--value = require('value')

inspect = require('inspect')

mainboard = Board:new()--[[{
  x = 20, y = 20,
  w = 32, h = 32,
  scale = 32,
  components = {},
}]]

unicorn = {}

camera = {
  x = 0, y = 0,
  --zoom = 1,
  minZoom = 1 / 32, maxZoom = 32,
  zoomLevels = {
    1/16, 1/8, 1/4, 1/2,
    1, 1.25, 1.5, 1.75, 2,
    2.5, 3, 3.5, 4,
    5, 6, 7, 8,
    10, 12, 14, 16,
    20, 24, 28, 32,
    --40, 48, 56, 64,
    --80, 96, 112, 128,
  },
  zoomIndex = 5
}

camera.zoom = camera.zoomLevels[camera.zoomIndex]

mouse = {
  pressed = {},
  down = {},
  number_of_buttons = 3, -- TODO: make this not necessarily constant? controls change based on number of buttons available?
  scroll_speed = 10,
}

rawset(_G, '_ALLOWGLOBALS', false)

--[[
function mainboard:draw()
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

function mainboard:each()
  return function(self, i)
    i = i + 1
    local v = self[i]
    if v then
      return i, v
    end
  end, self, 0
end

function mainboard:insert(comp)
  self.components[#self.components + 1] = comp
  return comp
end

function mainboard:insertNew(...)
  local comp = logic:instance(...)
  self.components[#self.components + 1] = comp
  return comp
end

function mainboard:remove(which)
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
]]

function love.load()
  io.stdout:setvbuf('no') -- enable normal use of the print() command

  mouse:init()

  --[[
  local mouse0 = mainboard:insertNew('Mouse', 1, 3)
  local gate0 = mainboard:insertNew('OR', 5, 2)
  local gate1 = mainboard:insertNew('NOT', 9, 3)
  local led0 = mainboard:insertNew('LED', 13, 4)
  mouse0:link(1, gate0, 1)
  mouse0:link(2, gate0, 2)
  gate0:link(1, gate1, 1)
  gate1:link(1, led0, 1)

  local gate2 = mainboard:insertNew('AND', 5, 5)
  mouse0:link(1, gate2, 1)
  mouse0:link(2, gate2, 2)

  --mouse0:unlinkAll()
  --]]

  mainboard:insertNew('Mouse', 1, 1)
  mainboard:insertNew('Joypad', 1, 6)

  local name = {
    'PassThru',
    'NOT', 'Negate', 'Truth', 'ABS', 'Sign', 'Random',
    'OR', 'AND', 'AVG', 'SignSplit', 'Add',
    'LED', 'ProgBar', 'Multimeter',
  }
  local placementy = 1
  local obj
  for yi in ipairs(name) do
    for xi = 0, 7 do
      if name[yi] then
        obj = mainboard:insertNew(name[yi], xi * 3 + 5, placementy)
      end
    end
    if name[yi] then
      placementy = placementy + logic.components[name[yi]].h
    end
  end

  --[[
  local inp1, out1, pin1, len
  len = #mainboard.components
  for i = 1, 256 do
    inp1 = mainboard.components[love.math.random(2, len)]
    out1 = mainboard.components[love.math.random(2, len)]
    pin1 = love.math.random(1, 2)
    inp1:link(1, out1, pin1)
  end
  --]]

  unicorn.image = love.graphics.newImage('unicorn.png')
  unicorn.x = 0--love.graphics.getWidth() / 2
  unicorn.y = 0--love.graphics.getHeight() / 8 * 7
end

function love.draw()
  love.graphics.clear(colors.BG)
  mainboard:draw(camera)
  if mouse.collider.hit then
    love.graphics.setColor(colors.Cyan)
  else
    love.graphics.setColor(colors.FullWhite)
  end
  if mouse.heldObject and mouse.heldObject.class == 'value' then
    local x1, y1, scale1
    x1, y1 = mouse.heldObject:Coords()
    x1, y1 = camera:project(x1 * mainboard.scale + mainboard.x, y1 * mainboard.scale + mainboard.y)
    scale1 = mainboard.scale * camera.zoom
    --[[
    local x1, y1 = mouse.heldObject:Coords()
    x1, y1 = (x1 * mainboard.scale) + mainboard.x, (y1 * mainboard.scale) + mainboard.y
    --]]
    logic:drawHangingWire(offx, offy, scale1, mouse.heldObject, x1, y1, mouse.x, mouse.y)
    mouse.heldObject:drawIONode('o', x1, y1, scale1)
    mouse.heldObject:drawIONode('arrow', mouse.x, mouse.y, scale1)
  end
  if SHOW_DEBUG_TEXT then
    mouse.collider:draw()
    local offx, offy = 0, 0
    --love.graphics.draw(unicorn.image, unicorn.x, unicorn.y)
    love.graphics.print(tostring(camera.x), offx, offy)
    love.graphics.print(tostring(camera.y), offx + 50, offy)
    love.graphics.print(tostring(camera.zoom), offx + 100, offy)
    for i = 1, mouse.number_of_buttons do
      love.graphics.print(tostring(mouse.pressed[i]), offx + (i - 1) * 40, offy + 20)
      love.graphics.print(tostring(mouse.down[i]), offx + (i - 1) * 40, offy + 40)
    end
    love.graphics.print(tostring(mouse.heldObject), offx, offy + 60)
  end
end

function love.update(dt)
  mouse:update{mainboard}
  for index, obj in ipairs(mainboard.components) do
    --if obj.mouseInput then obj:mouseInput() end
    if obj.update then obj:update() end
    if obj.collider then obj:updateCollider(camera, mainboard) end
  end

  -- new, better  idea: update colliders here, as we need the camera and the mainboard, and only visible components need colliders

  --[[
  -- Idea for how to implement updates:
  -- Probably won't work very well even for simple loops
  updateQueueCurrent = new List
  updateQueueNext = new List
  componentsLeft = allComponents:copy()

  for each component in componentsLeft {
    if component.number_of_connected_inputs == 0 then {
      # component has no inputs, so it's safe to update them in any order
      component:update()
      remove component from componentsLeft
      for each output in component {
        add output.component to updateQueueNext
        remove output.component from componentsLeft
      }
    }
  }

  while updateQueueNext.length != 0 {
    updateQueueCurrent = updateQueueNext
    updateQueueNext = new list
    for each component in updateQueueCurrent {
      component:update()
      for each output in component {
        add output.component to updateQueueNext
        remove output.component from componentsLeft
      }
    }
  }

  while componentsLeft.length != 0 {
    component:update()
  }
  ]]
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'escape' then
    love.event.quit()
  elseif key == 'f5' then
    love.event.quit('restart')
  elseif key == 'f7' then
    SHOW_DEBUG_TEXT = not SHOW_DEBUG_TEXT
  elseif key == 'f6' then
    NO_COLOR_MODE = not NO_COLOR_MODE
  end
end

function love.mousemoved(x, y, dx, dy, istouch)
  mouse.x, mouse.y = x, y
  mouse.collider:set{mouse.x, mouse.y}
  mouse:update()
end

function love.wheelmoved(x, y)
  if love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl') then
    camera.zoomIndex = math.min(math.max(1, camera.zoomIndex + y), #camera.zoomLevels)
    camera.zoom = camera.zoomLevels[camera.zoomIndex]
  else
    local dx, dy = - x * mainboard.scale / 4, - y * mainboard.scale / 4
    if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
      camera.x, camera.y = camera.x + dy, camera.y + dx
    else
      camera.x, camera.y = camera.x + dx, camera.y + dy
    end
  end
end

function love.mousepressed(x, y, button, istouch)
  mouse.pressed[button] = true
  local gx, gy = camera:reverseProject(x, y)
  if button == 1 then
    if mouse.heldObject then
      mouse:place()
    elseif mouse.hoveredObject then
      mouse:pick()
    end
  elseif button == 2 then
    if mouse.heldObject and mouse.heldObject.class == 'value' then
      mouse:releaseObject()
    end
  end
end

function love.mousereleased(x, y, button, istouch)
  mouse.pressed[button] = false
end

function mouse:init()
  for i = 1, self.number_of_buttons do
    self.pressed[i] = false
    self.down[i] = false
  end
  self.collider = collider:point{0, 0}
  self:update()
end

function mouse:update()
  self.x, self.y = love.mouse.getPosition()
  self.collider:set{self.x, self.y}
  --[[
  for i = 1, self.number_of_buttons do
    self.down[i] = love.mouse.isDown(i)
  end
  local x1, y1, x2, y2
  local blocked = false
  x1, y1 = camera:reverseProject(self.x, self.y)
  x2, y2 = camera:project(x1, y1)
  --print(self.x, self.y, x2, y2, self.x - x2, self.y - y2)
  --print(x1, y1)  if self.collider then
  --]]
  local function hitCallback(hit)
    if hit then return true, nil else return false, nil end
  end
  mouse.hoveredObject = nil
  for _, obj in ipairs(mainboard.components) do
    local exitLoop
    for o, out in ipairs(obj.output) do
      if out.collider:collide(mouse.collider, hitCallback) then
        exitLoop = true
        obj.collider.hit = false
        mouse.hoveredObject = out
        break
      end
    end
    if exitLoop then break end
    for i, inp in ipairs(obj.input) do
      if inp.collider:collide(mouse.collider, hitCallback) then
        exitLoop = true
        obj.collider.hit = false
        mouse.hoveredObject = inp
        break
      end
    end
    if exitLoop then break end
    if obj.collider:collide(mouse.collider, hitCallback) then
      mouse.hoveredObject = obj
    end
  end
  --print(mouse.hoveredObject)
end

function mouse:pick()
  if self.hoveredObject and self.hoveredObject.pick then
    self.heldObject = self.hoveredObject:pick(self)
  end
end

function mouse:place()
  if self.heldObject and self.heldObject.place then
    self.heldObject = self.heldObject:place(self)
  end
end

function mouse:releaseObject()
  self.heldObject = nil
end

function camera:project(x, y, w, h, scale)
  x = x or 0
  y = y or 0
  w = w or 1
  h = h or 1
  scale = scale or 1
  local nscale = self.zoom * scale
  return
    x * self.zoom - self.x, y * self.zoom - self.y,
    w * nscale, h * nscale,
    nscale
end

function camera:reverseProject(x, y)
  return (x + self.x) / self.zoom, (y + self.y) / self.zoom
end

--[[
function mouse.update_old(mouse, boardList)
  mouse.x, mouse.y = love.mouse.getPosition()
  for i = 1, mouse.number_of_buttons do
    mouse.down[i] = love.mouse.isDown(i)
  end
  local board = boardList[1]
  local x1, y1, x2, y2
  local blocked = false
  if mouse.pressed[1] then
    if mouse.heldObject then
      if mouse.heldobject.class == 'component' then
        for index, obj in ipairs(board.components) do
          if obj ~= mouse.heldobject then
            x1, y1, x2, y2 =
              mouse.heldobject.x, mouse.heldobject.y,
              mouse.heldobject.x + mouse.heldobject.w, mouse.heldobject.y + mouse.heldobject.h
            for index, obj in ipairs(board.components) do
              if obj ~= mouse.heldobject then
                if obj.x < x2 and obj.x + obj.w > x1 and obj.y < y2 and obj.y + obj.h > y1 then
                  blocked = true
                  break
                end
              end
            end
          end
        end
        if not blocked then mouse.heldobject = nil end
      elseif mouse.heldobject.class == 'value' then
        for index, obj in ipairs(board.components) do
          -- putting down wire
          for indexI, inp in ipairs(obj.input) do
            x1, y1 = obj:inputCoords(indexI)
            x2, y2 = (x1 + 1 / 4) * board.scale + board.x, (y1 + 1 / 4) * board.scale + board.y
            x1, y1 = (x1 - 1 / 4) * board.scale + board.x, (y1 - 1 / 4) * board.scale + board.y
            if mouse.x >= x1 and mouse.x < x2 and mouse.y >= y1 and mouse.y < y2 then
              mouse.heldobject.parent:link(mouse.heldobject.index, obj, indexI)
              break
            end
          end
        end
      end
    else
      for index, obj in ipairs(board.components) do
        -- picking up wire from output
        for indexO, val in ipairs(obj.output) do
          x1, y1 = obj:outputCoords(indexO)
          x1, y1 = x1, y1
          x2, y2 = (x1 + 1 / 4) * board.scale + board.x, (y1 + 1 / 4) * board.scale + board.y
          x1, y1 = (x1 - 1 / 4) * board.scale + board.x, (y1 - 1 / 4) * board.scale + board.y
          if mouse.x >= x1 and mouse.x < x2 and mouse.y >= y1 and mouse.y < y2 then
            mouse.heldobject = val
            break
          end
        end
        if mouse.heldobject then break end
        -- picking up wire from input
        for indexI, inp in ipairs(obj.input) do
          x1, y1 = obj:inputCoords(indexI)
          x1, y1 = x1, y1
          x2, y2 = (x1 + 1 / 4) * board.scale + board.x, (y1 + 1 / 4) * board.scale + board.y
          x1, y1 = (x1 - 1 / 4) * board.scale + board.x, (y1 - 1 / 4) * board.scale + board.y
          if mouse.x >= x1 and mouse.x < x2 and mouse.y >= y1 and mouse.y < y2 then
            if inp.link then
              mouse.heldobject = inp.link.val
              obj:unlinkInput(indexI)
              break
            end
          end
        end
        if mouse.heldobject then break end
        -- picking up component
        x1, y1, x2, y2 =
          obj.x * board.scale + board.x, obj.y * board.scale + board.y,
          (obj.x + obj.w) * board.scale + board.x, (obj.y + obj.h) * board.scale + board.y
        if mouse.x >= x1 and mouse.x < x2 and mouse.y >= y1 and mouse.y < y2 then
          mouse.heldobject = obj
          break
        end
      end
    end
  elseif mouse.heldobject then
    if mouse.heldobject.class == 'component' then
      mouse.heldobject.x, mouse.heldobject.y =
        math.floor((mouse.x - board.x) / board.scale - (mouse.heldobject.w / 2) + 0.5),
        math.floor((mouse.y - board.y) / board.scale - (mouse.heldobject.h / 2) + 0.5)
    elseif mouse.heldobject.class == 'value' then
      if mouse.pressed[2] then
        mouse.heldobject = nil
      end
    end
  end

  for i = 1, mouse.number_of_buttons do
    mouse.pressed[i] = false
  end
end
--]]
