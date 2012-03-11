class PlanningApplication < ActiveRecord::Base
  include ScrapedModel::Base
  belongs_to :council
  validates_presence_of :council_id, :uid
  validates_uniqueness_of :uid, :scope => :council_id
  alias_attribute :council_reference, :uid
  serialize :other_attributes
  acts_as_mappable :default_units => :kms
  before_save :update_lat_lng
  before_create :set_default_value_for_bitwise_flag
  STATUS_TYPES_AND_ALIASES = [
                              ['approved', 'permitted'],
                              ['pending'],
                              ['refused', 'refusal', 'rejected'],
                              ['invalid'],
                              ['withdrawn']
                              ]
  
  # The stale strategy for planning_applications is quite complex, due to the way planning applications change over time:
  # First of all planning_applications that have no retrieved_at timestamp are considered stale, as we've not got any 
  # details about them.
  # Then applications that are younger than 3 months ago are considered stale, but returned oldest first (based on retrieed_at) 
  # In addition, some info scrapers require several URLs to be fetched and parsed. This is done through the use of the 
  # bitwise_flag. This attribute is only used by info scrapers who have parsers with :bitwise_flag in the attribute_parser
  # 
  
  named_scope :stale, lambda { { :conditions => [ "retrieved_at IS NULL OR retrieved_at > ?", 3.months.ago], 
                                 :limit => 100, 
                                 :order => 'retrieved_at' } }
  
  named_scope :with_details, { :conditions => "retrieved_at IS NOT NULL" } 


  def address=(raw_address)
    cleaned_up_address = raw_address.blank? ? raw_address : raw_address.gsub("\r", "\n").gsub(/\s{2,}/,' ').strip
    self[:address] = cleaned_up_address
    parsed_postcode = cleaned_up_address&&cleaned_up_address.scan(Address::UKPostcodeRegex).first
    self[:postcode] = parsed_postcode unless postcode_changed? # if already changed it's prob been explicitly set
  end
  
  # status is used by ScrapedModel mixin to show status of AR record so we make :status attribute available through this method
  def application_status
    self[:status]
  end
  
  # overload normal attribute setter. This sets the bitwise_flag attribute using 
  def bitwise_flag=(bw_int)
    return unless bw_int
    new_bitwise_flag = (bitwise_flag||0) | bw_int
    self[:bitwise_flag] = new_bitwise_flag == 7 ? 0 : new_bitwise_flag
  end
  
  # overwrite default behaviour
  def self.find_all_existing(params={})
    []
  end
  
  def google_map_magnification
    13
  end
  
  def inferred_lat_lng
    return unless matched_code = postcode&&Postcode.find_from_messy_code(postcode)
    [matched_code.lat, matched_code.lng]
  end
  
  # cleean up so we can get consistency across councils
  def normalised_application_status
    return if application_status.blank?
    STATUS_TYPES_AND_ALIASES.detect{ |s_and_a| s_and_a.any?{ |matcher| application_status.match(Regexp.new(matcher, true)) } }.try(:first)
  end
  
  def title
    "Planning Application #{uid}" + (address.blank? ? '' : ", #{address[0..30]}...")
  end
  
  protected
  # overwrite default behaviour
  def self.record_not_found_behaviour(params)
    logger.debug "****** record_not_found: params[:uid] = #{params[:uid]}, params[:council]= #{params[:council]}"
    # HACK ALERT!! Not sure why but params['uid'] not found on prodcution server, params[:uid] not found on development!
    pa = params[:council].planning_applications.find_or_initialize_by_uid(params['uid']||params[:uid])
    logger.debug "****** record_not_found: Planning Application: #{pa.inspect}"
    pa
  end
  
  
  private
  def update_lat_lng
    i_lat_lng = [inferred_lat_lng].flatten # so gives empty array if nil
    self[:lat] = i_lat_lng[0] unless self[:lat] && self.lat_changed?
    self[:lng] = i_lat_lng[1] unless self[:lng] && self.lng_changed?
  end
  
  def set_default_value_for_bitwise_flag
    self[:bitwise_flag] ||= 0
  end
end
