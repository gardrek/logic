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

_ALLOWGLOBALS = nil

-- TODO: switch over to using vectors for more than just Color and colliders

local Value = require 'Value'
local Vector = require 'Vector'
local Collider = require 'Collider'
local Color = require 'Color'
local Logic = require 'Logic'
local Board = require 'Board'
local Menu = require 'Menu'

--local inspect = require('inspect')

local active_menu = false

local mainboard = Board:new{
  x = 20, y = 10,
  w = 64, h = 32,
  scale = 32,
}

local camera = {
  x = -40, y = -30,
  minZoom = 1 / 32, maxZoom = 32,
  zoomLevels = {
    1/16, 3/32, 1/8, 3/16,
    1/4,  3/8,  1/2, 3/4,
    1,
    1.25,  1.5,   1.75,  2,
    2.5,   3,     3.5,   4,
    5,     6,     7,     8,
    10,   12,    14,    16,
    20,   24,    28,    32,
    --40,   48,    56,    64,
    --80,   96,   112,   128,
  },
  zoomIndex = 8 + 1
}

camera.zoom = camera.zoomLevels[camera.zoomIndex]

local mouse = {
  pressed = {},
  down = {},
  number_of_buttons = 3,
  scroll_speed = 10,
  camera = camera,
}

mouse.shape = {
  -100, -100,
   100, -100,
  -100,  100,
  -100,  100,
}

local function createHighlightImage(radius, color)
  radius = radius or 64
  color = {unpack(color)} or Color:new{0xaa, 0xaa, 0x55, 0xff} / 0xfe
  if not color[4] then color[4] = 1 end
  color = Vector:new(color)

  local highlightImage = love.image.newImageData(radius * 2 + 2, radius * 2 + 2)

  highlightImage:mapPixel(function(x, y, r, g, b, a)
    x = x - radius
    y = y - radius
    color[4] = 1 - math.min((math.sqrt(x * x + y * y) / radius), 1)
    return unpack(color)
    --return r, g, b, a
  end)

  return love.graphics.newImage(highlightImage)
end

mouse.highlightImage = createHighlightImage(64, Color.Yellow)

function mouse:new_context_menu()
  local t = {}
  local obj
  local held = false
  if self.heldObject then
    held = true
    obj = self.heldObject
  else
    obj = self.hoveredObject
  end
  if not obj then return false end
  if obj.class == 'Component' then
    --[[table.insert(t, {name = 'Tweak (not implemented)', action = function()
    end})]]
    if not held then
      table.insert(t, {name = 'Copy', action = function()
        if held then
          --if mouse:place() then
            --mouse.heldObject = obj:dup()
          --end
        else
          mouse.heldObject = obj:dup()
        end
      end})
    end
    table.insert(t, {name = 'Delete', action = function()
      if held then
        self:releaseObject()
      else
        obj:unlinkAll()
        if obj.board then
          obj.board:remove(obj)
        end
      end
    end})
  else
    return false
  end
  return Menu:new(Vector:new{self.x, self.y}, t, {color = obj and obj.color})
end

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
    {'NOT', 'Negate', 'Truth', 'ABS', 'Sign',},
    {'OR', 'AND', 'AVG', 'SignSplit', 'Add', 'Sub',},
    {'LED', 'ProgBar', 'Multimeter', 'NegProgBar',},
  }
  local offx, offy, maxw, obj
  offx = 1
  for xi, cat in ipairs(components) do
    maxw = 0
    offy = 1
    for yi, name in ipairs(cat) do
      --obj = mainboard:insertNew(name, offx , offy)
      obj = mainboard:insertNew(name, offx * mainboard.scale + mainboard.x, offy * mainboard.scale + mainboard.y)
      offy = offy + Logic.components[name].h + 1
      maxw = math.max(Logic.components[name].w, maxw)
    end
    offx = offx + maxw + 1
  end
  for yi = 1, 8 do
    local dye =
      mainboard:insertNew('Colorize', offx * mainboard.scale + mainboard.x, (yi * 2 - 1) * mainboard.scale + mainboard.y)
    --dye:setColor(Color.BasicGate)
  end
  
  --]]
  --for name in pairs(Logic.components) do print(name) end

  local obj = mainboard:insertLocal('AND', 14, 1)
  table.insert(obj.input, {
    name = '',
    default = Value:new{color = obj.color},
    mouseCollider = Collider:rect{-1, -1, 1, 1},
    index = #obj.input + 1,
    parent = obj,
    --link = nil,
    pick = function(self, mouse)
      if self.link then
        local val = self.link.val
        self.parent:unlinkInput(self.index)
        return val
      end
    end,
    class = 'Input',
  })
  obj.h = obj.h + 1
