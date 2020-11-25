import Base: parse

global LVTYPES = Dict(
    "Cluster" => Dict,
    "Array"   => Array,
    "Refnum"  => String,
    "DBL"     => Float64,
    "I64"     => Int64,
    "I32"     => Int32,
    "I16"     => Int16,
    "I8"      => Int8,
    "U64"     => UInt64,
    "U32"     => UInt32,
    "U16"     => UInt16,
    "U8"      => UInt8,
    "String"  => String,
    "Boolean" => Bool,
)

Base.parse(::Type{T}, x::AbstractString) where T <: AbstractString = x

function parse_array(element)
    # find size of the array and parse as Int. This only works for 1D arrays!
    dimsize = LightXML.find_element(element, "Dimsize") |> LightXML.content |> x -> parse(Int, x)
    lvtype = get_array_eltype(element)
    jltype = LVTYPES[lvtype]
    # preallocate Array
    array = Array{jltype}(undef, dimsize)
    if dimsize > 0
        for (i, _el) in enumerate(LightXML.child_elements(element))
            i < 3 && continue
            value_str = LightXML.find_element(_el, "Val") |> LightXML.content
            value     = parse(jltype, value_str)
            array[i-2] = value
        end
    end
    array
end

function get_array_eltype(element)
    for (i,_e) in enumerate(LightXML.child_elements(element))
        i < 3 && continue
        if i == 3
            return LightXML.name(_e)
        end
    end
    error("No type information found in array $(LightXML.name(element))")
end

"""
    readxml(path::String) -> Dict{String,Any}

Reads a LabVIEW generated XML file and returns a `Dict`.
"""
function readxml(path::String)
    function loopelements(element, dict)
        for e in LightXML.child_elements(element)
            if haskey(LVTYPES, LightXML.name(e))
                if LightXML.name(e) == "Cluster"
                    # Go deeper if we hit a cluster
                    clustername = LightXML.find_element(e, "Name") |> LightXML.content
                    dict[clustername] = Dict{String,Any}()
                    loopelements(e, dict[clustername])
                elseif LightXML.name(e) == "Array"
                    arrayname = LightXML.find_element(e, "Name") |> LightXML.content
                    dict[arrayname] = parse_array(e)
                else
                    key, value = parseelement(e)
                    # Put out a warning if the key already exists
                    haskey(dict, key) && @warn "Overwriting key '$key'."
                    dict[key] = value
                end
            elseif any(LightXML.name(e) .== ["NumElts", "Name", "Dimsize"])
                # Ignore entry
                continue
            else
                # Put out a warning if the type can't be found
                @warn "Could not find type for $(LightXML.name(e))"
            end
        end
    end

    function parseelement(element)
        lvtype = LightXML.name(element)
        jltype = LVTYPES[lvtype]
        element_name = LightXML.find_element(element, "Name") |> LightXML.content
        value_str    = LightXML.find_element(element, "Val") |> LightXML.content
        value = parse(jltype, value_str)
        element_name, value
    end

    dict = Dict{String,Any}()

    xdoc = LightXML.parse_file(path)
    xroot = LightXML.root(xdoc)

    loopelements(xroot, dict)

    LightXML.free(xdoc)

    dict
end
