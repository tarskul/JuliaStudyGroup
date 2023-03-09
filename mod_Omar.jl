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
    file_extension = split(source_file,".")[2]
    source_dataframe = DataFrame()
    dataframe_obtained = false

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
function example_dataframe(parameters_file_name)
    parameters = TOML.parsefile(parameters_file)
    example_dataframe_dictionary = parameters["example_dataframe"]
    return(DataFrame(example_dataframe_dictionary))
end


""""
This fucntion writes a given DataFrame to an output folder for a given number of
file formats.
"""
function write_dataframe_to_folder(parameters_file)
    parameters = TOML.parsefile(parameters_file)
    output_files_parameters = parameters["files"]["output"]
    output_folder = output_files_parameters["folder"]
    chosen_output_formats = output_files_parameters["chosen_output_formats"]
    excel_sheet_name = output_files_parameters["excel_sheet_name"]
    excel_anchor_cell = output_files_parameters["excel_anchor_cell"]
    dataframe_name = output_files_parameters["dataframe_name"]

    dataframe = example_dataframe(parameters_file)
    
    writing_functions = Dict(
        "csv" => (dataframe,file_path) -> CSV.write(file_path,dataframe),
        "feather" => (dataframe,file_path) -> Arrow.write(file_path,dataframe), 
        "parquet" => (dataframe,file_path) -> write_parquet(file_path,dataframe),  
        # "h5" => (dataframe,file_path) -> h5write(file_path,"data",dataframe),
        #writing DataFrames to HDF5 does not seem to be supported
        #because h5write does not accept geenric Julia objects
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

if isinteractive() || abspath(PROGRAM_FILE) != @__FILE__   
    #The first condition is when usin the REPL


    parameters_file = "parameters_Omar.toml"
    dataframes_from_files_from_folder(parameters_file)
    println(example_dataframe(parameters_file))
    write_dataframe_to_folder(parameters_file)


end