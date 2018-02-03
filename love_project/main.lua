-- Globals

-- This library stops you from (accidentally) creating globals
require('noglobals')

rawset(_G, '_ALLOWGLOBALS', true)

SHOW_DEBUG_TEXT = true

-- list of colors for theming, etc
colors = require('colors')

-- This library is used to create and control the logic gates, sensors,  that make up logic circuitry
logic = require('logic')

-- This library is required by 'logic' and represents the signals passed thru
-- the logic circuitry
--value = require('value')

inspect = require('inspect')

mainboard = {
  x = 0, y = 0,
  scale = 48,
  components = {},
}

unicorn = {}

mouse = {
  pressed = {},
  down = {},
  number_of_buttons = 3, -- TODO: make this not necessarily constant? controls change based on number of buttons available?
}

rawset(_G, '_ALLOWGLOBALS', false)

function mainboard:draw()
  for _, func in ipairs{
    'draw',
    'drawWires',
    'drawOutputNodes',
    'drawInputNodes',
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

  unicorn.image = love.graphics.newImage('unicorn.png')
  unicorn.x = love.graphics.getWidth() / 2
  unicorn.y = love.graphics.getHeight() / 8 * 7
end

function love.draw()
  love.graphics.clear{0x22, 0x22, 0x22}
  --onents:draw(mainboard.x, mainboard.y, mainboard.scale)
  mainboard:draw()
  love.graphics.setColor{0xff, 0xff, 0xff}
  love.graphics.draw(unicorn.image, unicorn.x, unicorn.y)
  if SHOW_DEBUG_TEXT then
    love.graphics.print(tostring(mouse.x), 600, 100)
    love.graphics.print(tostring(mouse.y), 650, 100)
    for i = 1, mouse.number_of_buttons do
      love.graphics.print(tostring(mouse.pressed[i]), 600 + (i - 1) * 40, 120)
      love.graphics.print(tostring(mouse.down[i]), 600 + (i - 1) * 40, 140)
    end
    love.graphics.print(tostring(mouse.heldobject), 600, 160)
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

function love.mousepressed(x, y, button, isTouch)
  mouse.pressed[button] = true
end

function love.wheelmoved(x, y)
  --mainboard.x, mainboard.y = mainboard.x + x * 5, mainboard.y + y * 5
  mainboard.scale = mainboard.scale + y * 8
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
      for index, obj in ipairs(board.components) do
        if obj ~= mouse.heldobject then
          x1, y1, x2, y2 =
            mouse.heldobject.x, mouse.heldobject.y,
            mouse.heldobject.x + mouse.heldobject.w, mouse.heldobject.y + mouse.heldobject.h
          for index, obj in ipairs(board.components) do
            if obj ~= mouse.heldobject then
              if obj.x < x2 and obj.x + obj.w > x1 and obj.y < y2 and obj.y + obj.h > y1 then
                print(obj.name)
                blocked = true
                break
              end
            end
          end
        end
      end
      if not blocked then mouse.heldobject = nil end
    else
      for index, obj in ipairs(board.components) do
        -- picking up wires
        for indexO, val in ipairs(obj.output) do
          x1, y1 = obj:outputCoords(indexO)
          x2, y2 = x1 + board.scale / 8, y1 + board.scale / 8
          x1, y1 = x1 - board.scale / 8, y1 - board.scale / 8
          if mouse.x >= x1 and mouse.x < x2 and mouse.y >= y1 and mouse.y < y2 then
            error'sd'
            mouse.heldobject = true --val
            --obj:unlinkAll()
            break
          end
        end
        if mouse.heldobject then break end
        -- picking up components
        x1, y1, x2, y2 =
          obj.x * board.scale + board.x, obj.y * board.scale + board.x,
          (obj.x + obj.w) * board.scale + board.x, (obj.y + obj.h) * board.scale + board.x
        if mouse.x >= x1 and mouse.x < x2 and mouse.y >= y1 and mouse.y < y2 then
          mouse.heldobject = obj
          --obj:unlinkAll()
          break
        end
      end
    end
  elseif mouse.heldobject then
    mouse.heldobject.x, mouse.heldobject.y =
      math.floor((mouse.x - board.x) / board.scale - (mouse.heldobject.w / 2) + 0.5),
      math.floor((mouse.y - board.y) / board.scale - (mouse.heldobject.h / 2) + 0.5)
  end

  for i = 1, mouse.number_of_buttons do
    mouse.pressed[i] = false
  end
end
