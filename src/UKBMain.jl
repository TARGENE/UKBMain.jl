module UKBMain
using CSV
using DataFrames

"""
    field_metadata(fields::DataFrame, field_id::Int)

Retrieves the row corresponding to `field_id` from the metadata Dataframe `fields`.
"""
function field_metadata(fields::DataFrame, field_id::Int)
    row_id = findfirst(x -> x.field_id == field_id, eachrow(fields))
    return fields[row_id, :]
end

"""
    first_instance_fields(datasetfile)

Retrieves fields that correspond to first instances only.
"""
function first_instance_fields(datasetfile)
    all_fields = names(CSV.read(datasetfile, DataFrame, limit=1))
    final_fields = String[] 
    for field in all_fields[2:end]
        if split(field, "-")[2][1] == '0'
            push!(final_fields, field)
        end
    end
    return vcat(all_fields[1], final_fields)
end

convertcolumn(column::Vector{T}, ::Type{T}) where T = column

function convertcolumn(column::Vector{Union{Missing, T₁}}, ::Type{T₂}) where {T₁, T₂}
    convert(Vector{Union{T₂, Missing}}, column)
end

function convertcolumn(column::Vector{T₁}, ::Type{T₂}) where {T₁, T₂}
    convert(Vector{T₂}, column)
end

function process!(dataset, colname, field_metadata)
    column = dataset[:, colname]
    if field_metadata.value_type == 11
        dataset[!, colname] = convertcolumn(column, Int)
    elseif field_metadata.value_type == 21
        dataset[!, colname] = convertcolumn(column, Bool)
    end
end

"""
    decode(parsed_args)

A main dataset is decoded:
    - only the first instance of each field is kept
    - datatypes are converted as per field_value. Currently this only supports fields 
    that represent Integers and Booleans.
"""
function decode(parsed_args)
    datasetfile = parsed_args["dataset"]
    fieldsfile = parsed_args["fields"]
    outfile = parsed_args["out"]

    columns = first_instance_fields(datasetfile)
    dataset = CSV.read(datasetfile, DataFrame, select=columns)

    fields = CSV.read(fieldsfile, DataFrame)
    
    for colname in names(dataset)[2:end]
        field_id = parse(Int, split(colname, "-")[1])
        process!(dataset, colname, field_metadata(fields, field_id))
    end

    CSV.write(outfile, dataset)
end

export decode
end
