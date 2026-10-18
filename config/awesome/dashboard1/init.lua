-- dashboard1/init.lua
-- Port a Lua de Dashboard1/eww.yuck (mismas medidas y colores) con animación rubato.
--
-- Geometría original:  x 120px · ancho 650px · alto 97% · anclado a la izquierda, centrado en Y
--
-- Uso (rc.lua):
--   s.mydash = require("dashboard1").build(s)
--   s.mydash.toggle()

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local ui    = require("lib.ui")
local I     = require("lib.icons")
local anim  = require("lib.anim")
local C     = ui.c

local M = {}

-- =========================================
-- CONFIG
-- =========================================
local CFG = {
  x      = 120,    -- :x "120px"
  w      = 650,    -- :width "650px"
  h_pct  = 0.97,   -- :height "97%"
  pad    = 25,     -- padding del contenedor

  dur    = 0.25,   -- duración rubato (s), igual que el repo. Sin fade/opacidad
}

local SC     = ui.dir .. "scripts/"
local ASSETS = ui.dir .. "assets/"

-- clickable SIN mano: en el dashboard el cursor se queda normal
local function click(w, fn) return ui.clickable(w, fn, true) end

local refresh_buttons   -- se define más abajo (lee los estados de los botones)

-- =========================================
-- PIEZAS REUTILIZABLES
-- =========================================

-- Botón cuadrado (36x36, radio 10) de la tarjeta de usuario
local function sq_btn(glyph, color, fn)
  local l = ui.label { text = glyph, size = 16, color = color, halign = "center", valign = "center", box = 36 }
  return click(ui.box(ui.center(l), { bg = C.btn, radius = 10, w = 36, h = 36 }), fn)
end

-- Tarjeta con cabecera oscura + pie (usuario / música)
local function card_shell(top_content, bottom_content)
  return ui.box(
    wibox.widget {
      ui.box(top_content, { bg = C.panel, radius = { 16, 16, 12, 12 }, pad = { 20, 15, 30, 15 } }),
      ui.margin(bottom_content, 12, 15, 15, 15),
      layout = wibox.layout.fixed.vertical,
    },
    { bg = C.card, radius = 16 })
end

-- Botón circular on/off (44x44). Devuelve (widget, setter(estado))
local function state_button(key, ic_on, ic_off, extra)
  local lbl, set_lbl = ui.label { text = ic_off, size = 20, color = C.fg2, halign = "center", valign = "center", box = 44 }
  local circle = wibox.widget {
    ui.center(lbl),
    bg            = C.card,
    shape         = gears.shape.circle,
    forced_width  = 44,
    forced_height = 44,
    widget        = wibox.container.background,
  }
  click(circle, function()
    ui.sh("bash " .. SC .. "buttons.sh " .. key .. " toggle" .. (extra or ""))
    -- refresca el botón enseguida, sin esperar al poll
    gears.timer.start_new(0.15, function()
      if refresh_buttons then refresh_buttons() end
      return false
    end)
  end)
  local cur
  local function set(state)
    if state == cur then return end   -- no redibujar si no cambió
    cur = state
    local on = (state == "on")
    circle.bg = on and C.blue or C.card
    set_lbl(on and ic_on or ic_off, on and C.dark or C.fg2)
  end
  set("off")
  return ui.center(circle), set
end

-- Slider con icono encima. Devuelve (widget, setter(valor))
local function icon_slider(icon, init, on_change)
  local sl = wibox.widget {
    bar_shape        = gears.shape.rounded_bar,
    bar_height       = 36,
    bar_color        = C.card,
    bar_active_color = C.blue,
    handle_width     = 0,
    handle_color     = C.blue,
    minimum          = 0,
    maximum          = 101,
    value            = init or 0,
    forced_height    = 36,
    widget           = wibox.widget.slider,
  }

  local pressed, updating = false, false
  local pending
  local tmr = gears.timer {
    timeout     = 0.08,
    single_shot = true,
    callback    = function() on_change(math.floor(pending)) end,
  }

  sl:connect_signal("property::value", function()
    if updating then return end
    pending = sl.value
    if not tmr.started then tmr:start() end
  end)
  sl:connect_signal("button::press",   function() pressed = true end)
  sl:connect_signal("button::release", function() pressed = false end)

  local ic = ui.label { text = icon, size = 20, color = C.dark, halign = "left", valign = "center", box = 36 }
  local w = wibox.widget {
    sl,
    ui.margin(ic, 0, 0, 0, 15),
    layout = wibox.layout.stack,
  }

  local function set(v)
    if pressed then return end
    updating = true
    sl.value = tonumber(v) or 0
    updating = false
  end
  return w, set
