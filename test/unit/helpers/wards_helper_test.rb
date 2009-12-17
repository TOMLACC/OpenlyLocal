require 'test_helper'

class WardsHelperTest < ActionView::TestCase
  include OnsDatapointsHelper

  context "ons_statistics_graph helper method" do
    setup do
      datapoint_1 = stub_everything(:value => 53, :title => '0-17')
      datapoint_2 = stub_everything(:value => 42.3, :title => '18-25')
      datapoint_3 = stub_everything(:value => 61, :title => '26-35')
      @statistics_group = {:demographics => [datapoint_1, datapoint_2, datapoint_3]}
    end

    should "should get pie chart for ons statistics data" do
      Gchart.expects(:pie).returns("http://foo.com//graph")
      ons_statistics_graph(@statistics_group)
    end

    should "use datapoint values for graph" do
      Gchart.expects(:pie).with(has_entry( :data => [53,42.3,61])).returns("http://foo.com//graph")
      ons_statistics_graph(@statistics_group)
    end

    should "should use titles in legend" do
      Gchart.expects(:pie).with(has_entry( :legend => ['0-17', '18-25', '26-35'])).returns("http://foo.com//graph")
      ons_statistics_graph(@statistics_group)
    end

    should "return image tag using graph url as as src" do
      Gchart.stubs(:pie).returns("http://foo.com//graph")
      assert_dom_equal image_tag("http://foo.com//graph", :class => "chart", :alt => "Demographics graph"), ons_statistics_graph(@statistics_group)
    end

    should "not raise exception if no data" do
      assert_nothing_raised(Exception){ons_statistics_graph(nil)}
      assert_nothing_raised(Exception){ons_statistics_graph({})}
    end
  end

  context "ons_statistics_in_words helper method" do
    setup do
      ward = Factory(:ward)
      self.stubs(:mocha_mock_path).returns('/foo') #url in stats, so just stub out all calls to object's path
      datapoint_1 = stub_everything(:value => 534, :short_title => '18-25')
      datapoint_2 = stub_everything(:value => 42.2, :short_title => 'of the population', :muid_type => "Percentage", :muid_format => "%.1f%")
      datapoint_3 = stub_everything(:value => 61, :short_title => '26-35 years olds', :muid_type => "Age")
      datapoint_4 = stub_everything(:value => 75, :short_title => 'has a mean age of', :muid_type => "Age")
      statistics_group = {:demographics => [datapoint_1, datapoint_2, datapoint_3, datapoint_4]}
      @result = ons_statistics_in_words(statistics_group)
    end


    should "should return text with stats" do
      assert_match /534.+18\-25/, @result
    end

    should "should use muid format for number" do
      assert_match /42.2%.+of the population/, @result
    end

    should "should put number after number for age" do
      assert_match /has a mean age of.+75/, @result
    end

    should "should link to datapoints" do
      assert_match /href=\"\/foo\">has a mean age of<\/a>/, @result
    end

    should "not raise exception if no data" do
      assert_nothing_raised(Exception){ons_statistics_in_words(nil)}
      assert_nothing_raised(Exception){ons_statistics_in_words({})}
    end
  end
end
