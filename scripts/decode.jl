using ArgParse
using UKBMain

function parse_commandline()
    s = ArgParseSettings(description="Decodes a dataset output by ukbconv to scientific format.")

    @add_arg_table s begin
        "dataset"
            help = "Output of a ukbconv run"
            arg_type = String
        "fields"
            help = "Fields metadata file downloaded from https://biobank.ndph.ox.ac.uk/ukb/schema.cgi?id=1"
            arg_type = String
        "out"
            help = "Output file path"
            arg_type = String
    end

    return parse_args(s)
end

parsed_args = parse_commandline()

decode(parsed_args)