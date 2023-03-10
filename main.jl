"""
    mainmod

Main module for a more complex exercise: a monte carlo analysis on the parameters of a linear model (including visualisation through plots)
"""
module mainmod # for the module to be recognised it needs to be part of a package that is added in Julia

using JSON
using JuMP
using Ipopt,Cbc,HiGHS,GLPK

export main,loadfile,savefile,parameteranalysis,randomselection,linearmodel

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

function main()
    loadfile()
    parameteranalysis()
    savefile(Dict())
    println("The main file works")
end

end#module end

if abspath(PROGRAM_FILE) == @__FILE__
    #=
    This protects the module from executing this script when it is called by a different module or during an interactive session in the REPL.

    To use the file in the REPL you should use the following code:
    include("./mainmod.jl")
    mainmod.main()

    This is a more pythonic way of doing things. In Julia they typically make a separate example or test file (without the if abspath...). That would also make it easier to use in the REPL...
    =#
    using .mainmod #using because this code block is outside of the module and . for a local module
    main()
end
