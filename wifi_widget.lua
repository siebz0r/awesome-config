-- awesome libs
local awful = require("awful")
local beautiful = require("beautiful")
local mouse = require("mouse")
local naughty = require("naughty")
local wibox = require("wibox")
-- extra libs
local vicious = require("vicious")
local lgi = require("lgi")
local Gio = lgi.require("Gio")

graph_text_format = '<span bgcolor="#000000" bgalpha="40%%">%s%%</span>'


-- DBus connection
local bus = Gio.bus_get_sync(Gio.BusType.SYSTEM)

local function dbus_call(service, path, interface, method, callback)
    bus:call(
        service, path, interface, method, nil, nil, 0, -1, nil,
        function(conn, res)
            local ret, err = bus:call_finish(res)
            callback(ret, err)
        end)
end


-- Create a connman api
local connman = {}

function connman:connect(service_path, callback)
    dbus_call(
        'net.connman',
        service_path,
        'net.connman.Service',
        'Connect',
        callback)
end

function connman:get_services(callback)
    dbus_call(
        'net.connman',
        '/',
        'net.connman.Manager',
        'GetServices',
        callback)
end

function connman:scan(callback)
    dbus_call(
        'net.connman',
        '/net/connman/technology/wifi',
        'net.connman.Technology',
        'Scan',
        callback)
end


-- Create wifi widget
local widget = wibox.widget {
    layout = wibox.layout.fixed.horizontal
}
wifi_icon = wibox.widget.imagebox()
wifi_icon:set_image(
    os.getenv("HOME") .. "/.config/awesome/theme/icons/wifi-26.png")
wifi_icon:set_resize(true)
widget:add(wifi_icon)

wifi_bar = wibox.widget {
    widget = wibox.widget.progressbar
}
vicious.register(wifi_bar, vicious.widgets.wifi,
    function (widget, args)
        return args["{linp}"]
    end, 10, "wlan0")

wifi_bar_r = wibox.container.rotate(wifi_bar, 'east')
wifi_bar_r.forced_width = 30

wifi_txt = wibox.widget {
    align = 'center',
    widget = wibox.widget.textbox
}
vicious.register(wifi_txt, vicious.widgets.wifi,
    function (widget, args)
        return string.format(graph_text_format, args["{linp}"])
    end, 10, "wlan0")

wifi_bar_c = wibox.widget {
    wifi_bar_r,
    wifi_txt,
    layout = wibox.layout.stack
}
widget:add(wifi_bar_c)

widget:connect_signal('mouse::enter', function(other, geo)
    local services = wibox.widget {
        layout = wibox.layout.fixed.vertical
    }

    local w = wibox {
        width = 300,
        ontop = true,
        widget = wibox.container.margin(services, 1, 1, 1, 0, beautiful.fg_normal)
    }
    local function close()
        if mouse.current_wibox ~= w then
            w.visible = false
        end
    end
    w:connect_signal('mouse::leave', close)
    widget:connect_signal('mouse::leave', close)

    awful.placement.no_offscreen(w)
    w.visible = true

    local function refresh_services()
        connman:get_services(
            function(ret, err)
                services:reset()

                -- services
                local services_array = ret:get_child_value(0)
                local n_services = services_array:n_children()

                for s = 0, n_services-1 do
                    -- service
                    local service_struct = services_array:get_child_value(s)
                    -- service path
                    local service_path = service_struct:get_child_value(0):get_string()

                    -- service properties
                    local service_props = service_struct:get_child_value(1)
                    local service_props_tbl = {}
                    -- loop through service properties for name
                    for p = 0, service_props:n_children()-1 do
                        local prop = service_props:get_child_value(p)
                        local prop_key = prop:get_child_value(0):get_string()
                        local prop_value_cont = prop:get_child_value(1)
                        local prop_value = prop_value_cont:get_child_value(0)
                        local prop_type_string = prop_value:get_type_string()
                        if prop_type_string == 's' then
                            service_props_tbl[prop_key] = prop_value:get_string()
                        elseif prop_type_string == 'y' then
                            service_props_tbl[prop_key] = prop_value:get_byte()
                        elseif prop_type_string == 'as' then
                            local values = {}
                            local nc = prop_value:n_children()
                            if nc > 0 then
                                for i = 0, nc -1 do
                                    local v = prop_value:get_child_value(i)
                                    local value = v:get_string()
                                    table.insert(values, value)
                                end
                            end
                            service_props_tbl[prop_key] = values
                        end
                    end

                    if service_props_tbl['Type'] == 'wifi' then
                        local service_name_txt = wibox.widget {
                            widget = wibox.widget.textbox,
                            text = service_props_tbl['Name']
                        }
                        local service_state_img = wibox.widget {
                            widget = wibox.widget.imagebox
                        }
                        if service_props_tbl['State'] == 'online' then
                            service_state_img:set_image(os.getenv('HOME') .. '/.config/awesome/theme/icons/globe-26.png')
                        end

                        local service_security_img = wibox.widget {
                            widget = wibox.widget.imagebox
                        }
                        for _, v in pairs(service_props_tbl['Security']) do
                            if v == 'psk' then
                                service_security_img:set_image(os.getenv('HOME') .. '/.config/awesome/theme/icons/lock-26.png')
                            end
                        end

                        local service_strength_bar = wibox.widget {
                            widget = wibox.widget.progressbar,
                            max_value = 100,
                            value = service_props_tbl['Strength']
                        }
                        local service = wibox.widget {
                            service_name_txt,
                            service_state_img,
                            service_security_img,
                            service_strength_bar,
                            forced_height = 11,
                            layout = wibox.layout.flex.horizontal
                        }
                        local service_bg = wibox.container.background(service)
                        local service_margin = wibox.container.margin(service_bg, 1, 1, 1, 1)
                        local service_c = wibox.container.margin(
                            service_margin,
                            0, 0, 0, 1, beautiful.fg_normal)
                        service_c:connect_signal('mouse::enter', function()
                            service_bg.bg = beautiful.selected
                        end)
                        service_c:connect_signal('button::press', function(_, _, _, button)
                            if button == 1 then
                                connman:connect(
                                    service_path,
                                    function(ret, err)
                                        if ret then
                                            naughty.notify({text='Connected to ' .. service_props_tbl['Name']})
                                        else
                                            local err_msgs = {
                                                'Already connected',
                                                'Input/output error'}
                                            local unknown_err = true
                                            for _, msg in pairs(err_msgs) do
                                                if string.match(err.message, msg) then
                                                    unknown_err = false
                                                    naughty.notify({text=msg})
                                                end
                                            end
                                            if unknown_err then
                                                naughty.notify({text=err.message, timeout=0})
                                            end
                                        end
                                    end)
                            end
                        end)
                        service_c:connect_signal('mouse::leave', function()
                            service_bg.bg = nil
                        end)
                        services:add(
                            service_c)
                    else
                        n_services = n_services - 1
                    end
                end
                w.height = 14 * n_services + 1
                awful.placement.next_to(w, {
                    geometry = geo,
                    honor_workarea = true,
                    preferred_positions = {'top', 'right', 'left', 'bottom'}
                })
            end)
        end
        refresh_services()
        connman:scan(function(ret, err)
            refresh_services()
        end)
end)

return widget
