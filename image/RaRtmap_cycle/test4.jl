using Plots
using YAML
using Statistics

# ディレクトリ内のファイルリストを取得する関数
function list_files_in_directory(directory)
    files = readdir(directory)
    return files
end

# ディレクトリを指定
const DIRECTORY = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_pinkimac/231114outputdir/yamldir/"

# ディレクトリ内のファイルリストを取得
file_list = list_files_in_directory(DIRECTORY)

# ここでファイルリストから目的のファイルを選択する方法を実装します
# 例えば、最初のファイルを選択するなどの方法を選んでください
selected_file = joinpath(DIRECTORY, file_list[1])

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
extracted_data = extract_data(selected_file)

# LAMMPSファイルからデータを読み込み
lammpstrj_file = replace(selected_file, "yamldir" => "lammpstrjdir")
atoms_data = read_atoms_data(lammpstrj_file)

# yの標準偏差を計算
y_std_deviations = calculate_y_std_deviation(atoms_data, NUM_ATOMS)

# プロット
plot()
plt = plot!(extracted_data["Yg"] ./ 80, y_std_deviations, label="", st=scatter, mc=:red, ms=5, xlims=(0.2,0.8))
title!("(StD of y)/Ly vs. Yg/Ly")
xlabel!("Yg/Ly")
ylabel!("(StD of y)/Ly")
zlabel!("time")
display(plt)

# プロットの表示
ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
read(stdin, 1)
