-- rc.lua for AwesomeWM on Termux X11
-- Compatible with: picom, feh, eww, xfce4-terminal

-- =========================================
-- LIBRARIES
-- =========================================
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
local wibox = require("wibox")
local naughty = require("naughty")

-- =========================================
-- Smart function to move windows
-- =========================================
local function smart_move(dx, dy)
    local c = client.focus
    if c then
        -- Define which are your "free" apps
        -- Added "Firefox" to the list
        local is_free = (c.class == "Xfce4-terminal" or 
                         c.class == "Thunar" or 
                         c.class == "Audacious" or 
                         c.class == "Firefox")
        
        -- If it's a free app OR the lock is disabled, move it
        if is_free or not lock_mode_enabled then
            c:relative_move(dx, dy, 0, 0)
        end
    end
end

-- =========================================
-- Smart function to resize windows
-- =========================================
local function smart_resize(dw, dh)
    local c = client.focus
    if not c then
        return
    end

    local is_free = (
        c.class == "Xfce4-terminal" or
        c.class == "Thunar" or
        c.class == "Audacious" or
        c.class == "Firefox"
    )

    if is_free or not lock_mode_enabled then
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
awful.spawn.with_shell("feh --bg-fill ~/.config/Wallpaper/flowers-1.jpg")
awful.spawn.with_shell("picom &")
awful.spawn.with_shell("pgrep -x eww || eww daemon &")
awful.spawn.with_shell("sleep 2 && eww open bar")

-- =========================================
-- LAYOUTS
-- =========================================
awful.layout.layouts = { awful.layout.suit.floating, awful.layout.suit.max }

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

    awful.key({ "Control" }, "Return", function () awful.spawn("xfce4-terminal --hide-menubar") end),
    awful.key({ "Mod1" }, "r", awesome.restart),
    awful.key({ "Mod1" }, "q", awesome.quit),
    awful.key({ "Control" }, "d", function () awful.spawn.with_shell("rofi -show drun") end),
    awful.key({ "Mod1" }, "d", function () awful.spawn.with_shell("eww close launcher") end),

    -- Move floating window (Smart: Free apps always, Widgets only if not locked)
    awful.key({ "Control" }, "Left",  function () smart_move(-20, 0) end),
    awful.key({ "Control" }, "Down",  function () smart_move(0, 20) end),
    awful.key({ "Control" }, "Up",    function () smart_move(0, -20) end),
    awful.key({ "Control" }, "Right", function () smart_move(20, 0) end),

    -- Resize window (Keep the previous logic if you prefer it to also be smart)
    awful.key({ "Mod1" }, "Left",  function() smart_resize(-20, 0) end),
    awful.key({ "Mod1" }, "Down",  function() smart_resize(0, 20) end),
    awful.key({ "Mod1" }, "Up",    function() smart_resize(0, -20) end),
    awful.key({ "Mod1" }, "Right", function() smart_resize(20, 0) end),
    -- Flameshot (Alt + /)
    awful.key({ "Mod1" }, "/", function ()
        local cmd = "mkdir -p $HOME/Pictures && " ..
                    "FILE=$HOME/storage/downloads/Screenshot_$(date +%Y%m%d_%H%M%S).png && " ..
                    "flameshot full -r > $FILE && " ..
                    "bash ~/.config/eww/scripts/logger.sh 'Screenshot' 'Screenshot Is Ready!' 'Screenshot saved successfully' $FILE && " ..
                    "bash ~/.config/eww/scripts/logger.sh 'Screenshot' 'Screenshot' 'Screenshot removed successfully.' 'null'"
        awful.spawn.with_shell(cmd)
    end),

    -- Toggle Eww profiles (Ctrl + Z)
    awful.key({ "Control" }, "z", function ()
        awful.spawn.with_shell("~/.config/eww/scripts/toggle_profile.sh forward")
    end,
    {description = "Toggle Eww profiles (Forward)", group = "custom"}),

    -- Go back Eww profiles (Ctrl + X)
    awful.key({ "Control" }, "x", function ()
        awful.spawn.with_shell("~/.config/eww/scripts/toggle_profile.sh back")
    end,
    {description = "Go back Eww profiles (Back)", group = "custom"}),

    -- Python script (Ctrl + K)
    awful.key({ "Control" }, "k", function ()
        awful.spawn.with_shell("python ~/.config/eww/scripts/selector_gtk.py")
    end,
    {description = "Toggle selector_gtk.py (Open/Close)", group = "custom"}),

    -- Close Python script (Ctrl + N)
    awful.key({ "Control" }, "n", function ()
        awful.spawn.with_shell("pkill -f selector_gtk.py")
    end,
    {description = "Close GTK selector", group = "launcher"}),


    -- Controls
    awful.key({ "Control" }, "v", function ()
        mouse_mode_enabled = not mouse_mode_enabled
        naughty.notify({ app_name = "🖱️ Mouse Mode", text = (mouse_mode_enabled and "ENABLED" or "DISABLED") })
    end),
    awful.key({ "Control" }, "g", function ()
        lock_mode_enabled = not lock_mode_enabled
        naughty.notify({ app_name = "⚙️ Position", text = (lock_mode_enabled and "🔒 LOCKED" or "🔓 UNLOCKED") })
    end)
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
            if current_time - last_click_time < double_click_interval then awful.mouse.client.resize(c) end
            last_click_time = current_time
        end
    end),
    awful.button({ "Mod1" }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        if mouse_mode_enabled and not lock_mode_enabled then awful.mouse.client.move(c) end
    end)
)


