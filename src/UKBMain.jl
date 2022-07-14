module UKBMain
using CSV
using DataFrames
using CategoricalArrays
using MLJModels
using MLJModelInterface
using MLJBase
using HTTP
using Downloads
using DelimitedFiles
using SparseArrays

"""
    field_metadata(fields::DataFrame, field_id::Int)

Retrieves the row corresponding to `field_id` from the metadata Dataframe `fields`.
"""
function fieldmetadata(fields::DataFrame, field_id::Int)
    row_id = findfirst(x -> x.field_id == field_id, eachrow(fields))
    return fields[row_id, :]
end

function csvmerge(parsed_args)
    csv₁ = CSV.read(parsed_args["csv1"], DataFrame)
    csv₂ = CSV.read(parsed_args["csv2"], DataFrame)
    CSV.write(parsed_args["out"], innerjoin(csv₁, csv₂, on=:SAMPLE_ID))
end

function read_dataset(dataset_file::String, subset_file::Nothing)
    return CSV.read(dataset_file, DataFrame)
end

function read_dataset(dataset_file::String, subset_file::String)
    dataset = CSV.read(parsed_args["dataset"], DataFrame)
    subset = JSON.parse(parsed_args["subset"];)
    return dataset
end

function build_from_yaml_entry(entry::Vector, subfields, dataset, fields_metadata, codings)
    output = DataFrame()
    for field in entry
        field_output =  build_from_yaml_entry(field, subfields, dataset, fields_metadata, codings)
        output = hcat(output, field_output)
    end
    return output
end

function build_from_yaml_entry(entry, subfields, dataset, fields_metadata, codings)
    field_metadata = fieldmetadata(fields_metadata, entry)
    coding = codings[field_metadata.encoding_id]
    if field_metadata.value_type == 22
        return process_vt_22_c_6(dataset, field_metadata, coding, subfields)
    else
        throw(ArgumentError(string("Sorry I currently don't know how to process field: ", entry)))
    end
end

function main(parsed_args)
    # Read configuration
    conf = YAML.load_file(parsed_args["conf"])

    # Download and read fields metadata
    download_fields_metadata()
    fields_metadata = read_fields_metadata()

    # Download and read data codings
    codings = download_and_read_codings()

    # Read dataset
    dataset = read_dataset(parsed_args["dataset"], parsed_args["subset"])
    
    for role in ("phenotypes", )
        fields_dicts = conf[role]
        output = DataFrame()
        for fields_dict in fields_dicts
            subfields = haskey(fields_dict, "subfields") ? 
                unique(Iterators.flatten(fields_dict["subfields"])) : nothing
            entry = fields_dict["id"]
            # The entry could be any of: Vector | Integer | String
            entry_output = build_from_yaml_entry(entry, subfields, dataset, fields_metadata, codings)
            output = hcat(output, entry_output)
        end
        outfile = string(parsed_args["out-prefix"], ".", role, ".csv")
        CSV.write(outfile, output)
    end
end

export decode, csvmerge, main

end
