-- rc.lua for AwesomeWM on Termux X11
-- Compatible with: picom, feh, rofi, xfce4-terminal  (sin eww: bar, dashboard1 y
-- notifications ahora son módulos Lua con animaciones rubato)

-- =========================================
-- LIBRARIES
-- =========================================
local gears = require("gears")
awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
local wibox = require("wibox")
local naughty = require("naughty")
local notifs = require("notifications")

-- =========================================
-- CURSOR POR DEFECTO: Bibata-Material-Cloud-Light
-- =========================================
-- Copiá la carpeta  Bibata-Material-Cloud-Light  (la que tiene  cursors/  adentro) a
-- ~/.config/awesome/fonts/   (también la encuentra en ~/.config/awesome/ y en
-- ~/.config/awesome-vertical/fonts/).  Si no aparece, usa capitaine-cursors-light como antes.
--
-- Por qué esto va ANTES de todo lo demás: Awesome carga sus propios cursores (los de la barra,
-- el dashboard, los popups...) UNA sola vez al arrancar, leyendo  Xcursor.theme  de xrdb. En el
-- rc.lua anterior el tema se aplicaba después (autostart), y eso solo le llegaba a las apps de
-- afuera: sobre la barra el puntero salía distinto. Acá se deja el tema listo en xrdb y, si
-- Awesome había arrancado con otro, se reinicia UNA vez (antes de lanzar picom, feh, etc.).
local CURSOR = {
    theme        = "Bibata-Material-Cloud-Light",
    fallback     = "capitaine-cursors-light",
    size         = 32,
    restart_once = true,
}

