# 汎用時系列グラフ描画セル.

# ライブラリ.
using Plots
using YAML
using Statistics

# 複数のパスに手動で対応.
yaml_file_path = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_pinkimac/231114outputdir/yamldir/2023-11-15T15:21:59.073__chi1.265_Ay50_rho0.4_T0.43_dT0.04_Rd0.0_Rt0.5_Ra1.877538_g0.0003999718779659611_run4.0e7_output.yaml"

# YAMLファイルを読み取る.
data = YAML.load_file(yaml_file_path)

# 各データポイントから必要なデータを抽出.
parameter_list = ["step", "time", "temp", "pe", "ke", "etotal", "Yg"]
extracted_data = Dict{String, Any}()
for parameter in parameter_list
    extracted_data[parameter] = [entry[parameter] for entry in data if entry["time"] > 25000]
end

# x軸y軸の代表パラメータ.
time_values = extracted_data["time"]
Yg_values = extracted_data["Yg"] ./ 80



const lammpstrj_file = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_pinkimac/231114outputdir/lammpstrjdir/2023-11-15T15:21:59.073__chi1.265_Ay50_rho0.4_T0.43_dT0.04_Rd0.0_Rt0.5_Ra1.877538_g0.0003999718779659611_run4.0e7_output.lammpstrj"
const NUM_ATOMS = 1250

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
                # timeが25000より小さい時は, time_dataもatoms_dataも, push!をスキップしたい.
                if time <= 25000
                    continue  # 次のループに進む
                end
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
        push!(Yg_values, mean(positions))
        push!(standard_deviations, std(positions,corrected=false))
    end
    
    return standard_deviations
end

data = read_atoms_data(lammpstrj_file)
y_std_deviations= calculate_y_std_deviation(data["atoms_data"], NUM_ATOMS)

# plotly()
plot()
plt = plot!(Yg_values,y_std_deviations,label="",st=scatter,mc=:red,ms=5,xlims=(0.2,0.8))
title!("(StD of y)/Ly vs. Yg/Ly")
xlabel!("Yg/Ly")
ylabel!("(StD of y)/Ly")
zlabel!("time")
display(plot!())
savefig("fig4y_cycle")

ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
read(stdin, 1)