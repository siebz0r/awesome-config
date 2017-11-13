-- Standard awesome library
local gears = require("gears")
local mouse = require('mouse')
local screen = require('screen')
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
-- Vicious widget library
local vicious = require("vicious")
-- Extra libs
local math = require("math")

-- Cyclefocus (alt-tab thingy)
local cyclefocus = require("cyclefocus")
-- Keyboard backlight
kbd_backlight = require("kbd_backlight")
-- Widgets
local wifi_widget = require 'wifi_widget'

--- {{{ Naughty configuration
naughty.config.defaults.icon_size = 100
naughty.config.defaults.position = 'bottom_right'
--- }}}

--- {{{ Graph widget config
graph_text_format = '<span bgcolor="#000000" bgalpha="40%%">%s%%</span>'
--- }}}

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(os.getenv("HOME") .. "/.config/awesome/theme/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "lilyterm"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- {{{ Wallpaper
function set_wallpaper(sc)
    if beautiful.wallpaper then
        gears.wallpaper.maximized(beautiful.wallpaper, sc, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
previous_tag = nil
function init_tags(s)
    -- Each screen has its own tag table.
    tags[s.index] = {}
    for i = 1, 8 do
        local tag = awful.tag.add(i, {screen=s, layout=awful.layout.suit.floating})
        table.insert(tags[s.index], tag)
        if i == 1 then
            tag.selected = true
        end
        tag:connect_signal('property::selected', function(tag)
            if not tag.selected then
                previous_tag = tag
            end
        end)
    end
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
    { "manual", terminal .. " -e man awesome" },
    { "edit config", editor_cmd .. " " .. awesome.conffile },
    { "restart", awesome.restart },
    { "quit", awesome.quit }
}

-- Power menu using consolekit
_reboot_cmd = 'dbus-send --system --print-reply --dest="org.freedesktop.ConsoleKit" /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Restart'
_shutdown_cmd = 'dbus-send --system --print-reply --dest="org.freedesktop.ConsoleKit" /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Stop'
_suspend_cmd = 'dbus-send --system --print-reply --dest="org.freedesktop.UPower" /org/freedesktop/UPower org.freedesktop.UPower.Suspend'

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal, beautiful.terminal_icon },
                                    { nil },
                                    { 'suspend', _suspend_cmd, beautiful.suspend_icon },
                                    { 'reboot', _reboot_cmd, beautiful.reboot_icon },
                                    { 'shutdown', _shutdown_cmd, beautiful.shutdown_icon }
                                  }
                        })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
menubar.cache_entries = true
-- }}}

