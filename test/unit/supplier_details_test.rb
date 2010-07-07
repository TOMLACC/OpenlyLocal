require 'test_helper'

class SupplierDetailsTest < ActiveSupport::TestCase
  
  context "A SupplierDetails instance" do
    setup do
      @supplier_details = SupplierDetails.new
    end
    
    should 'have website accessor' do
      assert @supplier_details.respond_to?(:url)
      assert @supplier_details.respond_to?(:url=)
    end
    
    should 'have company_number accessor' do
      assert @supplier_details.respond_to?(:company_number)
      assert @supplier_details.respond_to?(:company_number=)
    end
    
    should 'have wikipedia_url accessor' do
      assert @supplier_details.respond_to?(:wikipedia_url)
      assert @supplier_details.respond_to?(:wikipedia_url=)
    end
    
    context 'when approving' do
      setup do
        @item = Factory(:supplier)
        @user_submission = Factory(:user_submission, :item => @item, :submission_type => 'supplier_details', :submission_details => {:company_number => '1234', :url => 'http://foo.com'})
        @supplier_details_object = @user_submission.submission_details
      end
      
      should 'update item associated with user_submission with supplier details' do
        @item.expects(:update_supplier_details).with(@supplier_details_object)
        
        @supplier_details_object.approve(@user_submission)
      end
      
      should 'return true if item successfully updated' do
        @item.expects(:update_supplier_details).with(@supplier_details_object).returns(true)
        assert @supplier_details_object.approve(@user_submission)
      end
      
      context "and problem updating from user_submission" do
        setup do
          @item.stubs(:update_supplier_details).with(@supplier_details_object).raises
        end
      
        should "not raise exception" do
          assert_nothing_raised(Exception) { @supplier_details_object.approve(@user_submission) }
        end
        
        should "return false" do
          assert !@supplier_details_object.approve(@user_submission)
        end
      end
    end

  end
end