-- notifications/init.lua
-- Port a Lua de Notifications/eww.yuck (panel + popups) con animaciones rubato.
--
-- API:
--   local N = require("notifications")
--   N.init()                          -- una vez, desde rc.lua
--   N.notify { app=, title=, body=, image=, kind=, store= }
--   N.launching("terminal")           -- reemplaza logger.sh 'Launchers' ...
--   N.screenshot_ready(file)          -- popup con botones Copy / Delete
--   N.toggle_panel() / open_panel() / close_panel()

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local ui    = require("lib.ui")
local I     = require("lib.icons")
local anim  = require("lib.anim")
local C     = ui.c

local M = {}

-- =========================================
-- CONFIG (mismas medidas que el .yuck)
-- =========================================
local CFG = {
  popup_w       = 380,   -- :width "380px"
  popup_margin  = 20,    -- :x "-20px"
  popup_y       = 15,    -- :y "15px"
  music_cover   = 160,   -- carátula de la tarjeta de música (antes 100): más grande, como la referencia
  panel_w       = 500,   -- :width "500px"
  panel_h_pct   = 0.97,  -- :height "97%"

  -- Animaciones (rubato)
  popup_dur     = 0.35,  -- segundos (rubato como notifcenter del repo, sin fade)
  panel_dur     = 0.35,

  popup_time         = 4,   -- segundos visible (popups simples)
  popup_time_actions = 6,   -- popups con botones (Copy/Delete, Previous/Next)
  removed_delay      = 1.2, -- cuánto se ve "Notification removed successfully"
  drag_step          = 90,  -- px de arrastre (touch) por cada tarjeta
}

local scripts_dir = ui.dir .. "scripts/"

-- =========================================
-- ESTADO
-- =========================================
local list    = {}   -- notificaciones del panel (la más nueva primero)
local next_id = 1
local first   = 1    -- primera tarjeta visible (scroll)

local panel, panel_anim, panel_target, panel_closed_x
local list_layout
local pop            -- popup actual { popup, anim, timer }

local function primary()
  return screen.primary or screen[1]
end

local function q(s)
  return "'" .. (tostring(s):gsub("'", "'\\''")) .. "'"
end

local function file_exists(p)
  local f = io.open(p, "r")
  if f then f:close() return true end
  return false
end

-- =========================================
-- PIEZAS COMUNES
-- =========================================
-- clickable SIN mano en las notificaciones
local function click(w, fn) return ui.clickable(w, fn, true) end

local function pill_button(text, fn)
  local lbl = ui.label { text = text, size = 14, bold = true, halign = "center", color = C.fg }
  return click(
    ui.box(lbl, { bg = C.btn_bg, radius = 20, pad = { 8, 8, 8, 8 }, border = 1, border_color = C.btn }),
    fn)
end

local function separator()
  return wibox.widget { forced_height = 1, bg = C.fg, widget = wibox.container.background }
end

-- =========================================
-- ACCIONES
-- =========================================
local show_popup -- forward

-- Log de errores de los avisos (por si algo falla en silencio):  cat ~/.cache/awesome-notify.log
local LOG = (os.getenv("HOME") or "") .. "/.cache/awesome-notify.log"
local function log(msg)
  local f = io.open(LOG, "a")
  if f then
    f:write(os.date("%F %T "), tostring(msg), "\n")
    f:close()
  end
end

-- Aviso de confirmación (copied / removed): MISMA ruta que "Launching!" (M.notify normal:
-- popup + tarjeta en el panel, app "Screenshot", título "Screenshot"). Se dispara PRIMERO y
-- en el mismo clic, igual que  notifs.launching(...)  seguido de awful.spawn(...).
local function confirm(body)
  local ok, err = pcall(M.notify, { app = "Screenshot", title = "Screenshot", body = body })
  if not ok then
    log("confirm(" .. body .. "): " .. tostring(err))
    -- plan B: por la cola externa (logger.sh), como hacía eww
    awful.spawn.with_shell("bash " .. q(scripts_dir .. "logger.sh") ..
                           " Screenshot Screenshot " .. q(body))
  end
