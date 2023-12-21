using Plots
using YAML
using Statistics

const NUM_ATOMS = 1250

function process_data(yaml_file_path, lammpstrj_file)
    extracted_data = extract_data(YAML.load_file(yaml_file_path))
    time_values = extracted_data["time"]
    Yg_values = extracted_data["Yg"] ./ 80
    
    atoms_data = read_atoms_data(lammpstrj_file)
    y_std_deviations = calculate_y_std_deviation(atoms_data, NUM_ATOMS)
    
    plot_results(Yg_values, y_std_deviations, time_values)
end

function extract_data(data)
    parameter_list = ["step", "time", "temp", "pe", "ke", "etotal", "Yg"]
    extracted_data = Dict{String, Any}()
    for parameter in parameter_list
        extracted_data[parameter] = [entry[parameter] for entry in data]
    end
    return extracted_data
end

function read_atoms_data(lammpstrj_file)
    atoms_data = Float64[]
    time_data = Float64[]

    open(lammpstrj_file, "r") do file
        timestep_section = false
        atoms_section = false
        
        for line in eachline(file)
            if occursin("ITEM: TIMESTEP", line)
                step = parse(Float64, readline(file))
                time = step * 0.005
                push!(time_data, time)
            elseif occursin("ITEM: ATOMS", line)
                atoms_section = true
            elseif atoms_section && !occursin("ITEM:", line)
                parts = split(line)
                push!(atoms_data, parse(Float64, parts[3]) / 80) # yのデータが記述される列を指定.
            else
                atoms_section = false
            end
        end
    end
    
    return Dict("time_data" => time_data, "atoms_data" => atoms_data)
end

function calculate_y_std_deviation(atoms_data, num_atoms)
    time_steps = div(length(atoms_data), num_atoms, 0)
    standard_deviations = Float64[]
    Yg_values = Float64[]
    
    for i in 1:time_steps
        start_index = (i - 1) * num_atoms + 1
        end_index = min(i * num_atoms, length(atoms_data))  # Ensure we don't go beyond the length of atoms_data
        positions = atoms_data[start_index:end_index]
        push!(Yg_values, mean(positions))
        push!(standard_deviations, std(positions, corrected = false))
    end
    
    return standard_deviations
end


function plot_results(Yg_values, y_std_deviations, time_values)
    plot()
    plt = plot!(Yg_values, y_std_deviations, time_values, label = "", st = scatter, mc = :red, ms = 2, xlims = (0.2, 0.8))
    xlabel!("Yg/Ly")
    ylabel!("(StD of y)/Ly")
    zlabel!("time")
    display(plot!())

    ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
    read(stdin, 1)
end

yaml_file_path = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_pinkimac/231114outputdir/yamldir/2023-11-15T15:21:59.073__chi1.265_Ay50_rho0.4_T0.43_dT0.04_Rd0.0_Rt0.5_Ra1.877538_g0.0003999718779659611_run4.0e7_output.yaml"
lammpstrj_file = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_pinkimac/231114outputdir/lammpstrjdir/2023-11-15T15:21:59.073__chi1.265_Ay50_rho0.4_T0.43_dT0.04_Rd0.0_Rt0.5_Ra1.877538_g0.0003999718779659611_run4.0e7_output.lammpstrj"

process_data(yaml_file_path, lammpstrj_file)