-- {{{ Wibox
-- Create a separator widget
separator = wibox.widget.textbox()
separator:set_text("  ")

-- Create a textclock widget
mytextclock = awful.widget.textclock("%F %H:%M:%S", 1)
mytextclock:set_font("DejaVu Sans 9")

-- Create a battery widget
battery_icon = wibox.widget.imagebox()
battery_icon:set_resize(true)
battery_text = wibox.widget {
    align = 'center',
    font = 'DejaVu Sans 6',
    widget = wibox.widget.textbox
}
vicious.register(
    battery_text,
    vicious.widgets.bat,
    string.format(graph_text_format, '$2'),
    1,
    "BAT0")
battery_shape = function(cr, width, height)
    local rad = 2
    local tip_h = height/3
    local tip_w = tip_h/1.5
    -- tip
    cr:new_sub_path()
    cr:arc_negative(width-(tip_w-rad), height/2-tip_h/2-rad, rad, math.pi, math.pi/2)
    cr:arc(width-rad, height/2-tip_h/2+rad, rad, 3*(math.pi/2), math.pi*2)
    cr:arc(width-rad, height/2+tip_h/2-rad, rad, math.pi*2, math.pi/2)
    cr:arc_negative(width-(tip_w-rad), height/2+tip_h/2+rad, rad, 3*(math.pi/2), math.pi)
    cr:fill()
    -- top left
    cr:arc(rad, rad, rad, math.pi, 3*(math.pi/2))
    -- top right
    cr:arc(width-rad-tip_w, rad, rad, 3*(math.pi/2), math.pi*2)
    -- bottom right
    cr:arc(width-rad-tip_w, height-rad, rad, math.pi*2, math.pi/2)
    -- bottom left
    cr:arc(rad, height-rad, rad, math.pi/2, math.pi)
    -- cr:fill()
    cr:close_path()
end
battery_bar_shape = function(cr, width, height)
    local rad = 2
    local tip = (height/3)/1.5
    gears.shape.rounded_rect(cr, width-(tip+1), height, rad)
end
battery_bar = wibox.widget {
    border_width = 2,
    bar_border_width = 1,
    max_value = 1,
    forced_width = 35,
    shape = battery_shape,
    bar_shape = battery_bar_shape,
    widget = wibox.widget.progressbar
}
vicious.register(
    battery_bar,
    vicious.widgets.bat,
    '$2',
    1,
    "BAT0")
battery_widget = wibox.widget {
    wibox.container.margin(battery_bar, 1, 1, 2, 2),
    wibox.container.margin(battery_text, 0, 5),
    layout = wibox.layout.stack
}


-- Create a CPU widget
cpu_widget = wibox.layout.fixed.horizontal()
cpu_icon = wibox.widget.imagebox()
cpu_icon:set_resize(true)
cpu_widget:add(cpu_icon)
cpu_icon:set_image(beautiful:icon('electronics'))
cpu_graph = wibox.widget {
    widget = wibox.widget.graph,
    width = 40,
}
vicious.cache(vicious.widgets.cpu)
vicious.register(cpu_graph, vicious.widgets.cpu, "$1", 2)
cpu_text = wibox.widget {
    align = 'center',
    widget = wibox.widget.textbox
}
vicious.register(
    cpu_text,
    vicious.widgets.cpu,
    string.format(graph_text_format, '$1'),
    2)
cpu_graph_s = wibox.widget {
    wibox.container.mirror(cpu_graph, { horizontal = true }),
    cpu_text,
    layout = wibox.layout.stack
}
cpu_widget:add(cpu_graph_s)

-- CPU usage tooltip widget
cpu_widget:connect_signal('mouse::enter', function(other, geo)
    local n_processes = 15
    local processes = wibox.widget {
        layout = wibox.layout.fixed.vertical
    }
    local proc_widgets = {}
    for i=1,n_processes do
        local p_name = wibox.widget {
            widget = wibox.widget.textbox,
        }
        local p_percentage_bar = wibox.widget {
            widget = wibox.widget.progressbar,
            max_value = 100,
        }
        local p_percentage_txt = wibox.widget {
            widget = wibox.widget.textbox,
            align = 'center'
        }
        local p_percentage = wibox.widget {
            p_percentage_bar,
            p_percentage_txt,
            layout = wibox.layout.stack
        }
        local process = wibox.widget {
            p_name,
            p_percentage,
            forced_height = 11,
            layout = wibox.layout.flex.horizontal
        }
        table.insert(proc_widgets, {p_name, p_percentage_bar, p_percentage_txt})
        processes:add(
            wibox.container.margin(
                wibox.container.margin(process, 1, 1, 1, 1),
                0, 0, 0, 1, beautiful.fg_normal))
    end

    local ps_comm = 'ps -Ao comm,pcpu --sort=-pcpu --no-headers | head -n %s'
    local function ps()
        awful.spawn.easy_async_with_shell(
            string.format(ps_comm, n_processes),
            function(stdout, stderr, exitreason, exitcode)
                local index = 1
                local w_index = 1
                for str in string.gmatch(stdout, '([^%s]+)') do
                    if (index % 2 == 1) then
                        proc_widgets[w_index][1].text = str
                    else
                        proc_widgets[w_index][2].value = str
                        proc_widgets[w_index][3].markup = string.format(graph_text_format, str)
                        w_index = w_index + 1
                    end
                    index = index + 1
                end
            end
        )
    end
    ps()
    local timer = gears.timer({
        timeout=1,
        autostart=true,
        callback=ps})

    local w = wibox {
        width = 200,
        height = 14 * n_processes + 1,
        ontop = true,
        widget = wibox.container.margin(processes, 1, 1, 1, 0, beautiful.fg_normal)
    }
    local function close()
        if mouse.current_wibox ~= w then
            w.visible = false
            timer:stop()
        end
    end
    w:connect_signal('mouse::leave', close)
    cpu_widget:connect_signal('mouse::leave', close)
    awful.placement.next_to(w, {
        geometry = geo,
        honor_workarea = true,
        preferred_positions = {'top', 'right', 'left', 'bottom'}
    })
    awful.placement.no_offscreen(w)
    w.visible = true
end)


-- Create a Memory widget
mem_widget = wibox.layout.fixed.horizontal()
mem_icon = wibox.widget.imagebox()
mem_icon:set_image(beautiful:icon('memmory_slot'))
mem_icon:set_resize(true)
mem_widget:add(mem_icon)

mem_graph = wibox.widget {
    widget = wibox.widget.graph,
    width = 40
}
vicious.cache(vicious.widgets.mem)
vicious.register(mem_graph, vicious.widgets.mem, "$1", 2)
mem_text = wibox.widget {
    align = 'center',
    widget = wibox.widget.textbox
}
vicious.register(
    mem_text,
    vicious.widgets.mem,
    string.format(graph_text_format, '$1'),
    2)
mem_graph_s = wibox.widget {
    wibox.container.mirror(mem_graph, { horizontal = true }),
    mem_text,
    layout = wibox.layout.stack
}
mem_widget:add(mem_graph_s)


-- Volume slider popup widget
vol_wibox_width = mouse.screen.geometry.width/3
vol_slider = wibox.widget {
    bar_height = 5,
    handle_width = 30,
    maximum = 1,
    widget = wibox.widget.slider
}
vicious.register(
    vol_slider,
    vicious.widgets.volume,
    '$1',
    60,
    "Master")
vol_slider_txt = wibox.widget {
    align = 'center',
    font = 'DejaVu Sans 20',
    widget = wibox.widget.textbox
}
vicious.register(
    vol_slider_txt,
    vicious.widgets.volume,
    string.format(graph_text_format, '$1'),
    60,
    "Master")
vol_slider_comp = wibox.widget {
    vol_slider,
    vol_slider_txt,
    layout = wibox.layout.stack
}
vol_wibox_height = 40
vol_wibox = wibox {
    width = vol_wibox_width,
    height = vol_wibox_height,
    ontop = true,
    x = mouse.screen.geometry.width/2 - vol_wibox_width/2,
    y = mouse.screen.geometry.height*0.75 - vol_wibox_height/2,
    shape = gears.shape.rounded_bar,
    opacity = 0.75,
    widget = vol_slider_comp
}
vol_wibox_timer = gears.timer({
    timeout=2,
    autostart=true,
    single_shot=true,
    callback=function()
        vol_wibox.visible = false
    end})
vol_wibox:connect_signal('mouse::enter', function()
    vol_wibox_timer:stop()
end)
vol_wibox:connect_signal('mouse::leave', function()
    vol_wibox_timer:start()
end)

function show_volume_slider()
    vol_wibox.visible = true
    vol_wibox_timer:again()
end


-- Create a volume widget
volume_widget = wibox.layout.fixed.horizontal()
volume_icon = wibox.widget.imagebox()
volume_icon:set_image(beautiful:icon('loudspeaker'))
volume_icon:set_resize(true)
volume_widget:add(volume_icon)

volume_text = wibox.widget {
    align = 'center',
    widget = wibox.widget.textbox
}
vicious.register(
    volume_text,
    vicious.widgets.volume,
    string.format(graph_text_format, '$1'),
    -- '$1%',
    60,
    "Master")

volume_bar = wibox.widget.progressbar()
volume_bar.max_value = 1

vicious.register(volume_bar, vicious.widgets.volume, '$1', 60, "Master")

volume_bar_r = wibox.container.rotate(volume_bar, 'east')
volume_bar_r.forced_width = 35
volume_graph_s = wibox.widget {
    volume_bar_r,
    volume_text,
    layout = wibox.layout.stack
}
volume_widget:add(volume_graph_s)

-- Register dbus event to update volume widget
if not dbus.request_name("session", "org.pulseaudio.volume") then
    naughty.notify({title='dbus', text='failed to request pulseaudio dbus channel'})
else
    dbus.add_match("session", "interface='org.pulseaudio.volume', member='change'")
    dbus.connect_signal("org.pulseaudio.volume", function(...)
        vicious.force({ volume_text })
        vicious.force({ volume_bar })
        vicious.force({ vol_slider })
        vicious.force({ vol_slider_txt })
    end)
end

awful.spawn.with_shell('killall pulseaudio-dbus; pulseaudio-dbus')


-- Create a root fs widget
sda_widget = wibox.layout.fixed.horizontal()
sda_icon = wibox.widget.imagebox()
sda_icon:set_image(beautiful:icon('hdd'))
sda_icon:set_resize(true)
sda_widget:add(sda_icon)

sda_pbar_layout = wibox.layout.fixed.vertical()
sda_txt = wibox.widget {
    align = 'left',
    font = 'DejaVu Sans 9',
    widget = wibox.widget.textbox
}
vicious.register(sda_txt, vicious.widgets.fs, "/: ${/ size_gb}GB(${/ avail_gb})")
sda_pbar_layout:add(sda_txt)

sda_pbar = wibox.widget {
    widget = wibox.widget.progressbar,
    forced_width = 120
}
vicious.register(sda_pbar, vicious.widgets.fs, "${/ used_p}")
sda_pbar_layout:add(sda_pbar)

sda_widget:add(sda_pbar_layout)

-- Create a root fs widget
sdb_widget = wibox.layout.fixed.horizontal()
sdb_icon = wibox.widget.imagebox()
sdb_icon:set_image(beautiful:icon('hdd'))
sdb_icon:set_resize(true)
sdb_widget:add(sdb_icon)

sdb_pbar_layout = wibox.layout.fixed.vertical()
sdb_txt = wibox.widget {
    align = 'left',
    font = 'DejaVu Sans 9',
    widget = wibox.widget.textbox
}
vicious.register(sdb_txt, vicious.widgets.fs, "/home: ${/home used_gb}GB(${/home avail_gb})")
sdb_pbar_layout:add(sdb_txt)

sdb_pbar = wibox.widget {
    widget = wibox.widget.progressbar,
    forced_width = 120
}
vicious.register(sdb_pbar, vicious.widgets.fs, "${/home used_p}")
sdb_pbar_layout:add(sdb_pbar)

sdb_widget:add(sdb_pbar_layout)


-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))


function init_wibox(s)
    -- Create a promptbox for each screen
    run_icon = wibox.widget.imagebox()
    mypromptbox[s.index] = awful.widget.prompt({ prompt = "Run :" })
    -- Create a taglist widget
    mytaglist[s.index] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s.index] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s.index] = awful.wibar({
        position="bottom",
        ontop=true,
        screen=s})

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mytaglist[s.index])
    left_layout:add(mypromptbox[s.index])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s.index == 1 then
        right_layout:add(separator)
        right_layout:add(wibox.widget.systray())
    end
    right_layout:add(separator)
    right_layout:add(sda_widget)
    right_layout:add(separator)
    right_layout:add(sdb_widget)
    right_layout:add(separator)
    right_layout:add(cpu_widget)
    right_layout:add(separator)
    right_layout:add(mem_widget)
    right_layout:add(separator)
    -- right_layout:add(swap_widget)
    right_layout:add(separator)
    right_layout:add(volume_widget)
    right_layout:add(separator)
    right_layout:add(wifi_widget)
    right_layout:add(separator)
    right_layout:add(battery_widget)
    right_layout:add(separator)
    right_layout:add(mytextclock)

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s.index])
    layout:set_right(right_layout)

    mywibox[s.index]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
