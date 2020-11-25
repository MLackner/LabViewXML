using Test
import LabViewXML

@testset "LabViewXML Tests" begin
    d = LabViewXML.readxml(joinpath(@__DIR__, "testdata/testdata.xml"))
    @test d["MyI8"] == Int8(4)
    @test d[""] == Int32(-1)
    @test d["MyCluster"]["MyU8Array"] == UInt8[1,2,3]
end