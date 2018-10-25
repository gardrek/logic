local Vector = require('Vector')

local Color = {
  Blue        = Vector:new{0x55, 0x55, 0xdd},
  Green       = Vector:new{0x55, 0xdd, 0x55},
  Red         = Vector:new{0xdd, 0x55, 0x55},
  Cyan        = Vector:new{0x55, 0xdd, 0xdd},
  Magenta     = Vector:new{0xdd, 0xdd, 0x55},
  Yellow      = Vector:new{0xdd, 0xdd, 0x55},
  LightGrey   = Vector:new{0xdd, 0xdd, 0xdd},
  Grey        = Vector:new{0x99, 0x99, 0x99},
  FullWhite   = Vector:new{0xff, 0xff, 0xff},
  Black       = Vector:new{0x00, 0x00, 0x00},
  BrightCyan  = Vector:new{0x00, 0xff, 0xff},
}

Color.BasicGate    = Color.Yellow
Color.BasicSensor  = Color.Green
Color.Fallback     = Color.Cyan
Color.boardBG      = Vector:new{0x00, 0x33, 0x11}--Vector:new{0x00, 0xdd, 0x55} / 5
Color.BG           = Vector:new{0x66, 0x77, 0x88}

function Color:random()
  local c = Vector:new{0x55, 0x55, 0x55}
  for i = 1, 3 do
    c[i] = c[i] + love.math.random(0,2) * 0x44--0x55 + love.math.random(0,1) * 0x33
  end
  --c[love.math.random(1,3)] = love.math.random(0,3) * 0x11 + 0xaa
  --c[love.math.random(1,3)] = love.math.random(0,3) * 0x11 + 0xaa
  --c[love.math.random(1,3)] = love.math.random(0,3) * 0x11 + 0xaa
  --c = self[love.math.random(1, #self)]:dup()
  return c / 0xff
end

for index, color in pairs(Color) do
  if type(color) == 'table' then
    Color[index] = color:dup() / 0xff
  end
end

return Color
