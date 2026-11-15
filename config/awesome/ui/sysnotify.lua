-- ui/sysnotify.lua
-- Puente con naughty + render/animación del popup (toast). Separado de
-- ui/notifications.lua (que se queda con el panel/historial, la cola externa y
-- la música) — igual que AlphaTechnolog lo tiene todo junto en ui/notifications.lua.
--
-- API:
--   local sysnotify = require("ui.sysnotify")
--   sysnotify.show { kind=, header=, title=, body=, image=, cover=,
--                     on_copy=, on_delete=, on_prev=, on_next= }
--   sysnotify.hide(instant)
--   sysnotify.connect_naughty(notify_fn)  -- conecta request::display[_error] de naughty

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local ui    = require("lib.ui")
local I     = require("lib.icons")
local anim  = require("lib.anim")
local C     = ui.c

local M = {}

-- =========================================
-- CONFIG (mismas medidas que el popup del .yuck original)
-- =========================================
local CFG = {
  popup_w            = 380,  -- :width "380px" (ancho sin tocar, como lo tenías)
  popup_margin       = 20,   -- :x "-20px"
  popup_y            = 15,   -- :y "15px"
  popup_dur          = 0.35, -- segundos (rubato, sin fade)
  popup_time         = 4,    -- segundos visible (popups simples)
  popup_time_actions = 6,    -- popups con botones (Copy/Delete, Previous/Next)
}

local function primary()
  return screen.primary or screen[1]
end

local function click(w, fn) return ui.clickable(w, fn, true) end

local function pill_button(text, fn)
  local lbl = ui.label { text = text, size = 14, bold = true, halign = "center", color = C.fg }
  return click(
    ui.box(lbl, { bg = C.btn_bg, radius = 18, pad = { 6, 8, 6, 8 }, border = 1, border_color = C.btn }),
    fn)
end

local function separator()
  return wibox.widget { forced_height = 1, bg = C.fg, widget = wibox.container.background }
end

-- =========================================
-- POPUP
-- =========================================
local pop -- popup actual { popup, anim, timer }

function M.hide(instant)
  if not pop then return end
  local cur = pop
  if cur.timer then cur.timer:stop() end
  if instant then
    cur.popup.visible = false
    pop = nil
  else
    cur.closing = true
    cur.anim:set(cur.closed_x)
  end
end

local function build_popup_card(spec, close)
  -- CABECERA
  local header
  if spec.kind == "screenshot" or spec.kind == "music" then
    local thumb = ui.image(spec.image or spec.cover, 32, 32, gears.shape.circle)
    local l = ui.label { text = spec.header, size = 16, bold = true }
    header = wibox.widget { thumb, l, spacing = 12, layout = wibox.layout.fixed.horizontal }
  else
    local ic = ui.label { text = I.notif, size = 26, color = C.blue, box = 38, halign = "center" }
    local l  = ui.label { text = spec.header, size = 16, bold = true }
    header = wibox.widget {
      ui.margin(ic, 0, 6, 0, 0), l,
      spacing = 12, layout = wibox.layout.fixed.horizontal,
    }
  end

  -- INFO
  local title_txt = spec.title
  local body_txt  = spec.body
  if spec.kind == "music" then
    title_txt = ui.limit(spec.title ~= "" and spec.title or "Unknown Title", 25)
    body_txt  = ui.limit(spec.body ~= "" and spec.body or "Unknown Artist", 30)
  end
  local info = wibox.widget {
    ui.label { text = title_txt, size = 18, bold = true, halign = "center", wrap = true },
    ui.label { text = body_txt,  size = 14, halign = "center", wrap = true },
    spacing = 6, layout = wibox.layout.fixed.vertical,
  }

  local has_actions = spec.kind == "screenshot" or spec.kind == "music"

  local top = wibox.widget {
    ui.margin(header, 0, 0, 8, 0),
    ui.margin(separator(), 0, 0, 12, 0),
    ui.margin(info, 0, 0, has_actions and 16 or 6, 0),
    layout = wibox.layout.fixed.vertical,
  }
  -- click en la parte de texto = cerrar (como el eventbox del original)
  top:buttons(gears.table.join(awful.button({}, 1, close)))

  local content
  if spec.kind == "screenshot" then
    content = wibox.widget {
      top,
      {
        pill_button("Copy",   function() if spec.on_copy then spec.on_copy() end end),
        pill_button("Delete", function() if spec.on_delete then spec.on_delete() end end),
        spacing = 15, layout = wibox.layout.flex.horizontal,
      },
      layout = wibox.layout.fixed.vertical,
    }
  elseif spec.kind == "music" then
    content = wibox.widget {
      top,
      {
        pill_button("Previous", function() if spec.on_prev then spec.on_prev() end end),
        pill_button("Next",     function() if spec.on_next then spec.on_next() end end),
        spacing = 15, layout = wibox.layout.flex.horizontal,
      },
      layout = wibox.layout.fixed.vertical,
    }
  else
    content = top
  end

  return ui.box(content, {
    bg = C.bg, radius = 20, pad = { 10, 18, 10, 18 },
    border = 1, border_color = C.border,
  }), has_actions
