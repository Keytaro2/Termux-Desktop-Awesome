-- lib/ui.lua
-- Helpers compartidos por bar, dashboard1 y notifications.
-- Aquí viven la paleta (los mismos colores de los .yuck) y utilidades
-- para que los tamaños en px sean idénticos a los de eww.

local awful     = require("awful")
local gears     = require("gears")
local wibox     = require("wibox")
local xresources = require("beautiful.xresources")
local cairo     = require("lgi").cairo

local M = {}

-- =========================================
-- PALETA (copiada de los .yuck)
-- =========================================
M.c = {
  bg      = "#020612fa",  -- rgba(2, 6, 18, 0.98)
  panel   = "#090E20",
  card    = "#111827",
  card2   = "#0c1326",
  border  = "#1a233a",
  btn     = "#292e42",
  btn_bg  = "#1a1b26",
  fg      = "#c0caf5",
  fg2     = "#a9b1d6",
  muted   = "#565f89",
  blue    = "#7aa2f7",
  purple  = "#bb9af7",
  red     = "#f7768e",
  dark    = "#020612",
}

-- Fuente base. Poné acá tu Nerd Font si querés (ej: "JetBrainsMono Nerd Font").
-- Con "Sans", Pango busca solo los glifos de iconos en tus fuentes instaladas.
M.fontname = "Sans"

-- Fuente que piden los .scss/.yuck de date1, menu2, powermenu y screnshoot
M.mono = "JetBrainsMono Nerd Font"

-- Ruta base de la config
M.dir = gears.filesystem.get_configuration_dir()

-- =========================================
-- TIPOGRAFÍA: px (como eww/GTK) -> puntos de Pango
-- =========================================
function M.pt(px)
  local dpi = xresources.get_dpi()
  if not dpi or dpi <= 0 then dpi = 96 end
  return px * 72 / dpi
end

function M.font(px, bold, family)
  return string.format("%s%s %.2f", family or M.fontname, bold and " Bold" or "", M.pt(px))
end

local function markup(text, color)
  return string.format('<span foreground="%s">%s</span>', color, gears.string.xml_escape(tostring(text)))
end

-- Devuelve (widget, setter). setter(texto, color_opcional). Opción box = N (ver abajo).
function M.label(o)
  local w = wibox.widget {
    font      = M.font(o.size or 14, o.bold, o.family),
    halign    = o.halign or "left",
    valign    = o.valign or "center",
    ellipsize = o.ellipsize or "none",
    widget    = wibox.widget.textbox,
  }
  if o.wrap then w.wrap = "word_char" end
  -- box = N: el textbox mide NxN y el glifo va centrado dentro. Los iconos Nerd Font se salen
  -- un poco de su caja de texto y, sin este espacio extra, se recortan.
  if o.box then w.forced_width, w.forced_height = o.box, o.box end
  w._col = o.color or M.c.fg
  w.markup = markup(o.text or "", w._col)
  local function set(txt, col)
    if col then w._col = col end
    w.markup = markup(txt, w._col)
  end
  return w, set
end

