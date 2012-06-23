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
        TestBase.expects(:active_fedora_find).returns TestBase.new
        TestBase.find(FCREPO_ID)
      end
    end
    describe "dynamic finder methods" do
      it "should call .find_by_conditions with correct attributes" do
        TestBase.expects(:find_by_conditions).with(:identifier => FCREPO_ID).returns(TestBase.new)
        TestBase.find_by_identifier(FCREPO_ID)
        TestBase.expects(:find_by_conditions).with(:cDate => FCREPO_DATE, :identifier => FCREPO_ID).returns(TestBase.new)
        TestBase.find_by_create_date_and_identifier(FCREPO_DATE, FCREPO_ID)
      end
      it "should return an ActiveFedora::Base when there is a single result" do
        pending "the mock of the rubydora repository object and a dummy response"
      end
      it "should return an array when there are multiple results" do
        pending "the mock of the rubydora repository object and a dummy response"
      end
    end
  end
end