do
    local gfs  = gears.filesystem
    local home = os.getenv("HOME") or ""
    local cfg  = (gfs.get_configuration_dir():gsub("/$", ""))
    local logf = home .. "/.cache/awesome-cursor.log"

    os.execute("mkdir -p " .. "'" .. home .. "/.cache'")
    local function log(msg)
        local f = io.open(logf, "a")
        if f then f:write(os.date("%F %T "), msg, "\n") f:close() end
    end
    local function q(x) return "'" .. tostring(x):gsub("'", "'\\''") .. "'" end
    local function has_theme(parent, name)
        return gfs.dir_readable(parent .. "/" .. name .. "/cursors")
    end

    -- 1) dónde está la carpeta del tema
    local prefix = os.getenv("PREFIX") or "/data/data/com.termux/files/usr"
    local parents = {
        cfg .. "/fonts", cfg, cfg .. "/cursors",
        home .. "/.config/awesome-vertical/fonts",
        home .. "/.icons", home .. "/.local/share/icons", prefix .. "/share/icons",
    }
    local theme, where = CURSOR.fallback, nil
    for _, d in ipairs(parents) do
        if has_theme(d, CURSOR.theme) then theme, where = CURSOR.theme, d break end
    end
    if where then
        -- Xcursor busca en ~/.icons, ~/.local/share/icons y /usr/share/icons: si el tema está en
        -- otra carpeta (la de awesome), se enlaza desde ~/.icons para que TODOS lo encuentren
        local std = (where == home .. "/.icons") or (where == home .. "/.local/share/icons")
                    or (where == prefix .. "/share/icons")
        if not std and not has_theme(home .. "/.icons", theme) then
            os.execute("mkdir -p " .. q(home .. "/.icons") .. " && ln -sfn " ..
                       q(where .. "/" .. theme) .. " " .. q(home .. "/.icons/" .. theme))
            log("enlace ~/.icons/" .. theme .. " -> " .. where .. "/" .. theme)
        end
        log("tema encontrado en " .. where)
    else
        log("no encontré " .. CURSOR.theme .. "; uso " .. CURSOR.fallback)
    end

    -- 2) ~/.Xresources (se conserva lo demás, solo se reemplazan las líneas Xcursor.*)
    local xr = home .. "/.Xresources"
    local keep = {}
    local f = io.open(xr, "r")
    if f then
        for line in f:lines() do
            if not line:match("^%s*Xcursor%.theme") and not line:match("^%s*Xcursor%.size") then
                keep[#keep + 1] = line
            end
        end
        f:close()
    end
    keep[#keep + 1] = "Xcursor.theme: " .. theme
    keep[#keep + 1] = "Xcursor.size: " .. CURSOR.size
    f = io.open(xr, "w")
    if f then f:write(table.concat(keep, "\n"), "\n") f:close() end

    -- 3) ¿con qué tema está arrancando Awesome? (lo que xrdb tiene AHORA)
    local function xrdb_theme()
        local p = io.popen("xrdb -query 2>/dev/null")
        if not p then return nil end
        local out = p:read("*a") or ""
        p:close()
        return out:match("[Xx]cursor%.theme:%s*([^\r\n]-)%s*[\r\n]")
    end
    local before = xrdb_theme()
    if before ~= theme then
        os.execute("xrdb -merge " .. q(xr) .. " 2>/dev/null")
        local after = xrdb_theme()
        log("xrdb: " .. tostring(before) .. " -> " .. tostring(after))
        if CURSOR.restart_once and after == theme then
            log("reinicio único de Awesome para que cargue el cursor " .. theme)
            awesome.restart()
        end
    end

    CURSOR.active = theme
end

-- =========================================
-- HELPER: Rounded corners (terminal, thunar, audacious, firefox)
-- =========================================
-- Estas 4 apps son las únicas que llegan a titlebars_enabled = true (ver RULES
-- más abajo), así que el radio se aplica en el signal "request::titlebars".
-- OJO: c.shape recorta TODA la ventana, titlebar incluido (la barra de los 3
-- botones no es una ventana aparte, así que su propio .shape no hace nada).
-- Por eso el cliente se redondea con las 4 esquinas y así también quedan
-- redondeadas las esquinas izquierdas, que son las de la barra de los 3 botones.
local ROUND_RADIUS = 16

local function shape_rounded(cr, w, h)
    gears.shape.rounded_rect(cr, w, h, ROUND_RADIUS)
end

-- maximizada / pantalla completa: esquinas rectas
local function update_round_shape(c)
    if not c.valid or not c._round_ready then return end
    if c.maximized or c.fullscreen then
        c.shape = gears.shape.rectangle
    else
        c.shape = shape_rounded
    end
end

client.connect_signal("property::maximized", update_round_shape)
client.connect_signal("property::fullscreen", update_round_shape)

-- =========================================
-- HELPER: Identify specific applications ignoring case
-- =========================================
local function is_target_app(c)
    if not c then return false end
    local cls = string.lower(c.class or "")
    local inst = string.lower(c.instance or "")
    return (string.find(cls, "xfce4%-terminal") or
            string.find(cls, "thunar") or
            string.find(cls, "audacious") or
            string.find(cls, "firefox") or
            string.find(inst, "navigator") or
            string.find(cls, "navigator"))
end

-- =========================================
-- Smart function to move windows
-- =========================================
local function smart_move(dx, dy)
    local c = client.focus
    if c and (is_target_app(c) or not lock_mode_enabled) then
        c:relative_move(dx, dy, 0, 0)
    end
end

-- =========================================
-- Smart function to resize windows
-- =========================================
local function smart_resize(dw, dh)
    local c = client.focus
    if c and (is_target_app(c) or not lock_mode_enabled) then
        local g = c:geometry()
        c:geometry({
            x = g.x,
            y = g.y,
            width = math.max(100, g.width + dw),
            height = math.max(100, g.height + dh)
        })
    end
end

-- =========================================
-- VARIABLES
-- =========================================
terminal = "xfce-terminal --hide-menubar"
modkey = "Mod4"

-- =========================================
-- THEME
-- =========================================
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.bg_normal = "#090E20"

-- =========================================
-- AUTOSTART
-- =========================================
awful.spawn.with_shell("feh --bg-fill ~/.config/Wallpaper/wallpaper.jpg &")
-- picom con blur para el powermenu (ventana "splash"); si no existe la config, picom a secas
awful.spawn.with_shell([[
  CONF="$HOME/.config/awesome/assets/picom/picom.conf"
  pkill -x picom 2>/dev/null; sleep 0.3
  if [ -f "$CONF" ]; then picom --config "$CONF" > "$HOME/.cache/picom.log" 2>&1 &
  else picom & fi
]])
-- cursor de la raíz (fondo del escritorio): el mismo tema que ya dejó listo el bloque de arriba
awful.spawn.with_shell(string.format([[
    export XCURSOR_THEME='%s' XCURSOR_SIZE=%d
    xrdb -merge ~/.Xresources
    xsetroot -cursor_name left_ptr
]], CURSOR.active, CURSOR.size))

-- =========================================
-- LAYOUTS
-- =========================================
awful.layout.layouts = {
    awful.layout.suit.tile,      -- Grid
    awful.layout.suit.floating,  -- Floating
    awful.layout.suit.max        -- Fullscreen
}


-- =========================================
-- TAGS
-- =========================================
awful.screen.connect_for_each_screen(function(s)
    awful.tag({ "1", "2", "3", "4", "5" }, s, awful.layout.layouts[1])

    -- Dashboard (Super-botón del bar) y barra vertical, ahora en Lua
    s.mydash = require("dashboard1").build(s)
    s.mybar  = require("bar").build(s, {
        on_dashboard = function() s.mydash.toggle() end,
    })
end)

-- Panel de notificaciones + popups + aviso de canciones
notifs.init()

-- =========================================
-- KEYS
-- =========================================
globalkeys = gears.table.join(
    awful.key({ "Control" }, "Return", function ()
        notifs.launching("terminal")
        awful.spawn("xfce4-terminal --hide-menubar")
    end),

    awful.key({ "Mod1" }, "r", awesome.restart),
    awful.key({ "Mod1" }, "q", awesome.quit),
    awful.key({ "Control" }, "d", function () awful.spawn.with_shell("rofi -show drun") end),

    awful.key({ "Control" }, "Left",  function () smart_move(-20, 0) end),
    awful.key({ "Control" }, "Down",  function () smart_move(0, 20) end),
    awful.key({ "Control" }, "Up",    function () smart_move(0, -20) end),
    awful.key({ "Control" }, "Right", function () smart_move(20, 0) end),

    awful.key({ "Mod1" }, "Left",  function() smart_resize(-20, 0) end),
    awful.key({ "Mod1" }, "Down",  function() smart_resize(0, 20) end),
    awful.key({ "Mod1" }, "Up",    function() smart_resize(0, -20) end),
    awful.key({ "Mod1" }, "Right", function() smart_resize(20, 0) end),

    -- Flameshot (Alt + /)
    awful.key({ "Mod1" }, "/", function ()
        local file = os.getenv("HOME") .. "/storage/downloads/Screenshot_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
        local cmd = "mkdir -p $HOME/Pictures && flameshot full -r > '" .. file .. "'"
        awful.spawn.easy_async_with_shell(cmd, function()
            notifs.screenshot_ready(file)
        end)
    end),

    -- Quick Flameshot GUI (Alt + -)
    awful.key({ "Mod1" }, "-", function ()
        local file = os.getenv("HOME") .. "/storage/downloads/Screenshot_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
        local cmd = "flameshot gui --accept-on-select -r > '" .. file .. "'; " ..
                    "if [ -s '" .. file .. "' ]; then echo ok; else rm -f '" .. file .. "'; fi"
        awful.spawn.easy_async_with_shell(cmd, function(out)
            if out and out:match("ok") then notifs.screenshot_ready(file) end
        end)
    end),

    -- Prueba rápida de popups (Alt + n)
    awful.key({ "Mod1" }, "n", function ()
        notifs.notify { app = "Test", title = "Popup de prueba", body = "Si ves esto, los popups funcionan." }
    end),

    awful.key({ "Control" }, "n", function ()
        awful.spawn.with_shell("pkill -f selector_gtk.py")
    end,
    {description = "Close GTK selector", group = "launcher"})
)
root.keys(globalkeys)

-- =========================================
-- GLOBAL VARIABLES AND BUTTONS
-- =========================================
mouse_mode_enabled = false
lock_mode_enabled = true
local last_click_time = 0
local double_click_interval = 0.30

clientbuttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        if mouse_mode_enabled and not lock_mode_enabled then
            local current_time = os.clock()
            if current_time - last_click_time < double_click_interval then
                awful.mouse.client.resize(c)
            end
            last_click_time = current_time
        end
    end),
    awful.button({ "Mod1" }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        if mouse_mode_enabled and not lock_mode_enabled then
            awful.mouse.client.move(c)
        end
    end)
)

