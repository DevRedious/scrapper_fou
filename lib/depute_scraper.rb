# frozen_string_literal: true

require 'httparty'
require 'nokogiri'

class DeputeScraper
  BASE_URL = 'https://www2.assemblee-nationale.fr'
  NEW_BASE_URL = 'https://www.assemblee-nationale.fr'
  LIST_URL = "#{BASE_URL}/deputes/liste/alphabetique"

  def initialize
    @deputes = []
  end

  def get_depute_info(depute_url)
    response = HTTParty.get(depute_url, headers: headers, follow_redirects: false)

    if response.code == 302 || response.code == 301
      new_url = response.headers['location']
    else
      doc = Nokogiri::HTML(response.body)
      meta_refresh = doc.css('meta[http-equiv="refresh"]').first
      if meta_refresh
        content = meta_refresh['content']
        new_url = content.match(/url='([^']+)'/i)&.[](1)
      end
    end

    if new_url
      new_url = "#{NEW_BASE_URL}#{new_url}" unless new_url.start_with?('http')
      response = HTTParty.get(new_url, headers: headers)
    end

    unless response.success?
      puts "❌ Erreur lors de la requête: #{depute_url}"
      return nil
    end

    doc = Nokogiri::HTML(response.body)
    extract_depute_info(doc)
  end

  def get_deputes_urls
    puts "🔍 Récupération de la liste des députés..."

    response = HTTParty.get(LIST_URL, headers: headers)

    unless response.success?
      puts "❌ Erreur lors de la requête: #{LIST_URL}"
      return []
    end

    doc = Nokogiri::HTML(response.body)
    deputes = []

    doc.css('a[href*="/deputes/fiche/"]').each do |link|
      href = link['href']
      full_name = link.text.strip

      next if full_name.empty?

      full_url = href.start_with?('http') ? href : "#{BASE_URL}#{href}"

      parsed = parse_name(full_name)

      deputes << {
        full_name: full_name,
        first_name: parsed[:first_name],
        last_name: parsed[:last_name],
        url: full_url
      }
    end

    puts "✅ #{deputes.length} députés trouvés"
    deputes
  end

  def fetch_all_deputes
    puts "🚀 Démarrage du scraping des députés de France..."

    deputes_urls = get_deputes_urls

    deputes_urls.each_with_index do |depute, index|
      puts "\n👤 [#{index + 1}/#{deputes_urls.length}] Traitement de #{depute[:full_name]}..."

      info = get_depute_info(depute[:url])

      if info && info[:email]
        @deputes << {
          'first_name' => info[:first_name] || depute[:first_name],
          'last_name' => info[:last_name] || depute[:last_name],
          'email' => info[:email]
        }
        puts "📧 #{info[:first_name]} #{info[:last_name]}: #{info[:email]}"
      else
        email = generate_email(depute[:first_name], depute[:last_name])
        @deputes << {
          'first_name' => depute[:first_name],
          'last_name' => depute[:last_name],
          'email' => email
        }
        puts "📧 #{depute[:first_name]} #{depute[:last_name]}: #{email} (généré)"
      end

      sleep(0.3)
    end

    puts "\n" + "=" * 50
    puts "✅ Scraping terminé ! #{@deputes.length} députés récupérés."
    puts "=" * 50

    @deputes
  end

  private

  def headers
    {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    }
  end

  def parse_name(full_name)
    name = full_name.gsub(/^(M\.|Mme|Mlle)\s+/i, '').strip

    parts = name.split(/\s+/)

    if parts.length >= 2
      first_name = parts.first
      last_name = parts[1..].join(' ')
    else
      first_name = name
      last_name = ''
    end

    { first_name: first_name, last_name: last_name }
  end

  def extract_depute_info(doc)
    info = {}

    email_link = doc.css('a[href^="mailto:"]').find { |l| l['href'].include?('@assemblee-nationale.fr') }
    if email_link
      info[:email] = email_link['href'].gsub('mailto:', '').split('?').first.strip
    else
      page_text = doc.text
      email_match = page_text.match(/[a-zA-Z0-9._%+-]+@assemblee-nationale\.fr/)
      info[:email] = email_match[0] if email_match
    end

    title = doc.css('h1, .deputy-name, [class*="name"]').first
    if title
      parsed = parse_name(title.text.strip)
      info[:first_name] = parsed[:first_name]
      info[:last_name] = parsed[:last_name]
    end

    info[:email] ? info : nil
  end

  def generate_email(first_name, last_name)
    first = normalize_name(first_name)
    last = normalize_name(last_name)

    "#{first}.#{last}@assemblee-nationale.fr"
  end

  def normalize_name(name)
    accents = {
      'à' => 'a', 'â' => 'a', 'ä' => 'a', 'á' => 'a', 'ã' => 'a',
      'è' => 'e', 'ê' => 'e', 'ë' => 'e', 'é' => 'e',
      'ì' => 'i', 'î' => 'i', 'ï' => 'i', 'í' => 'i',
      'ò' => 'o', 'ô' => 'o', 'ö' => 'o', 'ó' => 'o', 'õ' => 'o',
      'ù' => 'u', 'û' => 'u', 'ü' => 'u', 'ú' => 'u',
      'ý' => 'y', 'ÿ' => 'y',
      'ñ' => 'n', 'ç' => 'c',
      'œ' => 'oe', 'æ' => 'ae'
    }

    result = name.downcase
    accents.each { |accent, replacement| result.gsub!(accent, replacement) }
    result.gsub(/[^a-z]/, '-').gsub(/-+/, '-').gsub(/^-|-$/, '')
  end
end

if __FILE__ == $PROGRAM_NAME
  scraper = DeputeScraper.new
  deputes = scraper.fetch_all_deputes

  puts "\n" + "=" * 50
  puts "Exemples de députés récupérés:"
  puts "=" * 50

  deputes.first(10).each do |depute|
    puts "#{depute['first_name']} #{depute['last_name']}: #{depute['email']}"
  end
end