end

local function do_screenshot_copy(file)
  log("clic en Copy: " .. tostring(file))
  confirm("Screenshot copied successfully.")

  -- la copia real corre aparte y sin esperar: el aviso ya salió
  if file and file ~= "" and file_exists(file) then
    local script = scripts_dir .. "screenshot_actions.sh"
    local cmd
    if file_exists(script) then
      cmd = "timeout 4 bash " .. q(script) .. " copy " .. q(file)
    else
      cmd = "(xclip -selection clipboard -t image/png -i " .. q(file) ..
            " || wl-copy < " .. q(file) .. ") 2>/dev/null"
    end
    awful.spawn.with_shell(cmd)
  end
end

-- Delete es SOLO VISUAL: muestra el aviso pero NO borra la captura.
local function do_screenshot_delete(file)
  log("clic en Delete (solo aviso, no borra): " .. tostring(file))
  confirm("Screenshot removed successfully.")
end

-- =========================================
-- POPUPS
-- =========================================
local function hide_popup(instant)
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
    ui.margin(header, 0, 0, 12, 0),
    ui.margin(separator(), 0, 0, 18, 0),
    ui.margin(info, 0, 0, has_actions and 22 or 10, 0),
    layout = wibox.layout.fixed.vertical,
  }
  -- click en la parte de texto = cerrar (como el eventbox del original)
  top:buttons(gears.table.join(awful.button({}, 1, close)))

  local content
  if spec.kind == "screenshot" then
    local file = spec.image
    content = wibox.widget {
      top,
      {
        pill_button("Copy",   function() do_screenshot_copy(file) end),
        pill_button("Delete", function() do_screenshot_delete(file) end),
        spacing = 15, layout = wibox.layout.flex.horizontal,
      },
      layout = wibox.layout.fixed.vertical,
    }
  elseif spec.kind == "music" then
    content = wibox.widget {
      top,
      {
        pill_button("Previous", function() awful.spawn.with_shell("audtool playlist-reverse") end),
        pill_button("Next",     function() awful.spawn.with_shell("audtool playlist-advance") end),
        spacing = 15, layout = wibox.layout.flex.horizontal,
      },
      layout = wibox.layout.fixed.vertical,
    }
  else
    content = top
  end

  return ui.box(content, {
    bg = C.bg, radius = 24, pad = { 15, 20, 15, 20 },
    border = 1, border_color = C.border,
  }), has_actions
end

