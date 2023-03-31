"""
Omar's implementation
"""

using TOML
using CSV
using DataFrames
using Arrow
using HDF5
using Parquet
using JSON
using XLSX
using AxisArrays
# using GRIB     
using Random
using Statistics
using Distributions
using JuMP
import HiGHS
using Plots
# using Makie
using BenchmarkTools

"""
This function makes a DataFrame from a file.
It has a dictionary of functions for a number of supported file formats.
It returns a boolean telling if the file format is supportedand a DataFrame 
with the contents of the file (if supported, an empty DataFrame otherwise)
"""
function dataframe_from_file(source_file,source_folder,parameters_file)

    parameters = TOML.parsefile(parameters_file)
    file_parameters = parameters["files"]
    excel_file_source_sheet = file_parameters["excel_file_source_sheet"]
    
    reading_functions = Dict(
        "csv" => file_name -> CSV.File(file_name),
        "feather" => file_name -> Arrow.Table(file_name),
        "h5" => file_name -> h5open(file_name,"r"),
        "parquet" => file_name -> read_parquet(file_name),
        "json" => file_name -> JSON.parsefile(file_name),
        "xlsx" => file_name -> XLSX.readtable(file_name,excel_file_source_sheet),
        
    )

    source_file_path= source_folder*"/"*source_file
    file_extension = split(source_file,".")[end]
    source_dataframe = DataFrame()
    dataframe_obtained = falseaaaa

    if file_extension in keys(reading_functions)
        dataframe_obtained = true
        source_data = reading_functions[file_extension](source_file_path)
        source_dataframe = DataFrame(source_data)
    end

    return(dataframe_obtained,source_dataframe)
end


"""
This function iterates over the files from a folder and prints
a DataFrame for each one (if the format is supported).
It reads the source folder from a paramaeters file
"""
function dataframes_from_files_from_folder(parameters_file)
    parameters = TOML.parsefile(parameters_file)
    file_parameters = parameters["files"]
    input_files_parameters = file_parameters["input"]
    source_folder = input_files_parameters["source_folder"]

    
    source_files = readdir(source_folder)

    for source_file in source_files
        dataframe_obtained,source_dataframe = dataframe_from_file(
            source_file,source_folder,parameters_file
        )
        if dataframe_obtained
            println(first(source_dataframe,10))
        end
    end

end

"""
This `returns a Dataframe based on inputs in the parameters file`
"""
function example_dataframe(parameters_file)
    parameters = TOML.parsefile(parameters_file)
    example_dataframe_dictionary = parameters["example_dataframe"]
    return(DataFrame(example_dataframe_dictionary))
end


""""
This fucntion writes a given DataFrame to an output folder for a given number of
file formats.
"""
function write_dataframe_to_folder(dataframe, dataframe_name,parameters_file)
    parameters = TOML.parsefile(parameters_file)
    output_files_parameters = parameters["files"]["output"]
    output_folder = output_files_parameters["folder"]
    chosen_output_formats = output_files_parameters["chosen_output_formats"]
    excel_sheet_name = output_files_parameters["excel_sheet_name"]
    excel_anchor_cell = output_files_parameters["excel_anchor_cell"]
   

   
    
    writing_functions = Dict(
        "csv" => (dataframe,file_path) -> CSV.write(file_path,dataframe),
        "feather" => (dataframe,file_path) -> Arrow.write(file_path,dataframe), 
        "parquet" => (dataframe,file_path) -> write_parquet(file_path,dataframe),  
        # "h5" => (dataframe,file_path) -> h5write(file_path,"data",dataframe),
        #writing DataFrames to HDF5 does not seem to be supported
        #because h5write does not accept generic Julia objects
        #See:
        #https://github.com/JuliaIO/HDF5.jl/issues/122
        "json" => (dataframe,file_path) -> JSON.write(
            file_path,JSON.json(dataframe)
        ),
        "xlsx" => (dataframe,file_path) -> XLSX.writetable(
            file_path,dataframe,overwrite=true,sheetname=excel_sheet_name,
            anchor_cell=excel_anchor_cell
        ),
    )

    for chosen_format in chosen_output_formats
        if chosen_format in keys(writing_functions)
            writing_functions[chosen_format](
                dataframe,output_folder*"/"*dataframe_name*"."*chosen_format)
        else
            println(chosen_format*" is not supported")
        end
    end
