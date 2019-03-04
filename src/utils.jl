using DataFrames 

function get_model_result(m::PSI.CanonicalModel; kwargs...)

    d = Dict{String, DataFrame}()
    
    for (k, v) in m.variables
        d[k] = create_result_dict(v)        
    end

    return d

end


function create_result_dict(jump_array::JuMP.Containers.DenseAxisArray)

    d = Dict{String, Array{Float64,1}}()

    if length(jump_array.axes) == 2

        for var in jump_array.axes[1]
            
            arr = Array{Float64,1}()

            for t in jump_array.axes[2]
                 push!(arr, round(JuMP.value(jump_array[var, t]), digits=2))
            end

            d[var] = arr
        end
    
    elseif  length(jump_array.axes) == 1
            
            arr = Array{Float64,1}()

            for t in 1:12
                
                 push!(arr, round(JuMP.value(jump_array[t]), digits=2))
            end
            
        d["vrt"] = arr
            
    end

    return d

end

function get_total_thermal(d::Dict)
    return [sum(Matrix(d[:p_th][i,1:2])) for i in 1 : 24]
end

function get_total_renewable(d::Dict)
    return [sum(Matrix(d[:p_re][i,1:2])) for i in 1 : 24]
end

function get_total_load(d::Dict)
    return get_total_renewable(d) + get_total_thermal(d)
end

function get_fraction_renewable(d::Dict)
    return get_total_renewable(d)./(get_total_renewable(d)+get_total_thermal(d))
end

function get_total_curtail(d::Dict, sys::PowerSystems.PowerSystem)
    
     available =[gen.tech.installedcapacity*values(gen.scalingfactor) for gen in sys.generators.renewable]
     total =    [available[1][i]+available[2][i]+available[3][i] for i in 1:24]
     
    return total - get_total_renewable(d) 
end


#=
N = 1000
x = range(1, 10, length=N)
y = x.^2
v_ones = ones(N)

vals = [30, 20, 10] # Values to iterate over and add/subtract from y.

for (i, val) in enumerate(vals)
    alpha = 0.5*(i+1)/length(vals) # Modify the alpha value for each iteration.
    fill_between(x, y+v_ones*val, y-v_ones*val, color="red", alpha=alpha)
end
=#