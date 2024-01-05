using Test
using LuxorLayout
using LuxorLayout: LIMITING_WIDTH, LIMITING_HEIGHT, scale_limiting_get # Not public
import Luxor
using Luxor: Drawing, Point, O, BoundingBox, rotate, translate, scale
using Luxor: boxwidth, boxheight, background, blend
using Luxor: setblend, paint, setcolor, setopacity, sethue
using Luxor: dimension, text, rect, circle, line, origin

# We have some old images we won't overwrite. Start after:
countimage_setvalue(49)
@testset "Viewport extension without work (user)-space scaling. Pic. 50-52" begin
    Drawing(NaN, NaN, :rec)
    # Margins are set in 'output' points.
    # They are scaled to user coordinates where needed.
    m = margin_set(Margin())
    t1, b1, l1, r1 = m.t, m.b, m.l, m.r
    inkextent_reset()
    s1 = scale_limiting_get()
    @test s1 == 1
    mark_inkextent()
    # Add a background with transparency - the old inkextent
    # will show.
    background(Luxor.RGBA(1.0,0.922,0.804, 0.5))
    # Expand inkextent by adding graphics and |> encompass
    setcolor("darkblue")
    for y in range(0, 1200, step = 300)
        text("y $y", Point(0, y)) |> encompass
    end
    mark_inkextent()
    snap("This is overlain") #50
    # Desired output with margins is either
    #   800 x   800 
    #   800 x <=800
    # <=800 x   800
    # scale_limiting_get() returns the scaling to fit within margins.
    bb2 = inkextent_user_get()
    s2 = scale_limiting_get() 
    # svg file + png file + png in memory.
    pic2 = snap()           #51
    @test pic2.width == 415
    @test pic2.height == 800
    # Increasing (the left) margin by 100 expands inwards
    # (possibly changing the scale to fit inkextent), not outwards
    # (the output image will not grow larger)
    margin_set(;l = 32 + 100)
    bb3 = inkextent_user_get()
    s3 = scale_limiting_get() 
    @test boxwidth(bb2) == boxwidth(bb3)
    # In this case, the necessary scaling was unchanged,
    # as the height of inkextent, top and bottom margin
    # determines the scaling. We had room to add a wider 
    # left margin and could still fit in the output image. 
    @test s2 == s3

    # We can add rectangles as normal - they are not taken to be background
    setcolor("burlywood")
    setopacity(0.65)
    rect(O + (-1000, 0), 1000, 1200, action = :fill) |> encompass
    setopacity(1.0)
    bb3 = inkextent_user_get()
    @test boxwidth(bb3) == 1368
    @test boxheight(bb3) == 1576
    setcolor("darkblue")
    mark_inkextent()
    s4 = scale_limiting_get()
    @test s4 < s3
    pic3 = snap() # 52 svg file + png file + png in memory
    @test pic3.height < 800
    @test pic3.width == 800
end

@testset "User / work -space to device space: Zooming out. No pic." begin
    Drawing(NaN, NaN, :rec)
    inkextent_reset()
    margin_set(Margin())
    bbo = inkextent_user_get()
    @test all(inkextent_device_get() .== bbo)
    #
    # Set scaling transformation from user to device space.
    sc = 0.5
    scale(sc)
    # i.e. (1,1) in user space now maps to (0.5, 0.5) in device space.
    # Inkextents are "really" set in device coordinates.
    # So the unchanged ink extents, when mapped to user coordinates,
    # just doubled in width and height.
    bbn = inkextent_user_get()
    @test boxwidth(bbn) / boxwidth(bbo) == 2
    @test boxheight(bbo) / boxheight(bbn) == sc
    @test round(scale_limiting_get(), digits = 5) == sc
end

