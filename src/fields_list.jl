function update_list!(fields_list, fields::AbstractVector)
    for field_id in fields
        update_list!(fields_list, field_id)
    end
end

update_list!(fields_list, field) =
    push!(fields_list, field)

function build_fields_list(parsed_args)
    conf = YAML.load_file(parsed_args["conf"])
    fields_list = Int[]
    for (_, entries) in conf
        for entry in entries
            update_list!(fields_list, entry["fields"])
        end
    end

    writedlm(parsed_args["output"], fields_list)
end