-- =========================================
-- RULES
-- =========================================
awful.rules.rules = {

    -- Specific rule for Eww Powermenu (avoids gray background and borders)
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

    -- Global Rule for all other windows
    {
        rule = {},
        properties = {
            border_width = 0,
            focus = awful.client.focus.filter,
            raise = true,
            floating = true,
            placement = awful.placement.centered + awful.placement.no_offscreen,
            size_hints_honor = false,
            screen = awful.screen.preferred,
            titlebars_enabled = false,
            buttons = clientbuttons,
        },
        callback = function(c)
            awful.placement.centered(c, nil)
        end
    },

    -- Rule for exact terminal dimensions
    {
        rule = { class = "Xfce4-terminal" },
        properties = {
            width  = 650,
            height = 400,
        }
    },
}

-- =========================================
-- SIGNALS AND MAC/IOS BUTTON ENVIRONMENT
-- =========================================

-- Function to build textured circular buttons
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

-- Update of titlebars block with forced hiding
client.connect_signal("request::titlebars", function(c)
    -- If it's the terminal, remove native borders (this helps kill the top bar)
    if c.class == "Xfce4-terminal" then
        c.border_width = 0
        
        -- Create the sidebar for your buttons
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
    end
end)

-- EXTRA SIGNAL: This ensures the top bar dies when opening
client.connect_signal("manage", function(c)
    if c.class == "Xfce4-terminal" then
        -- Hide native window decorations
        c.border_width = 0
        -- Force redraw
        c:emit_signal("request::titlebars")
    end
end)

-- =========================================
-- NOTIFICATION BRIDGE (NAUGHTY -> EWW)
-- =========================================
naughty.connect_signal("request::display", function(n)
    -- Extract data directly from the notification object
    local app = tostring(n.app_name or "System")
    local title = tostring(n.title or "Notification")
    local message = tostring(n.message or "")

    -- Clean single quotes to protect the Bash command
    app = app:gsub("'", "")
    title = title:gsub("'", "")
    message = message:gsub("'", "")

    -- Build the exact command
    local script = "/data/data/com.termux/files/home/.config/eww/scripts/logger.sh"
    local cmd = string.format("%s '%s' '%s' '%s' ''", script, app, title, message)

    -- Send data to the Eww panel in the background
    awful.spawn.with_shell(cmd)

    -- Execute the destroy command so AwesomeWM doesn't draw its window
    naughty.destroy(n)
end)


