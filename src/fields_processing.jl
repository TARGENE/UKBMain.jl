
function check_categorical_entries(entry)
    @assert isa(entry, Dict) "Required `codings` key for entry: $(entry)"
    @assert haskey(entry, "codings") "Required `codings` key for entry: $(entry.field)"
end

function update_phenotypes_and_indices!(phenotypes::Vector, indices::Dict, ncols::Vector{Int64}, element) 
    push!(phenotypes, element)
    indices[element] = ncols[1]
    ncols[1] += 1
end

function update_phenotypes_and_indices!(phenotypes::Vector, indices::Dict, ncols::Vector{Int64}, element::Vector)
    for elem in element
        update_phenotypes_and_indices!(phenotypes, indices, ncols, elem)
    end
end

function update_phenotypes_and_indices!(phenotypes::Vector, indices::Dict, ncols::Vector{Int64}, element::Dict) 
    @assert(all(haskey(element, key) for key in ("any", "name")),
            "Codings with attributes are restricted to or statements having both `any` and `name` keys.")
    
    push!(phenotypes, element["name"])
    for val in element["any"]
        indices[val] = ncols[1]
    end
    ncols[1] += 1
end

function phenotypes_and_indices(codings::Vector)
    phenotypes = []
    indices = Dict()
    ncols = [1]
    for element in codings
        update_phenotypes_and_indices!(phenotypes, indices, ncols, element)
    end

    return phenotypes, indices
end

"""
`codings` is a single value
"""
function phenotypes_and_indices(codings)
    return [codings], Dict(codings => 1)
end


get_field_ids(entry::String) = parse.(Int, split(entry, " | "))
get_field_ids(field_id::Int) = [field_id]

fieldcolumns(dataset, field_id) = filter(x -> startswith(x, string(field_id)), names(dataset))

function process_categorical(dataset, entry)
    check_categorical_entries(entry)
    phenotypes, indices = phenotypes_and_indices(entry["codings"])

    output = spzeros(Bool, size(dataset, 1), size(phenotypes, 1))
    field_ids = get_field_ids(entry["field"])

    # This loop ensure that if the trait is declared for any of the
    # field in field_ids then it is accepted to be true
    for field_id in field_ids
        field_columns = fieldcolumns(dataset, field_id)
        # Looping over the columns of the field:
        # This means that a trait is declared present
        # if it is diagnosed at any of the assessment visits
        for colname in field_columns
            column = dataset[!, colname]
            for index in eachindex(column)
                value = getindex(column, index)
                if value !== missing && haskey(indices, value)
                    output[index, indices[value]] = true
                end
            end
        end
    end
    return DataFrame(collect(output), string.(entry["field"], "_", phenotypes))
end

"""
Processing of ordinal data, only the first instance is used.
"""
function process_ordinal(dataset, field_id)
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
function process_continuous(dataset, field_id)
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
function process_integer(dataset, field_id)
    colname = Symbol(field_id, "-0.0")
    return dataset[!, [colname]]
end