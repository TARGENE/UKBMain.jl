"""
    field_metadata(fields::DataFrame, field_id::Int)

Retrieves the row corresponding to `field_id` from the metadata Dataframe `fields`.
"""
function fieldmetadata(fields::DataFrame, field_id::Int)
    row_id = findfirst(x -> x.field_id == field_id, eachrow(fields))
    return fields[row_id, :]
end


function read_dataset(dataset_file::String, subset_file::Nothing)
    return CSV.read(dataset_file, DataFrame)
end

function read_dataset(dataset_file::String, subset_file::String)
    dataset = CSV.read(parsed_args["dataset"], DataFrame)
    subset = JSON.parse(parsed_args["subset"];)
    return dataset
end

function build_from_yaml_entry(entry::Vector, dataset, fields_metadata, codings)
    output = DataFrame()
    for field_id in entry
        field_output =  build_from_yaml_entry(field_id, dataset, fields_metadata, codings)
        output = hcat(output, field_output)
    end
    return output
end

get_field_id(entry::Int) = entry 
get_field_id(entry::Dict) = entry["field"]

function build_from_yaml_entry(entry, dataset, fields_metadata, codings)
    field_id = get_field_id(entry)
    println(field_id)
    field_metadata = fieldmetadata(fields_metadata, field_id)
    # coding = codings[field_metadata.encoding_id]
    if field_metadata.value_type == 22
        return process_22(dataset, entry)
    # Those seem to be ordinal values with negative values corresponding to missing data
    elseif field_metadata.value_type == 21
        return process_21(dataset, field_id)
    # Those seem to be continuous data
    elseif field_metadata.value_type == 31
        return process_31(dataset, field_id)
    # Integer data
    elseif field_metadata.value_type == 11
        return process_11(dataset, field_id)
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
        field_yaml_entries = conf[role]
        output = DataFrame()
        for entry in field_yaml_entries
            # The entry could be any of: Vector | Integer | Dict
            entry_output = build_from_yaml_entry(entry, dataset, fields_metadata, codings)
            output = hcat(output, entry_output)
        end
        outfile = string(parsed_args["out-prefix"], ".", role, ".csv")
        CSV.write(outfile, output)
    end
end