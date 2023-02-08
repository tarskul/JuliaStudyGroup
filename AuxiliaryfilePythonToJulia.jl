if abspath(PROGRAM_FILE) == @__FILE__
    println("The file is used directly")
else
    println("The file is used indirectly")
end