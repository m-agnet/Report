# 汎用LJポテンシャル描画セル.
# パッケージ.
using Plots

# 関数定義.
function theta(r) # 階段関数.
    return r > 0 ? 1 : 0
end
function phi(epsilon, sigma, r) # LJポテンシャル.
    return 4.0 * epsilon * ((sigma/r)^12 - (sigma/r)^6)
end
function phi_tilde(r, epsilon, sigma, rc) # シフトアップとカットオフ.
    return (phi(epsilon, sigma, r) - phi(epsilon, sigma, rc)) * theta(rc - r)
end

# 粒子-粒子LJポテンシャルのパラメータ.
epsilon = 1.0
sigma = 1.0
rc = 3.0 * sigma

# Rd, Rt, Raの配列.
Rd_values = range(0.0, length=1)
Rt_values = range(0.0,0.5, length=5)
Ra_values = range(1.877, length=1)

# プロット概形.
plot(xlabel="r/σ", ylabel="ϕ/ε")
xlims!(0.2,2.5)
ylims!(-1.5,3.0)
title!("LJ-Potential vs. r")
xlabel!("r/σ")
ylabel!("ϕ/ε")

# 粒子-粒子LJポテンシャルのプロット.
plot!(r -> phi_tilde(r, epsilon, sigma, rc), label="Potential_pair; ε=$(round(epsilon,digits=1)), σ=$(round(sigma,digits=1)), rc=$(round(3.0,digits=2))σ", linestyle=:dash)

# プロットの追加.
for Rd in Rd_values, 
    Rt in Rt_values, 
    Ra in Ra_values
    # 壁-粒子LJポテンシャルのパラメータ.
    epsilon_wall = (1.0 - Rd) * epsilon
    sigma_wall = (0.5 + Rt) * sigma
    rc_wall = ((2 ^ (1 / 6)) + Ra) * sigma_wall
    # 打つ点を調整.
    x_values = range(Rt+0.3,3.0,length=10000) 
    y_values = phi_tilde.(x_values, epsilon_wall, sigma_wall, rc_wall) 
    # 壁-粒子LJポテンシャルのプロット.
    plot!(x_values, y_values, label="Potential_wall; εw=$(round(epsilon_wall,digits=1))ε, σw=$(round(sigma_wall,digits=1))σ, rcw=$(round((2^(1/6)) + Ra,digits=2))σw=$(round(((2^(1/6)) + Ra)*sigma_wall,digits=2))σ", linestyle=:dash)
end

display(plot!())
# savefig("")

ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
read(stdin, 1)
