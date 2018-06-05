local Collider = require 'Collider'
local Vector = require 'Vector'
local Color = require 'Color'

local function class_assert(obj, class)
  local t = type(obj)
  if (t == 'table' and obj.class ~= class) or t ~= class then
    error('class_assert failed', 2)
  end
end

local Menu = {}
Menu.__index = Menu
Menu.class = 'Menu'

Menu.default = {
  width = 160,
  itemheight = 20,
  color = Color.Yellow
}

function Menu:new(v, items, params)
  params = params or {}
  local menu = {
    x = v[1],
    y = v[2],
  }
  for k, v in pairs(Menu.default) do
    menu[k] = params[k] or v
  end
  menu.items = {}
  for i, v in ipairs(items) do
    menu.items[i] = {
      name = v.name,
      action = v.action,
      collider = Collider:rect{
        menu.x,
        menu.y + (i - 1) * menu.itemheight,
        menu.width,
        menu.itemheight,
      },
    }
  end
  setmetatable(menu, Menu)
  return menu
end

function Menu:draw(cam)
  local drawx, drawy = self.x, self.y--cam:project(self.x, self.y)
  local scale = 1 --cam.zoom
  love.graphics.setLineWidth(2)
  love.graphics.setLineJoin('miter')

  local padding = 2
  local color = self.color or Color.Fallback
  local darkColor = color / 3
  local mediumColor = darkColor * 2
  local selectedColor = color

  love.graphics.setColor(darkColor)
  love.graphics.rectangle(
    'fill', self.x - 2 * padding, self.y - 2 * padding,
    self.width + 4 * padding, self.itemheight * #self.items + 4 * padding
  )

  love.graphics.setColor(color)
  love.graphics.rectangle(
    'line', self.x - 2 * padding, self.y - 2 * padding,
    self.width + 4 * padding, self.itemheight * #self.items + 4 * padding
  )

  for i, v in ipairs(self.items) do

    local col = v.collider
    if col.hit then
      love.graphics.setColor(mediumColor)
      love.graphics.rectangle(
        'fill', self.x, self.y + (i - 1) * self.itemheight,
        self.width, self.itemheight
      )
      love.graphics.setColor(Color.FullWhite)
    else
      love.graphics.setColor(color)
    end

    love.graphics.print(v.name, self.x, self.y + self.itemheight * (i - 1))
  end
end

return Menu
