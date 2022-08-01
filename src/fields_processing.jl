function selectable_indices(potential_coding_indexes, encoding)
    coding_indexes = Int[]
    for index in potential_coding_indexes
        if encoding[index, :selectable] == "Y"
            push!(coding_indexes, index)
        end
    end
    return coding_indexes
end

function selectable_codings(coding, encoding)
    if occursin("-", string(coding))
        first, last = split(coding, "-")
        first_index = findfirst(x -> startswith(x.coding, first), eachrow(encoding))
        last_index = findlast(x -> startswith(x.coding, last), eachrow(encoding))
        coding_indexes = selectable_indices(first_index:last_index, encoding)
    else
        coding_index = findfirst(x -> x.coding == coding, eachrow(encoding))
        @assert coding_index !== nothing "Coding $coding does not exist"
        if "selectable" in names(encoding)
            if encoding[coding_index, :selectable] == "Y"
                coding_indexes = [coding_index]
            else
                potential_coding_indexes = findall(x -> startswith(x.coding, coding), eachrow(encoding))
                coding_indexes = selectable_indices(potential_coding_indexes, encoding)
            end
        else
            coding_indexes = [coding_index]
        end
    end
    return encoding[coding_indexes, :coding]
end

function check_categorical_entries(entry)
    @assert isa(entry, Dict) "Required `codings` key for entry: $(entry)"
    @assert haskey(entry, "codings") "Required `codings` key for entry: $(entry.field)"
end

function update_phenotypes_and_indices!(phenotypes::Vector, indices::Dict, encoding, coding) 
    push!(phenotypes, coding)
    index = size(phenotypes, 1)
    for scoding in selectable_codings(coding, encoding)
        if haskey(indices, scoding)
            push!(indices[scoding], index)
        else
            indices[scoding] = [index]
        end
    end
end

function update_phenotypes_and_indices!(phenotypes::Vector, indices::Dict, encoding, coding_list::Vector)
    for coding in coding_list
        update_phenotypes_and_indices!(phenotypes, indices, encoding, coding)
    end
end

function update_phenotypes_and_indices!(phenotypes::Vector, indices::Dict, encoding, coding_dict::Dict) 
    @assert(all(haskey(coding_dict, key) for key in ("any", "name")),
            "Codings with attributes are restricted to or statements having both `any` and `name` keys.")
    
    push!(phenotypes, coding_dict["name"])
    index = size(phenotypes, 1)
    for coding in coding_dict["any"]
        for scoding in selectable_codings(coding, encoding)
            if haskey(indices, scoding)
                push!(indices[scoding], index)
            else
                indices[scoding] = [index]
            end
        end
    end
end

function phenotypes_and_indices(codings::Vector, encoding)
    phenotypes = []
    indices = Dict()
    for coding in codings
        update_phenotypes_and_indices!(phenotypes, indices, encoding, coding)
    end

    return phenotypes, indices
end

"""
`codings` is a single value
"""
function phenotypes_and_indices(coding, encoding)
    indices = Dict()
    index = 1
    for scoding in selectable_codings(coding, encoding)
        if haskey(indices, scoding)
            push!(indices[scoding], index)
        else
            indices[scoding] = [index]
        end
    end
    return [coding], indices
end


get_field_ids(entry::String) = parse.(Int, split(entry, " | "))
get_field_ids(field_id::Int) = [field_id]

fieldcolumns(dataset, field_id) = filter(x -> startswith(x, string(field_id)), names(dataset))

function process_binary_arrayed(dataset, entry, encoding)
    check_categorical_entries(entry)
    phenotypes, indices = phenotypes_and_indices(entry["codings"], encoding)

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
                    output[index, indices[value]] .= true
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

negative_as_missing(value::Real) = value < 0 ? missing : value
negative_as_missing(value) = value
negative_as_missing(column::AbstractVector) = [negative_as_missing(v) for v in column]


function process_categorical(dataset, field_id)
    colname = Symbol(field_id, "-0.0")
    column = NamedTuple{(colname,)}([categorical(negative_as_missing(dataset[!, colname]))])
    mach = machine(OneHotEncoder(), column)
    fit!(mach, verbosity=0)
    Xt = MLJBase.transform(mach)
    Xt_bool = NamedTuple{keys(Xt)}([convert(Vector{Union{Bool, Missing}}, column) for column in Xt])
    return DataFrame(Xt_bool)
end