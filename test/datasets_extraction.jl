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
    outfile = string(parsed_args["out-prefix"], ".phenotypes.csv")
    # Temp utils
    # data = UKBMain.read_dataset(parsed_args["dataset"], parsed_args["subset"])
    # CSV.write(parsed_args["dataset"], data)
    # cols = UKBMain.fieldcolumns(data, 40006)
    # fields_metadata = UKBMain.read_fields_metadata()
    # UKBMain.fieldmetadata(fields_metadata, 1707)
    
    UKBMain.main(parsed_args)

    phenotypes = CSV.read(outfile, DataFrame)
    # Check columns
    @test names(phenotypes) == ["1408-0.0",
                                "1727-0.0",
                                "1379-0.0",
                                "1329-0.0",
                                "1339-0.0",
                                "30270-0.0",
                                "1548-0.0",
                                "1707_1",
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
    @test phenotypes[!, "1707_1"] == [1, 0, 1, 1, 0, 1, 0, 1, 0, 0]
    @test phenotypes[!, "1707_2"] == [0, 0, 0, 0, 1, 0, 1, 0, 0, 0]
    
    # 40006 is a categorical trait
    # In theory all columns will contain at least one non-missing value
    # In this example, only the 3 first columns contain non-missing values
    @test phenotypes[:, "40006_Block D37-D48"] == [true, false, false, true, false, true, false, false, false, false]
    @test phenotypes[:, "40006_C43"] == [true, false, false, false, false, false, true, false, false, false]
    @test phenotypes[:, "40006_D41"] == [false, false, false, false, false, false, true, false, false, false]
    @test phenotypes[:, "40006_C44"] == [true, false, false, true, false, false, false, false, false, false]

    # 20002 is a categorical trait 
    # with multiple instances that correspond to the assessment visit
    # Reporting the disease at any of those visits results as the 
    # disease considered declared
    @test phenotypes[:, "20002_1674"] == [false, false, false, false, false, false, false, false, false, false]
    @test phenotypes[:, "20002_1065"] == [false, false, false, true, false, false, true, false, false, true]
    @test phenotypes[:, "20002_1066"] == [true, false, true, false, true, false, false, false, false, false]
    @test phenotypes[:, "20002_1067"] == [true, false, false, false, true, false, false, false, false, false]
    @test phenotypes[:, "20002_1762"] == [false, false, false, false, false, false, true, false, true, false]

    # 41202 | 41204 both are categorical
    # The presence of a disease in any of those fields results as the
    # disease considered declared
    @test phenotypes[:, "41202 | 41204_Block J40-J47"] == [false, false, false, false, false, false, false, false, false, false]
    @test phenotypes[:, "41202 | 41204_O26"] == [true, false, false, false, false, false, false, false, false, false]
    @test phenotypes[:, "41202 | 41204_O20"] == [false, false, false, false, false, false, false, false, false, false]
    @test phenotypes[:, "41202 | 41204_Block A30-A49"] == [false, false, false, false, false, false, false, false, false, false]
    @test phenotypes[:, "41202 | 41204_K44"] == [true, false, true, false, false, false, false, false, false, false]
    @test phenotypes[:, "41202 | 41204_G20"] == [false, false, false, false, false, false, false, false, false, true]
    
    rm(outfile)
end