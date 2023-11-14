# LJポテンシャル(壁-粒子)の描画.

# パッケージ
using Plots

# パラメータ
r_thickness = 0.0 # 壁の厚み
r_attractive = 0.0 # 引力壁

epsilon = 1.0
sigma = 0.5 + r_thickness
rc = 1.122462 * sigma + r_attractive

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
    if r > 0.0 # 0 < r < rc_pair.
        y = 4.0 * epsilon * ((sigma/r)^12 - (sigma/r)^6)
        return y
    elseif r >= 0.0 # r >= 0 , rc_pair =< r.
        y = 0
        return y
    end
end

# シフトアップを考慮したLJポテンシャルの定義.
function phi_tilde(r)
    y = (phi(r)-phi(rc))*theta(rc - r)
end

# plot(phi_tilde, xlims=(0.75,3.1), ylims=(-2,3), label="Potential", xlabel="r", ylabel="potential", title="LJ-Potential vs. r ()")
plot(phi_tilde, xlims=(0.4,1.0), ylims=(-0.1,0.8), label="Potential", xlabel="r", ylabel="potential", title="LJ-Potential(wall) vs. r ; (ε=1.0, σ=0.5, rc=1.12...)")
