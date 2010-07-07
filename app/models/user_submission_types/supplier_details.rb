class SupplierDetails < UserSubmissionDetails
  attr_accessor :url, :company_number, :wikipedia_url
  
  def approve(submission)
    submission.item.update_supplier_details(self) rescue return false
  end
end