#=
    Example of using Julia to solve toy economic equilbirum model
    n regions, exogenous supply, linear demand and trade subject to constraints
    PLUS carryover into the next period
    Set up as an MCP and solve for equilbirum prices and net trade volumes
    PLUS solve the model many times in a loop / sequence
    !! PLUS calibrate expected prices
=#

using JuMP, PATHSolver, DataFrames, Random, Plots

# initial parameters
n = 3                               # Number of regions
β = [10.0 5.0 7.5;                  # demand function parameters (X by region)
    -0.5 -0.25 -0.25]
βc = [5.0 10.0 5.0;                 # future price function parameters (X by region)
      -2.0 -3.0 -2.0]              
tr_l = [-10e100 -2.0 -1.0;          # trade limits (min-max by region) 
        10e100 0.5 0.5]             
c_l = [0.0 0.0 0.0;                 # carryover limits (min-max by regio`n)
       0.5 0.5 0.5]                
c0 = [0, 0, 0]                      # opening carryover

function solve_market(n, β, βc, tr_l, c_l, a, t, T, results)
    
    REGIONS = 1:n
    REG_2n = 2:n                        # first region has no trade limit (i.e., end of the river)

    t0 = t * n - 2
    tn = t0 + 2
    results[t0:tn, "Time"] .= t
    c0 = results[results.Time.==t,:Carryover]                               # Opening carryover

    model = Model(PATHSolver.Optimizer, add_bridges=false)
    set_string_names_on_creation(model, false)
    set_silent(model)

    @variables(model, begin
        tr_l[1,r] <= tr[r in REGIONS]  <= tr_l[2,r], (start = 0)                     # trade 
        p[r in REGIONS] >= 0, (start = 1)                                   # prices 
        c_l[1,r] <= c[r in REGIONS] <= c_l[2,r], (start = 0)                          # carryover
    end)

    q = @expression(model, [r in REGIONS], β[1,r] + β[2,r] * p[r])                    # use
    E_p = @expression(model, [r in REGIONS], βc[1,r] + βc[2,r] * c[r])                # expected prices
    xs = @expression(model, [r in REGIONS], a[r] + c0[r]  + tr[r] - c[r] - q[r])     # excess supply
    
    @constraints(model, begin
        [r in REG_2n],  p[1] - p[r] ⟂ tr[r]                                  # equalise prices st trade constraints
        [r in REGIONS], xs[r] ⟂ p[r]                                        # demand = supply st price > 0
        [r in REGIONS], p[r] - E_p[r] ⟂ c[r]                                # current price = future price st carryover > 1
        sum(tr) ⟂ tr[1]                                                       # sum trade = 0 (use t[1] as complement)
    end)

    optimize!(model)

    #solution_summary(model; verbose=true)

    results[t0:tn, "Region"] = REGIONS 
    results[t0:tn, "Price"] = value.(p).data 
    results[t0:tn, "Trade"] = value.(tr).data
    results[t0:tn, "Supply"] = a
    results[t0:tn, "Use"] = value.(q).data
    results[t0:tn, "Excess"] = value.(xs).data
    if t < T
        results[t0+n:tn+n, "Carryover"] = value.(c).data
        results[t0+n:tn+n, "Time"] .= t + 1
    end

    return results
end

function run_sim(T, n, β, βc, tr_l, c_l)
    
    cols = ["Time", "Region", "Price", "Trade", "Supply", "Use", "Carryover", "Excess"]
    results = DataFrame(zeros(T*n, length(cols)), cols)
    
    for t in 1:T

        a = rand(3)*5                     # random allocation between 0 and 5
        
        results = solve_market(n, β, βc, tr_l, c_l, a, t, T, results)
        
    end

    return results
end

function sgd_update(results, n, T, i, βc_a)
   
    η = (1 / (1 + 0.4*i))
    
    for r in 1:n
        X = Array{Float64}(undef, T, 2) 
        X[:,1] .= 1.0
        X[:,2] .= results[results.Region.==r, :Carryover]
        Y = results[results.Region.==r, :Price]
        
        Ŷ = X * βc_a[i-1, :,r]
        ϵ = Y - Ŷ
        ΔQ = transpose(sum((ϵ .* X) ./ T, dims=1))
        
        βc_a[i, :, r] = βc_a[i-1, :, r] + η * ΔQ 
    end 

    return βc_a   
end

function calibrate_model(T, I, n, β, βc, tr_l, c_l)

    βc_a = Array{Float64}(undef, I, 2, n)
    βc_a[1, :, :] = βc

    for i in 2:I
        
        results = run_sim(T, n, β, βc_a[i-1,:,:], tr_l, c_l)
        
        βc_a = sgd_update(results, n, T, i, βc_a)
        
    end
    return βc_a
end

βc_a = calibrate_model(100, 30, n, β, βc, tr_l, c_l)

#@time βc_a = calibrate_model(100, 30, n, β, βc, tr_l, c_l)

#plot(βc_a[:, 2, 3])
