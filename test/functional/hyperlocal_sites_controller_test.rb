require 'test_helper'

class HyperlocalSitesControllerTest < ActionController::TestCase
  def setup
    @hyperlocal_site = Factory(:approved_hyperlocal_site, :email => 'info@hyperlocal.com')
    @another_hyperlocal_site = Factory(:approved_hyperlocal_site, :country => 'Scotland', :title => "Second Hyperlocal Site")
    @unapproved_hyperlocal_site = Factory(:hyperlocal_site)
  end

  # index test
  context "on GET to :index" do
    context "with basic request" do
      setup do
        get :index
      end

      should_assign_to(:hyperlocal_sites) { [@hyperlocal_site, @another_hyperlocal_site]}
      should_respond_with :success
      should_render_template :index
      should "list only approved hyperlocal sites" do
        assert_select "li a", @hyperlocal_site.title
        assert_select "li a", :text => @unapproved_hyperlocal_site.title, :count => 0
      end

      should "show share block" do
        assert_select "#share_block"
      end

      should "show api block" do
        assert_select "#api_info"
      end
      
      should 'show title' do
        assert_select "title", /Hyperlocal Sites/i
      end
      
      should 'group by country' do
        assert_select "li.country", /Scotland/ do
          assert_select "ul li a", @another_hyperlocal_site.title
        end
      end
      
      should "enable google maps" do
        assert assigns(:enable_google_maps)
      end
      
      should "show rss feed link" do
        assert_select "link[rel='alternate'][type='application/rss+xml'][href='http://test.host/hyperlocal_sites.rss']"
      end
    end
    
    context "with request with location" do
      setup do
        @hyperlocal_site.stubs(:distance).returns(5)
        @another_hyperlocal_site.stubs(:distance).returns(9.2)
        @sites = [@hyperlocal_site, @another_hyperlocal_site]
        Geokit::LatLng.stubs(:normalize).returns(Geokit::LatLng.new)
        HyperlocalSite.stubs(:find).returns(@sites)
        
        get :index, :location => '100 Spear st, San Francisco, CA'
      end

      should_assign_to(:hyperlocal_sites) { }
      should_respond_with :success
      should_render_template :index

      should 'show location in title' do
        assert_select "title", /100 Spear st, San Francisco, CA/i
      end
      
      should 'show distance from location' do
        assert_select "ul li", /#{@another_hyperlocal_site.title}/ do
          assert_select "li", /9.2 miles/
        end
      end
      
      should "enable google maps" do
        assert assigns(:enable_google_maps)
      end
    end

    context "with xml request" do
      setup do
        get :index, :format => "xml"
      end

      should_assign_to(:hyperlocal_sites) { [@hyperlocal_site, @another_hyperlocal_site] }
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/xml'
      should "not include email address" do
        assert_select "email", false
      end
    end
    
    context "with json requested" do
      setup do
        get :index, :format => "json"
      end
  
      should_assign_to(:hyperlocal_sites) {  [@hyperlocal_site, @another_hyperlocal_site] }
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/json'
      should "not include email address" do
        assert_no_match /email\:/, @response.body
      end
    end
    
    context "with rss requested" do
      setup do
        HyperlocalSite.record_timestamps = false # update timestamp without triggering callbacks
        @hyperlocal_site.update_attributes(:distance_covered => 10.0, :created_at => 2.hours.ago)
        HyperlocalSite.record_timestamps = true # update timestamp without triggering callbacks
        get :index, :format => "rss"
      end
      
      should_assign_to(:hyperlocal_sites) {  [@hyperlocal_site, @another_hyperlocal_site] }
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/rss+xml'
      should "have title " do
        assert_select "title", "Latest UK Hyperlocal Sites"
      end
      should "list hyperlocal sites" do
        assert_select "item", 2 do
          assert_select "title", @hyperlocal_site.title
          assert_select "link", "http://test.host/hyperlocal_sites/#{@hyperlocal_site.to_param}"
          assert_match /georss:point>#{@hyperlocal_site.lat} #{@hyperlocal_site.lng}/, @response.body
          assert_match /georss:radius>#{@hyperlocal_site.distance_covered*1604.34}/, @response.body
        end
      end
      should "list newest hyperlocal site first" do
        assert_match /#{@another_hyperlocal_site.title}.+#{@hyperlocal_site.title}/m, @response.body
      end
    end
  end
    
  # custom_search tests for index action
  context "on GET to :custom search" do
    should "generate routing for custom search" do
      assert_routing("hyperlocal_sites/custom_search.xml", {:controller => "hyperlocal_sites", :action => "index", :custom_search => true, :format => "xml"})
    end
    
    context "in general should" do
      setup do
        get :index, :custom_search => true, :format => "xml"
      end
      
      should_assign_to(:hyperlocal_sites) { [@hyperlocal_site, @another_hyperlocal_site] }
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/xml'
      
      should "generate custom search title" do
        assert_xml_select 'CustomSearchEngine>Title' do
          assert_select "Title", /OpenlyLocal UK Hyperlocal/
        end
      end
      
      should "generate custom search info" do
        assert_xml_select "Annotations>Annotation", 2 do
          assert_select "Annotation[about='#{@hyperlocal_site.url}/*']"
          assert_select "Label[name='openlylocal_cse_hyperlocal_sites']"
        end
      end
    end
    
    # custom_search_results tests
    context "on GET to :custom_search_results" do
      should "generate routing for custom_search_results" do
        assert_routing("hyperlocal_sites/custom_search_results", {:controller => "hyperlocal_sites", :action => "custom_search_results"})
      end

      context "in general should" do
        setup do
          get :custom_search_results
        end
        
        should_respond_with :success
        should_render_with_layout
        should "show div for results" do
          assert_select "div#cse-search-results"
        end  
      end  
    end
  end  
  
  # show test
  context "on GET to :show" do

    context "with basic request" do
      setup do
        get :show, :id => @hyperlocal_site.id
      end

      should_assign_to :hyperlocal_site
      should_respond_with :success
      should_render_template :show

      should "include hyperlocal site in page title" do
        assert_select "title", /#{@hyperlocal_site.title}/
      end

      should "include phrase 'hyperlocal sites' in page title" do
        assert_select "title", /hyperlocal sites/i
      end

      should "list hyperlocal site attributes" do
        assert_select '.attributes dd', /#{@hyperlocal_site.url}/
      end
      
      should "not list email address" do
        assert_select ".attributes", :text => /#{@hyperlocal_site.email}/, :count => 0
      end
      
      should "enable google maps" do
        assert assigns(:enable_google_maps)
      end
      
      should "not nofollow link to website" do
        assert_select "a[rel=nofollow]", :text => @hyperlocal_site.url, :count => 0
      end
    end
    
    context "with unapproved site" do
      setup do
        get :show, :id => @unapproved_hyperlocal_site.id
      end
      
      should "nofollow link to website" do
        assert_select "a[rel=nofollow]", @unapproved_hyperlocal_site.url
      end
    end
    
    context "when hyperlocal_site belongs to hyperlocal_group" do
      setup do
        @hyperlocal_group = Factory(:hyperlocal_group)
        @hyperlocal_group.hyperlocal_sites << @hyperlocal_site
        get :show, :id => @hyperlocal_site.id
      end
      
      should "list hyperlocal group" do
        assert_select '.attributes dd a', @hyperlocal_group.title
      end
      
    end
  end

  # new test
  context "on GET to :new" do
    setup do
      get :new
    end
  
    should_assign_to(:hyperlocal_site)
    should_respond_with :success
    should_render_template :new
  
    should "show form" do
      assert_select "form#new_hyperlocal_site"
    end
    
    should "show possible hyperlocal groups in select box" do
      assert_select "select#hyperlocal_site_hyperlocal_group_id"
    end
    
    should "show possible platforms in select box" do
      assert_select "select#hyperlocal_site_platform"
    end
    
    should "not show approved tickbox" do
      assert_select "#hyperlocal_site_approved", false
    end
    
    should "enable google maps" do
      assert assigns(:enable_google_maps)
    end
  end  
  
  # create test
   context "on POST to :create" do
     setup do
       @attributes = Factory.attributes_for(:hyperlocal_site)
     end
    
    context "with valid params" do
       setup do
         stub_authentication
         post :create, :hyperlocal_site => @attributes
       end
     
       should_change "HyperlocalSite.count", :by => 1
       should_assign_to :hyperlocal_site
       should_redirect_to( "the hyperlocal_sites index page") { hyperlocal_sites_url }
       should_set_the_flash_to /Successfully submitted/i
        
       should "set approved flag to false by default" do
         assert !HyperlocalSite.find_by_title(@attributes[:title]).approved?
       end
     end
     
     context "with invalid params" do
       setup do
         stub_authentication
         post :create, :hyperlocal_site => {:title => "New Hyperlocal Site"}
       end
     
       should_not_change "HyperlocalSite.count"
       should_assign_to :hyperlocal_site
       should_render_template :new
       should_not_set_the_flash
     end
  
     context "with approved_flag set to true" do
       setup do
         stub_authentication
         post :create, :hyperlocal_site => @attributes.merge(:approved => "1")
       end
     
       should "not set approved flag to true" do
         assert !HyperlocalSite.find_by_title(@attributes[:title]).approved?
       end
     end
  
   end  
  
  # edit tests
  context "on get to :edit a hyperlocal site without auth" do
    setup do
      get :edit, :id => @hyperlocal_site.id
    end

    should_respond_with 401
  end

  context "on get to :edit a hyperlocal site" do
    setup do
      stub_authentication
      get :edit, :id => @hyperlocal_site.id
    end

    should_assign_to :hyperlocal_site
    should_respond_with :success
    should_render_template :edit
    should_not_set_the_flash
    should "display a form" do
     assert_select "form#edit_hyperlocal_site_#{@hyperlocal_site.id}"
    end

    should "show approved checkbox" do
      assert_select "#hyperlocal_site_approved"
    end
    
    should "show button to delete" do
      assert_select "form.button-to[action='/hyperlocal_sites/#{@hyperlocal_site.to_param}']"
    end
    
    should "enable google maps" do
      assert assigns(:enable_google_maps)
    end
  end

  # update tests
  context "on PUT to :update without auth" do
    setup do
      put :update, { :id => @hyperlocal_site.id,
                     :hyperlocal_site => { :title => "New title"}}
    end

    should_respond_with 401
  end

  context "on PUT to :update" do
    context "in general" do
      setup do
        stub_authentication
        put :update, { :id => @hyperlocal_site.id,
                       :hyperlocal_site => { :title => "New title"}}
      end

      should_assign_to :hyperlocal_site
      should_redirect_to( "the show page for hyperlocal_site") { hyperlocal_site_url(@hyperlocal_site.reload) }
      should_set_the_flash_to /Successfully updated/

      should "update hyperlocal_site" do
        assert_equal "New title", @hyperlocal_site.reload.title
      end
    end
    
    context "when approved is set to true" do
      setup do
        stub_authentication
        put :update, { :id => @hyperlocal_site.id,
                       :hyperlocal_site => { :approved => "1"}}
      end

      should "approve hyperlocal_site" do
        assert @hyperlocal_site.reload.approved?
      end
    end
    
    context "when approved is set to true" do
      setup do
        @hyperlocal_site.update_attribute(:approved, true)
        stub_authentication
        put :update, { :id => @hyperlocal_site.id,
                       :hyperlocal_site => { :approved => "0"}}
      end

      should "disapprove hyperlocal_site" do
        assert !@hyperlocal_site.reload.approved?
      end
    end
  end
  
  # delete tests
  context "on delete to :destroy a hyperlocal_site without auth" do
    setup do
      delete :destroy, :id => @hyperlocal_site.id
    end

    should_respond_with 401
  end

  context "on delete to :destroy a hyperlocal_site" do

    setup do
      stub_authentication
      delete :destroy, :id => @hyperlocal_site.id
    end

    should "destroy hyperlocal_site" do
      assert_nil HyperlocalSite.find_by_id(@hyperlocal_site.id)
    end
    should_redirect_to ( "the hyperlocal_sites index page") { hyperlocal_sites_url }
    should_set_the_flash_to /Successfully destroyed/
  end
    
end
