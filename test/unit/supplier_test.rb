require 'test_helper'

class SupplierTest < ActiveSupport::TestCase
  subject { @supplier }
  
  context "The Supplier class" do
    setup do
      @supplier = Factory(:supplier)
      @organisation = @supplier.organisation
    end
    
    should have_many(:financial_transactions).dependent(:destroy)
    # should belong_to :company
    should_validate_presence_of :organisation_type, :organisation_id
    
    should have_db_column :uid
    should have_db_column :url
    should have_db_column :name
    should have_db_column :failed_payee_search
    should have_db_column :total_spend
    should have_db_column :average_monthly_spend
    
    should 'belong to organisation polymorphically' do
      organisation = Factory(:council)
      assert_equal organisation, Factory(:supplier, :organisation => organisation).organisation
    end
    
    should 'belong to payee polymorphically' do
      payee = Factory(:company)
      assert_equal payee, Factory(:supplier, :payee => payee).payee
    end
    
    context "should have unmatched named_scope which" do
      setup do
        @payee = Factory(:company)
        @supplier_with_payee = Factory(:supplier, :payee => @payee)
      end
      
      should 'include suppliers without payees' do
        assert Supplier.unmatched.include?(@supplier)
      end
      
      should 'not include suppliers with payees' do
        assert !Supplier.unmatched.include?(@supplier_with_payee)
      end
    end
    
    should 'require either name or uid to be present' do
      invalid_supplier = Factory.build(:supplier, :name => nil, :uid => nil)
      assert !invalid_supplier.valid?
      assert_equal 'Either a name or uid is required', invalid_supplier.errors[:base]
      invalid_supplier.name = 'foo'
      assert invalid_supplier.valid?
      invalid_supplier.name = nil
      invalid_supplier.uid = '123'
      assert invalid_supplier.valid?
    end
    
    context 'when validating uniqueness of uid' do
      
      should 'scope to organisation' do
        @supplier.update_attribute(:uid, '123')
        another_supplier = Factory.build(:supplier, :uid => '123') # different org
        assert another_supplier.valid?
        another_supplier.organisation = @organisation
        assert !another_supplier.valid?
      end
      
      should 'allow nil' do
        another_supplier = Factory.build(:supplier, :organisation => @organisation)
        assert another_supplier.valid?
      end
    end
    
    context "when normalising title" do
      should "normalise title" do
        TitleNormaliser.expects(:normalise_company_title).with('foo bar')
        Supplier.normalise_title('foo bar')
      end
    end
  end
  
  context "An instance of the Supplier class" do
    setup do
      @supplier = Factory(:supplier)
    end

    should "alias name as title" do
      assert_equal @supplier.name, @supplier.title
    end
    
    should "use title when converting to_param" do
      @supplier.title = "some title-with/stuff"
      assert_equal "#{@supplier.id}-some-title-with-stuff", @supplier.to_param
    end

    context 'when saving' do
      
      should 'calculate total_spend' do
        @supplier.expects(:calculated_total_spend).returns(42.1)
        @supplier.save!
      end
      
      should 'update total_spend with calculated_total_spend' do
        @supplier.stubs(:calculated_total_spend).returns(42.1)
        @supplier.save!
        assert_equal 42.1, @supplier.reload.total_spend
      end
      
      should 'calculate average_monthly_spend' do
        @supplier.expects(:calculated_average_monthly_spend).returns(63.4)
        @supplier.save!
      end
      
      should 'update average_monthly_spend with calculated_average_monthly_spend' do
        @supplier.stubs(:calculated_average_monthly_spend).returns(63.4)
        @supplier.save!
        assert_equal 63.4, @supplier.reload.average_monthly_spend
      end
    end
    
    context 'after creating' do
      setup do
        @company = Factory(:company)
      end
      
      should 'try to match against company if company' do
        Supplier.any_instance.expects(:possible_payee)
        Factory(:supplier, :name => 'Foo company')
      end
      
      should 'and should associate with returned body' do
        Supplier.any_instance.expects(:possible_payee).returns(@company)
        supplier = Factory(:supplier, :name => 'Foo company')
        assert_equal @company, supplier.reload.payee
      end
      
    end
    
    context "when matching against existing possible payees" do
      context "and name is company-like" do
        setup do
          @supplier.name = 'Foo Ltd'
        end

        should "try to match against company" do
          Company.expects(:matches_title).with('Foo Ltd')
          @supplier.possible_payee
        end
      end
      
      context "and name is police authority like" do
        setup do
          @supplier.name = 'Foo Police Authority'
        end

        should "try to match against police authority" do
          PoliceAuthority.expects(:find_by_name).with('Foo Police Authority')
          @supplier.possible_payee
        end
      end
      
      context "and name is council-like" do
        setup do
          @supplier.name = 'Foo Council'
        end

        should "try to match against police authority" do
          Council.expects(:find_by_normalised_title).with('foo')
          @supplier.possible_payee
        end
      end
    end
    
    context "when finding and associating new company" do
      setup do
      end
      
      should 'search using CompaniesUtilities and supplier name' do
        CompanyUtilities::Client.any_instance.expects(:find_company_from_name).with(@supplier.name)
        @supplier.find_and_associate_new_company
      end
      
      context "and single company is returned" do
        setup do
          company_response = [{:status=>"Active", :company_number=>"06398324", :title=>"SPIKES CAVELL & COMPANY LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2007-10-15"}]
          CompanyUtilities::Client.any_instance.stubs(:find_company_from_name).returns(company_response)
        end
      
        should "create company" do
          assert_difference "Company.count", 1 do
            @supplier.find_and_associate_new_company
          end
        end
        
        should "associate company with supplier" do
          @supplier.find_and_associate_new_company
          assert company = @supplier.reload.payee
          assert_equal "SPIKES CAVELL & COMPANY LIMITED", company.title
          assert_equal "06398324", company.company_number
        end
      end
      
      context "and no company is returned" do
        setup do
          CompanyUtilities::Client.any_instance.stubs(:find_company_from_name) # => returns nil still
        end
      
        should "not create company" do
          assert_no_difference "Company.count" do
            @supplier.find_and_associate_new_company
          end
        end
        
        should "not associate company with supplier" do
          @supplier.find_and_associate_new_company
          assert_nil @supplier.reload.payee
        end
        
        should "mark supplier as failed_payee_search" do
          CompanyUtilities::Client.any_instance.expects(:find_company_from_name) # => returns nil still
          @supplier.find_and_associate_new_company
          assert @supplier.reload.failed_payee_search?
        end
        
        context "and supplier name has ampersand in it" do
          setup do
            @supplier.update_attribute(:title, 'Spikes Cavell & Company Ltd')
            @company_response = [{:status=>"Active", :company_number=>"06398324", :title=>"SPIKES CAVELL AND COMPANY LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2007-10-15"}]             
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name) # => returns nil
          end

          should "make second call replacing ampersand with 'and'" do
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name).with('Spikes Cavell and Company Ltd').returns(@company_response) # then returns company response
            @supplier.find_and_associate_new_company
          end

          should "create company from info returned in second call" do
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name).with('Spikes Cavell and Company Ltd').returns(@company_response) # then returns company response
            assert_difference "Company.count", 1 do
              @supplier.find_and_associate_new_company
            end
          end

          should "associate company with supplier" do
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name).with('Spikes Cavell and Company Ltd').returns(@company_response) # then returns company response
            @supplier.find_and_associate_new_company
            assert company = @supplier.reload.payee
            assert_equal "SPIKES CAVELL AND COMPANY LIMITED", company.title
            assert_equal "06398324", company.company_number
          end
          
          should "not create company if still no company" do
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name) # => returns nil still
            assert_no_difference "Company.count" do
              @supplier.find_and_associate_new_company
            end
          end
          
          should "mark supplier as failed_payee_search" do
            CompanyUtilities::Client.any_instance.expects(:find_company_from_name) # => returns nil still
            @supplier.find_and_associate_new_company
            assert @supplier.reload.failed_payee_search?
          end
          
        end
      end
      
      context "and several companies are returned" do
        setup do
          @supplier.update_attribute(:title, 'Spikes Cavell Analytic Ltd')
          company_response = [{:status=>"Active", :company_number=>"06398324", :title=>"SPIKES CAVELL & COMPANY LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2007-10-15"}, {:status=>"Active", :company_number=>"04917291", :title=>"SPIKES CAVELL ANALYTIC LIMITED", :company_type=>"Private Limited Company", :address_in_full=>"1 NORTHBROOK PLACE\nNEWBURY\nBERKSHIRE\nRG14 1DQ", :incorporation_date=>"2003-10-01"}]
          CompanyUtilities::Client.any_instance.stubs(:find_company_from_name).returns(company_response)
        end
      
        should "create company" do
          assert_difference "Company.count", 1 do
            @supplier.find_and_associate_new_company
          end
        end
        
        should "match company with matching normalised title" do
          @supplier.find_and_associate_new_company
          assert Company.find_by_company_number('04917291')
          assert !Company.find_by_company_number('06398324')
        end
        
      
        should "associate company with supplier" do
          @supplier.find_and_associate_new_company
          assert company = @supplier.reload.payee
          assert_equal "SPIKES CAVELL ANALYTIC LIMITED", company.title
          assert_equal "04917291", company.company_number
        end
        
        context "and no matching normalised title" do
          setup do
            @supplier.update_attribute(:title, 'Spikes Cavell Analytic')
          end
          
          should "not create company" do
            assert_no_difference "Company.count" do
              @supplier.find_and_associate_new_company
            end
          end
          
          should "not associate company with supplier" do
            @supplier.find_and_associate_new_company
            assert_nil @supplier.payee
          end
        end
      end
      
    end
    
    context 'when assigning company_number' do
      setup do
        @company = Factory(:company)
      end
      
      should 'match or create company from company number' do
        Company.expects(:match_or_create_from_company_number).with('123456')
        @supplier.company_number = '123456'
      end
      
      should 'associate returned company with given company number' do
        Company.stubs(:match_or_create_from_company_number).returns(@company)
        @supplier.company_number = '123456'
        assert_equal @company, @supplier.reload.payee
      end
      
      # context "and company with given number already exists" do
      #   setup do
      #     @old_company_count = Company.count
      #     @supplier.company_number = @existing_company.company_number
      #   end
      #   
      #   should 'not create new company' do
      #     assert_equal @old_company_count, Company.count
      #   end
      #   
      #   
      # end
      # 
      # context "and company not found" do
      #   
      #   should "create new company with given id" do
      #     assert_difference "Company.count", 1 do
      #        @supplier.company_number = '012345'
      #     end
      #     assert_equal '012345', @supplier.payee.company_number
      #   end
      # end
      
    end
        
    context "when returning associateds" do
      setup do
        @payee = Factory(:company)
        @supplier.update_attribute(:payee, @payee)
        @sibling_supplier = Factory(:supplier, :payee => @payee)
        @sole_supplier = Factory(:supplier, :payee => Factory(:company))
      end

      should "return suppliers belong to same company" do
        assert_equal [@sibling_supplier], @supplier.associateds
      end
      
      should "return empty array if no company for supplier" do
        assert_equal [], Factory(:supplier).associateds
      end
      
      should "return empty array if no other suppliers for company" do
        assert_equal [], @sole_supplier.associateds
      end
      
    end
    
    context "when calculating total_spend" do
      setup do
        @another_supplier = Factory(:supplier)
        @financial_transaction_1 = Factory(:financial_transaction, :supplier => @supplier, :value => 123.45)
        @financial_transaction_2 = Factory(:financial_transaction, :supplier => @supplier, :value => -32.1)
        @financial_transaction_3 = Factory(:financial_transaction, :supplier => @supplier, :value => 22.1)
        @unrelated_financial_transaction = Factory(:financial_transaction, :supplier => @another_supplier, :value => 22.1)
      end

      should "sum all financial transactions for supplier" do
        assert_in_delta (123.45 - 32.1 + 22.1), @supplier.calculated_total_spend, 2 ** -10
      end
    end

    context "when calculating average_monthly_spend" do
      setup do
        @financial_transaction_1 = Factory(:financial_transaction, :supplier => @supplier, :value => 123.45, :date => 11.months.ago)
        @financial_transaction_2 = Factory(:financial_transaction, :supplier => @supplier, :value => -32.1, :date => 3.months.ago)
        @financial_transaction_3 = Factory(:financial_transaction, :supplier => @supplier, :value => 22.1, :date => 5.months.ago)
      end

      should "divide calculated_total_spend by number of months" do
        assert_in_delta (123.45 - 32.1 + 22.1)/(8+1), @supplier.reload.calculated_average_monthly_spend, 2 ** -10 
      end
      
      should "return nil when no transactions" do
        assert_nil Factory(:supplier).calculated_average_monthly_spend
      end
    end
    
    context 'and when updating supplier details' do
      
      setup do
        @new_details = SupplierDetails.new(:url => 'http://foo.com', :company_number => '01234', :wikipedia_url => 'http://en.wikipedia.org/wiki/foo')
      end
      
      context "in general" do

        should "create new company" do
          assert_difference "Company.count", 1 do
            @supplier.update_supplier_details(@new_details)
          end
        end
        
        should "associate new company with supplier" do
          @supplier.update_supplier_details(@new_details)
          assert_kind_of Company, c = @supplier.reload.payee
          assert_equal "00001234", c.company_number
        end
        
        should "assign url and wikipedia_url to new company" do
          @supplier.update_supplier_details(@new_details)
          assert_equal 'http://foo.com', @supplier.payee.url
          assert_equal 'http://en.wikipedia.org/wiki/foo', @supplier.payee.wikipedia_url
        end
        
        should "return true" do
          assert @supplier.update_supplier_details(@new_details)
        end
        
      end
      
      
      context "when company with given company number already exists" do
        setup do
          @existing_company = Factory(:company, :company_number => '00001234')
        end

        should "not create new company" do
          assert_no_difference "Company.count" do
            @supplier.update_supplier_details(@new_details)
          end
        end

        should "associate existing company with supplier" do
          @supplier.update_supplier_details(@new_details)
          assert_equal @existing_company, @supplier.reload.payee
        end
        
        # should "assign url and wikipedia_url to new company" do
        #   @supplier.update_supplier_details(@new_details)
        #   assert_equal 'http://foo.com', @existing_company.url
        #   assert_equal 'http://en.wikipedia.org/wiki/foo', @existing_company.wikipedia_url
        # end
        
        should "return true" do
          assert @supplier.update_supplier_details(@new_details)
        end
      end
      
      context 'when missing essential data' do
        should 'return false' do
          assert !@supplier.update_supplier_details(SupplierDetails.new(:company_number => ''))
        end
      end
      # should 'set website if not set' do
      #   @supplier.update_supplier_details(@new_details)
      #   assert_equal 'http://foo.com', @supplier.reload.url
      # end
      # 
      # should 'update website if set' do
      #   @supplier.update_attribute(:url, 'htp://bar.com')
      #   @supplier.update_supplier_details(@new_details)
      #   assert_equal 'http://foo.com', @supplier.reload.url
      # end
      # 
      should 'assign company with (normalised version of) given company number' do
        @supplier.update_supplier_details(@new_details)
        assert_equal '00001234', @supplier.reload.payee.company_number
      end
      
      should 'not delete existing url if nil given for url' do
        @supplier.update_attribute(:url, 'http://bar.com')
        @supplier.update_supplier_details(SupplierDetails.new(:url => nil))
        assert_equal 'http://bar.com', @supplier.reload.url
      end
      
      should 'not delete existing company if nil given for company_number' do
        @company = Factory(:company)
        @supplier.update_attribute(:payee, @company)
        @supplier.update_supplier_details(SupplierDetails.new(:company_number => nil))
        assert_equal @company, @supplier.reload.payee
      end
      
    end

  end
end
