require 'spec_helper'
require 'config_helper'

describe ActiveFedora::Finders do
  class TestBase < ActiveFedora::Base
    include ActiveFedora::Finders
  end
  FCREPO_ID = 'fedora-system:ContentModel-3.0'
  FCREPO_DATE = '2012-06-01T12:34:56.000Z'
  
  describe "finder methods" do
    describe "default find method" do
      it "should call the normal find method when passed a string" do
        TestBase.expects(:find_one).returns TestBase.new
        TestBase.find(FCREPO_ID)
      end
    end
    describe "dynamic finder methods" do
      it "should call .find_by_conditions with correct attributes" do
        TestBase.expects(:fcrepo_find).with(is_a(ActiveRecord::DynamicFinderMatch), :identifier => FCREPO_ID).returns(TestBase.new)
        TestBase.find_by_identifier(FCREPO_ID)
        TestBase.expects(:fcrepo_find).with(is_a(ActiveRecord::DynamicFinderMatch), :cDate => FCREPO_DATE, :identifier => FCREPO_ID).returns(TestBase.new)
        TestBase.find_by_create_date_and_identifier(FCREPO_DATE, FCREPO_ID)
      end
      it "should return an ActiveFedora::Base when there is a single result" do
        stubfedora = mock("Fedora")
        stubfedora.expects(:connection).returns(mock("Connection", :find_objects =>fixture('find_one.xml')))
        TestBase.expects(:find_one).with(FCREPO_ID).returns TestBase.new(:pid=>FCREPO_ID)
        ActiveFedora::Base.fedora_connection = [stubfedora]
        TestBase.find_by_identifier(FCREPO_ID).should be_a TestBase
      end
      it "should return an array when there are multiple results" do
        stubfedora = mock("Fedora")
        stubfedora.expects(:connection).returns(mock("Connection", :find_objects =>fixture('find_multiple.xml')))
        ActiveFedora::Base.fedora_connection = [stubfedora]
        TestBase.expects(:find_one).with(FCREPO_ID).returns TestBase.new(:pid=>FCREPO_ID)
        TestBase.expects(:find_one).with("demo:1").returns TestBase.new(:pid=>"demo:1")
        TestBase.find_all_by_source("test").should be_a Array
      end
      it "should throw an error when no results and a bang" do
        stubfedora = mock("Fedora")
        stubfedora.expects(:connection).returns(mock("Connection", :find_objects =>fixture('find_none.xml')))
        ActiveFedora::Base.fedora_connection = [stubfedora]
        #ActiveRecord::Base
        begin
          TestBase.find_by_identifier!("dummy:1")
          fail "should not successfully return from bang method with no results"
        rescue Exception => e
          e.should be_a ActiveRecord::RecordNotFound
        end
      end
    end
  end
end
