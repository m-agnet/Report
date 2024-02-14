#===
# 出力ファイル保管

このJuliaコードは,LAMMPS分子動力学シミュレーションの実行によって生成された出力ファイルを,適切なディレクトリに保存します.

## 機能

- `Glob`パッケージを使用してファイルマッチングを行う.
- パラメータごとにLAMMPSを実行したことによって生成された出力ファイルを,指定のディレクトリに移動.
- 使用済みの仮LAMMPSファイルを一括削除.

## 手順

1. 出力ファイルを指定ディレクトリに保存.
2. 使用済みの仮LAMMPSファイルを削除.

このコードは,出力ファイルの整理と保管を行います.
===#

using Glob # *を使ってパターンマッチングするためのパッケージ. 

file_extensions = ["log", "yaml", "lammpstrj"] # 出力ファイルの拡張子

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
    
# 使用済みの仮LAMMPSファイルを一括削除
files = glob("in.temp_*")
for file in files
    rm(file)
end
