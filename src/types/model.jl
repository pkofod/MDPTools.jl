abstract type Horizon end
immutable InifiniteHorizon
end
immutable FiniteHorizon
    T
end
type DCModel{H<:Horizon}
    utilities
    states
    data
end