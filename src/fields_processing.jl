function process_22(dataset, entry)
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

"""
Processing of ordinal data, only the first instance is used.
"""
function process_21(dataset, field_id)
    colname = Symbol(field_id, "-0.0")
    column = dataset[!, colname]
    output = Vector{Union{Int, Missing}}(undef, size(column, 1))
    for index in eachindex(column)
        val = column[index] 
        if val !== missing && val >= 0
            output[index] = val
        end
    end
    return DataFrame(NamedTuple{(colname,)}([output]))
end

"""
Processing of continuous data, only the first instance is used.
"""
function process_31(dataset, field_id)
    colname = Symbol(field_id, "-0.0")
    column = dataset[!, colname]
    output = Vector{Union{Float64, Missing}}(undef, size(column, 1))
    for index in eachindex(column)
        val = column[index] 
        if val !== missing
            output[index] = val
        end
    end
    return DataFrame(NamedTuple{(colname,)}([output]))
end

"""
Processing of integer data, only the first instance is used.
"""
function process_11(dataset, field_id)
    colname = Symbol(field_id, "-0.0")
    return dataset[!, [colname]]
end