xrandr_output = "eDP1"
globalkeys = awful.util.table.join(
    awful.key({ "Mod1", "Control" }, "Left",   awful.tag.viewprev       ),
    awful.key({ "Mod1", "Control" }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, 'Tab',
        function ()
            -- Switch to previous tag, if available.
            if previous_tag then
                awful.tag.viewonly(previous_tag)
            end
        end),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey            }, "r",
        function ()
            mypromptbox[mouse.screen.index]:run()
        end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end),
    -- Lock
    awful.key({ modkey            }, "l",
        function ()
            awful.spawn("xscreensaver-command -lock")
        end),
    -- Screenshots
    awful.key({                   }, "Print",
        function ()
            awful.spawn("shutter --full")
        end),
    awful.key({ "Control"         }, "Print",
        function ()
            awful.spawn("shutter --select")
        end),
    awful.key({ "Mod4"            }, "Print",
        function ()
            awful.spawn("shutter --window")
        end),
    -- Suspend
    awful.key({                   }, "XF86Sleep",
        function ()
            awful.spawn("dbus-send --system --print-reply --dest=org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower.Suspend")
        end),
    awful.key({                   }, "XF86Display",
        function ()
            if xrandr_output == "HDMI2" then
                awful.spawn.with_shell(
                    "xrandr --output eDP1 --mode 1920x1080 && " ..
                    "xrandr --output HDMI2 --off")
                xrandr_output = "eDP1"
            elseif xrandr_output == "sDP1" then
                awful.spawn.with_shell(
                    "xrandr --output HDMI2 --mode 1680x1050 -r 60 && " ..
                    "xrandr --output eDP1 --off")
                xrandr_output = "HDMI2"
            end
        end),
    -- Keyboard backlight
    awful.key({                   }, "XF86KbdBrightnessUp",
        function ()
            kbd_backlight.up()
        end),
    awful.key({                   }, "XF86KbdBrightnessDown",
        function ()
            kbd_backlight.down()
        end)
)