@testset "User to device space: Zooming in. Pic. 53-54" begin
    Drawing(NaN, NaN, :rec)
    margin_set(Margin())
    inkextent_reset()
    background("chocolate")
    bbo = inkextent_user_get()
    #
    # Set scaling transformation from user to device space.
    sc = 4
    scale(sc)
    # i.e. (1,1) in user space now maps to (4, 4) in device space.
    w = boxwidth(inkextent_user_get())
    h = boxheight(inkextent_user_get())
    @test w / boxwidth(bbo) == 0.25
    @test boxheight(bbo) / h == sc
    @test w == 184
    setcolor("burlywood")
    format = (x) -> string(Int64(round(x)))
    dimension(O + (-w / 2, 50), O + (w / 2 , 50); format)
    dimension(O, O + (w / 2 , 0); format)
    dimension(O + (60, h / 2) , O + (60 , 0); format)
    dimension(O + (70, h / 2) , O + (70 , -h / 2); format)
    mark_inkextent()
    pic1 = snap("""
        User to device space: Zooming in
        by calling `scale($sc)`.""") #53
    # Drawing outside inkextents enlarges output too.
    pt = inkextent_user_get().corner2
    encompass(circle(pt, 50, :stroke))
    dbb = BoundingBox(inkextent_user_get().corner1, pt + (50, 50))
    @test all(inkextent_user_get() .== dbb)
    @test scale_limiting_get() < sc
    mark_inkextent()
    pic2 = snap("""
        We increased ink extents by (50,50 )
        without changing user space scaling ($sc).

        <small>snap()</small> will still output an image with
        the same outside dimensions.

        The scaling applied internally in 'snap' is:
            <small>scale_limiting_get()</small> = $(round(scale_limiting_get(), digits=4)).
        """)
    # There's a 0 / 1 thing going on with png output. 799 ≈ 800 anyway.
    @test abs(pic2.width - pic1.width) <= 1
end

@testset "Rotation. Pic. 56" begin
    Drawing(NaN, NaN, :rec)
    margin_set(Margin())
    inkextent_reset()
    background("blanchedalmond")
    ubb = inkextent_user_get()
    w1 = boxwidth(ubb)
    h1 = boxheight(ubb)
    ad = atan(h1 / w1)
    setopacity(0.5)
    rect(ubb.corner1, w1, h1, :fill)
    snap()
    a = 30 * π / 180
    # x is right, y is down, positive z is into the canvas.
    # Hence, positive rotation around z means the output / the device projection is 
    # rotated positive around z. That is, clockwise as seen from negative z.
    rotate(a)
    # This leads to scaling, which is complicated to foresee because
    # the margins in output are kept the same after scaling.
    @test round(scale_limiting_get(), digits = 4) == 0.7263
    setopacity(0.3)
    sethue("lightblue")
    # This demonstrates why we must keep track of
    # ink extents in device space rather than in 'user / work' space:
    # We're marking the inkextents in current user space,
    # but we do not encompass the user space.
    mark_inkextent()
    rect(ubb.corner1, w1, h1, :fill) |> encompass
    rotate(-a) # Back to normal. What we did last should be rotated clockwise
                # at output.
    setopacity(0.1)
    mark_inkextent()
    pic1 = snap("""
        This demonstrates why we keep track of
        ink extents in <i>device</i> space rather than in
        <i>user / work</i> space:
          1) Mark default <i>inkextent</i> - solid grey. It's slightly higher 
             than wide because side margins are larger.
          2) Set a clockwise rotation mapping from <i>user</i> to <i>device</i>.
          3) Draw a solid blue rectangle - same width and height.
          4) Encompass the blue rectangle, too, within <i>ink extent</i>.
          5) Mark <small>inkextent_user_get()</small> - dashed.
          6) Rotate back - <i>user</i> and <i>device</i> are aligned again
          7) Mark <small>inkextent_user_get()</small> - dashed and lighter. 
             This is larger than the solid grey one.

        A scale mapping is applied during output, to fit ink extents 
        as well as scaled margins within 800x800 points. 
            <small>scale_limiting_get()</small> = $(round(scale_limiting_get(), digits=3))

        In this case, width limits scaling. Output is 800 x 692.
    """)
    wr = boxwidth(inkextent_user_get()) / boxwidth(ubb)
    wre = cos(ad - a) / cos(ad)
    @test wr ≈ wre
    @test abs(pic1.width - 800) <= 1
    @test abs(pic1.height - 788) <= 1
end

@testset "Changing output size, blend background. Pic. 57" begin
    LIMITING_WIDTH[] = 400
    LIMITING_HEIGHT[] = 300
    Drawing(NaN, NaN, :rec)
    inkextent_reset()
    margin_set(Margin())
    w = boxwidth(inkextent_user_get())
    h = boxheight(inkextent_user_get())
    @test w == 336
    @test h == 252
    @test w + margin_get().l + margin_get().r == 400  
    @test h + margin_get().t + margin_get().b == 300
    # We're making a special kind of background here...
    # .svg output is post-processed as normal.
    orangered = blend(Point(-150, 0), Point(150, 0), "orange", "darkred")
    rotate(π/3)
    setblend(orangered)
    paint()
    rotate(-π/3)
    setcolor("burlywood")
    format = (x) -> string(Int64(round(x)))
    dimension(O + (-w / 2, 50), O + (w / 2 , 50); format)
    dimension(O, O + (w / 2 , 0); format)
    dimension(O + (40, h / 2) , O + (40 , 0); format)
    dimension(O + (100, h / 2) , O + (100 , -h / 2); format)
    mark_inkextent()
    pic1 = snap("""\r
         <small>snap()</small> outputs 400 x 300. 
         <small>scale_limiting_get()</small> = $(round(scale_limiting_get(), digits=4)).
         svg colors ≠ png colors 
    """)
    @test abs(pic1.width - 400) <= 1
    @test abs(pic1.height - 300) <= 1 # 204
