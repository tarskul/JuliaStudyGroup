## Generation expansion planning (GEP) with transmission constraints
## The template and ideas for this model were taken from>
## https://gitlab.kuleuven.be/UCM/esim-code-examples

## Step 0: Activate environment - ensure consistency accross computers
using Pkg
Pkg.activate(@__DIR__) # @__DIR__ = directory this script is in
Pkg.instantiate() # Download and install this environments packages
Pkg.precompile() # Precompiles all packages in environemt
include(joinpath(@__DIR__, "functions.jl")); # Functions for processing input data
println("Done")

##  Step 1: input data
using CSV
using DataFrames
using TOML

# input file names and allocation from Inputs.toml
inputs = "Inputs.toml" |> TOML.parsefile

# read data
scalars = "scalars.toml" |> append_input_dir |> TOML.parsefile

# read data
df_dem     = (inputs["input_file_dem"    ] |> read_csv |> DataFrame)
df_gen     = (inputs["input_file_gen"    ] |> read_csv |> DataFrame)
df_lin     = (inputs["input_file_lines"  ] |> read_csv |> DataFrame)
df_gen_ava = (inputs["input_file_gen_ava"] |> read_csv |> DataFrame)

## Step 2: create model & pass data to model
using JuMP
using HiGHS
m = Model(optimizer_with_attributes(HiGHS.Optimizer))

# solver options
set_attribute(m,"parallel","on")
set_attribute(m,"threads",2)

# call functions to define the input data in the model
define_sets!(m,inputs,scalars)
process_time_series_data!(m,df_dem,df_gen_ava)
process_parameters!(m,scalars,df_gen,df_lin)

# clear memory
scalars    = nothing
df_dem     = nothing
df_gen     = nothing
df_lin     = nothing
df_gen_ava = nothing

## Step 3: construct your model
# Greenfield GEP - single year
function build_GEP_model!(m::Model)
    # Clear m.ext entries "variables", "expressions" and "constraints"
    m.ext[:variables] = Dict()
    m.ext[:expressions] = Dict()
    m.ext[:constraints] = Dict()

    # Extract sets
    T = m.ext[:sets][:T]
    G = m.ext[:sets][:G]
    L = m.ext[:sets][:L]
    N = m.ext[:sets][:N]      

    # Extract time series data
    pDemand = m.ext[:timeseries][:Demand]
    pGenAva = m.ext[:timeseries][:GenAva]

    # scalar parameters
    pVOLL   = m.ext[:parameters][:pVOLL]  
    pWeight = m.ext[:parameters][:pWeight]
        
    # generator parameters
    pInvCost = m.ext[:parameters][:pInvCost]
    pVarCost = m.ext[:parameters][:pVarCost]
    pUnitCap = m.ext[:parameters][:pUnitCap]
    pGenCon  = m.ext[:parameters][:pGenCon] 
    
    # line parameters
    pNodeA  = m.ext[:parameters][:pNodeA] 
    pNodeB  = m.ext[:parameters][:pNodeB] 
    pExpCap = m.ext[:parameters][:pExpCap]
    pImpCap = m.ext[:parameters][:pImpCap]

    # Create variables
    vInvCost  = m.ext[:variables][:vInvCost ] = @variable(m,          lower_bound=0,                                       base_name="vInvCost" )
    vOpeCost  = m.ext[:variables][:vOpeCost ] = @variable(m,          lower_bound=0,                                       base_name="vOpeCost" )
    #vGenInv   = m.ext[:variables][:vGenInv  ] = @variable(m,[g=G    ],lower_bound=0,                                   Int,base_name="vGenInv"  )
    vGenInv   = m.ext[:variables][:vGenInv  ] = @variable(m,[g=G    ],lower_bound=0,                                       base_name="vGenInv"  )
    vGenProd  = m.ext[:variables][:vGenProd ] = @variable(m,[g=G,t=T],lower_bound=0,                                       base_name="vGenProd" )
    vLineFlow = m.ext[:variables][:vLineFlow] = @variable(m,[l=L,t=T],lower_bound=-pImpCap[l],upper_bound=pExpCap[l],      base_name="vLineFlow")
    vLossLoad = m.ext[:variables][:vLossLoad] = @variable(m,[n=N,t=T],lower_bound=0,          upper_bound=pDemand[n,t],    base_name="vLossLoad")

    # Formulate objective
    m.ext[:objective] = @objective(m, Min,
        vInvCost + vOpeCost
    )

    # constraints
    # eInvCost
    m.ext[:constraints][:eInvCost] = @constraint(m,
        vInvCost == sum(pInvCost[g]*pUnitCap[g]*vGenInv[g] for g in G)
    )

    # eOpeCost
    m.ext[:constraints][:eOpeCost] = @constraint(m,
        vOpeCost ==( sum(pVarCost[g]*vGenProd[g,t]  for g in G, t in T)
                    +sum(pVOLL      *vLossLoad[n,t] for n in N, t in T)) * pWeight
    )

    # eNodeBal
    m.ext[:constraints][:eNodeBal] = @constraint(m, [n in N, t in T],
          sum(vGenProd[g,t]  for g in G if pGenCon[g]==n)
        + sum(vLineFlow[l,t] for l in L if pNodeB[l] ==n)
        - sum(vLineFlow[l,t] for l in L if pNodeA[l] ==n)
        + vLossLoad[n,t]
        ==
        + pDemand[n,t]
    )

    # eMaxProd
    m.ext[:constraints][:eMaxProd] = @constraint(m, [n in N, g in G, t in T ; pGenCon[g]==n],
        vGenProd[g,t]  <= get(pGenAva,(n,g,t),1.0)*pUnitCap[g]*vGenInv[g]
    )

    return m
