using Plots
using YAML
using Statistics

function extract_ra_rt_values(file_path)
    # 正規表現を使ってRtとRaの値を抽出する
    regex_pattern = r"Rt([\d.]+)_Ra([\d.]+)"
    match_result = match(regex_pattern, basename(file_path))
    
    if match_result !== nothing
        # タプルとしてRtとRaの値を返す
        rt_value = parse(Float64, match_result.captures[1])
        ra_value = parse(Float64, match_result.captures[2])
        return (rt_value, ra_value)
    else
        # マッチしない場合は `nothing` を返す
        return (nothing, nothing)
    end
end


function plot_lnstd_vs_parameter(yaml_directory, parameter_key, x_label, y_label, title_label)
    # YAMLファイルのパスをフィルタリング
    yaml_file_paths = filter(x -> occursin(".yaml", x), readdir(yaml_directory))

    # 複数のパスに手動で対応.
    # yaml_file_paths = [
    # # 追加の YAML ファイルパスをここに追加.
    # ]

    # Rt-Ra毎のデータを保持する辞書
    rt_ra_data = Dict{Tuple{Float64, Float64}, Vector{Float64}}()

    # 各YAMLファイルからデータを抽出してグループ化
    for yaml_file_path in yaml_file_paths
        rt, ra = extract_ra_rt_values(yaml_file_path)
        if rt !== nothing && ra !== nothing
            data = YAML.load_file(joinpath(yaml_directory, yaml_file_path))
            Yg_values = [entry["Yg"] for entry in data if entry["time"] > 25000]
            std_Yg = std(Yg_values,corrected=false)
            ln_std_Yg = log(std_Yg)
            key = (rt, ra)
            # 辞書にデータを追加または新規追加する
            if haskey(rt_ra_data, key)
                push!(rt_ra_data[key], ln_std_Yg)
            else
                rt_ra_data[key] = [ln_std_Yg]
            end
        end
    end

    # ラベルやタイトルの設定
    plot()
    xlabel!(x_label)
    ylabel!(y_label)
    ylims!(0.0,2.5)
    title!(title_label)

    parameter_values = parameter_key == :rt ? unique([key[1] for key in keys(rt_ra_data)]) : unique([key[2] for key in keys(rt_ra_data)])
    sorted_values = sort(parameter_values)

    for parameter_value in sorted_values
        values_for_parameter = parameter_key == :rt ? [key[2] for key in keys(rt_ra_data) if key[1] == parameter_value] : [key[1] for key in keys(rt_ra_data) if key[2] == parameter_value]
        sorted_values_for_parameter = sort(values_for_parameter)

        sorted_std_Yg_values = parameter_key == :rt ? [rt_ra_data[(parameter_value, ra)][1] for ra in sorted_values_for_parameter] : [rt_ra_data[(rt, parameter_value)][1] for rt in sorted_values_for_parameter]

        plot!(sorted_values_for_parameter, sorted_std_Yg_values, label="$(parameter_key == :rt ? "Rt" : "Ra")=$(parameter_value)", marker=:circle, line=:dash)
    end
end

# 関数の実行
yaml_directory = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir_ness/231204outputdir/yamldir"

# 横軸Raでプロット
plot_lnstd_vs_parameter(yaml_directory, :rt, "Ra", "ln Standard Deviation of Yg", "ln Standard Deviation of Yg vs. Ra for different Rt")

# 横軸Rtでプロット
# plot_lnstd_vs_parameter(yaml_directory, :ra, "Rt", "ln Standard Deviation of Yg", "ln Standard Deviation of Yg vs. Rt for different Ra")

# display(plot!())
# savefig("lnStdYg_Ra0.70407675to0.98769_Rt0.5_ti25000.png")
savefig("lnStdYg_Rt0.0to0.5_Ra0.0to1.877538_ti25000")
