module KKT

using LinearAlgebra

import ..Tulip.Factory

export AbstractKKTSolver, KKTOptions

"""
    AbstractKKTSolver{T}

Abstract container for solving an augmented system
```
    [-(Θ⁻¹ + Rp)   Aᵀ] [dx] = [ξd]
    [   A          Rd] [dy]   [ξp]
```
where `ξd` and `ξp` are given right-hand side.
"""
abstract type AbstractKKTSolver{T} end

"""
    KKTOptions{T}

KKT solver options.
"""
Base.@kwdef mutable struct KKTOptions{T}
    Factory::Factory{<:AbstractKKTSolver} = default_factory(T)
end


"""
    setup(T::Type{<:AbstractKKTSolver}, args...; kwargs...)

Instantiate a KKT solver object.
"""
function setup(Ts::Type{<:AbstractKKTSolver}, args...; kwargs...)
    return Ts(args...; kwargs...)
end

# 
# Specialized implementations should extend the functions below
# 

"""
    update!(kkt, θinv, regP, regD)

Update internal data and factorization/pre-conditioner.

After this call, `kkt` can be used to solve the augmented system
```
    [-(Θ⁻¹ + Rp)   Aᵀ] [dx] = [ξd]
    [   A          Rd] [dy]   [ξp]
```
for given right-hand sides `ξd` and `ξp`.

# Arguments
* `kkt::AbstractKKTSolver{T}`: the KKT solver object
* `θinv::AbstractVector{T}`: ``θ⁻¹``
* `regP::AbstractVector{T}`: primal regularizations
* `regD::AbstractVector{T}`: dual regularizations
"""
function update! end


"""
    solve!(dx, dy, kkt, ξp, ξd)

Solve the symmetric quasi-definite augmented system
```
    [-(Θ⁻¹ + Rp)   Aᵀ] [dx] = [ξd]
    [   A          Rd] [dy]   [ξp]
```
and over-write `dx`, `dy` with the result.

# Arguments
- `dx, dy`: Vectors of unknowns, modified in-place
- `kkt`: Linear solver for the augmented system
- `ξp, ξd`: Right-hand-side vectors
"""
function solve! end

"""
    arithmetic(kkt::AbstractKKTSolver)

Return the arithmetic used by the solver.
"""
arithmetic(kkt::AbstractKKTSolver{T}) where T = T

"""
    backend(kkt)

Return the name of the solver's backend.
"""
backend(::AbstractKKTSolver) = "Unkown"

"""
    linear_system(kkt)

Return which system is solved by the kkt solver.
"""
linear_system(::AbstractKKTSolver) = "Unkown"

# Generic tests
include("test.jl")

# Custom linear solvers
include("lapack.jl")
include("cholmod.jl")
include("ldlfact.jl")
include("krylov.jl")

"""
    default_factory(T)

Use CHOLMOD for `Float64` and LDLFactorizations otherwise.
"""
function default_factory(::Type{T}) where{T}
    if T == Float64
        return Factory(CholmodSolver; normal_equations=false)
    else
        return Factory(LDLFactSQD)
    end
end

end  # module