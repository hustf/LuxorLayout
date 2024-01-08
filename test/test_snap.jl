using Test
using LuxorLayout
#using LuxorLayout: scale_limiting_get, LIMITING_WIDTH, LIMITING_HEIGHT,
#    margin_set, origin, BoundingBox, user_origin_in_overlay_space_get, finish, 
#    
import Luxor
using Luxor: Drawing, Point, background, sethue, @layer
using Luxor: O, brush, translate, rotate, origin, finish
using Luxor: midpoint, snapshot, BoundingBox, boxwidth, boxheight

# We have some other images we won't write over. Start after:
countimage_setvalue(19)

"Noone likes decimal points"
roundpt(pt) = Point(round(pt.x), round(pt.y))

"An overlay showing coordinate systems: user, device, output"
function t_overlay(; pt)
    # In the overlay context, the device origin is the 
    # centre of the canvas.
    # The origin here, o4, overlaps o1.
    mark_cs(O; labl = "o4", color = "black", r = 70, dir=:SW)
    mark_cs(roundpt(pt); labl = "pt4", color = "white", r = 80, dir=:SE)
    @layer begin
        translate(pt)
        mark_cs(O; labl = "o5", color = "navy", r = 90, dir=:E)
    end
end

@testset "Target a user space point in an overlay. Pic. 20-22" begin
    @testset "Rotation, but no ink extension past default. Pic. 20 -21" begin
        Drawing(NaN, NaN, :rec)
        background("coral")
        inkextent_reset()
        sethue("grey")
        mark_cs(O, labl = "o1", color = "red", r = 20)
        p = O + (200, -50)
        p |> encompass
        θ = π / 6
        mark_cs(p, labl = "p1", dir =:S, color = "green", r = 30)
        brush(O, p, 2)
        translate(p)
        mark_cs(O, labl = "o2", dir =:E, color = "blue", r = 40)
        rotate(-θ)
        mark_cs(O, labl = "o3", dir =:NW, color = "yellow", r = 50)
        @test point_device_get(O) == p
        outscale = scale_limiting_get()
        cb = inkextent_user_with_margin()
        # The origin of output in user coordinates (assuming default, symmetric margins)
        pto = midpoint(cb)
        mark_cs(roundpt(pto), labl = "pto", dir =:SE, color = "indigo", r = 60)
        # The current user origin in overlay / output / paper space coordinates
        pt = (O - pto) * outscale
        snapshot(;cb, scalefactor = outscale) # No overlay, no file output
        snap("""
            An overlay is a transparent graphic that is applied
            on top of another while saving with <small>snap()</small>.
            This text is an overlay to the circles.

            <b>test_snap.jl</b> explores the problem:

            <i>Having defined one or several points in user space,
            how can we target those points in an overlay?</i>

            Two steps to a solution:

            1) We need to find
            the mapping from
            <i>user</i> space to
            <i>overlay</i> (also paper) space.

            2) Pass that info to the overlay function.

            We could capture info in an argument-less definintion of an
            overlay function. We would then need to redefine 'overlay' when
            the info changes.

            Here, we define <small>overlay(;pt)</small>. The value of 'pt' can change.
            """)
        # `snap` will gobble up any keywords and pass them on to 'overlay'.
        snap(t_overlay, cb, outscale; pt)
    end
    @testset "Rotation and also ink extension. Pic. 22" begin
        Drawing(NaN, NaN, :rec)
        background("darksalmon")
        inkextent_reset()
        sethue("grey")
        mark_cs(O, labl = "o1", color = "red", r = 20)
        p = O + 3 .* (200, -50)
        p |> encompass
        θ = π / 6
        mark_cs(p, labl = "p1", dir =:S, color = "green", r = 30)
        brush(O, p, 2)
        translate(p)
        mark_cs(O, labl = "o2", dir =:E, color = "blue", r = 40)
        rotate(-θ)
        @test rotation_device_get() ≈ -θ
        mark_cs(O, labl = "o3", dir =:NW, color = "yellow", r = 50)
        @test point_device_get(O) == p
        outscale = scale_limiting_get()
        cb = inkextent_user_with_margin()
        # The origin of output in user coordinates:
        pto = midpoint(cb)
        mark_cs(roundpt(pto), labl = "pto", dir =:SE, color = "indigo", r = 60)
        # The current user origin in output coordinates
        pt = (O - pto) * outscale
        snapshot(;cb, scalefactor = outscale)  # No overlay, no file output
        snap(t_overlay, cb, outscale; pt)
    end
