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
#using Plots
using StatsPlots

export main,loadfile,savefile,parameteranalysis,randomselection,linearmodel

"""
    loadfile(;iofile="./Data_Tars/iofile.json")

Loads a json file 'iofile' and returns a dictionary.
Can also be used to load an excel file or a csv file.

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
        #iodf=DataFrame(funcmap[file_extension](iofile))
        #iodb=Dict(pairs(eachcol(iodf)))
        iodb=funcmap[file_extension](iofile)
    else
        println("The file does not exist, falling back to default dictionary.")
        iodb=Dict(
            "parameteranalysis" => Dict("i"=>0,"n"=>0,"t"=>0.0),
            "selection" => Dict(
                "gaspoweredplant" => Dict(
                    "I"=>[0.1,10],
                    "C"=>[1,100]
                ),
                "nuclear" => Dict(
                    "I" => [1,100],
                    "C" => [0.1,10]
                )
            ),
            "samples" => Dict(),
            "linearmodel" => Dict(
                "modeldata" => Dict("timesteps"=>10),
                "unitdata" => Dict(
                    "electricitydemand"=>Dict(
                        "category"=>"demand",
                        "I"=>0,
                        "C"=>0,
                        "pmax"=>10,
                        "powerprofile"=>[-i/10 for i in 1:10],
                    ),
                    "gaspoweredplant"=>Dict(
                        "category"=>"supply",
                        "I"=>1,
                        "C"=>10,
                        "pmax"=>15,
                    ),
                    "nuclear"=>Dict(
                        "category"=>"supply",
                        "I"=>10,
                        "C"=>1,
                        "pmax"=>5,
                    )
                )
            )
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
function parameteranalysis(iodb;npi=10,finish=0.0,i=0,itarget=10,t=0.0,ttarget=NaN,a=0.0,atarget=NaN,n=0,ntarget=NaN,parallel=false)
    samples=iodb["samples"]
    selectionarguments=iodb["selection"]
    modelarguments=iodb["linearmodel"]
    while finish<1.0
        # random selection, for this exercise limited to unitdata (next time I might merge model data and unit data)
        samplenames,inputvalues=randomselection(selectionarguments;numberofsamples=npi)
        # correction of redundant samples (future feature)
        # run model
        t1=time()
        if parallel==true
            nlist=zeros(length(samplenames))
            Threads.@threads for sampleindex in eachindex(samplenames)
                samplename=samplenames[sampleindex]
                modelinput=inputvalues[sampleindex]
                unitdata=copy(modelarguments["unitdata"])
                for (unitname,unitdict) in modelinput
                    merge!(unitdata[unitname],unitdict)
                end
                modeloutput=linearmodel(modelarguments["modeldata"],unitdata)
                samples[samplename]=(modelinput,modeloutput)
                nlist[sampleindex]=1
            end
            n+=sum(nlist)
        else
            for (samplename,modelinput) in Dict(samplenames .=> inputvalues)
                unitdata=copy(modelarguments["unitdata"])
                for (unitname,unitdict) in modelinput
                    merge!(unitdata[unitname],unitdict)
                end
                modeloutput=linearmodel(modelarguments["modeldata"],unitdata)
                samples[samplename]=(modelinput,modeloutput)
                n+=1
            end
        end
        t2=time()
        # end conditions
        t+=t2-t1
        i+=1
        finishratios=(# bool ? x : y implies if bool==True then do x else do y
            !isnan(itarget) ? i/itarget : 0.0,
            !isnan(ttarget) ? t/ttarget : 0.0,
            !isnan(ntarget) ? n/ntarget : 0.0,
            !isnan(atarget) ? a/atarget : 0.0
        )
        finish=maximum(finishratios)
        # save data (with signal interuption)
        iodb["samples"]=samples
        merge!(iodb,Dict("parameteranalysis"=>Dict("i"=>i,"n"=>n,"t"=>t,"finish"=>finish)))
        savefile(iodb)
    end
    return iodb
end

"""
    randomselection(datarange,numberofsamples)
