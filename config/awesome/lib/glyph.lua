-- lib/glyph.lua
-- Utilidades chicas compartidas por date1, menu1, menu2, powermenu y screnshoot.
--
--   G.char(0xF489)  -> el caracter UTF-8 de ese codepoint (sirve en Lua 5.1/5.3/5.4/LuaJIT).
--                      Los iconos Nerd Font usan codepoints privados que se pierden al
--                      copiar/pegar; así quedan escritos como número y no se rompen.
--   G.center_xy(s, w, h, dx, dy) -> x, y de una ventana w*h centrada en la pantalla s
--                      y desplazada (dx, dy): es el  :anchor "center" :x :y  de eww.

local M = {}

function M.char(cp)
  if utf8 and utf8.char then return utf8.char(cp) end
  if cp < 0x80 then
    return string.char(cp)
  elseif cp < 0x800 then
    return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
  elseif cp < 0x10000 then
    return string.char(0xE0 + math.floor(cp / 0x1000),
                       0x80 + math.floor(cp / 0x40) % 0x40,
                       0x80 + cp % 0x40)
  end
  return string.char(0xF0 + math.floor(cp / 0x40000),
                     0x80 + math.floor(cp / 0x1000) % 0x40,
                     0x80 + math.floor(cp / 0x40) % 0x40,
                     0x80 + cp % 0x40)
end

function M.center_xy(s, w, h, dx, dy)
  local g = s.geometry
  return math.floor(g.x + (g.width - w) / 2 + (dx or 0)),
         math.floor(g.y + (g.height - h) / 2 + (dy or 0))
end

-- Ventana w*h pegada a la barra por la derecha y con el borde de abajo alineado con el de la
-- barra (igual que el dashboard en x y que el calendario). Valores de la barra: x 20, ancho 90,
-- alto 97 %. gap = separación con la barra (10 = la del dashboard, x 120).
M.BAR = { x = 20, w = 90, pct = 0.97, gap = 10 }
function M.beside_bar(s, w, h)
  local g = s.geometry
  local bar_h = math.floor(g.height * M.BAR.pct)
  local bottom = g.y + math.floor((g.height - bar_h) / 2) + bar_h
  return g.x + M.BAR.x + M.BAR.w + M.BAR.gap, bottom - h
end

-- Mantiene (x, y) dentro de la pantalla s para una ventana w*h
function M.clamp_xy(s, x, y, w, h)
  local g = s.geometry
  x = math.max(g.x, math.min(x, g.x + g.width - w))
  y = math.max(g.y, math.min(y, g.y + g.height - h))
  return math.floor(x), math.floor(y)
end

return M
