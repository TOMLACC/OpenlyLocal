desc "Import May 2006 London Election Results"
task :import_london_2006_election_results => :environment do
  council_name, ward_name, council, ward, poll, wards = nil, nil, nil, nil, nil, nil #initialize variables
  councils = Council.find_all_by_authority_type('London Borough')
  political_parties = PoliticalParty.all
  FasterCSV.foreach(File.join(RAILS_ROOT, 'db/csv_data/London_LA_Election_Results_May_4_2006.csv'), :headers => true) do |row|
    if council_name != row["Borough"]
      council_name = row["Borough"]
      council = councils.detect{|c| Council.normalise_title(c.name) == Council.normalise_title(row["Borough"])}
      wards = council.wards
      puts "=======\nStarted importing results for #{council.name}"
    end
    if ward_name != row["WardName"]
      ward_name = row["WardName"]
      if ward = wards.detect{ |w| TitleNormaliser.normalise_title(w.title) == TitleNormaliser.normalise_title(ward_name) }
        poll = ward.polls.find_or_create_by_date_held("04-05-2006".to_date)
        puts "Now importing results for ward: #{ward.name}"
      else
        puts "****Can't match: #{ward_name}"
      end
    end
    last_name, first_name  = row["Candidate"].split(',').collect{ |n| n.strip }
    political_party = political_parties.detect{ |p| p.matches_name?(row["Party"]) }
    party = political_party ? nil : row["Party"]
    elected = !!row["Elected"]
    poll.candidates.create!(:elected => elected, :last_name => last_name, :first_name => first_name, :votes => row["Vote"], :political_party => political_party, :party => party)
  end
end

desc "Import May 2006 London Voting Proportions"
task :import_london_2006_voting_proportions => :environment do
  council_name, council, ward, poll, wards = nil, nil, nil, nil, nil #initialize variables
  councils = Council.find_all_by_authority_type('London Borough')
  political_parties = PoliticalParty.all
  FasterCSV.foreach(File.join(RAILS_ROOT, 'db/csv_data/London_LA_Voting_Proportions_May_4_2006.csv'), :headers => true) do |row|
    if council_name != row['Borough']
      council_name = row['Borough']
      council = councils.detect{|c| Council.normalise_title(c.name) == Council.normalise_title(row['Borough'])}
      wards = council.wards
      puts "=======\nStarted importing results for #{council.name}"
    end
    next if row['WardName'].strip == "Total"
    if ward = wards.detect{ |w| TitleNormaliser.normalise_title(w.title) == TitleNormaliser.normalise_title(row['WardName']) }
      poll = ward.polls.find_or_create_by_date_held("04-05-2006".to_date)
      voting_attribs = { :position => 'Member',
                         :electorate => row['Electorate'].gsub(',',''), 
                         :postal_votes => row['PostalVotes']&&row['PostalVotes'].gsub(',',''), 
                         :ballots_rejected => row['RejectedBallots'] }
      voting_attribs[:ballots_issued] = (row['PostalVotes']&&row['PostalVotes'].gsub(',','')).to_i + row['VotesInPerson'].gsub(',','').to_i
      poll.update_attributes(voting_attribs)
      puts "Updated results for #{ward.name}: #{voting_attribs.inspect}"
    else
      puts "****Can't match: #{row['WardName']}"
    end
  end  
end

desc "Scrape Electoral Commission for Political Parties"
task :scrape_electoral_commission_party_list => :environment do
  require 'hpricot'
  base_url = 'http://registers.electoralcommission.org.uk'
  party_list_page = 'http://registers.electoralcommission.org.uk/regulatory-issues/regpoliticalparties.cfm'
  Hpricot(open(party_list_page)).search('#id_political option')[1..-1].each do |option|
    party = PoliticalParty.find_or_initialize_by_electoral_commission_uid(:electoral_commission_uid => option[:value], :name => option.inner_text)
    begin
      party.save!
    rescue Exception => e
      puts "Problem saving ##{party.inspect}"
    end
  end
end