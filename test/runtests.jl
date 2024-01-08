using Test
ENV["JULIA_DEBUG"] = "LuxorLayout"

function run_all_tests()
    @testset "model_to_paper_transformation" begin
        include("test_model_to_paper_transformation.jl")
    end
    @testset "snap" begin
        include("test_snap.jl")
    end
    @testset "scale" begin
        include("test_scale.jl")
    end
    @testset "long paths" begin
        include("test_long_svg_paths.jl")
    end
    @testset "snowblind" begin
        include("test_snowblind.jl")
    end
end

# This is copied almost directly from Luxor.jl.
if get(ENV, "LUXORLAYOUT_KEEP_TEST_RESULTS", false) == "true"
    cd(mktempdir(cleanup=false))
    @info("...Keeping the results in: $(pwd())")
    run_all_tests()
    @info("Test images were saved in: $(pwd())")
else
mktempdir() do tmpdir
    cd(tmpdir) do
        msg = """Running tests in: $(pwd())
        but not keeping the results
        because you didn't do: ENV[\"LUXORLAYOUT_KEEP_TEST_RESULTS\"] = \"true\""""
        @info msg
        run_all_tests()
        @info("Test images weren't saved. To see the test images, next time do this before running:")
        @info(" ENV[\"LUXORLAYOUT_KEEP_TEST_RESULTS\"] = \"true\"")
    end
end
end