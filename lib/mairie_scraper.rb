# frozen_string_literal: true

require 'httparty'
require 'nokogiri'

class MairieScraper
  BASE_URL = 'https://lannuaire.service-public.gouv.fr'
  SEARCH_URL = "#{BASE_URL}/recherche"

  def initialize
    @townhalls = []
  end

  def get_townhall_email(townhall_url)
    response = HTTParty.get(townhall_url, headers: headers)

    unless response.success?
      puts "❌ Erreur lors de la requête: #{townhall_url}"
      return nil
    end

    doc = Nokogiri::HTML(response.body)
    find_email_in_page(doc)
  end

  def get_townhall_urls
    puts "🔍 Récupération de la liste des mairies du Val d'Oise..."

    townhalls = []
    page = 1

    loop do
      puts "📄 Chargement de la page #{page}..."

      url = "#{SEARCH_URL}?whoWhat=mairie&where=95&page=#{page}"
      response = HTTParty.get(url, headers: headers)

      unless response.success?
        puts "❌ Erreur lors de la requête: #{url}"
        break
      end

      doc = Nokogiri::HTML(response.body)
      before_count = townhalls.length

      doc.css('a[href*="/ile-de-france/val-d-oise/"]').each do |link|
        href = link['href']
        text = link.text.strip

        next if href.include?('/navigation/')
        next if href.include?('/recherche')

        full_url = href.start_with?('http') ? href : "#{BASE_URL}#{href}"

        name = text.gsub(/^Mairie\s*[-–de]*\s*/i, '').strip
        name = name.split(' - ').first&.strip || name

        next if name.empty?
        next if townhalls.any? { |t| t[:url] == full_url }

        townhalls << { name: name, url: full_url }
      end

      found = townhalls.length - before_count
      puts "   → #{found} mairies trouvées (total: #{townhalls.length})"

      break if found.zero?

      page += 1
      sleep(0.2)
    end

    puts "✅ #{townhalls.length} mairies trouvées au total"
    townhalls
  end

  def fetch_all_emails
    puts "🚀 Démarrage du scraping des mairies du Val d'Oise..."

    townhall_urls = get_townhall_urls

    townhall_urls.each_with_index do |townhall, index|
      name = townhall[:name]
      url = townhall[:url]

      puts "\n📍 [#{index + 1}/#{townhall_urls.length}] Traitement de #{name}..."

      email = get_townhall_email(url)

      if email
        @townhalls << { name => email }
        puts "📧 #{name}: #{email}"
      else
        puts "⚠️  Pas d'email trouvé pour #{name}"
      end

      sleep(0.3)
    end

    puts "\n" + "=" * 50
    puts "✅ Scraping terminé ! #{@townhalls.length} emails récupérés."
    puts "=" * 50

    @townhalls
  end

  private

  def headers
    {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    }
  end

  def find_email_in_page(doc)
    mailto_link = doc.css('a.send-mail[href^="mailto:"]').first
    mailto_link ||= doc.css('a[href^="mailto:"]').find { |l| l['href'].include?('@') && !l['href'].include?('subject=') }

    if mailto_link
      email = mailto_link['href'].gsub('mailto:', '').split('?').first.strip
      return email if valid_email?(email)
    end

    email_container = doc.css('#contentContactEmail, [data-test="contactCourriel"]').first
    if email_container
      email_match = email_container.text.match(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/)
      return email_match[0] if email_match && valid_email?(email_match[0])
    end

    page_text = doc.text
    email_matches = page_text.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/)

    email_matches.each do |email|
      next if email.include?('service-public')
      next if email.include?('exemple')
      next if email.include?('example')

      return email if valid_email?(email)
    end

    nil
  end

  def valid_email?(email)
    return false if email.nil? || email.empty?

    email.match?(/\A[\w.+-]+@[\w.-]+\.\w+\z/)
  end
end

if __FILE__ == $PROGRAM_NAME
  scraper = MairieScraper.new
  emails = scraper.fetch_all_emails

  puts "\n" + "=" * 50
  puts "Exemples d'emails récupérés:"
  puts "=" * 50

  emails.first(10).each do |townhall|
    townhall.each { |name, email| puts "#{name}: #{email}" }
  end
end
