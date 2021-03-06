require File.expand_path('../../test_helper', __FILE__)

class DocumentsControllerTest < ActionController::TestCase
  def setup
    #set up doc owner
    @committee = Factory(:committee)
    @council = @committee.council
    @doc_owner = Factory(:meeting, :council => @committee.council, :committee => @committee)
    @document = Factory(:document, :document_owner => @doc_owner)
    @another_document = Factory(:document, :document_owner => @doc_owner, :raw_body => "some different foobar text")
    @ac_committee = Factory(:committee, :council => Factory(:another_council))
    @ac_meeting = Factory(:meeting, :council => @ac_committee.council, :committee => @ac_committee)
    @ac_document = Factory(:document, :document_owner => @ac_meeting)
  end
  
  # index tests
  context "on GET to :index for council" do
    
    context "with basic request" do
      setup do
        get :index, :council_id => @council.id
      end
  
      should assign_to(:council) { @council } 
      should assign_to(:documents) { [@document, @another_document] }
      should respond_with :success
      should render_template :index
      should respond_with_content_type 'text/html'
      
      should "list council documents" do
        assert_select "#documents ul a", @document.extended_title
      end
      
      should "have title" do
        assert_select "title", /Committee documents/
      end

      should "have search box" do
        assert_select "form#document_search" do
          assert_select "input#term"
          assert_select "input[type='hidden'][value=#{@council.id}]#council_id"
        end
      end
      
      should "show rss feed link" do
        assert_select "link[rel='alternate'][type='application/rss+xml'][href='http://test.host/documents.rss?council_id=#{@council.id}']"
      end
    end
        
    context "and search term given" do
      setup do
        get :index, :council_id => @council.id, :term => "foobar"
      end
      
      should assign_to(:documents) { [@another_document] }
      should respond_with :success
      
      should "have title" do
        assert_select "title", /Committee documents with 'foobar'/
      end

    end
    
    context "with xml requested" do
      setup do
        get :index, :council_id => @council.id, :format => "xml"
      end
      
      should assign_to(:council) { @council } 
      should assign_to(:documents) { [@document, @another_document] }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/xml'
      should "return basic attributes only" do
        assert_select "document>title"
        assert_select "document>url"
        assert_select "document>openlylocal-url"
        assert_select "document>body", false
      end
    end
    
    context "with json requested" do
      setup do
        get :index, :council_id => @council.id, :format => "json"
      end
      
      should assign_to(:council) { @council } 
      should assign_to(:documents) { [@document, @another_document] }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/json'
    end
    
    context "with rss requested" do
      setup do
        get :index, :council_id => @council.id, :format => "rss"
      end
      
      should assign_to(:council) { @council } 
      should assign_to(:documents) { [@document, @another_document] }
      should respond_with :success
      should_not render_with_layout
      should respond_with_content_type 'application/rss+xml'
      should "have title " do
        assert_select "title", "#{@council.title}: Committee documents"
      end
      should "list documents" do
        assert_select "item", 2 do
          assert_select "title", @document.title
          assert_select "link", "http://test.host/documents/#{@document.to_param}"
        end
      end
    end
    
  end

  context "on GET to :show" do
    setup do
      get :show, :id => @document.id
    end
  
    should assign_to(:document) { @document}
    should respond_with :success
    should render_template :show
    should assign_to(:council) { @council }
  
    should "show document title in title" do
      assert_select "title", /#{@document.title}/
    end
    
    should "show body of document" do
      assert_select "#document_body", @document.body
    end
    
    should "show link to other documents" do
      assert_select "p.extra_info a[href='/documents?council_id=#{@council.id}']", /other committee documents/i
    end 
  end  
  
  context "with xml requested" do
    setup do
      get :show, :id => @document.id, :format => "xml"
    end
    
    should assign_to(:document) { @document}
    should respond_with :success
    should_not render_with_layout
    should respond_with_content_type 'application/xml'
    should "return full attributes only" do
      assert_select "document>title"
      assert_select "document>url"
      assert_select "document>openlylocal-url"
      assert_select "document>body"
    end
  end
  
  context "with json requested" do
    setup do
      get :show, :id => @document.id, :format => "json"
    end
    
    should assign_to(:document) { @document}
    should respond_with :success
    should_not render_with_layout
    should respond_with_content_type 'application/json'
  end
  
end
