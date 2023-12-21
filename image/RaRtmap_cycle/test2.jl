using Plots
using YAML
using Statistics

function process_data(lammpstrj_file)
    NUM_ATOMS = 1250
    
    atoms_data = read_atoms_data(lammpstrj_file)
    y_std_deviations, Yg_values = calculate_y_std_deviation(atoms_data["atoms_data"], NUM_ATOMS)
    
    plot_results(Yg_values, y_std_deviations, time_values)
end

function read_atoms_data(lammpstrj_file)
    data = Dict{String, Any}()
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
                push!(atoms_data, parse(Float64, parts[3])/80) # yのデータが記述される列を指定.
            else
                atoms_section = false
            end
        end
    end
    
    data["time_data"] = time_data
    data["atoms_data"] = atoms_data
    return data
end

function calculate_y_std_deviation(atoms_data, num_atoms)
    time_steps = length(atoms_data) ÷ num_atoms
    standard_deviations = Float64[]
    Yg_values = Float64[]
    for i in 1:time_steps
        start_index = (i - 1) * num_atoms + 1
        end_index = i * num_atoms
        positions = atoms_data[start_index:end_index]
        push!(standard_deviations, std(positions,corrected=false))
        push!(Yg_values, mean(positions))
    end
    
    return standard_deviations, Yg_values
end

function plot_results(Yg_values, y_std_deviations, time_values)
    plotly()
    plot()
    plt = plot(Yg_values, y_std_deviations, time_values, label="", st=scatter, mc=:red, ms=2, xlims=(0.2, 0.8))
    xlabel!("Yg/Ly")
    ylabel!("(StD of y)/Ly")
    zlabel!("time")
    display(plot!())
    # 
    ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
    read(stdin, 1)
end

yaml_file_path = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_pinkimac/231114outputdir/yamldir/2023-11-15T15:21:59.073__chi1.265_Ay50_rho0.4_T0.43_dT0.04_Rd0.0_Rt0.5_Ra1.877538_g0.0003999718779659611_run4.0e7_output.yaml"

lammpstrj_file = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_pinkimac/231114outputdir/lammpstrjdir/2023-11-15T15:21:59.073__chi1.265_Ay50_rho0.4_T0.43_dT0.04_Rd0.0_Rt0.5_Ra1.877538_g0.0003999718779659611_run4.0e7_output.lammpstrj"


process_data(yaml_file_path, lammpstrj_file)
