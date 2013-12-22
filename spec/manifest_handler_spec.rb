require File.expand_path('../spec_helper', __FILE__)

describe ManifestHandler do

  let(:settings) do
    s = Settings.new
    s.manifest_path = File.expand_path('spec/data/')
    s.offline = true
    s
  end
  
  let(:mh) do
    mh = ManifestHandler.new settings
    mh.read_remote
    mh
  end
  
  it "reads manifests" do
    mh.manifests.count.should == 5
    mh.libraries.count.should == 5
    mh.read_remote
    mh.manifests.count.should == 5
    mh.libraries.count.should == 5
  end

  it "provides access to manifests" do
    mh.manifest("awesomelib").class.should == Hash
    expect { mh.manifest("nonexisting") }.to raise_error
  end

  it "reads schema type" do
    mh.manifest("awesomelib")["schema_type"].should == "release"
    mh.manifest("newlib")["schema_type"].should == "generic"
    mh.manifest("proprietarylib")["schema_type"].should == "proprietary-release"
  end
  
  context "#libraries" do

    it "returns all libraries" do
      expect( mh.libraries.count ).to eq 5
    end
    
    it "returns stable libraries" do
      libraries = mh.libraries :stable
      expect( libraries.count ).to eq 2
      expect( libraries.first.manifests.last["name"] ).to eq "awesomelib"
      expect( libraries.first.manifests.last["version"] ).to eq "0.2.0"
    end
    
    it "returns development versions" do
      libraries = mh.libraries :edge
      expect( libraries.count ).to eq 1
      expect( libraries.first.manifests.last["name"] ).to eq "bleedingedge"
      expect( libraries.first.manifests.last["version"] ).to eq "edge"
    end
    
    it "returns unreleased libraries" do
      libraries = mh.unreleased_libraries
      expect( libraries.count ).to eq 1
      expect( libraries.first.manifests.last["name"] ).to eq "newlib"
    end
    
    it "returns commercial libraries" do
      libraries = mh.commercial_libraries
      expect( libraries.count ).to eq 3
      expect( libraries.first.manifests.last["name"] ).to eq "awesomelib"
      expect( libraries[1].manifests.last["name"] ).to eq "commercial"
    end

  end
  
  context "#library" do
    
    it "returns one library" do
      library = mh.library "awesomelib"
      expect( library.name ).to eq "awesomelib"
    end
    
  end
  
end
