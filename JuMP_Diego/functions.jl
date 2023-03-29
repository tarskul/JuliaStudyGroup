using JuMP, HiGHS, DataFrames, Chain, DataFramesMeta, StatsPlots, Plots
function append_input_dir(file_name)
    return joinpath(".",parameters_file["inputs_dir"], file_name)
end

function read_csv(file_name)
    return file_name |> append_input_dir |> CSV.File
end

function define_sets!(m::Model, parameters_file::Dict,scalars::Dict)
    # create dictionary to store sets
    m.ext[:sets] = Dict()

    m.ext[:sets][:T] = 1:scalars["time_steps"]
    m.ext[:sets][:G] = (parameters_file["input_file_set_g"] |> read_csv |> DataFrame).generators
    m.ext[:sets][:L] = (parameters_file["input_file_set_l"] |> read_csv |> DataFrame).lines
    m.ext[:sets][:N] = (parameters_file["input_file_set_n"] |> read_csv |> DataFrame).nodes

    return m
end

function process_time_series_data!(m::Model, df_dem::DataFrame, df_gen_ava::DataFrame)

    # create dictionary to store time series
    m.ext[:timeseries] = Dict()

    # add time series to dictionary
    m.ext[:timeseries][:Demand] = Dict(Pair.(zip(df_dem.Node    ,                     df_dem.Time    ),df_dem.Demand_MW          ))
    m.ext[:timeseries][:GenAva] = Dict(Pair.(zip(df_gen_ava.Node,df_gen_ava.Generator,df_gen_ava.Time),df_gen_ava.Availability_pu))

    return m
end

function process_parameters!(m::Model, parameters_file::Dict, scalars::Dict,df_gen::DataFrame,df_lin::DataFrame)

    # generate a dictonary "parameters"
    m.ext[:parameters] = Dict()

    # input parameters
    m.ext[:parameters][:pVOLL]     = scalars["value_of_lost_load"]
    m.ext[:parameters][:pWeight]   = 8760/scalars["time_steps"]
    m.ext[:parameters][:pCO2Tech]  = parameters_file["tech_to_apply_CO2_cost"]
    m.ext[:parameters][:pCO2Cost]  = parameters_file["CO2_price_kEUR_t_mean"]
    
    # generators input data
    m.ext[:parameters][:pInvCost] = Dict(zip(df_gen.Generator,df_gen.InvCost_kEUR_MW_year))
    m.ext[:parameters][:pVarCost] = Dict(zip(df_gen.Generator,df_gen.VarCost_kEUR_per_MWh))
    m.ext[:parameters][:pUnitCap] = Dict(zip(df_gen.Generator,df_gen.UnitCap_MW          ))
    m.ext[:parameters][:pGenCon ] = Dict(zip(df_gen.Generator,df_gen.Node                ))
    m.ext[:parameters][:pEmisFac] = Dict(zip(df_gen.Generator,df_gen.EmisFac_tCO2_per_MWh))
    m.ext[:parameters][:pGenTech] = Dict(zip(df_gen.Generator,df_gen.Technology          ))

    # lines input data
    m.ext[:parameters][:pNodeA]  = Dict(zip(df_lin.Line,df_lin.Node_from))
    m.ext[:parameters][:pNodeB]  = Dict(zip(df_lin.Line,df_lin.Node_to  ))
    m.ext[:parameters][:pExpCap] = Dict(zip(df_lin.Line,df_lin.ExpCap_MW))
    m.ext[:parameters][:pImpCap] = Dict(zip(df_lin.Line,df_lin.ImpCap_MW))

    return m
end


function run_mc_sim(m::Model, parameters_file::Dict,CO2_samples::Vector,RES_avai_samples::Dict)

    # outputs    
    df_inv_mc = DataFrame()
    df_mc_summary = DataFrame()

    # main monte carlo loop
    for i in 1:parameters_file["iterations"]

        # 
        RES_avai = Dict(k => RES_avai_samples[k][i] for k in keys(RES_avai_samples))

        # Build your model
        build_GEP_model!(m,CO2_samples[i],RES_avai)

        ## Step 4: solve
        optimize!(m)

        # check termination status
        print(
            """

            Iteration: $i Termination status: $(termination_status(m))

            """
        )

        # print some output
        @show value(m.ext[:objective])

        # save a summary in a df
        df_summary_iter = DataFrame(
            iteration    =[i],
            CO2_price    =[CO2_samples[i]],
            status       =[termination_status(m)],
            status_primal=[primal_status(m)],
            status_dual  =[dual_status(m)],
            objective    =[objective_value(m)]
        )
        df_mc_summary = vcat(df_mc_summary,df_summary_iter)

        # save the investment at each iteration
        df_inv_iter = convert_jump_container_to_df(value.(m.ext[:variables][:vGenInv]),dim_names=[:Generation],value_col=:Investment)
        # add information for each iteration
        df_inv_iter[!,"Iteration"] .= i
        df_inv_iter[!,"CO2 Price"] .= CO2_samples[i]
        # save the information
        df_inv_mc = vcat(df_inv_mc,df_inv_iter)

        # clear the auxiliary dfs
        df_inv_iter     = nothing
        df_summary_iter = nothing
    end

    # print lp file
    f = open("gep-model.lp", "w")
    print(f, m)
    close(f)    

    return df_mc_summary, df_inv_mc
