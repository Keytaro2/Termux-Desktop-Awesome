-- menu1/init.lua
-- Port a Lua de menu1.yuck + menu1.scss (menú contextual del clic derecho + submenú AwesomeWM).
--
-- yuck: menu1 280x340 (anchor top left, se abre donde hiciste clic)
--       menu1_5 280x240 (submenú, se abre al tocar "AwesomeWM ►")
-- scss: .menu       -> fondo #090E20, radio 10, padding 25
--       .menu-item  -> letra 20px, padding 10, radio 60 (píldora), hover rgba(192,202,245,.08)
--       .menu-label -> margin-left -100  (el texto queda corrido 50px a la izquierda del centro)
--       .bspwm-label margin-left 15 · .arrow margin-left 30 + 22px · .menu-label-1-5 margin-left 15
--
-- Uso (rc.lua ya lo llama así):
--   require("menu1").show(x, y)     -- clic derecho en el escritorio
--   require("menu1").hide()         -- clic izquierdo en el escritorio

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local ui    = require("lib.ui")
local G     = require("lib.glyph")
local C     = ui.c

local M = {}

local CFG = {
  w = 280, h = 340,        -- menu1
  sw = 280, sh = 240,      -- menu1_5
  bg = "#090E20",
  radius = 10,
  pad = 25,                -- .menu padding
  item_px = 20,            -- .menu-item font-size
  item_pad = 10,           -- .menu-item padding (10px 10px)
  fg = "#c0caf5",
  hover = "#c0caf514",     -- rgba(192, 202, 245, 0.08)
  label_shift = 100,       -- .menu-label { margin-left: -100px } -> centro corrido 50px a la izquierda
  bspwm_ml = 15,           -- .bspwm-label
  arrow_ml = 30,           -- .arrow
  arrow_px = 22,
  sub_ml = 15,             -- .menu-label-1-5
}

local main, sub
local sub_open = false
local mx, my = 0, 0

-- =========================================
-- ÍTEMS
-- =========================================
-- botón con forma de píldora y hover (transition de 200ms no se replica)
local function pill(content, fn)
  local box = ui.box(ui.margin(content, CFG.item_pad, CFG.item_pad, CFG.item_pad, CFG.item_pad),
                     { shape = gears.shape.rounded_bar })
  box:connect_signal("mouse::enter", function() box.bg = CFG.hover end)
  box:connect_signal("mouse::leave", function() box.bg = nil end)
  return ui.clickable(box, fn)
end

local function lbl(text, extra)
  extra = extra or {}
  return (ui.label { text = text, size = CFG.item_px, color = CFG.fg,
                     halign = extra.halign or "left", valign = "center" })
end

-- menu-item: la etiqueta va centrada, pero corrida 50px a la izquierda (margin-left: -100px)
local function item(text, fn)
  local l = lbl(text, { halign = "center" })
  return pill(ui.margin(l, 0, CFG.label_shift, 0, 0), fn)
end

-- awesome-item: "AwesomeWM" + flecha pegados a la izquierda (el box no reparte espacio)
local function awesome_item(fn)
  local l = lbl("AwesomeWM")
  local a = (ui.label { text = G.char(0x25BA), size = CFG.arrow_px, color = CFG.fg,
                        halign = "left", valign = "center" })
  local row = wibox.widget {
    ui.margin(l, 0, 0, 0, CFG.bspwm_ml),
    ui.margin(a, 0, 0, 0, CFG.arrow_ml),
    layout = wibox.layout.fixed.horizontal,
  }
  return pill(row, fn)
end

-- ítems del submenú (menu-item-1-5): texto a la izquierda con margin-left 15
local function item_sub(text, fn)
  return pill(ui.margin(lbl(text), 0, 0, 0, CFG.sub_ml), fn)
end

-- space-evenly de eww: todos los ítems reparten el alto por igual
local function column(items)
  local col = wibox.widget { layout = wibox.layout.flex.vertical }
  for _, it in ipairs(items) do col:add(it) end
  return col
end

local function panel(content, w, h)
  return wibox {
    type    = "dock",
    ontop   = true,
    visible = false,
    width   = w,
    height  = h,
    bg      = "#00000000",
    widget  = ui.box(content, { bg = CFG.bg, radius = CFG.radius,
                                pad = { CFG.pad, CFG.pad, CFG.pad, CFG.pad } }),
  }
end

-- =========================================
-- ACCIONES (mismos comandos que el yuck)
-- =========================================
local function run(cmd)
  return function()
    M.hide()
    awful.spawn.with_shell(cmd .. " &")
  end
end

local function lua_do(fn)
  return function()
    M.hide()
    fn()
  end
end

-- =========================================
-- CONSTRUCCIÓN
-- =========================================
local function build()
  -- menu1_5: submenú de AwesomeWM
  sub = panel(column {
    item_sub("Edit Config",       run("kitty -e nvim ~/.config/awesome/rc.lua")),
    item_sub("Edit Config (GUI)", run("mousepad ~/.config/awesome/rc.lua")),
    item_sub("Restart",           lua_do(function() awesome.restart() end)),
    item_sub("Close Session",     lua_do(function() awesome.quit() end)),
  }, CFG.sw, CFG.sh)

  local function toggle_sub()
    if sub_open then
      sub.visible = false
      sub_open = false
      return
    end
    local s = awful.screen.focused()
    -- el submenú nace pegado a la derecha del menú, alineado con el ítem "AwesomeWM" (el 6º)
    local sx = mx + CFG.w
    local sy = my + math.floor(CFG.h * 5 / 6)
    if sx + CFG.sw > s.geometry.x + s.geometry.width then sx = mx - CFG.sw end  -- no se sale por la derecha
    sub.x, sub.y = G.clamp_xy(s, sx, sy, CFG.sw, CFG.sh)
    sub.visible = true
    sub_open = true
  end

  -- menu1: menú principal ("Editor   " lleva espacios a propósito, igual que el yuck)
  main = panel(column {
    item("Terminal",   run("xfce4-terminal --hide-menubar")),
    item("Explorer",   run("thunar")),
    item("Browser",    run("firefox")),
    item("Editor   ",  run("kitty -e nvim")),
    item("GUI Edit",   run("mousepad")),
    awesome_item(toggle_sub),
  }, CFG.w, CFG.h)
end

-- =========================================
-- API
-- =========================================
function M.hide()
  if sub then sub.visible = false end
  if main then main.visible = false end
  sub_open = false
end

function M.show(x, y)
  if not main then build() end
  local s = awful.screen.focused()
  local c = mouse.coords()
  mx, my = G.clamp_xy(s, x or c.x, y or c.y, CFG.w, CFG.h)
  -- como en el rc.lua original: antes de abrir, cierra el submenú
  if sub then sub.visible = false end
  sub_open = false
  main.x, main.y = mx, my
  main.visible = true
end

function M.toggle()
  if main and main.visible then M.hide() else M.show() end
end

return M
