using UKBMain
using Test
using CSV
using DataFrames

const DATASETFILE = joinpath("data", "data.csv")
const FIELDSFILE = joinpath("data", "field.txt")

@testset "Test first_instance_fields" begin
    columns = UKBMain.first_instance_fields(DATASETFILE)
    @test columns == ["eid", "21003-0.0", "22001-0.0"]
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
        "22001-2.0" => [1, 0, 1, 1.]
        ))

    age_meta = UKBMain.field_metadata(fields_meta, 21003)
    sex_meta = UKBMain.field_metadata(fields_meta, 22001)
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

end

@testset "Test decode" begin
    parsed_args = Dict(
        "dataset" => DATASETFILE,
        "fields" => FIELDSFILE,
        "out" => "processed_output.csv"
    )
    decode(parsed_args)
    output = CSV.read(parsed_args["out"], DataFrame)
    @test names(output) == ["SAMPLE_ID", "21003-0.0", "22001-0.0"]
    @test output[:, "SAMPLE_ID"] isa Vector{Int}
    @test output[:, "21003-0.0"] isa Vector{Int}
    @test output[:, "22001-0.0"] isa Vector{Union{Bool, Missing}}

    rm(parsed_args["out"])
end
