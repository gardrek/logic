local Value = require 'Value'
local Color = require 'Color'

return function(Logic)
  return {
    Joypad = {
      displayName = 'Joypad',
      w = 2, h = 6,
      color = Color.BasicSensor,
      inputs = 0, outputs = 6,
      outputNames = {'joyX', 'joyY', 'a', 'b', 'c', 'start'},
      update = function(self)
        for index, name in ipairs{false, false, 'z', 'x', 'c', 'return'} do
          if name then
            self.output[index]:setvoltage(
              love.keyboard.isDown(name) and 1.0 or 0.0
            )
            --if love.keyboard.isDown(name) then
              --self.output[index]:setvoltage(1.0)
            --else
              --self.output[index]:setvoltage(0.0)
            --end
          end
        end
        local v = 0
        if love.keyboard.isDown('left') then v = v - 1.0 end
        if love.keyboard.isDown('right') then v = v + 1.0 end
        self.output[1]:setvoltage(v)
        v = 0
        if love.keyboard.isDown('down') then v = v - 1.0 end
        if love.keyboard.isDown('up') then v = v + 1.0 end
        self.output[2]:setvoltage(v)
      end,
    },
    Mouse = {
      displayName = 'Mouse',
      w =2, h = 5,
      color = Color.BasicSensor,
      inputs = 0,
      outputs = 5,
      outputNames = {'x', 'y', 'left', 'right', 'middle'},
      --[[
      init = function(self)
        local c
        for i = 1, 5 do
          c = vector:new{0x55, 0x55, 0x55}
          c[love.math.random(1,3)] = love.math.random(0,3) * 0x11 + 0x88
          c[love.math.random(1,3)] = love.math.random(0,3) * 0x11 + 0x88
          self.output[i]:setColor(c)
        end
      end,--]]
      update = function(self)
        local x, y = love.mouse.getPosition()
        local w, h = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
        --if love.mouse.isDown(1) then
          self.output[1]:setvoltage(Value.clamp((x - w) / w))
          self.output[2]:setvoltage(Value.clamp((y - h) / h))
        --end
        self.output[3]:setvoltage(love.mouse.isDown(1) and 1 or 0)
        self.output[4]:setvoltage(love.mouse.isDown(2) and 1 or 0)
        self.output[5]:setvoltage(love.mouse.isDown(3) and 1 or 0)
      end,
    },

    Random = {
      displayName = 'Random',
      w = 2, h = 1,
      color = Color.BasicSensor,
      inputs = 0, outputs = 1,
      update = function(self)
        self.output[1]:setvoltage(love.math.random())
      end,
    },

    Truth = {
      displayName = 'True',
      w = 1, h = 1,
      color = Color.BasicGate,
      inputs = 1,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local node = self.default
        if self.input[1].link then
          node = self.input[1].link.val
        end
        self.color = node.color
        self.output[1]:set(node)
        local voltage = self.output[1]:getvoltage()
        if voltage == 1.0 or voltage == -1.0 then
          self.output[1]:setvoltage(1.0)
        else
          self.output[1]:setvoltage(0.0)
        end
      end,
      ---[[
      --Truth
      draw = function(self, cam)
        local drawx, drawy = cam:project(self.x, self.y)
        local scale = self.scale * cam.zoom
        local color = self.color or Color.Fallback
        local darkColor = {color[1] / 3, color[2] / 3, color[3] / 3}
        local mediumColor = {color[1] / 3 * 2, color[2] / 3 * 2, color[3] / 3 * 2}
        local padding = scale / 32

        love.graphics.setColor(darkColor)
        love.graphics.setLineWidth(padding)
        love.graphics.rectangle(
          'fill', drawx + 2 * padding, drawy + 2 * padding,
          self.w * scale - 4 * padding, self.h * scale - 4 * padding
        )

        love.graphics.setColor(mediumColor)
        love.graphics.rectangle(
          'line', drawx + 2 * padding, drawy + 2 * padding,
          self.w * scale - 4 * padding, self.h * scale - 4 * padding
        )

        local node
        if self.input[1].link then
          node = self.input[1].link.val
        else
          node = self.default
        end

        Logic.drawTruthSymbol(node,
          drawx + self.w * scale / 2, drawy + self.h * scale / 2,
          scale, self.w * 0.5, self.color
        )
      end,--]]
    },

    AND = {
      displayName = 'AND',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 2,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        local val
        local node
        local maxval = 1.0
        for _, input in ipairs(self.input) do
          if input.link then
            val = math.abs(input.link.val:getvoltage())
            node = input.link.val
          else
            val = math.abs(self.default:getvoltage())
            node = self.default
          end
          if val <= maxval then
            passthru = node
            maxval = val
          end
        end
        self.output[1]:set(passthru)
      end,
    },

    OR = {
      displayName = 'OR',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 2,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        local val
        local node
        local maxval = 0.0
        for _, input in ipairs(self.input) do
          if input.link then
            val = math.abs(input.link.val:getvoltage())
            node = input.link.val
          else
            val = math.abs(self.default:getvoltage())
            node = self.default
          end
          if val >= maxval then
            passthru = node
            maxval = val
          end
        end
        self.output[1]:set(passthru)
      end,
    },

    -- TODO: XOR

    NOT = {
      displayName = 'NOT',
      w = 1, h = 1,
      color = Color.BasicGate,
      inputs = 1,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        if self.input[1].link then
          passthru = self.input[1].link.val
        end
        self.color = passthru.color
        self.output[1]:set(passthru)
        local voltage = self.output[1]:getvoltage()
        self.output[1]:setvoltage((voltage < 0.0 and -1.0 or 1.0) - voltage)
        --self.output[1]:setvoltage(voltage == 0.0 and 1.0 or 0.0)
        --self.output[1]:setvoltage(math.abs(voltage) == 1.0 and 0.0 or 1.0)
      end,
      ---[[
      draw = function(self, cam)
        local drawx, drawy = cam:project(self.x, self.y)
        local scale = self.scale * cam.zoom
        local color = self.color or Color.Fallback
        local darkColor = color / 3
        local mediumColor = darkColor * 2
        local padding = scale / 32
        local shape = {
          drawx + 2 * padding, drawy + 2 * padding,
          drawx + self.w * scale - 6 * padding, drawy + self.h * scale / 2,
          drawx + 2 * padding, drawy + self.h * scale - 2 * padding,
        }

        love.graphics.setColor(darkColor)
        love.graphics.setLineWidth(padding * 2)
        love.graphics.setLineJoin('miter')
        love.graphics.polygon('fill', shape)

        love.graphics.setColor(mediumColor)
        love.graphics.polygon('line', shape)

        love.graphics.setColor(darkColor)
        love.graphics.circle('fill', drawx + self.w * scale - 6 * padding, drawy + self.h * scale / 2, padding * 5)

        love.graphics.setColor(mediumColor)
        love.graphics.circle('line', drawx + self.w * scale - 6 * padding, drawy + self.h * scale / 2, padding * 5)
      end,--]]
    },

    ABS = {
      displayName = 'Abs',
      w = 1, h = 1,
      color = Color.BasicGate,
      inputs = 1,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local node = self.default
        if self.input[1].link then
          node = self.input[1].link.val
        end
        self.color = node.color
        self.output[1]:set(node)
        local voltage = self.output[1]:getvoltage()
        self.output[1]:setvoltage(math.abs(voltage))
      end,
    },

    Sign = {
      displayName = 'Sign',
      w = 1, h = 1,
      color = Color.BasicGate,
      inputs = 1,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local node = self.default
        if self.input[1].link then
          node = self.input[1].link.val
        end
        self.color = node.color
        self.output[1]:set(node)
        local voltage = self.output[1]:getvoltage()
        if voltage > 0.0 then
          self.output[1]:setvoltage(1.0)
        elseif voltage < 0.0 then
          self.output[1]:setvoltage(-1.0)
        else
          self.output[1]:setvoltage(0.0)
        end
      end,
      ---[[
      draw = function(self, cam)
        local drawx, drawy = cam:project(self.x, self.y)
        local scale = self.scale * cam.zoom
        local color = self.color or Color.Fallback
        local darkColor = {color[1] / 3, color[2] / 3, color[3] / 3}
        local mediumColor = {color[1] / 3 * 2, color[2] / 3 * 2, color[3] / 3 * 2}
        local padding = scale / 32

        love.graphics.setColor(darkColor)
        love.graphics.setLineWidth(padding)
        love.graphics.rectangle(
          'fill', drawx + 2 * padding, drawy + 2 * padding,
          self.w * scale - 4 * padding, self.h * scale - 4 * padding
        )

        love.graphics.setColor(mediumColor)
        love.graphics.rectangle(
          'line', drawx + 2 * padding, drawy + 2 * padding,
          self.w * scale - 4 * padding, self.h * scale - 4 * padding
        )

        local node
        if self.input[1].link then
          node = self.input[1].link.val
        else
          node = self.default
        end

        Logic.drawSignSymbol(node,
          drawx + self.w * scale / 2, drawy + self.h * scale / 2,
          scale, self.w * 0.5, self.color
        )
      end,--]]
    },

    PassThru = {
      displayName = 'PassThru',
      w = 1, h = 1,
      color = Color.BasicGate,
      inputs = 1,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
        self.visual = Value:new()
      end,
      update = function(self)
        local node
        if self.input[1].link then
          node = self.input[1].link.val
        else
          node = self.default
        end
        self.color = node.color or Color.BasicGate
        self.output[1]:set(node)
      end,
      --drawOutputNodes = function() end,
      --drawInputNodes = function() end,
      ---[[
      draw = function(self, cam)
        local drawx, drawy = cam:project(self.x, self.y)
        local scale = self.scale * cam.zoom
        self.visual:set(self.output[1])
        self.visual:setvoltage(1.0)
        self.visual:drawIONode('arrow',
          drawx + (self.w / 2) * scale,
          drawy + (self.h / 2) * scale,
          scale * self.w * 2.25
        )
      end,--]]
    },

    Colorize = {
      displayName = 'Dye',
      w = 1, h = 1,
      color = Color.BasicGate,
      inputs = 1,
      outputs = 1,
      init = function(self)
        self:setColor(Color:random())
      end,
      update = function(self)
        local node
        if self.input[1].link then
          node = self.input[1].link.val
        else
          node = self.input[1].default
        end
        --self.color = node.color or Color.BasicGate
        self.output[1]:set(node)
        self.output[1]:setColor(self.color)
      end,
    },

    AVG = {
      displayName = 'Average',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 2,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        local val = 0
        local count = 0
        local color
        self.output[1]:set(self.default)
        if #self.input == 0 then return end
        for _, input in ipairs(self.input) do
          if input.link then
            val = val + input.link.val:getvoltage()
            color = input.link.val.color
          end
          count = count + 1
        end
        if count == 0 then
          self.output[1]:set(self.default)
        else
          self.output[1]:set{
            voltage = val / count,
            color = color,
          }
        end
      end,
    },

    Add = {
      displayName = 'Add',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 2,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        local val = 0
        local color = self.default.color
        self.output[1]:set(self.default)
        if #self.input == 0 then return end
        for _, input in ipairs(self.input) do
          if input.link then
            val = val + input.link.val:getvoltage()
            color = input.link.val.color
          end
        end
        self.output[1]:set{
          voltage = Value.clamp(val),
          color = color,
        }
      end,
    },

    Sub = {
      displayName = 'Subtract',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 2,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        local val = 0
        local color = self.default.color
        local sign = 1
        self.output[1]:set(self.default)
        if #self.input == 0 then return end
        for _, input in ipairs(self.input) do
          if input.link then
            -- FIXME: Figure out how to generalize subtract to more than two
            -- inputs, or limit it to two inputs
            val = val + input.link.val:getvoltage() * sign
            color = input.link.val.color
          end
          sign = -sign
        end
        self.output[1]:set{
          voltage = Value.clamp(val),
          color = color,
        }
      end,
    },

    Negate = {
      displayName = 'Neg',
      w = 1, h = 1,
      color = Color.BasicGate,
      inputs = 1,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local node = self.default
        if self.input[1].link then
          node = self.input[1].link.val
        end
        self.color = node.color
        self.output[1]:set(node)
        self.output[1]:setvoltage(-self.output[1]:getvoltage())
      end,
    },

    SignSplit = {
      displayName = 'SignSplit',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 1,
      outputs = 2,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        if self.input[1].link then
          passthru = self.input[1].link.val
        end
        self.output[1]:set(passthru)
        self.output[2]:set(passthru)
        local voltage = passthru:getvoltage()
        if voltage >= 0 then
          self.output[1]:setvoltage(voltage)
          self.output[2]:setvoltage(0)
        else
          self.output[1]:setvoltage(0)
          self.output[2]:setvoltage(-voltage)
        end
      end,
    },

    LED = {
      displayName = 'LED',
      w = 1, h = 1,
      color = Color.Grey,
      inputs = 1,
      update = function(self)
        local node
        -- might not need to check number of inputs?
        -- might want to instead enforce number elsewhere
        if self.input[1] and self.input[1].link then
          node = self.input[1].link.comp.output[self.input[1].link.index]
        else
          node = self.input[1].default
        end
        self.color = --[[self.colorOverride or ]]node.color
      end,
      ---[[
      draw = function(self, cam)
        local drawx, drawy = cam:project(self.x, self.y)
        local scale = self.scale * cam.zoom
        local radius = self.w * scale / 2
        local drawx, drawy = drawx + radius, drawy + radius
        local brightness = 0
        local node
        if self.input[1] and self.input[1].link then
          node = self.input[1].link.val
        else
          node = self.input[1].default
        end

        brightness = math.abs(node:getvoltage())
        love.graphics.setColor(node.color * brightness)
        love.graphics.circle('fill', drawx, drawy, radius)

        love.graphics.setColor(node.color)
        love.graphics.setLineWidth(scale / 32)
        love.graphics.circle('line', drawx, drawy, radius)

        if SHOW_DEBUG_TEXT then
          love.graphics.setColor(node.color)
          love.graphics.print(tostring(node), drawx, drawy + radius)
        end
      end,--]]
    },

    ProgBar = {
      displayName = 'ProgBar',
      w = 2, h = 1,
      color = Color.Grey,
      inputs = 1,
      update = function(self)
        local node
        if self.input[1] and self.input[1].link then
          node = self.input[1].link.val
        else
          node = self.input[1].default
        end
        self.color = node.color
      end,
      ---[[
      draw = function(self, cam)
        local drawx, drawy = cam:project(self.x, self.y)
        local scale = self.scale * cam.zoom
        local node
        if self.input[1] and self.input[1].link then
          node = self.input[1].link.comp.output[self.input[1].link.index]
        else
          node = self.input[1].default
        end
        local length = node:getvoltage()
        local padding = scale / 32
        love.graphics.setColor(Color.Black)
        love.graphics.rectangle(
          'fill', drawx + 2 * padding, drawy + 2 * padding,
          self.w * scale - 4 * padding, self.h * scale - 4 * padding
        )
        love.graphics.setColor(node.color)
        love.graphics.setLineWidth(padding)
        love.graphics.rectangle(
          'line', drawx + 2 * padding, drawy + 2 * padding,
          self.w * scale - 4 * padding, self.h * scale - 4 * padding
        )
        love.graphics.rectangle(
          'fill',
          drawx + 5 * padding,
          drawy + 5 * padding,
          (self.w * scale - 10 * padding) * math.abs(length),
          self.h * scale - 10 * padding
        )
      end,--]]
    },

    NegProgBar = {
      displayName = 'NegProgBar',
      w = 2, h = 1,
      color = Color.Grey,
      inputs = 1,
      update = function(self)
        local node
        if self.input[1] and self.input[1].link then
          node = self.input[1].link.val
        else
          node = self.input[1].default
        end
        self.color = node.color
      end,
      ---[[
      draw = function(self, cam)
        local drawx, drawy = cam:project(self.x, self.y)
        local scale = self.scale * cam.zoom
        local node
        if self.input[1] and self.input[1].link then
          node = self.input[1].link.comp.output[self.input[1].link.index]
        else
          node = self.input[1].default
        end
        local length = node:getvoltage() / 2
        local padding = scale / 32
        love.graphics.setColor(Color.Black)
        love.graphics.rectangle(
          'fill', drawx + 2 * padding, drawy + 2 * padding,
          self.w * scale - 4 * padding, self.h * scale - 4 * padding
        )
        love.graphics.setColor(node.color)
        love.graphics.setLineWidth(padding)
        love.graphics.rectangle(
          'line', drawx + 2 * padding, drawy + 2 * padding,
          self.w * scale - 4 * padding, self.h * scale - 4 * padding
        )
        love.graphics.rectangle(
          'fill',
          drawx + scale / self.w * 2,
          drawy + 5 * padding,
          (self.w * scale - 10 * padding) * length,
          self.h * scale - 10 * padding
        )
      end,--]]
    },
    Multimeter = {
      displayName = 'Multimeter',
      w = 2, h = 2,
      color = Color.Grey,
      inputs = 1,
      update = function(self)
        local node
        if self.input[1] and self.input[1].link then
          node = self.input[1].link.val
        else
          node = self.input[1].default
        end
        self.color = node.color
      end,
      ---[[
      draw = function(self, cam)
        local drawx, drawy = cam:project(self.x, self.y)
        local scale = self.scale * cam.zoom
        local node
        if self.input[1] and self.input[1].link then
          node = self.input[1].link.comp.output[self.input[1].link.index]
        else
          node = self.input[1].default
        end
        local length = node:getvoltage()
        local padding = scale / 32
        love.graphics.setColor(Color.Black)
        love.graphics.rectangle(
          'fill', drawx + 2 * padding, drawy + 2 * padding,
          self.w * scale - 4 * padding, self.h * scale - 4 * padding
        )
        love.graphics.setColor(node.color)
        love.graphics.setLineWidth(padding)
        love.graphics.rectangle(
          'line', drawx + 2 * padding, drawy + 2 * padding,
          self.w * scale - 4 * padding, self.h * scale - 4 * padding
        )

        Logic.drawSignSymbol(node,
          drawx + (self.w / 4) * scale, drawy + (self.h / 4) * scale,
          scale, self.h / 4, node.color
        )

        Logic.drawTruthSymbol(node,
          drawx + scale, drawy + scale * 3 / 4,
          scale / 4, self.w * 0.5, node.color
        )

        local brightness = math.abs(node:getvoltage())
        love.graphics.setColor(node.color * brightness)
        love.graphics.circle('fill',
          drawx + (self.w * 3 / 4) * scale, drawy + (self.h / 4) * scale,
          self.h / 8 * scale
        )

        love.graphics.setColor(node.color)
        love.graphics.setLineWidth(padding * 2)
        love.graphics.circle('line',
          drawx + (self.w * 3 / 4) * scale, drawy + (self.h / 4) * scale,
          self.h / 8 * scale
        )

        love.graphics.rectangle(
          'fill',
          drawx + 5 * padding,
          drawy + (self.h / 2) * scale + 5 * padding,
          (self.w * scale - 10 * padding) * math.abs(length),
          (self.h / 2) * scale - 10 * padding
        )

        love.graphics.setLineWidth(padding)
        local lineX, lineY
        for i = 0, 2 do
          lineX, lineY = 
            drawx + (self.w * scale - 10 * padding) / 2 * i + 5 * padding,
            drawy + (self.h / 2) * scale + 4 * padding
          love.graphics.line(
            lineX, lineY,
            lineX, lineY - 5 * padding
          )
          if i < 2 then
          lineX, lineY = 
            drawx + (self.w * scale - 10 * padding) / 2 * i + 2.5 * padding + (self.w * scale) / 4,
            drawy + (self.h / 2) * scale + 4 * padding
            love.graphics.line(
              lineX, lineY,
              lineX, lineY - 3 * padding
            )
          end
        end
      end,--]]
    },


    NAND = {
      displayName = 'NAND',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 2,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        local val
        local node
        local maxval = 1.0
        for _, input in ipairs(self.input) do
          node = input.link and input.link.val or self.default
          val = math.abs(node:getvoltage())
          if val <= maxval then
            passthru = node
            maxval = val
          end
        end
        self.output[1]:set(passthru)
        self.output[1]:setvoltage(1 - math.abs(passthru:getvoltage()))
      end,
    },

    Clock = {
      displayName = 'CLK',
      w = 2, h = 1,
      color = Color.BasicSensor,
      inputs = 0, outputs = 1,
      init = function(self)
        self._start_time = love.timer.getTime()
        self._period = 1
        self._on_period = self._period / 2
      end,
      update = function(self)
        local now = love.timer.getTime()
        local t = now - self._start_time
        self.output[1]:setvoltage(
          t % self._period < self._on_period and 1 or 0
        )
      end,
    },

    GT = {
      displayName = '>',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 2,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        local input
        local node
        local inputA, inputB

        input = self.input[1]
        inputA = input.link and input.link.val:getvoltage() or 1
        input = self.input[2]
        inputB = input.link and input.link.val:getvoltage() or 0

        self.output[1]:set(passthru)
        self.output[1]:setvoltage(inputA > inputB and 1 or 0)
      end,
    },

    GE = {
      displayName = '>=',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 2,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        local input
        local node
        local inputA, inputB

        input = self.input[1]
        inputA = input.link and input.link.val:getvoltage() or 0
        input = self.input[2]
        inputB = input.link and input.link.val:getvoltage() or 0

        self.output[1]:set(passthru)
        self.output[1]:setvoltage(inputA >= inputB and 1 or 0)
      end,
    },

    LT = {
      displayName = '<',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 2,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        local input
        local node
        local inputA, inputB

        input = self.input[1]
        inputA = input.link and input.link.val:getvoltage() or 0
        input = self.input[2]
        inputB = input.link and input.link.val:getvoltage() or 0

        self.output[1]:set(passthru)
        self.output[1]:setvoltage(inputA < inputB and 1 or 0)
      end,
    },

    LE = {
      displayName = '<=',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 2,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        local input
        local node
        local inputA, inputB

        input = self.input[1]
        inputA = input.link and input.link.val:getvoltage() or 0
        input = self.input[2]
        inputB = input.link and input.link.val:getvoltage() or 0

        self.output[1]:set(passthru)
        self.output[1]:setvoltage(inputA <= inputB and 1 or 0)
      end,
    },

    SUB_LE = {
      displayName = 'SUB_LE',
      w = 2, h = 2,
      color = Color.BasicGate,
      inputs = 2,
      outputs = 1,
      init = function(self)
        self.default = Value:new{color = self.color}
      end,
      update = function(self)
        local passthru = self.default
        local input
        local node
        local inputA, inputB

        input = self.input[1]
        inputA = input.link and input.link.val:getvoltage() or 0
        input = self.input[2]
        inputB = input.link and input.link.val:getvoltage() or 0

        self.output[1]:set(passthru)
        self.output[1]:setvoltage(math.abs(inputA) <= math.abs(inputB) and Value.clamp(inputA - inputB) or Value.clamp(1 - inputA))
      end,
    },
  }
end
