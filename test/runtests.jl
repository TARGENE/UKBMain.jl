using UKBMain
using Test
using CSV
using DataFrames

@testset "Test main" begin
    parsed_args = Dict(
        "dataset" => "/home/s2042526/UK-BioBank-53116/phenotypes/output.csv",
        "out-prefix" => "processed",
        "conf" => joinpath("/exports/eddie/scratch/s2042526/dev/UKBMain.jl/", "config", "config.yaml"),
        "subset" => nothing
    )
    

end