-- powermenu/init.lua
-- Port a Lua de powermenu.yuck + powermenu.scss (menú de apagado a pantalla completa).
--
-- yuck: ventana 100% x 100% · avatar circular (assets/pfp.png) · "Hey" + "Keytaro!" ·
--       "What do you want to do?" · 4 botones: poweroff · reboot · logout · cerrar
-- scss: window  -> rgba(0,0,0,.6)          · fuente JetBrainsMono Nerd Font en todo
--       botones -> fondo rgba(26,27,38,.75), hover rgba(36,40,59,.95)
--                  power #f7768e · reboot #e0af68 · logout #bb9af7 · close #7aa2f7
--
-- TAMAÑOS: los del powermenu de AlphaTechnolog/dotfiles (ui/powermenu/init.lua), que son los que
--       el repo escribe en puntos de Pango y con dpi():  avatar 128x128 · saludo 20 pt · subtítulo
--       10 pt · glifos 32 pt dentro de un círculo con margen 2/18 (arriba-abajo / lados) ·
--       separación entre botones 18 · entre bloques 7 (saludo-subtítulo 2) · botones +10 arriba ·
--       margen general 12. Colores, textos, glifos y fondo siguen siendo los tuyos.
--
-- Los 3 primeros botones llaman a  scripts/poweroff.sh {poweroff|reboot|logout}
-- (el mismo script que ya tenías en ~/.config/eww/scripts; migrar.sh lo copia).
-- Si ese script no existe, "logout" cierra Awesome igual.
--
-- Cerrar: botón de la X, o la tecla Escape.
-- Uso:  require("powermenu").toggle()

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local xresources = require("beautiful.xresources")
local cairo = require("lgi").cairo
local ui    = require("lib.ui")
local G     = require("lib.glyph")

local M = {}

local dpi = xresources.apply_dpi

-- puntos de Pango (como  font .. ' 20'  del repo) -> px que espera ui.label
local function pt(n)
  local d = xresources.get_dpi()
  if not d or d <= 0 then d = 96 end
  return n * d / 72
end

local CFG = {
  name     = "Keytaro!",
  overlay  = "#00000066",    -- fondo si NO se puede capturar la pantalla (lo desenfoca picom)
  -- Fondo borroso propio (no depende de picom): se captura la pantalla antes de abrir el menú,
  -- se reduce y se vuelve a estirar (eso la desenfoca) y se oscurece con dim.
  snapshot = true,
  blur_div = 14,             -- más alto = más borroso (la captura se reduce 1/blur_div)
  dim      = 0.30,           -- oscurecido encima del borroso (0 = nada, 1 = negro)
  family   = ui.mono,
  avatar   = 160,            -- dotfiles usa 128; más grande a pedido (círculo de la imagen)
  greet_pt = 20,             -- dotfiles: font_name .. ' 20'
  hey      = "#c0caf5",
  name_c   = "#7aa2f7",
  sub_pt   = 10,             -- dotfiles: theme.font_size = 10
  btn_pt   = 32,             -- dotfiles: nerd_font .. ' 32'
  btn_ratio = 1.5,          -- diámetro del círculo = glifo * 1.5 (igual para los 4 botones)
  btn_m_y  = 2,              -- margen arriba/abajo del glifo (dpi)
  btn_m_x  = 18,             -- margen a los lados del glifo (dpi)
  btn_bg   = "#1a1b26bf",    -- rgba(26, 27, 38, 0.75)
  btn_bg_h = "#24283bf2",    -- rgba(36, 40, 59, 0.95)
  gap      = 18,             -- spacing entre botones (dpi)
  block    = 7,              -- spacing entre avatar / textos / botones (dpi)
  text_gap = 2,              -- spacing entre saludo y subtítulo (dpi)
  btn_top  = 10,             -- margen extra arriba de los botones (dpi)
  pad      = 12,             -- margen general (dpi)
  overlap  = 40 / 37,        -- el -40px de eww a 37px de letra, en "em": se escala con el saludo
}

local SC     = ui.dir .. "scripts/"
local ASSETS = ui.dir .. "assets/"

local win, grabber

local function file_exists(p)
  local f = io.open(p, "r")
  if f then f:close() return true end
  return false
end

local function power(action)
  return function()
    M.hide()
    local script = SC .. "poweroff.sh"
    if file_exists(script) then
      awful.spawn.with_shell("bash " .. script .. " " .. action)
    elseif action == "logout" then
      awesome.quit()
    else
      require("notifications").notify {
        app = "Power", title = "poweroff.sh no encontrado",
        body = "Copiá poweroff.sh a ~/.config/awesome/scripts/",
      }
    end
  end
end

