-- noglobals.lua
-- no globals allowed
-- stops globals from being created, but not from being used once created
-- so you can call this after all your globals are initialized and be fine

local mt = getmetatable(_G)

if not mt then
  mt = {}
  setmetatable(_G, mt)
end

mt.__newindex = function(self, key, value)
  if _ALLOWGLOBALS then
    rawset(self, key, value)
  elseif key == '_' then
    rawset(self, key, value)
  else
    error('No Globals is in effect', 2)
  end
end