Selects random values for each range of data provided

Example of the expected data
'''
Data=Dict(
    "category1" => [1,2],
    "category2" => [5,10]
)
'''
"""
function randomselection(datarange;numberofsamples=10,randomstep=0.1)
    samplenames=[]
    samplevalues=[]
    for _ in 1:numberofsamples
        samplename="_"
        sampledata=Dict()
        for (categoryname,categoryvalue) in datarange
            sampledata[categoryname]=Dict()
            for (parametername,parametervalue) in categoryvalue
                randomvalue=rand(parametervalue[1]:randomstep:parametervalue[2])#rand(min,max,#)
                samplename=samplename*string(randomvalue)*"_"
                sampledata[categoryname][parametername]=randomvalue
            end
        end
        push!(samplenames,samplename)
        push!(samplevalues,sampledata)
    end
    return samplenames,samplevalues#Dict(samplenames .=> samplevalues)
end

"""
    linearmodel(modeldata,unitdata)

Linear model using JuMP with the GLPK solver.

# Example of the expected input data
'''
    modeldata=Dict(
        "timesteps"=>10
    )
    unitdata=Dict(
        "electricitydemand"=>Dict(
            "category"=>"demand",
            "I"=>0,
            "C"=>0,
            "pmax"=>10,
            "powerprofile"=>[-i/10 for i in 1:10],
        ),
        "gaspoweredplant"=>Dict(
            "category"=>"supply",
            "I"=>1,
            "C"=>10,
            "pmax"=>15,
        ),
        "nuclear"=>Dict(
            "category"=>"supply",
            "I"=>10,
            "C"=>1,
            "pmax"=>5,
        )
    )
'''
"""
function linearmodel(modeldata,unitdata)#unitdata::Dict;

    constraintmapper=Dict(
        "demand" => unit -> demand(model,unit),
        "supply" => unit -> supply(model,unit)
    )
    function demand(model,unit)
        @constraint(model,[t=1:timesteps],po[unit,t]==unitdata[unit]["powerprofile"][t])
        @constraint(model,pc[unit]==pmax[unit])
    end
    function supply(model,unit)
        @constraint(model,[t=1:timesteps],0<=po[unit,t])
        @constraint(model,[t=1:timesteps],po[unit,t]<=pc[unit])
        @constraint(model,0<=pc[unit]<=pmax[unit])
    end


    model=Model(GLPK.Optimizer)
    set_silent(model)#set_optimizer_attribute(model,"print_level",0)#
    timesteps=modeldata["timesteps"]
    unitkeys=keys(unitdata)
    #region parameters
    I=Dict(unitkeys .=> [unitdata[unit]["I"] for unit in unitkeys])
    C=Dict(unitkeys .=> [unitdata[unit]["C"] for unit in unitkeys])
    pmax=Dict(unitkeys .=> [unitdata[unit]["C"] for unit in unitkeys])
    #endregion
    #region variables
    @variable(model,po[unitkeys,[t for t in 1:timesteps]])
    @variable(model,pc[unitkeys])
    #endregion
    #region objective
    @objective(model,Min,sum(I[u]*pc[u] for u in unitkeys)+sum(C[u]*po[u,t] for u in unitkeys for t in 1:timesteps))
    #endregion
    #region system contstraints
    @constraint(model,[t=1:timesteps],sum(po[u,t] for u in unitkeys)==0)#;base_name="balance")
    #endregion
    #region technology contstraints
    for unit in unitkeys
        unitcategory=unitdata[unit]["category"]
        constraintmapper[unitcategory](unit)
    end
    #endregion
    #print(model)
    optimize!(model)
    if termination_status(model) != OPTIMAL
        #does not work for Ipopt
        @warn("The model was not solved correctly.")
        return
    end
    modelresults=Dict(
        "status"=>termination_status(model),
        "status_primal"=>primal_status(model),
        "status_dual"=>dual_status(model),
        "objective"=>objective_value(model),
        #"shadow"=>shadow_price(balance[1]),
    )
    unitresults=Dict()
    for unit in unitkeys
        unitresults[unit]=Dict(
            "capacity"=>value(pc[unit]),
            "powerprofile"=>[value(po[unit,t]) for t in 1:timesteps]
        )
    end
    #for t in 1:timesteps
    #    modelresults[string("shadow$t")]=shadow_price(balance(t))
    #end
    return Dict("modelresults"=>modelresults,"unitresults"=>unitresults)
end

# something with powermodels? Nah, not for the Mopo project. Same for machine learning in the selection process.

function spinewrapper()
end

"""
    visualisation()
