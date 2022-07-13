using ArgParse
using UKBMain

function parse_commandline()
    s = ArgParseSettings(description="Merges 2 .csv file by SAMPLE_ID")

    @add_arg_table s begin
        "csv1"
            help = "First .csv file"
            arg_type = String
        "csv2"
            help = "Second .csv file"
            arg_type = String
        "out"
            help = "Output file path"
            arg_type = String
    end

    return parse_args(s)
end

parsed_args = parse_commandline()

csvmerge(parsed_args)