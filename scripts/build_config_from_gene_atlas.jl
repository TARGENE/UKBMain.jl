using ArgParse
using HTTP
using Gumbo
using AbstractTrees
using DataFrames
using YAML

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--out", "-o"
            help = "Path to output configuration file"
            arg_type = String
            default = "geneatlas_config.yaml"
    end

    return parse_args(s)
end

function find_div(html)
    for elem in PreOrderDFS(html.root)
        if elem isa HTMLText
            if occursin("UK Biobank fields", elem.text)
                return elem.parent.parent
            end
        end
    end
    throw(ErrorException("The mapping division was not found"))
end

function get_html(id)
    response = HTTP.get(
        "http://geneatlas.roslin.ed.ac.uk/trait/?traits=$id", 
        Dict(
            "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Encoding"=>"gzip, deflate",
            "Accept-Language"=>"en-GB,en;q=0.5",
            "Host"=> "geneatlas.roslin.ed.ac.uk",
        )
    )
    return parsehtml(String(response.body))
end

extract_fields(elem::HTMLText) = elem.text
extract_fields(elem::HTMLElement{:a}) = elem[1].text
extract_fields(elem) = ""

function extract_fields(elem, index)
    fields = ""
    next_index = index + 1
    next_elem = elem[next_index]
    while !(next_elem isa HTMLElement{:br})
        fields = fields * extract_fields(next_elem)
        next_index += 1 
        next_elem = elem[next_index]
    end
    return fields
end

function update_mapping!(mapping; max_index=777)
    for id in (size(mapping, 1)):max_index
        @info("Scrapping Outcome: $id")
        html = get_html(id)
        div = find_div(html)
        desc, fields, codes = nothing, nothing, nothing
        for index in firstindex(div.children):lastindex(div.children)
            if occursin("Description:", string(div.children[index]))
                desc = div.children[index + 1].text
            elseif occursin("UK Biobank fields:", string(div.children[index]))
                fields = extract_fields(div.children, index)
            elseif occursin("Field Codes:", string(div.children[index]))
                codes = div.children[index + 1].text
            end
        end

        push!(mapping, (desc, fields, codes))
    end
end

function process_fields_string(fields_string)
    fields = []
    for fieldstring in split(replace(fields_string, " " => ""), ",")
        if endswith(fieldstring, "-0.0")
            push!(fields, fieldstring[1:end-4])
        else
            push!(fields, fieldstring)
        end
    end
    return fields
end


function data_from_mapping(mapping)
    data = []
    for (fields, group) in pairs(groupby(mapping, :UKBFields))
        # Skipping # (46/47) and (48/49) fields
        if occursin("/", fields.UKBFields)
            continue
        end
        fields_dict = Dict(
            "fields"     => process_fields_string(fields.UKBFields),
            "phenotypes" => []
        )
        for row in eachrow(group)
            if row.UKBFieldsCodes isa Nothing || occursin("nan", row.UKBFieldsCodes)
                phenotype_dict = Dict("name" => row.Description)
            else
                phenotype_dict = Dict("name" => row.Description, "codings" => split(replace(row.UKBFieldsCodes, " " => ""), ","))
            end
            push!(fields_dict["phenotypes"], phenotype_dict)
        end 
        push!(data, fields_dict)
    end
    return data
end

function main(args)
    mapping = DataFrame(Description=[], UKBFields=[], UKBFieldsCodes=[])
    update_mapping!(mapping)

    mapping.Description .= strip.(mapping.Description, ' ')

    data = data_from_mapping(mapping)
    YAML.write_file(args["out"], Dict("traits" => data))
    @info("Done.")
end

main(parse_commandline())
