global ORDINAL_FIELDS = Set([
    1408, 1727, 1548, 728, 1717, 1389, 1478, 1518,
    1558, 1349, 1359, 1369, 1379, 1329, 1339, 1239, 1687, 1697,
    1319, 1498
]) 

"""
    field_metadata(fields::DataFrame, field_id::Int)

Retrieves the row corresponding to `field_id` from the metadata Dataframe `fields`.
"""
function fieldmetadata(fields::DataFrame, field_id::Int)
    row_id = findfirst(x -> x.field_id == field_id, eachrow(fields))
    return fields[row_id, :]
end

function fieldmetadata(fields::DataFrame, entry::String)
    field_ids = parse.(Int, split(entry, " | "))
    field_metadata = fieldmetadata(fields, field_ids[1])

    for f_id in field_ids
        f_meta = fieldmetadata(fields, f_id)
        @assert f_meta.value_type == field_metadata.value_type
        @assert f_meta.encoding_id == field_metadata.encoding_id
    end
    
    return field_metadata
end


function read_dataset(dataset_file::String, subset_file::Nothing)
    return CSV.read(dataset_file, DataFrame)
end

function read_dataset(dataset_file::String, subset_file::String)
    dataset = CSV.read(parsed_args["dataset"], DataFrame)
    subset = JSON.parse(parsed_args["subset"];)
    return dataset
end

build_from_yaml_entry(entry::Int, dataset, fields_metadata) = 
    _build_from_yaml_entry(entry, dataset, fields_metadata)

function build_from_yaml_entry(entry::Vector, dataset, fields_metadata)
    output = DataFrame()
    for field_id in entry
        field_output = _build_from_yaml_entry(field_id, dataset, fields_metadata)
        output = hcat(output, field_output)
    end
    return output
end

function build_from_yaml_entry(entry::Dict, dataset, fields_metadata)
    if ! haskey(entry, "codings")
        return build_from_yaml_entry(entry["field"], dataset, fields_metadata)
    else
        return _build_from_yaml_entry(entry, dataset, fields_metadata)
    end
end

get_field_id(entry) = entry 
get_field_id(entry::Dict) = entry["field"]

function main(parsed_args)
    # Read configuration
    conf = YAML.load_file(parsed_args["conf"])

    # Download and read fields metadata
    download_fields_metadata()
    fields_metadata = read_fields_metadata()

    # Read dataset
    dataset = read_dataset(parsed_args["dataset"], parsed_args["subset"])
    
    for role in ("phenotypes", "covariates", "confounders", "treatments")
        if haskey(conf, role)
            field_yaml_entries = conf[role]
            output = DataFrame()
            for entry in field_yaml_entries
                # The entry could be any of: Vector | Integer | Dict
                entry_output = build_from_yaml_entry(entry, dataset, fields_metadata)
                output = hcat(output, entry_output)
            end
            outfile = string(parsed_args["out-prefix"], ".", role, ".csv")
            CSV.write(outfile, output)
        end
    end
end

function _build_from_yaml_entry(entry, dataset, fields_metadata)
    field_id = get_field_id(entry)
    @info string("Processing field: ", field_id)
    field_metadata = fieldmetadata(fields_metadata, field_id)
    # Continuous data
    if field_metadata.value_type == 31
        return process_continuous(dataset, entry)
    # Integer data
    elseif field_metadata.value_type == 11
        return process_integer(dataset, entry)
    # Categorical data but considered ordinal
    elseif field_id ∈ ORDINAL_FIELDS
        return process_ordinal(dataset, entry)
    # Categorical data: all processed in the same way
    elseif field_metadata.value_type ∈ (22, 21)
        return process_categorical(dataset, entry)
    else
        throw(ArgumentError(string("Sorry I currently don't know how to process field: ", entry)))
    end
end
