-- bar/init.lua
-- Port a Lua de eww.yuck (la barra vertical izquierda).
--
-- Geometría original: x 20px · ancho 90px · alto 97% · anclada a la izquierda y centrada en Y
-- La barra es "exclusive": reserva espacio (struts) para que las ventanas no la tapen.
--
-- Uso (rc.lua):
--   s.mybar = require("bar").build(s, { on_dashboard = function() s.mydash.toggle() end })

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local ui    = require("lib.ui")
-- clickable SIN cursor de mano: sobre la barra el puntero se queda normal
local function click(w, fn) return ui.clickable(w, fn, true) end
local I     = require("lib.icons")
local anim  = require("lib.anim")
local C     = ui.c

local M = {}

-- =========================================
-- CONFIG
-- =========================================
local BAR = {
  x      = 20,     -- :x "20px"
  w      = 90,     -- :width "90px"
  h_pct  = 0.97,   -- :height "97%"
  pad_y  = 15,     -- margen interno arriba/abajo (ajustalo si tu .bar tenía otro)
  radius = 20,
}

local TOOLTIP = {
  x = 120, bottom = 70, w = 240, h = 52,   -- layout_tooltip
}

-- Tareas (ventanas abiertas): una LÍNEA vertical por ventana, como en eww.
-- La del foco es azul y más larga; las demás son grises; las minimizadas, más tenues.
local TASK = {
  w       = 8,           -- grosor de la línea
  h       = 18,          -- largo de la línea (ventana normal)
  h_focus = 30,          -- largo de la línea de la ventana en foco
  hit_x   = 14,          -- margen invisible a cada lado (para que sea fácil tocarla con el dedo)
  hit_y   = 4,           -- margen invisible arriba/abajo
  gap     = 2,           -- espacio entre líneas (se suma al margen invisible)
  dur     = 0.2,         -- rubato al crecer / cambiar de foco (s)
  normal  = "#3b4261",
  min     = "#1f2335",
  focus   = C.blue,
  urgent  = C.red,
}

-- Alto estimado del panel de ajustes rápidos (3 botones de 22px + espacios de 12px)
local QS_HEIGHT = 3 * 36 + 2 * 12 + 10

local LAYOUT_DIR = gears.filesystem.get_themes_dir() .. "default/layouts/"

local function layout_img(s)
  local name = awful.layout.getname(awful.layout.get(s))
  if name == "floating" then return LAYOUT_DIR .. "floatingw.png"
  elseif name == "max" then return LAYOUT_DIR .. "maxw.png" end
  return LAYOUT_DIR .. "tilew.png"
end

local function layout_title(s)
  local name = awful.layout.getname(awful.layout.get(s)) or "tile"
  return (name:gsub("^%l", string.upper))
end

-- =========================================
-- PIEZAS
-- =========================================
-- (defwidget launcher [icon size action])
local function launcher(icon, size, action)
  local lbl, set = ui.label { text = icon, size = size, color = C.fg, halign = "center" }
  local w = ui.margin(lbl, 4, 0, 4, 0)
  click(w, action)
  return w, set
end

