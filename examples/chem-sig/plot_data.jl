using Revise
using Plots
using MassConversion
using LaTeXStrings
using DifferentialEquations
pgfplotsx();

# --------- SOLV ODES ---------- #
p = [1e2, 1e3, 1e-2, 9900, 5e2, 1e2]
function f(du,u,p,t)
    a,b,c = u
    du[1] = p[5] - p[6]*a
    du[2] = p[2]*c - p[3]*b
    du[3] = p[1] - p[2]*c - p[4]*a*c
end
u0 = [5.0, 100.0, 0]
tspan = (0.0,1000.0)
prob = ODEProblem(f,u0,tspan,p)
sol = solve(prob)

# --------- LOAD DATA ---------- #

dir = "test";
ssa = load_raw(joinpath("/home/jkynaston/git/MassConversion.jl/examples/chem-sig/dat/", dir*"-ssa"));
mcm = load_raw(joinpath("/home/jkynaston/git/MassConversion.jl/examples/chem-sig/dat/", dir*"-mcm"));

ssa_full = sum(ssa);
mcm_full = sum(mcm);

p = plot(dpi=300,
        size=(400,300),
        xtickfontsize=9,
        ytickfontsize=9,
        legendfontsize=11,
        xlims=(0,200),
        ylims=(0,310),
        legend=:bottomright
    );
plot!(p, mcm_full.C[1:50:end,2]+mcm_full.D[1:50:end,2],linewidth=2,label=L"X_1");
plot!(p, ssa_full.D[1:50:end,2],lw=2,label=L"X_2");
plot!(p, sol(0:5:1000, idxs=2), lw=2,label=L"X_3")



p = plot(dpi=300);
plot(p, err_full)
plot(p, err_ssa)
plot(p, ode_err)