#=
    Example of using Julia to solve toy economic equilbirum model
    n regions, exogenous supply, linear demand and trade subject to constraints
    PLUS carryover into the next period
    Set up as an MCP and solve for equilbirum prices and net trade volumes
=#

using JuMP, PATHSolver, DataFrames

n = 3
REGIONS = 1:n
REG_2n = 2:n                        # first region has no trade limit (i.e., end of the river)
β0 = [10.0, 5.0, 7.5]               # demand function constant
β1 = [-0.5, -0.25, -0.25]           # demand function slope
βc0 = [0.0, 10.0, 0.0]              # future price function constant
βc1 = [0.0, -5.0, 0.0]              # future price function slope
t_min = [-10e100, -2.0, -1.0]       # trade lower (export) limit 
t_max = [10e100, 0.5, 0.5]          # trade upper (import) limit
c_max = [0.5, 0.5, 0.5]             # carryover limit
A = [0.0, 6.0, 3.0]                 # initial supply (allocation)

model = Model(PATHSolver.Optimizer)

@variables(model, begin
    t_min[r] <= t[r in REGIONS]  <= t_max[r], (start = 0)               # trade 
    p[r in REGIONS] >= 0, (start = 5)                                   # prices 
    0 <= c[r in REGIONS] <= c_max[r], (start = 0)                       # carryover
end)

q = @expression(model, [r in REGIONS], β0[r] + β1[r] * p[r])            # use
E_p = @expression(model, [r in REGIONS], βc0[r] + βc1[r] * c[r])        # expected prices

@constraints(model, begin
    [r in REG_2n], p[1] - p[r] ⟂ t[r]                                   # equalise prices st trade constraints
    [r in REGIONS], A[r] + t[r] - c[r] - q[r] ⟂ p[r]                    # demand = supply st price > 0
    [r in REGIONS], p[r] - E_p[r] ⟂ c[r]                                # current price = future price st carryover > 1
    sum(t) ⟂ t[1]                                                       # sum trade = 0 (use t[1] as complement)
end)

optimize!(model)

solution_summary(model; verbose=true)

# print the results

p = value.(p)
t = value.(t)
c = value.(c)
q = β0 + β1.*p 
xs = A + t - q - c

p = p.data; t=t.data; q=q.data; xs=xs.data; c=c.data;

result = DataFrame("Region"=>REGIONS, "Price"=>p, "Trade"=>t,  "Supply"=>A, "Use"=>q, "Carryover"=>c, "Excess supply"=>xs)

print(result)