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
SHOW_COLLIDERS = false
SHOW_MOUSE_INFO = false
COLOR_MODE = {NONE = 0, NORMAL = 1, SIGN = 2}
COLOR_MODE.CURRENT = COLOR_MODE.NORMAL

-- TODO: switch over to using vectors for more than just Color and colliders
local Vector = require('Vector')

local Collider = require('Collider')

-- colors for theming, etc and maybea function or two
local Color = require('Color')

-- This library is used to create and control the Logic gates, sensors,  that make up Logic circuitry
local Logic = require('Logic')

local Board = require('Board')

--inspect = require('inspect')

mainboard = Board:new{
  x = 20, y = 10,
  w = 32, h = 20,
  scale = 32,
}

camera = {
  x = -40, y = -30,
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
  camera = camera,
}

rawset(_G, '_ALLOWGLOBALS', false)

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

  --[===[
  mainboard:insertNew('Mouse', 1, 1)
  mainboard:insertNew('Joypad', 1, 6)

  local name = {
    'PassThru',  'Colorize',
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
      placementy = placementy + Logic.components[name[yi]].h
    end
  end
  --]===]

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

  --[[
  local cca,ccb,ccc,ccd =
    mainboard:insertNew('NOT', 1, 1),
    mainboard:insertNew('NOT', 3, 2),
    mainboard:insertNew('NOT', 1, 3),
    mainboard:insertNew('NOT', 3, 4)
    --]]


  ---[[
  local components = {
    {'Mouse', 'Joypad', 'Random',},
    {'PassThru', 'NOT', 'Negate', 'Truth', 'ABS', 'Sign',},
    {'OR', 'AND', 'AVG', 'SignSplit', 'Add',},
    {'LED', 'ProgBar', 'Multimeter',},
  }
  local offx, offy, maxw, obj
  offx = 1
  for xi, cat in ipairs(components) do
    maxw = 0
    offy = 1
    for yi, name in ipairs(cat) do
      obj = mainboard:insertNew(name, offx, offy)
      offy = offy + Logic.components[name].h + 1
      maxw = math.max(Logic.components[name].w, maxw)
    end
    offx = offx + maxw + 1
  end
  for yi = 1, 8 do
    mainboard:insertNew('Colorize', offx, yi * 2 - 1)
  end
  --]]
  --for name in pairs(Logic.components) do print(name) end
end

function love.draw()
  love.graphics.clear(Color.BG)
  mainboard:draw(camera)
  if mouse.heldObject then
    if mouse.heldObject.class == 'Value' then
      local x1, y1, scale1
      x1, y1 = mouse.heldObject:Coords()
      x1, y1 = camera:project(x1 * mainboard.scale + mainboard.x, y1 * mainboard.scale + mainboard.y)
      scale1 = mainboard.scale * camera.zoom
      --[[
      local x1, y1 = mouse.heldObject:Coords()
      x1, y1 = (x1 * mainboard.scale) + mainboard.x, (y1 * mainboard.scale) + mainboard.y
      --]]
      local comp = mouse.heldObject.parent
      x1, y1 = mouse.heldObject:Coords()
      x1, y1 = camera:project(
        (comp.x + x1) * comp.board.scale + comp.board.x,
        (comp.y + y1) * comp.board.scale + comp.board.y
      )
      scale1 = comp.board.scale * camera.zoom
      --Logic:drawHangingWire(offx, offy, scale1, mouse.heldObject, x1, y1, mouse.x, mouse.y)
      Logic:drawHangingWire(0, 0, scale1, mouse.heldObject, x1, y1, mouse.x, mouse.y)
      mouse.heldObject:drawIONode('o', x1, y1, scale1)
      mouse.heldObject:drawIONode('arrow', mouse.x, mouse.y, scale1)
    elseif mouse.heldObject.class == 'Component' then
      local scale = camera.zoom * 32
      local obj = mouse.heldObject
      obj.x, obj.y = mouse.x - obj.w / 2 * scale, mouse.y - obj.h / 2 * scale
      obj:draw(obj.x, obj.y, scale)
    end
  end
  if SHOW_MOUSE_INFO then
    love.graphics.setColor(Color.FullWhite)
    --mouse.collider:draw()
    local offx, offy = 0, 0
    love.graphics.print(tostring(camera.x), offx, offy)
    love.graphics.print(tostring(camera.y), offx + 50, offy)
    love.graphics.print(tostring(camera.zoom), offx + 100, offy)
    for i = 1, mouse.number_of_buttons do
      love.graphics.print(tostring(mouse.pressed[i]), offx + (i - 1) * 40, offy + 20)
      love.graphics.print(tostring(mouse.down[i]), offx + (i - 1) * 40, offy + 40)
    end
    if mouse.heldObject then
      love.graphics.print(tostring(mouse.heldObject.class) .. ' ' .. tostring(mouse.heldObject), offx, offy + 60)
    end
    if mouse.hoveredObject then
      love.graphics.print(tostring(mouse.hoveredObject.class) .. ' ' .. tostring(mouse.hoveredObject), offx, offy + 80)
    end
  end
end

function love.update(dt)
  mouse:update{mainboard}
  --mainboard:update()
  mainboard:updateColliders(camera)
  for index, obj in ipairs(mainboard.components) do
    --if obj.mouseInput then obj:mouseInput() end
    if obj.update then obj:update() end
    --if obj.collider then obj:updateColliders(camera, mainboard) end
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
  elseif key == 'f6' then
    SHOW_COLLIDERS = not SHOW_COLLIDERS
  elseif key == 'f7' then
    SHOW_DEBUG_TEXT = not SHOW_DEBUG_TEXT
  elseif key == 'f8' then
    SHOW_MOUSE_INFO = not SHOW_MOUSE_INFO
  end
end

function love.mousemoved(x, y, dx, dy, istouch)
  if mouse.dragScroll then
    camera.x, camera.y = camera.x - dx, camera.y - dy
    return
  end
  mouse.x, mouse.y = x, y
  mouse.collider:set{mouse.x, mouse.y}
  mouse:update()
end

function love.wheelmoved(x, y)
  if love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl') then
    camera.zoomIndex = math.min(math.max(1, camera.zoomIndex + y), #camera.zoomLevels)
    camera.zoom = camera.zoomLevels[camera.zoomIndex]
  else
    local dx, dy = x * -32, y * -32
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
    if mouse.heldObject and mouse.heldObject.class == 'Value' then
      mouse:releaseObject()
    end
  elseif button == 3 then
    if not mouse.heldObject and (not mouse.hoveredObject or mouse.hoveredObject.class == 'Board') then
      mouse:startDragScroll()
    end
  end
end

function love.mousereleased(x, y, button, istouch)
  mouse.pressed[button] = false
  if mouse.dragScroll and button == 3 then
    mouse:endDragScroll()
  end
end

function mouse:init()
  for i = 1, self.number_of_buttons do
    self.pressed[i] = false
    self.down[i] = false
  end
  self.collider = Collider:point{0, 0}
  self:update()
end

function mouse:update()
  if self.dragScroll then
    -- do dragScroll stuff
    return
  end
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
  mainboard.collider:collide(mouse.collider, hitCallback) -- set collision on mainboard
  -- should 'if' block this out if the mouse isn't colliding with the mainboard?
  for _, obj in ipairs(mainboard.components) do
    local exitLoop
    for o, out in ipairs(obj.output) do
      if out.collider:collide(mouse.collider, hitCallback) then
        exitLoop = true
        mainboard.collider.hit = false
        obj.collider.hit = false
        mouse.hoveredObject = out
        break
      end
    end
    if exitLoop then break end
    for i, inp in ipairs(obj.input) do
      if inp.collider:collide(mouse.collider, hitCallback) then
        exitLoop = true
        mainboard.collider.hit = false
        obj.collider.hit = false
        mouse.hoveredObject = inp
        break
      end
    end
    if exitLoop then break end
    if obj ~= mouse.heldObject and obj.collider:collide(mouse.collider, hitCallback) then
      mainboard.collider.hit = false
      mouse.hoveredObject = obj
    end
  end
  if not mouse.hoveredObject and mainboard.collider.hit then
    mouse.hoveredObject = mainboard
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

function mouse:startDragScroll()
  mouse.old_coords = {love.mouse.getPosition()}
  love.mouse.setRelativeMode(true)
  mouse.dragScroll = true
end

function mouse:endDragScroll()
  love.mouse.setRelativeMode(false)
  love.mouse.setPosition(unpack(mouse.old_coords))
  mouse.old_coords = nil
  mouse.dragScroll = false
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
