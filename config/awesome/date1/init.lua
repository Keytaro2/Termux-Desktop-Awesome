-- date1/init.lua
-- Port a Lua de date1.yuck + date1.scss (calendario), armado a mano para que se vea
-- como el GtkCalendar de eww:
--
--   · encabezado propio "Mes Año" (#7aa2f7, bold, spacing 10), sin el encabezado nativo
--   · semana que empieza en domingo, nombres de 3 letras (Sun Mon Tue ...) en #2dd4bf bold
--   · SIEMPRE 6 filas, con los días del mes anterior / siguiente en los huecos
--   · hoy = óvalo #2dd4bf con texto #090E20 (border-radius 50px)
--
-- TAMAÑO / POSICIÓN (como la captura de referencia): ventana de ~270 px de ancho, pegada a la
--   barra por la derecha (7 px de separación) y con su borde de abajo alineado con el de la barra.
--   Semana desde el LUNES, nombres de 2 letras (lu ma mi ju vi sá do) y sin días de otros meses;
--   solo se dibujan las filas que el mes necesita (5 o 6) y la ventana se ajusta a ellas.
-- scss: .cal-box -> fondo #090E20 · calendar -> texto #c0caf5
--
-- Uso:  require("date1").toggle()      (la barra ya lo llama con ui.call)

local awful  = require("awful")
local gears  = require("gears")
local wibox  = require("wibox")
local ui     = require("lib.ui")
local G      = require("lib.glyph")

local M = {}

local CFG = {
  -- posición: a la derecha de la barra, con el borde de abajo a la altura del de la barra
  bar_right = 110,         -- x de la barra (20) + ancho (90): borde derecho de la barra
  gap_x     = 10,          -- separación con la barra (10 = igual que el dashboard, x 120)
  bar_pct   = 0.97,        -- alto de la barra (97 %) para alinear el borde de abajo
  -- tamaño
  cell_w = 35,             -- ancho de cada día  (7 x 35 = 245)
  cell_h = 35,             -- alto de cada fila de días
  wd_h   = 24,             -- alto de la fila de nombres (lu ma mi ...)
  head_h = 24,             -- alto de "Mes Año"
  pad_x  = 12,             -- margen a los lados (ventana = 7*cell_w + 2*pad_x = 269)
  pad_top = 20,            -- margen de arriba
  pad_bottom = 25,         -- margen de abajo
  head_gap = 11,           -- entre "Mes Año" y los nombres de los días
  wd_gap   = 5,            -- entre los nombres y la primera fila
  -- estilo
  bg = "#090E20",          -- .cal-box
  radius = 10,             -- esquinas redondeadas
  accent = "#2dd4bf",      -- nombres de los días y "hoy"
  fg = "#c0caf5",          -- números
  head = "#7aa2f7",        -- "Mes Año"
  px = 13,                 -- tamaño de letra
  family = ui.mono,
  start_sunday = false,    -- false = la semana empieza en lunes (como la captura)
  wd_chars = 2,            -- letras de cada nombre de día (lu, ma, mi...)
}

CFG.w = 7 * CFG.cell_w + 2 * CFG.pad_x   -- 269

local TRANSPARENT = "#00000000"

local win, tick, set_month, set_year
local row_w = {}           -- row_w[1..6] = filas de días (se ocultan las que sobran)
local cells = {}           -- cells[1..42] = { bg = container, tb = textbox }

-- primeras n letras (UTF-8) sin el punto final: "lun." -> "lu", "sáb" -> "sá"
local function first_chars(str, n)
  str = str:gsub("%.$", "")
  local out, count = {}, 0
  for ch in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    count = count + 1
    if count > n then break end
    out[#out + 1] = ch
  end
  return table.concat(out)
end

-- Nombres CORTOS de los días según el idioma del sistema (7 ene 2024 fue domingo)
local function weekday_names()
  local names = {}
  local first = CFG.start_sunday and 0 or 1
  for i = 0, 6 do
    local t = os.time { year = 2024, month = 1, day = 7 + first + i, hour = 12 }
    names[#names + 1] = first_chars(os.date("%a", t), CFG.wd_chars)
  end
  return names
end

local function win_height(rows)
  return CFG.pad_top + CFG.head_h + CFG.head_gap + CFG.wd_h + CFG.wd_gap
       + rows * CFG.cell_h + CFG.pad_bottom
end

-- ventana pegada a la barra, con el borde de abajo alineado con el de la barra
local function place_win(s, rows)
  local g = s.geometry
  local h = win_height(rows)
  local bar_h = math.floor(g.height * CFG.bar_pct)
  local bar_bottom = g.y + math.floor((g.height - bar_h) / 2) + bar_h
  win.width, win.height = CFG.w, h
  win.x = g.x + CFG.bar_right + CFG.gap_x
  win.y = bar_bottom - h
end

local function refresh()
  local now = os.date("*t")
  set_month(os.date("%B"))
  set_year(os.date("%Y"))

  -- día de la semana del 1 del mes (1 = domingo) -> cuántos huecos van antes
  local first = os.date("*t", os.time { year = now.year, month = now.month, day = 1, hour = 12 })
  local offset = CFG.start_sunday and (first.wday - 1) or ((first.wday + 5) % 7)
  -- día 0 del mes siguiente = último día de este mes
  local dim  = os.date("*t", os.time { year = now.year, month = now.month + 1, day = 0, hour = 12 }).day
  local rows = math.ceil((offset + dim) / 7)

  for i = 0, 41 do
    local c = cells[i + 1]
    local day = i - offset + 1
    if day >= 1 and day <= dim then
      local is_today = (day == now.day)
      c.tb.text = tostring(day)
      c.bg.bg   = is_today and CFG.accent or TRANSPARENT   -- calendar:selected
      c.bg.fg   = is_today and CFG.bg or CFG.fg
    else
      c.tb.text = ""          -- huecos de otros meses: vacíos, como en la captura
      c.bg.bg   = TRANSPARENT
    end
  end
  for r = 1, 6 do row_w[r].visible = (r <= rows) end

  if win then place_win(awful.screen.focused(), rows) end
end

local function build()
  local month_l, set_m = ui.label { text = "", size = CFG.px, bold = true,
                                    color = CFG.head, family = CFG.family, halign = "center" }
  local year_l,  set_y = ui.label { text = "", size = CFG.px, bold = true,
                                    color = CFG.head, family = CFG.family, halign = "center" }
  set_month, set_year = set_m, set_y

  local header = wibox.widget {
    month_l, year_l,
    spacing = 10,                       -- :spacing 10 del yuck
    layout  = wibox.layout.fixed.horizontal,
  }

  -- fila de nombres de los días (calendar.highlight: #2dd4bf bold)
  local wd_row = wibox.widget { layout = wibox.layout.fixed.horizontal }
  for _, name in ipairs(weekday_names()) do
    wd_row:add(wibox.widget {
      {
        text   = name,
        font   = ui.font(CFG.px, true, CFG.family),
        halign = "center", valign = "center", ellipsize = "none",
        widget = wibox.widget.textbox,
      },
      fg            = CFG.accent,
      forced_width  = CFG.cell_w,
      forced_height = CFG.wd_h,
      widget        = wibox.container.background,
    })
  end

  local rows = wibox.widget { layout = wibox.layout.fixed.vertical }
  rows:add(wd_row)
  rows:add(wibox.widget { forced_height = CFG.wd_gap, widget = wibox.container.background })

  -- 6 filas x 7 días
  for r = 0, 5 do
    local row = wibox.widget { layout = wibox.layout.fixed.horizontal }
    for c = 0, 6 do
      local tb = wibox.widget {
        text   = "",
        font   = ui.font(CFG.px, false, CFG.family),
        halign = "center", valign = "center", ellipsize = "none",
        widget = wibox.widget.textbox,
      }
      local bg = wibox.widget {
        tb,
        bg            = TRANSPARENT,
        fg            = CFG.fg,
        shape         = gears.shape.rounded_bar,     -- border-radius: 50px
        forced_width  = CFG.cell_w,
        forced_height = CFG.cell_h,
        widget        = wibox.container.background,
      }
      cells[r * 7 + c + 1] = { bg = bg, tb = tb }
      row:add(bg)
    end
    row_w[r + 1] = row
    rows:add(row)
  end

  local content = wibox.widget {
    { header, forced_height = CFG.head_h, halign = "center", valign = "center",
      widget = wibox.container.place },
    { { rows, halign = "center", valign = "top", widget = wibox.container.place },
      top = CFG.head_gap, widget = wibox.container.margin },
    layout = wibox.layout.fixed.vertical,
  }

  win = wibox {
    type    = "dock",
    ontop   = true,
    visible = false,
    width   = CFG.w,
    height  = win_height(6),
    bg      = "#00000000",
    widget  = ui.box(content, { bg = CFG.bg, radius = CFG.radius,
                                pad = { CFG.pad_top, CFG.pad_x, CFG.pad_bottom, CFG.pad_x } }),
  }

  -- eww hacía defpoll cada 10 s; acá solo corre mientras el calendario está abierto
  tick = gears.timer { timeout = 10, call_now = false, autostart = false, callback = refresh }
end

function M.show()
  if not win then build() end
  refresh()               -- también coloca y dimensiona la ventana
  win.visible = true
  tick:start()
end

function M.hide()
  if not win then return end
  win.visible = false
  tick:stop()
end

function M.toggle()
  if win and win.visible then M.hide() else M.show() end
end

return M
