const ORDINAL_FIELDS = Set([
    1408, 1727, 1548, 728, 1717, 1389, 1478, 1518,
    1558, 1349, 1359, 1369, 1379, 1329, 1339, 1239, 1687, 1697,
    1319, 1498
]) 

function get_fields_metadata(fields_metadata::DataFrame, field_id)
    row_id = findfirst(x -> x.field_id == field_id, eachrow(fields_metadata))
    f_meta = fields_metadata[row_id, :]
    return field_id, f_meta.value_type, f_meta.encoding_id
end

"""
    get_fields_metadata(fields_metadata::DataFrame, field_ids::AbstractVector)

If multiple fields are provided, they should share the same encoding and value_type.
The field_id returned by this function is used as a canonical field_id for 
all field_ids in the list.
"""
function get_fields_metadata(fields_metadata::DataFrame, field_ids::AbstractVector)
    value_types = []
    encoding_ids = []
    for f_id in field_ids 
        _, value_type, encoding_id = get_fields_metadata(fields_metadata, f_id)
        push!(value_types, value_type)
        push!(encoding_ids, encoding_id)
    end
    @assert all(==(value_types[1]), value_types)
    @assert all(==(encoding_ids[1]), encoding_ids)
    
    return first(field_ids), first(value_types), first(encoding_ids)
end

function build_from_fields_entry(fields_entry, dataset, fields_metadata)
    field_ids = fields_entry["fields"]
    field_id, value_type, encoding_id = UKBMain.get_fields_metadata(fields_metadata, field_ids)
    # Ordinal data
    if field_id ∈ ORDINAL_FIELDS
        return process_ordinal(dataset, fields_entry)
    # Categorical data that is arrayed even if not 
    # described as such by the field_metadata
    elseif field_id ∈ (40006, 20002, 41202, 41204)
        return process_binary_arrayed(dataset, fields_entry)
    # Continuous data
    elseif value_type == 31
        return process_continuous(dataset, fields_entry)
    # Integer data
    elseif value_type == 11
        return process_integer(dataset, fields_entry)
    # Other categorical data: only the first column is used
    elseif value_type ∈ (21, 22)
        return process_categorical(dataset, fields_entry)
    else
        throw(ArgumentError(string("Sorry I currently don't know how to process entry: ", fields_entry)))
    end
end


subset_dataset(dataset, subset_args::Nothing, fields_metadata;verbosity=1) = dataset

function subset_dataset(dataset, subset_args, fields_metadata;verbosity=1)
    verbosity > 0 && @info "Subsetting dataset."
    filter_columns = UKBMain.extract(dataset, subset_args, fields_metadata; verbosity=verbosity)
    select!(filter_columns, Not(:SAMPLE_ID))
    dataset = hcat(dataset, filter_columns)
    dataset = subset(dataset, (Symbol(name) => x -> x .=== true for name in names(filter_columns))...)
end

withdraw_individuals(dataset, withdrawal_list::Nothing;verbosity=1) = dataset

function withdraw_individuals(dataset, withdrawal_list;verbosity=1)
    verbosity > 0 && @info "Removing individuals from withdrawal-list"
    withdrawal_list = Set(CSV.read(withdrawal_list, DataFrame; header=false)[!, 1])
    return subset(dataset, :eid => ByRow(x -> !(x ∈ withdrawal_list)))
end

function extract(dataset, field_entries, fields_metadata;verbosity=1)
    output = DataFrame(SAMPLE_ID=dataset[:, :eid])
    for fields_entry in field_entries
        verbosity > 0 && @info "Processing fields_entry: $(fields_entry["fields"])"
        field_output = build_from_fields_entry(fields_entry, dataset, fields_metadata)
        output = hcat(output, field_output)
    end
    return output
end

isbinary(::Type{Union{Missing, Bool}}) = true
isbinary(::Type{Bool}) = true
isbinary(val) = false

function filter_and_extract(parsed_args)
    v = parsed_args["verbosity"]
    # Read configuration
    conf = YAML.load_file(parsed_args["conf"])

    # Download and read fields metadata
    fields_metadata = UKBMain.download_and_read_fields_metadata()

    # Read dataset
    dataset = CSV.read(parsed_args["dataset"], DataFrame)
    subset_args = haskey(conf, "subset") ? conf["subset"] : nothing
    dataset = UKBMain.subset_dataset(dataset, subset_args, fields_metadata; verbosity=v)
    dataset = UKBMain.withdraw_individuals(dataset, parsed_args["withdrawal-list"]; verbosity=v)
    
    # Generate output
    output = extract(dataset, conf["traits"], fields_metadata; verbosity=v)
    CSV.write(parsed_args["out"], output)
end