-- ===================================================================
-- MASTER ADJUSTMENT: GEOMETRIC CONTROL WITH REAL DIMENSIONS
-- ===================================================================
client.connect_signal("manage", function(c)
    -- 🔹 Add "actions1", "notifications" and "menu" to the detection list
    if c.class == "Eww" or (c.name and (c.name:match("dashboard") or c.name:match("date") or c.name:match("actions") or c.name:match("notifications") or c.name:match("menu"))) then
        c.floating = true
        c.above = true
        c.sticky = true

        -- 🔥 Allows the widget to respond to the keyboard (Vital for Ctrl+Arrows)
        c.focusable = true

        -- 🔥 Forces Awesome to focus the widget when clicking on the background
        c:connect_signal("mouse::press", function()
            client.focus = c
            c:raise()
        end)

        gears.timer.delayed_call(function()
            if c.valid then
                local s_geo = c.screen.geometry
                local c_geo = c:geometry()
                local client_width = c_geo.width
                local client_height = c_geo.height
                
                -- Pre-calculated global variables
                local center_x = s_geo.x + (s_geo.width - client_width) / 2
                local center_y = s_geo.y + (s_geo.height - client_height) / 2

                -- 🔥 MENU RULES FIRST: Prevent them from stealing positions due to their size
                -- ===================================================
                -- 📜 MENU 1 (~280px) -> Profiles 1 and 3
                -- ===================================================
                if c.name and c.name:match("menu1") then
                    local current_profile = "1"
                    local file = io.open("/data/data/com.termux/files/usr/tmp/current_profile", "r")
                    if file then
                        current_profile = file:read("*all"):gsub("%s+", "")
                        file:close()
                    end

                    if current_profile == "3" then
                        -- 🔵 PROFILE 3: Subtract 600 to clear the 600px of the central dashboard
                        c:geometry({ x = center_x - 600, y = center_y + 120 })
                    else
                        -- ⚪ PROFILE 1: Original position intact
                        c:geometry({ x = center_x - 210, y = center_y + 100 })
                    end

                -- ===================================================
                -- 📜 MENU 2 (~280px) -> Profiles 2 and 4
                -- ===================================================
                elseif c.name and c.name:match("menu2") then
                    local current_profile = "2"
                    local file = io.open("/data/data/com.termux/files/usr/tmp/current_profile", "r")
                    if file then
                        current_profile = file:read("*all"):gsub("%s+", "")
                        file:close()
                    end

                    if current_profile == "4" then
                        -- 🟣 PROFILE 4: To the right of dashboard4 (Margin 120 + width ~380 = 500. Set to 530 for a clean margin)
                        c:geometry({ x = s_geo.x + 550, y = center_y + 120 })
                    else
                        -- 🔴 PROFILE 2: Perfect dynamic centering between the calendar (date2) and dashboard2
                        local date2_right = s_geo.x + 440                      -- Left margin (120) + date2 width (~320)
                        local dash2_left = (s_geo.x + s_geo.width / 2) - 375   -- Screen center - half of dashboard2 (750/2)
                        local gap = dash2_left - date2_right                   -- Real free space between both widgets
                        
                        c:geometry({ x = date2_right + (gap - client_width) / 2, y = center_y + 180 })
                    end

                -- ===================================================
                -- 🔹 1. DASHBOARD 1 (Real size: 650px)
                -- ===================================================
                elseif (c.name and c.name:match("dashboard1")) or (client_width >= 640 and client_width <= 660) then
                    awful.placement.left(c, { margins = { left = 120 }, honor_workarea = false })
                    awful.placement.center_vertical(c, { honor_workarea = false })

                -- ===================================================
                -- 🎛️ 2. DASHBOARD 2 (750x500)
                -- ===================================================
                elseif (c.name and c.name:match("dashboard2")) or (client_width >= 730 and client_width <= 770) then
                    local bottom_y = s_geo.y + s_geo.height - client_height - 15
                    c:geometry({ x = center_x, y = bottom_y })

                -- ===================================================
                -- 🎛️ 3. DASHBOARD 3 (600x780)
                -- ===================================================
                elseif (c.name and c.name:match("dashboard3")) or (client_width >= 580 and client_width <= 620) then
                    local bottom_y = s_geo.y + s_geo.height - client_height - 15
                    c:geometry({ x = center_x, y = bottom_y })

                -- ===================================================
                -- 📱 4. DASHBOARD 4 (~350-400px real width, 97% height)
                -- ===================================================
                -- 🔥 Ultra-safe detection so it doesn't fall into the screen center limbo
                elseif (c.name and c.name:match("dashboard4")) or 
                       (c.name and c.name:match("dashboard") and client_width < 500) or 
                       (client_width >= 280 and client_width <= 450 and not (c.name and (c.name:match("actions") or c.name:match("menu") or c.name:match("date")))) then
                    awful.placement.left(c, { margins = { left = 120 }, honor_workarea = false })
                    awful.placement.center_vertical(c, { honor_workarea = false })

                -- ===================================================
                -- ⚙️ 5. ACTIONS 1 and ACTIONS 2 (400px width)
                -- ===================================================
                elseif (client_width >= 390 and client_width <= 410 and client_height >= 200 and client_height <= 900) or (c.name and c.name:match("actions2")) then
                    local right_x = s_geo.x + s_geo.width - client_width - 20
                    local current_profile = "1"
                    local file = io.open("/data/data/com.termux/files/usr/tmp/current_profile", "r")
                    if file then
                        current_profile = file:read("*all"):gsub("%s+", "")
                        file:close()
                    end

                    if current_profile == "4" then
                        local top_y = s_geo.y + 15
                        c:geometry({ x = right_x, y = top_y })
                    elseif current_profile == "3" then
                        c.hidden = true
                        c:geometry({ x = -9999, y = -9999 })
                    else
                        local top_y = s_geo.y + 545
                        c:geometry({ x = right_x, y = top_y })
                    end

                -- ===================================================
                -- 🔔 6. NOTIFICATIONS (500px width)
                -- ===================================================
                elseif client_width >= 490 and client_width <= 510 then
                    local right_x = s_geo.x + s_geo.width - client_width - 20
                    local top_y = s_geo.y + 15
                    c:geometry({ x = right_x, y = top_y })

                -- ===================================================
                -- 📅 7. DATE 1 (~366x356)
                -- ===================================================
                elseif (client_width >= 360 and client_width <= 372 and client_height >= 350 and client_height <= 362) or (c.name and c.name:match("date1")) then
                    local current_profile = "1"
                    local file = io.open("/data/data/com.termux/files/usr/tmp/current_profile", "r")
                    if file then
                        current_profile = file:read("*all"):gsub("%s+", "")
                        file:close()
                    end

                    if current_profile == "3" then
                        local right_x = s_geo.x + s_geo.width - client_width - 20
                        local date_bottom_y = s_geo.y + s_geo.height - client_height - 20
                        c:geometry({ x = right_x, y = date_bottom_y })
                    else
                        c:geometry({ x = center_x - 170, y = center_y - 275 })
                    end

                -- ===================================================
                -- 📅 8. DATE 2 (~320x400)
                -- ===================================================
                elseif (client_width >= 310 and client_width <= 335 and client_height >= 390 and client_height <= 415) or (c.name and c.name:match("date2")) then
                    local current_profile = "2"
                    local file = io.open("/data/data/com.termux/files/usr/tmp/current_profile", "r")
                    if file then
                        current_profile = file:read("*all"):gsub("%s+", "")
                        file:close()
                    end

                    if current_profile == "4" then
                        local top_y = s_geo.y + 15
                        c:geometry({ x = center_x, y = top_y })
                    else
                        local left_x = s_geo.x
                        c:geometry({ x = left_x + 120, y = center_y + 250 })
                    end

                -- ===================================================
                -- 🔸 12. OTHER WIDGETS
                -- ===================================================
                else
                    awful.placement.bottom(c, { margins = { bottom = 20 }, honor_workarea = true })
                end
            end
        end)
    end
end)
