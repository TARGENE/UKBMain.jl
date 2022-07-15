using Test
using UKBMain
using DelimitedFiles

@testset "Test " begin
    parsed_args = Dict(
        "conf" => joinpath("config", "config.yaml"),
        "output" => "fields_output.txt"
    )
    build_fields_list(parsed_args)

    fields_list = readdlm(parsed_args["output"], Int)
    @test fields_list[:, 1] ==
    [1408, 1777, 1727, 1548, 924, 
     1379, 1329, 1339,
     30270,
     40006,
     20002,
     41202, 41204]

     rm(parsed_args["output"])
end