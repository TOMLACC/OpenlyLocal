require 'test_helper'

class CharityTest < ActiveSupport::TestCase

  context "The Charity class" do
    setup do
      @charity = Factory(:charity)
    end
    should have_many :supplying_relationships

    should have_db_column :title
    should have_db_column :activities
    should have_db_column :charity_number
    should have_db_column :website
    should have_db_column :email
    should have_db_column :telephone
    should have_db_column :date_registered
    # should have_db_column :charity_commission_url
    should validate_presence_of :charity_number
    should validate_presence_of :title
    should validate_uniqueness_of :charity_number
    should have_db_column :vat_number
    should have_db_column :contact_name
    should have_db_column :accounts_date
    should have_db_column :spending
    should have_db_column :income
    should have_db_column :date_removed
    
    should "mixin SpendingStat::Base module" do
      assert Charity.new.respond_to?(:spending_stat)
    end

    should 'mixin AddressMethods module' do
      assert @charity.respond_to?(:address_in_full)
    end
        
    context "when returning foaf version of telephone number" do

      should "return nil if telephone blank" do
        assert_nil @charity.foaf_telephone
      end

      should "return formatted number" do
        @charity.telephone = "0162 384 298"
        assert_equal "tel:+44-162-384-298", @charity.foaf_telephone
      end
    end
    
    context "when returning charity commission url" do
      should "build url using charity number" do
        assert_equal "http://www.charitycommission.gov.uk/SHOWCHARITY/RegisterOfCharities/SearchResultHandler.aspx?RegisteredCharityNumber=#{@charity.charity_number}&SubsidiaryNumber=0", @charity.charity_commission_url
      end

    end
    
    should "use title in to_param method" do
      @charity.title = "some title-with/stuff"
      assert_equal "#{@charity.id}-some-title-with-stuff", @charity.to_param
    end
    
  end
end
