# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'json'

class DarkTrader
  BASE_URL = 'https://coinmarketcap.com/'
  API_URL = 'https://api.coinmarketcap.com/data-api/v3/cryptocurrency/listing'

  def initialize
    @cryptos = []
  end

  def fetch_all_cryptos
    puts "🚀 Démarrage du scraping de CoinMarketCap..."

    fetch_from_api

    puts "✅ Scraping terminé ! #{@cryptos.length} cryptomonnaies récupérées."
    @cryptos
  end

  private

  def fetch_from_api
    start = 1
    limit = 100
    total_fetched = 0

    loop do
      response = HTTParty.get(
        API_URL,
        query: {
          start: start,
          limit: limit,
          sortBy: 'market_cap',
          sortType: 'desc',
          convert: 'USD',
          cryptoType: 'all',
          tagType: 'all',
          audited: false
        },
        headers: {
          'Accept' => 'application/json',
          'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
      )

      break unless response.success?

      data = JSON.parse(response.body)
      cryptos_data = data.dig('data', 'cryptoCurrencyList')

      break if cryptos_data.nil? || cryptos_data.empty?

      cryptos_data.each do |crypto|
        symbol = crypto['symbol']
        price = crypto.dig('quotes', 0, 'price')&.round(2)

        if symbol && price
          @cryptos << { symbol => price }
          puts "📈 #{symbol}: $#{price}"
        end
      end

      total_fetched += cryptos_data.length
      puts "--- #{total_fetched} cryptos récupérées ---"

      total_count = data.dig('data', 'totalCount').to_i
      break if total_count.zero? || start + limit > total_count

      start += limit
      sleep(0.5)
    end
  end
end

class DarkTraderHTML
  BASE_URL = 'https://coinmarketcap.com/'

  def initialize
    @cryptos = []
  end

  def fetch_all_cryptos
    puts "🚀 Démarrage du scraping HTML de CoinMarketCap..."

    response = HTTParty.get(
      BASE_URL,
      headers: {
        'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    )

    unless response.success?
      puts "❌ Erreur lors de la requête HTTP: #{response.code}"
      return []
    end

    doc = Nokogiri::HTML(response.body)

    doc.css('table tbody tr').each do |row|
      cells = row.css('td')
      next if cells.length < 4

      symbol_element = row.css('p.coin-item-symbol, span.crypto-symbol, [class*="symbol"]').first
      symbol = symbol_element&.text&.strip

      symbol ||= extract_symbol_from_row(row)

      price = extract_price_from_row(row)

      if symbol && price
        @cryptos << { symbol => price }
        puts "📈 #{symbol}: $#{price}"
      end
    end

    puts "✅ Scraping terminé ! #{@cryptos.length} cryptomonnaies récupérées."
    @cryptos
  end

  private

  def extract_symbol_from_row(row)
    row.css('p, span').each do |element|
      text = element.text.strip
      return text if text.match?(/^[A-Z]{2,10}$/) && !text.match?(/^(USD|EUR|GBP)$/)
    end
    nil
  end

  def extract_price_from_row(row)
    row.css('td').each do |cell|
      text = cell.text.strip
      if match = text.match(/\$?([\d,]+\.?\d*)/)
        price_str = match[1].gsub(',', '')
        price = price_str.to_f
        return price.round(2) if price > 0
      end
    end
    nil
  end
end

if __FILE__ == $PROGRAM_NAME
  trader = DarkTrader.new
  cryptos = trader.fetch_all_cryptos

  puts "\n" + "=" * 50
  puts "Résumé des #{cryptos.length} premières cryptomonnaies:"
  puts "=" * 50

  cryptos.first(10).each do |crypto|
    crypto.each { |symbol, price| puts "#{symbol}: $#{price}" }
  end
end