end

# Build your model
build_GEP_model!(m)

# print lp file
f = open("gep-model.lp", "w")
print(f, m)
close(f)

## Step 4: solve
optimize!(m)

# check termination status
print(
    """

    Termination status: $(termination_status(m))

    """
)

# print some output
@show value(m.ext[:objective])

## Step 5: interpretation
using Plots
using Interact
using StatsPlots
using Statistics

# sets
T = m.ext[:sets][:T]
G = m.ext[:sets][:G]
N = m.ext[:sets][:N]

# parameters
pWeight  = m.ext[:parameters][:pWeight]
pDemand  = m.ext[:timeseries][:Demand]
pUnitCap = m.ext[:parameters][:pUnitCap]

# variables/expressions
vGenInv   = value.(m.ext[:variables][:vGenInv  ])
vGenProd  = value.(m.ext[:variables][:vGenProd ])
vLossLoad = value.(m.ext[:variables][:vLossLoad])
λ         = dual.(m.ext[:constraints][:eNodeBal])

# create arrays for plotting
λvec   = [1e3*λ[n,t]/pWeight         for n in N, t in T]
gvec   = [vGenProd[g,t]/1e3          for g in G, t in T]
dvec   = [pDemand[n,t]               for n in N, t in T]
capvec = [pUnitCap[g]*vGenInv[g]/1e3 for g in G        ]

# average electricity price price
p1a = convert_jump_container_to_df(λ)  |> plot_avg_price_per_node;
p1b = convert_jump_container_to_df(λ)  |> plot_avg_price_per_hour;

# dispatch
df_prod = convert_jump_container_to_df(vGenProd)
df_ens  = convert_jump_container_to_df(vLossLoad)

p2 = plot_tot_gen_per_hour(df_prod,df_ens,dvec);

# capacity
p3 = convert_jump_container_to_df(vGenInv) |> plot_tot_inv_per_gen;

# Combine    
plot(p1a, p1b, p2, p3, layout = (2, 2))
plot!(size=(800,800))
