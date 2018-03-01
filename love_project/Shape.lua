require('noglobals')

local Shape = {}
Shape.__index = Shape

function Shape:draw1(cam)
  local drawx, drawy = cam:project(self.x, self.y)
  local scale = self.scale * cam.zoom
  local colors = {}
  colors[1] = self.color or Color.Fallback
  colors[2] = color / 3
  colors[3] = darkColor * 2
  local lineWidth = scale / 32
  local lineJoinStyle = 'miter'
  Shape:draw(obj, drawx, drawy, scale, colors, lineWidth, lineJoinStyle)
  --??? why am i doing this, what does it mean?
end

function Shape:draw(obj, drawx, drawy, scale, colors, lineWidth, lineJoinStyle)
  love.graphics.setColor(colors[3])
  love.graphics.setLineWidth(lineWidth)
  love.graphics.setLineJoin(lineJoinStyle)

  local padding = lineWidth

  love.graphics.rectangle(
    'fill', drawx + 2 * padding, drawy + 2 * padding,
    obj.w * scale - 4 * padding, obj.h * scale - 4 * padding
  )

  love.graphics.setColor(colors[2])
  love.graphics.rectangle(
    'line', drawx + 2 * padding, drawy + 2 * padding,
    obj.w * scale - 4 * padding, obj.h * scale - 4 * padding
  )

  love.graphics.setColor(colors[1])
  if scale >= 32 or SHOW_DEBUG_TEXT then
    love.graphics.print(obj.name, drawx + 3 * padding, drawy + 3 * padding)
  end
end


return Shape
