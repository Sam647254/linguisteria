function groupby(f::Function, items)
   collection = Dict()
   for item in items
      key = f(item)
      if key === nothing
         continue
      else
         push!(get!(collection, key, []), item)
      end
   end
   return collection
end

function default(a, b)
   a === nothing ? b : a
end