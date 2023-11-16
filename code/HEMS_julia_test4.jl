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
n = 3
REGIONS = Set{String}(["A", "B", "C"])                               # Number of regions
β = Dict("A" => [10.0, -2.0],
         "B" => [5.0, 3.0],
         "C" => [7.5,-2.0] 
         )
βc = Dict("A" => [5.0, -2.0],
         "B" => [10.0, -3.0],
         "C" => [5.0,-2.0] 
         )



tr_l = Dict("A" => [-10e100, 10e100],
         "B" => [-2.0, 0.5],
         "C" => [-1.0, 0.5] 
         )
c_l = Dict("A" => [0.0, 2.0],
         "B" => [0.0, 0.5],
         "C" => [0.0, 2.0] 
         )
         
dat = Dict("c0" => Dict("A" => 0.0,
                         "B" => 0.0,
                         "C" => 0.0 
                        ),
            "a" => Dict("A" => 2.0,
                        "B" => 3.0,
                        "C" => 2.0 
                       ),
            "p" => Dict("A" => 2.0,
                        "B" => 3.0,
                        "C" => 2.0 
                        )
            )
         #=
β = [10.0 5.0 7.5;                  # demand function parameters (X by region)
    -0.5 -0.25 -0.25]
βc = [5.0 10.0 5.0;                 # future price function parameters (X by region)
      -2.0 -3.0 -2.0]              
tr_l = [-10e100 -2.0 -1.0;          # trade limits (min-max by region) 
        10e100 0.5 0.5]             
c_l = [0.0 0.0 0.0;                 # carryover limits (min-max by region)
       2.0 0.5 2.0]                
c0 = [0, 0, 0]                      # opening carryover
=#

# Demand functions
function f_q(β, p)

    return β[1] .+ β[2] .* p

end
# Welfare (profit) function
function f_π(β, q)

    return (1 / 2β[2]) .* (q.^2)  - β[1]/β[2] .* q

end
# Expected prices function
#function f_Ep(β, q)

#    return (1 / 2β[2]) .* (q.^2)  - β[1]/β[2] .* q

#end

function solve_market(n, β, βc, tr_l, c_l, dat)
    
    REGIONS = Set{String}(["A", "B", "C"])                               # Number of regions
    REG_2n = Set{String}(["B", "C"])                                     # first region has no trade limit (i.e., end of the river)

    #t0 = t * n - 2
    #tn = t0 + 2
    #res[t0:tn, "Time"] .= t
    c0 = dat["c0"] #$res[res.Time.==t,:Carryover]                               # Opening carryover
    a = dat["a"] #$res[res.Time.==t,:Carryover]                               # Opening carryover
    
   

    model = Model(PATHSolver.Optimizer, add_bridges=false)
    set_string_names_on_creation(model, false)
    set_silent(model)

    @variables(model, begin
        tr_l[r][1] <= tr[r in REGIONS]  <= tr_l[r][2], (start = 0)                     # trade 
        p[r in REGIONS] >= 0, (start = data["p"][r])                                   # prices 
        c_l[r][1] <= c[r in REGIONS] <= c_l[r][2], (start = data["c"][r])                          # carryover
    end)

    q = @expression(model, [r in REGIONS], f_q(β[r], p[r])  )                      # use β[1, r]  + β[2,r] * p[r] 
    dgirls007!
    E_p = @expression(model, [r in REGIONS], βc[r][1] + βc[r][2] * c[r])                # expected prices
    xs = @expression(model, [r in REGIONS], a[r] + c0[r]  + tr[r] - c[r] - q[r])      # excess supply
    
    @constraints(model, begin
        [r in REG_2n],  p["A"] - p[r] ⟂ tr[r]                                 # equalise prices st trade constraints
        [r in REGIONS], xs[r] ⟂ p[r]                                        # demand = supply st price > 0
        [r in REGIONS], p[r] - E_p[r] ⟂ c[r]                                # current price = future price st carryover > 1
        sum(tr) ⟂ tr["A"]                                                     # sum trade = 0 (use t[1] as complement)
    end)

    optimize!(model)
    
    dat["p"] = value.(p).data
    dat["c0"] = value.(c).data
    
    #=
    #solution_summary(model; verbose=true)
    res[t0:tn, "Region"] = REGIONS 
    res[t0:tn, "Price"] = value.(p).data 
    res[t0:tn, "Trade"] = value.(tr).data
    res[t0:tn, "Supply"] = a
    res[t0:tn, "Use"] = value.(q).data
    res[t0:tn, "Excess"] = value.(xs).data
    if t < T
        res[t0+n:tn+n, "Carryover"] = value.(c).data
        res[t0+n:tn+n, "Time"] .= t + 1
    end 
    =#
    return data
end

function run_sim(t0, T, n, β, βc, tr_l, c_l, data, REGIONS)
    
    for t in t0:(T + t0 - 1)

        for r in REGIONS
            data["a"][r] = rand()*5                     # random allocation between 0 and 5
        end

        data = solve_market(n, β, βc, tr_l, c_l, data)
        
    end

    #for r in 1:n
    #    res[res.Region.==r, :Welfare] = f_π(β[:,r], res[res.Region.==r, :Use])
    #end

    return data #res

end

function sgd_update(res, n, T, i, βc_a)
   
    η = 0.05 #0.4*(1 / (1 + 0.3*i))
    
    for r in 1:n
        X = Array{Float64}(undef, T, 2) 
        X[:,1] .= 1.0
        X[:,2] .= res[res.Region.==r, :Carryover]
        Y = res[res.Region.==r, :Price]
        
        Ŷ = X * βc_a[i-1, :,r]
        ϵ = Y - Ŷ
        ΔQ = transpose(sum((ϵ .* X) ./ T, dims=1))
        
        βc_a[i, :, r] = βc_a[i-1, :, r] + η * ΔQ 
    end 

    return βc_a   
end

function calibrate_model(T, I, n, β, βc, tr_l, c_l, g=0.05)

    βc_a = Array{Float64}(undef, I, 2, n)
    βc_a[1, :, :] = βc
    t0 = 1 
    T = 100
    maxrows = Int(floor((100 * (1 + g)^(I-1)) * n + n))
    
    cols = ["Time", "Region", "Price", "Trade", "Supply", "Use", "Carryover", "Excess", "Welfare"]
    res = DataFrame(zeros(maxrows*n, length(cols)), cols)

    for i in 2:I
        
        res = run_sim(t0, T, n, β, βc_a[i-1,:,:], tr_l, c_l, res)
        
        βc_a = sgd_update(res[1:(T*n), :], n, T, i, βc_a)

        t0 = Int(t0 + floor(g * T))
        T = T + t0 - 1
    end
    return βc_a
end

#βc_a = calibrate_model(100, 50, n, β, βc, tr_l, c_l, 0.05)

#cols = ["Time", "Region", "Price", "Trade", "Supply", "Use", "Carryover", "Excess", "Welfare"]
#res = DataFrame(zeros(100*n+n, length(cols)), cols)

#@time βc_a = calibrate_model(100, 30, n, β, βc, tr_l, c_l)
@time data =run_sim(1, 100, n, β, βc, tr_l, c_l, dat)
#@time res = run_sim(1, 100, n, β, βc, tr_l, c_l, res)

#plot(βc_a[:, 2, 3])

@profview data =run_sim(1, 100, n, β, βc, tr_l, c_l, dat)