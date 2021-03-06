require_relative "../helper"

describe "Rorient::Rid" do

  it "initializes with a rid_obj argument" do
    proc { Rorient::Rid.new }.must_raise  ArgumentError
    rorient_rid = Rorient::Rid.new(rid_obj: "#12:34")
    rorient_rid.instance_variable_get(:@rid).must_equal "12:34"
  end

  it "will check rid is either #x:y or x:y" do
    proc { Rorient::Rid.new(rid_obj: "13#4") }.must_raise Rorient::Rid::WrongRidFormat  
    rorient_rid = Rorient::Rid.new(rid_obj: "12:34")
    rorient_rid.must_be_instance_of Rorient::Rid
  end

  it "will check that hash has a rid" do
    proc { Rorient::Rid.new(rid_obj: {first: 1, second: "no", good: true}) }.must_raise Rorient::Rid::NoRidFound
  end

  it "has a rid method to read rid" do
    rorient_rid = Rorient::Rid.new(rid_obj: "12:34")
    rorient_rid.rid.must_equal "12:34"
  end

  it "will always return a rid without #" do
    rorient_rid = Rorient::Rid.new(rid_obj: "#12:34")
    rorient_rid.rid.must_equal "12:34"
    rorient_rid = Rorient::Rid.new(rid_obj: {rid: "#12:34"})
    rorient_rid.rid.must_equal "12:34"
  end
end