function toggle_fullscreen(c)
    c.fullscreen = not c.fullscreen
end

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      toggle_fullscreen),
    awful.key({ "Mod1",           }, "F4",     function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, 'a',
        function (c)
            -- Toggle always on top
            c.ontop = not c.ontop
        end),
    awful.key({ modkey,           }, "Up",
        function (c)
            if c.maximized_horizontal and c.maximized_vertical then
                c.maximized_horizontal = false
                c.maximized_vertical = false
            else
                c.maximized_horizontal = true
                c.maximized_vertical = true
            end
        end),
    awful.key({ modkey            }, "Down",
        function (c)
            c.minimized = true
        end),
    awful.key({ "Mod1", "Control", "Shift" }, "Left",
        function (c)
            if client.focus then
                local current = awful.tag.getidx()
                if current == 1 then dest = 8
                else dest = current - 1
                end
                local tag = tags[client.focus.screen.index][dest]
                awful.client.movetotag(tag)
                awful.tag.viewonly(tag)
            end
        end),
    awful.key({ "Mod1", "Control", "Shift" }, "Right",
        function ()
            if client.focus then
                local current = awful.tag.getidx()
                if current == 8 then dest = 1
                else dest = current + 1
                end
                local tag = tags[client.focus.screen.index][dest]
                awful.client.movetotag(tag)
                awful.tag.viewonly(tag)
            end
        end),
    awful.key({ "Mod4",           }, "Left",
        function (c)
            -- Tile client to left half of screen.
            local screengeo = screen[c.screen.index].workarea
            local width = screengeo.width/2
            local height = screengeo.height - 1 - beautiful.border_width * 2
            local x = screengeo.x
            local y = screengeo.y
            c.maximized_horizontal = false
            c.maximized_vertical = true
            c:geometry({ x = screengeo.x, y = screengeo.y,
                         width = width, height = height })
        end),
    awful.key({ "Mod4",           }, "Right",
        function (c)
            -- Tile client to right half of screen.
            local screengeo = screen[c.screen.index].workarea
            local width = screengeo.width/2
            local height = screengeo.height - 1 - beautiful.border_width * 2
            c.maximized_horizontal = false
            c.maximized_vertical = true
            c:geometry({ x = screengeo.width - width, y = screengeo.y,
                         width = width, height = height })
        end),
    awful.key({ "Mod4", "Control" }, "Left",
        function (c)
            -- Tile client to lower left corner.
            local screengeo = screen[c.screen.index].workarea
            local width = screengeo.width / 2
            local height = screengeo.height / 2 - beautiful.border_width
            c.maximized_horizontal = false
            c.maximized_vertical = false
            c:geometry({ x = screengeo.x, y = screengeo.height/2,
                         width = width, height = height })
        end),
    awful.key({ "Mod4", "Control" }, "Up",
        function (c)
            -- Tile client to upper left corner.
            local screengeo = screen[c.screen.index].workarea
            local width = screengeo.width / 2
            local height = screengeo.height / 2 - beautiful.border_width
            c.maximized_horizontal = false
            c.maximized_vertical = false
            c:geometry({ x = screengeo.x, y = screengeo.y,
                         width = width, height = height })
        end),
    awful.key({ "Mod4", "Control" }, "Right",
        function (c)
            -- Tile client to upper right corner.
            local screengeo = screen[c.screen.index].workarea
            local width = screengeo.width / 2 - beautiful.border_width
            local height = screengeo.height / 2
            c.maximized_horizontal = false
            c.maximized_vertical = false
            c:geometry({ x = screengeo.width / 2, y = screengeo.y,
                         width = width, height = height })
        end),
    awful.key({ "Mod4", "Control" }, "Down",
        function (c)
            -- Tile client to lower right corner.
            local screengeo = screen[c.screen.index].workarea
            local width = screengeo.width / 2 - beautiful.border_width
            local height = screengeo.height / 2 - beautiful.border_width
            c.maximized_horizontal = false
            c.maximized_vertical = false
            c:geometry({ x = screengeo.width / 2, y = screengeo.height / 2,
                         width = width, height = height })
        end),
    awful.key({ "Mod4",           }, "c",
        function (c)
            -- Tile client to center.
            local screengeo = screen[c.screen.index].workarea
            local width = screengeo.width*0.7
            local height = screengeo.height*0.7
            c.maximized_horizontal = false
            c.maximized_vertical = false
            c:geometry({ x = screengeo.x + screengeo.width*0.15, y = screengeo.y + screengeo.height*0.15,
                         width = width, height = height })
        end),
    awful.key({ "Mod4", "Shift"   }, "c",
        function (c)
            -- Move client to center of screen
            local screengeo = screen[c.screen.index].workarea
            local geometry = c:geometry()
            local x_offset = screengeo.width - geometry.width - beautiful.border_width
            local x_offset = x_offset / 2
            local y_offset = screengeo.height - geometry.height - beautiful.border_width
            local y_offset = y_offset / 2
            c:geometry({ x = x_offset, y = y_offset })
        end),
    cyclefocus.key({ "Mod1",           }, "Tab", 1,
        { cycle_filters = { cyclefocus.filters.same_screen,
                            cyclefocus.filters.common_tag } }),
    cyclefocus.key({ "Mod1", "Shift"   }, "Tab", -1,
        { cycle_filters = { cyclefocus.filters.same_screen,
                            cyclefocus.filters.common_tag } })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

