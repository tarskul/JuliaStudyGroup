"""
    mod_Tars

Tars's implementation of the functions in the main module.
"""
module mod_Tars # for the module to be recognised it needs to be part of a package that is added in Julia

using JSON
using CSV
using XLSX
using DataFrames
using JuMP
using Ipopt,Cbc,HiGHS,GLPK

export loadfile,savefile,parameteranalysis,randomselection,linearmodel

"""
    loadfile(;iofile="./Data_Tars/iofile.json")

Loads a json file 'iofile' and returns a dictionary.

If the file does not exist, a warning is displayed and a default dictionary is returned instead.

# Examples
```julia-repl
julia> loadfile(iofile="")
The file does not exist, falling back to default dictionary.
Dict("parameteranalysis" => Dict("i" => 0))
```
"""
function loadfile(;iofile="./Data_Tars/iofile_Tars.json")
    funcmap=Dict(#map for fileextensions
        "json" => filename -> JSON.parsefile(filename),
        "xlsx" => filename -> xlhandler(filename),
        "csv" => filename -> CSV.File(filename)
    )

    function xlhandler(filename;firstsheet="Tabelle1")
        # just to have an example of a local function in funcmap
        return XLSX.readtable(filename,firstsheet)
    end

    file_extension=split(iofile,".")[end]
    if isfile(iofile) && file_extension in keys(funcmap)
        iodf=DataFrame(funcmap[file_extension](iofile))
        iodb=Dict(pairs(eachcol(iodf)))
    else
        println("The file does not exist, falling back to default dictionary.")
        iodb=Dict(
            "parameteranalysis" => Dict("i"=>0),
            "modelresults" => Dict()
            )
    end
    return iodb
end
function loadfile_legacy(;iofile="./Data_Tars/iofile_Tars.json")
    if isfile(iofile)
        iodb=Dict()
        fileextension=split(iofile, ".")[end]
        if fileextension=="json"
            open(iofile, "r") do f
                dicttxt = read(f,String)  # file information to string
                iodb=JSON.parse(dicttxt)  # parse and transform data
            end
        elseif fileextension=="xlsx"
            dfxl=DataFrame(XLSX.readtable(iofile,"Tabelle1"))
            iodb=Dict(pairs(eachcol(dfxl)))
        end
    else
        println("The file does not exist, falling back to default dictionary.")
        iodb=Dict(
            "parameteranalysis" => Dict(
                "i"=>0
                )
            )
    end
    return iodb
end

"""
    savefile(iodb::Dict;iofile="./Data_Tars/iofile_Tars.json")

Saves a dictionary to a json file.
"""
function savefile(iodb::Dict;iofile="./Data_Tars/iofile_Tars.json")
    stringdata = JSON.json(iodb,4) # pass data as a json string with indent 4
    open(iofile, "w") do f # write the file with the stringdata variable information
        write(f, stringdata)
    end 
end

"""
    savefile(iodb::DataFrame;iofile="./Data_Tars/iofile_Tars.csv")

Saves a DataFrame to a csv file.
"""
function savefile(iodb::DataFrame;iofile="./Data_Tars/iofile_Tars.csv")
    CSV.write(iofile,iodb)
end

"""
    parameteranalysis()

Outer optimisation loop for selecting parameters and evaluating an inner optimisation loop for these parameters.
"""
function parameteranalysis(;finish=0.0,i=0,itarget=10,t=0.0,ttarget=NaN,a=0.0,atarget=NaN,n=0,ntarget=NaN)
    while finish<1.0
        i+=1
        finishratios=(
        !isnan(itarget) ? i/itarget : 0.0,
        !isnan(ttarget) ? t/ttarget : 0.0,
        !isnan(ntarget) ? n/ntarget : 0.0,
        !isnan(atarget) ? a/atarget : 0.0
    )
    finish=maximum(finishratios)
    end
    modelresults=linearmodel()
    return Dict("i"=>i,"modelresults"=>modelresults)
end

function randomselection()
end

"""
    linearmodel()

Linear model using JuMP with the Ipopt solver.
"""
function linearmodel(;y1=3,xo1=12,yo2=20,xc1=6,xc2=7,yc1=8,yc2=12,c1=100,c2=120)
    model=Model(GLPK.Optimizer)
    set_silent(model)#set_optimizer_attribute(model,"print_level",0)#
    #region variables
    @variable(model,x>=0)
    @variable(model,0<=y<=y1)
    #endregion
    #region objective
    @objective(model,Min,xo1*x+yo2*y)
    #endregion
    #region contstraints
    @constraint(model,con1,xc1*x+yc1*y>=c1)
    @constraint(model,con2,xc2*x+yc2*y>=c2)
    #endregion
    #print(model)
    optimize!(model)
    if termination_status(model) != OPTIMAL
        #does not work for Ipopt
        @warn("The model was not solved correctly.")
        return
    end
    return Dict("status"=>termination_status(model),"status_primal"=>primal_status(model),"status_dual"=>dual_status(model),"objective"=>objective_value(model),"x"=>value(x),"y"=>value(y),"shadow1"=>shadow_price(con1),"shadow2"=>shadow_price(con2))
end

# something with powermodels? Nah, not for the Mopo project. Same for machine learning in the selection process.

function spinewrapper()
end

end#module end

if abspath(PROGRAM_FILE) == @__FILE__
    # this is a pythonic way of doing things
    # in Julia they typically make a separate example or test file
    using .mod_Tars #using because this code block is outside of the module and . for a local module
    using DataFrames
    iodb=loadfile()#iofile="")
    padb=parameteranalysis(;i=iodb["parameteranalysis"]["i"])
    iodb["parameteranalysis"]["i"]=pop!(padb,"i")
    savefile(DataFrame(padb["modelresults"]))
    merge!(iodb,padb)
    savefile(iodb)
end