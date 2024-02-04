# LuxorLayout

This adds layout functionality to [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl). 

It also "fixes" Cairo's issue [#349](https://github.com/JuliaGraphics/Cairo.jl/issues/349) by pinning Pango to a version fully working on Windows.

The package is registered in registry [M8](https://github.com/hustf/M8):
To use:

```
(@v1.9) pkg> registry add https://github.com/hustf/M8
julia> using LuxorLayout
julia> import Luxor
julia> using Luxor: circle, etc.... 
```

This loads LuxorLayout's [public interface](#Public-interface).


## Paper space and model space
Users are familiar with [Luxor.jl](https://github.com/JuliaGraphics/Luxor.jl), where the basic use case is how to draw pixels on a screen and save to an image file. The user threshold is low. This package separates the mental model into 'model space' and 'paper space':

<img src="resources/spaces.svg" alt = "spaces" style="display: inline-block; margin: 0 auto; max-width: 640px">

You will be drawing in 'model space' (figure right) and annotating in 'paper space' (figure left). 'Paper space' works like a window, where width and breadth equals the intended output image file. Annotations are temporary writing on that window for a particular snapshot.

In paper space, readable text should be in a readable size, e.g. 12 pixels. Margins are also relative to paper space. 

In model space, Luxor (based on [Cairo](https://github.com/JuliaGraphics/Cairo.jl)) does not need to know if '1' is one kilometer or centimeter. Model space is actually boundless. Model space coordinates are unitless, but you will often have a length unit in mind. 

## What this package adds 
### Overlay

<img src="resources/overlay.svg" alt = "overlay" style="display: inline-block; margin: 0 auto; max-width: 640px">

This packackage adds an 'overlay'. Every time we take a snapshot, i.e. project model space onto paper space and generate an image file, we can also overlay an annotation drawing. The overlay is generated in a separate thread, and does not inherit the current line width, color, coordinate system, etcetera. We also provide transformation functions, in case you will want to point an arrow at that star.

### Margin and ink extents
<img src="resources/margin.svg" alt = "margin" style="display: inline-block; margin: 0 auto; max-width: 640px">

This package also helps keep track of ink extents (the rectangle in model space in which you have drawn). From the get-go

It will scale ink extents to fit within paper space margins. This would otherwise be a rather tedious task, especially when rotated coordinate systems are involved.


### It can count, too
As you build a model, making up names for files get tedious. `snap` makes sequential file names. 


## Other words for model and paper space

We like the mental model of 'Model space' and 'Paper space'. It comes from AutoCAD, the Excel of computer aided design. The mental model in Cairo documentation is better for implementing the program.

 Still, we keep the terminology from Cairo (and Luxor) in function names and code. Here is an arguable translation table:


| Application | Window              |  Model          |
|:-----       |:----                |:----            |
|AutoCAD      |Paper space          |Model space      |
|Luxor        |Drawing              |World coordinates| 
|Cairo        |Surface              |Device space     |
|             |Destination          |Source           |

We should add all kinds of caveats here, mainly: 

    -'Source' and 'Destination' is used to describe other relations. 
    -'User space' begs for a mention here. But no!

  ### Public interface

See inline documentation for more.
<details>

 1. Margin and limiting width or height

    * margin_get
    * margin_set
    * Margin
    * factor_user_to_overlay_get
    * LIMITING_WIDTH
    * LIMITING_HEIGHT

 2. Inkextent
    * encompass
    * inkextent_set
    * inkextent_reset
    * inkextent_user_with_margin
    * inkextent_user_get
    * inkextent_device_get
    * point_device_get
    * point_user_get
    

 3. Overlay file

    * text_on_overlay
    * user_origin_in_overlay_space_get

 4. Snap

     -> png and svg sequential files

     -> png in memory

     Uses a second thread to add overlays

    * snap
    * countimage_set

 5. Utilities for user and debugging

     * mark_inkextent
     * mark_cs
     * rotation_device_get
     * distance_to_device_origin_get

</details>


  ### All functions, structured

  But first, check out the public interface functions.

<details>
 1. Margins and limiting width or height

    margin_get, margin_set, Margin, 
    factor_user_to_overlay_get,
    LIMITING_WIDTH[], LIMITING_HEIGHT[]

 2. Inkextent

```
    encompass, inkextent_user_with_margin,
    inkextent_reset, inkextent_user_get, 
    inkextent_set, inkextent_device_get, 
    point_device_get, point_user_get
```

 3. Overlay file

    This is normally run in a second thread with a separate Cairo instance.
```
    byte_description, overlay_file,
    assert_second_thread, assert_file_exists,
    text_on_overlay, user_origin_in_overlay_space_get
```

 4. Snap

     -> png and svg sequential files

     -> png in memory uses a second thread to add overlays.

```
    snap, countimage, countimage_set,
    text_on_overlay
```

 5. Utilities for user and debugging

```
     mark_inkextent, mark_cs, 
     rotation_device_get, distance_to_device_origin_get
```

</details>


## Default settings

Some defaults are inevitable. Let's have a look:

```
julia> using Luxor, LuxorLayout; Drawing(NaN, NaN, :rec)
 Luxor drawing: (type = :rec, width = NaN, height = NaN, location = in memory)

julia> LIMITING_WIDTH[], LIMITING_HEIGHT[] # 'paper space' dimensions, outside
(800, 800)

julia> margin_get()  # 'paper space' margins, subtracted from outside
Margin(t = 24, b = 24, l = 32, r = 32)

julia> inkextent_user_with_margin()
 ⤡ Point(-400.0, -400.0) : Point(400.0, 400.0)

julia> inkextent_user_get()
 ⤡ Point(-368.0, -376.0) : Point(368.0, 376.0)

julia> LuxorLayout.factor_user_to_overlay_get()
1.0

julia> mark_cs(O);mark_inkextent()

julia> snap()
```

<img src="resources/1.svg" alt = "1.svg" style="display: inline-block; margin: 0 auto; max-width: 640px">


File '1.svg' is 800x800 points, '1.png' is 800x800 pixels. The transparent background is shown differently depending on where you display the file.

If you draw outside of default ink extents, `⤡ Point(-368.0, -376.0) : Point(368.0, 376.0)`, call `encompass` with the new point and ink extents will increase. Output through `snap` remain 800x800, but `scale_limting_get` will decrease.

See the examples:

*    [Snowblind](test/test_snowblind.md) Large scales, rotations, overlays pointing to model space
*    [Scale](test/test_scale.md)
*    [Snap](test/test_snap.md)
*    [Long svg paths](test/test_long_svg_paths.md)

## Small model spaces

Model spaces smaller than 736 x 752 distance units need to reduce the default ink extents, thus (continued example):

```
julia> inkextent_set(BoundingBox(O, O + (50, 50)))
 ⤡ Point(0.0, 0.0) : Point(50.0, 50.0)

julia> snap()
```
<img src="resources/2.svg" alt = "2.svg" style="display: inline-block; margin: 0 auto; max-width: 640px">
