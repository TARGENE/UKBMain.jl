using UKBMain
using Test
using CSV
using DataFrames

fields_metadata_file = "fields_metadata.txt"
download_fields_metadata(output=fields_metadata_file)
fields_metadata = CSV.read(fields_metadata_file, DataFrame)

coding_6_file = "ukb_datacoding_6.tsv"
download_datacoding_6(output=coding_6_file)
coding_6 = CSV.read(coding_6_file, DataFrame)

const DATASETFILE = joinpath("data", "data.csv")
const FIELDSFILE = joinpath("data", "field.txt")

@testset "Test first_instance_fields" begin
    columns = UKBMain.first_instance_fields(DATASETFILE)
    @test columns == ["eid", "21000-0.0", "21003-0.0", "22001-0.0"]
end

@testset "Test field_metadata" begin
    fields_meta = CSV.read(FIELDSFILE, DataFrame)

    age_meta = UKBMain.field_metadata(fields_meta, 21003)
    @test age_meta.field_id == 21003
    @test age_meta.value_type == 11
    sex_meta = UKBMain.field_metadata(fields_meta, 22001)
    @test sex_meta.field_id == 22001
    @test sex_meta.value_type == 21 
end

@testset "Test process!" begin
    fields_meta = CSV.read(FIELDSFILE, DataFrame)
    dataset = DataFrame(Dict(
        "21003-0.0" => [64., 32., 23, 11],
        "21003-1.0" => [64, 32, 23, 11],
        "21003-2.0" => [64., 32, missing, 11],
        "22001-0.0" => [1, 0, 1, missing],
        "22001-1.0" => [1, 0, 1, 0],
        "22001-2.0" => [1, 0, 1, 1.],
        "21000-0.0" => [1001, -2, missing, 2]
        ))

    age_meta = UKBMain.field_metadata(fields_meta, 21003)
    sex_meta = UKBMain.field_metadata(fields_meta, 22001)
    ethnicity_meta = UKBMain.field_metadata(fields_meta, 21000)
    # First column
    @test eltype(dataset[!, "21003-0.0"]) === Float64
    UKBMain.process!(dataset, "21003-0.0", age_meta)
    @test eltype(dataset[!, "21003-0.0"]) === Int64

    # Second column
    @test eltype(dataset[!, "21003-1.0"]) === Int
    UKBMain.process!(dataset, "21003-1.0", age_meta)
    @test eltype(dataset[!, "21003-1.0"]) === Int64

    # Third column
    @test eltype(dataset[!, "21003-2.0"]) === Union{Float64, Missing}
    UKBMain.process!(dataset, "21003-2.0", age_meta)
    @test eltype(dataset[!, "21003-2.0"]) === Union{Int64, Missing}

    # Fourth column
    @test eltype(dataset[!, "22001-0.0"]) === Union{Int, Missing}
    UKBMain.process!(dataset, "22001-0.0", sex_meta)
    @test eltype(dataset[!, "22001-0.0"]) === Union{Bool, Missing}

    # Fifth column
    @test eltype(dataset[!, "22001-1.0"]) === Int
    UKBMain.process!(dataset, "22001-1.0", sex_meta)
    @test eltype(dataset[!, "22001-1.0"]) === Bool

    # Sixth column
    @test eltype(dataset[!, "22001-2.0"]) === Float64
    UKBMain.process!(dataset, "22001-2.0", sex_meta)
    @test eltype(dataset[!, "22001-2.0"]) === Bool

    # Seventh column
    @test eltype(dataset[!, "21000-0.0"]) === Union{Missing, Int64}
    UKBMain.process!(dataset, "21000-0.0", ethnicity_meta)
    @test isequal(dataset[!, "21000-0.0__-2"], [0., 1., missing, 0.])
    @test isequal(dataset[!, "21000-0.0__2"], [0., 0., missing, 1.])
    @test isequal(dataset[!, "21000-0.0__1001"], [1., 0., missing, 0.])
    @test "21000-0.0" ∉ names(dataset)
end

@testset "Test decode" begin
    parsed_args = Dict(
        "dataset" => DATASETFILE,
        "fields" => FIELDSFILE,
        "out" => "processed_output.csv"
    )
    decode(parsed_args)
    output = CSV.read(parsed_args["out"], DataFrame)
    @test names(output) == ["SAMPLE_ID"
                            "21003-0.0"
                            "22001-0.0"
                            "21000-0.0__-3"
                            "21000-0.0__-1"
                            "21000-0.0__1"
                            "21000-0.0__2"
                            "21000-0.0__6"
                            "21000-0.0__1001"
                            "21000-0.0__1003"
                            "21000-0.0__2002"
                            "21000-0.0__4002"]
    @test output[:, "SAMPLE_ID"] isa Vector{Int}
    @test output[:, "21003-0.0"] isa Vector{Int}
    @test output[:, "22001-0.0"] isa Vector{Union{Bool, Missing}}

    rm(parsed_args["out"])
end

@testset "Test csvmerge" begin
    CSV. write("test_csv1.csv",
        DataFrame(SAMPLE_ID=[1,2,3], COL1=[1., 2., 3.])
    )
    CSV. write("test_csv2.csv",
        DataFrame(SAMPLE_ID=[4,3,2], COL2=[1., 2., 3.])
    )

    parsed_args = Dict(
        "csv1" => "test_csv1.csv",
        "csv2" => "test_csv2.csv",
        "out" => "test_out.csv"
    )
    csvmerge(parsed_args)

    out = CSV.read(parsed_args["out"], DataFrame)

    @test out == DataFrame(
        SAMPLE_ID = [3, 2],
        COL1      = [3., 2.],
        COL2      = [2., 3.]
    )
    
    for file in values(parsed_args)
        rm(file)
    end
end

@testset "Test main" begin
    parsed_args = Dict(
        "dataset" => DATASETFILE,
        "out-prefix" => "processed",
        "confounders" => joinpath("config", "confounders.txt"),
        "covariates" => joinpath("config", "covariates.txt"),
        "phenotypes" => joinpath("config", "phenotypes.txt"),
        "treatments" => joinpath("config", "treatments.txt"),
    )

end