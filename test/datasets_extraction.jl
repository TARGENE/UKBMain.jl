module TestDatasetExtraction

using Test
using UKBMain
using CSV
using DataFrames


function test_column_with_missing(expected, actual)
    for j in eachindex(expected)
        value = actual[j]
        if value isa Missing
            @test expected[j] === missing
        else
            @test expected[j] == value
        end
    end
end

@testset "Test filter_and_extract no subset / no withdrawal" begin
    parsed_args = Dict(
        "dataset" => joinpath("data", "ukb_sample_traits.csv"),
        "out" => "extracted.csv",
        "conf" => joinpath("config", "config.yaml"),
        "withdrawal-list" => nothing,
        "verbosity" => 0
    )
    
    filter_and_extract(parsed_args)

    traits = CSV.read(parsed_args["out"], DataFrame)
    @test size(traits) == (10, 21)

    # 1707 is a categorical field
    test_column_with_missing(
        traits[!, "1707"], 
        [1, 1, 2, 2, missing, missing, 3, 2, 1, 3]
    )

    # 1777 is a categorical field
    test_column_with_missing(
        traits[!, "1777"], 
        [1, 0, 0, missing, missing, missing, 1, 0, 1, 1]
    )

    # 40006 is a categorical trait
    # In theory all columns will contain at least one non-missing value
    # In this example, only the 3 first columns contain non-missing values
    @test traits[:, "disease_1"] == [true, false, false, true, false, false, true, false, false, false]
    @test traits[:, "disease_2"] == [true, false, false, false, false, false, false, false, false, false]

    # 20002 is a categorical trait 
    # with multiple instances that correspond to the assessment visit
    # Reporting the disease at any of those visits results as the 
    # disease considered declared
    @test traits[:, "disease_3"] == [true, false, true, true, true, false, true, false, false, true]
    @test traits[:, "disease_4"] == [false, false, false, false, false, false, true, false, true, false]
    @test traits[:, "disease_5"] == [false, false, false, false, false, false, false, false, false, false]

    # 41202 | 41204 both are categorical
    # The presence of a disease in any of those fields results as the
    # disease considered declared
    @test traits[:, "disease_6"] == [true, true, false, true, false, false, false, true, false, true]
    @test traits[:, "disease_7"] == [false, false, false, false, false, false, false, false, true, true]
    @test traits[:, "disease_8"] == [false, true, false, false, false, true, false, false, false, true]

    # 1408 is an ordinal field
    # Negative values are declared missing and other values forwarded
    @test 1408 ∈ UKBMain.ORDINAL_FIELDS
    test_column_with_missing(
        traits[!, "1408"], 
        [missing, missing, missing, 3, 3, 1, 3, 2, 3, missing]
    )

    # 30270 is a continuous field
    # Values are forwarded
    test_column_with_missing(
        traits[!, "30270"], 
        [79.5, 82.61, 81.0, 78.8, 83.16, 73.7, 81.72, 84.0, 75.34, missing]
    )

    @test traits[!, "ethnicity"] == [1001, 2, 3002, 6, 1001, 1001, 1001, 1001, 1001, 4001]

    test_column_with_missing(
        traits[!, "genetic sex"], 
        [1, 0, 0, 0, 1, 1, 0, 1, 1, missing]
    )

    test_column_with_missing(
        traits[!, "age"], 
        [64, 42, 44, 46, 49, 57, 45, 57, 42, 61]
    )

    rm(parsed_args["out"])
end

@testset "Test filter_and_extract subset / withdrawal" begin
    parsed_args = Dict(
        "dataset" => joinpath("data", "ukb_sample_traits.csv"),
        "out" => "extracted",
        "conf" => joinpath("config", "config_with_subset.yaml"),
        "withdrawal-list" => joinpath("data", "withdrawal_list.txt"),
        "verbosity" => 0
    )
    
    filter_and_extract(parsed_args)

    traits = CSV.read(parsed_args["out"], DataFrame)
    # ethnicity filter will keep samples: 1, 3, 5:9
    # sex filter will keep samples: 2, 3, 4, 7
    # withdrawal list will remove sample 7
    # => remain sample 3
    @test traits == DataFrame(
        [[3], [2], [1], [1], [false], [false], [true]], 
        ["SAMPLE_ID", "1379", "1329", "1339", "disease_1", "disease_2", "disease_3"]
    )

    rm(parsed_args["out"])
end

@testset "Test filter_and_extract subset / no withdrawal" begin
    parsed_args = Dict(
        "dataset" => joinpath("data", "ukb_sample_traits.csv"),
        "out" => "extracted.csv",
        "conf" => joinpath("config", "config_with_subset.yaml"),
        "withdrawal-list" => nothing,
        "verbosity" => 0
    )
    
    filter_and_extract(parsed_args)

    traits = CSV.read(parsed_args["out"], DataFrame)
    # ethnicity filter will keep samples: 1, 3, 5:9
    # sex filter will keep samples: 2, 3, 4, 7
    # => remain sample 3, 7
    @test traits == DataFrame(
        [[3, 7], [2, 2], [1, 1], [1, 1], [false, true], [false, false], [true, true]], 
        ["SAMPLE_ID", "1379", "1329", "1339", "disease_1", "disease_2", "disease_3"]
    )
    rm(parsed_args["out"])
end

end

true