show_popup = function(spec)
  hide_popup(true)

  local s  = primary()
  local g  = s.geometry
  local fx = g.x + g.width - CFG.popup_margin - CFG.popup_w
  local fy = g.y + CFG.popup_y

  local cur = {}
  local function close() hide_popup(false) end

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
  cur.closed_x = g.x + g.width   -- fuera de pantalla, a la derecha

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
    callback    = function() if pop == cur then hide_popup(false) end end,
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
-- PANEL: TARJETAS
-- =========================================
local function build_item(item)
  -- Estado "removed": tarjeta compacta
  if item.removed then
    local row = wibox.widget {
      ui.label { text = I.notif, size = 20, color = C.blue, box = 26, halign = "center" },
      ui.label { text = "Notification removed successfully", size = 16, bold = true },
      spacing = 12, layout = wibox.layout.fixed.horizontal,
    }
    -- tarjeta delgada: antes 68 px de alto (pad 16 + icono 36); ahora ~42 px
    return ui.margin(
      ui.box(row, { bg = C.card2, radius = 16, pad = { 8, 16, 8, 16 } }), 0, 0, 8, 0)
  end

  -- Cabecera
  local app = ui.label { text = item.app, size = 22, bold = true, halign = "left" }
  local del = click(
    ui.label { text = I.trash, size = 20, color = C.red, halign = "right", box = 30 },
    function() M.remove(item.id) end)
  local header = ui.box(
    wibox.widget { first = app, third = del, layout = wibox.layout.align.horizontal },
    { bg = C.card2, radius = { 20, 20, 0, 0 }, pad = { 12, 18, 12, 18 } })

  -- Cuerpo
  local body
  local is_music = (item.app == "Music" or item.app == "Audacious")
  local has_img  = item.image and item.image ~= "" and item.image ~= "null"

  if is_music then
    item._cover = item._cover or ui.image(item.image, CFG.music_cover, CFG.music_cover, ui.rrect(14))
    local texts = wibox.widget {
      ui.label { text = item.title, size = 28, bold = true, halign = "center", wrap = true },
      ui.label { text = item.body,  size = 20, halign = "center", wrap = true },
      spacing = 6, layout = wibox.layout.fixed.vertical,
    }
    body = wibox.widget {
      first = item._cover,
      second = ui.margin(ui.center(texts), 0, 0, 0, 20),
      layout = wibox.layout.align.horizontal,
    }
  elseif has_img then
    -- ancho útil: panel 500 - padding panel 24 - padding tarjeta 30 = 446
    item._big = item._big or ui.image(item.image, 446, 220, ui.rrect(12))
    body = wibox.widget {
      ui.margin(item._big, 0, 0, 5, 0),
      {
        ui.label { text = item.title, size = 28, bold = true, halign = "center", wrap = true },
        ui.label { text = item.body,  size = 16, halign = "center", wrap = true },
        spacing = 3, layout = wibox.layout.fixed.vertical,
      },
      spacing = 10, layout = wibox.layout.fixed.vertical,
    }
  else
    local ic = ui.label { text = I.notif, size = 45, color = C.blue, halign = "center", box = 64 }
    -- texto CENTRADO en el espacio que queda a la derecha del icono
    -- (Copy / Remove / Launching, como en banner.png)
    local texts = wibox.widget {
      ui.label { text = item.title, size = 22, bold = true, halign = "center", wrap = true },
      ui.label { text = item.body,  size = 16, halign = "center", wrap = true },
      spacing = 6, layout = wibox.layout.fixed.vertical,
    }
    body = wibox.widget {
      first = ui.margin(ic, 0, 15, 0, 0),
      second = wibox.widget { texts, halign = "center", valign = "center", widget = wibox.container.place },
      layout = wibox.layout.align.horizontal,
    }
  end

  local card_body = ui.box(body, { bg = C.card, radius = { 0, 0, 20, 20 }, pad = { 15, 15, 15, 15 } })

  return ui.margin(
    ui.box(wibox.widget { header, card_body, layout = wibox.layout.fixed.vertical },
           { bg = C.card2, radius = 20 }),
    0, 0, 8, 0)
end

local function rebuild()
  if not list_layout then return end
  if first > #list then first = math.max(1, #list) end
  list_layout:reset()
  for i = first, #list do
    list_layout:add(build_item(list[i]))
  end
end

function M.remove(id)
  for _, it in ipairs(list) do
    if it.id == id and not it.removed then
      it.removed = true
      rebuild()
      gears.timer.start_new(CFG.removed_delay, function()
        for i, x in ipairs(list) do
          if x.id == id then table.remove(list, i) break end
        end
        rebuild()
        return false
      end)
      return
    end
  end
end

function M.clear()
  list = {}
  first = 1
  rebuild()
end

-- =========================================
-- API: NOTIFICAR
-- =========================================
-- Prende un icono del menu2 durante unos segundos (si el módulo existe)
local function flash_icon(key)
  local ok, m2 = pcall(require, "menu2")
  if ok and type(m2) == "table" and m2.flash then pcall(m2.flash, key) end
end

