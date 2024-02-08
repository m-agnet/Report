#===
# LAMMPSシミュレーション実行と出力ファイル保管

このJuliaコードは,LAMMPS分子動力学シミュレーションを実行し,生成された出力ファイルを適切なディレクトリに保存します.

## 機能

- `Glob`と`Dates`パッケージを使用してファイルマッチングと日時取得を行う
- パラメータを配列で定義
- LAMMPSファイル内のプレースホルダーをパラメータ値に置き換えて,実行用スクリプトを生成
- パラメータごとにLAMMPSを実行し,生成された出力ファイルを指定のディレクトリに移動
- 使用済みの仮LAMMPSファイルを一括削除

## 手順

1. LAMMPSファイルの特定とパラメータ設定
2. パラメータの範囲を定義
3. パラメータの組み合わせごとにLAMMPSを実行
4. 出力ファイルを指定ディレクトリに保存
5. 使用済みの仮LAMMPSファイルを削除

このコードは,異なるパラメータでのLAMMPSシミュレーションを自動化し,出力ファイルの整理と保管を行います.
===#

using Glob # ファイルパターンのマッチングに使用するパッケージ
using Dates # 日付と時刻の取得に使用するパッケージ

# 実行するLAMMPSファイルを特定
lammpsfile = glob("in.*")[1]

# パラメータの設定
chi = 1.265
remark_text = "test"
file_extensions = ["log", "yaml", "lammpstrj"] # 出力ファイルの拡張子

# パラメータの範囲を設定
Ay_range = range(50, length=1) # Ayの範囲
rho_range = range(0.4, length=1) # 密度の範囲
T_range = range(0.43, length=1) # 初期温度の範囲
dT_range = range(0.04, length=1) # 熱浴の温度差の範囲
Rd_range = range(0.0, length=1) # 乾燥度の範囲
Rt_range = range(0.0, 0.5, length=5) # 壁の厚みの範囲
Ra_range = range(0.0, 1.877538, length=5) # 引力幅の範囲
run_range = range(4e7, length=1) # 実行ステップ数の範囲

# パラメータごとに実験を実行
for Ay_value in Ay_range, 
    rho_value in rho_range, 
    T_value in T_range, 
    dT_value in dT_range,
    Rd_value in Rd_range, 
    Rt_value in Rt_range, 
    Ra_value in Ra_range, 
    run_value in run_range

    # パラメータに基づいて重力を計算
    g_value = dT_value / ((Ay_value / sqrt(rho_value)) * chi)

    # 実験日時を記録
    n = string(now())

    # パラメータに基づいた出力ファイル名を生成
    parameter = "chi$(chi)_Ay$(Ay_value)_rho$(rho_value)_T$(T_value)_dT$(dT_value)_Rd$(Rd_value)_Rt$(Rt_value)_Ra$(Ra_value)_g$(g_value)_run$(run_value)"
    outputtitle = "$(n)_$(remark_text)_$(parameter)"

    # LAMMPSファイルの内容を読み込み,パラメータを置換
    template_script = read(lammpsfile, String)
    mod_script = replace(template_script,
        "PLACEHOLDER_Ay" => string(Ay_value),
        "PLACEHOLDER_rho" => string(rho_value),
        "PLACEHOLDER_T" => string(T_value), 
        "PLACEHOLDER_dT" => string(dT_value), 
        "PLACEHOLDER_g" => string(g_value), 
        "PLACEHOLDER_Rd" => string(Rd_value), 
        "PLACEHOLDER_Rt" => string(Rt_value), 
        "PLACEHOLDER_Ra" => string(Ra_value), 
        "PLACEHOLDER_run" => string(run_value),
        "PLACEHOLDER_outputtitle" => string(outputtitle)
    )

    # 一意のファイル名を生成して仮ファイルを作成し,パラメータを書き込む
    tempfile = "in.temp_script_$(n)"
    fp = open(tempfile, "w")
    write(fp, mod_script)
    close(fp)

    # LAMMPSを実行
    run(`mpirun -n 4 lmp_mpi -log $(outputtitle).log -in $(tempfile)`)

    # 出力ファイルを保存
    for file_ext in file_extensions
        files = glob("*.$(file_ext)")
        for file in files
            outputpath = "../outputdir/$(file_ext)dir"
            mkpath(outputpath)
            script = read(file, String)
            fp = open(joinpath(outputpath, "$(file)"), "w")

            if file_ext == "log"
                println(fp, "$(file)")
            end

            write(fp, script)
            close(fp)
            rm(file)
        end
    end
end

# 使用済みの仮LAMMPSファイルを一括削除
files = glob("in.temp_*")
for file in files
    rm(file)
end