end

function love.draw()
  love.graphics.clear(Color.BG)
  mainboard:draw(camera)
  if mouse.heldObject then
    mouse:drawHighlight(camera, mouse.heldObject, mouse.highlightImage)
  elseif mouse.hoveredObject then
    mouse:drawHighlight(camera, mouse.hoveredObject, mouse.highlightImage)
  end
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
        comp.x + x1 * comp.scale,
        comp.y + y1 * comp.scale
      )
      scale1 = comp.scale * camera.zoom
      Logic:drawHangingWire(0, 0, scale1, mouse.heldObject, x1, y1, mouse.x, mouse.y)
      mouse.heldObject:drawIONode('o', x1, y1, scale1)
      mouse.heldObject:drawIONode('arrow', mouse.x, mouse.y, scale1)
    elseif mouse.heldObject.class == 'Component' then
      local obj = mouse.heldObject
      local x1, y1 = camera:reverseProject(mouse.x, mouse.y)
      obj.x, obj.y =
        x1 - obj.w / 2 * obj.scale,
        y1 - obj.h / 2 * obj.scale
      local board
      if mouse.hoveredObject then
        if mouse.hoveredObject.class == 'Board' then
          board = mouse.hoveredObject
        elseif
          mouse.hoveredObject.class == 'Value' or
          mouse.hoveredObject.class == 'Input' and
          mouse.hoveredObject.parent then
            board = mouse.hoveredObject.parent.board
        --[[
        elseif
          mouse.hoveredObject.board and
          mouse.hoveredObject.board.class == 'Board' then
            board = mouse.hoveredObject.board
        --]]
        end
      end
      if board then
        obj.x, obj.y =
        --mouse.insertX, mouse.insertY =
          math.floor((obj.x - board.x) / board.scale + 0.5) * board.scale + board.x,
          math.floor((obj.y - board.y) / board.scale + 0.5) * board.scale + board.y
      end
      obj:updateMouseColliders(camera)
      obj:drawAll(camera)
    end
  end

  if active_menu then
    active_menu:draw(camera)
    --error'yeee'
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
  mouse:draw(camera)
end

function love.update(dt)
  mouse:update{mainboard}
  mainboard:update()
  mainboard:updateColliders(camera)
  for index, obj in ipairs(mainboard.components) do
    --if obj.mouseInput then obj:mouseInput() end
    if obj.update then obj:update() end
    --if obj.collider then obj:updateColliders(camera, mainboard) end
  end
  if mouse.heldObject and mouse.heldObject.class == 'Component' then
    mouse.heldObject:update()
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
    -- TODO: FIXME: center/recenter the camera after a zoom
    --local dx, dy = 0, 0
    --camera.x, camera.y = camera.x + dx, camera.y + dy
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

  if active_menu then
    for i, v in ipairs(active_menu.items) do
      if v.collider.hit then
        --v.collider.hit = false
        v.action()
        active_menu = false
        break
      end
    end
    active_menu = false
  else
    if button == 1 then
      if mouse.heldObject then
        mouse:place()
      elseif mouse.hoveredObject then
        mouse:pick()
      end
    elseif button == 2 then
      if mouse.heldObject then
        if mouse.heldObject.class == 'Value' then
          mouse:releaseObject()
        elseif mouse.heldObject.class == 'Component' then
          if mouse.heldObject.base == 'PassThru' then
            mouse:releaseObject()
          else
            active_menu = mouse:new_context_menu()
          end
        end
      elseif mouse.hoveredObject then
        active_menu = mouse:new_context_menu()
      end
    elseif button == 3 then
      if mouse.heldObject then
        if mouse.heldObject.class == 'Component' then
          local obj = mouse.heldObject
          if mouse:place() then
            mouse.heldObject = obj:dup()
          end
        end
      else
        if mouse.hoveredObject then
          if mouse.hoveredObject.class == 'Board' then
            mouse:startDragScroll()
          elseif mouse.hoveredObject.class == 'Component' then
            mouse.heldObject = mouse.hoveredObject:dup()
          end
        else
          mouse:startDragScroll()
        end
      end
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
  mainboard.mouseCollider:collide(mouse.collider, hitCallback) -- set collision on mainboard
  -- should block this out if the mouse isn't colliding with the mainboard? that would completely disallow overhanging

  if active_menu then
    for i, v in ipairs(active_menu.items) do
      if v.collider:collide(mouse.collider, hitCallback) then
      end
    end
  else
    for _, obj in ipairs(mainboard.components) do
      local exitLoop
      for o, out in ipairs(obj.output) do
        if out.mouseCollider:collide(mouse.collider, hitCallback) then
          exitLoop = true
          mainboard.mouseCollider.hit = false
          obj.mouseCollider.hit = false
          mouse.hoveredObject = out
          break
        end
      end
      if exitLoop then break end
      for i, inp in ipairs(obj.input) do
        if inp.mouseCollider:collide(mouse.collider, hitCallback) then
          exitLoop = true
          mainboard.mouseCollider.hit = false
          obj.mouseCollider.hit = false
          mouse.hoveredObject = inp
          break
        end
      end
      if exitLoop then break end
      if obj ~= mouse.heldObject and obj.mouseCollider:collide(mouse.collider, hitCallback) then
        mainboard.mouseCollider.hit = false
        mouse.hoveredObject = obj
      end
    end
    if not mouse.hoveredObject and mainboard.mouseCollider.hit then
      mouse.hoveredObject = mainboard
    end
    if mouse.heldObject then
      mouse.heldObject.mouseCollider.hit = false
    end
  end

  --print(mouse.hoveredObject)
