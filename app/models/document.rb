class Document < ActiveRecord::Base
  include ScrapedModel::Base
  validates_presence_of :body
  validates_presence_of :url
  validates_presence_of :document_owner_id
  validates_presence_of :document_owner_type
  validates_uniqueness_of :url, :scope => :document_type
  belongs_to :document_owner, :polymorphic => true
  before_validation :sanitize_body
  default_scope :order => "documents.updated_at DESC" # newest first. Specify fully for when used with joins
  delegate :council, :to => :document_owner
  alias_method :old_to_xml, :to_xml
  before_save :update_precis
  
  def document_type
    self[:document_type] || "Document"
  end
  
  # def calculated_precis
  #   stripped_text = ActionController::Base.helpers.strip_tags(body).gsub(/[\t\r\n]+ *[\t\r\n]+/,"\n")
  #   ActionController::Base.helpers.truncate(stripped_text, :length => 500)
  # end
  # 
  def title
    self[:title] || "#{document_type} for #{document_owner.extended_title}"
  end
  
  def extended_title
    self[:title] || "#{document_type} for #{document_owner.extended_title}"
  end
  
  def to_xml(options={}, &block)
    old_to_xml({:methods => [:title, :openlylocal_url, :status], :only => [:id, :url] }.merge(options), &block)
  end
  
  protected
  def sanitize_body
    self.body = DocumentUtilities.sanitize(raw_body, :base_url => url)
  #   # return if raw_body.blank?
  #   # uncommented_body = raw_body.gsub(/<\!--.*?-->/mi, '').gsub(/<\!\[.*?\]>/mi, '') # remove comments otherwise they are escape by sanitizer and show in browser
  #   # sanitized_body = ActionController::Base.helpers.sanitize(uncommented_body)
  #   # base_url = url&&url.sub(/\/[^\/]+$/,'/')
  #   # doc = Hpricot(sanitized_body)
  #   # doc.search("a[@href]").each do |link|
  #   #   link[:href].match(/^http:|^mailto:/) ? link : link.set_attribute(:href, "#{base_url}#{link[:href]}")
  #   #   link.set_attribute(:class, 'external')
  #   # end
  #   # doc.search('img').remove
  #   # self.body = doc.to_html
  end
  
  private
  def update_precis
    self.precis = DocumentUtilities.precis(body)
  end
end
