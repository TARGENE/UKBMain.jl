using ArgParse
using UKBMain

function parse_commandline()
    s = ArgParseSettings(description="Extracts and process traits from main dataset.")

    @add_arg_table s begin
        "dataset"
            help = "The main dataset to read from"
            arg_type = String
        "--conf"
            help = "The YAML configuration file"
            default = joinpath("config", "config.yaml")
            arg_type = String
        "--out"
            help = "output path"
            default = "processed"
            arg_type = String
        "--withdrawal-list"
            help = "Path to UKB withdrawal list"
            arg_type = String
        "--verbosity"
            help = "Path to UKB withdrawal list"
            arg_type = Int
            default = 1
    end

    return parse_args(s)
end

parsed_args = parse_commandline()

filter_and_extract(parsed_args)