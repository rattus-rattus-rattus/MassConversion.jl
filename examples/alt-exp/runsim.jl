using Revise
using MassConversion
using Base.Threads

println("Number of threads ", Threads.nthreads())

function main(is_ssa::Bool, rn::Int64)
    tf = 10.0
    dt = 5e-4
    λ = [1e0, 2e2, 1e2]
    R = [
        -1 1
        0 0
        ]
        if is_ssa
            IC = [1000, 0]
            θ = [(Inf, Inf)]
        else
            IC = [0, 1000]
            θ = [(300, 300)]
        end
        
        ts = (2.5, 7.5)
        
        function F!(dxdt, S, t, L)
            if ts[1] < t < ts[2]
                dxdt[2] = 0
            else
                dxdt[2] = -L[1] * S[2]
            end
    end
    
    function A!(a, S, t, L)
        if ts[1] < t < ts[2]
            a[1] = 0.0
            a[2] = L[2]
        else
            a[1] = L[1] * S[1]
            a[2] = 0.0
        end
    end

    return run_mcm(tf, dt, IC, λ, R, θ, F!, A!, rn)
end;

O = MassConversion.MCMOutput;
data = Vector{Tuple{O,O}}();

Threads.@threads for i = 1:4
    time = @elapsed push!(data, (main(false, 10), main(true, 10)))
    println("Repeat " * string(i) * " complete. Elapsed: " * string(time) * " seconds.")
end

#! IO CONFIG
casename = "alt-exp"
datname = "no-fractional-jumps"
scratch_save(data)