end

"""
This function returns a random value bewteen two values, with a normal
Distributions
"""
function rand_between(min_value, max_value,spread_ratio)
    # return(Uniform(min_value,max_value))
    return (
        Truncated(
            Normal((max_value+min_value)/2, (max_value-min_value)/spread_ratio),
            min_value,max_value)
    )
end

"""
This function returns arrays containing the characteristics of
power plants
"""
function characteristics_of_power_plants(parameters_file)

    power_plants_inputs = TOML.parsefile(parameters_file)["power_plants"]
    maximal_demand = power_plants_inputs["maximal_demand"]
    minimal_demand = power_plants_inputs["minimal_demand"]
    number_of_power_plants = power_plants_inputs["number_of_power_plants"]
    minimal_plant_variable_costs = power_plants_inputs[
        "minimal_plant_variable_costs"]
    maximal_plant_variable_costs = power_plants_inputs[
        "maximal_plant_variable_costs"]
    spread_ratio = power_plants_inputs["spread_ratio"]

    # When determining minimal and maximal productions, we need
    # to check that the minimal values are lower than the maximal ones,
    # otherwise the solver won't work
    minimal_versus_maximal_test_not_done = true

  
    # We draw the minimal and maximal production
    minimal_productions = (
        (2 * minimal_demand / number_of_power_plants) 
        * rand(number_of_power_plants)
    )
    # The factor 2 so that the sum (for a large nuumber of plants is (close to)
    # the minimal demand
    maximal_productions = (
        (2 * maximal_demand / number_of_power_plants) 
        * rand(number_of_power_plants)
    )
    # The factor 2 so that the sum (for a large nuumber of plants is (close to)
    # the maxiimal demand

    # We then test if the minimal productions are all smaller
    # then their maximal correspondants. Otherwise, we redraw (to avoid issues
    # with solving the problem). We also need to check that the minimal 
    # production sum  does not exceed minimal demand and that 
    # the maximal production sum is not smaller than the maximal production.
    # Any of these three could lead to an unsolvable system.
 

    while (
            any(minimal_productions .>= maximal_productions)
            #The dot is there for a piecewise comparison
            ||
            sum(minimal_productions) > minimal_demand
            ||
            sum(maximal_productions) < maximal_demand
    )   
        
        minimal_productions = (
            (2 * minimal_demand / number_of_power_plants) 
            * rand(number_of_power_plants)
        )
        maximal_productions = (
            (2 * maximal_demand / number_of_power_plants) 
            * rand(number_of_power_plants)
        )

    end


    plant_variable_costs = (
        rand(
            rand_between(
                minimal_plant_variable_costs,maximal_plant_variable_costs,
                spread_ratio), 
            number_of_power_plants
        )
    )


    return (minimal_productions, maximal_productions, plant_variable_costs)

end


"""
This function solves the dispatch for a given situation.
It is based on the code provided here:
https://jump.dev/JuMP.jl/stable/tutorials/applications/power_systems/

"""
function solve_dispatch(
    demand, renewable_availability, renewables_variable_costs,
    minimal_productions, maximal_productions, plant_variable_costs)
   
    # Define the economic dispatch (ED) model
    model = Model(HiGHS.Optimizer)
    set_silent(model)

    number_of_power_plants = length(minimal_productions)

    # The first variable is the plant_production
    @variable(
        model, 
        minimal_productions[plant_index] 
        <= plant_production[plant_index = 1:number_of_power_plants]
        <= maximal_productions[plant_index]
        )

    # The second variablke is the reneables injection
    @variable(
        model,
        0
        <= renewable_production
        <= renewable_availability
    )

    # The objective is to minimize the plant_variable_costs
    @objective(
        model,
        Min,
        sum(plant_production .* plant_variable_costs)
        #.* is for piecewise product
        + renewable_production*renewables_variable_costs
    )

    # The constraint is the the production matches the demand
    @constraint(
        model,
        sum(plant_production) + renewable_production == demand
    )


  
    # Solve statement
    optimize!(model)


    renewable_curtailment = (
        renewable_availability -value(renewable_production)
    )

    total_cost = objective_value(model)
    return(
        value.(plant_production), value(renewable_production), 
        # we need to used value to get the value, 
        # and a version with a dot for a vector
        renewable_curtailment,
        total_cost
    )


end


