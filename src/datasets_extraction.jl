const ORDINAL_FIELDS = Set([
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


build_from_yaml_entry(entry::Int, dataset, fields_metadata, role) = 
    _build_from_yaml_entry(entry, dataset, fields_metadata, role)

function build_from_yaml_entry(entry::Vector, dataset, fields_metadata, role)
    output = DataFrame()
    for field_id in entry
        field_output = _build_from_yaml_entry(field_id, dataset, fields_metadata, role)
        output = hcat(output, field_output)
    end
    return output
end

function build_from_yaml_entry(entry::Dict, dataset, fields_metadata, role)
    if ! haskey(entry, "codings")
        return build_from_yaml_entry(entry["field"], dataset, fields_metadata, role)
    else
        return _build_from_yaml_entry(entry, dataset, fields_metadata, role)
    end
end

get_field_id(entry) = entry 
get_field_id(entry::Dict) = entry["field"]

function _build_from_yaml_entry(entry, dataset, fields_metadata, role)
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
    elseif field_metadata.field_id ∈ ORDINAL_FIELDS
        return process_ordinal(dataset, entry)
    # Categorical data that is arrayed even if not 
    # described as such by the field_metadata
    elseif field_metadata.field_id ∈ (40006, 20002, 41202, 41204)
        encoding = download_and_read_datacoding(field_metadata.encoding_id)
        return process_binary_arrayed(dataset, entry, encoding)
    # Other categorical data: only the first column is used
    elseif field_metadata.value_type ∈ (21, 22)
        # Extra treatment variables are not one hot encoded
        if role == "treatments"
            return process_categorical_treatment(dataset, entry)
        else
            # if codings are specified, we fallback to binary processing
            if entry isa Dict && haskey(entry, "codings")
                encoding = download_and_read_datacoding(field_metadata.encoding_id)
                return process_binary_arrayed(dataset, entry, encoding)
            # Otherwise, values are one hot encoded
            else
                return process_categorical(dataset, entry)
            end
        end
    else
        throw(ArgumentError(string("Sorry I currently don't know how to process entry: ", entry)))
    end
end

function read_dataset(parsed_args, conf, fields_metadata)
    dataset = CSV.read(parsed_args["dataset"], DataFrame)
    if haskey(conf, "subset")
        @info "Subsetting dataset."
        field_yaml_entries = conf["subset"]
        filter_columns = UKBMain.role_dataframe(field_yaml_entries, dataset, fields_metadata,  "subset")
        select!(filter_columns, Not(:SAMPLE_ID))
        dataset = hcat(dataset, filter_columns)
        dataset = subset(dataset, (Symbol(name) => x -> x .=== true for name in names(filter_columns))...)
    end
    if parsed_args["withdrawal-list"] !== nothing
        @info "Removing individuals from withdrawal-list"
        withdrawal_list = Set(CSV.read(parsed_args["withdrawal-list"], DataFrame; header=false)[!, 1])
        dataset = subset(dataset, :eid => ByRow(x -> !(x ∈ withdrawal_list)))
    end
    return dataset
end

function role_dataframe(field_yaml_entries, dataset, fields_metadata, role)
    output = DataFrame(SAMPLE_ID=dataset[:, :eid])
    for entry in field_yaml_entries
        # The entry could be any of: Vector | Integer | Dict
        entry_output = build_from_yaml_entry(entry, dataset, fields_metadata, role)
        output = hcat(output, entry_output)
    end
    return output
end

isbinary(::Type{Union{Missing, Bool}}) = true
isbinary(::Type{Bool}) = true
isbinary(val) = false

function filter_and_extract(parsed_args)
    # Read configuration
    conf = YAML.load_file(parsed_args["conf"])

    # Download and read fields metadata
    download_fields_metadata()
    fields_metadata = read_fields_metadata()

    # Read dataset
    dataset = read_dataset(parsed_args, conf, fields_metadata)
    
    # Generate various output files
    for role in ("phenotypes", "covariates", "confounders", "treatments")
        if haskey(conf, role)
            @info string("Generating processed file for: ", role, ".")
            field_yaml_entries = conf[role]
            output = role_dataframe(field_yaml_entries, dataset, fields_metadata, role)
            if role == "phenotypes"
                binary_cols = [colname for colname in names(output) if isbinary(eltype(output[!, colname]))]
                continuous_cols = [colname for colname in names(output) if !(colname ∈ binary_cols)]
                CSV.write(string(parsed_args["out-prefix"], ".binary.", role, ".csv"), output[!, vcat("SAMPLE_ID", binary_cols)])
                CSV.write(string(parsed_args["out-prefix"], ".continuous.", role, ".csv"), output[!, continuous_cols])
            else
                CSV.write(string(parsed_args["out-prefix"], ".", role, ".csv"), output)
            end
        end
    end

    # Write sample ids
    CSV.write(string(parsed_args["out-prefix"], ".sample_ids.txt"), dataset[!,[:eid]]; header=false)
end


