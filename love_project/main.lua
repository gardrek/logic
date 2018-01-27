--Globals
logic = require('logic')
colors = require('colors')

value = require('value')


mainboard = {
  x = 0, y = 0,
  scale = 48,
  components = {},
}
unicorn = {}
mouse = {}

function mainboard:draw()
  for _, obj in ipairs(self.components) do
    obj:draw(self.x, self.y, self.scale)
  end
  for _, obj in ipairs(self.components) do
    --obj:drawWires(self.x, self.y, self.scale)
  end
end

function mainboard:insert(comp)
  self.components[#self.components + 1] = comp
end

function mainboard:delete(index)
  table.remove(self.components, index):disconnectAll()
end

function love.load()
  io.stdout:setvbuf('no') -- enable normal use of the print() command

  local mouse = logic:instance('Mouse',1 ,1 )
  mainboard:insert(mouse)
  local gate0 = logic:instance('AND',1 ,1 )
  --mainboard:insert(gate0)

  --[[
  local mouse0 = logic.comp.base.Mouse:instance{x = 1, y = 1}
  mainboard:insert(mouse0)
  local gate0 = logic.comp.base.AVG:instance{x = 6, y = 2}
  gate0:connect(1, mouse0, 1)
  gate0:connect(2, mouse0, 2)
  mainboard:insert(gate0)
  local led0 = logic.comp.base.RGB:instance{x = 9, y = 2}
  led0:connect(1, gate0, 1)
  mainboard:insert(led0)
  --]]

  --[[
  local mouse0 = logic.comp.base.Mouse:instance{x = 1, y = 1}
  mainboard:insert(mouse0)
  local binx = logic.comp.base.Truth:instance{x = 4, y = 1}
  binx:connect(1, mouse0, 1)
  mainboard:insert(binx)
  local biny = logic.comp.base.RangeToPositive:instance{x = 4, y = 3}
  biny:connect(1, mouse0, 2)
  mainboard:insert(biny)
  local bin3 = logic.comp.base.NOT:instance{x = 4, y = 5}
  bin3:connect(1, mouse0, 2)
  mainboard:insert(bin3)
  local gate0 = logic.comp.base.AVG:instance{x = 6, y = 2}
  gate0:connect(1, binx, 1)
  gate0:connect(2, biny, 1)
  mainboard:insert(gate0)
  local gate1 = logic.comp.base.SUB:instance{x = 6, y = 5}
  gate1:connect(1, mouse0, 1)
  gate1:connect(2, bin3, 1)
  mainboard:insert(gate1)
  local gate2 = logic.comp.base.OR:instance{x = 6, y = 8}
  gate2:connect(1, mouse0, 1)
  gate2:connect(2, mouse0, 2)
  mainboard:insert(gate2)
  local gate3 = logic.comp.base.XOR:instance{x = 6, y =11}
  gate3:connect(1, mouse0, 1)
  gate3:connect(2, mouse0, 2)
  mainboard:insert(gate)
  local led1 = logic.comp.base.RGB:instance{x = 9, y = 5}
  led1:connect(1, gate1, 1)
  mainboard:insert(led1)
  local led0 = logic.comp.base.RGB:instance{x = 9, y = 2}
  led0:connect(1, gate0, 1)
  mainboard:insert(led0)
  --]]
  --[[
  local inputA, inputB, gate, output
  inputA = logic.comp.base.Mouse:instance{x = 1, y = 1}
  inputB = logic.comp.base.SWITCH:instance{x = 1, y = 5}
  gate = logic.comp.base.AND:instance{x = 5, y = 3}
  output = logic.comp.base.LED:instance{x = 10, y = 3}
  gate:connect(1, inputA, 1)
  --gate:connect(2, inputB, 1)
  gate:connect(2, inputA, 2) -- not working…
  output:connect(1, gate, 1)
  for k, v in ipairs{inputA, inputB, gate, output} do
    components[#components + 1] = v
  end
  components[#components + 1] = logic.comp.base.AVG:instance{x = 1, y = 9}
  --]]

  unicorn.image = love.graphics.newImage('unicorn.png')
  unicorn.x = love.graphics.getWidth() / 2
  unicorn.y = love.graphics.getHeight() / 8 * 7
end

function love.draw()
  love.graphics.clear({0x22, 0x22, 0x22})
  --onents:draw(mainboard.x, mainboard.y, mainboard.scale)
  mainboard:draw()
  love.graphics.setColor{0xff, 0xff, 0xff}
  love.graphics.draw(unicorn.image, unicorn.x, unicorn.y)
  ---[[
  love.graphics.print(tostring(mouse.x), 600, 100)
  love.graphics.print(tostring(mouse.y), 650, 100)
  love.graphics.print(tostring(mouse.pressed), 600, 120)
  love.graphics.print(tostring(mouse.down), 600, 140)
  love.graphics.print(tostring(mouse.heldobject), 600, 160)
  --]]
end

function love.update(dt)
  updatemouse(mainboard)
  for index, obj in ipairs(mainboard.components) do
    --if obj.mouseInput then obj:mouseInput() end
    if obj.update then obj:update() end
  end
end

function love.mousepressed(x, y, button, isTouch)
  --if button == 1 then mouse.pressed == true end
end

function love.wheelmoved(x, y)
  mainboard.x, mainboard.y = mainboard.x + x * 5, mainboard.y + y * 5
end

function updatemouse(board)
  mouse.x, mouse.y = love.mouse.getPosition()
  local down = love.mouse.isDown(1)
  mouse.pressed = down and not mouse.down
  mouse.down = down
  down = love.mouse.isDown(3)
  mouse.pressed2 = down and not mouse.down2
  mouse.down2 = down
  if  mouse.pressed2 then print('yy') end
  local x1, y1, x2, y2
  local blocked = false
  if mouse.pressed then
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
        x1, y1, x2, y2 =
          obj.x * board.scale + board.x, obj.y * board.scale + board.x,
          (obj.x + obj.w) * board.scale + board.x, (obj.y + obj.h) * board.scale + board.x
        if mouse.x >= x1 and mouse.x < x2 and mouse.y >= y1 and mouse.y < y2 then
          mouse.heldobject = obj
          --obj:disconnectAll()
          break
        end
      end
    end
  elseif mouse.heldobject then
    mouse.heldobject.x, mouse.heldobject.y =
      math.floor((mouse.x - board.x) / board.scale - (mouse.heldobject.w / 2) + 0.5),
      math.floor((mouse.y - board.y) / board.scale - (mouse.heldobject.h / 2) + 0.5)
  end
end
