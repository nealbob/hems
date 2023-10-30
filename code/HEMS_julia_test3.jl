#=
    Example of using Julia to solve toy economic equilbirum model
    n regions, exogenous supply, linear demand and trade subject to constraints
    PLUS carryover into the next period
    Set up as an MCP and solve for equilbirum prices and net trade volumes
    PLUS solve the model many times in a loop / sequence
=#

using JuMP, PATHSolver, DataFrames, Random

# set parameters
n = 3
β0 = [10.0, 5.0, 7.5]               # demand function constant
β1 = [-0.5, -0.25, -0.25]           # demand function slope
βc0 = [0.0, 10.0, 0.0]              # future price function constant
βc1 = [0.0, -5.0, 0.0]              # future price function slope
tl = [-10e100, -2.0, -1.0]          # trade lower (export) limit 
tu = [10e100, 0.5, 0.5]             # trade upper (import) limit
cu = [0.5, 0.5, 0.5]                # carryover limit

function solve_market(n, β0, β1, βc0, βc1, tl, tu, cu, a, c0)
    
    REGIONS = 1:n
    REG_2n = 2:n                        # first region has no trade limit (i.e., end of the river)

    model = Model(PATHSolver.Optimizer)

    set_silent(model)

    @variables(model, begin
        tl[r] <= t[r in REGIONS]  <= tu[r], (start = 0)                     # trade 
        p[r in REGIONS] >= 0, (start = 5)                                   # prices 
        0 <= c[r in REGIONS] <= cu[r], (start = 0)                          # carryover
    end)

    q = @expression(model, [r in REGIONS], β0[r] + β1[r] * p[r])                    # use
    E_p = @expression(model, [r in REGIONS], βc0[r] + βc1[r] * c[r])                # expected prices
    xs = @expression(model, [r in REGIONS], a[r] + c0[r]  + t[r] - c[r] - q[r])     # excess supply
    
    @constraints(model, begin
        [r in REG_2n],  p[1] - p[r] ⟂ t[r]                                  # equalise prices st trade constraints
        [r in REGIONS], xs[r] ⟂ p[r]                                        # demand = supply st price > 0
        [r in REGIONS], p[r] - E_p[r] ⟂ c[r]                                # current price = future price st carryover > 1
        sum(t) ⟂ t[1]                                                       # sum trade = 0 (use t[1] as complement)
    end)

    optimize!(model)

    result = DataFrame("Region"=>REGIONS, 
                   "Price"=>value.(p).data, 
                   "Trade"=>value.(t).data,
                   "Supply"=>a,
                   "Use"=>value.(q).data,
                   "Carryover"=>value.(c).data,
                   "Excess supply"=>value.(xs).data
                   )
    
    return result
end

function run_sim(T, n, β0, β1, βc0, βc1, tl, tu, cu, c0)
    
    results = DataFrame()
    
    for t in 1:T

        a = rand(3)*5                     # random allocation between 0 and 5

        res_t = solve_market(n, β0, β1, βc0, βc1, tl, tu, cu, a, c0)
        
        c0 = res_t.Carryover               # Opening carryover t+1 = closing carryover t
        res_t[!, :Time] .= t
        results = vcat(results, res_t)     # Store results for period t

    end

    return results
end

c0 = [0, 0, 0]              # opening carryover

@time begin
    results = run_sim(500, n, β0, β1, βc0, βc1, tl, tu, cu, c0)
end