end

function M.show(spec)
  M.hide(true)

  local s  = primary()
  local g  = s.geometry
  local fx = g.x + g.width - CFG.popup_margin - CFG.popup_w
  local fy = g.y + CFG.popup_y

  local cur = {}
  local function close() M.hide(false) end

  local card, has_actions = build_popup_card(spec, close)

  cur.popup = awful.popup {
    widget  = { card, strategy = "exact", width = CFG.popup_w, widget = wibox.container.constraint },
    ontop   = true,
    visible = false,
    bg      = "#00000000",
    type    = "notification",
    screen  = s,
    x       = g.x + g.width,
    y       = fy,
  }
  cur.closed_x = g.x + g.width -- fuera de pantalla, a la derecha

  -- ANIMACIÓN (rubato): x va de fuera de pantalla a su sitio, sin fade
  cur.anim = anim.new {
    duration = CFG.popup_dur,
    pos      = cur.closed_x,
    on_update = function(x)
      if not cur.popup then return end
      cur.popup.x = math.floor(x + 0.5)
      if cur.closing and x >= cur.closed_x - 0.5 then
        cur.popup.visible = false
        if pop == cur then pop = nil end
      end
    end,
  }

  cur.timer = gears.timer {
    timeout     = has_actions and CFG.popup_time_actions or CFG.popup_time,
    single_shot = true,
    callback    = function() if pop == cur then M.hide(false) end end,
  }

  -- Mientras el mouse está encima no se cierra solo
  card:connect_signal("mouse::enter", function() cur.timer:stop() end)
  card:connect_signal("mouse::leave", function()
    if pop == cur and not cur.closing then cur.timer:again() end
  end)

  pop = cur
  cur.popup.x = cur.closed_x
  cur.popup.visible = true
  cur.anim:set(fx)
  cur.timer:start()
end

-- =========================================
-- PUENTE NAUGHTY -> panel Lua
-- (antes vivía suelto en rc.lua; igual que AlphaTechnolog lo tiene junto al
-- render del popup, en un solo módulo: ui/notifications.lua)
-- =========================================
local bridge_connected = false
function M.connect_naughty(notify_fn)
  if bridge_connected then return end
  bridge_connected = true

  local naughty = require("naughty")

  -- aviso de errores (incluye los de arranque de Awesome)
  naughty.connect_signal("request::display_error", function(message, startup)
    naughty.notification {
      urgency = "critical",
      title = "An error happened" .. (startup and " during startup" or ""),
      message = message,
    }
  end)

  -- notificaciones del sistema (dbus / notify-send) -> mismo pipeline que
  -- la cola externa y la música: se guardan en el panel y muestran popup
  naughty.connect_signal("request::display", function(n)
    notify_fn {
      app   = tostring(n.app_name or "System"),
      title = tostring(n.title or "Notification"),
      body  = tostring(n.message or ""),
    }
    pcall(function() n:destroy() end)
  end)
end

return M
