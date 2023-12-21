using Plots
using YAML
using Statistics

# ファイルパス
const YAML_FILE_PATH = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_pinkimac/231114outputdir/yamldir/2023-11-15T15:21:59.073__chi1.265_Ay50_rho0.4_T0.43_dT0.04_Rd0.0_Rt0.5_Ra1.877538_g0.0003999718779659611_run4.0e7_output.yaml"
const LAMMPSTRJ_FILE = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_pinkimac/231114outputdir/lammpstrjdir/2023-11-15T15:21:59.073__chi1.265_Ay50_rho0.4_T0.43_dT0.04_Rd0.0_Rt0.5_Ra1.877538_g0.0003999718779659611_run4.0e7_output.lammpstrj"
const NUM_ATOMS = 1250

# YAMLファイルから必要なデータを抽出する関数
function extract_data(file_path)
    data = YAML.load_file(file_path)
    parameter_list = ["time", "Yg"]
    extracted_data = Dict{String, Vector{Float64}}()

    for parameter in parameter_list
        extracted_data[parameter] = Float64[]
        for entry in data
            push!(extracted_data[parameter], entry[parameter])
        end
    end

    return extracted_data
end

# LAMMPSファイルからデータを読み込む関数
function read_atoms_data(file_path)
    atoms_data = Float64[]
    time_data = Float64[]

    open(file_path, "r") do file
        timestep_section = false
        atoms_section = false
        
        for line in eachline(file)
            if occursin("ITEM: TIMESTEP", line)
                # timeが25000より小さい時は, time_dataもatoms_dataも, push!をスキップしたい.
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

# yの標準偏差を計算する関数
function calculate_y_std_deviation(atoms_data, num_atoms)
    time_steps = length(atoms_data["atoms_data"]) ÷ num_atoms
    standard_deviations = Float64[]
    Yg_values = Float64[]

    for i in 1:time_steps
        start_index = (i - 1) * num_atoms + 1
        end_index = i * num_atoms
        positions = atoms_data["atoms_data"][start_index:end_index]
        push!(Yg_values, mean(positions))
        push!(standard_deviations, std(positions, corrected = false))
    end
    
    return standard_deviations
end

# データ抽出
extracted_data = extract_data(YAML_FILE_PATH)

# LAMMPSファイルからデータを読み込み
atoms_data = read_atoms_data(LAMMPSTRJ_FILE)

# yの標準偏差を計算
y_std_deviations = calculate_y_std_deviation(atoms_data, NUM_ATOMS)

# プロット
plot()
plt = plot!(extracted_data["Yg"] ./ 80, y_std_deviations, label="", st=scatter, mc=:red, ms=5, xlims=(0.2,0.8))
title!("(StD of y)/Ly vs. Yg/Ly")
xlabel!("Yg/Ly")
ylabel!("(StD of y)/Ly")
zlabel!("time")
# savefig("fig4y_cycle")
display(plt)

# プロットの表示
ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
read(stdin, 1)