-- menu1 (menú contextual) ahora es un módulo Lua: ~/.config/awesome/menu1/init.lua (show(x, y) / hide())
local function menu1(fn, ...)
    local ok, m = pcall(require, "menu1")
    if ok and type(m) == "table" and type(m[fn]) == "function" then m[fn](...) end
end

root.buttons(gears.table.join(
    -- RIGHT CLICK -> CONTEXT MENU
    awful.button({}, 3, function()
        local coords = mouse.coords()
        menu1("show", coords.x + 8, coords.y + 8)
    end),

    -- LEFT CLICK -> CLOSE MENU
    awful.button({}, 1, function()
        menu1("hide")
    end)
))

-- =========================================
-- RULES
-- =========================================
awful.rules.rules = {
    {
        rule = { instance = "eww-powermenu" },
        properties = {
            floating = true,
            border_width = 0,
            titlebars_enabled = false,
            sticky = true,
            ontop = true,
            skip_taskbar = true,
        }
    },
    {
        -- Base rule for ALL windows
        rule = {},
        properties = {
            border_width = 0,
            focus = awful.client.focus.filter,
            raise = true,
            floating = true,
            placement = awful.placement.centered + awful.placement.no_offscreen,
            size_hints_honor = false,
            screen = awful.screen.preferred,
            titlebars_enabled = false, -- OFF by default so it doesn't interfere with other apps
            buttons = clientbuttons,
        },
        callback = function(c)
            awful.placement.centered(c, nil)
        end
    },
    {
        -- Rule for Terminal, Thunar, and Audacious
        rule_any = { class = { "Xfce4-terminal", "Thunar", "thunar", "Audacious", "audacious" } },
        properties = {
            width  = 650,
            height = 400,
            placement = awful.placement.centered,
            titlebars_enabled = true -- Explicitly ON
        },
        callback = function(c)
            awful.placement.centered(c, nil)
        end
    },
    {
        -- SPECIFIC rule for Firefox with all its possible name variations
        rule_any = {
            class = { "Firefox", "firefox", "Navigator", "firefox-esr", "Firefox-esr" },
            instance = { "Navigator", "firefox", "firefox-esr" }
        },
        properties = {
            floating = true,
            width  = 900,
            height = 550,
            placement = awful.placement.centered,
            size_hints_honor = false,
            titlebars_enabled = true, -- Explicitly ON
        },
        callback = function(c)
            -- Initial centering
            awful.placement.centered(c, nil)

            -- Magic delay: Forces the position and BUTTONS once Firefox manages to load
            gears.timer.delayed_call(function()
                if c.valid then
                    awful.placement.centered(c, nil)
                    c:emit_signal("request::titlebars")
                end
            end)
        end
    }
}

