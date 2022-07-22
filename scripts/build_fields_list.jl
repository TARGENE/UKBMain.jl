using ArgParse
using UKBMain

function parse_commandline()
    s = ArgParseSettings(description="Build a fields list from .yaml file")

    @add_arg_table s begin
        "--conf"
            help = "The YAML configuration file"
            default = joinpath("config", "config.yaml")
            arg_type = String
        "--output"
            help = "output file"
            default = "fields_list.txt"
            arg_type = String
    end

    return parse_args(s)
end

parsed_args = parse_commandline()

build_fields_list(parsed_args)
