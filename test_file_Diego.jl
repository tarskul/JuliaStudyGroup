if isinteractive() || abspath(PROGRAM_FILE) == @__FILE__ 
    # this is a pythonic way of doing things
    # in Julia they typically make a separate example or test file, so perhaps we'll put this code in the jupyter file instead, then we can also remove the auxiliary file and add that code here instead
    using .mainmod_diego #using because this code block is outside of the module and . for a local module
    iodb=loadfile()#iofile="")
    padb=parameteranalysis(;i=iodb["parameteranalysis"]["i"])
    iodb["parameteranalysis"]["i"]=pop!(padb,"i")
    merge!(iodb,padb)
    savefile(iodb)
end