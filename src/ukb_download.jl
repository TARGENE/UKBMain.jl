
const CONTENT_LENGTH = Dict(
    6 => 4,
    19 => 5,
    100377 => 9
)

download_fields_metadata(;output="fields_metadata.txt") = 
    Downloads.download("biobank.ndph.ox.ac.uk/ukb/scdown.cgi?fmt=txt&id=1", output)

read_fields_metadata(;input="fields_metadata.txt") =
    CSV.read(input, DataFrame)

default_coding_path(id) = string("ukb_datacoding_", id, ".tsv")

function download_datacoding(id; output=default_coding_path(id))
    open(output, "w") do io
        HTTP.post(
            "https://biobank.ndph.ox.ac.uk/showcase/codown.cgi", 
            Dict(
                "Accept"=>"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
                "Accept-Encoding"=>"gzip, deflate, br",
                "Accept-Language"=>"en-GB,en;q=0.5",
                "Connection"=>"keep-alive",
                "Content-Length"=> string(CONTENT_LENGTH[id]),
                "Content-Type"=>"application/x-www-form-urlencoded",
                "Host"=> "biobank.ndph.ox.ac.uk",
                "Origin"=>"https://biobank.ndph.ox.ac.uk",
                "Referer"=> string("https://biobank.ndph.ox.ac.uk/showcase/coding.cgi?id=", id),
                "Sec-Fetch-Dest"=>"document",
                "Sec-Fetch-Mode"=> "navigate",
                "Sec-Fetch-Site"=> "same-origin",
                "Sec-Fetch-User"=>"?1",
                "Upgrade-Insecure-Requests"=> "1",
        ),
            Dict("id"=>string(id));
            response_stream=io
        )
    end
end

read_datacoding(input) = CSV.read(input, DataFrame)


function download_and_read_codings()
    download_datacoding_6()
    download_datacoding_19()

    return Dict(6=>read_datacoding_6(), 19 => read_datacoding_19())
end