Visualisation of the results of the parameter analysis.
"""
function visualisation(iodb;plotfolder="./Data_Tars/",extensions=["png","svg","pdf"])#perhaps also selection
    selection=iodb["selection"]
    samples=iodb["samples"]
    modeldata=iodb["linearmodel"]["modeldata"]
    unitdata=iodb["linearmodel"]["unitdata"]

    # process data from dictionary to dataframes
        #sampledata=DataFrame()
    
    #profile plot
    profileplots=[]
    timesteps=[t for t in 1:modeldata["timesteps"]]
    for unitname in keys(unitdata)
        p=plot(title=unitname,legend=false)#legend=:outterright
        for (samplename,sample) in samples
            unitprofile=sample[2]["unitresults"][unitname]["powerprofile"]
            plot!(timesteps,unitprofile,label=samplename)
        end
        push!(profileplots,p)
    end
    profileplot=plot(profileplots...)
    for extension in extensions
        savefig(profileplot,plotfolder*"profileplot."*extension)
    end

    # data preparation
    selectionnames=[]
    for category in keys(selection)
        for parameter in keys(selection[category])
            push!(selectionnames,category*"_"*parameter)
        end
    end
    columnnames=[["samplename","objective"];["capacity_"*unitname for unitname in keys(unitdata)];selectionnames]
    sampledata=DataFrame([[] for _ = columnnames],columnnames)
    for (samplename,sample) in samples
        samplerow=[samplename,sample[2]["modelresults"]["objective"]]
        for unitname in keys(unitdata)
            push!(samplerow,sample[2]["unitresults"][unitname]["capacity"])
        end
        for category in keys(selection)
            for parameter in keys(selection[category])
                push!(samplerow,sample[1][category][parameter])
            end
        end
        push!(sampledata,samplerow)
    end

    # scatter plots
    # violinbox
    violinboxplot=plot(ylabel="objective",legend=false)
    @df sampledata violin!(selectionnames, :objective, linewidth=0)
    @df sampledata boxplot!(selectionnames, :objective, fillalpha=0.75, linewidth=2)
    @df sampledata dotplot!(selectionnames, :objective, marker=(:black, stroke(0)))
    for extension in extensions
        savefig(violinboxplot,plotfolder*"violinboxplot."*extension)
    end
    # gif?
end

"""
    main()
Runs an example of the parameter analysis
"""
function main(;parallelcomputing=false,iofilelocation="")
    iodb=loadfile(iofile=iofilelocation)
    pasettings=Dict(Symbol(k) => v for (k,v) in iodb["parameteranalysis"])
    pasettings[:parallel]=parallelcomputing
    iodb=parameteranalysis(iodb;pasettings...)
    visualisation(iodb)
    #savefile(DataFrame(iodb["samples"]))
    #savefile(iodb)
end

end#module end

if abspath(PROGRAM_FILE) == @__FILE__
    # this is a pythonic way of doing things
    # in Julia they typically make a separate example or test file
    using .mod_Tars #using because this code block is outside of the module and . for a local module
    mod_Tars.main()
elseif isinteractive()#should be deleted after developing the file
    using .mod_Tars
    mod_Tars.main()
end