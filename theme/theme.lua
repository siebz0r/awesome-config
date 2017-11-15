---------------------------
-- Default awesome theme --
---------------------------

local gears = require("gears")

theme = {}

theme.font          = "DejaVu Sans 9"

theme.bg_normal     = "#222222"
theme.bg_focus      = "#535d6c"
theme.bg_urgent     = "#ff0000"
theme.bg_minimize   = "#444444"
theme.bg_systray    = theme.bg_normal

theme.fg_normal     = "#aaaaaa"
theme.fg_focus      = "#ffffff"
theme.fg_urgent     = "#ffffff"
theme.fg_minimize   = "#ffffff"

theme.border_width  = 1
theme.border_normal = "#000000"
theme.border_focus  = "#257000"
theme.border_marked = "#91231c"

theme.shadow = '#78AC00'
theme.selected = '#000000'

theme.arcchart_bg = '#000000'

theme.graph_fg = theme.fg_normal
theme.graph_border_color = '#ffffff'

theme.notification_opacity = 0.75

theme.progressbar_border_color = theme.fg_normal
theme.progressbar_bar_border_color = theme.border_normal
theme.progressbar_fg = theme.fg_normal
theme.progressbar_bg = '#000000'
theme.progressbar_shape = gears.shape.octogon
theme.progressbar_bar_shape = gears.shape.octogon

theme.slider_bar_shape = gears.shape.rounded_bar
theme.slider_bar_color = theme.shadow
theme.slider_handle_shape = gears.shape.circle
theme.slider_handle_color = theme.fg_normal

local function wibar_gradient(stops)
    return gears.color.create_pattern({
        type='linear',
        from={0, 0},
        to={0, 22},
        stops=stops
    })
end
theme.wibar_bg = wibar_gradient({
        {0, '#363636'}, -- lightened by 8%
        {0.5, theme.bg_normal},
        {1, '#0d0d0d'} -- 8% darker
    })
theme.tasklist_bg_normal = theme.wibar_bg
theme.tasklist_bg_focus = wibar_gradient({
    {0, '#677180'}, -- lightened by 8%
    {0.5, theme.bg_focus},
    {1, '#3E4857'} -- 8% darker
})
theme.tasklist_bg_minimize = wibar_gradient({
    {0, '#585858'}, -- lightened by 8%
    {0.5, theme.bg_minimize},
    {1, '#2f2f2f'} -- 8% darker
})
theme.tasklist_bg_urgent = wibar_gradient({
    {0, '#ff2929'}, -- lightened by 16%
    {0.5, theme.bg_urgent},
    {1, '#d60000'} -- 16% darker
})

theme.wibar_height = 20

theme.vol_widget_bg = gears.color.create_pattern({
    type='linear',
    from={0, 0},
    to={0, 12},
    stops={
        {0, '#363636'},
        {1, theme.bg_normal}
    }
})

local theme_dir = os.getenv("HOME") .. '/.config/awesome/theme/'
local icon_dir = theme_dir .. 'icons/'

function theme:icon(name)
    return icon_dir .. name .. '-26.png'
end

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- Example:
--theme.taglist_bg_focus = "#ff0000"

-- Display the taglist squares
theme.taglist_squares_sel   = theme_dir .. "/taglist/squarefw.png"
theme.taglist_squares_unsel = theme_dir .. "/taglist/squarew.png"

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = theme_dir .. "/submenu.png"
theme.menu_height = 15
theme.menu_width  = 100

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

-- Define the image to load
theme.wallpaper = theme_dir .. "/background.png"

theme.awesome_icon = "/usr/share/awesome/icons/awesome16.png"
theme.reboot_icon = theme:icon('restart')
theme.shutdown_icon = theme:icon('shutdown')
theme.suspend_icon = theme:icon('sleep')
theme.terminal_icon = theme:icon('console')

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = nil

return theme
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