end

function mouse:draw(cam)
  love.graphics.setLineWidth(cam.zoom / 16)
  love.graphics.setLineJoin('miter')
  local color = Color.Magenta / 3
  love.graphics.setColor(color)
  love.graphics.polygon('fill', self.shape)
  love.graphics.setColor(color * 2)
  love.graphics.polygon('line', self.shape)
end

function mouse:drawHighlight(cam, obj, image)
  local drawX, drawY, scaleX, scaleY
  local iw, ih = image:getWidth(), image:getHeight()
  local scale = math.min(iw, ih)
  if obj.class == 'Input' or obj.class == 'Value' then
    local x, y
    if obj.class == 'Input' then
      x, y = obj.parent:inputCoords(obj.index)
    else
      x, y = obj:Coords()
    end
    drawX, drawY = cam:project((x) * obj.parent.scale + obj.parent.x, (y) * obj.parent.scale + obj.parent.y)
    scaleX, scaleY = 0.25 * cam.zoom, 0.25 * cam.zoom
  elseif obj.class == 'Component' then
    drawX, drawY = cam:project(obj.x + obj.w / 2 * obj.scale, obj.y + obj.h / 2 * obj.scale)
    scaleX, scaleY = (obj.w + 1.5) / scale * obj.scale * cam.zoom, (obj.h + 1.5) / scale * obj.scale * cam.zoom
  else
    return
  end
  love.graphics.setColor(Color.FullWhite)
  love.graphics.draw(image, drawX, drawY, 0, scaleX, scaleY, iw / 2 + 0.5, ih / 2 + 0.5)
end

function mouse:pick()
  if self.hoveredObject and self.hoveredObject.pick then
    self.heldObject = self.hoveredObject:pick(self)
  end
end

function mouse:place()
  if self.heldObject and self.heldObject.place then
    local obj = self.heldObject:place(self)
    if obj ~= self.heldObject then
      self.heldObject = obj
      return true
    end
  end
end

function mouse:releaseObject()
  local rObj
  if self.heldObject.mouseDelete then
    rObj = self.heldObject:mouseDelete(self)
  end
  if self.heldObject.class == 'Component' then
    mouse.heldObject:unlinkAll()
  end
  self.heldObject = rObj
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

function camera:projectRect(x, y, w, h, scale)
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

function mouse:reverseProject()
  return self.camera:reverseProject(self.x, self.y)
end

function camera:project(x, y)
  return x * self.zoom - self.x, y * self.zoom - self.y
end

function camera:reverseProject(x, y)
  return (x + self.x) / self.zoom, (y + self.y) / self.zoom
end
