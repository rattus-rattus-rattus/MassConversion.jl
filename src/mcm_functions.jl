"""
    sample_dist(a::Union{AbstractArray{T}, Tuple{Vararg{T}}}, a₀::T) where T <: Real

Samples from an unnormalised discrete distribution.

### Arguments
- `a`: Array/Tuple of weights
- `a₀`: Sum of weights
"""
function sample_dist(a::Union{AbstractArray{T},Tuple{Vararg{T}}}, a₀::T) where {T<:Real}

    i = 1
    cumsum = a[1]
    r = rand()

    while cumsum < r * a₀
        i += 1
        cumsum += a[i]
    end

    return i
end

"""
    run_mcm(tf, dt, IC, λ, R, F!, A!, rn)

Run the mass-conversion method.

### Arguments
- `tf` : Simulation run time
- `dt` : Time step
- `IC` : Vector containing initial condition
- `λ` : Vector containing rate parameters. The last K parameters, where K is the number of species, is assumed to be the regime transition rate.
- `R` : Stoichiometric matrix representing all non-transitional reactions
- `θ` : Vector containing tuples representing the lower and upper thresholds, respectively
- `F!` : Function for computing dxdt for the forward Euler method
- `A!` : Function for computing propensity functions for all non-transitional reactions
- `rn` : Number of repeats
"""
function run_mcm(tf, dt, IC::Vector{T}, λ::Vector{Float64}, R::Matrix, θ::Vector{Tuple}, F!::Function, A!::Function, rn::Int64) where T <: Real

    # Match type
    IC = Vector{Float64}(IC)

    # Get timesteps etc
    tn = floor(Int64, tf / dt) + 1
    Kn = floor(Int64, length(IC)/2) # Number of unique species
    Rn = size(R, 2) # Number of non-transitional reactions

    # Preallocation
    rec = zeros(2 * Kn, tn, rn)
    state = similar(IC)
    α = zeros(Rn + 2 * Kn)
    dxdt = zeros(2 * Kn)

    for ri ∈ 1:rn
        # Initial conditions
        t = 0.0
        td = dt
        state .= IC
        ti = 1
        rec[:, ti, ri] .= state

        while t < tf
            # Update propensity functions
            A!(α, state, t, λ)
            α₀ = sum(α)

            # Time to next reaction
            τ = log(1 / rand()) / α₀

            if t + τ < td
                # Execute stochastic event
                t += τ
                reaci = sample_dist(α, α₀)
                R!(state, reaci)
            else
                # Execute ODE update
                F!(dxdt, state, t, λ)
                @. state += dt * dxdt

                # Record
                ti += 1
                rec[:, ti, ri] .= state
                t = (ti - 1) * dt
                td = ti * dt
            end
        end

        # Final record
        rec[:, end, ri] .= state
    end

    # Create dictionary for storing parameter values
    dict = Dict("tf" => tf, "dt" => dt, "IC" => IC, "λ" => λ, "rn" => rn)

    return MCMOutput(rec, dict)
end

"""
    record_state!()
"""
function record_state!(rec::Array, t::Float64, tn::Int64, tp::Array{Int64}, Δt::Float64, state::Array, repi::Int64)
    if t > tp[1] * Δt
        _tc::Int64 = min(tn, floor(t / Δt) + 1)
        for i ∈ 1:length(state)
            for j ∈ tp[1]:_tc
                rec[i, j, repi] += state[i]
            end
        end
        tp .= _tc + 1
    end
    nothing
end

"""
    run_ssa(tf, dt, IC, λ, R, A!, rn)
"""
function run_ssa(tf, dt, IC::Vector{T}, λ::Vector{Float64}, R::Matrix, A!::Function, rn::Int64) where {T<:Real}

    # Get timesteps etc
    tn = floor(Int64, tf / dt) + 1
    K = length(IC)

    # Preallocation
    rec = zeros(K, tn, rn)
    state = similar(IC)
    α = zeros(size(R, 2))
    dxdt = zeros(K)
    reac_count = zeros(Int64, size(R, 2))

    for ri ∈ 1:rn
        # Initial conditions
        t = 0.0
        tp = [1]
        state .= IC

        while t < tf
            # Update propensity functions
            A!(α, state, λ)
            α₀ = sum(α)

            # Time to next reaction
            τ = log(1 / rand()) / α₀

            # Execute stochastic event
            t += τ
            reaci = sample_dist(α, α₀)
            for i ∈ 1:K state[i] += R[i, reaci] end
            reac_count[reaci] += 1
             
            # Record
            record_state!(rec, t, tn, tp, dt, state, ri)
        end

        # Final record
        rec[:, end, ri] .= state
    end

    return SSAOutput(rec, reac_count) 
end