end
@testset "Transform both ways - translate" begin
    Drawing(NaN, NaN, :rec)
    background("orange")
    @test point_device_get(O) == O
    @test point_user_get(O) == O
    translate(O + (100, 0))
    @test point_device_get(O) == O + (100, 0)
    @test point_user_get( O + (100, 0)) == O 
end
@testset "Transform both ways - translate 2" begin
    Drawing(NaN, NaN, :rec)
    @test point_device_get(O) == O
    @test point_user_get(O) == O
    translate(O + (100, 100))
    @test point_device_get(O) == O + (100, 100)
    @test point_user_get( O + (100, 100)) == O 
end

@testset "Transform both ways - rotate " begin
    Drawing(NaN, NaN, :rec)
    @test point_device_get(O) == O
    @test point_user_get(O) == O
    rotate(atan(1))
    pu = O + (100, 0)
    pd =  O + cos(atan(1)) .* (100, 100)
    @test point_device_get(pu) == pd
    @test point_user_get(pd) == pu 
end
@testset "Transform both ways - transform " begin
    Drawing(NaN, NaN, :rec)
    @test point_device_get(O) == O
    @test point_user_get(O) == O
    rotate(atan(1))
    translate(O + (100, 0))
    pu = O
    pd =  O + cos(atan(1)) .* (100, 100)
    @test point_device_get(pu) == pd
    @test point_user_get(pd) == pu 
end
@testset "Transform both ways - opposite order transform " begin
    Drawing(NaN, NaN, :rec)
    @test point_device_get(O) == O
    @test point_user_get(O) == O
    translate(O + (100, 0))
    rotate(atan(1))
    pu = O
    pd =  O + (100, 0)
    @test point_device_get(pu) == pd
    @test point_user_get(pd) == pu
    pu1 = O + (100, 0)
    pd1 =  O + (100, 0) + cos(atan(1)) .* (100, 100)
    @test point_device_get(pu1) == pd1
    @test point_user_get(pd1) == pu1 
    # Get rid of the current transformation (Drawing finish does not do that)
    origin()
    Luxor.finish()
end
# Don't cause harm, reset
LIMITING_WIDTH[] = 800
LIMITING_HEIGHT[] = 800


@testset "Fit A4 page printable area. Pic. 58" begin
    # The dots density we decide on is not decisive, if
    # we are planning to print based on vector graphics.
    # Inskape seems to have a default assumption of 96,
    # so we can work from that. One option for printing
    # of large images is to split an svg into page-sized
    # rectangles with bitmap. In that case, we can decide the
    # pixel resolution later.
    """ ```
    julia> dpmm = 96/inch |> mm # dots per mm, Inkscape's default
    (480//127)mm⁻¹
    
    julia> (210., 297.)mm .* dpmm # Points per A4. A4 outside size is 210mm x 297mm
    (793.7007874015748, 1122.51968503937)
    
    julia> (210. - 2*5, 297. - 2*5)mm .* ρ  # Printable points per A4, 5mm unprintable all sides.
    (755.9055118110236, 1084.724409448819)
    ```
    # But Inkscape's printing is buggy (straight lines disappear and other issues exist).
    # Another source of standard is PostScript, which use 72 pts/inch. Also, 595 x 842 points per A4:
    ```
    julia> dpmm = 72/inch |> mm
    (360//127)mm⁻¹

    julia> (210., 297.)mm .* dpmm
    (595.275590551181, 841.8897637795275)
    ```
    So, this is outside dimensions. But subtracting 10mm for 'gutter' margin is
    insignificant. We'll stick to 595x842 as a definition, and neglect 'gutter margins'.
    """

    dpmm = 360 / 127
    # edges_mm = 5
    #w = Int(ceil((210 - edges_mm) * dpmm)) 
    #h = Int(ceil((297 - edges_mm) * dpmm))
    w, h = 595, 842
    # These can be set regardless of Drawing being activated.
    LIMITING_WIDTH[] = w
    LIMITING_HEIGHT[] = h
    margin_set(;t = 0, b = 0, l =0, r = 0)
    inkextent_reset()
    #
    @test boxwidth(LuxorLayout.inkextent_default()) == w
    @test boxwidth(inkextent_user_with_margin()) == w
    @test boxheight(inkextent_user_with_margin()) == h
    @test scale_limiting_get() == 1.0
    @test all(inkextent_user_get() .== inkextent_user_with_margin())
    # Activating a Drawing doesn't change things.
    Drawing(NaN, NaN, :rec)
    @test boxwidth(inkextent_user_with_margin()) == w
    @test boxheight(inkextent_user_with_margin()) == h
    @test scale_limiting_get() == 1.0
    @test all(inkextent_user_get() .== inkextent_user_with_margin())
    # Let's draw something
    background("salmon")
    setcolor("blue")
    bb = inkextent_user_get()
    line(bb.corner1, bb.corner2, :stroke)
    # Let's draw a length we can measure on prints
    l = 150 * dpmm # 150mm converted to points
    format = (x) -> string(Int64(round(x / dpmm))) * "mm"
    # Horizontal
    dimension(O + (-l / 2, l / 2), O + (l / 2 , l / 2); format, 
        textrotation = -π/2, textgap = 20)
    # Vertical 
    dimension(O + (l / 2, l / 2), O + (l / 2, -l / 2); format)
    snap("This should be a printable A4 page\n ($w x $h)pt @$(Int(round(dpmm * 25.4)))dpi") 
    Luxor.finish()
