function update_list!(fields_list, entry::Vector)
    for field_id in entry
        push!(fields_list, field_id)
    end
end

update_list!(fields_list, entry::Int) =
    push!(fields_list, entry)

update_list!(fields_list, entry::Dict) =
    update_list!(fields_list, entry["field"])


function build_fields_list(parsed_args)
    conf = YAML.load_file(parsed_args["conf"])
    fields_list = Int[]
    for (role, entries) in conf
        for entry in entries
            update_list!(fields_list, entry)
        end
    end

    writedlm(parsed_args["output"], fields_list)
end