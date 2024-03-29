negative_as_missing(value::Real) = value < 0 ? missing : value
negative_as_missing(value) = value
negative_as_missing(column::AbstractVector) = [negative_as_missing(v) for v in column]

only_one_field(field) = field
function only_one_field(fields::AbstractVector)
    @assert length(fields) == 1 "Error when processing: $fields, only one field is supported in this setting."
    return first(fields)
end

asvector(x) = [x]
asvector(x::AbstractVector) = x
asvector(x::AbstractVector{<:AbstractVector}) = vcat(x...)

fieldcolumns(dataset, field_id) = filter(x -> startswith(x, string(field_id)), names(dataset))

function update_with_coding!(output, coding, index, coding_to_column_indices)
    coding = string(coding)
    if haskey(coding_to_column_indices, coding)
        output[index, coding_to_column_indices[coding]] .= true
    end
end

update_with_coding!(output, coding::Missing, index, coding_to_column_indices) = nothing

maybe_convert_to_int(v, ::Type{<:AbstractFloat}) =
    convert(Vector{Int}, v) 

maybe_convert_to_int(v, ::Type{<:Union{Missing, AbstractFloat}}) =
    convert(Vector{Union{Missing, Int}}, v) 

maybe_convert_to_int(v, ::Any) = v

maybe_convert_to_int(v) = maybe_convert_to_int(v, eltype(v))

"""
    process_binary_arrayed(dataset, fields_entry)
"""
function process_binary_arrayed(dataset, fields_entry)
    # Retrieve phenotype names and mapping between codings and the
    # phenotypes they map to
    phenotypes = Vector{Any}(undef, size(fields_entry["phenotypes"], 1))
    coding_to_column_indices = Dict{String, Vector{Int}}()
    for index in eachindex(fields_entry["phenotypes"])
        phenotype_entry = fields_entry["phenotypes"][index]
        phenotypes[index] = phenotype_entry["name"]
        for coding in asvector(phenotype_entry["codings"])
            coding = string(coding)
            if haskey(coding_to_column_indices, coding)
                push!(coding_to_column_indices[coding], index)
            else
                coding_to_column_indices[coding] = [index]
            end
        end
    end

    # Output as a sparse matrix, most people are assumed to have no condition
    output = zeros(Bool, size(dataset, 1), size(phenotypes, 1))

    # This loop ensure that if the trait is declared for any of the
    # field in field_ids then it is accepted to be true
    for field_id in asvector(fields_entry["fields"])
        field_columns = fieldcolumns(dataset, field_id)
        # Looping over the columns of the field:
        # This means that a trait is declared present
        # if it is diagnosed at any of the assessment visits
        for colname in field_columns
            column = maybe_convert_to_int(dataset[!, colname])
            for index in eachindex(column)
                coding = getindex(column, index)
                update_with_coding!(output, coding, index, coding_to_column_indices)
            end
        end
    end
    return DataFrame(collect(output), string.(phenotypes))
end

"""
    process_custom(dataset, fields_entry)

Processing function for a manually added column. SImply forward the column
"""
process_custom(dataset, fields_entry) =
    dataset[!, asvector(fields_entry["fields"])]

"""
    process_ordinal(dataset, fields_entry)
"""
function process_ordinal(dataset, fields_entry)
    field = only_one_field(fields_entry["fields"])
    output_df = DataFrame()
    for phenotype_entry in fields_entry["phenotypes"]
        operation = !haskey(phenotype_entry, "operation") ? "first" : phenotype_entry["operation"] 
        if operation == "first"
            column = dataset[!, Symbol(field, "-0.0")]
            output = Vector{Union{Int, Missing}}(undef, size(column, 1))
            for index in eachindex(column)
                val = column[index] 
                if val !== missing && val >= 0
                    output[index] = val
                end
            end
            output_df[!, Symbol(phenotype_entry["name"])] = output
        else
            throw(ArgumentError("Only `first` operation supported for now."))
        end
    end
    return output_df
end

"""
    process_continuous(dataset, fields_entry)
"""
function process_continuous(dataset, fields_entry)
    field = only_one_field(fields_entry["fields"])
    output_df = DataFrame()
    for phenotype_entry in fields_entry["phenotypes"]
        operation = !haskey(phenotype_entry, "operation") ? "first" : phenotype_entry["operation"] 
        if operation == "first"
            column = dataset[!, Symbol(field, "-0.0")]
            output = Vector{Union{Float64, Missing}}(undef, size(column, 1))
            for index in eachindex(column)
                val = column[index] 
                if val !== missing
                    output[index] = val
                end
            end
            output_df[!, Symbol(phenotype_entry["name"])] = output
        else
            throw(ArgumentError("Only `first` operation supported for now."))
        end
    end
    return output_df
end

"""
    process_integer(dataset, fields_entry)
"""
function process_integer(dataset, fields_entry)
    field = only_one_field(fields_entry["fields"])
    output_df = DataFrame()
    for phenotype_entry in fields_entry["phenotypes"]
        operation = !haskey(phenotype_entry, "operation") ? "first" : phenotype_entry["operation"] 
        if operation == "first"
            output_df[!, Symbol(phenotype_entry["name"])] = dataset[!, Symbol(field, "-0.0")]
        else
            throw(ArgumentError("Only `first` operation supported for now."))
        end
    end
    return output_df
end

"""
    process_categorical(dataset, fields_entry)
"""
function process_categorical(dataset, fields_entry)
    field = only_one_field(fields_entry["fields"])
    output_df = DataFrame()
    for phenotype_entry in fields_entry["phenotypes"]
        operation = !haskey(phenotype_entry, "operation") ? "first" : phenotype_entry["operation"] 
        if operation == "first"
            column = dataset[!, Symbol(field, "-0.0")]
            output = Vector{Union{String, Missing}}(missing, length(column))
            for index in eachindex(column)
                val = negative_as_missing(column[index])
                if val !== missing 
                    output[index] = string(val)
                end
            end
            if haskey(phenotype_entry, "codings")
                codings_output = Vector{Union{Bool, Missing}}(missing, length(column))
                codings = Set(string.(asvector(phenotype_entry["codings"])))
                for index in eachindex(output)
                    if output[index] !== missing 
                        codings_output[index] = output[index] ∈ codings
                    end
                end
                output_df[!, Symbol(phenotype_entry["name"])] = codings_output
            else
                output_df[!, Symbol(phenotype_entry["name"])] = output
            end
        else
            throw(ArgumentError("Only `first` operation supported for now."))
        end
    end
    return output_df
end
