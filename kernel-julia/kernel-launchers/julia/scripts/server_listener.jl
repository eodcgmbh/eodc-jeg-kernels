module ServerListener

using Sockets
using JSON
using UUIDs
using Base64
using Random
using Logging
using Nettle
using MbedTLS

const LAUNCHER_VERSION = 1
const MAX_PORT_RANGE_RETRIES = parse(Int, get(ENV, "MAX_PORT_RANGE_RETRIES", get(ENV, "EG_MAX_PORT_RANGE_RETRIES", "5")))

# Configure basic logging
global_logger(ConsoleLogger(stdout, Logging.Info))

function _pkcs7_pad(data::Vector{UInt8}, block_size::Int=16)
    pad_len = block_size - (length(data) % block_size)
    padded = copy(data)
    append!(padded, fill(UInt8(pad_len), pad_len))
    return padded
end

function _encrypt(connection_info_str::String, public_key_b64::String)
    # Generate 16-byte AES key
    aes_key = rand(UInt8, 16)

    # Encrypt connection info using AES-ECB
    encrypter = Encryptor("AES128", aes_key)
    padded_info = _pkcs7_pad(Vector{UInt8}(connection_info_str))
    encrypted_connection_info = encrypt(encrypter, padded_info)
    b64_connection_info = base64encode(encrypted_connection_info)

    # Encrypt AES key using the server's RSA public key (PKCS1 v1.5)
    rsa_pub = MbedTLS.parse_public_key(base64decode(public_key_b64))
    encrypted_key = MbedTLS.encrypt(rsa_pub, aes_key)
    b64_encrypted_key = base64encode(encrypted_key)

    payload = Dict(
        "version" => LAUNCHER_VERSION,
        "key" => b64_encrypted_key,
        "conn_info" => b64_connection_info
    )
    
    return base64encode(JSON.json(payload))
end

function _get_candidate_port(lower_port::Int, upper_port::Int)
    return lower_port == upper_port ? 0 : rand(lower_port:upper_port)
end

function _select_socket(lower_port::Int, upper_port::Int)
    retries = 0
    while true
        port = _get_candidate_port(lower_port, upper_port)
        try
            server = listen(IPv4(0), port)
            return server, port
        catch
            retries += 1
            if retries > MAX_PORT_RANGE_RETRIES
                error("Failed to locate port within range $lower_port..$upper_port after $MAX_PORT_RANGE_RETRIES retries!")
            end
        end
    end
end

function _select_ports(count::Int, lower_port::Int, upper_port::Int)
    ports = Int[]
    servers = Sockets.TCPServer[]

    for _ in 1:count
        server, port = _select_socket(lower_port, upper_port)
        push!(ports, port)
        push!(servers, server)
    end

    # Close sockets to free the ports for the kernel
    for server in servers
        close(server)
    end

    return ports
end

function prepare_comm_socket(lower_port::Int, upper_port::Int)
    server, port = _select_socket(lower_port, upper_port)
    @info "Signal socket bound to host: 0.0.0.0, port: $port"
    return server, port
end

function return_connection_info(conn_filename::String, response_addr::String, lower_port::Int, upper_port::Int, kernel_id::String, public_key::String, parent_pid::Int)
    response_parts = split(response_addr, ":")
    if length(response_parts) != 2
        @error "Invalid format for response address '$response_addr'. Assuming 'pull' mode..."
        return nothing
    end

    response_ip = response_parts[1]
    response_port = tryparse(Int, response_parts[2])
    if response_port === nothing
        @error "Invalid port component found in response address '$response_addr'. Assuming 'pull' mode..."
        return nothing
    end

    cf_json = JSON.parsefile(conn_filename)

    # Add OS process identifiers
    cf_json["pid"] = parent_pid
    cf_json["pgid"] = ccall(:getpgid, Cint, (Cint,), parent_pid)

    comm_server, comm_port = prepare_comm_socket(lower_port, upper_port)
    cf_json["comm_port"] = comm_port
    cf_json["kernel_id"] = kernel_id

    json_content = JSON.json(cf_json)
    payload = _encrypt(json_content, public_key)

    # Send encrypted payload back to Enterprise Gateway
    conn = connect(response_ip, response_port)
    write(conn, payload)
    close(conn)

    return comm_server
end

function get_server_request(server::Sockets.TCPServer)
    conn = accept(server)
    data = String(readavailable(conn))
    close(conn)
    return isempty(data) ? nothing : JSON.parse(data)
end

function server_listener(server::Sockets.TCPServer, parent_pid::Int)
    shutdown = false
    while !shutdown
        request = get_server_request(server)
        if request !== nothing
            signum = -1
            if haskey(request, "signum")
                signum = convert(Int, request["signum"])
                ccall(:kill, Cint, (Cint, Cint), parent_pid, signum)
            end
            if haskey(request, "shutdown")
                shutdown = convert(Bool, request["shutdown"])
            end
            if signum != 0
                @info "server_listener got request: $request"
            end
        end
    end
end

function setup_server_listener(; conn_filename::String, parent_pid::Int, lower_port::Int, upper_port::Int, response_addr::String, kernel_id::String, public_key::String)
    
    key = string(uuid4())
    ports = _select_ports(5, lower_port, upper_port)

    # Construct standard Jupyter connection dictionary
    conn_data = Dict(
        "ip" => "0.0.0.0",
        "key" => key,
        "transport" => "tcp",
        "signature_scheme" => "hmac-sha256",
        "shell_port" => ports[1],
        "iopub_port" => ports[2],
        "stdin_port" => ports[3],
        "hb_port" => ports[4],
        "control_port" => ports[5]
    )

    open(conn_filename, "w") do f
        write(f, JSON.json(conn_data))
    end
    println("Connection file written to: $conn_filename")

    if response_addr != ""
        comm_server = return_connection_info(
            conn_filename,
            response_addr,
            lower_port,
            upper_port,
            kernel_id,
            public_key,
            parent_pid
        )

        if comm_server !== nothing
            println("Server listener started for kernel $kernel_id")
            # Launch the listener loop asynchronously 
            @async server_listener(comm_server, parent_pid)
        end
    end
end

end # module ServerListener