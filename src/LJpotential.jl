# LJポテンシャル描画セル.
# パッケージ.
using Plots

# 関数.
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
Rd_values = range(0.0,length=1)
Rt_values = range(0.5,length=1)
Ra_values = range(0.0,3.0-2^(1/6),length=3)

# プロット設定.
plt=plot(xlims=(0.5, 2.0), ylims=(-1.5, 3.5), xlabel="r/σ", ylabel="ϕ/ε", title="LJ-Potential vs. r", show=true)
plot!(r -> phi_tilde(r, epsilon, sigma, rc), label="Potential", linestyle=:dash)
for Rd in Rd_values, 
    Rt in Rt_values, 
    Ra in Ra_values
    # 壁-粒子LJポテンシャルのパラメータ.
    epsilon_wall = (1.0 - Rd) * epsilon
    sigma_wall = (0.5 + Rt) * sigma
    rc_wall = ((2^(1/6)) + Ra) * sigma_wall
    plot!(r -> phi_tilde(r, epsilon_wall, sigma_wall, rc_wall), label="Potential_wall; Rd=$(Rd), Rt=$(Rt), Ra=$(round(Ra,digits=1))", linestyle=:dash)
end
display(plt)

ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
read(stdin, 1)
