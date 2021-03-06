class Supplier < ActiveRecord::Base
  AllowedPayeeModels = [['Council', 'District, Borough, County Council'], ['ParishCouncil', 'Parish or Town Council'], ['Entity', 'Government body/quango/etc'], ['Charity'], ['PoliceAuthority'], ['PoliceForce'], ['Company']]
  belongs_to :organisation, :polymorphic => true
  belongs_to :payee, :polymorphic => true
  has_many :financial_transactions, :dependent => :destroy
  include SpendingStatUtilities::Base
  validates_presence_of :organisation_id, :organisation_type
  validates_uniqueness_of :uid, :scope => [:organisation_type, :organisation_id], :allow_nil => true
  named_scope :unmatched, :conditions => {:payee_id => nil}
  named_scope :filter_by, lambda { |filter_hash| filter_hash[:name] ? 
                                  { :conditions => ['UPPER(name) LIKE ?', "%#{filter_hash[:name].upcase}%"] } :
                                  {} }
  after_create :queue_matching_company_and_vat_info
  alias_attribute :title, :name
  attr_accessor :vat_number
  attr_accessor :company_number
  
  def validate
    errors.add_to_base('Either a name or uid is required') if name.blank? && uid.blank?
  end
  
  def self.allowed_payee_classes
    AllowedPayeeModels.collect(&:first)
  end
  
  # Finds supplier given params, one of which must be :organisation (and that organisation 
  # should have_many suppliers). If a :uid is supplied, checks 
  # suppliers belonging to organisation with uid and if not for suppliers with matching name
  def self.find_or_build_from(params)
    # 
    squished_name = NameParser.strip_all_spaces(params[:name]).try(:squish)
    supplier = if params[:uid].blank?
      squished_name.blank? ? nil : params[:organisation].suppliers.find_by_name(squished_name)
    else
      params[:organisation].suppliers.find_by_uid(params[:uid])
    end
    if supplier
      supplier.instance_variable_set(:@vat_number, params[:vat_number]) if params[:vat_number]
      supplier.instance_variable_set(:@company_number, params[:company_number]) if params[:company_number]
      supplier
    else
      Supplier.new(params)
    end
  end

  # ScrapedModel module isn't mixed but in any case we need to do a bit more when normalising supplier titles
  def self.normalise_title(raw_title)
    TitleNormaliser.normalise_company_title(raw_title)
  end
  
  # alias financial_transactions to make spending_stat calculations cleaner
  def payments
    financial_transactions
  end
  
  # returns associated suppliers (i.e. those with same company)
  def associateds
    return [] unless payee
    payee.supplying_relationships - [self]
  end
  
  def match_with_payee
    if payee = possible_payee
      payee.supplying_relationships << self #doing it this way rather than setting payee means after_add callbacks are triggered
    else
      update_attribute(:failed_payee_search, true)
    end
  end
  
  def update_payee(new_payee)
    if old_payee = self.payee
      self.payee = nil
      old_payee.update_spending_stat # we do it manually rather than using after_remove callbacks as these duplicate some of the ones when adding supplier, and these should be called after new relationship added
    end
    new_payee.supplying_relationships << self #doing it this way rather than setting payee means after_add callbacks are triggered
  end
  
  # strip excess spaces and UTF8 spaces from name
  def name=(raw_name)
    self[:name] = NameParser.strip_all_spaces(raw_name).try(:squish) if raw_name
  end

  def openlylocal_url
    "http://#{DefaultDomain}/suppliers/#{to_param}"
  end
  
  # alias populate_basic_info as perform so that this gets run when doing delayed_job on a company
  def perform
    match_with_payee
  end

  def possible_payee
    return Company.from_title(name) if Company.probable_company?(name)
    case name
    when /Police Authority/i
      PoliceAuthority.find_by_name(name)
    when /Pension Fund/i
      PensionFund.find_by_name(name)
    when /Town Council|Parish Council/i
      pcs = ParishCouncil.find_all_by_normalised_title(ParishCouncil.normalise_title(name))
      pcs && (pcs.size == 1) ? pcs.first : nil
    when /Council|Borough|(City of)|Authority/i
      Council.find_by_normalised_title(Council.normalise_title(name))
    else
      Charity.find_by_normalised_title(name)||Entity.find_by_title(name)
    end
  end
  
  def to_param
    "#{id}-#{title&&title.parameterize}"
  end
  
  def update_supplier_details(details)
    non_nil_attribs = details.attributes.delete_if { |k,v| v.blank? }
    if details.entity_id.blank?
      entity = Company.match_or_create(non_nil_attribs.except(:source_for_info, :entity_type, :entity_id).merge(:title => title)) if details.entity_type == 'Company'
      entity = Charity.find_by_charity_number(non_nil_attribs[:charity_number].to_s) if details.entity_type == 'Charity'
    else
      entity = self.class.allowed_payee_classes.include?(details.entity_type)&&details.entity_type.constantize.find(details.entity_id)
      entity.update_attribute(:url, details.url) if details.url && entity.respond_to?(:url) && entity.url.blank?
    end
    if res = entity&&!entity.new_record? # it hasn't successfully saved
      entity.supplying_relationships << self
    end
    res
  end
  
  private
  def queue_matching_company_and_vat_info
    if self.company_number
      matcher = SupplierUtilities::CompanyNumberMatcher.new(:company_number => company_number, :supplier => self)
      matcher.delay.perform
    end
    if self.vat_number
      matcher = SupplierUtilities::VatMatcher.new(:vat_number => vat_number, :supplier => self, :title => title)
      matcher.delay.perform
    end
  end
  
end
