using Test
using UKBMain
using DelimitedFiles

@testset "Test build_fields_list" begin
    parsed_args = Dict(
        "conf" => joinpath("config", "config.yaml"),
        "output" => "fields_output.txt"
    )
    build_fields_list(parsed_args)
    fields_list = readdlm(parsed_args["output"], Int)
    @test fields_list[:, 1] == [21000,
                                1408, 1727,
                                1379, 1329, 1339,
                                30270,
                                1548,
                                1707,
                                1777,
                                40006,
                                20002,
                                41202, 41204,
                                22001,
                                21003]
     rm(parsed_args["output"])

     parsed_args = Dict(
        "conf" => joinpath("config", "config_with_subset_no_confounders.yaml"),
        "output" => "fields_output.txt"
    )
    build_fields_list(parsed_args)
    fields_list = readdlm(parsed_args["output"], Int)
    @test fields_list[:, 1] == [21000,
                                22001,
                                1408,
                                1727,
                                1379,
                                1329,
                                1339,
                                30270,
                                1548,
                                1707,
                                1777,
                                40006,
                                20002,
                                41202,
                                41204,
                                21003]
     rm(parsed_args["output"])
end