-- =========================================
-- SIGNALS AND MAC/IOS BUTTON ENVIRONMENT
-- =========================================
local function create_dot_button(color, action)
    local button = wibox.widget {
        markup = '<span foreground="' .. color .. '">●</span>',
        font   = "Sans 14",
        align  = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    button:buttons(gears.table.join(
        awful.button({ }, 1, action)
    ))
    return button
end

client.connect_signal("request::titlebars", function(c)
    -- HERE IS THE TRICK: We remove the name filter.
    -- If the window reaches this function, it is because the rules above allowed "titlebars_enabled = true"
    c.border_width = 0

    -- Esquinas redondeadas en las 4 puntas (incluye las de la barra de los 3 botones)
    c._round_ready = true
    update_round_shape(c)

    local sidebar = awful.titlebar(c, {
        position = "left",
        size     = 40,
        bg       = "#090E20"
    })

    sidebar:setup {
        {
            {
                create_dot_button("#ed6a7f", function() c:kill() end),
                create_dot_button("#f2d68f", function() c.minimized = true end),
                create_dot_button("#a8e8c0", function()
                    c.maximized = not c.maximized
                    c:raise()
                end),
                spacing = 14,
                layout  = wibox.layout.fixed.vertical
            },
            top    = 22,
            left   = 14,
            right  = 0,
            widget = wibox.container.margin
        },
        nil,
        nil,
        layout = wibox.layout.align.vertical
    }
end)

-- =========================================
-- NOTIFICATION BRIDGE (NAUGHTY -> panel Lua)
-- =========================================
naughty.connect_signal("request::display", function(n)
    notifs.notify {
        app   = tostring(n.app_name or "System"),
        title = tostring(n.title or "Notification"),
        body  = tostring(n.message or ""),
    }
    pcall(function() n:destroy() end)
end)

-- (El icono del layout y su tooltip ahora los maneja bar/init.lua directamente.)
