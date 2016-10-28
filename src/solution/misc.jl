policy(U::AbstractUtility) = U.P
policy(U::AbstractUtility, a) = U.P[a]

"""
Returns the current value function iterate.
"""
current(V::AbstractValueFunction) = V.Vᵏ⁺¹
current(EV::ExpectedValueFunction) = EV.EVᵏ⁺¹

"""
Returns the previous value function iterate.
"""
previous(V::AbstractValueFunction) = V.Vᵏ
previous(EV::ExpectedValueFunction) = EV.EVᵏ

"""
    βEV!(β, F, V)
Calculates the discounted expected value in-place. This function is used in the
bellman operator.
"""
function βEV!{T<:Real}(β::T, F, V)
    for i = 1:length(F)
        A_mul_B!(β, F[i], V.Vᵏ, zero(T), V.βEV[i])
    end
end
function βEV!{T<:Real}(β::T, F, EV::ExpectedValueFunction)
    for iA = 1:length(F)
        A_mul_B!(β, F[iA], EV.EVᵏ, zero(T), EV.βEV[iA])
    end
    mapreduce(maximum, max, EV.EVᵏ)
end

"""
    βFP!(V, β, P, F)
Calculates the discounted unconditional transition probabilities induced by P.
"""
function βFP!(V, β, P, F)
    V.βFP .= sum(β*P[a].*F[a] for a = 1:length(P))
end
function βFP!(EV::ExpectedValueFunction, P, β, F)
    for a = 1:length(F)
        EV.βFP[a] .= β*P[a].*F[a]
    end
end


"""
    P!(args...)
Updates the choice probabilities given the provided value function.
"""
P!(U, F, V) = P!(U.P, U.U, U.β, F, V)
function P!(P, U, β, F, V)
    if length(P) == 2
        P[1] .= 1./(1 + exp.(U[2] + β*(F[2]*V) - (U[1] + β*(F[1]*V))))
        P[2] .= 1 - P[1]
    else
        _maximum = maximum(V)
        denominator = sum(exp.(U[a]+ β*(F[a]*V)-_maximum) for a = 1:length(P))
        for a = 1:length(P)-1
            P[a][:] = exp.(U[a]+ β*(F[a]*V)-_maximum)./denominator
        end
        P[end][:] = 1 - sum(P[a] for a = 1:length(P)-1)
    end
end

P!(U, EV) = P!(U.P, U.U, U.β, EV)
function P!(P, U, β, EV)
    if length(P) == 2
        P[1][:] = 1./(1 + exp.(U[2] + β*EV[2] - (U[1] + β*EV[1])))
        P[2][:] = 1 - P[1]
    else
        _maximum = mapreduce(maximum, max, EV)
        denominator = sum(exp.(U[a]+β*EV[a]-_maximum) for a = 1:length(P))
        for a = 1:length(P)-1
            P[a][:] = exp.(U[a]+β*(EV[a])-_maximum)./denominator
        end
        P[end][:] = 1 - sum(P[a] for a = 1:length(P)-1)
    end
end

# These are just short-hand notation for the method above. Makes it easier to
# update U.P with a U, S, and value function.
P!{Ts<:AbstractState}(U, S::Ts, V) = P!(U, S.F, current(V))
P!{Ts<:AbstractState}(U, S::Ts, EV::ExpectedValueFunction) = P!(U, current(EV))