"""
This function runs the power systems model.
It throws the system characteristics in the solver and gets the system costs
and renewable curtailment as a function of the renewables potential
(which goes from zero to the maximal demand).
We also randomly draw the plant characteristics (minimal, maxaimal production,
and costs, but the sampling of these can be turned off in the settings), 
the renewable availability, and demand.
We then plot a scatter of all the iterations to get a range of outcomes.

"""
function power_systems_model(parameters_file)



    power_plants_inputs = TOML.parsefile(parameters_file)["power_plants"]
    renewable_capacity_range_steps = power_plants_inputs[
        "renewable_capacity_range_steps"]
    model_iterations = power_plants_inputs["model_iterations"]
    minimal_demand = power_plants_inputs["minimal_demand"]
    maximal_demand = power_plants_inputs["maximal_demand"]
    renewables_variable_costs = power_plants_inputs["renewables_variable_costs"]
    renewables_bottom_availability_factor =power_plants_inputs[
        "renewables_bottom_availability_factor"
    ]
    spread_ratio = power_plants_inputs["spread_ratio"]
    renewable_capacity_range = range(
        start=0 ,stop=maximal_demand, length=renewable_capacity_range_steps
    )

    cost_data = zeros(model_iterations, renewable_capacity_range_steps)
    curtailment_data = zeros(model_iterations, renewable_capacity_range_steps)
    plant_production_total = zeros(
        model_iterations, renewable_capacity_range_steps
    )
    renewable_production_computed  = zeros(
        model_iterations, renewable_capacity_range_steps
    )

    minimal_productions, maximal_productions, plant_variable_costs = (
            characteristics_of_power_plants(
                parameters_file)
        )
    plant_characteristics_in_iteration = power_plants_inputs[
        "plant_characteristics_in_iteration"
    ]
    
    for iteration in range(length=model_iterations)

        println(iteration)
        # We draw the parameters of the system
        renewable_availability_factor = rand(
            rand_between(
                renewables_bottom_availability_factor,1,spread_ratio),1)[1]
        demand = rand(
            rand_between(minimal_demand,maximal_demand,spread_ratio), 1)[1]
        if plant_characteristics_in_iteration
            minimal_productions, maximal_productions, plant_variable_costs = (
                characteristics_of_power_plants(
                    parameters_file)
            )
        end


        for (renewable_capacity_index, renewable_capacity)  in enumerate(
                renewable_capacity_range)

            renewable_availability = (
                renewable_availability_factor *renewable_capacity
            )

            (
                plant_production, renewable_production, renewable_curtailment,
                total_cost
                ) = solve_dispatch(
                    demand, renewable_availability, renewables_variable_costs,
                    minimal_productions, maximal_productions, 
                    plant_variable_costs
            )

            cost_data[iteration, renewable_capacity_index] = total_cost
            curtailment_data[iteration, renewable_capacity_index] = (
                renewable_curtailment)
            plant_production_total[iteration, renewable_capacity_index]  = (
                sum(plant_production)
            )
            renewable_production_computed[
                iteration, renewable_capacity_index] =(
                renewable_production
            )

        end
    

    end

    write_dataframe_to_folder(
        DataFrame(cost_data, :auto), "cost_data", parameters_file)
    write_dataframe_to_folder(
        DataFrame(curtailment_data, :auto), "curtailment_data", parameters_file)
    write_dataframe_to_folder(
        DataFrame(plant_production_total, :auto),
                 "plant_production_total", parameters_file)
    write_dataframe_to_folder(
        DataFrame(renewable_production_computed, :auto), 
                "renewable_production_computed", parameters_file)
  

    chosen_marker_size = power_plants_inputs["chosen_marker_size"]
    chosen_marker_alpha = power_plants_inputs["chosen_marker_alpha"]


    renewables__xlabel = (
        "Renewables peak production (GWh) (maximal demand=$(maximal_demand) GWh)"
    )

    cost_plot = scatter()

    for iteration in range(length=model_iterations) 
        
        cost_plot = scatter!(
            #The ! is there so that we put the plots on top of each other
            renewable_capacity_range, cost_data[iteration, :],
            markercolor=:blue,
            # seriescolor=:teal,
            # markerstrokecolor=:teal,
            legend=false, ylims=(0, Inf), markersize=chosen_marker_size,
            markeralpha=chosen_marker_alpha,
            markerstrokewidth=0,
            markerstrokealpha=0.26,
            title="Variable costs", ylabel="Variable costs (million €)",
            xlabel=renewables__xlabel, dpi=300
        )
    end


    savefig("Output_Omar/costs.png")

    curtailment_plot = scatter()
    for iteration in range(length=model_iterations)
        curtailment_plot = scatter!(
            #The ! is there so that we put the plots on top of each other
            renewable_capacity_range, curtailment_data[iteration, :],
            markercolor=:red, 
            # markerstrokecolor=:red,
            markeralpha=chosen_marker_alpha,
            legend=false, ylims=(0, Inf), markersize=chosen_marker_size,
            markerstrokewidth=0,
            markerstrokealpha=0.26,
            title="Curtailment", ylabel="Curtailed renewables (GWh)",
            xlabel=renewables__xlabel, dpi=300
        )
    end
    savefig("Output_Omar/curtail.png")


    plant_production_plot = scatter()
    for iteration in range(length=model_iterations)
        plant_production_plot = scatter!(
            #The ! is there so that we put the plots on top of each other
            renewable_capacity_range, plant_production_total[iteration, :],
            markercolor=:orange, 
            # markerstrokecolor=:red,
            markeralpha=chosen_marker_alpha,
            legend=false, ylims=(0, Inf), markersize=chosen_marker_size,
            markerstrokewidth=0,
            markerstrokealpha=0.26,
            title="Plant production", ylabel="Production (GWh)",
            xlabel=renewables__xlabel, dpi=300
        )
    end
    savefig("Output_Omar/plants.png")


    renewables_plot = scatter()
    for iteration in range(length=model_iterations)
        renewables_plot = scatter!(
            #The ! is there so that we put the plots on top of each other
            renewable_capacity_range, 
            renewable_production_computed[iteration, :],
            markercolor=:green, 
            # markerstrokecolor=:red,
            markeralpha=chosen_marker_alpha,
            legend=false, ylims=(0, Inf), markersize=chosen_marker_size,
            markerstrokewidth=0,
            markerstrokealpha=0.26,
            title="Renewables production", ylabel="Production (GWh)",
            xlabel=renewables__xlabel, dpi=300
        )
    end
    savefig("Output_Omar/renewables.png")

    # We made the plots in different figures. If we want one figure with
    # all these plots, we need to create a new plot (without an exclamation
    # mark) where we plot our previous plots.
    # Note that we can do the same by omitting using results_plot altogether
    # (i.e. just write plot(cost_plot, .....)), but naming it might allow us
    # to do things with it further (in the same way we did with all the 
    # subplots above and putting them in the results_plot)

    results_plot=plot()

    results_plot=plot(
        cost_plot, curtailment_plot, plant_production_plot,  renewables_plot,
        xguidefontsize=6, yguidefontsize=6,
        layout=(2,2), dpi=300)

    # Julia does not seem to have a super title plot feature (as in Python's 
    # Matplotlib), so we wee to use the following:
    title_plot = plot(
        title = "Power plant model results", grid = false, showaxis = false, 
        bottom_margin = -50Plots.px)

    results_plot_with_title = plot()
    results_plot_with_title = plot(
        title_plot, results_plot,
        layout=grid(2,1,heights=[0.1,0.9]), dpi=300)
    
    savefig("Output_Omar/power_plant_model.png")
    
end

if isinteractive() || abspath(PROGRAM_FILE) != @__FILE__   
    #The first condition is when using the REPL


    parameters_file = "parameters_Omar.toml"
    to_execute = TOML.parsefile(parameters_file)["to_execute"]
    

    if to_execute["file_reading"]
        dataframes_from_files_from_folder(parameters_file)
        println(example_dataframe(parameters_file))
        dataframe = example_dataframe(parameters_file)
        write_dataframe_to_folder(dataframe, "example", parameters_file)
    end

    if to_execute["power_systems"]
        if to_execute["benchmark_power_systems"]
            benchmark_samples = to_execute["benchmark_samples"]
            benchmark_evals = to_execute["benchmark_evals"]
            power_benchmark = @benchmark power_systems_model(parameters_file) samples = benchmark_samples evals=benchmark_evals
            BenchmarkTools.save(
                 "Output_Omar/benchmark_power.json", power_benchmark
            )
        else
            power_systems_model(parameters_file)
        end
    end



end