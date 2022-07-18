using Test
using UKBMain
using CSV
using DataFrames

@testset "Test main" begin
    parsed_args = Dict(
        "dataset" => joinpath("data", "ukb_sample_traits.csv"),
        "out-prefix" => "processed",
        "conf" => joinpath("config", "config.yaml"),
        "subset" => nothing
    )
    
    data = UKBMain.read_dataset(parsed_args["dataset"], parsed_args["subset"])
    
    UKBMain.main(parsed_args)

    phenotypes = CSV.read(
        string(parsed_args["out-prefix"], ".phenotypes.csv"), 
        DataFrame
    )

    # 1408 is an ordinal field
    # Negative values are declared missing and other values forwarded
    @test 1408 ∈ UKBMain.ORDINAL_FIELDS
    expected_output = [missing, missing, missing, 3, 3, 1, 3, 2, 3, 1]
    for index in eachindex(expected_output)
        if expected_output[index] === missing
            @test phenotypes[index, "1408-0.0"] === expected_output[index]
        else
            @test phenotypes[index, "1408-0.0"] == expected_output[index]
        end
    end

    # 30270 is a continuous field
    # Values are forwarded
    expected_output = [79.5, 82.61, 81.0, 78.8, 83.16, 73.7, 81.72, 84.0, 75.34, missing]
    @test phenotypes[1:end-1, "30270-0.0"] == expected_output[1:end-1]
    @test phenotypes[end, "30270-0.0"] === expected_output[end]

    # 1707 is a categorical field, 2 codings are queried
    phenotypes[!, "1707_1"] == [true, missing, true, true, missing, true, missing, true, missing, missing]


end