function M.notify(n)
  local item = {
    id    = next_id,
    app   = tostring(n.app or "System"),
    title = tostring(n.title or "Notification"),
    body  = tostring(n.body or n.message or ""),
    image = n.image or "",
  }
  next_id = next_id + 1

  if n.store ~= false then
    table.insert(list, 1, item)
    first = 1
    rebuild()
  end

  if n.popup ~= false then
    flash_icon("notif")
    if n.kind == "screenshot" then
      flash_icon("flameshot")
      show_popup { kind = "screenshot", header = "Screenshot",
                   title = item.title, body = item.body, image = item.image }
    elseif item.app == "Music" or item.app == "Audacious" then
      show_popup { kind = "music", header = "Music",
                   title = item.title, body = item.body, cover = item.image }
    else
      show_popup { kind = "plain", header = item.app,
                   title = item.title, body = item.body }
    end
  end
  return item.id
end

-- Reemplazo de: logger.sh 'Launchers' 'Launching!' 'Launching <x>, please wait...'
function M.launching(what)
  M.notify {
    app = "Launchers", title = "Launching!",
    body = "Launching " .. what .. ", please wait...",
  }
end

-- Reemplazo de: logger.sh 'Screenshot' 'Screenshot Is Ready!' 'Screenshot saved successfully' $FILE
function M.screenshot_ready(file)
  M.notify {
    app = "Screenshot", title = "Screenshot Is Ready!",
    body = "Screenshot saved successfully", image = file, kind = "screenshot",
  }
end

-- =========================================
-- PANEL: VENTANA
-- =========================================
local function panel_geometry()
  local g = primary().geometry
  local h = math.floor(g.height * CFG.panel_h_pct)
  return {
    x = g.x + g.width - CFG.popup_margin - CFG.panel_w,
    y = g.y + CFG.popup_y,
    w = CFG.panel_w,
    h = h,
  }
end

