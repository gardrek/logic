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

-- TODO: either switch over to using vectors, or remove this
--vec2 = require('vec2')
vector = require('vector')

-- list of colors for theming, etc
colors = require('colors')

-- This library is used to create and control the logic gates, sensors,  that make up logic circuitry
logic = require('logic')

-- This library is required by 'logic' and represents the signals passed thru
-- the logic circuitry
--value = require('value')

inspect = require('inspect')

mainboard = {
  x = 20, y = 20,
  scale = 32,
  components = {},
}

unicorn = {}

mouse = {
  pressed = {},
  down = {},
  number_of_buttons = 3, -- TODO: make this not necessarily constant? controls change based on number of buttons available?
  scroll_speed = 10,
}

rawset(_G, '_ALLOWGLOBALS', false)

function mainboard:draw()
  for _, func in ipairs{
    'draw',
    'drawOutputNodes',
    'drawInputNodes',
    'drawWires',
  } do
    for _, obj in ipairs(self.components) do
      obj[func](obj, self.x, self.y, self.scale)
    end
  end
  --[[
  for _, obj in ipairs(self.components) do
    obj:drawWires(self.x, self.y, self.scale)
  end
  for _, obj in ipairs(self.components) do
    obj:draw(self.x, self.y, self.scale)
  end
  --]]
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
    'NOT', 'Negate', 'Truth', 'ABS', 'Sign',
    'OR', 'AND', 'AVG', 'SignSplit',
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
  love.graphics.clear{0x22, 0x22, 0x22}
  mainboard:draw()
  love.graphics.setColor{0xff, 0xff, 0xff}
  if SHOW_DEBUG_TEXT then
    love.graphics.draw(unicorn.image, unicorn.x, unicorn.y)
    love.graphics.print(tostring(mouse.x), 600, 100)
    love.graphics.print(tostring(mouse.y), 650, 100)
    for i = 1, mouse.number_of_buttons do
      love.graphics.print(tostring(mouse.pressed[i]), 600 + (i - 1) * 40, 120)
      love.graphics.print(tostring(mouse.down[i]), 600 + (i - 1) * 40, 140)
    end
    love.graphics.print(tostring(mouse.heldobject), 600, 160)
  end
  if mouse.heldobject and mouse.heldobject.class == 'value' then
    local x1, y1 = mouse.heldobject:Coords()
    x1, y1 = (x1 * mainboard.scale) + mainboard.x, (y1 * mainboard.scale) + mainboard.y
    logic:drawHangingWire(offx, offy, mainboard.scale, mouse.heldobject, x1, y1, mouse.x, mouse.y)
    --[[logic.drawWire(offx, offy, mainboard.scale, mouse.heldobject, {
      x1, y1,
      x1 + 0.25 * mainboard.scale, y1,
      mouse.x - 0.25 * mainboard.scale, mouse.y,
      mouse.x, mouse.y
    })]]
    mouse.heldobject:drawIONode('o', x1, y1, mainboard.scale)
    mouse.heldobject:drawIONode('arrow', mouse.x, mouse.y, mainboard.scale)
  end
end

function love.update(dt)

  --[[ Idea for how to implement updates:
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

  mouse:update(mainboard)
  for index, obj in ipairs(mainboard.components) do
    --if obj.mouseInput then obj:mouseInput() end
    if obj.update then obj:update() end
  end
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

function love.mousepressed(x, y, button, isTouch)
  mouse.pressed[button] = true
end

function love.wheelmoved(x, y)
  if love.keyboard.isDown('lctrl') or love.keyboard.isDown('rctrl') then
    mainboard.scale = mainboard.scale + 8 * y
    if mainboard.scale <= 0 then mainboard.scale = 8 end
  else
    local dx, dy =  x * mainboard.scale / 4, y * mainboard.scale / 4
    if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
      mainboard.x, mainboard.y = mainboard.x + dy, mainboard.y + dx
    else
      mainboard.x, mainboard.y = mainboard.x + dx, mainboard.y + dy
    end
  end
end

function mouse:init()
  for i = 1, mouse.number_of_buttons do
    mouse.pressed[i] = false
    mouse.down[i] = false
  end
end

function mouse.update(mouse, board)
  mouse.x, mouse.y = love.mouse.getPosition()
  for i = 1, mouse.number_of_buttons do
    mouse.down[i] = love.mouse.isDown(i)
  end
  local x1, y1, x2, y2
  local blocked = false
  if mouse.pressed[1] then
    if mouse.heldobject then
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
            x1, y1 = x1, y1
            x2, y2 = (x1 + 1 / 4) * board.scale + board.x, (y1 + 1 / 4) * board.scale + board.y
            x1, y1 = (x1 - 1 / 4) * board.scale + board.x, (y1 - 1 / 4) * board.scale + board.y
            if mouse.x >= x1 and mouse.x < x2 and mouse.y >= y1 and mouse.y < y2 then
              mouse.heldobject.parent:link(mouse.heldobject.index, obj, indexI)
              --mouse.heldobject = nil
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
