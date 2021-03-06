require File.expand_path('../../test_helper', __FILE__)

class MainControllerTest < ActionController::TestCase
  context "on GET to :index" do
    setup do
      @council1 = Factory(:council)
      @council2 = Factory(:another_council)
      @member = Factory(:member, :council => @council1)
      @committee = Factory(:committee, :council => @council1)
      
      @meeting = Factory(:meeting, :council => @council1, :committee => @committee)
      @news_item = Factory(:feed_entry)
      @council_news_item = Factory(:feed_entry, :feed_owner => @council1)
      @future_meeting = Factory(:meeting, :date_held => 3.days.from_now.to_date, :council => @council1, :committee => @committee)

      get :index
    end
  
    should assign_to :councils
    should respond_with :success
    should render_template :index
    should_not set_the_flash
    
    should "have basic title" do
      assert_select "title", /Openly Local.+Local Government/
    end
    
    should "list latest parsed councils" do
      assert_select "#latest_councils" do
        assert_select "li", 1 do # only #council1 has members and therefore is considered parsed
          assert_select "a", @council1.title
        end
      end
    end
    
    should "list latest forthoming meetings" do
      assert_select "#forthcoming_meetings" do
        assert_select "li", 1 do 
          assert_select "a", /#{@meeting.title}/
        end
      end
    end
    
    should "list latest latest councillors" do
      assert_select "#latest_councillors" do
        assert_select "li", 1 do 
          assert_select "a", /#{@member.title}/
        end
      end
    end
    
    should "show latest news from blog" do
      assert_select "#site_news" do
        assert_select "h4", /#{@news_item.title}/
      end
    end
    
    should "not show other feed items" do
      assert_select "#site_news h4", :text => /#{@council_news_item.title}/, :count => 0
    end
  end
end