-- Multimedia keys
mediakeys = awful.util.table.join(
    awful.key({}, "XF86AudioRaiseVolume",
        function ()
            awful.spawn.with_shell("amixer set Master 2%+")
            show_volume_slider()
        end),
    awful.key({}, "XF86AudioLowerVolume",
        function ()
            awful.spawn.with_shell("amixer set Master 2%-")
            show_volume_slider()
        end),
    awful.key({}, "XF86AudioMute",
        function ()
            awful.spawn("amixer set Master toggle", false)
        end),
    awful.key({}, "XF86AudioPlay",
        function ()
            awful.spawn.easy_async(
                'pidof spotify',
                function(stdout, stderr, exitreason, exitcode)
                    if stdout ~= '' then
                        awful.spawn('sp play')
                    end
                end)
        end),
    awful.key({}, "XF86AudioNext",
        function ()
            awful.spawn.easy_async(
                'pidof spotify',
                function(stdout, stderr, exitreason, exitcode)
                    if stdout ~= '' then
                        awful.spawn('sp next')
                    end
                end)
        end),
    awful.key({}, "XF86AudioPrevious",
        function ()
            awful.spawn.easy_async(
                'pidof spotify',
                function(stdout, stderr, exitreason, exitcode)
                    if stdout ~= '' then
                        awful.spawn('sp prev')
                    end
                end)
        end)
    )


clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(awful.util.table.join(
    globalkeys,
    mediakeys))
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "terminology" },
      properties = { size_hints_honor = false } },
    { rule = { class = "xterm" },
      properties = { size_hints_honor = false } },
    { rule = { class = "Lilyterm" },
      properties = { size_hints_honor = false } }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    awful.placement.no_offscreen(c)
    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
--    naughty.notify({title=c.class})
end)

client.connect_signal('property::class', function(c)
    -- Move Spotify to tag 5 when started.
    if c.class == "Spotify" then
        awful.client.movetotag(tags[1][5], c)
    end
end)

--- Uncomment if killing fullscreen apps enables drawing clients on a wibox.
---
--- client.connect_signal("unmanage", function(c)
---     if c.fullscreen then
---         mywibox[c.screen.index].ontop = true
---     end
--- end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus

    if c.fullscreen then
        mywibox[c.screen.index].ontop = false
    end
end)

client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal

    if c.fullscreen then
        mywibox[c.screen.index].ontop = true
    end
end)

client.connect_signal("property::fullscreen", function (c)
    if c.fullscreen and c == client.focus then
        mywibox[c.screen.index].ontop = false
    else
        mywibox[c.screen.index].ontop = true
    end
end)
-- }}}

-- Startup applications
awful.spawn.with_shell('_conf_keyboard')
awful.spawn.with_shell('shutter --min_at_startup')
awful.spawn.with_shell('xscreensaver')
awful.spawn.with_shell('gnome-keyring-daemon --start')
--awful.spawn.with_shell('kill $(ps -o pid= -C redshift-gtk) ; redshift-gtk')

-- r = string.sub(theme.shadow, 2, 3)
-- g = string.sub(theme.shadow, 4, 5)
-- b = string.sub(theme.shadow, 6, 7)
--
-- r = tonumber(r, 16)/255
-- g = tonumber(g, 16)/255
-- b = tonumber(b, 16)/255
--
awful.spawn.with_shell(
    'compton -c -C' ..
--    ' --shadow-red ' .. r ..
--    ' --shadow-green ' .. g ..
--    ' --shadow-blue ' .. b ..
--    ' -z -m 0.9' ..
    ' --backend glx')
-- }}}

function init_screen(s)
    init_tags(s)
    init_wibox(s)
    set_wallpaper(s)
end

for s in screen do
    init_screen(s)
end
awful.tag.viewonly(tags[1][1])
