class RelatedArticle < ActiveRecord::Base
  belongs_to :subject, :polymorphic => true
  belongs_to :hyperlocal_site
  validates_presence_of :title, :url, :hyperlocal_site_id, :subject_type, :subject_id
  validates_uniqueness_of :url
  default_scope :order => 'created_at'
  delegate :openlylocal_url, :to => :subject, :allow_nil => true
  ModelsAcceptingPingbacks = %w(members committees meetings polls financial_transactions suppliers companies)
  
  def self.process_pingback(pingback)
    subject_params = pingback.target_uri.scan(/openlylocal.com\/([\w_]+)\/(\d+)/i).flatten
    hyperlocal_site = HyperlocalSite.find_from_article_url(pingback.source_uri)
    logger.error { "****Pingback received: #{pingback.inspect}" }
    return false unless subject_params.size == 2 && ModelsAcceptingPingbacks.include?(subject_params.first)
    subject = subject_params.first.classify.constantize.find_by_id(subject_params[1]) rescue nil
    if subject && hyperlocal_site
      create( :title => pingback.title,
              :url => pingback.source_uri,
              :extract => pingback.content,
              :hyperlocal_site => hyperlocal_site,
              :subject => subject
      )
      true
    else
      false
    end
  end
end
