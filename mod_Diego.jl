"""
    mainmod

Main module for a more complex exercise: a monte carlo analysis on the parameters of a linear model (including visualisation through plots)
"""
module mainmod # for the module to be recognised it needs to be part of a package that is added in Julia

using JSON
using JuMP
using Ipopt,Cbc,HiGHS,GLPK

export loadfile,savefile,parameteranalysis,randomselection,linearmodel

"""
    loadfile(;iofile="./iofile.json")

Loads a json file 'iofile' and returns a dictionary.

If the file does not exist, a warning is displayed and a default dictionary is returned instead.

# Examples
```julia-repl
julia> loadfile(iofile="")
The file does not exist, falling back to default dictionary.
Dict("parameteranalysis" => Dict("i" => 0))
```
"""
function loadfile(;iofile="./iofile_Diego.json")
    if isfile(iofile)
        iodb=Dict()
        open(iofile, "r") do f
            dicttxt = read(f,String)  # file information to string
            iodb=JSON.parse(dicttxt)  # parse and transform data
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
    savefile(iodb::Dict;iofile="./iofile.json")

Saves a dictionary to a json file 'iofile'.
"""
function savefile(iodb::Dict;iofile="./iofile_Diego.json")
    stringdata = JSON.json(iodb,4) # pass data as a json string with indent 4
    open(iofile, "w") do f # write the file with the stringdata variable information
        write(f, stringdata)
    end
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
    linearmodel(;iofile="./iofile.json")

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
