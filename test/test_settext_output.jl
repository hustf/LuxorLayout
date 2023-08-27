# `settext` and `text` don't behave intuitively together with Cairo transformations.
# We recommend putting text in paper space, in user-defined 'overlay' functions.
# This explores `settext` and its actual behaviour for possible workarounds.
# If you have already crashed text to png rendering, log out of Windows, log in again.

using Test
using LuxorLayout
import Luxor
using Luxor: Drawing#, Point, background, sethue
using Luxor: O, translate, rotate

function textrotations()
    αs = range(0, 6.2, step = π / 12)
    @layer begin
        sethue("white")
        rdeg = round(rotation_device_get() * 180 / π; digits = 4)
        settext("rotation_device_get() = $(rdeg)°", inkextent_user_get()[1] * 0.15)
        for α in αs
            setline(2π - α)
            randomhue()
            p = O + 300 .*(cos(α), sin(α))
            αdeg = α * 180 / π
            line(O, p; action = :stroke)
            msg = "$(Int(round(αdeg)))°"
            # Angle behaves as desribed in inline docs
            settext(msg, p; angle = - αdeg)
        end
    end
end


# We have some other images we won't write over. Start after:
countimage_setvalue(29) # Check later

# This shows well-defined behaviour, as described in Luxor inline docs.
Drawing(NaN, NaN, :rec)
textrotations()
snap()


# This demonstrates that settext tries to take Cairo rotations into account, but
# does so incorrectly.
Drawing(NaN, NaN, :rec)
@layer begin
    # Make the same drawing, but user space is
    # temporarily rotated 15° clockwise, so 0° is below the horizontal axis.
    rotate(π / 12)
    textrotations()
end
snap()

# Lets try and find a compensation:
function textrotations_comp()
    αs = range(0, 6.2, step = π / 12)
    @layer begin
        sethue("white")
        rdeg = round(rotation_device_get() * 180 / π; digits = 4)
        settext("rotation_device_get() = $(rdeg)°", inkextent_user_get()[1] * 0.25)
        for α in αs
            setline(2π - α)
            randomhue()
            p = O + 300 .*(cos(α), sin(α))
            αdeg = α * 180 / π
            line(O, p; action = :stroke)
            msg = "$(Int(round(αdeg)))°"
            # Angle does not behave as described ; compensate
            settext(msg, p; angle = - αdeg - rdeg)
        end
    end
end

Drawing(NaN, NaN, :rec)
background("salmon")
@layer begin
    # Make the same drawing, but user space is
    # temporarily rotated 15° clockwise, so 0° is below the horizontal axis.
    rotate(π / 12)
    textrotations_comp()
end
snap()


# So, the correct angle argument is:

αdeg = α * 180 / π
rdeg = rotation_device_get() * 180 / π
settext(msg, p; angle = - αdeg - rdeg)