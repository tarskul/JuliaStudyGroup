using JuMP, HiGHS, DataFrames, Chain
function append_input_dir(file_name)
    return joinpath(".",inputs["inputs_dir"], file_name)
end

function read_csv(file_name)
    return file_name |> append_input_dir |> CSV.File
end

function define_sets!(m::Model, inputs::Dict,scalars::Dict)
    # create dictionary to store sets
    m.ext[:sets] = Dict()

    m.ext[:sets][:T] = 1:scalars["time_steps"]
    m.ext[:sets][:G] = (inputs["input_file_set_g"] |> read_csv |> DataFrame).generators
    m.ext[:sets][:L] = (inputs["input_file_set_l"] |> read_csv |> DataFrame).lines
    m.ext[:sets][:N] = (inputs["input_file_set_n"] |> read_csv |> DataFrame).nodes

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

function process_parameters!(m::Model, scalars::Dict,df_gen::DataFrame,df_lin::DataFrame)

    # generate a dictonary "parameters"
    m.ext[:parameters] = Dict()

    # input parameters
    m.ext[:parameters][:pVOLL]    = scalars["value_of_lost_load"]
    m.ext[:parameters][:pWeight]  = 8760/scalars["time_steps"]
    
    # generators input data
    m.ext[:parameters][:pInvCost] = Dict(zip(df_gen.Generator,df_gen.InvCost_kEUR_MW_year))
    m.ext[:parameters][:pVarCost] = Dict(zip(df_gen.Generator,df_gen.VarCost_kEUR_per_MWh))
    m.ext[:parameters][:pUnitCap] = Dict(zip(df_gen.Generator,df_gen.UnitCap_MW          ))
    m.ext[:parameters][:pGenCon ] = Dict(zip(df_gen.Generator,df_gen.Node                ))

    # lines input data
    m.ext[:parameters][:pNodeA]  = Dict(zip(df_lin.Line,df_lin.Node_from))
    m.ext[:parameters][:pNodeB]  = Dict(zip(df_lin.Line,df_lin.Node_to  ))
    m.ext[:parameters][:pExpCap] = Dict(zip(df_lin.Line,df_lin.ExpCap_MW))
    m.ext[:parameters][:pImpCap] = Dict(zip(df_lin.Line,df_lin.ImpCap_MW))

    return m
end

"""
Returns a `DataFrame` with the values of the variables from the JuMP container `var`.
The column names of the `DataFrame` can be specified for the indexing columns in `dim_names`,
and the name of the data value column by a Symbol `value_col` e.g. :Value
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
            groupby(:dim1)
            combine(:Value => mean  => :Mean_val)
            sort(:Mean_val,rev=true)
        end)
    
    p = plot(df.dim1,
             df.Mean_val*1e3/pWeight,
             xlabel="Node [-]", 
             ylabel="Average λ [EUR/MWh]",
             legend=false
            )

    return p
end

function plot_avg_price_per_hour(df_::DataFrame)

    df =(@chain df_ begin
            groupby(:dim2)
            combine(:Value => mean  => :Mean_val)
        end)
    
    p = plot(df.dim2,
             df.Mean_val*1e3/pWeight,
             xlabel="Timesteps [-]", 
             ylabel="Average λ [EUR/MWh]",
             legend=false
             )

    return p
end