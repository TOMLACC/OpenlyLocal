require 'test_helper'

class DocumentsControllerTest < ActionController::TestCase
  def setup
    #set up doc owner
    @committee = Factory(:committee)
    @council = @committee.council
    @doc_owner = Factory(:meeting, :council => @committee.council, :committee => @committee)
    @document = Factory(:document, :document_owner => @doc_owner)
    @another_document = Factory(:document, :document_owner => @doc_owner)
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
  
      should_assign_to(:council) { @council } 
      should_assign_to(:documents) { [@document, @another_document] }
      should_respond_with :success
      should_render_template :index
      should_respond_with_content_type 'text/html'
      
      should "list council documents" do
        assert_select "#documents ul a", @document.extended_title
      end
      
      should "have title" do
        assert_select "title", /Committee documents/
      end

    end
        
    
    context "with xml requested" do
      setup do
        get :index, :council_id => @council.id, :format => "xml"
      end
      
      should_assign_to(:council) { @council } 
      should_assign_to(:documents) { [@document, @another_document] }
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/xml'
    end
    
    context "with json requested" do
      setup do
        get :index, :council_id => @council.id, :format => "json"
      end
      
      should_assign_to(:council) { @council } 
      should_assign_to(:documents) { [@document, @another_document] }
      should_respond_with :success
      should_render_without_layout
      should_respond_with_content_type 'application/json'
    end
    
    # context "with rss requested" do
    #   setup do
    #     get :index, :council_id => @council.id, :format => "rss"
    #   end
    #   
    #   should_assign_to(:council) { @council } 
    #   should_assign_to(:documents) { [@document, @another_document] }
    #   should_respond_with :success
    #   should_render_without_layout
    #   should_respond_with_content_type 'text/calendar'
    # end
    
  end

  context "on GET to :show" do
    setup do
      get :show, :id => @document.id
    end
  
    should_assign_to(:document) { @document}
    should_respond_with :success
    should_render_template :show
    
    should_assign_to(:council) { @council }
  
    should "show document title in title" do
      assert_select "title", /#{@document.title}/
    end
    
    should "show body of document" do
      assert_select "#document_body", @document.body
    end
        
  end  
end
