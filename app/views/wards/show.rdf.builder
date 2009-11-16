xml.instruct! :xml, :version => "1.0" 
xml.tag! "rdf:RDF",
         "xmlns:foaf"  => "http://xmlns.com/foaf/0.1/", 
         "xmlns:rdfs"  => "http://www.w3.org/2000/01/rdf-schema#", 
         "xmlns:rdf"   => "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
         "xmlns:dct"   => "http://purl.org/dc/terms/", 
         "xmlns:xsd"   => "http://www.w3.org/2001/XMLSchema#", 
         "xmlns:administrative-geography"   => "http://statistics.data.gov.uk/def/administrative-geography/", 
         "xmlns:openlylocal" => "#{rdfa_vocab_url}#" do
  xml.tag! "rdf:Description", "rdf:about" => ward_url(:id => @ward.id) do
    xml.tag! "rdfs:label", @ward.name
  end
end

# xmlns:administrative-geography="http://statistics.data.gov.uk/def/administrative-geography/"

# <rdf:Description rdf:about="<%= show_it_path(@company) %>">
#   <rdfs:label>Description of the company <%= @company.name %></rdfs:label>
#   <dcterms:created rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime"><%= @company.created_at %></dcterms:created>
#   <dcterms:modified rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime"><%= @company.updated_at %></dcterms:modified>
#   <foaf:primaryTopic rdf:resource="<%= show_it_path(@company.company_number) %>"/>
# </rdf:Description>
#  
# <foaf:Organization rdf:about="<%= show_it_path(@company.company_number) %>">
#    <foaf:name><%= @company.name %></foaf:name>
#    <foafcorp:company_number><%= @company.company_number %></foafcorp:company_number>
#    <!-- TODO: extend address details when we receive companies house xml (stored in 1 single field atm) -->
#    <vcard:Extadd><%= @company.address %></vcard:Extadd>
# </foaf:Organization>