local function build_panel()
  local geo = panel_geometry()
  local sg  = primary().geometry
  panel_closed_x = sg.x + sg.width

  list_layout = wibox.widget { spacing = 8, layout = wibox.layout.fixed.vertical }

  -- Scroll: rueda del mouse o arrastre con el dedo (por tarjetas)
  local scroll = wibox.widget { list_layout, widget = wibox.container.background }
  scroll:buttons(gears.table.join(
    awful.button({}, 4, function()
      if first > 1 then first = first - 1; rebuild() end
    end),
    awful.button({}, 5, function()
      if first < #list then first = first + 1; rebuild() end
    end)
  ))
  local drag = { on = false, y0 = 0, f0 = 1 }
  scroll:connect_signal("button::press", function(_, _, _, b)
    if b == 1 then
      drag.on, drag.y0, drag.f0 = true, mouse.coords().y, first
    end
  end)
  scroll:connect_signal("button::release", function() drag.on = false end)
  scroll:connect_signal("mouse::leave", function() drag.on = false end)
  scroll:connect_signal("mouse::move", function()
    if not drag.on then return end
    local steps = math.floor((drag.y0 - mouse.coords().y) / CFG.drag_step)
    local nf = math.max(1, math.min(math.max(1, #list), drag.f0 + steps))
    if nf ~= first then first = nf; rebuild() end
  end)

  local title = ui.label { text = "Notifications", size = 34, bold = true,
                           halign = "center", valign = "top" }

  local content = ui.box(
    wibox.widget {
      first  = ui.margin(title, 0, 0, 5, 0),
      second = scroll,
      layout = wibox.layout.align.vertical,
    },
    { bg = C.bg, radius = 24, pad = { 12, 12, 12, 12 } })

  panel = wibox {
    screen  = primary(),
    type    = "dock",
    ontop   = true,
    visible = false,
    bg      = "#00000000",
    x = panel_closed_x, y = geo.y,
    width = geo.w, height = geo.h,
  }
  panel.widget = content

  panel_anim = anim.new {
    duration = CFG.panel_dur,
    pos      = panel_closed_x,
    on_update = function(x)
      if not panel then return end
      panel.x = math.floor(x + 0.5)
      if panel_target == 0 and x >= panel_closed_x - 0.5 then
        panel.visible = false
      end
    end,
  }
end

function M.open_panel()
  if not panel then return end
  local geo = panel_geometry()
  panel.y, panel.height = geo.y, geo.h
  first = 1
  rebuild()
  panel.visible = true
  panel_target = 1
  panel_anim:set(geo.x)
end

function M.close_panel()
  if not panel then return end
  panel_target = 0
  panel_anim:set(panel_closed_x)
end

function M.toggle_panel()
  if panel_target == 1 then M.close_panel() else M.open_panel() end
end

-- =========================================
-- COLA DE AVISOS EXTERNOS (scripts -> popup), sin awesome-client ni dbus
-- logger.sh agrega una línea a ~/.cache/awesome-notify.queue:
--     app<TAB>titulo<TAB>mensaje<TAB>imagen
-- y aquí la leemos con `tail -F` (sin polling, no gasta nada en reposo).
-- =========================================
local QUEUE = (os.getenv("HOME") or "") .. "/.cache/awesome-notify.queue"
local PIDF  = QUEUE .. ".pid"

local function handle_queue_line(line)
  local app, title, body, image = line:match("^(.-)\t(.-)\t(.-)\t(.*)$")
  if not app then return end
  if app == "Screenshot" and image ~= "" then
    M.screenshot_ready(image)
  else
    M.notify {
      app   = app ~= "" and app or "System",
      title = title,
      body  = body,
      image = image,
    }
  end
end

local function watch_queue()
  -- mata el tail de un awesome anterior (reinicio con Alt+r), vacía la cola y escucha
  local cmd = table.concat({
    "mkdir -p \"$(dirname " .. q(QUEUE) .. ")\"",
    "if [ -f " .. q(PIDF) .. " ]; then o=$(cat " .. q(PIDF) .. "); " ..
      "grep -aq awesome-notify.queue /proc/$o/cmdline 2>/dev/null && kill $o 2>/dev/null; fi",
    ": > " .. q(QUEUE),
    "echo $$ > " .. q(PIDF),
    "exec tail -n 0 -F " .. q(QUEUE) .. " 2>/dev/null",
  }, "; ")
  awful.spawn.with_line_callback({ "sh", "-c", cmd }, { stdout = handle_queue_line })
end

-- =========================================
-- MÚSICA: avisa cuando cambia la canción (reemplaza watch_music.sh)
-- =========================================
local function watch_music()
  local last, primed = nil, false
  gears.timer {
    timeout   = 3,
    autostart = true,
    call_now  = true,
    callback  = function()
      ui.sh("audtool current-song-tuple-data title 2>/dev/null; echo '|||'; " ..
            "audtool current-song-tuple-data artist 2>/dev/null",
        function(out)
          local title, artist = out:match("^(.-)%s*|||%s*(.-)$")
          title, artist = title or "", artist or ""
          local key = title .. "|" .. artist

          -- primer chequeo: solo memoriza lo que ya sonaba (no avisa al arrancar),
          -- pero si Audacious aún no estaba abierto, la primera canción SÍ avisa.
          if not primed then
            primed = true
            if title ~= "" then last = key end
            return
          end
          if title == "" then last = nil return end
          if key == last then return end
          last = key

          local cover_script = scripts_dir .. "cover.sh"
          local function go(cover)
            M.notify { app = "Music", title = title, body = artist, image = cover or "" }
          end
          if file_exists(cover_script) then
            ui.sh("timeout 4 bash " .. q(cover_script) .. " 2>/dev/null", go)
          else
            go("")
          end
        end)
    end,
  }
end

-- =========================================
-- INIT
-- =========================================
local started = false
function M.init()
  if started then return end
  started = true
  build_panel()
  rebuild()
  watch_queue()
  watch_music()
end

return M
