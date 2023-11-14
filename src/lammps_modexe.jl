#=
lammpsファイルの実行及び出力ファイルの保管.
- lammpsファイルを適切にパラメータ処理する必要がある.
- lammpsファイル実行時に出力される*.logファイル,*.yamlファイルが指定した同一フォルダに,それぞれのフォルダを作成して保管される.
- lammpsファイルと同一ディレクトリにある*.lammpstrjファイルは削除.
- パラメータごとにlammpsファイルを編集して繰り返し実効させる.
=#

using Glob # *を使ってパターンマッチングするためのパッケージ.
using Dates #日時を取得するパッケージ.

lammpsfile = glob("in.*")[1] # 実行ファイルを指定.
file_list = ["log", "yaml", "lammpstrj"] # 扱う出力ファイルの拡張子.
outputpath = "/Users/2023_2gou/Desktop/r_yamamoto/Research/outputdir" # 出力ディレクトリのパス.
remark_text="rain"

#= 
パラメータを指定.
各パラメータの要素数の積数回分だけlammpsが実行されるので大きくしすぎないように注意.
=#
Ay_range = range(50,length=1) # 偶数にする.
rho_range = range(0.4,length=1) # 密度.
T_range = range(0.43,length=1) # 初期温度.
dT_range = range(0.04,length=1) # 熱浴の温度の差.
g_range = range(4e-4,length=1) # 重力.
# rt_range = range(0.0,length=1) # 壁の厚み.
# ra_range = range(3.0-1.122462,length=1) # 濡れ具合.
run_range= range(1e7,length=1) # run step.

# 多重ループを用いてパラメータごとに実験を実行.
for Ay in Ay_range, 
    rho in rho_range, 
    T in T_range, 
    dT in dT_range, 
    g in g_range, 
    # rt in rt_range, 
    # ra in ra_range, 
    run_value in run_range # 変数をrunにしてしまうとjuliaのrun(``)と競合してしまう.

    template_script = read(lammpsfile, String) # lammpsファイルを読み込む.
    # パラメータ編集.
    mod_script = replace(template_script, 
    "PLACEHOLDER_Ay" => string(Ay), 
    "PLACEHOLDER_rho" => string(rho), 
    "PLACEHOLDER_T" => string(T), 
    "PLACEHOLDER_dT" => string(dT), 
    "PLACEHOLDER_g" => string(g), 
    # "PLACEHOLDER_rt" => string(rt), 
    # "PLACEHOLDER_ra" => string(ra), 
    "PLACEHOLDER_run" => string(run_value)
    )

    tempfile = "in.temp_script"  # 仮lammpsファイル.
    fp = open(tempfile, "w")  # 仮ファイルを作成して開く.
    write(fp, mod_script) # 仮ファイルにパラメータを書き込む.
    close(fp)

    n = string(now())  # 実験日時の記録.
    parameter = "Ay$(Ay)_rho$(rho)_T$(T)_dT$(dT)_g$(g)_run$(run_value)"
    run(`mpirun -n 4 lmp_mpi -log output.log -in $(tempfile)`)  # lammpsの実行.
    run(`rm $(tempfile)`)  # 仮ファイルを削除.

    # 出力ファイルの保管.
    for file in file_list

        # 読み込みに失敗したら次のループに進む.
        try
            readfile = glob("output.$(file)")[1] # 読み込みファイルを指定.
            script = read(readfile, String) # 読み込みファイルを読み込む.
            writepath = joinpath(outputpath, "$(file)dir", "$(n)_$(remark_text)$(parameter)_$(readfile)") # 書き込みファイルの絶対パス.
            fp = open(writepath, "w") # 書き込みファイルを作成して開く.

            if file == "log" # logファイルのとき.
                println(fp, "実験日時: $(n)") # 実験日時の書き込み.
                println(fp, parameter) # コピー用.
                println(fp, "備考欄: $(remark_text)") # 特別なことをした時の書き込み.
                rm(readfile)
            end

            write(fp, script) # 読み込んだテキストを書き込む.
            close(fp) # 書き込みファイルを閉じる.

            if file == "yaml" # yamlファイルのとき.
                rm(readfile)
            end

            if file == "lammpstrj" # lammpstrjファイルのとき.
                rm(readfile) # lammpstrjファイルは重いので, 移動後は削除.
            end

        catch
            
        end
    end

end
