-- lib/anim.lua
-- Envoltorio fino sobre rubato (https://github.com/andOrlando/rubato).
--
-- Busca rubato en varias rutas comunes. Si no lo encuentra, NO rompe nada:
-- las animaciones pasan a ser instantáneas (el valor salta directo al final).
--
-- Uso:
--   local a = anim.new {
--     duration  = 0.35,
--     pos       = 0,
--     on_update = function(p) ... end,   -- p va de 0 a 1 (o el rango que uses)
--   }
--   a:set(1)   -- anima hacia 1
--   a:set(0)   -- anima hacia 0

local M = {}

local rubato
for _, name in ipairs { "lib.rubato", "rubato", "modules.rubato", "utils.rubato" } do
  local ok, mod = pcall(require, name)
  if ok and type(mod) == "table" and mod.timed then
    rubato = mod
    break
  end
end

M.available = rubato ~= nil

function M.new(o)
  local self = {
    pos    = o.pos or 0,
    target = o.pos or 0,
  }

  local function fire(p)
    self.pos = p
    if o.on_update then o.on_update(p) end
  end

  if rubato then
    local args = {
      duration   = o.duration or 0.3,
      pos        = self.pos,
      rate       = o.rate or 60,
      override_dt = o.override_dt ~= false,   -- igual que AlphaTechnolog/dotfiles
      subscribed = fire,
    }
    if o.intro  then args.intro  = o.intro  end
    if o.outro  then args.outro  = o.outro  end
    self.timed = rubato.timed(args)
  end

  function self:running()
    return self.timed and self.timed.running or false
  end

  function self:set(target)
    self.target = target
    if self.timed then
      self.timed.target = target
    else
      fire(target)
    end
  end

  -- Salta sin animar (útil al inicializar)
  function self:snap(value)
    self.target = value
    if self.timed then
      pcall(function()
        self.timed.target = value
        self.timed.pos = value
      end)
    end
    fire(value)
  end

  return self
end

return M
