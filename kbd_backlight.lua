local kbd_backlight = {}

function open(mode)
    -- Open the backlight file with the given mode.
    return io.open('/sys/class/leds/asus::kbd_backlight/brightness', mode)
end

function read(file)
    -- Read the given file to a number and return that number.
    value = tonumber(file:read())
    file:close()
    return value
end

function write(file, value)
    -- Write the given value to the given file.
    file:write(value)
    file:close()
end

function kbd_backlight:up()
    -- Increment the backlight value.
    value = read(open('r'))
    print(value)
    if value < 3 then
        value = value + 1
        write(open('w'), value)
    end
end

function kbd_backlight:down()
    -- Decrement the backlight value.
    value = read(open('r'))
    if value > 0 then
        value = value - 1
        write(open('w'), value)
    end
end

return kbd_backlight
