local Vector = require('Vector')

local Color = {
  Blue = Vector:new{0x55, 0x55, 0xdd},
  Green = Vector:new{0x55, 0xdd, 0x55},
  Red = Vector:new{0xdd, 0x55, 0x55},
  Cyan = Vector:new{0x55, 0xdd, 0xdd},
  Magenta = Vector:new{0xdd, 0xdd, 0x55},
  Yellow = Vector:new{0xdd, 0xdd, 0x55},
  FullWhite = Vector:new{0xff, 0xff, 0xff},
  Black = Vector:new{0x0, 0x0, 0x0},
  BrightCyan = Vector:new{0x00, 0xff, 0xff},
}

Color.BasicGate = Color.Yellow
Color.BasicSensor = Color.Green
Color.Fallback = Color.Cyan
Color.boardBG = Vector:new{0x11, 0x22, 0x11}
Color.BG = Vector:new{0x22, 0x22, 0x22}

function Color:random()
  local c = Vector:new{0x55, 0x55, 0x55}
  c[love.math.random(1,3)] = love.math.random(0,3) * 0x11 + 0x99
  c[love.math.random(1,3)] = love.math.random(0,3) * 0x11 + 0x99
  --c = self[love.math.random(1, #self)]:dup()
  return c
end

return Color