-- Trunca a n caracteres (como :limit-width de eww)
function M.limit(text, n)
  text = tostring(text or "")
  local out, count = {}, 0
  for ch in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    count = count + 1
    if count > n then
      out[#out + 1] = "…"
      break
    end
    out[#out + 1] = ch
  end
  return table.concat(out)
end

-- =========================================
-- FORMAS Y CONTENEDORES
-- =========================================
-- Rectángulo redondeado con radio distinto por esquina (tl, tr, br, bl)
function M.rrect(tl, tr, br, bl)
  tr, br, bl = tr or tl, br or tl, bl or tl
  return function(cr, w, h)
    cr:new_sub_path()
    cr:arc(w - tr, tr, tr, -math.pi / 2, 0)
    cr:arc(w - br, h - br, br, 0, math.pi / 2)
    cr:arc(bl, h - bl, bl, math.pi / 2, math.pi)
    cr:arc(tl, tl, tl, math.pi, 3 * math.pi / 2)
    cr:close_path()
  end
end

-- padding = { arriba, derecha, abajo, izquierda }
function M.margin(child, t, r, b, l)
  return wibox.widget {
    child,
    top = t or 0, right = r or 0, bottom = b or 0, left = l or 0,
    widget = wibox.container.margin,
  }
end

-- Caja con fondo/radio/padding. o = { bg, radius = n | {tl,tr,br,bl}, pad = {t,r,b,l},
--   w, h, border, border_color }
function M.box(child, o)
  o = o or {}
  local inner = child
  if o.pad then inner = M.margin(child, o.pad[1], o.pad[2], o.pad[3], o.pad[4]) end
  local shape
  if type(o.radius) == "table" then
    shape = M.rrect(o.radius[1], o.radius[2], o.radius[3], o.radius[4])
  elseif o.radius then
    shape = M.rrect(o.radius)
  end
  return wibox.widget {
    inner,
    bg                 = o.bg,
    shape              = o.shape or shape,
    shape_border_width = o.border,
    shape_border_color = o.border_color,
    forced_width       = o.w,
    forced_height      = o.h,
    widget             = wibox.container.background,
  }
end

function M.center(child)
  return wibox.widget { child, halign = "center", valign = "center", widget = wibox.container.place }
end

-- Hace clickeable un widget. Por defecto pone cursor de mano; con no_hand = true
-- NO toca el cursor (queda el puntero normal), que es lo que usa la barra.
function M.clickable(w, fn, no_hand)
  w:buttons(gears.table.join(awful.button({}, 1, fn)))
  if no_hand then return w end
  w:connect_signal("mouse::enter", function()
    local wb = mouse.current_wibox
    if wb then wb.cursor = "hand1" end
  end)
  w:connect_signal("mouse::leave", function()
    local wb = mouse.current_wibox
    if wb then wb.cursor = "left_ptr" end
  end)
  return w
end

-- =========================================
-- IMÁGENES "background-size: cover"
-- =========================================
function M.cover(path, w, h)
  if not path or path == "" or path == "null" then return nil end
  path = path:gsub("^~", os.getenv("HOME") or "")
  local f = io.open(path, "rb")
  if not f then return nil end
  f:close()
  local ok, img = pcall(gears.surface.load_uncached, path)
  if not ok or not img then return nil end
  local iw, ih = gears.surface.get_size(img)
  if not iw or iw == 0 or ih == 0 then return nil end
  local scale = math.max(w / iw, h / ih)
  local out = cairo.ImageSurface(cairo.Format.ARGB32, w, h)
  local cr = cairo.Context(out)
  cr:translate((w - iw * scale) / 2, (h - ih * scale) / 2)
  cr:scale(scale, scale)
  cr:set_source_surface(img, 0, 0)
  cr:paint()
  return out
end

-- Imagebox con recorte tipo cover. shape: función de forma (circle, rrect...)
function M.image(path, w, h, shape)
  local ib = wibox.widget {
    image         = M.cover(path, w, h),
    resize        = false,
    forced_width  = w,
    forced_height = h,
    clip_shape    = shape,
    widget        = wibox.widget.imagebox,
  }
  function ib.update_path(p)
    ib.image = M.cover(p, w, h)
  end
  return ib
end

-- =========================================
-- SHELL / POLLING
-- =========================================
function M.sh(cmd, cb)
  if cb then
    awful.spawn.easy_async_with_shell(cmd, function(out)
      local s = (out or ""):gsub("^%s+", ""):gsub("%s+$", "")
      cb(s)
    end)
  else
    awful.spawn.with_shell(cmd)
  end
end

-- Timer que ejecuta cmd cada `interval` s y llama cb(salida). Devuelve el timer (start/stop).
function M.poll(cmd, interval, cb)
  return gears.timer {
    timeout   = interval,
    call_now  = true,
    autostart = false,
    callback  = function() M.sh(cmd, cb) end,
  }
end

-- =========================================
-- Llamar módulos opcionales (powermenu, menu2, date1, screnshoot...)
-- Los que todavía no migraste a Lua avisan en vez de romper.
-- =========================================
function M.call(modname, fn, ...)
  local ok, mod = pcall(require, modname)
  if ok and type(mod) == "table" and type(mod[fn]) == "function" then
    return mod[fn](...)
  end
  local msg = ok and ("'" .. modname .. "' no tiene " .. fn .. "()")
                  or ("Módulo '" .. modname .. "' aún no migrado a Lua")
  local nok, notifs = pcall(require, "notifications")
  if nok and notifs.notify then
    -- arriba del popup va el nombre del módulo (como "Screenshot" en
    -- screenshot_ready), no el genérico "Awesome"
    notifs.notify { app = modname, title = "Awesome", body = msg }
  end
end

return M