end

-- Tarjeta con anillo (CPU / RAM / Temp / Disk). Devuelve (widget, setter(valor))
local function sys_card(title, icon)
  local ic = ui.label { text = icon, size = 32, color = C.fg, halign = "center", valign = "center", box = 64 }
  local arc = wibox.widget {
    ui.center(ic),
    value         = 0,
    min_value     = 0,
    max_value     = 100,
    thickness     = 14,
    start_angle   = math.pi * 3 / 2,  -- arranca arriba (start-at 75)
    rounded_edge  = false,
    colors        = { C.blue },
    bg            = C.card,
    paddings      = 0,
    forced_width  = 125,
    forced_height = 125,
    widget        = wibox.container.arcchart,
  }
  local t = ui.label { text = title, size = 13, bold = true, color = C.muted, halign = "left" }
  local card = ui.box(
    wibox.widget { first = t, second = ui.center(arc), layout = wibox.layout.align.vertical },
    { bg = C.panel, radius = 16, pad = { 15, 15, 15, 15 } })
  return card, function(v)
    local n = tonumber(v) or 0
    if arc.value ~= n then arc.value = n end
  end
end

-- =========================================
-- BUILD
-- =========================================
function M.build(s)
  local self = {}
  local g  = s.geometry
  local h  = math.floor(g.height * CFG.h_pct)
  local fx = g.x + CFG.x
  local fy = g.y + math.floor((g.height - h) / 2)

  -- ---------- ROW 0: BÚSQUEDA ----------
  local pfp1  = ui.image(ASSETS .. "pfp1.png", 24, 24, gears.shape.circle)
  local hello = ui.label { text = "Hello Keytaro", size = 14, color = C.fg }
  local sicon = ui.label { text = I.search, size = 14, color = C.blue, box = 24 }
  local stxt  = ui.label { text = "Search...", size = 13, color = C.muted, halign = "left" }

  local search_box = click(
    ui.box(
      wibox.widget { ui.margin(sicon, 0, 8, 0, 0), stxt, layout = wibox.layout.fixed.horizontal },
      { bg = C.panel, radius = 20, pad = { 8, 15, 8, 15 } }),
    function() ui.sh("rofi -show drun &") end)

  local left = wibox.widget {
    ui.margin(pfp1, 0, 10, 0, 0),
    ui.margin(hello, 0, 15, 0, 0),
    layout = wibox.layout.fixed.horizontal,
  }
  local search_row = ui.margin(
    ui.box(
      wibox.widget { first = left, second = search_box, layout = wibox.layout.align.horizontal },
      { bg = C.card, radius = 16, pad = { 12, 15, 12, 15 } }),
    0, 0, 5, 0)

  -- ---------- ROW 1: USUARIO + MÚSICA ----------
  local pfp = ui.image(ASSETS .. "pfp.png", 65, 65, gears.shape.circle)
  local uptime_lbl, set_uptime = ui.label { text = "up", size = 13, color = C.fg, halign = "left" }

  local user_top = wibox.widget {
    ui.margin(pfp, 0, 15, 0, 0),
    {
      {
        ui.label { text = "Welcome Keytaro", size = 16, bold = true, color = C.fg, halign = "left" },
        ui.margin(uptime_lbl, 4, 0, 0, 0),
        layout = wibox.layout.fixed.vertical,
      },
      valign = "center", halign = "left",
      widget = wibox.container.place,
    },
    layout = wibox.layout.fixed.horizontal,
  }

  -- Acción de los botones reiniciar / apagar (poweroff.sh viene de ~/.config/eww/scripts vía migrar.sh)
  local function power_action(action)
    return function()
      local script = SC .. "poweroff.sh"
      local f = io.open(script, "r")
      if f then
        f:close()
        ui.sh("bash " .. script .. " " .. action)
      else
        local ok, N = pcall(require, "notifications")
        if ok and N.notify then
          N.notify { app = "Power", title = "poweroff.sh no encontrado",
                     body = "Copiá poweroff.sh a ~/.config/awesome/scripts/" }
        end
      end
    end
  end

  -- Fila inferior de la tarjeta (los 3 botones de 36x36):
  --   [menú de apagado] ............ [reiniciar] [apagar]
  -- Se arma con stack + place (no con align first+third sin second): así la fila siempre
  -- mide 36 px de alto y los botones se dibujan a la izquierda y a la derecha.
  local user_bottom = wibox.widget {
    {
      sq_btn(I.pwr_btn, C.blue, function() ui.call("powermenu", "toggle") end),
      halign = "left", valign = "center",
      widget = wibox.container.place,
    },
    {
      {
        sq_btn(I.reboot,  C.purple, power_action("reboot")),
        sq_btn(I.pwr_btn, C.red,    power_action("poweroff")),
        spacing = 10,
        layout  = wibox.layout.fixed.horizontal,
      },
      halign = "right", valign = "center",
      widget = wibox.container.place,
    },
    layout = wibox.layout.stack,
  }
  local user_card = card_shell(user_top, user_bottom)

  -- Música
  local cover_img = ui.image(nil, 65, 65, ui.rrect(12))
  local title_lbl,  set_title  = ui.label { text = "No title",  size = 16, bold = true, color = C.fg, halign = "left" }
  local artist_lbl, set_artist = ui.label { text = "No artist", size = 13, color = C.fg, halign = "left" }

  local music_top = wibox.widget {
    ui.margin(cover_img, 0, 15, 0, 0),
    {
      {
        title_lbl,
        ui.margin(artist_lbl, 4, 0, 0, 0),
        layout = wibox.layout.fixed.vertical,
      },
      valign = "center", halign = "left",
      widget = wibox.container.place,
    },
    layout = wibox.layout.fixed.horizontal,
  }

  local play_lbl, set_play = ui.label { text = I.play, size = 20, color = C.fg, halign = "center", box = 32 }
  local function ctl(w, fn) return click(ui.margin(w, 4, 4, 4, 4), fn) end
  local music_bottom = wibox.widget {
    ctl(ui.label { text = I.prev, size = 16, color = C.fg, halign = "center", box = 28 },
        function() ui.sh("audtool playlist-reverse") end),
    ctl(play_lbl, function() ui.sh("audtool playback-playpause") end),
    ctl(ui.label { text = I.next, size = 16, color = C.fg, halign = "center", box = 28 },
        function() ui.sh("audtool playlist-advance") end),
    spacing = 25,
    layout  = wibox.layout.fixed.horizontal,
  }
  local music_card = card_shell(music_top, ui.center(music_bottom))

  local row1 = wibox.widget { user_card, music_card, spacing = 15, layout = wibox.layout.flex.horizontal }

  -- ---------- ROW 2: CONTROLES + ACCIONES ----------
  local vol_w, set_vol = icon_slider(I.d_vol_on, 0, function(v)
    ui.sh("bash " .. SC .. "volume.sh " .. v)
  end)
  local bri_w, _ = icon_slider(I.brightness, 100, function(v)
    ui.sh("bash " .. SC .. "brightness.sh " .. v)
  end)

  local sliders_card = ui.box(
    wibox.widget {
      ui.margin(ui.label { text = "Controls", size = 12, bold = true, color = C.muted, halign = "left" }, 0, 0, 5, 0),
      vol_w,
      bri_w,
      spacing = 15,
      layout  = wibox.layout.fixed.vertical,
    },
    { bg = C.panel, radius = 16, pad = { 15, 15, 15, 15 } })
  -- centrado vertical dentro de la fila
  sliders_card = wibox.widget { sliders_card, valign = "center",
                                fill_horizontal = true, widget = wibox.container.place }

  local btn_set = {}
  local b_wifi, b_vol, b_air, b_bri, b_bt, b_mic, b_crop, b_sync
  b_wifi, btn_set.wifi = state_button("wifi", I.d_wifi_on, I.d_wifi_off)
  b_vol,  btn_set.vol  = state_button("vol",  I.d_vol_on,  I.d_vol_off,
                                       " && bash " .. SC .. "toggle_mute.sh &")
  b_air,  btn_set.air  = state_button("air",  I.air_on,    I.air_off)
  b_bri,  btn_set.bri  = state_button("bri",  I.bri_on,    I.bri_off)
  b_bt,   btn_set.bt   = state_button("bt",   I.bt_on,     I.bt_off)
  b_mic,  btn_set.mic  = state_button("mic",  I.mic_on,    I.mic_off)
  b_crop, btn_set.crop = state_button("crop", I.crop,      I.crop, " && xdotool key alt+slash &")
  b_sync, btn_set.sync = state_button("sync", I.sync,      I.sync, " && xdotool key alt+minus &")

  local actions_card = ui.box(
    wibox.widget {
      ui.margin(ui.label { text = "Actions", size = 12, bold = true, color = C.muted, halign = "left" }, 0, 0, 5, 0),
      { b_wifi, b_vol, b_air, b_bri, spacing = 10, layout = wibox.layout.flex.horizontal },
      { b_bt, b_mic, b_crop, b_sync, spacing = 10, layout = wibox.layout.flex.horizontal },
      spacing = 10,
      layout  = wibox.layout.fixed.vertical,
    },
    { bg = C.panel, radius = 16, pad = { 15, 15, 15, 15 } })

  local row2 = wibox.widget { sliders_card, actions_card, spacing = 15, layout = wibox.layout.flex.horizontal }

  -- ---------- ROW 3 / 4: ANILLOS ----------
  local cpu_card,  set_cpu  = sys_card("CPU",  I.cpu)
  local ram_card,  set_ram  = sys_card("RAM",  I.ram)
  local temp_card, set_temp = sys_card("Temp", I.temp)
  local disk_card, set_disk = sys_card("Disk", I.disk)

  local row3 = wibox.widget { cpu_card,  ram_card,  spacing = 15, layout = wibox.layout.flex.horizontal }
  local row4 = wibox.widget { temp_card, disk_card, spacing = 15, layout = wibox.layout.flex.horizontal }

  -- ---------- ENSAMBLE ----------
  local top  = wibox.widget { search_row, row1, row2, spacing = 15, layout = wibox.layout.fixed.vertical }
  local rows = wibox.widget { row3, row4, spacing = 15, layout = wibox.layout.flex.vertical }
  local main = wibox.widget {
    first  = top,
    second = ui.margin(rows, 15, 0, 0, 0),
    layout = wibox.layout.align.vertical,
  }
  local root = ui.box(main, { bg = C.bg, radius = 20,
                              pad = { CFG.pad, CFG.pad, CFG.pad, CFG.pad } })

  -- =========================================
  -- POLLERS (solo corren mientras el dashboard está abierto)
  -- =========================================
  local timers, pending = {}, {}
  local last_music

  -- Intervalos pensados para Termux: cada poll lanza procesos y eso cuesta.
  timers[#timers + 1] = ui.poll(SC .. "cpu.sh",     3,   set_cpu)
  timers[#timers + 1] = ui.poll(SC .. "ram.sh",     5,   set_ram)
  timers[#timers + 1] = ui.poll(SC .. "storage.sh", 600, set_disk)
  -- battery.sh usa termux-battery-status (Termux:API = proceso Java, muy pesado)
  timers[#timers + 1] = ui.poll(SC .. "battery.sh", 30,  set_temp)
  timers[#timers + 1] = ui.poll("bash " .. SC .. "volume.sh", 3, set_vol)

  -- Estados de los botones: se leen directo del cache desde Lua (0 procesos)
  local TOGGLES  = (os.getenv("HOME") or "") .. "/.cache/eww_toggles/"
  local BTN_KEYS = { "wifi", "vol", "air", "bri", "bt", "mic", "crop", "sync" }
  refresh_buttons = function()
    for _, k in ipairs(BTN_KEYS) do
      local f = io.open(TOGGLES .. k, "r")
      local v = f and f:read("*l")
      if f then f:close() end
      if v ~= "on" and v ~= "off" then v = (k == "wifi") and "on" or "off" end
      btn_set[k](v)
    end
  end
  timers[#timers + 1] = gears.timer {
    timeout = 1, call_now = true, autostart = false, callback = refresh_buttons,
  }

  -- Música: UNA sola llamada cada 2 s (estado + título + artista).
  -- cover.sh solo corre cuando cambia la canción.
  timers[#timers + 1] = ui.poll(
    "audtool playback-status 2>/dev/null; echo '|||'; " ..
    "audtool current-song-tuple-data title 2>/dev/null; echo '|||'; " ..
    "audtool current-song-tuple-data artist 2>/dev/null", 2,
    function(out)
      local status, title, artist = out:match("^(.-)%s*|||%s*(.-)%s*|||%s*(.-)$")
      status = status or ""
      title  = (title  and title  ~= "") and title  or "No title"
      artist = (artist and artist ~= "") and artist or "No artist"
      set_play(status == "playing" and I.pause or I.play)
      set_title(ui.limit(title, 15))
      set_artist(ui.limit(artist, 18))
      local key = title .. "|" .. artist
      if key ~= last_music then
        last_music = key
        ui.sh("bash " .. SC .. "cover.sh 2>/dev/null", function(cover)
          cover_img.update_path(cover)
        end)
      end
    end)

  local function stop_pollers()
    for _, p in ipairs(pending) do p:stop() end
    pending = {}
    for _, t in ipairs(timers) do t:stop() end
  end
  -- Los pollers arrancan ESCALONADOS y cuando termina la animación,
  -- para no lanzar ~10 procesos a la vez mientras el panel se desliza.
  local function start_pollers()
    stop_pollers()
    for i, t in ipairs(timers) do
      pending[#pending + 1] = gears.timer.start_new(CFG.dur + 0.1 * i, function()
        t:start()
        return false
      end)
    end
    gears.timer.start_new(CFG.dur + 0.05, function()
      ui.sh("uptime -p 2>/dev/null", function(out)
        set_uptime(out ~= "" and out or "up")
      end)
      return false
    end)
  end

  -- =========================================
  -- VENTANA + ANIMACIÓN (rubato)
  -- =========================================
  local win = wibox {
    screen  = s,
    type    = "dock",
    ontop   = true,
    visible = false,
    bg      = "#00000000",
    x       = fx,
    y       = fy,
    width   = 1,
    height  = h,
  }

  -- Animación copiada de AlphaTechnolog/dotfiles (ui/dashboard/init.lua):
-- el ancho de la ventana crece de 1 a w con rubato; mientras anima se muestra
-- un fondo vacío y el contenido real solo cuando está casi abierto.
  local null_widget = ui.box(wibox.widget { markup = "", widget = wibox.widget.textbox },
                             { bg = C.bg, radius = 20 })
  local stop_offset = CFG.w - 5
  local showing = null_widget
  win.widget = null_widget

  local is_open, status = false, "undefined"
  local a
  a = anim.new {
    duration = CFG.dur,
    pos      = 0,
    on_update = function(v)
      if status == "undefined" then return end
      if v > 0 then
        local w = math.max(1, math.floor(v + 0.5))
        if w ~= win.width then win.width = w end
        local want = (v <= stop_offset) and null_widget or root
        if want ~= showing then showing = want; win.widget = want end
      end
      if status == "closing" and (v < 1 or not a:running()) then
        win.visible = false
        status = "undefined"
        stop_pollers()
      end
    end,
  }

  function self.open()
    if is_open then return end
    is_open = true
    status = "opening"
    win.visible = true
    start_pollers()
    a:set(CFG.w)
  end

  function self.close()
    if not is_open then return end
    is_open = false
    status = "closing"
    a:set(0)
  end

  function self.toggle()
    if is_open then self.close() else self.open() end
  end

  function self.is_open() return is_open end
  self.wibox = win

  return self
end

return M
