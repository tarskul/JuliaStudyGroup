"""
    mainmod

Main module for a more complex exercise: a monte carlo analysis on the parameters of a linear model (including visualisation through plots)
"""
module mainmod_diego # for the module to be recognised it needs to be part of a package that is added in Julia

using CSV, TOML
using JuMP
using Ipopt,Cbc,HiGHS,GLPK

export loadfile,savefiles,parameteranalysis,randomselection,linearmodel

"""
    loadfile(;input_file="./Data_Diego/input_file_Diego.toml")

Loads a toml file 'input_file_Diego' and returns a dictionary.

If the file does not exist, a warning is displayed and a default dictionary is returned instead.
"""
function loadfile(;ifile="./Data_Diego/input_file_Diego.toml")
    if isfile(ifile)
        idb=Dict{String, Integer}
            idb=TOML.parsefile(ifile)  # parse and transform data
    else
        println("The file does not exist, falling back to default dictionary.")
        idb=Dict(
            "parameteranalysis" => Dict(
                "i"=>0
                )
            )
    end
    return idb
end

"""
savefiles(idb::Dict;padb::Dict;ifile="./Data_Diego/input_file_Diego.toml";ofile="./Data_Diego/output_file_Diego.csv")

Saves a dictionary to a csv file and updates the input data in the toml file.
"""
function savefiles(idb::Dict,padb::Dict;ifile="./Data_Diego/input_file_Diego.toml",ofile="./Data_Diego/output_file_Diego.csv")
    # update input file
    open(ifile, "w") do f # write the file in TOML
        TOML.print(f, idb) 
    end

    # write results in CSV
    CSV.write(ofile, padb["modelresults"])
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
    modelresults=linearmodel(;y1=i/itarget)
    return Dict("i"=>i,"modelresults"=>modelresults)
end

function randomselection()
end

"""
    linearmodel(;iofile="./iofile.json")

Linear model using JuMP with the Ipopt solver.
"""
function linearmodel(;y1=3,xo1=12,yo2=20,xc1=6,xc2=7,yc1=8,yc2=12,c1=100,c2=120)
    model=Model(HiGHS.Optimizer)
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
    print(model)
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

if isinteractive() || abspath(PROGRAM_FILE) == @__FILE__ 
    # this is a pythonic way of doing things
    # in Julia they typically make a separate example or test file, so perhaps we'll put this code in the jupyter file instead, then we can also remove the auxiliary file and add that code here instead
    using .mainmod_diego #using because this code block is outside of the module and . for a local module
    idb=loadfile()
    padb=parameteranalysis(;i=idb["parameteranalysis"]["i"])
    idb["parameteranalysis"]["i"]=pop!(padb,"i")
    savefiles(idb,padb)
end