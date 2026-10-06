-- rc.lua for AwesomeWM on Termux X11
-- Compatible with: picom, feh, eww, xfce4-terminal

-- =========================================
-- LIBRARIES
-- =========================================
local gears = require("gears")
awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
local wibox = require("wibox")
local naughty = require("naughty")
local rubato = require("lib.rubato")

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
awful.spawn.with_shell("bash /data/data/com.termux/files/home/.config/eww/scripts/watch_music.sh > /data/data/com.termux/files/usr/tmp/watch_music.log 2>&1 &")
awful.spawn.with_shell("pkill -f '[m]anage_notifs.sh'; bash /data/data/com.termux/files/home/.config/eww/scripts/manage_notifs.sh &")
awful.spawn.with_shell("feh --bg-fill ~/.config/Wallpaper/wallpaper.jpg &")
awful.spawn.with_shell("picom &")
awful.spawn.with_shell("pgrep -x eww || eww daemon &")
awful.spawn.with_shell("sleep 2 && eww open bar")
awful.spawn.with_shell([[
    echo "Xcursor.theme: capitaine-cursors-light" > ~/.Xresources
    echo "Xcursor.size: 32" >> ~/.Xresources
    export XCURSOR_SIZE=32
    xrdb -merge ~/.Xresources
    xsetroot -cursor_name left_ptr
]])

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
end)

-- =========================================
-- KEYS
-- =========================================
globalkeys = gears.table.join(
    awful.key({ "Control" }, "Return", function ()
        awful.spawn.with_shell("bash ~/.config/eww/scripts/logger.sh 'Launchers' 'Launching!' 'Launching terminal, please wait...' ''")
        awful.spawn("xfce4-terminal --hide-menubar")
    end),

    awful.key({ "Mod1" }, "r", awesome.restart),
    awful.key({ "Mod1" }, "q", awesome.quit),
    awful.key({ "Control" }, "d", function () awful.spawn.with_shell("rofi -show drun") end),
    awful.key({ "Mod1" }, "d", function () awful.spawn.with_shell("eww close launcher") end),

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
        local cmd = "mkdir -p $HOME/Pictures && " ..
                    "FILE=$HOME/storage/downloads/Screenshot_$(date +%Y%m%d_%H%M%S).png && " ..
                    "flameshot full -r > $FILE && " ..
                    "eww -c ~/.config/eww/menu2 update show_flameshot=true && sleep 3 && eww -c ~/.config/eww/menu2 update show_flameshot=false & " ..
                    "bash ~/.config/eww/scripts/logger.sh 'Screenshot' 'Screenshot Is Ready!' 'Screenshot saved successfully' $FILE"
        awful.spawn.with_shell(cmd)
    end),

    -- Quick Flameshot GUI (Alt + -)
    awful.key({ "Mod1" }, "-", function ()
        local cmd = "FILE=$HOME/storage/downloads/Screenshot_$(date +%Y%m%d_%H%M%S).png; " ..
                    "flameshot gui --accept-on-select -r > \"$FILE\"; " ..
                    "if [ -s \"$FILE\" ]; then " ..
                    "  ( eww -c ~/.config/eww/menu2 update show_flameshot=true && sleep 3 && eww -c ~/.config/eww/menu2 update show_flameshot=false ) & " ..
                    "  bash ~/.config/eww/scripts/logger.sh 'Screenshot' 'Screenshot Is Ready!' 'Screenshot saved successfully' \"$FILE\"; " ..
                    "else " ..
                    "  rm -f \"$FILE\"; " ..
                    "fi"
        awful.spawn.with_shell(cmd)
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

root.buttons(gears.table.join(
    -- =====================================
    -- RIGHT CLICK -> EWW CONTEXT MENU
    -- =====================================
    awful.button({}, 3, function()
        local coords = mouse.coords()
        local x = coords.x + 8
        local y = coords.y + 8

        awful.spawn.with_shell("eww -c ~/.config/eww/menu1 close menu1_5 2>/dev/null")
        awful.spawn.with_shell(string.format("bash ~/.config/eww/scripts/launch.sh %d %d", x, y))
    end),

    -- =====================================
    -- LEFT CLICK -> CLOSE MENU
    -- =====================================
    awful.button({}, 1, function()
        awful.spawn.with_shell("eww -c ~/.config/eww/menu1 close menu1 menu1_5 2>/dev/null")
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

-- Executed when OPENING any window
client.connect_signal("manage", function(c)
    -- Triggers the icon updater in Eww
    awful.spawn.with_shell("bash ~/.config/eww/scripts/update_icons.sh")
end)

-- Executed when CLOSING any window
client.connect_signal("unmanage", function(c)
    -- Triggers the icon updater in Eww
    awful.spawn.with_shell("bash ~/.config/eww/scripts/update_icons.sh")
end)

-- =========================================
-- NOTIFICATION BRIDGE (NAUGHTY -> EWW)
-- =========================================
naughty.connect_signal("request::display", function(n)
    local app = tostring(n.app_name or "System")
    local title = tostring(n.title or "Notification")
    local message = tostring(n.message or "")

    app = app:gsub("'", "")
    title = title:gsub("'", "")
    message = message:gsub("'", "")

    local script = "/data/data/com.termux/files/home/.config/eww/scripts/logger.sh"
    local cmd = string.format("%s '%s' '%s' '%s' ''", script, app, title, message)

    awful.spawn.with_shell(cmd)
    naughty.destroy(n)
end)

-- =========================================
-- EWW LAYOUT ICON SYNC (IMAGES)
-- =========================================
tag.connect_signal("property::layout", function(t)
    local layout_name = awful.layout.getname(t.layout)
    local theme_dir = "/data/data/com.termux/files/usr/share/awesome/themes/default/layouts/"

    local img_path = theme_dir .. "tilew.png" -- 1: Grid (tile)

    if layout_name == "floating" then
        img_path = theme_dir .. "floatingw.png" -- 2: Floating
    elseif layout_name == "max" then
        img_path = theme_dir .. "maxw.png" -- 3: Maximized
    end

    awful.spawn.with_shell("eww update layout_image='" .. img_path .. "'")
end)