end

@testset "user_origin_in_overlay_space_get() - no file output" begin

    @testset " -- no margins or rotation" begin
        Drawing(NaN, NaN, :rec)
        origin()
        margin_set(Margin(0,0,0,0))
        #
        LIMITING_WIDTH[] = 200
        LIMITING_HEIGHT[] = 200
        inkextent_set(BoundingBox(O + (-100, -100), O + (100, 100)))
        @test scale_limiting_get() == 1
        @test boxwidth(inkextent_user_with_margin()) == 200
        @test boxheight(inkextent_user_with_margin()) == 200
        @test user_origin_in_overlay_space_get() == O
        #
        inkextent_set(BoundingBox(O + (-200, -200), O + (200, 200)))
        @test scale_limiting_get() == 0.5
        @test boxwidth(inkextent_user_with_margin()) == 400
        @test boxheight(inkextent_user_with_margin()) == 400
        @test user_origin_in_overlay_space_get() == O
        #
        LIMITING_WIDTH[] = 300
        LIMITING_HEIGHT[] = 300
        inkextent_set(BoundingBox(O + (-200, -200), O + (100, 100)))
        @test scale_limiting_get() == 1
        @test boxwidth(inkextent_user_with_margin()) == 300
        @test boxheight(inkextent_user_with_margin()) == 300
        @test user_origin_in_overlay_space_get() == O + (50, 50)
        #
        inkextent_set(BoundingBox(O + (-2000, -2000), O + (1000, 1000)))
        @test scale_limiting_get() == 0.1
        @test boxwidth(inkextent_user_with_margin()) == 3000
        @test boxheight(inkextent_user_with_margin()) == 3000
        @test user_origin_in_overlay_space_get() == O + (50, 50)
        #
        finish()
    end
    @testset " -- margins bottom left no rotation" begin
        Drawing(NaN, NaN, :rec)
        origin()
        margin_set(Margin(0, 200, 200,0))
        #
        LIMITING_WIDTH[] = 400
        LIMITING_HEIGHT[] = 400
        inkextent_set(BoundingBox(O + (-100, -100), O + (100, 100)))
        @test scale_limiting_get() == 1
        @test boxwidth(inkextent_user_with_margin()) == 200 + 200
        @test boxheight(inkextent_user_with_margin()) == 200 + 200
        @test user_origin_in_overlay_space_get() == O + (100, 100)
        #
        inkextent_set(BoundingBox(O + (-200, -200), O + (200, 200)))
        @test scale_limiting_get() == 0.5
        @test boxwidth(inkextent_user_with_margin()) == 400 + 200/ 0.5
        @test boxheight(inkextent_user_with_margin()) == 400 + 200 / 0.5
        @test user_origin_in_overlay_space_get() == O + (100, 100)
        #
        LIMITING_WIDTH[] = 500
        LIMITING_HEIGHT[] = 500
        inkextent_set(BoundingBox(O + (-200, -200), O + (100, 100)))
        @test scale_limiting_get() == (500 - 200) / 300
        @test boxwidth(inkextent_user_with_margin()) == 300 + 200
        @test boxheight(inkextent_user_with_margin()) == 300 + 200
        @test user_origin_in_overlay_space_get() == O + (150, 150)
        #
        inkextent_set(BoundingBox(O + (-2000, -2000), O + (1000, 1000)))
        @test scale_limiting_get() == (500 - 200) / 3000
        @test boxwidth(inkextent_user_with_margin()) == 3000 + 2000
        @test boxheight(inkextent_user_with_margin()) == 3000 + 2000
        @test user_origin_in_overlay_space_get() == O + (150, 150)
        #
        finish()
    end
end
# Cleanup
LIMITING_HEIGHT[] = 800
LIMITING_WIDTH[] = 800
