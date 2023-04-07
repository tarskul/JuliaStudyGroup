module spinewrapper

using SpineInterface
using SpineOpt

export main

function printspineinterfacenames()
    for name in names(SpineInterface)
        println(name)
    end
end

function buildtest(;db_url="sqlite:///$(@__DIR__)/spineproject/.spinetoolbox/items/spinedb_in/SpineDB_in.sqlite",cm="buildtest")
    d=Dict(
        :object_classes => [:model,:temporal_block,:stochastic_structure,:node],
        :objects => [[:model, :mora],[:temporal_block, :clock],[:stochastic_structure,:gantt],[:node,:nora]],
        #:object_parameters => [],
    )
    import_data(db_url,d,cm)
end

function runtest(;
    db_url_in="sqlite:///$(@__DIR__)/spineproject/.spinetoolbox/items/spinedb_in/SpineDB_in.sqlite",
    db_url_out="sqlite:///$(@__DIR__)/spineproject/.spinetoolbox/items/spinedb_out/SpineDB_out.sqlite"
    )

    m = run_spineopt(db_url_in, db_url_out; upgrade=true, log_level=2)
end

function main()
    buildtest()
    runtest()
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    using .spinewrapper
    spinewrapper.main()
end