-- menu2/init.lua
-- Port a Lua de menu2.yuck (indicadores de apps abiertas).
--
-- yuck: 280x210 · anchor center · x -885px · y 160px
-- scss: .menu-box -> fondo #090E20, radio 15, padding 5 (siempre visible)
-- Fila 1: terminal, thunar, firefox, audacious, flameshot   (spacing 20)
-- Fila 2: notificación, scrcpy                              (spacing 20)
-- Entre filas: spacing 20. Iconos de 34px, cada uno con su color.
--
-- En eww las variables show_* las prendían scripts externos (update_icons.sh, etc.).
-- Acá se calculan solas:
--   term/thunar/firefox/audacious -> mirando los clientes de Awesome (manage/unmanage)
--   scrcpy                        -> pgrep cada 1 s, SOLO mientras el menú está abierto
--   flameshot / notif             -> M.flash("flameshot") / M.flash("notif") los prende 3 s
--
-- Uso:  require("menu2").toggle()

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local ui    = require("lib.ui")
local G     = require("lib.glyph")
local C     = ui.c

local M = {}

local CFG = {
  w = 280, h = 210,
  dx = -885, dy = 160,
  icon_px = 34,
  gap = 20,
  pad = 5,                -- .menu-box padding
  radius = 15,            -- .menu-box border-radius
  bg = "#090E20",         -- .menu-box background-color
  flash_secs = 3,
}

-- key, codepoint, color  (mismos glifos y colores que el yuck)
local ICONS = {
  row1 = {
    { "term",      0xF489,  "#a8e8c0" },
    { "thunar",    0xF0770, "#f2d68f" },
    { "firefox",   0xF0239, "#ff9e64" },
    { "audacious", 0xF075A, "#c678dd" },
    { "flameshot", 0xF0E51, "#ed6a7f" },
  },
  row2 = {
    { "notif",  0xF009A, "#61afef" },
    { "scrcpy", 0xF0EC3, "#ff5555" },
  },
}

-- patrones (en minúscula) para reconocer cada app entre los clientes
local MATCH = {
  term      = { "xfce4%-terminal" },
  thunar    = { "thunar" },
  firefox   = { "firefox", "navigator" },
  audacious = { "audacious" },
}

local state = { term = false, thunar = false, firefox = false, audacious = false,
                flameshot = false, notif = false, scrcpy = false }

local win, row1, row2, labels, scrcpy_timer
local flash_timers = {}

-- =========================================
-- DIBUJO
-- =========================================
local function rebuild()
  if not win then return end
  local function fill(row, list)
    local kids = {}
    for _, ic in ipairs(list) do
      if state[ic[1]] then kids[#kids + 1] = labels[ic[1]] end
    end
    row:set_children(kids)
  end
  fill(row1, ICONS.row1)
  fill(row2, ICONS.row2)
end

local function set(key, value)
  value = value and true or false
  if state[key] == value then return end
  state[key] = value
  rebuild()
end

-- =========================================
-- DETECCIÓN
-- =========================================
local function scan_clients()
  local found = { term = false, thunar = false, firefox = false, audacious = false }
  for _, c in ipairs(client.get()) do
    local hay = ((c.class or "") .. " " .. (c.instance or "")):lower()
    for key, pats in pairs(MATCH) do
      for _, p in ipairs(pats) do
        if hay:find(p) then found[key] = true end
      end
    end
  end
  for key, v in pairs(found) do state[key] = v end
  rebuild()
end

local function poll_scrcpy()
  awful.spawn.easy_async_with_shell("pgrep scrcpy > /dev/null && echo true || echo false", function(out)
    set("scrcpy", (out or ""):match("true") ~= nil)
  end)
end

-- =========================================
-- CONSTRUCCIÓN
-- =========================================
local function build()
  labels = {}
  local function make_row(list)
    for _, ic in ipairs(list) do
      labels[ic[1]] = (ui.label { text = G.char(ic[2]), size = CFG.icon_px, color = ic[3],
                                  family = ui.mono, box = 36,
                                  halign = "center", valign = "center" })   -- font-family del :style del yuck
    end
    return wibox.widget { spacing = CFG.gap, layout = wibox.layout.fixed.horizontal }
  end
  row1 = make_row(ICONS.row1)
  row2 = make_row(ICONS.row2)

  local content = wibox.widget {
    row1, row2,
    spacing = CFG.gap,       -- spacing 20 entre la fila 1 y la 2
    layout  = wibox.layout.fixed.vertical,
  }

  win = wibox {
    type    = "dock",
    ontop   = true,
    visible = false,
    width   = CFG.w,
    height  = CFG.h,
    bg      = "#00000000",
    widget  = ui.box(content, { bg = CFG.bg, radius = CFG.radius,
                                pad = { CFG.pad, CFG.pad, CFG.pad, CFG.pad } }),
  }

  -- 1 s como el defpoll del yuck, pero solo con el menú a la vista
  scrcpy_timer = gears.timer { timeout = 1, call_now = false, autostart = false, callback = poll_scrcpy }

  rebuild()
end

-- Mantiene los iconos de apps al día aunque el menú esté cerrado (es barato: solo recorre clientes)
client.connect_signal("manage",   function() if win and win.visible then scan_clients() end end)
client.connect_signal("unmanage", function() if win and win.visible then
  -- el cliente que se va todavía figura en client.get() dentro de "unmanage"
  gears.timer.delayed_call(scan_clients)
end end)

-- =========================================
-- API
-- =========================================
function M.show()
  if not win then build() end
  local s = awful.screen.focused()
  -- y: donde estaba (dy del yuck). x: solo la separación con la barra, igual que dashboard y date1
  local _, y = G.center_xy(s, CFG.w, CFG.h, CFG.dx, CFG.dy)
  local x    = G.beside_bar(s, CFG.w, CFG.h)
  win.x, win.y = x, y
  scan_clients()
  poll_scrcpy()
  win.visible = true
  scrcpy_timer:start()
end

function M.hide()
  if not win then return end
  win.visible = false
  scrcpy_timer:stop()
end

function M.toggle()
  if win and win.visible then M.hide() else M.show() end
end

-- Prende un icono unos segundos (equivale a: eww update show_flameshot=true; sleep 3; ...=false)
--   require("menu2").flash("flameshot")      require("menu2").flash("notif", 5)
function M.flash(key, secs)
  if state[key] == nil then return end
  set(key, true)
  if flash_timers[key] then flash_timers[key]:stop() end
  flash_timers[key] = gears.timer.start_new(secs or CFG.flash_secs, function()
    set(key, false)
    flash_timers[key] = nil
    return false
  end)
end

-- Control manual: require("menu2").set("notif", true)
function M.set(key, value)
  if state[key] ~= nil then set(key, value) end
end

return M
