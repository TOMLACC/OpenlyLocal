require 'test_helper'

class OutputAreaTest < ActiveSupport::TestCase
  subject { @output_area }
  context "The OutputArea class" do
    setup do
      @output_area = Factory(:output_area)
    end
    
    should_validate_presence_of :oa_code, :lsoa_code, :lsoa_name#, :ward_id, :ward_snac_id
    should_validate_uniqueness_of :oa_code
    should_belong_to :ward
    
  end
end