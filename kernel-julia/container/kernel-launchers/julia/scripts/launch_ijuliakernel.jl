using IJulia


# Set up the kernel path
path = pathof(IJulia)
kernel_path = join(vcat(split(path, '/')[1:end-1], "kernel.jl"), '/')
@assert isfile(kernel_path)
pid = getpid()


# Determine the directory this script resides in
script_path = abspath(PROGRAM_FILE)
listener_file = joinpath(dirname(script_path), "server_listener.py")


# Set startup arguments
lower_port = 49152
upper_port = 65535
kernel_id = ARGS[2]
response_address = ARGS[6]
public_key = ARGS[8]


# Launch the server listener
svr_listener_cmd = `python3 -v -c
"import os, sys, importlib.util;
spec = importlib.util.spec_from_file_location('setup_server_listener', '$listener_file');
gl = importlib.util.module_from_spec(spec);
spec.loader.exec_module(gl);
gl.setup_server_listener(conn_filename='/tmp/confile.json', parent_pid=$pid,
                            lower_port=$lower_port, upper_port=$upper_port,
                            response_addr='$response_address', kernel_id='$kernel_id',
                            public_key='$public_key')"`

println("Starting server_listener.py")
@async Base.run(pipeline(svr_listener_cmd))


# Wait for the connection file to be created
while !isfile("/tmp/confile.json")
    sleep(0.2)
end
@assert isfile("/tmp/confile.json")


# Set ARGS for kernel.jl
empty!(ARGS)
push!(ARGS, "/tmp/confile.json")

println("Starting kernel.jl")
include(kernel_path)
