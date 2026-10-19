-- lib/anim.lua
-- Animaciones: usa rubato (https://github.com/andOrlando/rubato) y, si rubato no carga o no
-- anima, cae a un motor propio con la MISMA curva (cuadrática in/out), así las animaciones
-- nunca desaparecen. Lo que pasó se anota en  ~/.cache/awesome-anim.log
--
-- Uso:
--   local a = anim.new {
--     duration  = 0.35,
--     pos       = 0,
--     on_update = function(p) ... end,   -- p va de pos al destino (0..1 o el rango que uses)
--   }
--   a:set(1)      -- anima hacia 1
--   a:snap(0)     -- salta sin animar

local gears = require("gears")
local glib  = require("lgi").GLib

local M = {}

-- ---------- log ----------
local LOG_DIR = (os.getenv("HOME") or "") .. "/.cache"
pcall(gears.filesystem.make_directories, LOG_DIR)   -- ~/.cache puede no existir
local LOG = LOG_DIR .. "/awesome-anim.log"
local function log(msg)
  local f = io.open(LOG, "a")
  if f then f:write(os.date("%H:%M:%S  ") .. msg .. "\n"); f:close() end
end
do local f = io.open(LOG, "w"); if f then f:close() end end

-- ---------- buscar rubato ----------
-- Prueba varias rutas (lib/rubato/init.lua, lib/rubato/rubato/init.lua, ...) y apunta los errores
local rubato, errors = nil, {}
for _, name in ipairs {
  "lib.rubato", "lib.rubato.init", "lib.rubato.rubato", "rubato", "modules.rubato", "utils.rubato",
} do
  local ok, mod = pcall(require, name)
  if ok and type(mod) == "table" and mod.timed then
    rubato = mod
    log("rubato cargado con require('" .. name .. "')")
    break
  else
    errors[#errors + 1] = name .. " -> " .. tostring(ok and "no tiene .timed" or mod):sub(1, 160)
  end
end
if not rubato then
  log("rubato NO se pudo cargar; se usa el motor propio. Intentos:")
  for _, e in ipairs(errors) do log("   " .. e) end
end

M.available = true          -- siempre hay animación (rubato o motor propio)
M.rubato    = rubato ~= nil

-- ---------- motor propio ----------
local function now() return glib.get_monotonic_time() / 1e6 end
local function ease(t)       -- cuadrática in/out, como el easing por defecto de rubato
  if t < 0.5 then return 2 * t * t end
  return 1 - 2 * (1 - t) * (1 - t)
end

local force_builtin = false

function M.new(o)
  local self = {
    pos    = o.pos or 0,
    target = o.pos or 0,
    fires  = 0,
  }
  local duration = o.duration or 0.3

  local function fire(p)
    self.pos   = p
    self.fires = self.fires + 1
    if o.on_update then o.on_update(p) end
  end

  -- ----- motor propio -----
  local timer
  local function stop_builtin()
    if timer then timer:stop(); timer = nil end
  end
  local function run_builtin(target)
    stop_builtin()
    local from, t0 = self.pos, now()
    if from == target or duration <= 0 then fire(target); return end
    timer = gears.timer {
      timeout   = 1 / (o.rate or 60),
      autostart = true,
      callback  = function()
        local k = math.min(1, (now() - t0) / duration)
        fire(from + (target - from) * ease(k))
        if k >= 1 then stop_builtin(); return false end
      end,
    }
  end

  -- ----- rubato -----
  if rubato and not force_builtin then
    local args = {
      duration    = duration,
      pos         = self.pos,
      rate        = o.rate or 60,
      override_dt = o.override_dt ~= false,   -- igual que AlphaTechnolog/dotfiles
      subscribed  = fire,
    }
    if o.intro then args.intro = o.intro end
    if o.outro then args.outro = o.outro end
    local ok, t = pcall(rubato.timed, args)
    if ok then
      self.timed = t
    else
      log("rubato.timed falló (" .. tostring(t):sub(1, 160) .. "); motor propio para esta animación")
    end
  end

  function self:running()
    if self.timed then return self.timed.running or false end
    return timer ~= nil
  end

  function self:set(target)
    self.target = target
    if self.timed and not force_builtin then
      local before = self.fires
      self.timed.target = target
      -- vigilante: si rubato no dispara ni un frame, se cambia al motor propio
      if target ~= self.pos then
        gears.timer.start_new(math.max(0.25, duration * 0.5), function()
          if self.fires == before and self.pos ~= target then
            force_builtin = true
            log("rubato no animó (0 frames); se cambia al motor propio. ¿falta el parche math.floor en timed.lua?")
            self.timed = nil
            run_builtin(target)
          end
          return false
        end)
      end
    else
      run_builtin(target)
    end
  end

  -- Salta sin animar (útil al inicializar)
  function self:snap(value)
    self.target = value
    stop_builtin()
    if self.timed then
      pcall(function()
        self.timed.target = value
        self.timed.pos    = value
      end)
    end
    fire(value)
  end

  return self
end

return M
