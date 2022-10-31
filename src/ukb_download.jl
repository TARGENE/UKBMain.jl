
const CONTENT_LENGTH = Dict(
    6 => 4,
    19 => 5,
    100377 => 9,
    100430 => 9,
    100349 => 9,
    7 => 4,
    1001 => 7,
    9 => 4
)

download_fields_metadata(;output="fields_metadata.txt") = 
    Downloads.download("biobank.ndph.ox.ac.uk/ukb/scdown.cgi?fmt=txt&id=1", output)

read_fields_metadata(;input="fields_metadata.txt") =
    CSV.read(input, DataFrame)

function download_and_read_fields_metadata(;path="fields_metadata.txt")
    if !isfile(path)
        download_fields_metadata(;output=path)
    end
    return read_fields_metadata(input=path)
end


default_coding_path(id) = string("ukb_datacoding_", id, ".tsv")

function download_datacoding(id; output=default_coding_path(id))
    open(output, "w") do io
        HTTP.post(
            "https://biobank.ndph.ox.ac.uk/showcase/codown.cgi", 
            Dict(
                "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
                "Accept-Encoding"=>"gzip, deflate, br",
                "Accept-Language"=>"en-GB,en;q=0.5",
                "Content-Length"=> string(CONTENT_LENGTH[id]),
                "Content-Type"=>"application/x-www-form-urlencoded",
                "Host"=> "biobank.ndph.ox.ac.uk",
                "Origin"=>"https://biobank.ndph.ox.ac.uk",
                "Referer"=> string("https://biobank.ndph.ox.ac.uk/showcase/coding.cgi?id=", id),
        ),
            Dict("id"=>string(id));
            response_stream=io,
            readtimeout=20,
            retry_non_idempotent=true
        )
    end
end

read_datacoding(input) = CSV.read(input, DataFrame)


function download_and_read_datacoding(id)
    if !isfile(default_coding_path(id))
        download_datacoding(id)
    end
    data = CSV.read(default_coding_path(id), DataFrame)
    if size(data, 1) == 0
        sleep(5)
        return download_and_read_datacoding(id)
    else
        return data
    end
end
