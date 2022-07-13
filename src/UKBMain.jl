module UKBMain
using CSV
using DataFrames
using CategoricalArrays
using MLJModels
using MLJModelInterface
using MLJBase
using HTTP
using Downloads
using DelimitedFiles
using SparseArrays

"""
    field_metadata(fields::DataFrame, field_id::Int)

Retrieves the row corresponding to `field_id` from the metadata Dataframe `fields`.
"""
function fieldmetadata(fields::DataFrame, field_id::Int)
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

function convertcolumn(column::Vector, ::Type{CategoricalValue}, colname)
    model = OneHotEncoder(drop_last=false)
    X = NamedTuple{(Symbol(colname),)}([categorical(column),])
    fitresult, _, _ = MLJModelInterface.fit(model, 0, X)
    return MLJModelInterface.transform(model, fitresult, X)
end

function process!(dataset, colname, field_metadata)
    column = dataset[:, colname]
    if field_metadata.value_type == 11
        dataset[!, colname] = convertcolumn(column, Int)
    elseif field_metadata.value_type == 21 && Set(unique(skipmissing(column))) == Set([0, 1])
        println(colname)
        dataset[!, colname] = convertcolumn(column, Bool)
    elseif field_metadata.value_type == 21
        select!(dataset, Not(colname))
        encoded = convertcolumn(column, CategoricalValue, colname)
        for key in keys(encoded)
            dataset[!, key] = getproperty(encoded, key)
        end
    elseif field_metadata.value_type == 22

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
    rename!(dataset, :eid => :SAMPLE_ID)

    fields = CSV.read(fieldsfile, DataFrame)
    
    for colname in names(dataset)[2:end]
        field_id = parse(Int, split(colname, "-")[1])
        process!(dataset, colname, field_metadata(fields, field_id))
    end

    CSV.write(outfile, dataset)
end

function csvmerge(parsed_args)
    csv₁ = CSV.read(parsed_args["csv1"], DataFrame)
    csv₂ = CSV.read(parsed_args["csv2"], DataFrame)
    CSV.write(parsed_args["out"], innerjoin(csv₁, csv₂, on=:SAMPLE_ID))
end

function fieldsroles(parsed_args)
    roles_to_fields = Dict()
    for role in ("covariates", "confounders", "phenotypes", "treatments")
        if parsed_args[role] !== nothing
            roles_to_fields[role] = readdlm(parsed_args[role], Int)
        end
    end
    return roles_to_fields
end

function read_dataset(dataset_file::String, subset_file::Nothing)
    return CSV.read(dataset_file, DataFrame)
end

function read_dataset(dataset_file::String, subset_file::String)
    dataset = CSV.read(parsed_args["dataset"], DataFrame)
    subset = JSON.parse(parsed_args["subset"];)
    return dataset
end

function extract_from_field(dataset, field_metadata, coding)
    # Categorical Multiple values
    if field_metadata.value_type == 22
        # for each individual we list all traits that were diagnosed
        # for at least one of the assessment visit 
        n = nrows(dataset)
        p = nrows(coding)
        output = spzeros(Bool, n, p)
        field_id = field_metadata.field_id
        value_to_index = Dict(val => i for (i, val) in  enumerate(coding.coding))
        field_columns = filter(x -> startswith(x, string(field_id)), names(dataset))
        
        for colname in field_columns
            column = dataset[!, colname]
            for index in eachindex(column)
                value = getindex(column, index)
                if value !== missing
                    output[index, value_to_index[value]] = 1
                end
            end
        end

        return DataFrame(collect(output), string.(field_id, "-", coding.coding))

    end
end

function main(parsed_args)

    # Read queried fields
    roles_to_fields = fieldsroles(parsed_args)

    # Download and read fields metadata
    download_fields_metadata()
    fields_metadata = read_fields_metadata()

    # Download and read data codings
    download_datacoding_6()
    coding_6 = read_datacoding_6()

    # Read dataset
    dataset = read_dataset(parsed_args["dataset"], parsed_args["subset"])
    
    for (role, fields) in roles_to_fields
        output = DataFrame()
        for field in fields
            field_metadata = fieldmetadata(fields_metadata, field)
            field_output = extract_from_field(dataset, field_metadata, coding_6)
            output = hcat(output, field_output)
        end
        outfile = string(parsed_args["out-prefix"], ".", role, ".csv")
        CSV.write(outfile, output)
    end

end

export decode, csvmerge, main

end
