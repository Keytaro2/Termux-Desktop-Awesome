-- screnshoot/init.lua
-- Port a Lua de screnshoot.yuck + screnshoot.scss (menú "Take a Screenshot!").
--
-- yuck/scss: ventana centrada · .menu #090E20 radio 24 padding 15 20 25 20 · punto rojo (#f7768e, 16px) ·
--            título 26px bold · 2 botones de modo (120x110, glifo 40px, radio 12) ·
--            caja "Delay In Seconds: N" 260x45 (#16161e, radio 10, texto 14px) ·
--            botón "Go and Enjoy!" (#2dd4bf, radio 8, padding 6 16, 16px bold) ·
--            tooltip flotante (240x52) al pasar el mouse por los modos.
--
-- Flujo (igual que el yuck): cierra el menú -> espera DELAY s -> flameshot -> guarda en
-- ~/storage/downloads/Screenshot_<fecha>.png -> popup "Screenshot Is Ready!" + icono en menu2.
--
-- Animación: copiada de AlphaTechnolog/dotfiles (ui/screenshot-center/init.lua): rubato sobre el ALTO
-- de la ventana (0 -> CFG.h, duración 0.15 s, override_dt, 60 fps), siempre recentrada. Mientras
-- anima se ve un fondo vacío redondeado y el contenido real solo aparece casi abierto (h > alto-10);
-- al cerrar el contenido desaparece al instante y la caja se encoge. Sin fade.
--
-- Uso:  require("screnshoot").toggle()

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local ui    = require("lib.ui")
local G     = require("lib.glyph")
local anim  = require("lib.anim")
local C     = ui.c
-- clickable SIN mano: en screnshoot el cursor se queda normal
local function click(w, fn) return ui.clickable(w, fn, true) end

local M = {}

local CFG = {
  w = 450,                    -- el yuck pide 340, pero en eww se veía ancho (~450): rectángulo, no alargado
  h = 380,                    -- el yuck pide 330, pero el contenido natural mide ~380 y GTK crece la ventana
  bg = "#090E20", radius = 24,
  pad = { 15, 20, 25, 20 },   -- .menu padding
  family = ui.mono,
  mode_w = 120, mode_h = 110, mode_px = 40, mode_gap = 20,
  delay_w = 260, delay_h = 45, delay_px = 14,
  tip_w = 240, tip_h = 52, tip_dy = 230,
  teal = "#2dd4bf",
  dark = "#1a1b26",
  delay_bg = "#16161e",
  inactive = "#a9b1d6",       -- color inline de los modos sin seleccionar
  dur = 0.15,                 -- rubato (s): igual que screenshot-center del repo
}

local GLYPH = { full = G.char(0xF02F2), crop = G.char(0xF019E) }
local TIP   = { full = "Full Screenshot", crop = "Area Screenshot" }

local win, tip
local mode, delay, editing = "full", "0", false

-- animación (rubato)
local content_widget, null_widget, showing
local win_anim, status, is_open, cur_screen = nil, "undefined", false, nil

-- widgets que cambian
local mode_btns = {}          -- mode_btns[m] = { box = background, set = setter_del_glifo }
local delay_label_set, delay_label_box, input_tb, go_set

local function sanitize(t)
  local d = tostring(t or ""):gsub("%D", "")
  if d == "" then d = "0" end
  return d
end

-- =========================================
-- ESTILO DE LOS BOTONES DE MODO
-- =========================================
local function paint_modes()
  for m, b in pairs(mode_btns) do
    local on = (m == mode)
    b.box.bg = on and C.blue or CFG.dark          -- .active / .mode-btn
    b.set(GLYPH[m], on and CFG.dark or CFG.inactive)
  end
  if go_set then go_set(GLYPH[mode] .. " Go and Enjoy!") end
end

local function show_tip(m)
  if not tip then return end
  tip.set(TIP[m])
  local s = awful.screen.focused()
  tip.win.x, tip.win.y = G.center_xy(s, CFG.tip_w, CFG.tip_h, 0, CFG.tip_dy)
  tip.win.visible = true
end

local function hide_tip()
  if tip then tip.win.visible = false end
end

-- =========================================
-- CAPTURA
-- =========================================
local function capture()
  local d = sanitize(delay)
  local file = os.getenv("HOME") .. "/storage/downloads/Screenshot_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
  local cmd
  if mode == "full" then
    cmd = "sleep " .. d .. "; mkdir -p \"$HOME/storage/downloads\"; " ..
          "flameshot full -r > '" .. file .. "'; echo ok"
  else
    cmd = "sleep " .. d .. "; mkdir -p \"$HOME/storage/downloads\"; " ..
          "flameshot gui --accept-on-select -r > '" .. file .. "'; " ..
          "if [ -s '" .. file .. "' ]; then echo ok; else rm -f '" .. file .. "'; fi"
  end
  -- pequeña pausa para que el menú ya no esté en pantalla cuando se captura
  cmd = "sleep 0.25; " .. cmd
  awful.spawn.easy_async_with_shell(cmd, function(out)
    if out and out:match("ok") then
      -- screenshot_ready ya prende el icono de flameshot en menu2
      require("notifications").screenshot_ready(file)
    end
  end)
end

-- =========================================
-- CAJA DE DELAY (etiqueta <-> input)
-- =========================================
local function show_label()
  editing = false
  delay_label_set("Delay In Seconds: " .. delay)
  delay_label_box.visible = true
  input_tb.visible = false
end

local function start_editing()
  if editing then return end
  editing = true
  delay_label_box.visible = false
  input_tb.visible = true
  awful.prompt.run {
    prompt           = "",
    textbox          = input_tb,
    text             = delay,
    selectall        = true,
    changed_callback = function(t) delay = sanitize(t) end,
    exe_callback     = function(t) delay = sanitize(t or delay) end,
    done_callback    = function() show_label() end,
  }
end

-- =========================================
-- CONSTRUCCIÓN
-- =========================================
local function mode_button(m)
  local l, set = ui.label { text = GLYPH[m], size = CFG.mode_px, color = CFG.inactive,
                            family = CFG.family, halign = "center", valign = "center",
                            box = CFG.mode_px * 2 }   -- caja cuadrada: el icono no se corta
  local box = ui.box(ui.center(l), { bg = CFG.dark, radius = 12,
                                     w = CFG.mode_w, h = CFG.mode_h })
  mode_btns[m] = { box = box, set = set }
  click(box, function() mode = m; paint_modes() end)
  box:connect_signal("mouse::enter", function() show_tip(m) end)
  box:connect_signal("mouse::leave", hide_tip)
  return box
end

local function build_tip()
  local icon = ui.label { text = G.char(0x24D8), size = 18, bold = true, color = C.blue, family = CFG.family,
                           box = 28, halign = "center" }
  local text, set = ui.label { text = "", size = 16, color = C.fg, family = CFG.family }
  local row = wibox.widget {
    icon, text,
    spacing = 12,
    layout  = wibox.layout.fixed.horizontal,
  }
  local w = wibox {
    type = "dock", ontop = true, visible = false,
    width = CFG.tip_w, height = CFG.tip_h, bg = "#00000000",
    widget = ui.box(ui.center(row), { bg = C.bg, radius = 10, pad = { 10, 20, 10, 20 } }),
  }
  tip = { win = w, set = set }
end

local function build()
  -- punto rojo para cerrar (16x16; margin-top 10, margin-left 10, margin-bottom 5)
  local dot = click(
    ui.box(wibox.widget { text = "", widget = wibox.widget.textbox },
           { bg = C.red, radius = 10, w = 16, h = 16 }),
    function() M.hide() end)
  local close = wibox.widget {
    { dot, top = 10, left = 10, bottom = 5, widget = wibox.container.margin },
    halign = "left", widget = wibox.container.place,
  }

  -- título (margin-bottom 25)
  local title = ui.label { text = "Take a Screenshot!", size = 26, bold = true,
                           color = C.fg, family = CFG.family, halign = "center" }

  -- modos (margin-bottom 25)
  local modes = wibox.widget {
    mode_button("full"),
    mode_button("crop"),
    spacing = CFG.mode_gap,
    layout  = wibox.layout.fixed.horizontal,
  }

  -- delay: etiqueta clickeable + input
  local dl, dset = ui.label { text = "Delay In Seconds: " .. delay, size = CFG.delay_px,
                              color = CFG.inactive, family = CFG.family,
                              halign = "center", valign = "center" }
  delay_label_set = dset
  input_tb = wibox.widget {
    font = ui.font(CFG.delay_px, false, CFG.family), halign = "center", valign = "center",
    visible = false, widget = wibox.widget.textbox,
  }
  delay_label_box = click(ui.center(dl), start_editing)
  local delay_stack = wibox.widget {
    delay_label_box, input_tb,
    layout = wibox.layout.stack,
  }
  local delay_box = ui.box(delay_stack, { bg = CFG.delay_bg, radius = 10,
                                          w = CFG.delay_w, h = CFG.delay_h })

  -- Go and Enjoy!  (padding 6 16, min 110x30, radio 8, 16px bold)
  local gl, gset = ui.label { text = GLYPH.full .. " Go and Enjoy!", size = 16, bold = true,
                              color = CFG.dark, family = CFG.family,
                              halign = "center", valign = "center" }
  go_set = function(t) gset(t, CFG.dark) end
  local go = click(
    ui.box(ui.center(gl), { bg = CFG.teal, radius = 8, pad = { 6, 16, 6, 16 } }),
    function()
      M.hide()
      capture()
    end)

  local content = wibox.widget {
    close,
    { title, bottom = 25, widget = wibox.container.margin },
    { { modes, bottom = 25, widget = wibox.container.margin },
      halign = "center", widget = wibox.container.place },
    { delay_box, halign = "center", widget = wibox.container.place },
    { { go, top = 18, bottom = 20, widget = wibox.container.margin },      -- separador de 18 + margin-bottom 20
      halign = "center", widget = wibox.container.place },
    layout = wibox.layout.fixed.vertical,
  }

  content_widget = ui.box(content, { bg = CFG.bg, radius = CFG.radius, pad = CFG.pad })

  -- widget que no muestra nada: se usa mientras la ventana crece / se encoge
  -- (la forma se recalcula con el alto actual para que las esquinas nunca se deformen)
  null_widget = ui.box(wibox.widget { markup = "", widget = wibox.widget.textbox }, {
    bg    = CFG.bg,
    shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, CFG.radius) end,
  })

  win = wibox {
    type    = "dock",
    ontop   = true,
    visible = false,
    width   = CFG.w,
    height  = 1,                 -- 0 no es un alto válido para un wibox
    bg      = "#00000000",
    widget  = null_widget,
  }
  showing = null_widget

  local function set_content(w)
    if w ~= showing then
      showing = w
      win.widget = w
    end
  end

  win_anim = anim.new {
    duration = CFG.dur,
    pos      = 0,
    on_update = function(h)
      -- animación de cierre terminada
      if h < 1 and status == "closing" then
        win.visible = false
        status = "undefined"
        return
      end

      -- al cerrar se quita el contenido; al abrir se pone cuando ya casi está completa
      if status == "closing" then
        set_content(null_widget)
      elseif status == "opening" and h > CFG.h - 10 then
        set_content(content_widget)
      end

      if h > 0 then
        local nh = math.max(1, math.floor(h + 0.5))
        if nh ~= win.height then win.height = nh end
        local s = cur_screen or awful.screen.focused()
        win.x, win.y = G.center_xy(s, CFG.w, nh, 0, 0)   -- recentra en cada cuadro
      end
    end,
  }

  build_tip()
  paint_modes()
end

-- =========================================
-- API
-- =========================================
function M.show()
  if not win then build() end
  cur_screen = awful.screen.focused()
  mode, delay = "full", "0"
  paint_modes()
  show_label()

  is_open = true
  status  = "opening"
  win.x, win.y = G.center_xy(cur_screen, CFG.w, win.height, 0, 0)
  win.visible = true
  win_anim:set(CFG.h)
end

function M.hide()
  hide_tip()
  if not win or not is_open then return end
  is_open = false
  status  = "closing"
  win_anim:set(0)
end

function M.toggle()
  if is_open then M.hide() else M.show() end
end

return M
