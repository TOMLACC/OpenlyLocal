require File.expand_path('../../test_helper', __FILE__)

class SuppliersControllerTest < ActionController::TestCase
  def setup
    @supplier = Factory(:supplier)
    @organisation = @supplier.organisation
    @another_supplier = Factory(:supplier, :name => 'another supplier')
    @another_supplier_same_org = Factory(:supplier, :name => 'Another supplier', :organisation => @organisation)
    @financial_transaction = Factory(:financial_transaction, :supplier => @supplier, :value => 42, :date => 3.day.ago)
    @big_financial_transaction = Factory(:financial_transaction, :supplier => @supplier, :value => 10000, :date => 2.days.ago)
    [@supplier, @another_supplier, @another_supplier_same_org].each{ |s| s.update_attribute(:spending_stat, SpendingStat.new); s.spending_stat.perform }#can't sort without sppending_stat
  end
  
  # index test
  context "on GET to :index" do
    
    context "with basic request" do
      setup do
        get :index
      end
      
      should assign_to(:suppliers)
      should respond_with :success
      
      should "show title" do
        assert_select "title", /suppliers/i
      end
      
      should 'list suppliers' do
        assert_select 'a.supplier_link', @supplier.name
      end
      
      should 'order by name' do
        assert_equal @another_supplier_same_org, assigns(:suppliers).first
      end
      
      should 'show link to sort by total_spend' do
        assert_select 'a.sort', /total spend/i
      end
            
    end
    
    context 'when sorting by total_spend' do
      setup do
        get :index, :order => 'total_spend'
      end
      
      should assign_to(:suppliers)
      should respond_with :success
      
      
      should 'order by total_spend' do
        assert_equal @supplier, assigns(:suppliers).first
      end
            
      should 'show link to sort by name' do
        assert_select 'a.sort', /name/i
      end
            
    end
    
    context 'when searching by name' do
      setup do
        get :index, :name_filter => 'Anoth'
      end
      
      should assign_to(:suppliers)
      should respond_with :success
      
      
      should 'return only those matching filter' do
        assert assigns(:suppliers).include?(@another_supplier_same_org)
        assert !assigns(:suppliers).include?(@supplier)
      end
                        
    end
    
    context 'when enough results' do
      setup do
        30.times { Factory(:supplier).create_spending_stat }
      end
      
      context 'in general' do
        setup do
          get :index
        end
        
        should 'show pagination links' do
          assert_select "div.pagination"
        end
        
        should 'show page number in title' do
          assert_select "title", /page 1/i
        end
      end
      
      context "with xml requested" do
        setup do
          get :index, :format => "xml"
        end

        should assign_to(:suppliers)
        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/xml'

        should "include suppliers" do
          assert_select "suppliers>supplier>id"
        end

        should_eventually "include organisation" do
          assert_select "suppliers>supplier>organisation>id"
        end

        should 'include pagination info' do
          assert_select "suppliers>total-entries"
        end
      end
      
      context "with json requested" do
        setup do
          get :index, :format => "json"
        end

        should assign_to(:suppliers)
        should respond_with :success
        should_not render_with_layout
        should respond_with_content_type 'application/json'
        
        should 'include pagination info' do
          assert_match %r(total_entries.+33), @response.body
          assert_match %r(per_page), @response.body
          assert_match %r(page.+1), @response.body
        end
      end
      
    end
    
    context "with basic request and organisation details" do
      setup do
        
      end
      context "in general" do
        setup do
          get :index, :organisation_id => @organisation.id, :organisation_type => @organisation.class.to_s
        end

        should assign_to(:suppliers)
        should assign_to(:organisation) { @organisation }
        should respond_with :success

        should "show title" do
          assert_select "title", /suppliers/i
        end

        should 'list suppliers' do
          assert_select 'a.supplier_link', @supplier.name
        end
        
        should 'order by name' do
          assert_equal @another_supplier_same_org, assigns(:suppliers).first
        end

        should 'show link to sort by total_spend' do
          assert_select 'a.sort', /total spend/i
        end
        
        should 'show overview of spending' do
          assert_select '#overview', /suppliers/i
        end
      end
      
      context 'when sorting by total_spend' do
        setup do
          get :index, :organisation_id => @organisation.id, :organisation_type => @organisation.class.to_s, :order => 'total_spend'
        end

        should assign_to(:suppliers)
        should respond_with :success


        should 'order by total_spend' do
          assert_equal @supplier, assigns(:suppliers).first
        end

        should 'show link to sort by name' do
          assert_select 'a.sort', /name/i
        end

      end
         
    end    
    
  end
  
  context "on GET to :show" do
    context "in general" do
      setup do
        get :show, :id => @supplier.id
      end

      should assign_to(:supplier) { @supplier}
      should respond_with :success
      should render_template :show
      should assign_to(:organisation) { @organisation }

      should "show supplier name in title" do
        assert_select "title", /#{@supplier.title}/
      end

      should "show organisation name in title" do
        assert_select "title", /#{@supplier.organisation.title}/
      end

      should "list financial transactions" do
        assert_select "#financial_transactions .value", /#{@financial_transaction.value}/
      end
      
      should "show link to add company details" do
        assert_select 'a[href*=user_submissions/new]', /add/i
      end
      
      should "sort in date order, oldest first" do
        assert_equal @financial_transaction, assigns(:financial_transactions).first
      end
      
      should "show summary of spending" do
        assert_select '#supplier_dashboard'
      end
      
      should "show spend_by_month graph" do
        assert_select "#spend_by_month"
      end
    end
    
    context "when value order given" do
      setup do
        get :show, :id => @supplier.id, :order => 'value'
      end

      should "sort with highest value first" do
        assert_equal @big_financial_transaction, assigns(:financial_transactions).first
      end
    end
    
    context "when supplier is company" do
      setup do
        @company = Factory(:company, :company_number => '12345')
        @another_supplying_relationship = Factory(:supplier, :payee => @company)
        @supplier.update_attribute(:payee, @company)
        get :show, :id => @supplier.id
      end

      should assign_to(:supplier) { @supplier}
      should respond_with :success
      should render_template :show
      should assign_to(:organisation) { @organisation }

      should "show company details" do
        assert_select ".company_number", /12345/
      end

      should "link to company" do
        assert_select "#payee_info a[href*=/companies/#{@company.id}]"
      end

      should "list other councils supplied by company" do
        assert_select "#other_supplying_relationships a", /#{@another_supplying_relationship.organisation.title}/
      end
      
      should "not show link to add company details" do
        assert_select 'a[href*=user_submissions/new]', false
      end
    end
    
    context "when supplier is a council" do
      setup do
        @council = Factory(:council)
        @another_supplying_relationship = Factory(:supplier, :payee => @council)
        @supplier.update_attribute(:payee, @council)
        get :show, :id => @supplier.id
      end

      should assign_to(:supplier) { @supplier}
      should respond_with :success
      should render_template :show
      should assign_to(:organisation) { @organisation }

      should "council details" do
        assert_select ".authority_type", /#{@council.authority_type}/
      end

      should "link to company" do
        assert_select "#payee_info a[href*=/councils/#{@council.id}]"
      end

      should "list other councils supplied by council" do
        assert_select "#other_supplying_relationships a", /#{@another_supplying_relationship.organisation.title}/
      end
    end
    
    context "when supplier is a police_authority" do
      setup do
        @police_authority = Factory(:police_authority)
        @another_supplying_relationship = Factory(:supplier, :payee => @police_authority)
        @supplier.update_attribute(:payee, @police_authority)
        get :show, :id => @supplier.id
      end

      should assign_to(:supplier) { @supplier}
      should respond_with :success
      should render_template :show
      should assign_to(:organisation) { @organisation }

      should "police_authority details" do
        assert_select ".authority_for", /#{@police_authority.police_force.title}/
      end

      should "link to company" do
        assert_select "#payee_info a[href*=/police_authorities/#{@police_authority.id}]"
      end

      should "list other councils supplied by council" do
        assert_select "#other_supplying_relationships a", /#{@another_supplying_relationship.organisation.title}/
      end
    end
    
    context "when supplier is charity" do
      setup do
        @charity = Factory(:charity, :charity_number => 'cn12345')
        @another_supplying_relationship = Factory(:supplier, :payee => @charity)
        @supplier.update_attribute(:payee, @charity)
        get :show, :id => @supplier.id
      end

      should assign_to(:supplier) { @supplier}
      should respond_with :success
      should render_template :show
      should assign_to(:organisation) { @organisation }

      should "show charity details" do
        assert_select ".charity_number", /cn12345/
      end
    end

    context "when supplier is entity" do
      setup do
        @entity = Factory(:entity, :sponsoring_organisation => 'Dept Foo')
        @another_supplying_relationship = Factory(:supplier, :payee => @entity)
        @supplier.update_attribute(:payee, @entity)
        get :show, :id => @supplier.id
      end

      should assign_to(:supplier) { @supplier}
      should respond_with :success
      should render_template :show
      should assign_to(:organisation) { @organisation }

      should "show entity details" do
        assert_select ".sponsoring_organisation"
      end
    end
  end  

  context "with xml requested" do
    setup do
      @company = Factory(:company)
      @supplier.update_attribute(:payee, @company)
      get :show, :id => @supplier.id, :format => "xml"
    end

    should assign_to(:supplier) { @supplier }
    should respond_with :success
    should_not render_with_layout
    should respond_with_content_type 'application/xml'
    should "include company" do
      assert_select "supplier>payee>id", "#{@company.id}"
    end
    should "include financial_transactions" do
      assert_select "supplier>financial-transactions>financial-transaction>id", "#{@financial_transaction.id}"
    end
  end

  context "with json requested" do
    setup do
      get :show, :id => @supplier.id, :format => "json"
    end

    should assign_to(:supplier) { @supplier }
    should respond_with :success
    should_not render_with_layout
    should respond_with_content_type 'application/json'
    should "include financial_transactions" do
      assert_match /supplier\":.+financial_transactions\":.+id\":#{@financial_transaction.id}/, @response.body
    end
  end

end
