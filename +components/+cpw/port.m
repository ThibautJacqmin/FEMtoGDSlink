function p = port(name, pos, ori, cpw_spec)
arguments
    name {mustBeTextScalar}
    pos
    ori
    cpw_spec routing.PortSpec
end

p = routing.PortRef(name=name, pos=pos, ori=ori, spec=cpw_spec);
end