-- =========================================
-- BUILD
-- =========================================
function M.build(s, opts)
  opts = opts or {}
  local self = {}
  local g = s.geometry
  local h = math.floor(g.height * BAR.h_pct)

  -- ---------- TOP: lanzadores ----------
  local function launching(what, cmd)
    return function()
      require("notifications").launching(what)
      awful.spawn.with_shell(cmd .. " &")
    end
  end

  local top = wibox.widget {
    (launcher(I.app_launcher, 30, function() awful.spawn.with_shell("rofi -show drun &") end)),
    (launcher(I.image, 25, function() ui.call("screnshoot", "toggle") end)),
    (launcher(I.browser, 30, launching("browser", "firefox"))),
    (launcher(I.terminal, 30, launching("terminal", "xfce4-terminal --hide-menubar"))),
    (launcher(I.folder, 20, launching("explorer", "thunar"))),
    spacing = 20,
    layout  = wibox.layout.fixed.vertical,
  }

  -- ---------- CENTRO: lista de ventanas (reemplaza tasks.sh) ----------
  -- Cada ventana abierta (terminal, thunar, firefox...) es una línea vertical en la barra.
  local function task_color(c)
    if c.urgent then return TASK.urgent end
    if c == client.focus and not c.minimized then return TASK.focus end
    if c.minimized then return TASK.min end
    return TASK.normal
  end

  -- colores de las líneas también por tema, para que el tasklist nunca las pise
  beautiful.tasklist_bg_normal   = TASK.normal
  beautiful.tasklist_bg_focus    = TASK.focus
  beautiful.tasklist_bg_minimize = TASK.min
  beautiful.tasklist_bg_urgent   = TASK.urgent

  -- animación de cada línea, guardada por widget (así no dependemos de qué objeto
  -- nos pase el tasklist en cada callback)
  local task_anim = setmetatable({}, { __mode = "k" })

  -- OJO: el tasklist le pone su propio shape (nil = cuadrado) al background_role en cada
  -- actualización, por eso la forma se vuelve a aplicar acá, después de que él termina.
  local function task_shape(cr, w, h)
    gears.shape.rounded_rect(cr, w, h, math.min(w, h) / 2)
  end

  local function task_refresh(self2, c)
    local line = self2:get_children_by_id("background_role")[1]
    local a = line and task_anim[line]
    if not a then return end
    line.shape = task_shape
    line.bg = task_color(c)
    local focused = (c == client.focus and not c.minimized)
    a:set(focused and TASK.h_focus or TASK.h)
  end

  local tasks = awful.widget.tasklist {
    screen  = s,
    filter  = awful.widget.tasklist.filter.alltags,
    buttons = gears.table.join(
      awful.button({}, 1, function(c)
        if c == client.focus and not c.minimized then
          c.minimized = true
        else
          c.minimized = false
          c:emit_signal("request::activate", "tasklist", { raise = true })
        end
      end)),
    layout  = { spacing = TASK.gap, layout = wibox.layout.fixed.vertical },
    style   = { shape = task_shape },
    widget_template = {
      {
        {
          id            = "background_role",
          forced_width  = TASK.w,
          forced_height = 1,
          shape         = task_shape,
          widget        = wibox.container.background,
        },
        left   = TASK.hit_x, right  = TASK.hit_x,
        top    = TASK.hit_y, bottom = TASK.hit_y,
        widget = wibox.container.margin,
      },
      widget = wibox.container.background,
      create_callback = function(self2, c)
        local line = self2:get_children_by_id("background_role")[1]
        -- la línea "crece" al abrirse la ventana
        task_anim[line] = anim.new {
          duration = TASK.dur,
          pos      = 0,
          on_update = function(h)
            line.forced_height = math.max(1, math.floor(h + 0.5))
          end,
        }
        task_refresh(self2, c)
        gears.timer.delayed_call(function()
          if c.valid then task_refresh(self2, c) end
        end)
      end,
      update_callback = function(self2, c)
        task_refresh(self2, c)
      end,
    },
  }
  local center = wibox.widget { tasks, halign = "center", valign = "center", widget = wibox.container.place }

  -- ---------- ABAJO: ajustes rápidos ----------
  local wifi_off, vol_muted = false, false

  local wifi_w, set_wifi = launcher(I.wifi_on, 22, function() end)
  click(wifi_w, function()
    wifi_off = not wifi_off
    set_wifi(wifi_off and I.wifi_off or I.wifi_on)
  end)

  local vol_w, set_vol = launcher(I.vol_on, 22, function() end)
  click(vol_w, function()
    vol_muted = not vol_muted
    set_vol(vol_muted and I.vol_muted or I.vol_on)
    awful.spawn.with_shell("bash " .. ui.dir .. "scripts/toggle_mute.sh &")
  end)

  local bell_w = launcher(I.bell, 22, function() require("notifications").toggle_panel() end)

  local qs_inner = wibox.widget {
    wifi_w, vol_w, bell_w,
    spacing = 12,
    layout  = wibox.layout.fixed.vertical,
  }
  local qs = wibox.widget {
    qs_inner,
    strategy = "max",
    height   = 1,
    widget   = wibox.container.constraint,
  }
  qs.visible = false

  -- panel de ajustes rápidos: igual que ui/bar/modules/actions.lua del repo (0.2 s)
  local qs_open = false
  local qs_anim = anim.new {
    duration = 0.2,
    pos      = 0,
    on_update = function(h)
      if h <= 0.001 then
        qs.visible = false
      else
        qs.visible = true
        qs.height  = math.max(1, math.floor(h))
      end
    end,
  }

  local gear_w = launcher(I.gear, 23, function()
    qs_open = not qs_open
    qs_anim:set(qs_open and QS_HEIGHT or 0)
  end)

  local quick = wibox.widget {
    qs, gear_w,
    spacing = 10,
    layout  = wibox.layout.fixed.vertical,
  }

  -- ---------- RELOJ ----------
  local hour_w, set_hour = ui.label { text = "00", size = 24, bold = true, color = C.fg,   halign = "center" }
  local min_w,  set_min  = ui.label { text = "00", size = 24, bold = true, color = C.blue, halign = "center" }
  local clock = click(
    wibox.widget { hour_w, min_w, layout = wibox.layout.fixed.vertical },
    function() ui.call("date1", "toggle") end)

  local last_h, last_m
  gears.timer {
    timeout   = 1,
    autostart = true,
    call_now  = true,
    callback  = function()
      local hh, mm = os.date("%H"), os.date("%M")
      if hh ~= last_h then last_h = hh; set_hour(hh) end
      if mm ~= last_m then last_m = mm; set_min(mm) end
    end,
  }

  -- ---------- SELECTOR DE LAYOUT + TOOLTIP ----------
  local layout_icon = wibox.widget {
    image         = layout_img(s),
    resize        = true,
    forced_width  = 22,
    forced_height = 22,
    widget        = wibox.widget.imagebox,
  }
  local layout_btn = click(
    ui.margin(ui.center(layout_icon), 4, 0, 4, 0),
    function() awful.layout.inc(1) end)

  local tip_text, set_tip = ui.label { text = "Layout " .. layout_title(s), size = 16, bold = true, color = C.fg }
  local tip_icon = ui.label { text = I.info, size = 18, bold = true, color = C.blue }
  local tooltip = wibox {
    screen            = s,
    type              = "tooltip",
    ontop             = true,
    visible           = false,
    input_passthrough = true,
    bg                = "#00000000",
    x                 = g.x + TOOLTIP.x,
    y                 = g.y + g.height - TOOLTIP.bottom - TOOLTIP.h,
    width             = TOOLTIP.w,
    height            = TOOLTIP.h,
  }
  tooltip.widget = ui.box(
    ui.center(wibox.widget { tip_icon, tip_text, spacing = 12, layout = wibox.layout.fixed.horizontal }),
    { bg = C.bg, radius = 10, pad = { 10, 20, 10, 20 } })

  local function refresh_layout()
    layout_icon.image = layout_img(s)
    set_tip("Layout " .. layout_title(s))
  end
  tag.connect_signal("property::layout", refresh_layout)
  tag.connect_signal("property::selected", refresh_layout)

  layout_btn:connect_signal("mouse::enter", function() refresh_layout(); tooltip.visible = true end)
  layout_btn:connect_signal("mouse::leave", function() tooltip.visible = false end)

  -- ---------- POWER ----------
  local power_w = launcher(I.power, 23, function() ui.call("powermenu", "toggle") end)

  local bottom = wibox.widget {
    (launcher(I.arrow, 23, function() ui.call("menu2", "toggle") end)),
    (launcher(I.dashboard, 23, function()
      if opts.on_dashboard then opts.on_dashboard() end
    end)),
    quick,
    clock,
    layout_btn,
    power_w,
    spacing = 15,
    layout  = wibox.layout.fixed.vertical,
  }

  -- ---------- VENTANA ----------
  local bar = wibox {
    screen  = s,
    type    = "dock",
    ontop   = true,
    visible = true,
    bg      = C.bg,
    shape   = ui.rrect(BAR.radius),
    x       = g.x + BAR.x,
    y       = g.y + math.floor((g.height - h) / 2),
    width   = BAR.w,
    height  = h,
  }
  bar:struts { left = BAR.x + BAR.w }  -- :exclusive true

  bar:setup {
    {
      first  = top,
      second = center,
      third  = bottom,
      expand = "none",
      layout = wibox.layout.align.vertical,
    },
    top    = BAR.pad_y,
    bottom = BAR.pad_y,
    widget = wibox.container.margin,
  }

  self.wibox = bar
  return self
end

return M