-- Botón redondo con glifo (btn-power / btn-reboot / btn-logout / btn-close).
-- Los 4 botones miden EXACTAMENTE lo mismo (círculo fijo). El glifo va en un textbox del mismo
-- tamaño que el círculo y centrado: antes el textbox medía lo justo del texto y los iconos de
-- Nerd Font, que se salen un poco de su caja, quedaban cortados.
local function btn(cp, color, fn)
  local size = math.floor(pt(CFG.btn_pt) * CFG.btn_ratio + 0.5)
  local glyph = wibox.widget {
    markup        = string.format('<span foreground="%s">%s</span>', color, G.char(cp)),
    font          = string.format("%s %d", CFG.family, CFG.btn_pt),
    align         = "center",
    valign        = "center",
    forced_width  = size,
    forced_height = size,
    widget        = wibox.widget.textbox,
  }
  local box = wibox.widget {
    glyph,
    bg            = CFG.btn_bg,
    shape         = gears.shape.circle,
    forced_width  = size,
    forced_height = size,
    widget        = wibox.container.background,
  }
  box:connect_signal("mouse::enter", function() box.bg = CFG.btn_bg_h end)
  box:connect_signal("mouse::leave", function() box.bg = CFG.btn_bg end)
  return ui.clickable(box, fn, true)
end

local function build()
  -- avatar circular
  local avatar = ui.image(ASSETS .. "pfp.png", CFG.avatar, CFG.avatar, gears.shape.circle)

  -- Saludo como en el repo: un solo textbox  "Hey <nombre en azul>"
  local greet = wibox.widget {
    markup = string.format('<b><span foreground="%s">Hey </span><span foreground="%s">%s</span></b>',
                           CFG.hey, CFG.name_c, gears.string.xml_escape(CFG.name)),
    font   = string.format("%s %d", CFG.family, CFG.greet_pt),
    align  = "center",
    widget = wibox.widget.textbox,
  }

  local sub = ui.label { text = "What do you want to do?", size = pt(CFG.sub_pt), color = CFG.hey,
                         family = CFG.family, halign = "center" }

  local buttons = wibox.widget {
    btn(0x23FB,  "#f7768e", power("poweroff")),
    btn(0xF01E,  "#e0af68", power("reboot")),
    btn(0xF0343, "#bb9af7", power("logout")),
    btn(0xF00D,  "#7aa2f7", function() M.hide() end),
    spacing = dpi(CFG.gap),
    layout  = wibox.layout.fixed.horizontal,
  }

  -- columna del repo: avatar / (saludo + subtítulo, spacing 2) / botones (+10 arriba)
  local column = wibox.widget {
    {
      {
        { avatar, halign = "center", widget = wibox.container.place },
        {
          { greet, halign = "center", widget = wibox.container.place },
          { sub,   halign = "center", widget = wibox.container.place },
          spacing = dpi(CFG.text_gap),
          layout  = wibox.layout.fixed.vertical,
        },
        { { buttons, halign = "center", widget = wibox.container.place },
          top = dpi(CFG.btn_top), widget = wibox.container.margin },
        spacing = dpi(CFG.block),
        layout  = wibox.layout.fixed.vertical,
      },
      margins = dpi(CFG.pad),
      widget  = wibox.container.margin,
    },
    halign = "center", widget = wibox.container.place,
  }

  win = wibox {
    type    = "splash",    -- picom desenfoca SOLO las ventanas "splash" (assets/picom/picom.conf)
    ontop   = true,
    visible = false,
    bg      = CFG.overlay,
    widget  = { column, halign = "center", valign = "center", widget = wibox.container.place },
  }

  local kok, kg = pcall(function()
    return awful.keygrabber {
      autostart = false,
      keypressed_callback = function(_, _, key)
        if key == "Escape" then M.hide() end
      end,
    }
  end)
  grabber = kok and kg or nil
end

-- Captura la pantalla y devuelve una versión reducida (borrosa al estirarla). nil si falla.
local function blurred_snapshot(g)
  local ok, out = pcall(function()
    local src = gears.surface(root.content())
    local function step(img, ox, oy, k, w, h)
      local nw, nh = math.max(1, math.floor(w / k)), math.max(1, math.floor(h / k))
      local o  = cairo.ImageSurface(cairo.Format.ARGB32, nw, nh)
      local cr = cairo.Context(o)
      cr:scale(nw / w, nh / h)
      cr:set_source_surface(img, -ox, -oy)
      cr:paint()
      return o
    end
    local a = step(src, g.x, g.y, 4, g.width, g.height)           -- 1/4 de la pantalla
    local aw, ah = gears.surface.get_size(a)
    return step(a, 0, 0, CFG.blur_div / 4, aw, ah)                 -- y luego hasta 1/blur_div
  end)
  if ok then return out end
  return nil
end

function M.show()
  local s = awful.screen.focused()
  if not win then build() end
  local g = s.geometry
  win:geometry { x = g.x, y = g.y, width = g.width, height = g.height }
  -- la captura va ANTES de mostrar el menú, así no sale el propio menú en el fondo
  local snap = CFG.snapshot and blurred_snapshot(g) or nil
  if snap then
    local sw, sh = gears.surface.get_size(snap)
    win.bgimage = function(_, cr, w, h)
      cr:save()
      cr:scale(w / sw, h / sh)
      cr:set_source_surface(snap, 0, 0)
      cr:paint()
      cr:restore()
      cr:set_source_rgba(0, 0, 0, CFG.dim)
      cr:paint()
    end
  else
    win.bgimage = nil
  end
  win.visible = true
  if grabber then grabber:start() end
end

function M.hide()
  if grabber then grabber:stop() end
  if win then win.visible = false end
end

function M.toggle()
  if win and win.visible then M.hide() else M.show() end
end

return M
