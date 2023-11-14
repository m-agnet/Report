# LJポテンシャル(粒子-粒子)の描画.

# パッケージ
using Plots

# パラメータ
epsilon_pair = 1.0
sigma_pair = 1.0
rc_pair = 2.5 * sigma_pair

# 階段関数の定義.
function theta(r)
    if r <= 0
        y = 0
        return y
    elseif r > 0
        y = 1
        return y
    end
end

# LJポテンシャルの定義.
function phi(r)
    if r > 0.0 
        y = 4.0 * epsilon_pair * ((sigma_pair/r)^12 - (sigma_pair/r)^6)
        return y
    elseif r >= 0.0
        y = 0
        return y
    end
end

# シフトアップを考慮したLJポテンシャルの定義.
function phi_tilde(r)
    y = (phi(r)-phi(rc_pair))*theta(rc_pair - r)
end

plot(phi_tilde, xlims=(0.75,3.1), ylims=(-2,3), label="Potential", xlabel="r", ylabel="potential", title="LJ-Potential(pair) vs. r ; (ε=1.0, σ=1.0, rc=2.5)")
# plot(phi_tilde, xlims=(0.4,1.0), ylims=(-0.1,0.8), label="Potential", xlabel="r", ylabel="potential", title="LJ-Potential vs. r ()")