end
# Don't cause harm, reset
LIMITING_WIDTH[] = 800
LIMITING_HEIGHT[] = 800

@testset "2 A4 pages, side by side, magins, scale 2. Pic. 59" begin
    w, h = 2 * 595, 842
    # These can be set regardless of Drawing being activated.
    LIMITING_WIDTH[] = w
    LIMITING_HEIGHT[] = h
    m = margin_set(;t = 30, b = 50, l = 70, r = 90)
    inkextent_reset() # this means 'scale 1:1' in a way
    #
    @test boxwidth(LuxorLayout.inkextent_default()) + m.l + m.r == w
    @test boxwidth(inkextent_user_with_margin()) == w
    @test boxheight(LuxorLayout.inkextent_default()) + m.t + m.b == h
    @test boxheight(inkextent_user_with_margin()) == h
    @test scale_limiting_get() == 1.0
    # Activating a Drawing doesn't change things.
    Drawing(NaN, NaN, :rec)
    @test boxwidth(inkextent_user_with_margin()) == w
    @test boxheight(inkextent_user_with_margin()) == h
    @test scale_limiting_get() == 1.0
    bb = inkextent_user_get()
    wu = boxwidth(bb)
    wh = boxheight(bb)
    @test wu + m.l + m.r == w
    @test wh + m.t + m.b == h
    # Let's draw something
    background("white")
    setcolor("blue")
    p1, p2, p3, p4 = LuxorLayout.four_corners(bb)
    # This increases the ink extent be a factor of 2.
    # Model to paper scale changes to 1 / 2 = 0.5
    pttl = 2 * p1
    ptbr = 2 * p3
    encompass(pttl)
    encompass(ptbr)
    line(pttl, ptbr, :stroke)
    @test round(scale_limiting_get(); digits = 5) == 0.5
    # Let's mark ink extents now... In order to visualize the margins better.
    p1, p2, p3, p4 = LuxorLayout.four_corners(inkextent_user_get())
    line(p1, p2, :stroke)
    line(p2, p3, :stroke)
    line(p3, p4, :stroke)
    line(p4, p1, :stroke)
    # Let's draw a length we can measure on prints.
    dpmm = 360 / 127 # This is the scaling of the output image, or of the overlay.
    l = 150 * dpmm # 150mm converted to points. Since the ink extents is now larger, we 
                   # will measure 75mm on the paper output.
    format = (x) -> string(Int64(round(x / dpmm))) * "mm in 'model space'"
    # Horizontal
    dimension(O + (-l / 2, l / 2), O + (l / 2 , l / 2); format, 
        textrotation = -π/2, textgap = 20)
    # Vertical 
    dimension(O + (l / 2, l / 2), O + (l / 2, -l / 2); format)
    snap("This should fit on two A4 pages, side by side\n and with margins $m \n ($w x $h)pt @$(Int(round(dpmm * 25.4)))dpi")
    Luxor.finish()
end
# Don't cause harm, reset
LIMITING_WIDTH[] = 800
LIMITING_HEIGHT[] = 800
margin_set(Margin(24, 24, 32, 32))
