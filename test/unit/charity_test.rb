require File.expand_path('../../test_helper', __FILE__)

class CharityTest < ActiveSupport::TestCase

  context "The Charity class" do
    setup do
      @charity = Factory(:charity)
    end

    should have_many :classification_links
    should have_many(:classifications).through :classification_links
    should have_many :charity_annual_reports

    should validate_presence_of :charity_number
    should validate_presence_of :title
    should validate_uniqueness_of :charity_number
    [ :title, :activities, :charity_number, :website, :email, :telephone,
      :date_registered, :vat_number, :contact_name, :accounts_date, :spending,
      :income, :date_removed, :normalised_title, :accounts, :employees,
      :volunteers, :financial_breakdown, :trustees, :other_names, :last_checked,
      :facebook_account_name, :youtube_account_name, :feed_url,
      :governing_document, :company_number, :housing_association_number,
      :subsidiary_number, :fax, :area_of_benefit, :signed_up_for_1010,
      :corrected_company_number, :manually_updated,
    ].each do |column|
      should have_db_column column
    end

    should "serialize mixed data columns" do
      %w(financial_breakdown other_names trustees accounts).each do |attrib|
        @charity.update_attribute(attrib, [{:foo => 'bar'}])
        assert_equal [{:foo => 'bar'}], @charity.reload.send(attrib), "#{attrib} attribute is not serialized"
      end
    end

    should "have belong_to company with corrected_company_number as foreign key" do
      company = Factory(:company)
      company_charity = Factory(:charity, :corrected_company_number => company.company_number)
      assert_equal company, company_charity.company
    end

    should "validate uniqueness of non-blank company_number" do
      another_charity = Factory.build(:charity)
      assert another_charity.valid?
      @charity.update_attribute(:company_number, 'AB12345')
      dup_charity = Factory.build(:charity, :company_number => @charity.company_number)
      assert !dup_charity.valid?
    end

    should "mixin SpendingStatUtilities::Base module" do
      assert Charity.new.respond_to?(:spending_stat)
    end

    should "mixin SpendingStatUtilities::Payee module" do
      assert Charity.new.respond_to?(:supplying_relationships)
    end

    should 'mixin AddressUtilities::Base module' do
      assert @charity.respond_to?(:address_in_full)
    end

    should "include SocialNetworkingUtilities::Base mixin" do
      assert Charity.new.respond_to?(:update_social_networking_details)
    end

    context "when normalising title" do

      should "return nil if blank" do
        assert_nil Charity.normalise_title(nil)
        assert_nil Charity.normalise_title('')
      end

      should "normalise title" do
        TitleNormaliser.expects(:normalise_title).with('foo bar')
        Charity.normalise_title('foo bar')
      end

      should "remove leading 'the' " do
        TitleNormaliser.expects(:normalise_title).with('foo trust')
        Charity.normalise_title('the foo trust')
      end

      should "remove leading 'the' from a word" do
        TitleNormaliser.expects(:normalise_title).with('theatre trust')
        Charity.normalise_title('theatre trust')
      end
    end

    context "when adding new charities" do
      setup do
        @new_charity_info = [{:charity_number => '98765', :title => "NEW CHARITY"},
                            {:charity_number => '8765', :title => "ANOTHER NEW CHARITY"}]
        CharityUtilities::Client.any_instance.stubs(:get_recent_charities).returns(@new_charity_info)
      end

      should "get new charities using CharityUtilities" do
        Charity.any_instance.stubs(:update_info)
        CharityUtilities::Client.any_instance.expects(:get_recent_charities).returns(@new_charity_info)
        Charity.add_new_charities
      end

      should "create new charities from information returned from CharityUtilities" do
        Charity.any_instance.stubs(:update_info)
        assert_difference "Charity.count", 2 do
          Charity.add_new_charities
        end
      end

      should "update info for newly-created charities" do
        Charity.any_instance.expects(:update_info).twice
        Charity.add_new_charities
      end

      should "return charities" do
        Charity.any_instance.stubs(:update_info)
        charities = Charity.add_new_charities
        assert_equal 2, charities.size
        assert_kind_of Charity, charities.first
      end

      context "and problem updating info on charities" do
        # setup do
        #   Charity.any_instance.stubs(:update_from_charity_register).returns(true)
        # end

        should "still save basic charity details" do
          Charity.any_instance.expects(:update_info).twice.raises
          assert_difference "Charity.count", 2 do
            charities = Charity.add_new_charities
          end
        end

        should "not raise exception if Timeout:Error" do
          Charity.any_instance.expects(:update_info).twice.raises(Timeout::Error)

          assert_nothing_raised() { Charity.add_new_charities }
        end
      end

      context "and specific dates given" do
        setup do
          Charity.any_instance.stubs(:update_info)
        end

        should "get new charities between given dates" do
          Charity.any_instance.stubs(:update_info)
          start_date, end_date = 1.month.ago, 2.weeks.ago
          CharityUtilities::Client.any_instance.expects(:get_recent_charities).with(start_date, end_date).returns(@new_charity_info)
          Charity.add_new_charities(:start_date => start_date, :end_date => end_date)
        end
      end

      context "and charity with charity number already exists" do
        setup do
          Factory(:charity, :charity_number => '8765')
        end

        should "not create another charity with charity number" do
          Charity.any_instance.stubs(:update_info)
          assert_difference "Charity.count", 1 do
            Charity.add_new_charities
          end
        end

        should "update info only for new charity" do
          Charity.any_instance.expects(:update_info) #once
          Charity.add_new_charities
        end

        should "not raise exception" do
          Charity.any_instance.stubs(:update_info)
          assert_nothing_raised(Exception) { Charity.add_new_charities }
        end

        should "return all charities, even ones not saved" do
          Charity.any_instance.stubs(:update_info)
          charities = Charity.add_new_charities
          assert_equal 2, charities.size
          assert_kind_of Charity, charities.first
          unsaved_charity = charities.detect{ |c| c.new_record? }
          assert_equal '8765', unsaved_charity.charity_number
        end
      end

    end

  end

  context "an instance of the Charity class" do
    setup do
      @charity = Factory(:charity)
    end

    context "after creation" do
      setup do
        @unsaved_charity = Factory.build(:charity)
      end

      should 'update external info' do
        @unsaved_charity.expects(:update_external_info)
        @unsaved_charity.save!
      end
    end

    context "when saving" do
      should "normalise title" do
        @charity.expects(:normalise_title)
        @charity.save!
      end

      should "save normalised title" do
        @charity.title = "The Foo & Baz Trust. "
        @charity.save!
        assert_equal "foo and baz trust", @charity.reload.normalised_title
      end
    end

    should "alias website as url" do
      assert_equal 'http://foo.com', Charity.new(:website => 'http://foo.com').url
    end

    context "when setting website" do
      should "clean up using url_normaliser" do
        assert_equal 'http://foo.com', Charity.new(:website => 'foo.com').website
      end
    end

    context "when setting company_number" do
      setup do
        Company.stubs(:normalise_company_number).returns('BC4567')
      end

      should "set company number" do
        @charity.company_number = 'AB1234'
        assert_equal 'AB1234', @charity.company_number
      end

      should "normalised company_number" do
        Company.expects(:normalise_company_number).with('AB1234')
        @charity.company_number = 'AB1234'
      end

      should "set corrected_company_number to normalised company number" do
        @charity.company_number = 'AB1234'
        assert_equal 'BC4567', @charity.corrected_company_number
      end

      context "and corrected_company_number already set" do
        setup do
          @charity.corrected_company_number = 'AB5678'
        end

        should "not change corrected_company_number" do
          @charity.company_number = 'AB1234'
          assert_equal 'AB5678', @charity.corrected_company_number
        end
      end
    end

    context "when returning extended_title" do

      should "return charity with charity number in brackets" do
        assert_equal "#{@charity.title} (charity number #{@charity.charity_number})", @charity.extended_title
      end

      should "include status in brackets if status not nil" do
        @charity.stubs(:status).returns('removed')
        assert_equal "#{@charity.title} (charity number #{@charity.charity_number}, removed)", @charity.extended_title
      end
    end

    context "when returning status" do

      should "return nil by default" do
        assert_nil @charity.status
      end

      should "return 'removed' if date_removed not nil" do
        assert_equal "removed", Charity.new(:date_removed => 3.days.ago.to_date).status
      end
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
        assert_equal "http://apps.charitycommission.gov.uk/Showcharity/RegisterOfCharities/SearchResultHandler.aspx?RegisteredCharityNumber=#{@charity.charity_number}&SubsidiaryNumber=0", @charity.charity_commission_url
      end

    end

    context "when returning resource_uri" do
      should 'return OpenCharities uri for charity' do
        assert_equal "http://opencharities.org/id/charities/#{@charity.charity_number}", @charity.resource_uri
      end
    end

    context "when performing" do
      should "update_from_charity_register" do
        @charity.expects(:update_from_charity_register)
        @charity.perform
      end
    end

    context "when returning possible_company?" do
      should "return true only if Governing Document begins with Mem etc" do
        assert Charity.new(:governing_document => 'Memorandum etc').possible_company?
        assert Charity.new(:governing_document => 'MEMORANDUM').possible_company?
        assert Charity.new(:governing_document => 'Mem & Art').possible_company?
        assert Charity.new(:governing_document => 'M&A').possible_company?
        assert Charity.new(:governing_document => 'M & A').possible_company?
        assert !Charity.new(:governing_document => 'foo').possible_company?
        assert !Charity.new.possible_company?
      end
    end

    context "when matching company_number" do
      setup do
        @possible_company_charity = Factory(:charity, :title => 'Foo Bar Ltd')
      end

      should "reconcile against OpenCorporates" do

      end
    end

    should "use title in to_param method" do
      @charity.title = "some title-with/stuff"
      assert_equal "#{@charity.id}-some-title-with-stuff", @charity.to_param
    end

    should "return nil for twitter_list_name" do
      assert_nil @charity.twitter_list_name
    end

    context "when assigning info to accounts" do
      setup do
        @accounts_info = [ { :accounts_date => '31 Mar 2009', :income => '1234', :spending => '2345', :accounts_url => 'http://charitycommission.gov.uk/accounts2.pdf'},
                           { :accounts_date => '31 Mar 2008', :income => '123', :spending => '234', :accounts_url => 'http://charitycommission.gov.uk/accounts1.pdf'}]
      end

      should "used given info to set accounts attribute" do
        @charity.accounts = @accounts_info
        assert_equal @accounts_info, @charity.accounts
      end

      should "used first year to set current accounts attributes" do
        @charity.accounts = @accounts_info
        assert_equal '31 Mar 2009'.to_date, @charity.accounts_date
        assert_equal 1234, @charity.income
        assert_equal 2345, @charity.spending
      end

      should "not raise excption if no accounts" do
        assert_nothing_raised(Exception) { @charity.accounts = [] }
      end

    end

    context "when updating info" do
      setup do
        @charity.stubs(:update_from_charity_register).returns(true)
      end

      should "update from charity register" do
        @charity.expects(:update_from_charity_register)
        @charity.update_info
      end

      should "update social networking info from website" do
        @charity.expects(:update_social_networking_details_from_website)
        @charity.update_info
      end

      context "and new record after updating from register" do
        should "not update social networking info" do
          new_charity = Charity.new
          new_charity.stubs(:update_from_charity_register)
          new_charity.expects(:update_social_networking_details_from_website).never

          new_charity.update_info
        end
      end

    end

    context "when updating external info" do

      should "update social networking info from website" do
        @charity.expects(:update_social_networking_details_from_website)
        @charity.update_external_info
      end

      should "update with company_number" do
        @charity.expects(:update_with_company_number)
        @charity.update_external_info
      end
   end

    context "when updating from register" do
      should "get info using charity utilities" do
        dummy_client = stub
        CharityUtilities::Client.expects(:new).with(:charity_number => @charity.charity_number).returns(dummy_client)
        dummy_client.expects(:get_details).returns({})
        @charity.update_from_charity_register
      end

      should "update using info returned from charity utilities" do
        CharityUtilities::Client.any_instance.stubs(:get_details).returns(:activities => 'foo stuff')
        @charity.update_from_charity_register
        assert_equal 'foo stuff', @charity.reload.activities
      end

      should "not fail if there are unknown attributes" do
        CharityUtilities::Client.any_instance.stubs(:get_details).returns(:activities => 'foo stuff', :foo => 'bar')
        assert_nothing_raised(Exception) { @charity.update_from_charity_register }
        assert_equal 'foo stuff', @charity.reload.activities
      end

      should "not overwrite existing entries with blank ones" do
        @charity.update_attribute(:website, 'http://foo.com')
        CharityUtilities::Client.any_instance.stubs(:get_details).returns(:activities => 'foo stuff', :website => '')
        @charity.update_from_charity_register
        assert_equal 'http://foo.com', @charity.reload.website
      end

      should "update last_checked time" do
        CharityUtilities::Client.any_instance.stubs(:get_details).returns(:activities => 'foo stuff', :website => '')
        @charity.update_from_charity_register
        assert_in_delta Time.now, @charity.reload.last_checked, 2
      end

      should "not update last_checked time if problem saving @charity" do
        @charity.title = nil
        CharityUtilities::Client.any_instance.stubs(:get_details).returns(:activities => 'foo stuff')
        assert !@charity.update_from_charity_register
        assert_nil @charity.reload.last_checked
      end

    end

    context "when updating with company number" do
      setup do
        @poss_company_charity = Factory(:charity)
      end

      context "and charity is possible_company?" do
        setup do
          @poss_company_charity.stubs(:possible_company?).returns(true)
        end

        should "match company_number" do
          @poss_company_charity.expects(:match_company_number)
          @poss_company_charity.update_with_company_number
        end

        should "update charity with matched company number" do
          @poss_company_charity.stubs(:match_company_number).returns('98765432')
          @poss_company_charity.update_with_company_number
          assert @poss_company_charity.reload.company_number == '98765432'
        end
      end

      context "and charity is not possible_company?" do
        setup do
          @poss_company_charity.stubs(:possible_company?)
        end

        should "not match_company_number" do
          @poss_company_charity.expects(:match_company_number).never
          @poss_company_charity.update_with_company_number
        end
      end

      context "and charity already has company_number" do
        setup do
          @poss_company_charity.company_number = '12345678'
          @poss_company_charity.stubs(:possible_company?).returns(true)
        end

        should "not match_company_number" do
          @poss_company_charity.expects(:match_company_number).never
          @poss_company_charity.update_with_company_number
        end
      end
    end
  end

end
