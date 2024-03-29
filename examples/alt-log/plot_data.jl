using Revise
using Plots
using MassConversion
gr()

dir = "alter";

ssa1 = load_raw(joinpath("/home/jkynaston/git/MassConversion.jl/examples/alt-log/dat/", dir*"-ssa1"));
ssa2 = load_raw(joinpath("/home/jkynaston/git/MassConversion.jl/examples/alt-log/dat/", dir*"-ssa2"));
mcm = load_raw(joinpath("/home/jkynaston/git/MassConversion.jl/examples/alt-log/dat/", dir*"-mcm"));
ode = load_raw(joinpath("/home/jkynaston/git/MassConversion.jl/examples/alt-log/dat/", dir*"-ode"));

ssa_full = sum(ssa1);
ssa_full2 = sum(ssa2);
mcm_full = sum(mcm);
ode_full = sum(ode);

p = plot(dpi=600)
plot(p,mcm_full)

err_full = RelativeError(mcm_full, ssa_full)
err_ssa = RelativeError(ssa_full2, ssa_full)
ode_err = RelativeError(ode_full, ssa_full)

p = plot(dpi=600)
plot(p, err_full)
plot(p, err_ssa)
plot(p, ode_err)