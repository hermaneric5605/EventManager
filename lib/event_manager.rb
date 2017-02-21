require "csv"
require "sunlight/congress"
require "erb"

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phonenumber(phonenumber)
	phonenumber = phonenumber.scan(/\d+/).join('')
	if phonenumber.length == 10
	elsif phonenumber.length == 11 && phonenumber[0] == "1"
		phonenumber[0] = ""
	else
		phonenumber = "INVALID"
	end
	phonenumber
end

#obtain hour and weekday of registration
def get_signuptime(regdate)
	regdate = DateTime.strptime(regdate, '%m/%d/%Y %H:%M')
	regdate = [regdate.hour, regdate.wday]
end


def legislators_by_zipcode(zipcode)
	legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id,form_letter)
	Dir.mkdir("output") unless Dir.exists? "output"
	filename = "output/thanks#{id}.html"
	File.open(filename,'w') do |file|
		file.puts form_letter
	end
end

puts "EventManager Initialized!"

#load CSV
contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

# Initialize hashes for registration insights
reghour = Hash.new(0)
regday = Hash.new(0)

contents.each do |line|

	id = line[0]
	name = line[:first_name]
	zipcode = clean_zipcode(line[:zipcode])
	phonenumber = clean_phonenumber(line[:homephone])

	#save hour and weekday frequency to a hash
	reghour[get_signuptime(line[:regdate])[0]] +=1
	regday[get_signuptime(line[:regdate])[1]] +=1

	#get legislator information and put it into the letter format
	legislators = legislators_by_zipcode(zipcode)
	form_letter = erb_template.result(binding)
	save_thank_you_letters(id,form_letter)
end
#Information for manager about time targeting and weekday targeting
puts "Registration times, ordered by hour"
puts Hash[reghour.sort]
puts "Registration times, ordered by frequency"
puts Hash[reghour.sort_by{|key, val| val}.reverse]
puts "Registration weekday, by weekday (0 = Sunday)"
puts Hash[regday.sort]
puts "Optimal advertising time:"
puts "The #{reghour.max_by{|key, val| val}[0]}(st/nd/rd/th) hour on day #{regday.max_by{|key, val| val}[0]}"

