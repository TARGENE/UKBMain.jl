using ArgParse
using UKBMain

function parse_commandline()
    s = ArgParseSettings(description="Extracts and process traits from main dataset.")

    @add_arg_table s begin
        "dataset"
            help = "The main dataset to read from"
            arg_type = String
        "--out-prefix"
            help = "output prefix"
            default = "processed"
            arg_type = String
        "--covariates"
            help = "File containing covariates fields (one per row, no header)"
            arg_type = String
        "--confounders"
            help = "File containing confounders fields (one per row, no header)"
            arg_type = String
        "--phenotypes"
            help = "File containing phenotypes fields (one per row, no header)"
            arg_type = String
        "--treatments"
            help = "File containing treatments fields (one per row, no header)"
            arg_type = String
        "--subset"
            help = "JSON file: {field_1: [values], field_2: [values]}. The filter clause "* 
                   "will be on all fields containing any of the values in each list"
            arg_type = String
    end

    return parse_args(s)
end

parsed_args = parse_commandline()

println(parsed_args)

#main(parsed_args)