# This is an example of
# making an overlay function which
# takes keyword arguments.

# Thus, we don't have to redefine the overlay
# function - it can access current transformation
# from model to paper space.

using LuxorLayout, Luxor
# We have some other images we won't write over. Start after:
countimage_setvalue(19)

# Imagine this is an array of label coordinates,
# which may be changing between taking snaps and increasing
# the canvas size.
const P = [ O,
      O + (100, 0),
      O + (100, 100),
      ]

# Run this to change back to default in-place
P .= [ O,
        O + (100, 0),
        O + (100, 100),
        ]

function draw_P_in_new_model()
    Drawing(NaN, NaN, :rec)
    background("skyblue")
    setcolor("blue")
    inkextent_reset()
    for p in P
        mark_cs(p;labl = "Model")
        encompass(p)
    end
    mark_inkextent()
end

function mark_P_from_overlay(; scale_model_to_paper, O_model)
    setcolor("darkgreen")
    setfont("Helvetica", 15)
    vq = map(P) do p
        O_model + p * scale_model_to_paper
    end
    for q in vq
        q_near = (q + (-100, -50)) * scale_model_to_paper
        arrow(q_near, q)
        txt = "Paper\r ($(round(q[1])), $(round(q[2])))"
        settext(txt, q_near)
    end
    @show scale_model_to_paper
end


# 1 to 1, no transformation between paper and model space. Very easy,
# points should overlap.
draw_P_in_new_model()
snap(mark_P_from_overlay; 
    scale_model_to_paper = scale_limiting_get(),
    O_model = (O - midpoint(inkextent_user_with_margin())) * scale_limiting_get())

# Extend the model canvas to the right and down (+y).
# Now there is a small scaling and a transformation. 
P .*= 4
draw_P_in_new_model()
snap(mark_P_from_overlay; 
    scale_model_to_paper = scale_limiting_get(),
    O_model = (O - midpoint(inkextent_user_with_margin())) * scale_limiting_get())