end


"""
Returns a `DataFrame` with the values of the variables from the JuMP container `var`.
The column names of the `DataFrame` can be specified for the indexing columns in `dim_names`,
and the name of the data value column by a Symbol `value_col` e.g. :Value
function from: https://discourse.julialang.org/t/extracting-jump-results/51429/6
"""
function convert_jump_container_to_df(var::JuMP.Containers.DenseAxisArray;
    dim_names::Vector{Symbol}=Vector{Symbol}(),
    value_col::Symbol=:Value)

    if isempty(var)
        return DataFrame()
    end

    if length(dim_names) == 0
        dim_names = [Symbol("dim$i") for i in 1:length(var.axes)]
    end

    if length(dim_names) != length(var.axes)
        throw(ArgumentError("Length of given name list does not fit the number of variable dimensions"))
    end

    tup_dim = (dim_names...,)

    # With a product over all axis sets of size M, form an Mx1 Array of all indices to the JuMP container `var`
    ind = reshape([collect(k[i] for i in 1:length(dim_names)) for k in Base.Iterators.product(var.axes...)],:,1)

    var_val  = value.(var)

    df = DataFrame([merge(NamedTuple{tup_dim}(ind[i]), NamedTuple{(value_col,)}(var_val[(ind[i]...,)...])) for i in 1:length(ind)])

    return df
end

function plot_avg_price_per_node(df_::DataFrame)

    df =(@chain df_ begin
            groupby(:Node)
            combine(:Price => mean  => :Avg_price)
            sort(:Avg_price,rev=true)
        end)
    
    p = plot(df.Node,
             df.Avg_price*1e3/pWeight,
             xlabel="Node [-]", 
             ylabel="Average λ [EUR/MWh]",
             legend=false
            )

    return p
end

function plot_marginalkde(x::Vector,
                          y::Vector;
                          x_label="CO2 price [€/t]",
                          y_label="Total Cost [MEUR]",
                          HasLegend=false)
    p = marginalkde(x,
                    y,
                    xlabel=x_label, 
                    ylabel=y_label,
                    legend=HasLegend
                    )
    return p
end

function plot_investment_dist(df_::DataFrame,dict::Dict)

    df_cap = DataFrame("Generation" => collect(keys(dict)),
                       "pUnitCap"   => collect(values(dict))
                      )
    
    df = innerjoin(df_,df_cap,on=:Generation)    

    @transform!(df, :Generation = categorical(:Generation))

    p = violin(string.(df.Generation), df.Investment .* df.pUnitCap, linewidth=0)

    boxplot!(string.(df.Generation), df.Investment .* df.pUnitCap , fillalpha=0.75, linewidth=2)
    dotplot!(string.(df.Generation), df.Investment .* df.pUnitCap , marker=(:black, stroke(0)),
             xlabel="Technology [-]", ylabel="Investment [MW]", legend=false)

    return p
end

function plot_corr(df_::DataFrame)
    df = unstack(df_,:Generation,:Investment)
    ncols = ncol(df)
    p = @df df corrplot(cols(2:ncols), grid = false)
    return p
end

function plot_avg_price_per_hour(df_::DataFrame)

    df =(@chain df_ begin
            groupby(:Time)
            combine(:Price => mean  => :Avg_price)
        end)
    
    p = plot(df.Time,
             df.Avg_price*1e3/pWeight,
             xlabel="Timesteps [-]", 
             ylabel="Average λ [EUR/MWh]",
             legend=false
             )

    return p
end

function plot_tot_gen_per_hour(df_prod_::DataFrame,df_ens_::DataFrame,dem::Matrix)
   
    df_prod = unstack(df_prod_, :Time, :Generation, :Production)

    df_ens =(@chain df_ens_ begin
                groupby(:Time)
                combine(:ENS => sum => :ENS)
            end)

    # create the grouped bar plot
    p=groupedbar(df_prod.Time,
                 hcat(df_prod.OCGT, df_prod.CCGT, df_prod.WIND, df_prod.SOLAR, df_ens.ENS),
                 bar_position = :stack,
                 label=["OCGT" "CCGT" "WIND" "SOLAR" "ENS"],                 
                )

    plot!(p, T, sum(dem,dims=1)',
          linewidth=3,
          lc=:black,
          xlabel="Timesteps [-]", 
          ylabel="Production [MWh]",
          label="DEM",
          legend=:outertopright
         );
                
    return p
end

function plot_tot_inv_per_gen(df_::DataFrame,dict::Dict)
    
    df_cap = DataFrame("Generation" => collect(keys(dict)),
                       "pUnitCap"   => collect(values(dict))
                      )
    
    df = innerjoin(df_,df_cap,on=:Generation)

    p = bar(df.Generation,
            df.Investment .* df.pUnitCap /1e3,
            xlabel="Generation [-]", 
            ylabel="Capacity [GW]",
            legend=false
           )
             
    return p
end