
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def phone_numbers(homephone)
  homephone = homephone.to_s.gsub(/\D/, '')
  if homephone.length < 10 || homephone.length > 11
    return "Uncorrect phone number"
  end

  if homephone.length == 11 && homephone[0] == "1"
    homephone = homephone.slice(1..-1)
  elsif homephone.length == 11 && homephone[0] != "1"
    return "Uncorrect phone number"
  end

  return homephone
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def format_time(registration_date)
  Time.strptime(registration_date, '%m/%d/%y %k:%M')
end

def peak_hour(time)
  hour = time.each_with_object(Hash.new(0)) { |frequency, result| result[frequency] += 1 }
  "Peak hour is at #{hour.key(hour.values.max)} with: #{hour.values.max} people"
end

def peak_day(time)
  day = time.each_with_object(Hash.new(0)) { |frequency, result| result[frequency] += 1 }
  "Peak day is #{day.key(day.values.max)} with: #{day.values.max} people"
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
array_of_hours = []
array_of_weekdays = [] 
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  numbers = phone_numbers(row[:homephone])

  save_thank_you_letter(id,form_letter)

  puts "#{name} #{zipcode} #{numbers}"

  array_of_hours << format_time(row[:regdate]).hour
  array_of_weekdays << format_time(row[:regdate]).strftime('%A')

end

puts peak_hour(array_of_hours)
puts peak_day(array_of_weekdays)