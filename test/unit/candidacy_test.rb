require File.expand_path('../../test_helper', __FILE__)

class CandidacyTest < ActiveSupport::TestCase
  subject { @candidacy }

  context "The Candidacy class" do
    setup do
      @poll = Factory(:poll)
      @candidacy = Factory(:candidacy, :poll => @poll)
    end

    should belong_to :poll
    should belong_to :political_party
    should belong_to :member
    [:first_name, :last_name, :party, :elected, :votes, :basic_address].each do |column|
      should have_db_column column
    end
    [:poll_id, :last_name].each do |attribute|
      should validate_presence_of attribute
    end
    
    should "delegate area to poll" do
      assert_equal @poll.area, @candidacy.area
    end
    
    should 'mixin AddressUtilities::Base module' do
      assert @candidacy.respond_to?(:address_in_full)
    end

  end

  context "A Candidacy instance" do
    setup do
      @candidacy = Factory(:candidacy)
    end
    
    should "not be elected by default" do
      assert !@candidacy.elected?
    end
    
    context "when returning party_name" do
      
      should "return 'Independent' if not party_name and not associated political party" do
        assert_equal 'Independent', @candidacy.party_name
      end
      
      should "return name of political party if set" do
        political_party = Factory(:political_party)
        @candidacy.political_party = political_party
        assert_equal political_party.name, @candidacy.party_name
      end
      
      should "return party if political party if not set" do
        @candidacy.party = "foo"
        assert_equal "foo", @candidacy.party_name
      end
      
      should "return name of political party if political_party and party set" do
        political_party = Factory(:political_party)
        @candidacy.political_party = political_party
        @candidacy.party = "foo"
        assert_equal political_party.name, @candidacy.party_name
      end
      
    end
    
    context "when returning full_name" do
      should "concatenate first and last names" do
        assert_equal 'Fred M Flintstone', Candidacy.new(:first_name => 'Fred M', :last_name => 'Flintstone').full_name
      end
      
      should "concatenate return last name if no first_name" do
        assert_equal 'Flintstone', Candidacy.new(:last_name => 'Flintstone').full_name
      end
    end
    
    context "when returning status" do
      should "return nil by default" do
        assert_nil @candidacy.status
      end
      
      should "return 'elected' if elected" do
        @candidacy.elected = true
        assert 'elected', @candidacy.status
      end
    end
  end
end
