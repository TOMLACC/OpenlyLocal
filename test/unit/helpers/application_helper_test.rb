require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase

  context "attribute_tag helper method" do

    should "return nil by default" do
      assert_nil attribute_tag
    end

    should "return div tag using key as attrib name and value as value" do
      assert_dom_equal "<dt class=\"foo_bar\">Foo Bar</dt> <dd>some value</dd>", attribute_tag(:foo_bar, "some value")
    end

    should "return nil if value is nil" do
      assert_nil attribute_tag(:foo_bar, nil)
    end

    should "return nil if value is blank" do
      assert_nil attribute_tag(:foo_bar, "")
    end
  end

  context "link_for helper method" do

    should "return nil by default" do
      assert_nil link_for
    end

    should "return link for item with object title for link text" do
      obj = stale_factory_object(:committee) # poss better way of testing this. obj can be any ActiveRecord obj
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), link_for(obj)
    end

    should "escape object's title" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" )
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link"), link_for(obj)
    end

    should "pass on options" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" )
      assert_dom_equal link_to(h(obj.title), obj, :foo => "bar", :class => "committee_link"), link_for(obj, :foo => "bar")
    end

    should "leave options hash untouched" do
      obj = stale_factory_object(:committee)
      h = {:text => "bar", :class => "foo", :extended => true, :basic => true}
      old_h = h.clone
      link_for(obj, h)
      assert_equal old_h, h
    end

    should "add given class to object class" do
      obj = stale_factory_object(:committee, :title => "something & nothing" )
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link bar"), link_for(obj, :class => "bar")
    end

    should "add object's status of object to class" do
      obj = stale_factory_object(:committee, :title => "something & nothing" )
      obj.stubs(:status).returns("foostatus")
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link foostatus bar"), link_for(obj, :class => "bar")
    end

    should "not fail if object doesn't respond_to? status" do
      self.stubs(:mocha_mock_path).returns('/')
      obj1 = stub_everything(:title => 'object') # so will return false to respond_to? and new_record? methods
      obj1.stubs(:respond_to?).with(:status).returns(false)
      obj1.stubs(:status).raises(NoMethodError) # shouldn't be called
      assert_nothing_raised(Exception) {link_for(obj1, :class => "bar")}
    end

    should "add 'new' class and flash if it has recently been created" do
      obj = Factory(:committee)
      assert_dom_equal image_tag("new_flash.gif", :alt => "new", :class => "icon") + link_to(obj.title, obj, :class => "committee_link new"), link_for(obj)
    end

    should "add 'updated' class and flash if it is not new but has recently been updated" do
      obj = Factory(:committee)
      obj.stubs(:created_at => 8.days.ago)
      assert_dom_equal image_tag("updated_flash.gif", :alt => "updated", :class => "icon") + link_to(obj.title, obj, :class => "committee_link updated"), link_for(obj)
    end

    should "add new class and flash if it has recently been created as well as given class" do
      obj = Factory(:committee)
      assert_dom_equal image_tag("new_flash.gif", :alt => "new", :class => "icon") + link_to(obj.title, obj, :class => "committee_link new foo"), link_for(obj, :class => "foo")
    end

    should "return basic_link if it is requested" do
      obj = Factory(:committee)

      assert_dom_equal basic_link_for(obj), link_for(obj, :basic => true)
    end

    should "return extended_link if it is requested" do
      obj = Factory(:committee)
      obj.stubs(:extended_title => "some extended title")

      assert_dom_equal extended_link_for(obj), link_for(obj, :extended => true)
    end

    should "use given text for link in preference to object title" do
      obj = stale_factory_object(:committee)
      assert_dom_equal link_to("Some other text", obj, :class => "committee_link"), link_for(obj, :text => "Some other text")
    end

  end

  context "basic_link_for helper method" do

    should "return nil by default" do
      assert_nil basic_link_for
    end

    should "return nil by if blank" do
      assert_nil basic_link_for("")
    end

    should "return show as plain text if object is new" do
      assert_equal "new committee", basic_link_for(Committee.new(:title => "new committee"))
    end

    should "return empty string if new object's title is nil" do
      assert_equal "", basic_link_for( Committee.new)
    end

    should "escape new object's title" do
      assert_equal h("something & nothing... which <needs> escaping"), basic_link_for(Committee.new(:title => "something & nothing... which <needs> escaping"))
    end

    # should "return nil if object's title is nil" do
    #   assert_nil basic_link_for Committee.new
    # end

    # should "return nil if object's title is nil" do
    #   assert_nil basic_link_for Committee.new
    # end

    should "return link for item with object title for link text" do
      obj = stale_factory_object(:committee) # poss better way of testing this. obj can be any ActiveRecord obj
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), basic_link_for(obj)
    end

    should "leave options hash untouched" do
      obj = stale_factory_object(:committee)
      h = { :text => "bar", :class => "foo" }
      old_h = h.clone
      basic_link_for(obj, h)
      assert_equal old_h, h
    end

    should "escape object's title" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" )
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link"), basic_link_for(obj)
    end

    should "pass on options" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" )
      assert_dom_equal link_to(h(obj.title), obj, :foo => "bar", :class => "committee_link"), basic_link_for(obj, :foo => "bar")
    end

    should "add given class to object class" do
      obj = stale_factory_object(:committee, :title => "something & nothing... which <needs> escaping" )
      assert_dom_equal link_to(h(obj.title), obj, :class => "committee_link bar"), basic_link_for(obj, :class => "bar")
    end

    should "not add new class if it has recently been created" do
      obj = Factory(:committee)
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), basic_link_for(obj)
    end

    should "not add updated class if it is not new but has recently been updated" do
      obj = Factory(:committee)
      obj.stubs(:created_at => 8.days.ago)
      assert_dom_equal link_to(obj.title, obj, :class => "committee_link"), basic_link_for(obj)
    end
  end

  context "extended_link_for helper method" do

    should "return nil by default" do
      assert_nil extended_link_for
    end

    should "return link_for object by default" do
      obj = stale_factory_object(:committee) # poss better way of testing this. obj can be any ActiveRecord obj
      assert_dom_equal link_for(obj), extended_link_for(obj)
    end

    should "pass options to link_for" do
      obj = stale_factory_object(:committee)
      assert_dom_equal link_for(obj, :foo => "bar"), extended_link_for(obj, :foo => "bar")
    end

    should "leave options hash untouched" do
      obj = stale_factory_object(:committee)
      h = {:text => "bar", :class => "foo"}
      old_h = h.dup
      extended_link_for(obj, h)
      assert_equal old_h, h
    end

    should "use object's extended title if it exists" do
      obj = stale_factory_object(:committee)
      obj.stubs(:extended_title => "some extended title")
      assert_dom_equal link_for(obj, :text => "some extended title"), extended_link_for(obj)
    end

    should "use given text in preference to object's extended title" do
      obj = stale_factory_object(:committee)
      obj.stubs(:extended_title => "some extended title")
      assert_dom_equal link_for(obj, :text => "some other text"), extended_link_for(obj, :text => "some other text")
    end
  end

  context "council_page_for helper method" do

    should "return link based on url" do
      obj = stub(:url => "http://somecouncil/meeting")
      assert_dom_equal link_to("official page", "http://somecouncil/meeting", :class => "official_page external"), council_page_for(obj)
    end

    should "return nil if url nil" do
      obj = stub(:url => nil)
      assert_nil council_page_for(obj)
    end

    should "use options when constructing link" do
      obj = stub(:url => "http://somecouncil/meeting")
      assert_dom_equal link_to("official page", "http://somecouncil/meeting", :class => "official_page external", :foo => "bar"), council_page_for(obj, :foo => "bar")
    end

  end

  context "link_to_api_url" do
    setup do
      @controller = TestController.new
      self.stubs(:params).returns(:controller => "councils", :action => "index")
    end

    should "should return xml link when xml requested" do
      assert_equal link_to("xml", { :controller => "councils", :action => "index", :format => "xml" }, :class => "api_link xml"), link_to_api_url("xml")
    end

    should "should return js link when json requested" do
      assert_equal link_to("json", { :controller => "councils", :action => "index", :format => "json" }, :class => "api_link json"), link_to_api_url("json")
    end

    should "should use id rather than to_param in url js link when json requested" do
      resource = Factory(:member)
      self.stubs(:params).returns(:controller => "members", :action => "show", :id => resource.to_param)
      assert_equal link_to("json", { :controller => "members", :action => "show", :format => "json", :id => resource.id }, :class => "api_link json"), link_to_api_url("json")
    end

  end

  context "list_all helper method" do
    setup do
      @obj1 = Factory(:committee )
      @obj2 = Factory(:another_council)
    end

    should "return message if no object given" do
      assert_dom_equal "<p class='no_results'>No results</p>", list_all
    end

    should "return message if empty_array given" do
      assert_dom_equal "<p class='no_results'>No results</p>", list_all([])
    end

    should "return message if nil given" do
      assert_dom_equal "<p class='no_results'>No results</p>", list_all(nil)
    end

    should "check to see if list_item partial exists for item" do
      self.expects(:partial_exists?).with('committees/list_item')
      list_all(@obj1)
    end

    context "when no list_item partial exists for given item" do
      setup do
        self.stubs(:partial_exists?)
      end

      should "return unordered list of objects using link_for helper method" do
        assert_dom_equal "<ul><li>#{link_for(@obj1)}</li><li>#{link_for(@obj2)}</li></ul>", list_all([@obj1,@obj2])
      end

      should "return unordered list of single object" do
        assert_dom_equal "<ul><li>#{link_for(@obj1)}</li></ul>", list_all(@obj1)
      end

      should "pass on options to link if given" do
        assert_dom_equal "<ul><li>#{link_for(@obj1, :foo => "bar")}</li></ul>", list_all(@obj1, :foo => "bar")
      end

    end

    context "when list_item partial exists for given item" do

      should "render using partial" do
        # need to figure out way of testing this
      end
    end

  end

  context "partial_exists helper method" do
    should "return false by default" do
      assert !partial_exists?("foo")
    end

    should "return true if partial exists" do
      assert partial_exists?("shared/footer")
    end
  end

  context "link_to_calendar helper method" do
    setup do
      @controller = TestController.new
      self.stubs(:params).returns(:controller => "meetings", :action => "index", :foo => "bar")
    end

    should "return link to current page with calendar params added" do
      assert_equal link_to("Subscribe to this calendar", { :controller => "meetings",
                                                           :action => "index",
                                                           :foo => "bar",
                                                           :protocol => "webcal",
                                                           :only_path => false,
                                                           :format => "ics" }, :class => "calendar feed"),
                      link_to_calendar
    end

    should "return link to given page with calendar params added" do
      assert_equal link_to("Subscribe to this calendar", { :controller => "committees",
                                                           :action => "show",
                                                           :id => 1,
                                                           :protocol => "webcal",
                                                           :only_path => false,
                                                           :format => "ics" }, :class => "calendar feed"),
                      link_to_calendar({:controller => "committees", :action => "show", :id => 1})
    end
  end

  context "canonical_link_tag helper method" do

    should "return nil by default" do
      assert_nil canonical_link_tag
    end

    should "return link to canonical_url if set" do
      self.instance_variable_set(:@canonical_url, "/foo/bar")
      assert_dom_equal tag(:link, :rel => :canonical, :href => "/foo/bar"), canonical_link_tag
    end

    should "return link to calculated canonical_url if canonical_url IS true" do
      member = Factory(:member)
      self.stubs(:controller).returns(stub(:controller_name => "members"))
      self.instance_variable_set(:@canonical_url, true)
      self.instance_variable_set(:@member, member)
      assert_dom_equal tag(:link, :rel => :canonical, :href => "/members/#{member.to_param}"), canonical_link_tag
    end

    should "return nil if canonical_url IS true but controller doesn't have instance variable for resource" do
      member = Factory(:member)
      self.stubs(:controller).returns(stub(:controller_name => "members"))
      self.instance_variable_set(:@canonical_url, true)
      assert_nil canonical_link_tag
    end

  end

  context "timestamp_data_for helper method" do
    setup do
      @last_updated = 2.hours.ago
      @obj = stub(:updated_at => @last_updated)
    end
    should "return details of when updated" do
      assert_dom_equal content_tag(:p, "Last updated #{@last_updated.to_s(:short)} (#{time_ago_in_words(@last_updated)} ago)", :class => "attribution"), timestamp_data_for(@obj)
    end
  end

  context "help_link_to helper method" do
    should "return nil by default" do
      assert_nil help_link_to(nil)
    end

    should "return link to url using help icon" do
      assert_equal link_to(image_tag("help.png"), "http://en.wikipedia.org/wiki/London_borough", :class => "help", :alt => "help"), help_link_to("http://en.wikipedia.org/wiki/London_borough")
    end
  end

  context "wikipedia_link_for helper method" do
    should "return nil by default" do
      assert_nil wikipedia_link_for(nil)
    end

    should "return link to wikipedia_page" do
      assert_equal link_to("Foo Bar", "http://en.wikipedia.org/wiki/Foo_Bar", :class => "wikipedia_link external", :title => "Wikipedia page for 'Foo Bar'"), wikipedia_link_for("Foo Bar")
    end

    should "return link to wikipedia_page using URL given" do
      assert_equal link_to("Foo Bar", "http://en.wikipedia.org/wiki/Bar_Foo_Baz", :class => "wikipedia_link external", :title => "Wikipedia page for 'Foo Bar'"), wikipedia_link_for("Foo Bar", :url => "http://en.wikipedia.org/wiki/Bar_Foo_Baz")
    end
  end

  context "resource_uri_for helper method" do

    should "return url_for object with :redirect_from_resource flag set and only using id" do
      # @obj = Factory(:committee )
      # assert_equal "http://test.com/id/committees/#{@obj.id}", resource_uri_for(@obj)
    end
  end
  
  context "breadcrumbs helper method" do
    setup do
      @obj1 = Factory(:council)
      @obj2 = Factory(:committee, :council => @obj1)
    end
    
    should "show basic link to given item in breadcrumb div" do  
      assert_equal content_tag(:span, basic_link_for(@obj1), :class => "breadcrumbs"), breadcrumbs([@obj1])
    end
    
    should "return nil if no items basic links to given item" do  
      assert_nil breadcrumbs([])
      assert_nil breadcrumbs(nil)
    end
    
    should "show basic links to items separated by '>'" do
      assert_equal content_tag(:span, "#{basic_link_for @obj2} > #{basic_link_for @obj1}", :class => "breadcrumbs"), breadcrumbs([@obj2, @obj1])
    end
  end

  private
  def stale_factory_object(name, options={})
    obj = Factory(name, options)
    obj.stubs(:created_at => 8.days.ago, :updated_at => 8.days.ago)
    obj
  end
end
