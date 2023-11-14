# LJポテンシャル(壁-粒子)の描画.
# c_attractiveを変えて同時プロット.

# パッケージ
using Plots

# パラメータ
r_thickness = 0.0 # 壁の厚み
r_attractive_list = range(0.0, 2.0, step=0.2) # 引力壁について

epsilon_wall = 1.0
sigma_wall = 0.5 + r_thickness

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
        y = 4.0 * epsilon_wall * ((sigma_wall/r)^12 - (sigma_wall/r)^6)
        return y
    elseif r <= 0.0
        y = 0
        return y
    end
end

plt=plot()
for r_attractive in r_attractive_list

    rc =(1.122462 + r_attractive) * sigma_wall

    # シフトアップを考慮したLJポテンシャルの定義.
    function phi_tilde(r)
        y = (phi(r)-phi(rc))*theta(rc - r)
    end

    plot!(
    phi_tilde, xlims=(0.4,2.2), ylims=(-1.1,0.8), # normal 
    # phi_tilde, xlims=(0.5,1.5), ylims=(-0.5,1), # zoom 
    label="Potential (rc=$(round(rc, digits=4)))", xlabel="r", 
    ylabel="potential", title="LJ-Potential(wall) vs. r ; (ε=1.0, σ=0.5)")
end
plot(plt)
