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
function loadfile(;iofile="./iofile.json")
end

"""
    savefile(iodb::Dict;iofile="./iofile.json")

Saves a dictionary to a json file 'iofile'.
"""
function savefile(iodb::Dict;iofile="./iofile.json")
end

"""
    parameteranalysis()

Outer optimisation loop for selecting parameters and evaluating an inner optimisation loop for these parameters.
"""
function parameteranalysis(;finish=0.0,i=0,itarget=10,t=0.0,ttarget=NaN,a=0.0,atarget=NaN,n=0,ntarget=NaN)
end

function randomselection()
end

"""
    linearmodel(;iofile="./iofile.json")

Linear model using JuMP with the Ipopt solver.
"""
function linearmodel()
end

# something with powermodels? Nah, not for the Mopo project. Same for machine learning in the selection process.

function spinewrapper()
end

end#module end

if abspath(PROGRAM_FILE) == @__FILE__
    # this is a pythonic way of doing things
    # in Julia they typically make a separate example or test file, so perhaps we'll put this code in the jupyter file instead, then we can also remove the auxiliary file and add that code here instead
    using .DSTmini #using because this code block is outside of the module and . for a local module
    iodb=loadfile()#iofile="")
    padb=parameteranalysis(;i=iodb["parameteranalysis"]["i"])
    iodb["parameteranalysis"]["i"]=pop!(padb,"i")
    merge!(iodb,padb)
    savefile(iodb)
end