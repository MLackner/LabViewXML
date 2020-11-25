using Test
using BenchmarkTools
import LabViewXML

println("testfile parsing benchmarking ...")
#   113.140 μs (264 allocations: 14.94 KiB)
d = @btime LabViewXML.readxml(joinpath(@__DIR__, "testdata/testdata.xml"))
@test d["MyI8"] == Int8(4)
@test d[""] == Int32(-1)
@test d["MyCluster"]["MyU8Array"] == UInt8[1,2,3]