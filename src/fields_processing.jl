function process_vt_22_c_6(dataset, field_metadata, coding, subfields)
    # for each individual we list all traits that were diagnosed
    # for at least one of the assessment visit 
    n = nrows(dataset)
    p = nrows(subfields)
    output = spzeros(Bool, n, p)

    field_id = field_metadata.field_id
    value_to_index = Dict(val => i for (i, val) in  enumerate(subfields))
    field_columns = filter(x -> startswith(x, string(field_id)), names(dataset))

    for colname in field_columns
        column = dataset[!, colname]
        for index in eachindex(column)
            value = getindex(column, index)
            if haskey(value_to_index, value)
                output[index, value_to_index[value]] = 1
            end
        end
    end

    return DataFrame(collect(output), string.(field_id, "-", subfields))

end