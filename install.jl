using JSON
using Pkg

# install packages
packagesstr = get(ENV, "PACKAGES", "[]")
try 
    packages = JSON.parse(packagesstr)
    if isa(packages, Array)
        if length(packages) > 0
            for package in Iterators.Stateful(packages)
                try
                    Pkg.add(package)
                catch e
                    println("Failed to install package '" * package * "' error: " * sprint(showerror, e))
                    exit(153)            
                end
            end
            Pkg.resolve()
        end
    else
        println("Packages variable is not an array.")
        exit(152)
    end
catch e
    println("Packages variable '" * packagesstr * "' is not a JSON string, error: " * sprint(showerror, e))
    exit(152)
end
