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
tr_l = [-10e100, -2.0, -1.0]          # trade lower (export) limit 
tr_u = [10e100, 0.5, 0.5]             # trade upper (import) limit
c_u = [0.5, 0.5, 0.5]                # carryover limit


function solve_market(n, β0, β1, βc0, βc1, tr_l, tr_u, c_u, a, c0, t, results)
    
    REGIONS = 1:n
    REG_2n = 2:n                        # first region has no trade limit (i.e., end of the river)

    model = Model(PATHSolver.Optimizer, add_bridges=false)
    set_string_names_on_creation(model, false)
    set_silent(model)

    @variables(model, begin
        tr_l[r] <= tr[r in REGIONS]  <= tr_u[r], (start = 0)                     # trade 
        p[r in REGIONS] >= 0, (start = 1)                                   # prices 
        0 <= c[r in REGIONS] <= c_u[r], (start = 0)                          # carryover
    end)

    q = @expression(model, [r in REGIONS], β0[r] + β1[r] * p[r])                    # use
    E_p = @expression(model, [r in REGIONS], βc0[r] + βc1[r] * c[r])                # expected prices
    xs = @expression(model, [r in REGIONS], a[r] + c0[r]  + tr[r] - c[r] - q[r])     # excess supply
    
    @constraints(model, begin
        [r in REG_2n],  p[1] - p[r] ⟂ tr[r]                                  # equalise prices st trade constraints
        [r in REGIONS], xs[r] ⟂ p[r]                                        # demand = supply st price > 0
        [r in REGIONS], p[r] - E_p[r] ⟂ c[r]                                # current price = future price st carryover > 1
        sum(tr) ⟂ tr[1]                                                       # sum trade = 0 (use t[1] as complement)
    end)

    optimize!(model)

    #solution_summary(model; verbose=true)

    t0 = t * n - 2
    tn = t0 + 2
    results[t0:tn, "Time"] .= t
    results[t0:tn, "Region"] = REGIONS 
    results[t0:tn, "Price"] = value.(p).data 
    results[t0:tn, "Trade"] = value.(tr).data
    results[t0:tn, "Supply"] = a
    results[t0:tn, "Use"] = value.(q).data
    results[t0:tn, "Carryover"] = value.(c).data
    results[t0:tn, "Excess"] = value.(xs).data
    
    return results
end

function run_sim(T, n, β0, β1, βc0, βc1, tr_l, tr_u, c_u, c0)
    
    cols = ["Time", "Region", "Price", "Trade", "Supply", "Use", "Carryover", "Excess"]
    results = DataFrame(zeros(T*n, length(cols)), cols)
    
    for t in 1:T

        a = rand(3)*5                     # random allocation between 0 and 5

        results = solve_market(n, β0, β1, βc0, βc1, tr_l, tr_u, c_u, a, c0, t, results)
        
        c0 = res_t[:, "Carryover"]               # Opening carryover t+1 = closing carryover t
        
    end

    return results
end

c0 = [0, 0, 0]              # opening carryover

results = run_sim(100, n, β0, β1, βc0, βc1, tr_l, tr_u, cu, c0)

#@profview  results = run_sim(10, n, β0, β1, βc0, βc1, tr_l, tr_u, c_u, c0)

#@profview  results = run_sim(10000, n, β0, β1, βc0, βc1, tr_l, tr_u, c_u, c0)

#@time results = run_sim(50, n, β0, β1, βc0, βc1, tr_l, tr_u, cu, c0)

#@time results = run_sim(10000, n, β0, β1, βc0, βc1, tr_l, tr_u, cu, c0)
