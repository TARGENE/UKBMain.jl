using Test
using UKBMain
using CSV
using DataFrames

@testset "Test main with phenotypes, covariates and confounders" begin
    parsed_args = Dict(
        "dataset" => joinpath("data", "ukb_sample_traits.csv"),
        "out-prefix" => "processed",
        "conf" => joinpath("config", "config.yaml"),
    )
    
    filter_and_extract(parsed_args)

    # Check phenotypes output
    binary_phenotypes_outfile = string(parsed_args["out-prefix"], ".binary.phenotypes.csv")
    binary_phenotypes = CSV.read(binary_phenotypes_outfile, DataFrame)
    # Check columns
    @test names(binary_phenotypes) == ["1707_1",
                                "1707_2",
                                "1777_1",
                                "40006_C43",
                                "40006_Block D37-D48",
                                "40006_D41",
                                "40006_C44",
                                "20002_1674",
                                "20002_1065",
                                "20002_1066",
                                "20002_1067",
                                "20002_1762",
                                "41202 | 41204_Block J40-J47",
                                "41202 | 41204_O26",
                                "41202 | 41204_O20",
                                "41202 | 41204_Block A30-A49",
                                "41202 | 41204_K44",
                                "41202 | 41204_G20"]
    @test size(binary_phenotypes) == (10, 18)

    # 1707 is a categorical field, 2 codings are queried
    @test binary_phenotypes[!, "1707_1"] == [1, 0, 1, 1, 0, 1, 0, 1, 0, 0]
    @test binary_phenotypes[!, "1707_2"] == [0, 0, 0, 0, 1, 0, 1, 0, 0, 0]
    
    # 40006 is a categorical trait
    # In theory all columns will contain at least one non-missing value
    # In this example, only the 3 first columns contain non-missing values
    @test binary_phenotypes[:, "40006_Block D37-D48"] == [true, false, false, true, false, true, false, false, false, false]
    @test binary_phenotypes[:, "40006_C43"] == [true, false, false, false, false, false, true, false, false, false]
    @test binary_phenotypes[:, "40006_D41"] == [false, false, false, false, false, false, true, false, false, false]
    @test binary_phenotypes[:, "40006_C44"] == [true, false, false, true, false, false, false, false, false, false]

    # 20002 is a categorical trait 
    # with multiple instances that correspond to the assessment visit
    # Reporting the disease at any of those visits results as the 
    # disease considered declared
    @test binary_phenotypes[:, "20002_1674"] == [false, false, false, false, false, false, false, false, false, false]
    @test binary_phenotypes[:, "20002_1065"] == [false, false, false, true, false, false, true, false, false, true]
    @test binary_phenotypes[:, "20002_1066"] == [true, false, true, false, true, false, false, false, false, false]
    @test binary_phenotypes[:, "20002_1067"] == [true, false, false, false, true, false, false, false, false, false]
    @test binary_phenotypes[:, "20002_1762"] == [false, false, false, false, false, false, true, false, true, false]

    # 41202 | 41204 both are categorical
    # The presence of a disease in any of those fields results as the
    # disease considered declared
    @test binary_phenotypes[:, "41202 | 41204_Block J40-J47"] == [false, false, false, false, false, false, false, false, false, false]
    @test binary_phenotypes[:, "41202 | 41204_O26"] == [true, false, false, false, false, false, false, false, false, false]
    @test binary_phenotypes[:, "41202 | 41204_O20"] == [false, false, false, false, false, false, false, false, false, false]
    @test binary_phenotypes[:, "41202 | 41204_Block A30-A49"] == [false, false, false, false, false, false, false, false, false, false]
    @test binary_phenotypes[:, "41202 | 41204_K44"] == [true, false, true, false, false, false, false, false, false, false]
    @test binary_phenotypes[:, "41202 | 41204_G20"] == [false, false, false, false, false, false, false, false, false, true]
    
    rm(binary_phenotypes_outfile)

    continuous_phenotypes_outfile = string(parsed_args["out-prefix"], ".continuous.phenotypes.csv")
    continuous_phenotypes = CSV.read(continuous_phenotypes_outfile, DataFrame)
    @test names(continuous_phenotypes) == ["1408-0.0",
                                           "1727-0.0",
                                           "1379-0.0",
                                           "1329-0.0",
                                           "1339-0.0",
                                           "30270-0.0",
                                           "1548-0.0"]
    @test size(continuous_phenotypes) == (10, 7)

    # 1408 is an ordinal field
    # Negative values are declared missing and other values forwarded
    @test 1408 ∈ UKBMain.ORDINAL_FIELDS
    expected_output = [missing, missing, missing, 3, 3, 1, 3, 2, 3, 1]
    for index in eachindex(expected_output)
        if expected_output[index] === missing
            @test continuous_phenotypes[index, "1408-0.0"] === expected_output[index]
        else
            @test continuous_phenotypes[index, "1408-0.0"] == expected_output[index]
        end
    end

    # 30270 is a continuous field
    # Values are forwarded
    expected_output = [79.5, 82.61, 81.0, 78.8, 83.16, 73.7, 81.72, 84.0, 75.34, missing]
    @test continuous_phenotypes[1:end-1, "30270-0.0"] == expected_output[1:end-1]
    @test continuous_phenotypes[end, "30270-0.0"] === expected_output[end]

    # Check confounders output
    confounders_outfile = string(parsed_args["out-prefix"], ".confounders.csv")
    confounders = CSV.read(confounders_outfile, DataFrame)
    # Check columns
    @test names(confounders) == ["21000_White",
                                 "21000_Mixed",
                                 "21000_Asian",
                                 "21000_Black",
                                 "21000_Chinese",
                                 "21000_Other"]
    @test size(confounders) == (10, 6)
    @test confounders[!, "21000_White"] == [1, 0, 0, 0, 1, 1, 1, 1, 1, 1]
    @test confounders[!, "21000_Mixed"] == [0, 1, 0, 0, 0, 0, 0, 0, 0, 0]
    @test confounders[!, "21000_Asian"] == [0, 0, 1, 0, 0, 0, 0, 0, 0, 0]
    @test confounders[!, "21000_Other"] == [0, 0, 0, 1, 0, 0, 0, 0, 0, 0]
    @test confounders[!, "21000_Chinese"] == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    @test confounders[!, "21000_Black"] == [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    rm(confounders_outfile)

    # Check covariates output
    covariates_outfile = string(parsed_args["out-prefix"], ".covariates.csv")
    covariates = CSV.read(covariates_outfile, DataFrame)

    @test names(covariates) == ["22001_Female", "21003-0.0"]
    @test size(covariates) == (10, 2)
    @test covariates[!, "22001_Female"] == [0, 1, 1, 1, 0, 0, 1,0, 0, 0]
    @test covariates[!, "21003-0.0"] == [64, 42,44, 46, 49, 57, 45, 57, 42, 61]
    rm(covariates_outfile)

    # Check sample_ids
    sample_ids_file = string(parsed_args["out-prefix"], ".sample_ids.txt")
    sample_ids = CSV.read(sample_ids_file, DataFrame, header=false)[!, 1]
    @test sample_ids == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    rm(sample_ids_file)
end

@testset "Test main with subset and no confounders" begin
    parsed_args = Dict(
        "dataset" => joinpath("data", "ukb_sample_traits.csv"),
        "out-prefix" => "processed",
        "conf" => joinpath("config", "config_with_subset_no_confounders.yaml"),
    )
    
    filter_and_extract(parsed_args)

    binary_phenotypes_outfile = string(parsed_args["out-prefix"], ".binary.phenotypes.csv")
    binary_phenotypes = CSV.read(binary_phenotypes_outfile, DataFrame)
    @test size(binary_phenotypes) == (2, 18)
    continuous_phenotypes_outfile = string(parsed_args["out-prefix"], ".continuous.phenotypes.csv")
    continuous_phenotypes = CSV.read(continuous_phenotypes_outfile, DataFrame)
    @test size(continuous_phenotypes) == (2, 7)
    rm(binary_phenotypes_outfile)
    rm(continuous_phenotypes_outfile)

    covariates_outfile = string(parsed_args["out-prefix"], ".covariates.csv")
    covariates = CSV.read(covariates_outfile, DataFrame)
    @test size(covariates) == (2, 1)
    rm(covariates_outfile)

    confounders_outfile = string(parsed_args["out-prefix"], ".confounders.csv")
    @test !isfile(confounders_outfile)

    sample_ids_file = string(parsed_args["out-prefix"], ".sample_ids.txt")
    sample_ids = CSV.read(sample_ids_file, DataFrame, header=false)[!, 1]
    @test sample_ids == [2, 7]
    rm(sample_ids_file)
    

end