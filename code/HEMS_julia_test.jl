#=
    Example of using Julia to solve toy economic MCP
    n regions, exogenous supply A, linear demand and trade subject to constraints
    Set up as MCP and solve for equilbirum prices and net trade volumes
=#

using JuMP, PATHSolver, DataFrames

n = 3
REGIONS = 1:n
REG_2n = 2:n                        # first region has no trade limit (i.e., end of the river)
β_0 = [10.0, 5.0, 7.5]              # demand function constant
β_1 = [-0.5, -0.25, -0.25]          # demand function slope
t_min = [-10e100, -2.0, -1.0]       # trade lower (export) limit 
t_max = [10e100, 0.5, 0.5]          # trade upper (import) limit
A = [0.0, 6.0, 3.0]                 # initial supply (allocation)

model = Model(PATHSolver.Optimizer)

@variables(model, begin
    t_min[r] <= t[r in REGIONS]  <= t_max[r], (start = 0)               # trade constraints
    p[r in REGIONS] >= 0, (start = 1)                                   # prices must be positive
end)

@constraints(model, begin
    [r in REG_2n], p[1] - p[r] ⟂ t[r]                                   # equalise prices st trade constraints
    [r in REGIONS], A[r] + t[r] - (β_0[r] + β_1[r] * p[r])  ⟂ p[r]      # demand = supply st price > 0
    sum(t) ⟂ t[1]                                                       # sum trade = 0 (use t[1] as complement)
end)

optimize!(model)

solution_summary(model; verbose=true)

# print the results

p = value.(p)
t = value.(t)
q = β_0 + β_1.*p 
xs = A + t - q

p = p.data; t=t.data; q=q.data; xs=xs.data; 

result = DataFrame("Region"=>REGIONS, "Price"=>p, "Trade"=>t, "Use"=>q, "Supply"=>A, "Excess supply"=>xs)

print(result)